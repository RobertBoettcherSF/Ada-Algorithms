--  Random_Search body — uniform / log-uniform sampling, random & grid search.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Generic_Elementary_Functions;

package body Random_Search
  with SPARK_Mode => Off
is

   package EF is new Ada.Numerics.Generic_Elementary_Functions (Real);
   use EF;

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

   function Better
     (Candidate, Best : Real; Sense_Flag : Sense) return Boolean
   is
   begin
      case Sense_Flag is
         when Minimize_Sense =>
            return Candidate < Best;
         when Maximize_Sense =>
            return Candidate > Best;
      end case;
   end Better;

   ---------------------------------------------------------------------------
   -- Sampling
   ---------------------------------------------------------------------------

   function Sample_Uniform
     (State : in out RNG_State; Lo, Hi : Real) return Real
   is
   begin
      return Next_Uniform (State, Lo, Hi);
   end Sample_Uniform;

   function Sample_Log_Uniform
     (State : in out RNG_State; Lo, Hi : Positive_Real) return Real
   is
      Log_Lo : Real;
      Log_Hi : Real;
      U      : Unit_Interval;
   begin
      if Lo <= 0.0 or else Hi < Lo then
         raise Invalid_Argument;
      end if;
      Log_Lo := Log (Real (Lo));
      Log_Hi := Log (Real (Hi));
      U := Next_Unit (State);
      return Exp (Log_Lo + Real (U) * (Log_Hi - Log_Lo));
   end Sample_Log_Uniform;

   function Sample_Point
     (State : in out RNG_State;
      B     : Bounds;
      Kind  : Sampling_Kind) return Point
   is
      P : Point (B'Range);
   begin
      for I in B'Range loop
         if B (I).Lo > B (I).Hi then
            raise Invalid_Argument;
         end if;
         case Kind is
            when Uniform =>
               P (I) := Sample_Uniform (State, B (I).Lo, B (I).Hi);
            when Log_Uniform =>
               if B (I).Lo <= 0.0 then
                  raise Invalid_Argument;
               end if;
               P (I) := Sample_Log_Uniform
                 (State,
                  Positive_Real (B (I).Lo),
                  Positive_Real (B (I).Hi));
         end case;
         P (I) := Clamp (P (I), B (I).Lo, B (I).Hi);
      end loop;
      return P;
   end Sample_Point;

   ---------------------------------------------------------------------------
   -- Built-in objectives
   ---------------------------------------------------------------------------

   function Quadratic_1D (X : Real) return Real is
   begin
      return X * X;
   end Quadratic_1D;

   function Shifted_Quadratic_1D (X : Real) return Real is
      D : constant Real := X - 3.0;
   begin
      return D * D;
   end Shifted_Quadratic_1D;

   function Needle_1D (X : Real) return Real is
      D : constant Real := X - 0.7;
   begin
      return D * D;
   end Needle_1D;

   function Sphere_ND (X : Point) return Real is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + X (I) * X (I);
      end loop;
      return S;
   end Sphere_ND;

   function Needle_Haystack_2D (X : Point) return Real is
      D : Real;
   begin
      if X'Length < 1 then
         return 0.0;
      end if;
      D := X (X'First) - 0.75;
      return D * D;
   end Needle_Haystack_2D;

   function Rastrigin_2D (X : Point) return Real is
      Two_Pi : constant Real := 2.0 * Real (Ada.Numerics.Pi);
      S      : Real := 0.0;
      Xi     : Real;
      N      : Natural := 0;
   begin
      for I in X'Range loop
         Xi := X (I);
         S := S + (Xi * Xi - 10.0 * Cos (Two_Pi * Xi) + 10.0);
         N := N + 1;
         exit when N >= 2;
      end loop;
      return S;
   end Rastrigin_2D;

   function Neg_Sphere_ND (X : Point) return Real is
   begin
      return -Sphere_ND (X);
   end Neg_Sphere_ND;

   function Log10_Squared_1D (X : Real) return Real is
      L : Real;
   begin
      if X <= 0.0 then
         raise Invalid_Argument;
      end if;
      L := Log (X) / Log (10.0);
      return L * L;
   end Log10_Squared_1D;

   function Neg_Quadratic_1D_As_ND (X : Point) return Real is
   begin
      return -(X (X'First) * X (X'First));
   end Neg_Quadratic_1D_As_ND;

   ---------------------------------------------------------------------------
   -- Internal N-D core
   ---------------------------------------------------------------------------

   function Run_Search
     (Objective : Objective_ND;
      B         : Bounds;
      Cfg       : Config;
      Seed      : Natural) return Result
   is
      State : RNG_State;
      R     : Result;
      P     : Point (B'Range);
      F     : Real;
      First : Boolean := True;
      D     : constant Dim_Count := Dim_Count (B'Length);
   begin
      R.Dim := D;
      R.Trials_Run := 0;
      R.Best_Trial := 0;
      for I in 1 .. Max_Dim loop
         R.Best_X (I) := 0.0;
      end loop;

      if Cfg.Trials = 0 then
         return R;
      end if;

      for I in B'Range loop
         if B (I).Lo > B (I).Hi then
            raise Invalid_Argument;
         end if;
         if Cfg.Kind = Log_Uniform and then B (I).Lo <= 0.0 then
            raise Invalid_Argument;
         end if;
      end loop;

      Seed_RNG (State, Seed);

      for T in 1 .. Cfg.Trials loop
         P := Sample_Point (State, B, Cfg.Kind);
         F := Objective (P);
         R.Trials_Run := R.Trials_Run + 1;
         if First or else Better (F, R.Best_F, Cfg.Sense_Flag) then
            R.Best_F := F;
            declare
               K : Dim_Index := 1;
            begin
               for I in P'Range loop
                  R.Best_X (K) := P (I);
                  exit when K = Max_Dim;
                  K := K + 1;
               end loop;
            end;
            R.Best_Trial := T;
            First := False;
         end if;
      end loop;

      return R;
   end Run_Search;

   ---------------------------------------------------------------------------
   -- Search drivers
   ---------------------------------------------------------------------------

   function Search_1D
     (Objective : Objective_1D;
      Lo, Hi    : Real;
      Cfg       : Config;
      Seed      : Natural) return Result
   is
      State : RNG_State;
      R     : Result;
      X, F  : Real;
      First : Boolean := True;
   begin
      if Objective = null or else Lo >= Hi then
         raise Invalid_Argument;
      end if;
      if Cfg.Kind = Log_Uniform and then Lo <= 0.0 then
         raise Invalid_Argument;
      end if;

      R.Dim := 1;
      R.Trials_Run := 0;
      R.Best_Trial := 0;
      for I in 1 .. Max_Dim loop
         R.Best_X (I) := 0.0;
      end loop;

      if Cfg.Trials = 0 then
         return R;
      end if;

      Seed_RNG (State, Seed);

      for T in 1 .. Cfg.Trials loop
         case Cfg.Kind is
            when Uniform =>
               X := Sample_Uniform (State, Lo, Hi);
            when Log_Uniform =>
               X := Sample_Log_Uniform
                 (State, Positive_Real (Lo), Positive_Real (Hi));
         end case;
         X := Clamp (X, Lo, Hi);
         F := Objective (X);
         R.Trials_Run := R.Trials_Run + 1;
         if First or else Better (F, R.Best_F, Cfg.Sense_Flag) then
            R.Best_F := F;
            R.Best_X (1) := X;
            R.Best_Trial := T;
            First := False;
         end if;
      end loop;

      return R;
   end Search_1D;

   function Search_ND
     (Objective : Objective_ND;
      B         : Bounds;
      Cfg       : Config;
      Seed      : Natural) return Result
   is
   begin
      if Objective = null
        or else B'Length < 1
        or else B'Length > Max_Dim
      then
         raise Invalid_Argument;
      end if;
      return Run_Search (Objective, B, Cfg, Seed);
   end Search_ND;

   function Minimize
     (Objective : Objective_ND;
      B         : Bounds;
      Trials    : Natural;
      Seed      : Natural;
      Kind      : Sampling_Kind := Uniform) return Result
   is
      Cfg : constant Config :=
        (Trials => Trials, Kind => Kind, Sense_Flag => Minimize_Sense);
   begin
      return Search_ND (Objective, B, Cfg, Seed);
   end Minimize;

   function Maximize
     (Objective : Objective_ND;
      B         : Bounds;
      Trials    : Natural;
      Seed      : Natural;
      Kind      : Sampling_Kind := Uniform) return Result
   is
      Cfg : constant Config :=
        (Trials => Trials, Kind => Kind, Sense_Flag => Maximize_Sense);
   begin
      return Search_ND (Objective, B, Cfg, Seed);
   end Maximize;

   ---------------------------------------------------------------------------
   -- Grid search 2-D
   ---------------------------------------------------------------------------

   function Grid_Search_2D
     (Objective : Objective_ND;
      Bx, By    : Bound;
      Nx, Ny    : Positive;
      Sense_Flag : Sense := Minimize_Sense) return Result
   is
      R      : Result;
      First  : Boolean := True;
      X, Y   : Real;
      F      : Real;
      P      : Point (1 .. 2);
      Dx, Dy : Real;
      Trial  : Natural := 0;
   begin
      if Objective = null
        or else Bx.Lo >= Bx.Hi
        or else By.Lo >= By.Hi
      then
         raise Invalid_Argument;
      end if;

      R.Dim := 2;
      R.Trials_Run := 0;
      R.Best_Trial := 0;
      for I in 1 .. Max_Dim loop
         R.Best_X (I) := 0.0;
      end loop;

      if Nx = 1 then
         Dx := 0.0;
      else
         Dx := (Bx.Hi - Bx.Lo) / Real (Nx - 1);
      end if;
      if Ny = 1 then
         Dy := 0.0;
      else
         Dy := (By.Hi - By.Lo) / Real (Ny - 1);
      end if;

      for I in 0 .. Nx - 1 loop
         if Nx = 1 then
            X := Clamp ((Bx.Lo + Bx.Hi) / 2.0, Bx.Lo, Bx.Hi);
         else
            X := Clamp (Bx.Lo + Real (I) * Dx, Bx.Lo, Bx.Hi);
         end if;
         for J in 0 .. Ny - 1 loop
            if Ny = 1 then
               Y := Clamp ((By.Lo + By.Hi) / 2.0, By.Lo, By.Hi);
            else
               Y := Clamp (By.Lo + Real (J) * Dy, By.Lo, By.Hi);
            end if;
            P (1) := X;
            P (2) := Y;
            F := Objective (P);
            Trial := Trial + 1;
            R.Trials_Run := Trial;
            if First or else Better (F, R.Best_F, Sense_Flag) then
               R.Best_F := F;
               R.Best_X (1) := X;
               R.Best_X (2) := Y;
               R.Best_Trial := Trial;
               First := False;
            end if;
         end loop;
      end loop;

      return R;
   end Grid_Search_2D;

end Random_Search;
