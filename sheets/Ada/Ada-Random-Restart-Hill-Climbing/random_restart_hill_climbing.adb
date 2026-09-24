--  Random_Restart_Hill_Climbing body — steepest descent + random restarts.

pragma Ada_2022;

package body Random_Restart_Hill_Climbing
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- RNG (Numerical Recipes–style LCG, period 2^32)
   ---------------------------------------------------------------------------

   Multiplier : constant RNG_State := 1_664_525;
   Increment  : constant RNG_State := 1_013_904_223;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural) is
   begin
      if Seed = 0 then
         State := 1;
      else
         State := RNG_State (Seed);
      end if;
   end Seed_RNG;

   function Next_Unit (State : in out RNG_State) return Unit_Interval is
      Denom : constant Real := Real (RNG_State'Last) + 1.0;
   begin
      State := State * Multiplier + Increment;
      return Unit_Interval (Real (State) / Denom);
   end Next_Unit;

   function Next_Uniform
     (State : in out RNG_State; Lo, Hi : Real) return Real
   is
      U : constant Unit_Interval := Next_Unit (State);
   begin
      return Lo + Real (U) * (Hi - Lo);
   end Next_Uniform;

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
   is
      U    : constant Unit_Interval := Next_Unit (State);
      Span : constant Natural := Hi - Lo;
      K    : Natural;
   begin
      if Span = 0 then
         return Lo;
      end if;
      K := Natural (Real (U) * Real (Span + 1));
      if K > Span then
         K := Span;
      end if;
      return Lo + K;
   end Next_Natural;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Clamp (X, Lo, Hi : Real) return Real is
   begin
      if X < Lo then
         return Lo;
      elsif X > Hi then
         return Hi;
      else
         return X;
      end if;
   end Clamp;

   ---------------------------------------------------------------------------
   -- Bit-string utilities
   ---------------------------------------------------------------------------

   function Hamming_Distance (A, B : Bit_String) return Natural is
      D : Natural := 0;
   begin
      for I in A'Range loop
         if A (I) /= B (I - A'First + B'First) then
            D := D + 1;
         end if;
      end loop;
      return D;
   end Hamming_Distance;

   function Zero_Count (Bits : Bit_String) return Natural is
      Z : Natural := 0;
   begin
      for B of Bits loop
         if not B then
            Z := Z + 1;
         end if;
      end loop;
      return Z;
   end Zero_Count;

   function Ones_Count (Bits : Bit_String) return Natural is
   begin
      return Bits'Length - Zero_Count (Bits);
   end Ones_Count;

   function Flip_Bit (Bits : Bit_String; Index : Positive) return Bit_String is
      R : Bit_String := Bits;
   begin
      R (Index) := not R (Index);
      return R;
   end Flip_Bit;

   function Random_Bit_String
     (State : in out RNG_State; N : Bit_Count) return Bit_String
   is
      R : Bit_String (1 .. N);
   begin
      for I in 1 .. N loop
         R (I) := Next_Unit (State) >= 0.5;
      end loop;
      return R;
   end Random_Bit_String;


   ---------------------------------------------------------------------------
   -- Bit hill climb (steepest descent on Hamming / OneMax)
   ---------------------------------------------------------------------------

   function Hill_Climb_Hamming
     (Start  : Bit_String;
      Target : Bit_String;
      Cfg    : Config) return Bit_Result
   is
      N      : constant Bit_Count := Start'Length;
      Cur    : Bit_String (1 .. N) := Start;
      Cost   : Real := Real (Hamming_Distance (Cur, Target));
      Climbs : Natural := 0;
      Found  : Boolean;
      Best_N : Bit_String (1 .. N);
      Best_C : Real;
      Cand   : Bit_String (1 .. N);
      Cand_C : Real;
      R      : Bit_Result;
   begin
      if Start'Length /= Target'Length
        or else Start'Length < 1
        or else Start'Length > Max_Bits
      then
         raise Invalid_Argument;
      end if;

      --  Already optimal or empty improving neighborhood → return start.
      if Cost = 0.0 then
         R.N             := N;
         R.Best_Cost     := 0.0;
         R.Climbs        := 0;
         R.Restarts_Used := 0;
         for I in 1 .. N loop
            R.Best_Bits (I) := Cur (I);
         end loop;
         return R;
      end if;

      for Step_I in 1 .. Cfg.Max_Climb_Steps loop
         pragma Unreferenced (Step_I);
         Found  := False;
         Best_C := Cost;
         Best_N := Cur;

         for K in 1 .. N loop
            Cand   := Flip_Bit (Cur, K);
            Cand_C := Real (Hamming_Distance (Cand, Target));
            if Cand_C < Best_C then
               Found  := True;
               Best_C := Cand_C;
               Best_N := Cand;
            end if;
         end loop;

         exit when not Found;

         Cur    := Best_N;
         Cost   := Best_C;
         Climbs := Climbs + 1;
         exit when Cost = 0.0;
      end loop;

      R.N             := N;
      R.Best_Cost     := Cost;
      R.Climbs        := Climbs;
      R.Restarts_Used := 0;
      for I in 1 .. N loop
         R.Best_Bits (I) := Cur (I);
      end loop;
      return R;
   end Hill_Climb_Hamming;

   function Hill_Climb_OneMax
     (Start : Bit_String; Cfg : Config) return Bit_Result
   is
      N      : constant Bit_Count := Start'Length;
      Target : constant Bit_String (1 .. N) := [others => True];
      R      : Bit_Result;
   begin
      R := Hill_Climb_Hamming (Start, Target, Cfg);
      --  OneMax cost = zero count (same as Hamming to all-ones).
      return R;
   end Hill_Climb_OneMax;

   function Random_Restart_Hamming
     (Target : Bit_String; Cfg : Config) return Bit_Result
   is
      N       : constant Bit_Count := Target'Length;
      State   : RNG_State;
      Best    : Bit_Result;
      Trial   : Bit_Result;
      Start   : Bit_String (1 .. N);
      First   : Boolean := True;
      Total_C : Natural := 0;
   begin
      if Target'Length < 1 or else Target'Length > Max_Bits then
         raise Invalid_Argument;
      end if;

      Best.N             := N;
      Best.Best_Cost     := Real (N);
      Best.Restarts_Used := 0;
      Best.Climbs        := 0;

      if Cfg.Max_Restarts = 0 then
         return Best;
      end if;

      Seed_RNG (State, Cfg.Seed);

      for R in 1 .. Cfg.Max_Restarts loop
         Start := Random_Bit_String (State, N);
         Trial := Hill_Climb_Hamming (Start, Target, Cfg);
         Total_C := Total_C + Trial.Climbs;
         if First or else Trial.Best_Cost < Best.Best_Cost then
            Best  := Trial;
            First := False;
         end if;
         Best.Restarts_Used := R;
         Best.Climbs        := Total_C;
         exit when Best.Best_Cost = 0.0;
      end loop;

      return Best;
   end Random_Restart_Hamming;

   function Random_Restart_OneMax
     (N : Bit_Count; Cfg : Config) return Bit_Result
   is
      Target : constant Bit_String (1 .. N) := [others => True];
   begin
      return Random_Restart_Hamming (Target, Cfg);
   end Random_Restart_OneMax;

   ---------------------------------------------------------------------------
   -- Continuous objectives
   ---------------------------------------------------------------------------

   function Sphere_1D (X : Real) return Real is
   begin
      return X * X;
   end Sphere_1D;

   function Shifted_Sphere_1D (X : Real) return Real is
      D : constant Real := X - 3.0;
   begin
      return D * D;
   end Shifted_Sphere_1D;

   function Double_Well (X : Real) return Real is
      X2 : constant Real := X * X;
   begin
      return (X2 - 1.0) * (X2 - 1.0) + 0.15 * X;
   end Double_Well;

   function Two_Basin (X : Real) return Real is
      --  Shallow well at +2 (depth 1) and deep well at −3 (depth 0).
      D1 : constant Real := X - 2.0;
      D2 : constant Real := X + 3.0;
      W1 : constant Real := D1 * D1 + 1.0;
      W2 : constant Real := D2 * D2;
   begin
      if W1 < W2 then
         return W1;
      else
         return W2;
      end if;
   end Two_Basin;

   ---------------------------------------------------------------------------
   -- Continuous 1-D steepest descent (±Step neighbors)
   ---------------------------------------------------------------------------

   function Hill_Climb_1D
     (Objective : Objective_1D;
      X0        : Real;
      Cfg       : Config;
      Lo        : Real := -10.0;
      Hi        : Real := 10.0) return Cont_Result
   is
      X      : Real := Clamp (X0, Lo, Hi);
      Cost   : Real;
      Climbs : Natural := 0;
      Left   : Real;
      Right  : Real;
      CL, CR : Real;
      Best_X : Real;
      Best_C : Real;
      Moved  : Boolean;
      R      : Cont_Result;
   begin
      if Objective = null or else Lo >= Hi then
         raise Invalid_Argument;
      end if;

      Cost := Objective (X);

      for Step_I in 1 .. Cfg.Max_Climb_Steps loop
         pragma Unreferenced (Step_I);
         Left  := Clamp (X - Real (Cfg.Step), Lo, Hi);
         Right := Clamp (X + Real (Cfg.Step), Lo, Hi);
         CL    := Objective (Left);
         CR    := Objective (Right);
         Best_X := X;
         Best_C := Cost;
         Moved  := False;

         if CL < Best_C then
            Best_C := CL;
            Best_X := Left;
            Moved  := True;
         end if;
         if CR < Best_C then
            Best_C := CR;
            Best_X := Right;
            Moved  := True;
         end if;

         --  No strictly better neighbor (or both neighbors == current
         --  because of clamping at a bound with no improvement).
         exit when not Moved;
         --  If neighbor equals current position (stuck at bound), stop.
         exit when Near (Best_X, X);

         X      := Best_X;
         Cost   := Best_C;
         Climbs := Climbs + 1;
      end loop;

      R.Best_X        := X;
      R.Best_Cost     := Cost;
      R.Climbs        := Climbs;
      R.Restarts_Used := 0;
      return R;
   end Hill_Climb_1D;

   function Random_Restart_1D
     (Objective : Objective_1D;
      Cfg       : Config;
      Lo        : Real := -10.0;
      Hi        : Real := 10.0) return Cont_Result
   is
      State   : RNG_State;
      Best    : Cont_Result;
      Trial   : Cont_Result;
      X0      : Real;
      First   : Boolean := True;
      Total_C : Natural := 0;
   begin
      if Objective = null or else Lo >= Hi then
         raise Invalid_Argument;
      end if;

      Best.Best_X        := Lo;
      Best.Best_Cost     := Real'Last;
      Best.Restarts_Used := 0;
      Best.Climbs        := 0;

      if Cfg.Max_Restarts = 0 then
         return Best;
      end if;

      Seed_RNG (State, Cfg.Seed);

      for R in 1 .. Cfg.Max_Restarts loop
         X0    := Next_Uniform (State, Lo, Hi);
         Trial := Hill_Climb_1D (Objective, X0, Cfg, Lo, Hi);
         Total_C := Total_C + Trial.Climbs;
         if First or else Trial.Best_Cost < Best.Best_Cost then
            Best  := Trial;
            First := False;
         end if;
         Best.Restarts_Used := R;
         Best.Climbs        := Total_C;
      end loop;

      return Best;
   end Random_Restart_1D;

   ---------------------------------------------------------------------------
   -- TSP helpers
   ---------------------------------------------------------------------------

   function Tour_Length (T : Tour; D : Dist_Matrix) return Non_Negative is
      Len  : Real := 0.0;
      A, B : City_Index;
   begin
      for I in T'First .. T'Last - 1 loop
         A := T (I);
         B := T (I + 1);
         Len := Len + Real (D (A, B));
      end loop;
      A := T (T'Last);
      B := T (T'First);
      Len := Len + Real (D (A, B));
      return Non_Negative (Len);
   end Tour_Length;

   function Apply_2Opt (T : Tour; I, J : City_Index) return Tour is
      R   : Tour := T;
      Lo  : City_Index := I + 1;
      Hi  : City_Index := J;
      Tmp : City_Index;
   begin
      while Lo < Hi loop
         Tmp    := R (Lo);
         R (Lo) := R (Hi);
         R (Hi) := Tmp;
         Lo     := Lo + 1;
         Hi     := Hi - 1;
      end loop;
      return R;
   end Apply_2Opt;

   function Identity_Tour (N : City_Count) return Tour is
      T : Tour (1 .. City_Index (N));
   begin
      for I in T'Range loop
         T (I) := I;
      end loop;
      return T;
   end Identity_Tour;

   function Random_Tour
     (State : in out RNG_State; N : City_Count) return Tour
   is
      T   : Tour (1 .. City_Index (N)) := Identity_Tour (N);
      J   : City_Index;
      Tmp : City_Index;
   begin
      --  Fisher–Yates shuffle.
      for I in reverse 2 .. Natural (N) loop
         J := City_Index (Next_Natural (State, 1, I));
         Tmp := T (City_Index (I));
         T (City_Index (I)) := T (J);
         T (J) := Tmp;
      end loop;
      return T;
   end Random_Tour;

   function Hill_Climb_TSP
     (D     : Dist_Matrix;
      Start : Tour;
      Cfg   : Config) return TSP_Result
   is
      N       : constant City_Count := Start'Length;
      Last_C  : constant City_Index := City_Index (N);
      Cur     : Tour (1 .. Last_C) := Start;
      Len     : Non_Negative := Tour_Length (Cur, D);
      Climbs  : Natural := 0;
      Found   : Boolean;
      Best_T  : Tour (1 .. Last_C);
      Best_L  : Non_Negative;
      Cand    : Tour (1 .. Last_C);
      Cand_L  : Non_Negative;
      I, J    : City_Index;
      R       : TSP_Result;
   begin
      if Start'Length < 2 or else Start'Length > Max_Cities then
         raise Invalid_Argument;
      end if;

      for Step_I in 1 .. Cfg.Max_Climb_Steps loop
         pragma Unreferenced (Step_I);
         Found  := False;
         Best_L := Len;
         Best_T := Cur;

         for II in 1 .. Natural (N) - 2 loop
            I := City_Index (II);
            for JJ in II + 2 .. Natural (N) loop
               J := City_Index (JJ);
               if I = 1 and then J = Last_C then
                  null;  -- full reverse ≈ direction flip
               else
                  Cand   := Apply_2Opt (Cur, I, J);
                  Cand_L := Tour_Length (Cand, D);
                  if Cand_L < Best_L then
                     Found  := True;
                     Best_L := Cand_L;
                     Best_T := Cand;
                  end if;
               end if;
            end loop;
         end loop;

         exit when not Found;

         Cur    := Best_T;
         Len    := Best_L;
         Climbs := Climbs + 1;
      end loop;

      R.N             := N;
      R.Best_Length   := Len;
      R.Climbs        := Climbs;
      R.Restarts_Used := 0;
      for K in Cur'Range loop
         R.Best_Tour (K) := Cur (K);
      end loop;
      return R;
   end Hill_Climb_TSP;

   function Random_Restart_TSP
     (D : Dist_Matrix; Cfg : Config) return TSP_Result
   is
      N       : constant City_Count := City_Count (D'Length (1));
      State   : RNG_State;
      Best    : TSP_Result;
      Trial   : TSP_Result;
      Start   : Tour (1 .. City_Index (N));
      First   : Boolean := True;
      Total_C : Natural := 0;
   begin
      if D'Length (1) < 2 or else D'Length (1) > Max_Cities then
         raise Invalid_Argument;
      end if;

      Best.N             := N;
      Best.Best_Length   := Non_Negative'Last;
      Best.Restarts_Used := 0;
      Best.Climbs        := 0;

      if Cfg.Max_Restarts = 0 then
         return Best;
      end if;

      Seed_RNG (State, Cfg.Seed);

      for R in 1 .. Cfg.Max_Restarts loop
         Start := Random_Tour (State, N);
         Trial := Hill_Climb_TSP (D, Start, Cfg);
         Total_C := Total_C + Trial.Climbs;
         if First or else Trial.Best_Length < Best.Best_Length then
            Best  := Trial;
            First := False;
         end if;
         Best.Restarts_Used := R;
         Best.Climbs        := Total_C;
      end loop;

      return Best;
   end Random_Restart_TSP;

   ---------------------------------------------------------------------------
   -- To_Result adapters
   ---------------------------------------------------------------------------

   function To_Result (R : Bit_Result) return Result is
   begin
      return
        (Best_Cost     => R.Best_Cost,
         Restarts_Used => R.Restarts_Used,
         Climbs        => R.Climbs);
   end To_Result;

   function To_Result (R : Cont_Result) return Result is
   begin
      return
        (Best_Cost     => R.Best_Cost,
         Restarts_Used => R.Restarts_Used,
         Climbs        => R.Climbs);
   end To_Result;

   function To_Result (R : TSP_Result) return Result is
   begin
      return
        (Best_Cost     => Real (R.Best_Length),
         Restarts_Used => R.Restarts_Used,
         Climbs        => R.Climbs);
   end To_Result;

end Random_Restart_Hill_Climbing;
