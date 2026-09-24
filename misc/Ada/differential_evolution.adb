--  Differential_Evolution body — Storn & Price (1995) educational DE:
--  Init_Population, Mutate_Rand1, Binomial_Crossover, Select_Greedy,
--  Step_Generation, Minimize / Maximize / Optimize.

pragma Ada_2022;

with Ada.Numerics;                       use Ada.Numerics;
with Ada.Numerics.Elementary_Functions;  use Ada.Numerics.Elementary_Functions;

package body Differential_Evolution
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

   function Clamp_Vector
     (X : Vector; B : Bounds) return Vector
   is
      Y : Vector (X'Range);
      Bi : Natural := B'First;
   begin
      for I in X'Range loop
         if B (Bi).Lo > B (Bi).Hi then
            raise Invalid_Argument;
         end if;
         Y (I) := Clamp (X (I), B (Bi).Lo, B (Bi).Hi);
         Bi := Bi + 1;
      end loop;
      return Y;
   end Clamp_Vector;

   function Default_Parameters
     (F        : Scale_Factor    := 0.8;
      CR       : Unit_Interval   := 0.9;
      NP       : Population_Size := 20;
      Max_Gen  : Natural         := 200;
      Seed     : Natural         := 1;
      Maximize : Boolean         := False) return Parameters
   is
   begin
      return
        (F        => F,
         CR       => CR,
         NP       => NP,
         Max_Gen  => Max_Gen,
         Seed     => Seed,
         Maximize => Maximize);
   end Default_Parameters;

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

   function Next_Index
     (State : in out RNG_State; Lo, Hi : Positive) return Positive
   is
      Span : constant Natural := Hi - Lo + 1;
      U    : constant Unit_Interval := Next_Unit (State);
      Off  : Natural;
   begin
      Off := Natural (Real (U) * Real (Span));
      if Off >= Span then
         Off := Span - 1;
      end if;
      return Lo + Off;
   end Next_Index;

   ---------------------------------------------------------------------------
   -- Objectives
   ---------------------------------------------------------------------------

   function Sphere (X : Vector) return Real is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + X (I) * X (I);
      end loop;
      return S;
   end Sphere;

   function Rosenbrock (X : Vector) return Real is
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

   function Rastrigin (X : Vector) return Real is
      Two_Pi : constant Float := 2.0 * Float (Pi);
      S      : Real := 10.0 * Real (X'Length);
   begin
      for I in X'Range loop
         declare
            Xi : constant Float := Float (X (I));
         begin
            S := S + X (I) * X (I)
              - 10.0 * Real (Cos (Two_Pi * Xi));
         end;
      end loop;
      return S;
   end Rastrigin;

   function Shifted_Sphere (X : Vector) return Real is
      S : Real := 0.0;
   begin
      for I in X'Range loop
         S := S + (X (I) - 1.0) ** 2;
      end loop;
      return S;
   end Shifted_Sphere;

   function Neg_Sphere (X : Vector) return Real is
   begin
      return -Sphere (X);
   end Neg_Sphere;

   ---------------------------------------------------------------------------
   -- Internal helpers
   ---------------------------------------------------------------------------

   procedure Validate_Bounds (B : Bounds) is
   begin
      for I in B'Range loop
         if B (I).Lo > B (I).Hi then
            raise Invalid_Argument;
         end if;
      end loop;
   end Validate_Bounds;

   function Slice_Vector (P : Vector; Dim : Dimension) return Vector is
      Out_V : Vector (1 .. Dim);
   begin
      for I in 1 .. Dim loop
         Out_V (I) := P (I);
      end loop;
      return Out_V;
   end Slice_Vector;

   function Bound_At (B : Bounds; D : Dimension) return Bound is
   begin
      return B (B'First + D - 1);
   end Bound_At;

   function Eval_Slice
     (Objective : Objective_Fn; P : Vector; Dim : Dimension) return Real
   is
   begin
      return Objective (Slice_Vector (P, Dim));
   end Eval_Slice;

   ---------------------------------------------------------------------------
   -- Init_Population
   ---------------------------------------------------------------------------

   procedure Init_Population
     (Pop       : in out Population;
      B         : Bounds;
      Objective : Objective_Fn;
      State     : in out RNG_State)
   is
      Dim : constant Dimension := Dimension (B'Length);
   begin
      if Objective = null then
         raise Invalid_Argument;
      end if;
      if Pop.Capacity < 4 then
         raise Invalid_Argument;
      end if;
      Validate_Bounds (B);

      Pop.Dim  := Dim;
      Pop.Size := Pop.Capacity;

      for I in 1 .. Pop.Capacity loop
         Pop.Members (I).Dim := Dim;
         for D in 1 .. Dim loop
            declare
               Bd : constant Bound := Bound_At (B, D);
            begin
               Pop.Members (I).X (D) :=
                 Next_Uniform (State, Bd.Lo, Bd.Hi);
            end;
         end loop;
         for D in Dim + 1 .. Max_Dim loop
            Pop.Members (I).X (D) := 0.0;
         end loop;
         Pop.Members (I).Cost :=
           Eval_Slice (Objective, Pop.Members (I).X, Dim);
      end loop;
   end Init_Population;

   ---------------------------------------------------------------------------
   -- Mutate_Rand1
   ---------------------------------------------------------------------------

   function Mutate_Rand1
     (Base, Diff1, Diff2 : Vector;
      F                  : Scale_Factor;
      B                  : Bounds) return Vector
   is
      V  : Vector (Base'Range);
      Bi : Natural := B'First;
      B0 : Natural := Base'First;
      D1 : Natural := Diff1'First;
      D2 : Natural := Diff2'First;
   begin
      for I in Base'Range loop
         V (I) := Base (B0)
           + Real (F) * (Diff1 (D1) - Diff2 (D2));
         V (I) := Clamp (V (I), B (Bi).Lo, B (Bi).Hi);
         B0 := B0 + 1;
         D1 := D1 + 1;
         D2 := D2 + 1;
         Bi := Bi + 1;
      end loop;
      return V;
   end Mutate_Rand1;

   ---------------------------------------------------------------------------
   -- Binomial_Crossover
   ---------------------------------------------------------------------------

   function Binomial_Crossover
     (Target, Mutant : Vector;
      CR             : Unit_Interval;
      J_Rand         : Dim_Index;
      State          : in out RNG_State) return Vector
   is
      U  : Vector (Target'Range);
      Ti : Natural := Target'First;
      Mi : Natural := Mutant'First;
      J  : Dim_Index;
   begin
      for I in Target'Range loop
         J := Dim_Index (I - Target'First + 1);
         if J = J_Rand or else Next_Unit (State) < CR then
            U (I) := Mutant (Mi);
         else
            U (I) := Target (Ti);
         end if;
         Ti := Ti + 1;
         Mi := Mi + 1;
      end loop;
      return U;
   end Binomial_Crossover;

   ---------------------------------------------------------------------------
   -- Selection helpers
   ---------------------------------------------------------------------------

   function Better
     (Trial_Cost, Target_Cost : Real; Maximize : Boolean) return Boolean
   is
   begin
      if Maximize then
         return Trial_Cost > Target_Cost;
      else
         return Trial_Cost < Target_Cost;
      end if;
   end Better;

   procedure Select_Greedy
     (Target      : in out Agent;
      Trial_X     : Vector;
      Trial_Cost  : Real;
      Maximize    : Boolean)
   is
      Ti : Natural := Trial_X'First;
   begin
      if Better (Trial_Cost, Target.Cost, Maximize) then
         for D in 1 .. Target.Dim loop
            Target.X (D) := Trial_X (Ti);
            Ti := Ti + 1;
         end loop;
         Target.Cost := Trial_Cost;
      end if;
   end Select_Greedy;

   function Best_Agent_Index (Pop : Population) return Positive is
      Best : Positive := 1;
   begin
      for I in 2 .. Pop.Size loop
         if Pop.Members (I).Cost < Pop.Members (Best).Cost then
            Best := I;
         end if;
      end loop;
      return Best;
   end Best_Agent_Index;

   function Best_Agent_Index_Sense
     (Pop : Population; Maximize : Boolean) return Positive
   is
      Best : Positive := 1;
   begin
      for I in 2 .. Pop.Size loop
         if Better
              (Pop.Members (I).Cost, Pop.Members (Best).Cost, Maximize)
         then
            Best := I;
         end if;
      end loop;
      return Best;
   end Best_Agent_Index_Sense;

   ---------------------------------------------------------------------------
   -- Pick three distinct indices ≠ Target_Idx in 1 .. Size
   ---------------------------------------------------------------------------

   procedure Pick_Three_Distinct
     (State      : in out RNG_State;
      Size       : Positive;
      Target_Idx : Positive;
      R1, R2, R3 : out Positive)
   is
      function Pick_One (Exclude1, Exclude2, Exclude3 : Natural)
        return Positive
      is
         Cand : Positive;
         Guard : Natural := 0;
      begin
         loop
            Cand := Next_Index (State, 1, Size);
            Guard := Guard + 1;
            exit when Cand /= Target_Idx
              and then Cand /= Exclude1
              and then Cand /= Exclude2
              and then Cand /= Exclude3;
            if Guard > 10_000 then
               raise Invalid_Argument;
            end if;
         end loop;
         return Cand;
      end Pick_One;
   begin
      if Size < 4 then
         raise Invalid_Argument;
      end if;
      R1 := Pick_One (0, 0, 0);
      R2 := Pick_One (R1, 0, 0);
      R3 := Pick_One (R1, R2, 0);
   end Pick_Three_Distinct;

   ---------------------------------------------------------------------------
   -- Step_Generation
   ---------------------------------------------------------------------------

   procedure Step_Generation
     (Pop       : in out Population;
      B         : Bounds;
      Params    : Parameters;
      Objective : Objective_Fn;
      State     : in out RNG_State)
   is
      Dim    : constant Dimension := Pop.Dim;
      Active : constant Positive  := Pop.Size;
      R1, R2, R3 : Positive;
      J_Rand     : Dim_Index;
      Mutant     : Vector (1 .. Dim);
      Trial      : Vector (1 .. Dim);
      Trial_Cost : Real;
      Base_V, D1_V, D2_V, Target_V : Vector (1 .. Dim);
   begin
      if Objective = null then
         raise Invalid_Argument;
      end if;
      if Active < 4 then
         raise Invalid_Argument;
      end if;
      Validate_Bounds (B);

      for I in 1 .. Active loop
         Pick_Three_Distinct (State, Active, I, R1, R2, R3);

         for D in 1 .. Dim loop
            Base_V (D)   := Pop.Members (R1).X (D);
            D1_V (D)     := Pop.Members (R2).X (D);
            D2_V (D)     := Pop.Members (R3).X (D);
            Target_V (D) := Pop.Members (I).X (D);
         end loop;

         Mutant := Mutate_Rand1 (Base_V, D1_V, D2_V, Params.F, B);
         J_Rand := Dim_Index (Next_Index (State, 1, Positive (Dim)));
         Trial  := Binomial_Crossover
           (Target_V, Mutant, Params.CR, J_Rand, State);
         Trial_Cost := Objective (Trial);

         Select_Greedy
           (Pop.Members (I), Trial, Trial_Cost, Params.Maximize);
      end loop;
   end Step_Generation;

   ---------------------------------------------------------------------------
   -- Drivers
   ---------------------------------------------------------------------------

   function Run_DE
     (Objective : Objective_Fn;
      B         : Bounds;
      Params    : Parameters;
      Force_Max : Boolean;
      Force_Min : Boolean) return Result
   is
      Dim    : constant Dimension := Dimension (B'Length);
      NP     : constant Population_Size := Params.NP;
      Pop    : Population (Capacity => NP);
      State  : RNG_State;
      P      : Parameters := Params;
      R      : Result;
      Best_I : Positive;
   begin
      if Objective = null then
         raise Invalid_Argument;
      end if;
      Validate_Bounds (B);

      if Force_Max then
         P.Maximize := True;
      elsif Force_Min then
         P.Maximize := False;
      end if;

      Seed_RNG (State, P.Seed);
      Init_Population (Pop, B, Objective, State);

      for Gen in 1 .. P.Max_Gen loop
         Step_Generation (Pop, B, P, Objective, State);
      end loop;

      Best_I := Best_Agent_Index_Sense (Pop, P.Maximize);
      R.Best_Cost   := Pop.Members (Best_I).Cost;
      R.Dim         := Dim;
      R.Generations := P.Max_Gen;
      R.NP_Used     := NP;
      for D in 1 .. Dim loop
         R.Best_X (D) := Pop.Members (Best_I).X (D);
      end loop;
      for D in Dim + 1 .. Max_Dim loop
         R.Best_X (D) := 0.0;
      end loop;
      return R;
   end Run_DE;

   function Minimize
     (Objective : Objective_Fn;
      B         : Bounds;
      Params    : Parameters) return Result
   is
   begin
      return Run_DE (Objective, B, Params, Force_Max => False,
                     Force_Min => True);
   end Minimize;

   function Maximize
     (Objective : Objective_Fn;
      B         : Bounds;
      Params    : Parameters) return Result
   is
   begin
      return Run_DE (Objective, B, Params, Force_Max => True,
                     Force_Min => False);
   end Maximize;

   function Optimize
     (Objective : Objective_Fn;
      B         : Bounds;
      Params    : Parameters) return Result
   is
   begin
      return Run_DE (Objective, B, Params, Force_Max => False,
                     Force_Min => False);
   end Optimize;

end Differential_Evolution;
