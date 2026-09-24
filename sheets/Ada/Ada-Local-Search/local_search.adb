--  Local_Search body — neighborhoods, hill climbs, restarts, ILS, 2-opt.

pragma Ada_2022;

package body Local_Search
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

   function Default_Config
     (Max_Climb_Steps : Positive := 500;
      Max_Restarts    : Natural  := 5;
      Perturb_Flips   : Positive := 2;
      Seed            : Natural  := 1) return Config
   is
   begin
      return
        (Max_Climb_Steps => Max_Climb_Steps,
         Max_Restarts    => Max_Restarts,
         Perturb_Flips   => Perturb_Flips,
         Seed            => Seed);
   end Default_Config;

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

   function Copy_Bits (Src : Bit_String; N : Bit_Count) return Bit_String is
      R : Bit_String (1 .. N);
   begin
      for I in 1 .. N loop
         R (I) := Src (Src'First + I - 1);
      end loop;
      return R;
   end Copy_Bits;

   function All_Ones (N : Bit_Count) return Bit_String is
      B : constant Bit_String (1 .. N) := [others => True];
   begin
      return B;
   end All_Ones;

   function All_Zeros (N : Bit_Count) return Bit_String is
      B : constant Bit_String (1 .. N) := [others => False];
   begin
      return B;
   end All_Zeros;

   function Pack_Bits
     (Cur : Bit_String; N : Bit_Count; Cost : Real;
      Climbs, Restarts, Perturbs : Natural) return Bit_Result
   is
      R : Bit_Result;
   begin
      R.N             := N;
      R.Best_Cost     := Cost;
      R.Climbs        := Climbs;
      R.Restarts_Used := Restarts;
      R.Perturbations := Perturbs;
      for I in 1 .. N loop
         R.Best_Bits (I) := Cur (I);
      end loop;
      return R;
   end Pack_Bits;

   function Is_Local_Optimum_Hamming
     (Bits : Bit_String; Target : Bit_String) return Boolean
   is
      N    : constant Bit_Count := Bits'Length;
      Cur  : constant Bit_String (1 .. N) := Copy_Bits (Bits, N);
      Tgt  : constant Bit_String (1 .. N) := Copy_Bits (Target, N);
      Cost : constant Natural := Hamming_Distance (Cur, Tgt);
      Cand : Bit_String (1 .. N);
   begin
      for K in 1 .. N loop
         Cand := Flip_Bit (Cur, K);
         if Hamming_Distance (Cand, Tgt) < Cost then
            return False;
         end if;
      end loop;
      return True;
   end Is_Local_Optimum_Hamming;

   function Is_Local_Optimum_OneMax (Bits : Bit_String) return Boolean is
   begin
      return Is_Local_Optimum_Hamming (Bits, All_Ones (Bits'Length));
   end Is_Local_Optimum_OneMax;

   ---------------------------------------------------------------------------
   -- Steepest hill climb
   ---------------------------------------------------------------------------

   function Steepest_Climb_Hamming
     (Start  : Bit_String;
      Target : Bit_String;
      Cfg    : Config) return Bit_Result
   is
      N      : constant Bit_Count := Start'Length;
      Cur    : Bit_String (1 .. N) := Copy_Bits (Start, N);
      Tgt    : constant Bit_String (1 .. N) := Copy_Bits (Target, N);
      Cost   : Real := Real (Hamming_Distance (Cur, Tgt));
      Climbs : Natural := 0;
      Found  : Boolean;
      Best_N : Bit_String (1 .. N);
      Best_C : Real;
      Cand   : Bit_String (1 .. N);
      Cand_C : Real;
   begin
      if Start'Length /= Target'Length
        or else Start'Length < 1
        or else Start'Length > Max_Bits
      then
         raise Invalid_Argument;
      end if;

      if Cost = 0.0 then
         return Pack_Bits (Cur, N, 0.0, 0, 0, 0);
      end if;

      for Step_I in 1 .. Cfg.Max_Climb_Steps loop
         pragma Unreferenced (Step_I);
         Found  := False;
         Best_C := Cost;
         Best_N := Cur;

         for K in 1 .. N loop
            Cand   := Flip_Bit (Cur, K);
            Cand_C := Real (Hamming_Distance (Cand, Tgt));
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

      return Pack_Bits (Cur, N, Cost, Climbs, 0, 0);
   end Steepest_Climb_Hamming;

   function Steepest_Climb_OneMax
     (Start : Bit_String; Cfg : Config) return Bit_Result
   is
   begin
      return Steepest_Climb_Hamming (Start, All_Ones (Start'Length), Cfg);
   end Steepest_Climb_OneMax;

   ---------------------------------------------------------------------------
   -- First-improvement hill climb
   ---------------------------------------------------------------------------

   function First_Improve_Hamming
     (Start  : Bit_String;
      Target : Bit_String;
      Cfg    : Config) return Bit_Result
   is
      N      : constant Bit_Count := Start'Length;
      Cur    : Bit_String (1 .. N) := Copy_Bits (Start, N);
      Tgt    : constant Bit_String (1 .. N) := Copy_Bits (Target, N);
      Cost   : Real := Real (Hamming_Distance (Cur, Tgt));
      Climbs : Natural := 0;
      Found  : Boolean;
      Cand   : Bit_String (1 .. N);
      Cand_C : Real;
   begin
      if Start'Length /= Target'Length
        or else Start'Length < 1
        or else Start'Length > Max_Bits
      then
         raise Invalid_Argument;
      end if;

      if Cost = 0.0 then
         return Pack_Bits (Cur, N, 0.0, 0, 0, 0);
      end if;

      for Step_I in 1 .. Cfg.Max_Climb_Steps loop
         pragma Unreferenced (Step_I);
         Found := False;

         for K in 1 .. N loop
            Cand   := Flip_Bit (Cur, K);
            Cand_C := Real (Hamming_Distance (Cand, Tgt));
            if Cand_C < Cost then
               Cur    := Cand;
               Cost   := Cand_C;
               Climbs := Climbs + 1;
               Found  := True;
               exit;
            end if;
         end loop;

         exit when not Found;
         exit when Cost = 0.0;
      end loop;

      return Pack_Bits (Cur, N, Cost, Climbs, 0, 0);
   end First_Improve_Hamming;

   function First_Improve_OneMax
     (Start : Bit_String; Cfg : Config) return Bit_Result
   is
   begin
      return First_Improve_Hamming (Start, All_Ones (Start'Length), Cfg);
   end First_Improve_OneMax;

   ---------------------------------------------------------------------------
   -- Random-restart wrapper
   ---------------------------------------------------------------------------

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

      Best := Pack_Bits (All_Zeros (N), N, Real'Last, 0, 0, 0);

      if Cfg.Max_Restarts = 0 then
         return Best;
      end if;

      Seed_RNG (State, Cfg.Seed);

      for R in 1 .. Cfg.Max_Restarts loop
         Start := Random_Bit_String (State, N);
         Trial := Steepest_Climb_Hamming (Start, Target, Cfg);
         Total_C := Total_C + Trial.Climbs;
         if First or else Trial.Best_Cost < Best.Best_Cost then
            Best  := Trial;
            First := False;
         end if;
         Best.Restarts_Used := R;
         Best.Climbs        := Total_C;
      end loop;

      return Best;
   end Random_Restart_Hamming;

   function Random_Restart_OneMax
     (N : Bit_Count; Cfg : Config) return Bit_Result
   is
   begin
      return Random_Restart_Hamming (All_Ones (N), Cfg);
   end Random_Restart_OneMax;

   ---------------------------------------------------------------------------
   -- Perturbation + Iterated Local Search
   ---------------------------------------------------------------------------

   function Perturb_Bits
     (Bits  : Bit_String;
      State : in out RNG_State;
      K     : Positive) return Bit_String
   is
      N   : constant Bit_Count := Bits'Length;
      Cur : Bit_String (1 .. N) := Copy_Bits (Bits, N);
      Idx : Positive;
   begin
      for Flip_I in 1 .. K loop
         pragma Unreferenced (Flip_I);
         Idx := Next_Natural (State, 1, N);
         Cur (Idx) := not Cur (Idx);
      end loop;
      return Cur;
   end Perturb_Bits;

   function Iterated_Local_Search_Hamming
     (Start  : Bit_String;
      Target : Bit_String;
      Cfg    : Config) return Bit_Result
   is
      N         : constant Bit_Count := Start'Length;
      Tgt       : constant Bit_String (1 .. N) := Copy_Bits (Target, N);
      State     : RNG_State;
      Cur       : Bit_Result;
      Cand      : Bit_Result;
      Perturbed : Bit_String (1 .. N);
      Total_C   : Natural := 0;
      Outer     : Natural := 0;
      Accepts   : Natural := 0;
   begin
      if Start'Length /= Target'Length
        or else Start'Length < 1
        or else Start'Length > Max_Bits
      then
         raise Invalid_Argument;
      end if;

      Seed_RNG (State, Cfg.Seed);

      --  Initial climb from Start.
      Cur := Steepest_Climb_Hamming (Start, Tgt, Cfg);
      Total_C := Cur.Climbs;

      --  Outer ILS loop: perturb → climb → accept if better (or equal cost
      --  with different bits to allow plateaus / diversification lightly).
      for Iter in 1 .. Cfg.Max_Restarts loop
         pragma Unreferenced (Iter);
         exit when Cur.Best_Cost = 0.0;

         Outer := Outer + 1;
         Perturbed := Perturb_Bits
           (Copy_Bits (Cur.Best_Bits, N), State, Cfg.Perturb_Flips);
         Cand := Steepest_Climb_Hamming (Perturbed, Tgt, Cfg);
         Total_C := Total_C + Cand.Climbs;

         if Cand.Best_Cost < Cur.Best_Cost then
            Cur := Cand;
            Accepts := Accepts + 1;
         end if;
      end loop;

      Cur.Climbs        := Total_C;
      Cur.Restarts_Used := Outer;
      Cur.Perturbations := Outer;
      return Cur;
   end Iterated_Local_Search_Hamming;

   function Iterated_Local_Search_OneMax
     (Start : Bit_String; Cfg : Config) return Bit_Result
   is
   begin
      return Iterated_Local_Search_Hamming
        (Start, All_Ones (Start'Length), Cfg);
   end Iterated_Local_Search_OneMax;

   ---------------------------------------------------------------------------
   -- TSP helpers + 2-opt
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
      T    : Tour (1 .. City_Index (N));
      J    : City_Index;
      Tmp  : City_Index;
      Pick : Natural;
   begin
      for I in T'Range loop
         T (I) := I;
      end loop;
      --  Fisher–Yates shuffle.
      for I in reverse T'First + 1 .. T'Last loop
         Pick := Next_Natural (State, Natural (T'First), Natural (I));
         J    := City_Index (Pick);
         Tmp  := T (I);
         T (I) := T (J);
         T (J) := Tmp;
      end loop;
      return T;
   end Random_Tour;

   function Is_Local_Optimum_TSP
     (T : Tour; D : Dist_Matrix) return Boolean
   is
      Len  : constant Non_Negative := Tour_Length (T, D);
      Cand : Tour (T'Range);
   begin
      for I in T'First .. T'Last - 2 loop
         for J in I + 2 .. T'Last loop
            --  Skip adjacent wrap that would be a null move on a cycle
            --  when I = First and J = Last (same edge).
            if not (I = T'First and then J = T'Last) then
               Cand := Apply_2Opt (T, I, J);
               if Tour_Length (Cand, D) < Len then
                  return False;
               end if;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Local_Optimum_TSP;

   function Pack_Tour
     (Cur : Tour; N : City_Count; Len : Non_Negative;
      Climbs, Restarts, Perturbs : Natural) return TSP_Result
   is
      R : TSP_Result;
   begin
      R.N             := N;
      R.Best_Length   := Len;
      R.Climbs        := Climbs;
      R.Restarts_Used := Restarts;
      R.Perturbations := Perturbs;
      for I in 1 .. City_Index (N) loop
         R.Best_Tour (I) := Cur (I);
      end loop;
      return R;
   end Pack_Tour;

   function Two_Opt_Local_Search
     (D     : Dist_Matrix;
      Start : Tour;
      Cfg   : Config) return TSP_Result
   is
      N      : constant City_Count := Start'Length;
      Cur    : Tour (1 .. City_Index (N)) := Start;
      Len    : Non_Negative := Tour_Length (Cur, D);
      Climbs : Natural := 0;
      Found  : Boolean;
      Best_T : Tour (1 .. City_Index (N));
      Best_L : Non_Negative;
      Cand   : Tour (1 .. City_Index (N));
      Cand_L : Non_Negative;
   begin
      if Start'Length < 2 or else Start'Length > Max_Cities then
         raise Invalid_Argument;
      end if;

      for Step_I in 1 .. Cfg.Max_Climb_Steps loop
         pragma Unreferenced (Step_I);
         Found  := False;
         Best_L := Len;
         Best_T := Cur;

         for I in Cur'First .. Cur'Last - 2 loop
            for J in I + 2 .. Cur'Last loop
               if not (I = Cur'First and then J = Cur'Last) then
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

      return Pack_Tour (Cur, N, Len, Climbs, 0, 0);
   end Two_Opt_Local_Search;

   function Random_Restart_TSP
     (D : Dist_Matrix; Cfg : Config) return TSP_Result
   is
      N       : constant City_Count := D'Length (1);
      State   : RNG_State;
      Best    : TSP_Result;
      Trial   : TSP_Result;
      Start   : Tour (1 .. City_Index (N));
      First   : Boolean := True;
      Total_C : Natural := 0;
   begin
      Best := Pack_Tour
        (Identity_Tour (N), N, Non_Negative'Last, 0, 0, 0);

      if Cfg.Max_Restarts = 0 then
         return Best;
      end if;

      Seed_RNG (State, Cfg.Seed);

      for R in 1 .. Cfg.Max_Restarts loop
         Start := Random_Tour (State, N);
         Trial := Two_Opt_Local_Search (D, Start, Cfg);
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
   -- Taxonomy
   ---------------------------------------------------------------------------

   function Classify_Method (Kind : Method_Kind) return Method_Info is
   begin
      case Kind is
         when Hill_Climbing =>
            return (Kind => Hill_Climbing,
                    Implemented => True,
                    Stochastic  => False,
                    Uses_Memory => False);
         when Random_Restart =>
            return (Kind => Random_Restart,
                    Implemented => True,
                    Stochastic  => True,
                    Uses_Memory => False);
         when Tabu =>
            return (Kind => Tabu,
                    Implemented => False,
                    Stochastic  => False,
                    Uses_Memory => True);
         when Simulated_Annealing =>
            return (Kind => Simulated_Annealing,
                    Implemented => False,
                    Stochastic  => True,
                    Uses_Memory => False);
         when Iterated_Local_Search =>
            return (Kind => Iterated_Local_Search,
                    Implemented => True,
                    Stochastic  => True,
                    Uses_Memory => False);
         when Random_Search =>
            return (Kind => Random_Search,
                    Implemented => False,
                    Stochastic  => True,
                    Uses_Memory => False);
      end case;
   end Classify_Method;

   function Method_Name (Kind : Method_Kind) return String is
   begin
      case Kind is
         when Hill_Climbing          => return "Hill Climbing";
         when Random_Restart         => return "Random Restart";
         when Tabu                   => return "Tabu Search";
         when Simulated_Annealing    => return "Simulated Annealing";
         when Iterated_Local_Search  => return "Iterated Local Search";
         when Random_Search          => return "Random Search";
      end case;
   end Method_Name;

   function Method_Implemented (Kind : Method_Kind) return Boolean is
   begin
      return Classify_Method (Kind).Implemented;
   end Method_Implemented;

   ---------------------------------------------------------------------------
   -- To_Result
   ---------------------------------------------------------------------------

   function To_Result (R : Bit_Result) return Result is
   begin
      return
        (Best_Cost     => R.Best_Cost,
         Restarts_Used => R.Restarts_Used,
         Climbs        => R.Climbs,
         Perturbations => R.Perturbations);
   end To_Result;

   function To_Result (R : TSP_Result) return Result is
   begin
      return
        (Best_Cost     => Real (R.Best_Length),
         Restarts_Used => R.Restarts_Used,
         Climbs        => R.Climbs,
         Perturbations => R.Perturbations);
   end To_Result;

end Local_Search;
