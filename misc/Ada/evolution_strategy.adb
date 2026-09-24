--  Evolution_Strategy body — (1+1)-ES with 1/5 rule; (μ,λ)/(μ+λ)-ES
--  with Gaussian mutation, optional intermediate recombination, and
--  log-normal self-adaptive σ. Unbounded Sphere / Rosenbrock demos.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;

package body Evolution_Strategy
  with SPARK_Mode => Off
is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Default_Config
     (Mu             : Mu_Count      := 1;
      Lambda         : Lambda_Count  := 1;
      Plus_Or_Comma  : Selection_Mode := Plus;
      Max_Gens       : Natural       := 500;
      Seed           : Natural       := 1;
      Init_Sigma     : Positive_Real := 1.0;
      Recombine      : Boolean       := False;
      Success_Window : Positive      := 10) return Config
   is
   begin
      return
        (Mu             => Mu,
         Lambda         => Lambda,
         Plus_Or_Comma  => Plus_Or_Comma,
         Max_Gens       => Max_Gens,
         Seed           => Seed,
         Init_Sigma     => Init_Sigma,
         Recombine      => Recombine,
         Success_Window => Success_Window);
   end Default_Config;

   function Config_Is_Valid (Cfg : Config) return Boolean is
   begin
      if Cfg.Plus_Or_Comma = Comma
        and then Natural (Cfg.Lambda) < Natural (Cfg.Mu)
      then
         return False;
      end if;
      return True;
   end Config_Is_Valid;

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
      Span : constant Natural := Hi - Lo;
      U    : Unit_Interval;
      Idx  : Natural;
   begin
      if Span = 0 then
         return Lo;
      end if;
      U := Next_Unit (State);
      Idx := Natural (Real (U) * Real (Span + 1));
      if Idx > Span then
         Idx := Span;
      end if;
      return Lo + Idx;
   end Next_Natural;

   function Sample_Normal (State : in out RNG_State) return Real is
      --  Marsaglia polar Box–Muller: N(0,1) from uniforms on the unit
      --  disk. The paired second sample is discarded so State alone
      --  owns the stream (no package-level spare).
      U, V, S, Mul : Real;
   begin
      loop
         U := 2.0 * Real (Next_Unit (State)) - 1.0;
         V := 2.0 * Real (Next_Unit (State)) - 1.0;
         S := U * U + V * V;
         exit when S > 0.0 and then S < 1.0;
      end loop;

      Mul := Math.Sqrt (-2.0 * Math.Log (S) / S);
      return U * Mul;
   end Sample_Normal;

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
   -- Internal helpers
   ---------------------------------------------------------------------------

   function Slice_Point (P : Point; Dim : Dim_Count) return Point is
      Out_P : Point (1 .. Dim);
   begin
      for I in 1 .. Dim loop
         Out_P (I) := P (I);
      end loop;
      return Out_P;
   end Slice_Point;

   function Eval
     (Objective : Objective_Fn;
      Ind       : Individual) return Real
   is
      X : constant Point := Slice_Point (Ind.X, Ind.Dim);
   begin
      return Objective (X);
   end Eval;

   function Clamp_Sigma (S : Real) return Positive_Real is
      Floor : constant Real := 1.0E-12;
      Cap   : constant Real := 1.0E6;
   begin
      if S < Floor then
         return Positive_Real (Floor);
      elsif S > Cap then
         return Positive_Real (Cap);
      else
         return Positive_Real (S);
      end if;
   end Clamp_Sigma;

   function Learning_Rate (Dim : Dim_Count) return Real is
   begin
      --  Classical global learning rate 1/√n for single σ.
      return 1.0 / Math.Sqrt (Real (Dim));
   end Learning_Rate;

   ---------------------------------------------------------------------------
   -- Mutation / recombination
   ---------------------------------------------------------------------------

   function Mutate
     (Parent : Individual;
      State  : in out RNG_State) return Individual
   is
      Child : Individual := Parent;
   begin
      for I in 1 .. Parent.Dim loop
         Child.X (I) := Parent.X (I)
           + Real (Parent.Sigma) * Sample_Normal (State);
      end loop;
      Child.Fitness := Real'Last;
      return Child;
   end Mutate;

   function Mutate_Self_Adaptive
     (Parent : Individual;
      State  : in out RNG_State) return Individual
   is
      Child : Individual := Parent;
      Tau   : constant Real := Learning_Rate (Parent.Dim);
      Factor : Real;
   begin
      Factor := Math.Exp (Tau * Sample_Normal (State));
      Child.Sigma := Clamp_Sigma (Real (Parent.Sigma) * Factor);
      for I in 1 .. Parent.Dim loop
         Child.X (I) := Parent.X (I)
           + Real (Child.Sigma) * Sample_Normal (State);
      end loop;
      Child.Fitness := Real'Last;
      return Child;
   end Mutate_Self_Adaptive;

   function Intermediate_Recombine
     (A, B  : Individual;
      State : in out RNG_State) return Individual
   is
      Mid : Individual := A;
   begin
      Mid.Dim := A.Dim;
      for I in 1 .. A.Dim loop
         Mid.X (I) := 0.5 * (A.X (I) + B.X (I));
      end loop;
      Mid.Sigma := Clamp_Sigma (0.5 * (Real (A.Sigma) + Real (B.Sigma)));
      Mid.Fitness := Real'Last;
      return Mutate_Self_Adaptive (Mid, State);
   end Intermediate_Recombine;

   ---------------------------------------------------------------------------
   -- Ranking / best
   ---------------------------------------------------------------------------

   procedure Rank_Ascending (Pop : in out Population) is
      --  Stable insertion sort by Fitness (ascending).
      Key : Individual;
      J   : Natural;
   begin
      for I in 2 .. Pop.Size loop
         Key := Pop.Members (I);
         J := I - 1;
         while J >= 1
           and then Pop.Members (J).Fitness > Key.Fitness
         loop
            Pop.Members (J + 1) := Pop.Members (J);
            J := J - 1;
         end loop;
         Pop.Members (J + 1) := Key;
      end loop;
   end Rank_Ascending;

   function Best_Index (Pop : Population) return Positive is
      Best : Positive := 1;
   begin
      for I in 2 .. Pop.Size loop
         if Pop.Members (I).Fitness < Pop.Members (Best).Fitness then
            Best := I;
         end if;
      end loop;
      return Best;
   end Best_Index;

   ---------------------------------------------------------------------------
   -- Init
   ---------------------------------------------------------------------------

   procedure Init_Population
     (Pop       : in out Population;
      Dim       : Dim_Count;
      Cfg       : Config;
      Objective : Objective_Fn;
      State     : in out RNG_State;
      Init_Lo   : Real := -2.0;
      Init_Hi   : Real := 2.0)
   is
      Ind : Individual;
   begin
      if not Config_Is_Valid (Cfg) then
         raise Invalid_Argument;
      end if;
      if Objective = null then
         raise Invalid_Argument;
      end if;
      if Init_Lo > Init_Hi then
         raise Invalid_Argument;
      end if;
      if Pop.Capacity < Natural (Cfg.Mu) then
         raise Invalid_Argument;
      end if;

      Pop.Dim := Dim;
      Pop.Size := Natural (Cfg.Mu);

      for K in 1 .. Pop.Size loop
         Ind.Dim := Dim;
         Ind.Sigma := Cfg.Init_Sigma;
         for D in 1 .. Dim loop
            Ind.X (D) := Next_Uniform (State, Init_Lo, Init_Hi);
         end loop;
         for D in Dim + 1 .. Max_Dim loop
            Ind.X (D) := 0.0;
         end loop;
         Ind.Fitness := Eval (Objective, Ind);
         Pop.Members (K) := Ind;
      end loop;
   end Init_Population;

   ---------------------------------------------------------------------------
   -- (1+1)-ES with 1/5 success rule
   ---------------------------------------------------------------------------

   Success_Factor : constant Real := 0.82;
   --  Classical Rechenberg factor ≈ 0.817 ≈ e^{−1/√n} for small n;
   --  educational constant used for both increase (1/c) and decrease (c).

   procedure Step_One_Plus_One
     (Parent         : in out Individual;
      Objective      : Objective_Fn;
      State          : in out RNG_State;
      Successes      : in out Natural;
      Trials         : in out Natural;
      Success_Window : Positive;
      Evaluations    : in out Natural)
   is
      Child : Individual;
      Rate  : Real;
   begin
      if Objective = null then
         raise Invalid_Argument;
      end if;

      Child := Mutate (Parent, State);
      Child.Fitness := Eval (Objective, Child);
      Evaluations := Evaluations + 1;
      Trials := Trials + 1;

      if Child.Fitness <= Parent.Fitness then
         Parent := Child;
         Successes := Successes + 1;
      end if;

      if Trials >= Success_Window then
         Rate := Real (Successes) / Real (Trials);
         if Rate > 0.2 then
            Parent.Sigma :=
              Clamp_Sigma (Real (Parent.Sigma) / Success_Factor);
         elsif Rate < 0.2 then
            Parent.Sigma :=
              Clamp_Sigma (Real (Parent.Sigma) * Success_Factor);
         end if;
         --  Rate = 0.2 → leave σ unchanged.
         Successes := 0;
         Trials := 0;
      end if;
   end Step_One_Plus_One;

   ---------------------------------------------------------------------------
   -- (μ,λ) / (μ+λ) generation
   ---------------------------------------------------------------------------

   procedure Step_Mu_Lambda
     (Pop         : in out Population;
      Cfg         : Config;
      Objective   : Objective_Fn;
      State       : in out RNG_State;
      Evaluations : in out Natural)
   is
      Lambda_N : constant Positive := Positive (Cfg.Lambda);
      Mu_N     : constant Positive := Positive (Cfg.Mu);
      Offspring : Individual_Array (1 .. Lambda_N);
      Pool_Size : Positive;
      Pool      : Individual_Array (1 .. Mu_N + Lambda_N);
      Ia, Ib    : Positive;
      Child     : Individual;
   begin
      if not Config_Is_Valid (Cfg) then
         raise Invalid_Argument;
      end if;
      if Objective = null then
         raise Invalid_Argument;
      end if;
      if Pop.Size /= Natural (Cfg.Mu) then
         raise Invalid_Argument;
      end if;

      for K in 1 .. Lambda_N loop
         if Cfg.Recombine and then Mu_N >= 2 then
            Ia := Next_Natural (State, 1, Mu_N);
            Ib := Next_Natural (State, 1, Mu_N);
            Child := Intermediate_Recombine
              (Pop.Members (Ia), Pop.Members (Ib), State);
         else
            Ia := Next_Natural (State, 1, Mu_N);
            Child := Mutate_Self_Adaptive (Pop.Members (Ia), State);
         end if;
         Child.Fitness := Eval (Objective, Child);
         Evaluations := Evaluations + 1;
         Offspring (K) := Child;
      end loop;

      case Cfg.Plus_Or_Comma is
         when Comma =>
            Pool_Size := Lambda_N;
            for K in 1 .. Lambda_N loop
               Pool (K) := Offspring (K);
            end loop;
         when Plus =>
            Pool_Size := Mu_N + Lambda_N;
            for K in 1 .. Mu_N loop
               Pool (K) := Pop.Members (K);
            end loop;
            for K in 1 .. Lambda_N loop
               Pool (Mu_N + K) := Offspring (K);
            end loop;
      end case;

      --  Select best Mu from Pool (partial selection via insertion of top).
      declare
         Work : Population (Pool_Size);
      begin
         Work.Size := Pool_Size;
         Work.Dim := Pop.Dim;
         for K in 1 .. Pool_Size loop
            Work.Members (K) := Pool (K);
         end loop;
         Rank_Ascending (Work);
         for K in 1 .. Mu_N loop
            Pop.Members (K) := Work.Members (K);
         end loop;
         Pop.Size := Mu_N;
      end;
   end Step_Mu_Lambda;

   ---------------------------------------------------------------------------
   -- Driver
   ---------------------------------------------------------------------------

   function Minimize
     (Objective : Objective_Fn;
      Dim       : Dim_Count;
      Cfg       : Config;
      Init_Lo   : Real := -2.0;
      Init_Hi   : Real := 2.0) return Result
   is
      State       : RNG_State;
      R           : Result;
      Evaluations : Natural := 0;
      One_Plus_One : Boolean;
   begin
      if not Config_Is_Valid (Cfg) then
         raise Invalid_Argument;
      end if;
      if Objective = null then
         raise Invalid_Argument;
      end if;
      if Init_Lo > Init_Hi then
         raise Invalid_Argument;
      end if;

      Seed_RNG (State, Cfg.Seed);
      One_Plus_One :=
        Cfg.Mu = 1 and then Cfg.Lambda = 1
        and then Cfg.Plus_Or_Comma = Plus;

      if One_Plus_One then
         declare
            Parent     : Individual;
            Successes  : Natural := 0;
            Trials     : Natural := 0;
            Pop        : Population (1);
         begin
            Init_Population
              (Pop, Dim, Cfg, Objective, State, Init_Lo, Init_Hi);
            Parent := Pop.Members (1);
            Evaluations := 1;

            for G in 1 .. Cfg.Max_Gens loop
               Step_One_Plus_One
                 (Parent, Objective, State, Successes, Trials,
                  Cfg.Success_Window, Evaluations);
            end loop;

            R.Best_Cost := Parent.Fitness;
            R.Best_X := Parent.X;
            R.Best_Sigma := Real (Parent.Sigma);
            R.Dim := Dim;
            R.Generations := Cfg.Max_Gens;
            R.Evaluations := Evaluations;
            R.Mu_Used := 1;
            R.Lambda_Used := 1;
         end;
      else
         declare
            Pop  : Population (Positive (Cfg.Mu));
            Bi   : Positive;
            Best : Individual;
         begin
            Init_Population
              (Pop, Dim, Cfg, Objective, State, Init_Lo, Init_Hi);
            Evaluations := Natural (Cfg.Mu);
            Bi := Best_Index (Pop);
            Best := Pop.Members (Bi);

            for G in 1 .. Cfg.Max_Gens loop
               Step_Mu_Lambda (Pop, Cfg, Objective, State, Evaluations);
               Bi := Best_Index (Pop);
               if Pop.Members (Bi).Fitness < Best.Fitness then
                  Best := Pop.Members (Bi);
               end if;
            end loop;

            --  After comma selection the elite may not be in Pop; keep Best.
            if Cfg.Plus_Or_Comma = Plus then
               Bi := Best_Index (Pop);
               Best := Pop.Members (Bi);
            end if;

            R.Best_Cost := Best.Fitness;
            R.Best_X := Best.X;
            R.Best_Sigma := Real (Best.Sigma);
            R.Dim := Dim;
            R.Generations := Cfg.Max_Gens;
            R.Evaluations := Evaluations;
            R.Mu_Used := Natural (Cfg.Mu);
            R.Lambda_Used := Natural (Cfg.Lambda);
         end;
      end if;

      return R;
   end Minimize;

end Evolution_Strategy;
