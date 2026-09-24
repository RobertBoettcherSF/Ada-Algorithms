--  Metropolis_Hastings — Ada 2023 educational package for the
--  Metropolis–Hastings MCMC algorithm (Metropolis et al. 1953;
--  Hastings 1970). Samples from a target density known only up to a
--  normalizing constant via a Markov chain with accept/reject steps.
--  Primary API: 1D symmetric Gaussian random-walk Metropolis, general
--  MH with proposal density ratio, running mean/variance, acceptance
--  rate, burn-in. Optional: independent MH, tiny discrete Bernoulli /
--  1D Ising toys, and isotropic RW-MH in D ≤ 4.
--  Primary sources:
--  https://en.wikipedia.org/wiki/Metropolis%E2%80%93Hastings_algorithm
--  Metropolis et al. (1953); Hastings (1970).
--  Siblings (Monte Carlo survey): Ada-MISER, Ada-Wang-Landau,
--  Ada-Gibbs-Sampling, Ada-Hybrid-Monte-Carlo (README links).

pragma Ada_2022;

package Metropolis_Hastings
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Fraction is Real range 0.0 .. 1.0;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Unnormalized log target density: log π(x) (additive constant OK).
   type Log_Target_1D is access function (X : Real) return Real;

   --  Educational dimension cap for optional multi-D RW-MH.
   Max_Dimension : constant Positive := 4;
   subtype Dimension_Count is Positive range 1 .. Max_Dimension;

   type Point is array (Positive range <>) of Real;

   type Log_Target_ND is access function (X : Point) return Real;

   --  Cap on optionally stored post-burn-in samples (moments always kept).
   Max_Store : constant Positive := 20_000;
   subtype Store_Count is Natural range 0 .. Max_Store;
   type Sample_Array is array (Positive range <>) of Real;

   --  Steps          : total Markov steps after initialization
   --  Burn_In        : discarded initial steps (not used in moments)
   --  Proposal_Sigma : Gaussian RW proposal std-dev (1D / isotropic ND)
   --  Seed           : RNG seed (Ada.Numerics.Float_Random)
   --  Start          : initial state x_0 (1D)
   --  Keep_Samples   : if True, store up to Max_Store post-burn-in draws
   type Config is record
      Steps          : Positive      := 10_000;
      Burn_In        : Natural       := 1_000;
      Proposal_Sigma : Positive_Real := 1.0;
      Seed           : Integer       := 42;
      Start          : Real          := 0.0;
      Keep_Samples   : Boolean       := False;
   end record;

   --  Running moments over kept (post-burn-in) samples + acceptance rate.
   type Result is record
      Mean         : Real          := 0.0;
      Variance     : Real          := 0.0;
      Accept_Rate  : Unit_Fraction := 0.0;
      N_Kept       : Natural       := 0;
      N_Accepted   : Natural       := 0;
      N_Proposed   : Natural       := 0;
      Stored       : Store_Count   := 0;
      Samples      : Sample_Array (1 .. Max_Store) := [others => 0.0];
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-12;

   --  Metropolis–Hastings acceptance probability in log space:
   --    α = min(1, exp(Log_Alpha)) with Log_Alpha =
   --        log π(x') − log π(x) + log q(x|x') − log q(x'|x).
   --  For symmetric proposals the q terms cancel (pass Q_Ratio_Log = 0).
   function Accept_Probability (Log_Alpha : Real) return Unit_Fraction
     with Global => null;

   --  Standard normal / Gaussian log-density helpers (educational targets).
   function Log_Std_Normal (X : Real) return Real
     with Global => null;
   --  log N(x; 0, 1) up to an additive constant (−x²/2).

   function Log_Normal (X, Mu, Sigma : Real) return Real
     with Pre => Sigma > 0.0, Global => null;
   --  log N(x; μ, σ) up to additive constant.

   function Log_Normal_Full (X, Mu, Sigma : Real) return Real
     with Pre => Sigma > 0.0, Global => null;
   --  Full log N including −log(σ√(2π)).

   ---------------------------------------------------------------------------
   -- Core algorithms (1D)
   ---------------------------------------------------------------------------

   --  Symmetric Gaussian random-walk Metropolis:
   --    x' = x + σ · Z,  Z ~ N(0,1);  q symmetric ⇒ Hastings ratio = 1.
   --  Target via Log_Pi (unnormalized OK). Tracks accept rate + moments.
   function Sample_1D
     (Log_Pi : Log_Target_1D;
      Cfg    : Config := (others => <>)) return Result
     with Pre => Log_Pi /= null;

   --  Alias matching the series Run naming.
   function Run
     (Log_Pi : Log_Target_1D;
      Cfg    : Config := (others => <>)) return Result
     renames Sample_1D;

   --  General 1D Metropolis–Hastings with explicit proposal density ratio.
   --  Propose: x' ~ from Log_Q / caller-supplied Gaussian or custom via
   --  the independent-MH and RW helpers below; this entry takes a
   --  Propose_From callback through the independent / custom APIs.
   --  Independent Metropolis: propose x' ~ q(·) independent of current x;
   --  Log_Q(X) = log q(X). Acceptance uses
   --    α = min(1, exp(log π(x')−log π(x) + log q(x)−log q(x'))).
   type Log_Density_1D is access function (X : Real) return Real;

   function Sample_1D_Independent
     (Log_Pi : Log_Target_1D;
      Log_Q  : Log_Density_1D;
      Cfg    : Config := (others => <>)) return Result
     with Pre => Log_Pi /= null and then Log_Q /= null;
   --  Proposals drawn as N(Cfg.Start, Cfg.Proposal_Sigma) i.i.d.;
   --  Log_Q should match that proposal (use Log_Normal_Full).

   --  General MH step helper (symmetric or not) exposing the q-ratio:
   --  Log_Q_Ratio = log q(x|x') − log q(x'|x). For RW Gaussian = 0.
   function Log_Hastings_Ratio
     (Log_Pi_Current : Real;
      Log_Pi_Prop    : Real;
      Log_Q_Ratio    : Real := 0.0) return Real
     with Global => null;
   --  Returns log(π(x')/π(x) · q(x|x')/q(x'|x)).

   ---------------------------------------------------------------------------
   -- Optional multi-D (D ≤ 4): isotropic Gaussian RW Metropolis
   ---------------------------------------------------------------------------

   type Config_ND (D : Dimension_Count) is record
      Steps          : Positive      := 10_000;
      Burn_In        : Natural       := 1_000;
      Proposal_Sigma : Positive_Real := 1.0;
      Seed           : Integer       := 42;
      Start          : Point (1 .. D) := [others => 0.0];
   end record;

   type Result_ND (D : Dimension_Count) is record
      Mean        : Point (1 .. D) := [others => 0.0];
      Variance    : Point (1 .. D) := [others => 0.0];
      Accept_Rate : Unit_Fraction  := 0.0;
      N_Kept      : Natural        := 0;
      N_Accepted  : Natural        := 0;
      N_Proposed  : Natural        := 0;
   end record;

   function Sample_ND
     (Log_Pi : Log_Target_ND;
      Cfg    : Config_ND) return Result_ND
     with Pre => Log_Pi /= null;

   ---------------------------------------------------------------------------
   -- Optional discrete toys
   ---------------------------------------------------------------------------

   --  Bernoulli(p) on {0,1} with flip proposals (symmetric Metropolis).
   --  Returns mean ≈ p and accept rate in (0,1) for p ∈ (0,1).
   function Sample_Bernoulli
     (P   : Unit_Fraction;
      Cfg : Config := (others => <>)) return Result
     with Pre => P > 0.0 and then P < 1.0;

   --  Tiny 1D Ising: N spins ±1, periodic BC, J = 1, inverse temp Beta.
   --  Single-spin-flip Metropolis; returns mean magnetization m ∈ [−1,1].
   Max_Ising_N : constant Positive := 8;

   type Ising_Result is record
      Mean_Magnetization : Real          := 0.0;
      Mean_Energy        : Real          := 0.0;
      Accept_Rate        : Unit_Fraction := 0.0;
      N_Kept             : Natural       := 0;
   end record;

   function Sample_Ising_1D
     (N     : Positive;
      Beta  : Non_Negative;
      Steps : Positive := 20_000;
      Burn  : Natural  := 2_000;
      Seed  : Integer  := 42) return Ising_Result
     with Pre => N >= 2 and then N <= Max_Ising_N;

   ---------------------------------------------------------------------------
   -- Library-level educational targets (for 'Access in tests / demos)
   ---------------------------------------------------------------------------

   function Target_Std_Normal (X : Real) return Real;
   --  Unnormalized log N(0,1): −x²/2.

   function Target_Normal_Mu2 (X : Real) return Real;
   --  Unnormalized log N(2,1): −(x−2)²/2.

   function Target_Normal_Wide (X : Real) return Real;
   --  Unnormalized log N(0,2): −x²/(2·4).

   function Target_Bimodal (X : Real) return Real;
   --  log(exp(−(x+2)²/2) + exp(−(x−2)²/2))  (equal mixture, unnormalized).

   --  Proposal density matching Sample_1D_Independent default:
   --  full log N(x; 0, 1).
   function Proposal_Std_Normal (X : Real) return Real;

   --  Multi-D educational targets (library-level for 'Access).
   function Target_Iso_Normal_ND (X : Point) return Real;
   --  Independent standard normals: −‖x‖²/2 (uses X'Length coords).

   function Target_Std_Normal_ND (X : Point) return Real;
   --  Same as Target_Iso_Normal_ND (alias clarity for D=1 demos).

end Metropolis_Hastings;
