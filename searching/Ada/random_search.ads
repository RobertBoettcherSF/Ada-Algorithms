--  Random_Search — Ada 2023 educational package for Wikipedia
--  "Hyperparameter optimization" § Random search (Bergstra & Bengio,
--  JMLR 13:281–305, 2012): sample hyperparameter configurations
--  uniformly (or log-uniformly) at random and keep the best objective
--  value under a fixed evaluation budget. Often beats grid search when
--  only a few dimensions matter (low effective dimensionality).
--  Primary source:
--  https://en.wikipedia.org/wiki/Hyperparameter_optimization#Random_search
--  Sibling (metaheuristics): Ada-Simulated-Annealing /
--  Ada-Stochastic-Tunneling (README links).

pragma Ada_2022;

package Random_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Dim : constant := 8;
   subtype Dim_Count is Positive range 1 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;

   type Point is array (Dim_Index range <>) of Real;

   --  Closed interval per coordinate (or shared box).
   type Bound is record
      Lo : Real := -1.0;
      Hi : Real := 1.0;
   end record;

   type Bounds is array (Dim_Index range <>) of Bound;

   type Sampling_Kind is (Uniform, Log_Uniform);
   type Sense is (Minimize_Sense, Maximize_Sense);

   --  Search budget and sampling mode.
   --  Trials     : number of random evaluations (budget)
   --  Kind       : Uniform on [Lo,Hi] or Log_Uniform on (0,∞)-style scales
   --  Sense_Flag : minimize or maximize the objective
   type Config is record
      Trials     : Natural        := 100;
      Kind       : Sampling_Kind  := Uniform;
      Sense_Flag : Sense          := Minimize_Sense;
   end record;

   type Result is record
      Best_X     : Point (1 .. Max_Dim);
      Best_F     : Real    := 0.0;
      Dim        : Dim_Count := 1;
      Trials_Run : Natural := 0;
      Best_Trial : Natural := 0;
   end record;

   --  Scalar 1-D and N-D objectives.
   type Objective_1D is access function (X : Real) return Real;
   type Objective_ND is access function (X : Point) return Real;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Seeded RNG (32-bit LCG) for reproducible Monte Carlo
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

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Clamp (X, Lo, Hi : Real) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- Sampling
   ---------------------------------------------------------------------------

   function Sample_Uniform
     (State : in out RNG_State; Lo, Hi : Real) return Real
     with Pre => Lo <= Hi, Global => null;
   --  Uniform draw on [Lo, Hi] (alias of Next_Uniform).

   function Sample_Log_Uniform
     (State : in out RNG_State; Lo, Hi : Positive_Real) return Real
     with Pre => Lo <= Hi, Global => null;
   --  Log-uniform: exp(U(log Lo, log Hi)). Requires Lo > 0, Hi >= Lo.
   --  Useful for positive scale hyperparameters (learning rates, C, γ).

   function Sample_Point
     (State : in out RNG_State;
      B     : Bounds;
      Kind  : Sampling_Kind) return Point
     with Pre => B'Length >= 1 and then B'Length <= Max_Dim,
          Global => null;
   --  Independent sample per coordinate according to Kind.
   --  Log_Uniform requires every Lo > 0.

   ---------------------------------------------------------------------------
   -- Built-in test objectives
   ---------------------------------------------------------------------------

   function Quadratic_1D (X : Real) return Real
     with Global => null;
   --  f(x) = x²; unique min 0 at x = 0.

   function Shifted_Quadratic_1D (X : Real) return Real
     with Global => null;
   --  f(x) = (x − 3)²; unique min 0 at x = 3.

   function Needle_1D (X : Real) return Real
     with Global => null;
   --  f(x) = (x − 0.7)² on a flat-ish range; min near 0.7.

   function Sphere_ND (X : Point) return Real
     with Global => null;
   --  f(x) = Σ x_i²; unique min 0 at the origin.

   function Needle_Haystack_2D (X : Point) return Real
     with Global => null;
   --  Only first coordinate matters: f(x,y) = (x − 0.75)² + 0·y.
   --  Bergstra–Bengio low-effective-dimensionality demo.

   function Rastrigin_2D (X : Point) return Real
     with Global => null;
   --  Lite 2-D Rastrigin; global min ≈ 0 at (0,0).

   function Neg_Sphere_ND (X : Point) return Real
     with Global => null;
   --  f(x) = −Σ x_i²; unique max 0 at the origin (Maximize demo).

   function Log10_Squared_1D (X : Real) return Real
     with Global => null;
   --  f(x) = (log10 x)² for x > 0; unique min 0 at x = 1.
   --  Suited to log-uniform sampling over positive scales.

   function Neg_Quadratic_1D_As_ND (X : Point) return Real
     with Global => null;
   --  f(x) = −(first coord)²; for Maximize on a 1-D box embedded in Point.

   ---------------------------------------------------------------------------
   -- Search drivers
   ---------------------------------------------------------------------------

   function Search_1D
     (Objective : Objective_1D;
      Lo, Hi    : Real;
      Cfg       : Config;
      Seed      : Natural) return Result
     with Pre => Lo < Hi and then Objective /= null,
          Global => null;
   --  Random search on a 1-D interval. Trials = 0 → empty Result.

   function Search_ND
     (Objective : Objective_ND;
      B         : Bounds;
      Cfg       : Config;
      Seed      : Natural) return Result
     with Pre => B'Length >= 1
            and then B'Length <= Max_Dim
            and then Objective /= null,
          Global => null;
   --  Random search with per-dimension bounds (dim ≤ Max_Dim).

   function Minimize
     (Objective : Objective_ND;
      B         : Bounds;
      Trials    : Natural;
      Seed      : Natural;
      Kind      : Sampling_Kind := Uniform) return Result
     with Pre => B'Length >= 1
            and then B'Length <= Max_Dim
            and then Objective /= null,
          Global => null;
   --  Convenience: Search_ND with Minimize_Sense.

   function Maximize
     (Objective : Objective_ND;
      B         : Bounds;
      Trials    : Natural;
      Seed      : Natural;
      Kind      : Sampling_Kind := Uniform) return Result
     with Pre => B'Length >= 1
            and then B'Length <= Max_Dim
            and then Objective /= null,
          Global => null;
   --  Convenience: Search_ND with Maximize_Sense.

   ---------------------------------------------------------------------------
   -- Grid search (same budget comparison helper)
   ---------------------------------------------------------------------------

   function Grid_Search_2D
     (Objective : Objective_ND;
      Bx, By    : Bound;
      Nx, Ny    : Positive;
      Sense_Flag : Sense := Minimize_Sense) return Result
     with Pre => Objective /= null
            and then Bx.Lo < Bx.Hi
            and then By.Lo < By.Hi,
          Global => null;
   --  Regular Nx × Ny grid over the rectangle; evaluates all cells.
   --  Useful to contrast with random search under equal evaluation count.

end Random_Search;
