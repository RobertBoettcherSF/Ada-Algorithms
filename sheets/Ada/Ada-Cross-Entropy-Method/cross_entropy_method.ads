--  Cross_Entropy_Method — Ada 2023 educational package for Wikipedia
--  "Cross-entropy method" (Rubinstein CE): Monte Carlo importance sampling
--  and optimization. Continuous path: independent (diagonal) Gaussian
--  sampling, elite ρ-quantile update of (μ, σ), optional smoothing α and
--  σ floor. Optional Bernoulli sketch for tiny combinatorial toys.
--  Primary source: https://en.wikipedia.org/wiki/Cross-entropy_method
--  Siblings (README links): Ada-Differential-Evolution /
--  Ada-Evolutionary-Computation / Ada-Particle-Swarm /
--  Ada-Genetic-Algorithms.

pragma Ada_2022;

package Cross_Entropy_Method
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   --  Elite quantile ρ typically in (0, 1]; keep open at 0 via subtype use.
   subtype Elite_Fraction is Real range 0.01 .. 1.0;
   --  Smoothing α in [0, 1]: 1 = full elite update, 0 = freeze.
   subtype Smooth_Factor is Unit_Interval;

   Max_Dim : constant := 8;
   Max_N   : constant := 256;

   subtype Dimension is Positive range 1 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;
   subtype Sample_Size is Positive range 2 .. Max_N;
   --  N ≥ 2 so elite set can be at least one while leaving non-elites.

   type Vector is array (Dim_Index range <>) of Real;

   --  Independent (diagonal) Gaussian parameters per dimension.
   type Gaussian_Params is record
      Means : Vector (1 .. Max_Dim) := [others => 0.0];
      Stds  : Vector (1 .. Max_Dim) := [others => 1.0];
      Dim   : Dimension             := 1;
   end record;

   --  N         : sample size per iteration
   --  Rho       : elite quantile (top ρ fraction for minimization)
   --  Alpha     : smoothing for μ / σ updates
   --  Max_Iter  : outer iteration budget (0 → init-only Result)
   --  Seed      : LCG seed for reproducibility
   --  Sigma_Min : floor on each σ to avoid collapse
   type Parameters is record
      N         : Sample_Size    := 100;
      Rho       : Elite_Fraction := 0.1;
      Alpha     : Smooth_Factor  := 0.7;
      Max_Iter  : Natural        := 100;
      Seed      : Natural        := 1;
      Sigma_Min : Non_Negative   := 1.0E-6;
   end record;

   type Result is record
      Best_Cost    : Real      := 0.0;
      Best_X       : Vector (1 .. Max_Dim) := [others => 0.0];
      Dim          : Dimension := 1;
      Iterations   : Natural   := 0;
      Samples_Used : Natural   := 0;
      Final_Mean   : Vector (1 .. Max_Dim) := [others => 0.0];
      Final_Std    : Vector (1 .. Max_Dim) := [others => 0.0];
   end record;

   type Objective_Fn is access function (X : Vector) return Real;

   ---------------------------------------------------------------------------
   -- Sample buffer (one CE iteration's candidates)
   ---------------------------------------------------------------------------

   type Candidate is record
      X    : Vector (1 .. Max_Dim) := [others => 0.0];
      Cost : Real                  := Real'Last;
      Dim  : Dimension             := 1;
   end record;

   type Candidate_Array is array (Positive range <>) of Candidate;

   type Sample_Buffer (Capacity : Positive) is record
      Members : Candidate_Array (1 .. Capacity) := [others => <>];
      Size    : Natural   := 0;
      Dim     : Dimension := 1;
   end record;

   type Index_List is array (Positive range <>) of Positive;

   ---------------------------------------------------------------------------
   -- Optional Bernoulli (discrete) sketch — tiny combinatorial toys
   ---------------------------------------------------------------------------

   type Bernoulli_Params is record
      Probs : Vector (1 .. Max_Dim) := [others => 0.5];
      Dim   : Dimension             := 1;
   end record;

   type Bit_Vector is array (Dim_Index range <>) of Boolean;

   ---------------------------------------------------------------------------
   -- Exceptions / helpers
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Clamp (X, Lo, Hi : Real) return Real
     with Global => null;

   function Elite_Count (N : Sample_Size; Rho : Elite_Fraction) return Positive
     with Pre => N >= 2,
          Post => Elite_Count'Result >= 1
             and then Elite_Count'Result <= N,
          Global => null;
   --  Ne = max(1, floor(ρ · N)), capped at N.

   function Default_Parameters
     (N         : Sample_Size    := 100;
      Rho       : Elite_Fraction := 0.1;
      Alpha     : Smooth_Factor  := 0.7;
      Max_Iter  : Natural        := 100;
      Seed      : Natural        := 1;
      Sigma_Min : Non_Negative   := 1.0E-6) return Parameters
     with Global => null;

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) + Box–Muller Gaussian
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

   function Next_Gaussian
     (State : in out RNG_State; Mean, Std : Real) return Real
     with Pre => Std >= 0.0, Global => null;
   --  Box–Muller: ~ N(Mean, Std²). Std = 0 → deterministic Mean.

   function Next_Bernoulli
     (State : in out RNG_State; P : Unit_Interval) return Boolean
     with Global => null;
   --  True with probability P.

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

   function Shifted_Sphere (X : Vector) return Real
     with Global => null;
   --  f(x) = Σ (x_i − 1)²; unique min 0 at (1,…,1).

   ---------------------------------------------------------------------------
   -- Continuous CE primitives
   ---------------------------------------------------------------------------

   function Init_Isotropic
     (Dim : Dimension; Mean, Std : Real) return Gaussian_Params
     with Pre => Std >= 0.0, Global => null;
   --  All Means := Mean, all Stds := Std, Dim set.

   procedure Sample_Gaussian
     (Buf    : in out Sample_Buffer;
      Params : Gaussian_Params;
      State  : in out RNG_State)
     with Pre => Buf.Capacity >= 2
            and then Params.Dim >= 1
            and then Params.Dim <= Max_Dim,
          Global => null;
   --  Fill Buf.Capacity candidates ~ independent N(μ_d, σ_d²); sets Size/Dim.
   --  Does not evaluate the objective (Cost left as Real'Last).

   procedure Evaluate_Samples
     (Buf       : in out Sample_Buffer;
      Objective : Objective_Fn)
     with Pre => Buf.Size >= 1
            and then Objective /= null,
          Global => null;
   --  Cost := Objective(X(1 .. Dim)) for each filled candidate.

   function Elite_Indices
     (Buf : Sample_Buffer;
      Rho : Elite_Fraction) return Index_List
     with Pre => Buf.Size >= 2,
          Global => null;
   --  Indices of the Ne best (lowest Cost) candidates, ascending Cost order.
   --  Length = Elite_Count(Buf.Size, Rho). Ties broken by smaller index.

   procedure Update_From_Elite
     (G          : in out Gaussian_Params;
      Buf        : Sample_Buffer;
      Elite      : Index_List;
      Alpha      : Smooth_Factor;
      Sigma_Min  : Non_Negative)
     with Pre => Elite'Length >= 1
            and then Buf.Size >= Elite'Length
            and then G.Dim = Buf.Dim
            and then G.Dim >= 1,
          Global => null;
   --  Elite sample mean / std per dim; smoothed:
   --    μ ← (1−α)μ + α μ_e ,  σ ← (1−α)σ + α σ_e , then σ := max(σ, Σ_min).
   --  Elite length 1 → σ_e := 0 before floor/smooth.

   procedure Step
     (G         : in out Gaussian_Params;
      Buf       : in out Sample_Buffer;
      Params    : Parameters;
      Objective : Objective_Fn;
      State     : in out RNG_State;
      Best_Cost : in out Real;
      Best_X    : in out Vector)
     with Pre => Buf.Capacity >= Params.N
            and then Params.N >= 2
            and then G.Dim >= 1
            and then G.Dim <= Max_Dim
            and then Best_X'Length >= Natural (G.Dim)
            and then Objective /= null,
          Global => null;
   --  One CE iteration: sample N, evaluate, elite update, track best.

   ---------------------------------------------------------------------------
   -- Bernoulli sketch primitives (optional combinatorial path)
   ---------------------------------------------------------------------------

   function Init_Bernoulli
     (Dim : Dimension; P : Unit_Interval := 0.5) return Bernoulli_Params
     with Global => null;

   procedure Sample_Bernoulli_Bits
     (Bits   : out Bit_Vector;
      B      : Bernoulli_Params;
      State  : in out RNG_State)
     with Pre => Bits'Length = Natural (B.Dim)
            and then B.Dim >= 1,
          Global => null;

   procedure Update_Bernoulli_From_Elite
     (B         : in out Bernoulli_Params;
      Elite_Bits : Bit_Vector;
      Elite_N   : Positive;
      Alpha     : Smooth_Factor)
     with Pre => Elite_N >= 1
            and then Elite_Bits'Length = Natural (B.Dim) * Elite_N
            and then B.Dim >= 1,
          Global => null;
   --  Elite_Bits packs Elite_N consecutive bit-vectors of length Dim.
   --  p_d ← (1−α)p_d + α (elite frequency of bit d); clamp to [ε,1−ε].

   function Tiny_Knapsack_Value
     (Bits : Bit_Vector;
      Values : Vector;
      Weights : Vector;
      Capacity : Non_Negative) return Real
     with Pre => Bits'Length = Values'Length
            and then Bits'Length = Weights'Length
            and then Bits'Length >= 1,
          Global => null;
   --  Sum of Values for selected bits if total weight ≤ Capacity, else −∞
   --  proxy (−1.0E30). Educational 0-1 knapsack score (maximize).

   ---------------------------------------------------------------------------
   -- Drivers
   ---------------------------------------------------------------------------

   function Minimize
     (Objective : Objective_Fn;
      Init      : Gaussian_Params;
      Params    : Parameters) return Result
     with Pre => Init.Dim >= 1
            and then Init.Dim <= Max_Dim
            and then Objective /= null,
          Global => null;
   --  Continuous CE minimization from Init (μ, σ).

   function Minimize_Isotropic
     (Objective : Objective_Fn;
      Dim       : Dimension;
      Mean      : Real := 0.0;
      Std       : Real := 5.0;
      Params    : Parameters := Default_Parameters) return Result
     with Pre => Std >= 0.0 and then Objective /= null,
          Global => null;
   --  Convenience: Init_Isotropic then Minimize.

end Cross_Entropy_Method;
