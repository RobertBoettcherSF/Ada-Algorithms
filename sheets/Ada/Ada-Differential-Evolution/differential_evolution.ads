--  Differential_Evolution — Ada 2023 educational package for Wikipedia
--  "Differential evolution" (DE; Storn & Price, 1995): population-based
--  metaheuristic for continuous box search. Classic DE/rand/1/bin:
--  mutant = x_r1 + F*(x_r2 − x_r3), binomial crossover with CR and j_rand,
--  greedy selection. No gradients required; no optimality guarantee.
--  Primary source: https://en.wikipedia.org/wiki/Differential_evolution
--  Siblings (README links): Ada-Evolutionary-Computation /
--  Ada-Genetic-Algorithms / Ada-Evolution-Strategy / Ada-Particle-Swarm /
--  Ada-Memetic-Algorithm.

pragma Ada_2022;

package Differential_Evolution
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   --  Differential weight F typically in [0, 2]
   subtype Scale_Factor is Real range 0.0 .. 2.0;

   Max_Dim : constant := 8;
   Max_NP  : constant := 64;

   subtype Dimension is Positive range 1 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;
   subtype Population_Size is Positive range 4 .. Max_NP;
   --  NP ≥ 4: target plus three distinct donors for DE/rand/1.

   type Vector is array (Dim_Index range <>) of Real;

   type Bound is record
      Lo : Real := -1.0;
      Hi : Real := 1.0;
   end record;

   type Bounds is array (Dim_Index range <>) of Bound;

   --  F       : differential weight (scale factor)
   --  CR      : binomial crossover probability
   --  NP      : population size
   --  Max_Gen : generation budget (0 → init-only Result)
   --  Seed    : LCG seed for reproducibility
   --  Maximize: True → maximize f (else minimize)
   type Parameters is record
      F        : Scale_Factor    := 0.8;
      CR       : Unit_Interval   := 0.9;
      NP       : Population_Size := 20;
      Max_Gen  : Natural         := 200;
      Seed     : Natural         := 1;
      Maximize : Boolean         := False;
   end record;

   type Result is record
      Best_Cost  : Real      := 0.0;
      Best_X     : Vector (1 .. Max_Dim) := [others => 0.0];
      Dim        : Dimension := 1;
      Generations : Natural  := 0;
      NP_Used    : Natural   := 0;
   end record;

   type Objective_Fn is access function (X : Vector) return Real;

   ---------------------------------------------------------------------------
   -- Population state
   ---------------------------------------------------------------------------

   type Agent is record
      X    : Vector (1 .. Max_Dim) := [others => 0.0];
      Cost : Real                  := Real'Last;
      Dim  : Dimension             := 1;
   end record;

   type Agent_Array is array (Positive range <>) of Agent;

   type Population (Capacity : Positive) is record
      Members : Agent_Array (1 .. Capacity) := [others => <>];
      Size    : Natural   := 0;
      Dim     : Dimension := 1;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions / helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Clamp (X, Lo, Hi : Real) return Real
     with Global => null;

   function Clamp_Vector
     (X : Vector; B : Bounds) return Vector
     with Pre => X'Length = B'Length
            and then X'Length >= 1
            and then X'Length <= Max_Dim,
          Global => null;

   function Default_Parameters
     (F        : Scale_Factor    := 0.8;
      CR       : Unit_Interval   := 0.9;
      NP       : Population_Size := 20;
      Max_Gen  : Natural         := 200;
      Seed     : Natural         := 1;
      Maximize : Boolean         := False) return Parameters
     with Global => null;

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) for reproducible DE
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

   function Next_Index
     (State : in out RNG_State; Lo, Hi : Positive) return Positive
     with Pre => Lo <= Hi, Global => null;
   --  Uniform integer index in [Lo, Hi].

   ---------------------------------------------------------------------------
   -- Built-in continuous objectives (minimize)
   ---------------------------------------------------------------------------

   function Sphere (X : Vector) return Real
     with Global => null;
   --  f(x) = Σ x_i²; unique min 0 at the origin.

   function Rosenbrock (X : Vector) return Real
     with Global => null;
   --  Classic banana: f(x,y) = (1−x)² + 100(y−x²)²; min 0 at (1,1).
   --  Uses first two coordinates (requires Dim ≥ 2).

   function Rastrigin (X : Vector) return Real
     with Global => null;
   --  f(x) = 10n + Σ (x_i² − 10 cos(2π x_i)); min 0 at origin.
   --  Highly multimodal; educational toy for small D.

   function Shifted_Sphere (X : Vector) return Real
     with Global => null;
   --  f(x) = Σ (x_i − 1)²; unique min 0 at (1,…,1).

   function Neg_Sphere (X : Vector) return Real
     with Global => null;
   --  f(x) = −Σ x_i²; unique max 0 at the origin (for Maximize demos).

   ---------------------------------------------------------------------------
   -- DE/rand/1/bin primitives
   ---------------------------------------------------------------------------

   procedure Init_Population
     (Pop       : in out Population;
      B         : Bounds;
      Objective : Objective_Fn;
      State     : in out RNG_State)
     with Pre => B'Length >= 1
            and then B'Length <= Max_Dim
            and then Objective /= null
            and then Pop.Capacity >= 4,
          Global => null;
   --  Fill Capacity agents: x ~ U(box), evaluate costs. Sets Size and Dim.

   function Mutate_Rand1
     (Base, Diff1, Diff2 : Vector;
      F                  : Scale_Factor;
      B                  : Bounds) return Vector
     with Pre => Base'Length = Diff1'Length
            and then Base'Length = Diff2'Length
            and then Base'Length = B'Length
            and then Base'Length >= 1
            and then Base'Length <= Max_Dim,
          Global => null;
   --  v = base + F*(diff1 − diff2), then clamp each coordinate to box.

   function Binomial_Crossover
     (Target, Mutant : Vector;
      CR             : Unit_Interval;
      J_Rand         : Dim_Index;
      State          : in out RNG_State) return Vector
     with Pre => Target'Length = Mutant'Length
            and then Target'Length >= 1
            and then Target'Length <= Max_Dim
            and then J_Rand <= Target'Length,
          Global => null;
   --  Trial u_j = mutant_j if r_j < CR or j = j_rand, else target_j.
   --  Guarantees at least dimension j_rand is taken from the mutant.

   function Better
     (Trial_Cost, Target_Cost : Real; Maximize : Boolean) return Boolean
     with Global => null;
   --  True iff trial should replace target under min/max sense.

   procedure Select_Greedy
     (Target      : in out Agent;
      Trial_X     : Vector;
      Trial_Cost  : Real;
      Maximize    : Boolean)
     with Pre => Trial_X'Length = Natural (Target.Dim)
            and then Target.Dim >= 1,
          Global => null;
   --  Replace Target if Trial is better (minimize by default).

   function Best_Agent_Index (Pop : Population) return Positive
     with Pre => Pop.Size >= 1, Global => null;
   --  Index of agent with best cost under minimization (ties: first).
   --  Note: stored Cost is always the raw objective; Maximize flips
   --  comparison only in selection / driver ranking.

   procedure Step_Generation
     (Pop       : in out Population;
      B         : Bounds;
      Params    : Parameters;
      Objective : Objective_Fn;
      State     : in out RNG_State)
     with Pre => Pop.Size >= 4
            and then B'Length = Natural (Pop.Dim)
            and then B'Length >= 1
            and then B'Length <= Max_Dim
            and then Objective /= null
            and then Params.NP <= Pop.Size,
          Global => null;
   --  One DE/rand/1/bin generation over agents 1 .. Pop.Size
   --  (Params.NP is advisory; Size is the active count).

   ---------------------------------------------------------------------------
   -- Drivers
   ---------------------------------------------------------------------------

   function Minimize
     (Objective : Objective_Fn;
      B         : Bounds;
      Params    : Parameters) return Result
     with Pre => B'Length >= 1
            and then B'Length <= Max_Dim
            and then Objective /= null,
          Global => null;
   --  Minimize f on box (forces Maximize := False regardless of Params).

   function Maximize
     (Objective : Objective_Fn;
      B         : Bounds;
      Params    : Parameters) return Result
     with Pre => B'Length >= 1
            and then B'Length <= Max_Dim
            and then Objective /= null,
          Global => null;
   --  Maximize f on box (forces Maximize := True).

   function Optimize
     (Objective : Objective_Fn;
      B         : Bounds;
      Params    : Parameters) return Result
     with Pre => B'Length >= 1
            and then B'Length <= Max_Dim
            and then Objective /= null,
          Global => null;
   --  Run DE using Params.Maximize flag.

end Differential_Evolution;
