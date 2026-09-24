--  Harmony_Search body — Geem et al. (2001) educational harmony search:
--  Init_HM, Improvise (HMCR / PAR / BW), Update_HM, Minimize_Box,
--  Minimize_OneMax.

pragma Ada_2022;

package body Harmony_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Clamp (X, Lo, Hi : Real) return Real is
   begin
      if Lo > Hi then
         raise Invalid_Argument;
      end if;
      if X < Lo then
         return Lo;
      elsif X > Hi then
         return Hi;
      else
         return X;
      end if;
   end Clamp;

   function Default_Config
     (HMS                : HMS_Count     := 10;
      HMCR               : Unit_Interval := 0.90;
      PAR                : Unit_Interval := 0.30;
      BW                 : Non_Negative  := 0.20;
      Max_Improvisations : Natural       := 1_000;
      Seed               : Natural       := 1) return Config
   is
   begin
      return
        (HMS                => HMS,
         HMCR               => HMCR,
         PAR                => PAR,
         BW                 => BW,
         Max_Improvisations => Max_Improvisations,
         Seed               => Seed);
   end Default_Config;

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
   -- Objectives
   ---------------------------------------------------------------------------

   function Sphere (X : Point) return Real is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + X (I) * X (I);
      end loop;
      return S;
   end Sphere;

   function Rosenbrock (X : Point) return Real is
      A  : constant Real := 1.0;
      B  : constant Real := 100.0;
      Xx : Real;
      Yy : Real;
   begin
      if X'Length < 2 then
         raise Invalid_Argument;
      end if;
      Xx := X (X'First);
      Yy := X (X'First + 1);
      return (A - Xx) ** 2 + B * (Yy - Xx ** 2) ** 2;
   end Rosenbrock;

   function Shifted_Sphere (X : Point) return Real is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + (X (I) - 1.0) ** 2;
      end loop;
      return S;
   end Shifted_Sphere;

   ---------------------------------------------------------------------------
   -- Bit helpers
   ---------------------------------------------------------------------------

   function Zero_Count (Bits : Bit_String) return Natural is
      C : Natural := 0;
   begin
      for I in Bits'Range loop
         if not Bits (I) then
            C := C + 1;
         end if;
      end loop;
      return C;
   end Zero_Count;

   function Ones_Count (Bits : Bit_String) return Natural is
      C : Natural := 0;
   begin
      for I in Bits'Range loop
         if Bits (I) then
            C := C + 1;
         end if;
      end loop;
      return C;
   end Ones_Count;

   function Flip_Bit (Bits : Bit_String; Index : Positive) return Bit_String is
      R : Bit_String (Bits'Range) := Bits;
   begin
      R (Index) := not R (Index);
      return R;
   end Flip_Bit;

   ---------------------------------------------------------------------------
   -- Continuous HM
   ---------------------------------------------------------------------------

   procedure Validate_Bounds (B : Bounds) is
   begin
      for I in B'Range loop
         if B (I).Lo > B (I).Hi then
            raise Invalid_Argument;
         end if;
      end loop;
   end Validate_Bounds;

   function Random_Point
     (State : in out RNG_State; B : Bounds) return Point
   is
      P : Point (B'Range);
   begin
      for I in B'Range loop
         P (I) := Next_Uniform (State, B (I).Lo, B (I).Hi);
      end loop;
      return P;
   end Random_Point;

   procedure Copy_Point_Into
     (Src : Point; Dest : in out Point; Dim : Dim_Count)
   is
      J : Dim_Index := Src'First;
   begin
      for I in 1 .. Dim loop
         Dest (I) := Src (J);
         if J < Src'Last then
            J := J + 1;
         end if;
      end loop;
   end Copy_Point_Into;

   procedure Init_HM
     (HM        : in out Harmony_Memory;
      B         : Bounds;
      Objective : Objective_Fn;
      State     : in out RNG_State)
   is
      Dim : constant Dim_Count := Dim_Count (B'Length);
      P   : Point (B'Range);
   begin
      if Objective = null then
         raise Invalid_Argument;
      end if;
      Validate_Bounds (B);
      HM.Dim  := Dim;
      HM.Size := 0;
      for K in 1 .. HM.Capacity loop
         P := Random_Point (State, B);
         HM.Members (K).Dim := Dim;
         HM.Members (K).X   := [others => 0.0];
         Copy_Point_Into (P, HM.Members (K).X, Dim);
         HM.Members (K).Cost := Objective (P);
         HM.Size := HM.Size + 1;
      end loop;
   end Init_HM;

   function Improvise
     (HM    : Harmony_Memory;
      B     : Bounds;
      Cfg   : Config;
      State : in out RNG_State) return Harmony
   is
      Dim  : constant Dim_Count := HM.Dim;
      H    : Harmony;
      Mem  : Positive;
      U    : Unit_Interval;
      Sign : Real;
      Adj : Real;
      Idx  : Dim_Index;
   begin
      if HM.Size < 1 or else B'Length /= Natural (Dim) then
         raise Invalid_Argument;
      end if;
      Validate_Bounds (B);
      H.Dim  := Dim;
      H.X    := [others => 0.0];
      H.Cost := Real'Last;

      for D in 1 .. Dim loop
         Idx := Dim_Index (D);
         U := Next_Unit (State);
         if Real (U) < Real (Cfg.HMCR) then
            Mem := Next_Natural (State, 1, HM.Size);
            H.X (Idx) := HM.Members (Mem).X (Idx);
            U := Next_Unit (State);
            if Real (U) < Real (Cfg.PAR) then
               --  Pitch adjust: x := x ± U·BW (random sign), then clamp.
               Sign := (if Next_Unit (State) < 0.5 then -1.0 else 1.0);
               Adj := Sign * Real (Next_Unit (State)) * Real (Cfg.BW);
               H.X (Idx) :=
                 Clamp
                   (H.X (Idx) + Adj,
                    B (B'First + D - 1).Lo,
                    B (B'First + D - 1).Hi);
            end if;
         else
            H.X (Idx) :=
              Next_Uniform
                (State,
                 B (B'First + D - 1).Lo,
                 B (B'First + D - 1).Hi);
         end if;
      end loop;
      return H;
   end Improvise;

   function Worst_Index (HM : Harmony_Memory) return Positive is
      W : Positive := 1;
   begin
      for K in 2 .. HM.Size loop
         if HM.Members (K).Cost > HM.Members (W).Cost then
            W := K;
         end if;
      end loop;
      return W;
   end Worst_Index;

   function Best_Index (HM : Harmony_Memory) return Positive is
      B : Positive := 1;
   begin
      for K in 2 .. HM.Size loop
         if HM.Members (K).Cost < HM.Members (B).Cost then
            B := K;
         end if;
      end loop;
      return B;
   end Best_Index;

   procedure Update_HM
     (HM        : in out Harmony_Memory;
      Candidate : Harmony)
   is
      W : Positive;
   begin
      if HM.Size < 1 or else Candidate.Dim /= HM.Dim then
         raise Invalid_Argument;
      end if;
      W := Worst_Index (HM);
      if Candidate.Cost < HM.Members (W).Cost then
         HM.Members (W) := Candidate;
      end if;
   end Update_HM;

   ---------------------------------------------------------------------------
   -- Discrete HM
   ---------------------------------------------------------------------------

   procedure Init_Bit_HM
     (HM    : in out Bit_Harmony_Memory;
      N     : Bit_Count;
      State : in out RNG_State)
   is
      Bits : Bit_String (1 .. N);
   begin
      HM.N    := N;
      HM.Size := 0;
      for K in 1 .. HM.Capacity loop
         for I in 1 .. N loop
            Bits (I) := Next_Unit (State) < 0.5;
         end loop;
         HM.Members (K).N    := N;
         HM.Members (K).Bits := [others => False];
         for I in 1 .. N loop
            HM.Members (K).Bits (I) := Bits (I);
         end loop;
         HM.Members (K).Cost := Real (Zero_Count (Bits));
         HM.Size := HM.Size + 1;
      end loop;
   end Init_Bit_HM;

   function Improvise_Bits
     (HM    : Bit_Harmony_Memory;
      Cfg   : Config;
      State : in out RNG_State) return Bit_Harmony
   is
      N   : constant Bit_Count := HM.N;
      H   : Bit_Harmony;
      Mem : Positive;
      U   : Unit_Interval;
      Bit_Val : Boolean;
   begin
      if HM.Size < 1 then
         raise Invalid_Argument;
      end if;
      H.N    := N;
      H.Bits := [others => False];
      H.Cost := Real'Last;

      for I in 1 .. N loop
         U := Next_Unit (State);
         if Real (U) < Real (Cfg.HMCR) then
            Mem := Next_Natural (State, 1, HM.Size);
            Bit_Val := HM.Members (Mem).Bits (I);
            U := Next_Unit (State);
            if Real (U) < Real (Cfg.PAR) then
               Bit_Val := not Bit_Val;  -- discrete pitch neighbor = flip
            end if;
            H.Bits (I) := Bit_Val;
         else
            H.Bits (I) := Next_Unit (State) < 0.5;
         end if;
      end loop;
      return H;
   end Improvise_Bits;

   function Worst_Bit_Index (HM : Bit_Harmony_Memory) return Positive is
      W : Positive := 1;
   begin
      for K in 2 .. HM.Size loop
         if HM.Members (K).Cost > HM.Members (W).Cost then
            W := K;
         end if;
      end loop;
      return W;
   end Worst_Bit_Index;

   function Best_Bit_Index (HM : Bit_Harmony_Memory) return Positive is
      B : Positive := 1;
   begin
      for K in 2 .. HM.Size loop
         if HM.Members (K).Cost < HM.Members (B).Cost then
            B := K;
         end if;
      end loop;
      return B;
   end Best_Bit_Index;

   procedure Update_Bit_HM
     (HM        : in out Bit_Harmony_Memory;
      Candidate : Bit_Harmony)
   is
      W : Positive;
   begin
      if HM.Size < 1 or else Candidate.N /= HM.N then
         raise Invalid_Argument;
      end if;
      W := Worst_Bit_Index (HM);
      if Candidate.Cost < HM.Members (W).Cost then
         HM.Members (W) := Candidate;
      end if;
   end Update_Bit_HM;

   ---------------------------------------------------------------------------
   -- Drivers
   ---------------------------------------------------------------------------

   function Minimize_Box
     (Objective : Objective_Fn;
      B         : Bounds;
      Cfg       : Config) return Result
   is
      Dim    : constant Dim_Count := Dim_Count (B'Length);
      HM     : Harmony_Memory (Cfg.HMS);
      State  : RNG_State;
      Cand   : Harmony;
      Bi     : Positive;
      R      : Result;
      P      : Point (B'Range);
   begin
      if Objective = null then
         raise Invalid_Argument;
      end if;
      Validate_Bounds (B);
      Seed_RNG (State, Cfg.Seed);
      Init_HM (HM, B, Objective, State);

      for Iter in 1 .. Cfg.Max_Improvisations loop
         Cand := Improvise (HM, B, Cfg, State);
         for I in 1 .. Dim loop
            P (B'First + I - 1) := Cand.X (I);
         end loop;
         Cand.Cost := Objective (P);
         Update_HM (HM, Cand);
      end loop;

      Bi := Best_Index (HM);
      R.Best_Cost      := HM.Members (Bi).Cost;
      R.Best_X         := HM.Members (Bi).X;
      R.Dim            := Dim;
      R.Improvisations := Cfg.Max_Improvisations;
      R.HMS_Used       := HM.Size;
      return R;
   end Minimize_Box;

   function Minimize_OneMax
     (N   : Bit_Count;
      Cfg : Config) return Bit_Result
   is
      HM    : Bit_Harmony_Memory (Cfg.HMS);
      State : RNG_State;
      Cand  : Bit_Harmony;
      Bi    : Positive;
      R     : Bit_Result;
      Slice : Bit_String (1 .. N);
   begin
      Seed_RNG (State, Cfg.Seed);
      Init_Bit_HM (HM, N, State);

      for Iter in 1 .. Cfg.Max_Improvisations loop
         Cand := Improvise_Bits (HM, Cfg, State);
         for I in 1 .. N loop
            Slice (I) := Cand.Bits (I);
         end loop;
         Cand.Cost := Real (Zero_Count (Slice));
         Update_Bit_HM (HM, Cand);
      end loop;

      Bi := Best_Bit_Index (HM);
      R.Best_Bits      := HM.Members (Bi).Bits;
      R.N              := N;
      R.Best_Cost      := HM.Members (Bi).Cost;
      R.Improvisations := Cfg.Max_Improvisations;
      R.HMS_Used       := HM.Size;
      return R;
   end Minimize_OneMax;

end Harmony_Search;
