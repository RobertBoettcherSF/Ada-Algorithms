--  Evolution_Strategy — Ada 2023 educational package for Wikipedia
--  "Evolution strategy" (Rechenberg / Schwefel): continuous EA with
--  Gaussian mutation, optional intermediate recombination, deterministic
--  (μ,λ) / (μ+λ) selection, (1+1)-ES with 1/5 success-rule σ adaptation,
--  and log-normal self-adaptive σ for multi-member ES. Unbounded demos.
--  Primary source: https://en.wikipedia.org/wiki/Evolution_strategy
--  Siblings: Ada-Genetic-Algorithms / Ada-Truncation-Selection (README).

pragma Ada_2022;

package Evolution_Strategy
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Dim    : constant := 8;
   Max_Mu     : constant := 40;
   Max_Lambda : constant := 200;

   subtype Dim_Count is Positive range 1 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;
   subtype Mu_Count is Positive range 1 .. Max_Mu;
   subtype Lambda_Count is Positive range 1 .. Max_Lambda;

   type Point is array (Dim_Index range <>) of Real;

   --  Plus  = (μ+λ): select best μ from parents ∪ offspring
   --  Comma = (μ,λ): select best μ from offspring only (requires λ ≥ μ)
   type Selection_Mode is (Plus, Comma);

   --  Mu            : parent population size μ
   --  Lambda        : offspring count λ
   --  Plus_Or_Comma : (μ+λ) vs (μ,λ) selection
   --  Max_Gens      : generation budget (0 → init-only Result)
   --  Seed          : LCG seed for reproducibility
   --  Init_Sigma    : initial mutation step size σ
   --  Recombine     : optional intermediate recombination of two parents
   --  Success_Window: generations for (1+1) 1/5-rule success-rate estimate
   type Config is record
      Mu             : Mu_Count      := 1;
      Lambda         : Lambda_Count  := 1;
      Plus_Or_Comma  : Selection_Mode := Plus;
      Max_Gens       : Natural       := 500;
      Seed           : Natural       := 1;
      Init_Sigma     : Positive_Real := 1.0;
      Recombine      : Boolean       := False;
      Success_Window : Positive      := 10;
   end record;

   --  X       : decision vector (prefix Dim used)
   --  Sigma   : mutation step size σ (self-adapted)
   --  Fitness : objective value (cost; lower is better)
   --  Dim     : active dimension
   type Individual is record
      X       : Point (1 .. Max_Dim) := [others => 0.0];
      Sigma   : Positive_Real        := 1.0;
      Fitness : Real                 := Real'Last;
      Dim     : Dim_Count            := 1;
   end record;

   type Individual_Array is array (Positive range <>) of Individual;

   type Population (Capacity : Positive) is record
      Members : Individual_Array (1 .. Capacity) := [others => <>];
      Size    : Natural   := 0;
      Dim     : Dim_Count := 1;
   end record;

   type Result is record
      Best_Cost   : Real      := 0.0;
      Best_X      : Point (1 .. Max_Dim) := [others => 0.0];
      Best_Sigma  : Real      := 0.0;
      Dim         : Dim_Count := 1;
      Generations : Natural   := 0;
      Evaluations : Natural   := 0;
      Mu_Used     : Natural   := 0;
      Lambda_Used : Natural   := 0;
   end record;

   type Objective_Fn is access function (X : Point) return Real;

   ---------------------------------------------------------------------------
   -- Exceptions / helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Default_Config
     (Mu             : Mu_Count      := 1;
      Lambda         : Lambda_Count  := 1;
      Plus_Or_Comma  : Selection_Mode := Plus;
      Max_Gens       : Natural       := 500;
      Seed           : Natural       := 1;
      Init_Sigma     : Positive_Real := 1.0;
      Recombine      : Boolean       := False;
      Success_Window : Positive      := 10) return Config
     with Global => null;

   function Config_Is_Valid (Cfg : Config) return Boolean
     with Global => null;
   --  True iff λ ≥ μ when Comma (else offspring pool too small), and
   --  Init_Sigma > 0 (enforced by subtype).

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) + Box–Muller normal
   ---------------------------------------------------------------------------

   type RNG_State is mod 2**32;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural)
     with Global => null;

   function Next_Unit (State : in out RNG_State) return Unit_Interval
     with Global => null;
   --  Uniform on [0, 1).

   function Next_Uniform
     (State : in out RNG_State; Lo, Hi : Real) return Real
     with Pre => Lo <= Hi, Global => null;
   --  Uniform on [Lo, Hi].

   function Sample_Normal (State : in out RNG_State) return Real
     with Global => null;
   --  Standard normal N(0,1) via Box–Muller (Marsaglia polar form).

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
     with Pre => Lo <= Hi, Global => null;

   ---------------------------------------------------------------------------
   -- Built-in continuous objectives (unbounded / box-free)
   ---------------------------------------------------------------------------

   function Sphere (X : Point) return Real
     with Global => null;
   --  f(x) = Σ x_i²; unique min 0 at the origin.

   function Rosenbrock (X : Point) return Real
     with Global => null;
   --  Classic banana: f(x,y) = (1−x)² + 100(y−x²)²; min 0 at (1,1).
   --  Uses first two coordinates (requires Dim ≥ 2).

   function Shifted_Sphere (X : Point) return Real
     with Global => null;
   --  f(x) = Σ (x_i − 1)²; unique min 0 at (1,…,1).

   ---------------------------------------------------------------------------
   -- Population / mutation / selection primitives
   ---------------------------------------------------------------------------

   procedure Init_Population
     (Pop       : in out Population;
      Dim       : Dim_Count;
      Cfg       : Config;
      Objective : Objective_Fn;
      State     : in out RNG_State;
      Init_Lo   : Real := -2.0;
      Init_Hi   : Real := 2.0)
     with Pre => Objective /= null
            and then Pop.Capacity >= Natural (Cfg.Mu)
            and then Init_Lo <= Init_Hi
            and then Config_Is_Valid (Cfg),
          Global => null;
   --  Fill Mu parents: x ~ U(Init_Lo, Init_Hi)^Dim, σ ← Init_Sigma,
   --  evaluate Fitness. Sets Pop.Size and Pop.Dim.

   function Mutate
     (Parent : Individual;
      State  : in out RNG_State) return Individual
     with Pre => Parent.Dim >= 1, Global => null;
   --  Offspring with same σ (no self-adapt): x' = x + σ N(0,I).

   function Mutate_Self_Adaptive
     (Parent : Individual;
      State  : in out RNG_State) return Individual
     with Pre => Parent.Dim >= 1, Global => null;
   --  Log-normal σ' = σ · exp((1/√n) N(0,1)), then x' = x + σ' N(0,I).

   function Intermediate_Recombine
     (A, B  : Individual;
      State : in out RNG_State) return Individual
     with Pre => A.Dim = B.Dim and then A.Dim >= 1, Global => null;
   --  Intermediate recombination then self-adaptive mutation:
   --  x ← (x_A+x_B)/2, σ ← (σ_A+σ_B)/2, then Mutate_Self_Adaptive.

   procedure Rank_Ascending (Pop : in out Population)
     with Pre => Pop.Size >= 1, Global => null;
   --  Sort by Fitness ascending (best / lowest cost first). Stable ties.

   function Best_Index (Pop : Population) return Positive
     with Pre => Pop.Size >= 1, Global => null;

   procedure Step_One_Plus_One
     (Parent         : in out Individual;
      Objective      : Objective_Fn;
      State          : in out RNG_State;
      Successes      : in out Natural;
      Trials         : in out Natural;
      Success_Window : Positive;
      Evaluations    : in out Natural)
     with Pre => Parent.Dim >= 1 and then Objective /= null, Global => null;
   --  One (1+1)-ES trial with 1/5 success-rule σ update every Window trials.

   procedure Step_Mu_Lambda
     (Pop       : in out Population;
      Cfg       : Config;
      Objective : Objective_Fn;
      State     : in out RNG_State;
      Evaluations : in out Natural)
     with Pre => Pop.Size >= 1
            and then Natural (Cfg.Mu) = Pop.Size
            and then Objective /= null
            and then Config_Is_Valid (Cfg),
          Global => null;
   --  One (μ,λ) or (μ+λ) generation with optional recombination and
   --  log-normal self-adaptive σ.

   ---------------------------------------------------------------------------
   -- Drivers
   ---------------------------------------------------------------------------

   function Minimize
     (Objective : Objective_Fn;
      Dim       : Dim_Count;
      Cfg       : Config;
      Init_Lo   : Real := -2.0;
      Init_Hi   : Real := 2.0) return Result
     with Pre => Objective /= null
            and then Init_Lo <= Init_Hi
            and then Config_Is_Valid (Cfg),
          Global => null;
   --  Unbounded continuous ES on R^Dim (Dim ≤ Max_Dim). Uses (1+1) path
   --  when Mu=Lambda=1 and Plus; otherwise multi-member (μ,λ)/(μ+λ).

end Evolution_Strategy;
