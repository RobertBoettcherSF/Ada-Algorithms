--  Simulated_Annealing — Ada 2023 educational package for Wikipedia
--  "Simulated annealing" (SA; Kirkpatrick, Gelatt & Vecchi 1983;
--  Černý 1985): probabilistic metaheuristic for global optimization
--  inspired by metallurgical annealing. Metropolis acceptance with a
--  cooling schedule explores the search space then settles downhill.
--  Primary source: https://en.wikipedia.org/wiki/Simulated_annealing
--  Sibling (barrier tunneling): Ada-Stochastic-Tunneling (README link).

pragma Ada_2022;

package Simulated_Annealing
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   type Cooling_Kind is (Geometric, Linear);

   --  SA schedule for 1-D continuous (and combinatorial) minimization.
   --  T0 / T_Min : start and stop temperatures (T > 0)
   --  Alpha      : geometric factor T := Alpha * T  (0 < Alpha < 1)
   --  Step       : proposal step width (Gaussian σ or uniform half-width)
   --  Max_Iters  : hard iteration budget
   --  Cool_Every : apply cooling every N accepted-or-proposed steps
   --  Kind       : Geometric (default) or Linear toward T_Min
   type Config is record
      T0                : Positive_Real := 10.0;
      T_Min             : Positive_Real := 1.0E-4;
      Alpha             : Unit_Interval := 0.95;
      Step              : Positive_Real := 0.4;
      Max_Iters         : Positive      := 8_000;
      Cool_Every        : Positive      := 20;
      Kind              : Cooling_Kind  := Geometric;
      Use_Gaussian_Step : Boolean       := True;
   end record;

   type Result is record
      Best_X       : Real          := 0.0;
      Best_E       : Real          := 0.0;
      Final_T      : Non_Negative  := 0.0;
      Iters        : Natural       := 0;
      Accept_Count : Natural       := 0;
   end record;

   --  Access to a scalar objective E(x) to minimize.
   type Objective_Fn is access function (X : Real) return Real;

   --  Tiny TSP-lite: permutation of at most 8 cities (1-based indices).
   Max_Cities : constant := 8;
   subtype City_Count is Positive range 2 .. Max_Cities;
   type City_Index is range 1 .. Max_Cities;
   type Tour is array (City_Index range <>) of City_Index;
   type Dist_Matrix is array (City_Index range <>, City_Index range <>) of Non_Negative;

   type TSP_Result is record
      Best_Tour    : Tour (1 .. Max_Cities);
      N            : City_Count := 2;
      Best_Length  : Non_Negative := 0.0;
      Final_T      : Non_Negative := 0.0;
      Iters        : Natural := 0;
      Accept_Count : Natural := 0;
   end record;

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

   function Next_Gaussian (State : in out RNG_State) return Real
     with Global => null;
   --  Standard normal N(0,1) via Box–Muller.

   function Next_Uniform
     (State : in out RNG_State; Lo, Hi : Real) return Real
     with Pre => Lo <= Hi, Global => null;
   --  Uniform on [Lo, Hi].

   function Next_Natural
     (State : in out RNG_State; Lo, Hi : Natural) return Natural
     with Pre => Lo <= Hi, Global => null;
   --  Uniform integer in [Lo, Hi].

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Metropolis acceptance (minimization)
   ---------------------------------------------------------------------------

   function Accept_Probability
     (Delta_E : Real; Temperature : Non_Negative) return Unit_Interval
     with Global => null;
   --  P = min(1, exp(−ΔE/T)) for minimization. ΔE ≤ 0 → 1.
   --  T = 0 → 1 if ΔE ≤ 0 else 0 (greedy).

   function Metropolis_Accept
     (Delta_E     : Real;
      Temperature : Non_Negative;
      State       : in out RNG_State) return Boolean
     with Global => null;
   --  True iff U < Accept_Probability(Delta_E, T).

   ---------------------------------------------------------------------------
   -- Cooling schedules
   ---------------------------------------------------------------------------

   function Cool_Geometric
     (T : Non_Negative; Alpha : Unit_Interval) return Non_Negative
     with Global => null;
   --  T' = Alpha * T. Alpha in [0,1]; Alpha = 1 leaves T unchanged.

   function Cool_Linear
     (T, T0, T_Min : Non_Negative; Progress : Unit_Interval)
      return Non_Negative
     with Global => null;
   --  Linear interpolate from T0 toward T_Min: T' = T0 + (T_Min−T0)*Progress.
   --  Progress in [0,1] is fraction of budget expended. Result ≥ 0.

   ---------------------------------------------------------------------------
   -- Built-in multimodal test objectives (1-D)
   ---------------------------------------------------------------------------

   function Double_Well (X : Real) return Real
     with Global => null;
   --  E(x) = (x² − 1)² + 0.15·x
   --  Local min near x ≈ +1; deeper (global) min near x ≈ −1.

   function Rastrigin_1D (X : Real) return Real
     with Global => null;
   --  Lite 1-D Rastrigin: x² − 10 cos(2πx) + 10; global min 0 at x = 0.

   function Quadratic (X : Real) return Real
     with Global => null;
   --  E(x) = x²; unique min 0 at x = 0.

   function Shifted_Quadratic (X : Real) return Real
     with Global => null;
   --  E(x) = (x − 3)²; unique min 0 at x = 3.

   ---------------------------------------------------------------------------
   -- 1-D continuous SA minimizer
   ---------------------------------------------------------------------------

   function Minimize_1D
     (Objective : Objective_Fn;
      X0        : Real;
      Cfg       : Config;
      Seed      : Natural;
      Lo        : Real := -1.0E6;
      Hi        : Real := 1.0E6) return Result
     with Pre => Lo < Hi and then Objective /= null,
          Global => null;
   --  Simulated annealing walk: proposals x' = x ± step noise, Metropolis
   --  accept with temperature T, cool geometrically (or linearly) until
   --  T ≤ T_Min or Max_Iters. Tracks best-so-far.

   ---------------------------------------------------------------------------
   -- Tiny combinatorial demo: TSP-lite (pair-swap, n ≤ 8)
   ---------------------------------------------------------------------------

   function Tour_Length
     (T : Tour; D : Dist_Matrix) return Non_Negative
     with Pre => T'First = D'First (1)
            and then T'Last = D'Last (1)
            and then D'First (1) = D'First (2)
            and then D'Last (1) = D'Last (2),
          Global => null;

   function Minimize_TSP
     (D     : Dist_Matrix;
      Cfg   : Config;
      Seed  : Natural;
      Start : Tour) return TSP_Result
     with Pre => Start'First = D'First (1)
            and then Start'Last = D'Last (1)
            and then D'First (1) = D'First (2)
            and then D'Last (1) = D'Last (2)
            and then Start'Length >= 2
            and then Start'Length <= Max_Cities,
          Global => null;
   --  Pair-swap neighbors on a closed tour; same Metropolis + cooling.

end Simulated_Annealing;
