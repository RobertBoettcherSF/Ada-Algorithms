--  Stochastic_Tunneling — Ada 2023 educational package for Wikipedia
--  "Stochastic tunneling" (STUN; Wenzel & Hamacher, 1999): global
--  optimization by Metropolis Monte Carlo on a nonlinearly transformed
--  objective that flattens barriers above the best energy found so far,
--  enabling faster tunneling among basins.
--  Primary source: https://en.wikipedia.org/wiki/Stochastic_tunneling
--  Sibling (canonical MCMC): Ada-Glauber-Dynamics / Ada-Demon-Method
--  (links in README).

pragma Ada_2022;

package Stochastic_Tunneling
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  STUN / Metropolis schedule for 1-D continuous minimization.
   --  Gamma  : energy scale in f_STUN = 1 − exp(−(E−E0)/γ)
   --  Beta   : inverse temperature for Metropolis on Δf_STUN (T = 1/β)
   --  Step   : proposal step width (Gaussian σ or uniform half-width)
   --  Max_Iters : maximum Metropolis trials
   type Config is record
      Gamma             : Positive_Real := 1.0;
      Beta              : Non_Negative  := 5.0;
      Step              : Positive_Real := 0.4;
      Max_Iters         : Positive      := 5_000;
      Use_Gaussian_Step : Boolean       := True;
   end record;

   type Result is record
      Best_X : Real    := 0.0;
      Best_E : Real    := 0.0;
      Iters  : Natural := 0;
   end record;

   --  Access to a scalar objective E(x) to minimize.
   type Objective_Fn is access function (X : Real) return Real;

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

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- STUN transform and Metropolis acceptance
   ---------------------------------------------------------------------------

   function Stun_Transform
     (E, E0 : Real; Gamma : Positive_Real) return Non_Negative
     with Global => null;
   --  Standard STUN map (this package's gamma-as-scale convention):
   --    f_STUN(E, E0, γ) = 1 − exp(−(E − E0)/γ)   when E ≥ E0
   --  If E < E0 the result is clamped to 0 (energy below the best-so-far
   --  is treated as already at the floor of the transformed landscape).
   --  Loci of minima of E are preserved for E ≥ E0. Wikipedia often writes
   --  1 − exp(−γ_wiki · (E − E0)); here γ = 1/γ_wiki (energy units).

   function Metropolis_Accept_Prob
     (Delta_F_Stun : Real; Beta : Non_Negative) return Unit_Interval
     with Global => null;
   --  min(1, exp(−β · Δf_STUN)).

   function Metropolis_Accept_Stun
     (Delta_F_Stun : Real;
      Beta         : Non_Negative;
      State        : in out RNG_State) return Boolean
     with Global => null;
   --  True iff a uniform U < Metropolis_Accept_Prob.

   function Metropolis_Accept_Energy
     (Delta_E : Real;
      Beta    : Non_Negative;
      State   : in out RNG_State) return Boolean
     with Global => null;
   --  Plain Metropolis / SA accept on raw ΔE (comparison helper).

   ---------------------------------------------------------------------------
   -- Built-in multimodal test objectives (1-D)
   ---------------------------------------------------------------------------

   function Double_Well (X : Real) return Real
     with Global => null;
   --  E(x) = (x² − 1)² + 0.15·x
   --  Local min near x ≈ +1; deeper (global) min near x ≈ −1; barrier ≈ 0.

   function Rastrigin_1D (X : Real) return Real
     with Global => null;
   --  Lite 1-D Rastrigin: x² − 10 cos(2πx) + 10; global min 0 at x = 0.

   function Sum_Of_Gaussians (X : Real) return Real
     with Global => null;
   --  Negative sum of three Gaussians (minimize → deepest well at x ≈ −2).

   function Quadratic (X : Real) return Real
     with Global => null;
   --  E(x) = x²; unique min 0 at x = 0.

   function Shifted_Quadratic (X : Real) return Real
     with Global => null;
   --  E(x) = (x − 3)²; unique min 0 at x = 3.

   function Tall_Double_Well (X : Real) return Real
     with Global => null;
   --  E(x) = 25·(x² − 1)² + 0.2·x
   --  Tall barrier (~25) so raw Metropolis at moderate β is sticky while
   --  STUN still tunnels (Δf_STUN ≤ 1).

   ---------------------------------------------------------------------------
   -- 1-D continuous minimizers
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
   --  STUN Metropolis walk: track best-so-far E0; proposals
   --  x' = x + N(0, Step) or Uniform(−Step, Step), clamped to [Lo, Hi].

   function Minimize_1D_Metropolis
     (Objective : Objective_Fn;
      X0        : Real;
      Cfg       : Config;
      Seed      : Natural;
      Lo        : Real := -1.0E6;
      Hi        : Real := 1.0E6) return Result
     with Pre => Lo < Hi and then Objective /= null,
          Global => null;
   --  Plain Metropolis on raw E (no STUN transform); same proposals / β.

end Stochastic_Tunneling;
