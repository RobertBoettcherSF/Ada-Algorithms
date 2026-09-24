--  Gibbs_Sampling — Ada 2023 educational package for Gibbs sampling
--  (Geman & Geman 1984; heat-bath algorithm in statistical physics).
--  MCMC by cycling through full conditionals; each coordinate update is
--  a Metropolis–Hastings proposal with acceptance probability 1 when the
--  proposal equals the exact conditional. Primary demo: bivariate
--  standard Normal with known correlation ρ (exact Normal conditionals).
--  Optional: Beta–Bernoulli conjugate Bayesian toy (sample p from its
--  Beta full conditional given fixed Bernoulli counts).
--  Primary sources:
--  https://en.wikipedia.org/wiki/Gibbs_sampling
--  Geman & Geman (1984); Casella & George (1992).
--  Siblings (Monte Carlo survey): Ada-Metropolis-Hastings,
--  Ada-Hybrid-Monte-Carlo, Ada-Wang-Landau (README links).

pragma Ada_2022;

package Gibbs_Sampling
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

   --  Correlation ρ for standard bivariate Normal; |ρ| < 1 required.
   subtype Open_Unit_Correlation is Real range -1.0 .. 1.0;

   --  Cap on optionally stored post-burn-in samples (moments always kept).
   Max_Store : constant Positive := 20_000;
   subtype Store_Count is Natural range 0 .. Max_Store;
   type Sample_Array is array (Positive range <>) of Real;

   --  Steps        : total full Gibbs sweeps after initialization
   --  Burn_In      : discarded initial sweeps (not used in moments)
   --  Seed         : RNG seed (Ada.Numerics.Float_Random)
   --  Rho          : target correlation for bivariate N(0, Σ)
   --  Start_X/Y    : initial state (x_0, y_0)
   --  Keep_Samples : if True, store up to Max_Store post-burn-in draws
   type Config is record
      Steps        : Positive              := 10_000;
      Burn_In      : Natural               := 1_000;
      Seed         : Integer               := 42;
      Rho          : Open_Unit_Correlation := 0.5;
      Start_X      : Real                  := 0.0;
      Start_Y      : Real                  := 0.0;
      Keep_Samples : Boolean               := False;
   end record;

   --  Running moments over kept (post-burn-in) bivariate samples.
   type Result is record
      Mean_X      : Real        := 0.0;
      Mean_Y      : Real        := 0.0;
      Var_X       : Real        := 0.0;
      Var_Y       : Real        := 0.0;
      Cov_XY      : Real        := 0.0;
      Correlation : Real        := 0.0;
      N_Kept      : Natural     := 0;
      Stored      : Store_Count := 0;
      Samples_X   : Sample_Array (1 .. Max_Store) := [others => 0.0];
      Samples_Y   : Sample_Array (1 .. Max_Store) := [others => 0.0];
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Conditional Normal helpers (standard bivariate N with corr ρ)
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-12;

   --  For (X,Y) ~ N(0, Σ) with Corr(X,Y)=ρ, Var=1:
   --    X | Y=y  ~  N(ρ·y,  1−ρ²)
   --    Y | X=x  ~  N(ρ·x,  1−ρ²)
   function Conditional_Mean (Rho, Other : Real) return Real
     with Global => null;
   --  E[X|Y=Other] = Rho * Other  (same formula for Y|X).

   function Conditional_Variance (Rho : Real) return Non_Negative
     with Global => null;
   --  Var(X|Y) = 1 − Rho²  (requires |Rho| ≤ 1).

   function Conditional_Std_Dev (Rho : Real) return Non_Negative
     with Global => null;
   --  sqrt(Conditional_Variance(Rho)).

   --  True when |Rho| < 1 − Epsilon_Tol so conditional variance is positive.
   function Valid_Correlation (Rho : Real) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Core algorithm: bivariate Normal Gibbs
   ---------------------------------------------------------------------------

   --  Gibbs sampler for standard bivariate Normal with correlation Cfg.Rho:
   --  each sweep samples X|Y then Y|X from the exact Normal conditionals.
   --  Acceptance probability is identically 1 (Gibbs ≡ MH with q = full
   --  conditional). Tracks means, variances, covariance, sample correlation.
   function Sample_Bivariate_Normal
     (Cfg : Config := (others => <>)) return Result
     with Pre => Valid_Correlation (Cfg.Rho)
                 and then Cfg.Burn_In < Cfg.Steps;

   --  Alias matching the series Run naming.
   function Run
     (Cfg : Config := (others => <>)) return Result
     renames Sample_Bivariate_Normal;

   ---------------------------------------------------------------------------
   -- Optional: Beta–Bernoulli conjugate Bayesian toy
   ---------------------------------------------------------------------------

   --  Prior p ~ Beta(Alpha, Beta_P); observe Successes successes in Trials
   --  Bernoulli trials. Full conditional (and posterior) is
   --    p | data ~ Beta(Alpha+Successes, Beta_P+Trials−Successes).
   --  Each Gibbs “sweep” draws p from that Beta (i.i.d. posterior samples
   --  when data are fixed — educational conjugate full-conditional demo).
   type Beta_Bernoulli_Config is record
      Steps     : Positive      := 10_000;
      Burn_In   : Natural       := 1_000;
      Seed      : Integer       := 42;
      Alpha     : Positive_Real := 2.0;
      Beta_P    : Positive_Real := 2.0;
      Successes : Natural       := 7;
      Trials    : Positive      := 10;
   end record;

   type Beta_Bernoulli_Result is record
      Mean_P : Real    := 0.0;
      Var_P  : Real    := 0.0;
      N_Kept : Natural := 0;
   end record;

   function Posterior_Alpha
     (Alpha : Positive_Real; Successes : Natural) return Positive_Real
     with Global => null;

   function Posterior_Beta
     (Beta_P            : Positive_Real;
      Successes, Trials : Natural) return Positive_Real
     with Pre => Successes <= Trials, Global => null;

   --  Exact Beta posterior mean (α'/(α'+β')) after conjugate update.
   function Posterior_Mean
     (Alpha, Beta_P     : Positive_Real;
      Successes, Trials : Natural) return Unit_Fraction
     with Pre => Successes <= Trials, Global => null;

   function Sample_Beta_Bernoulli
     (Cfg : Beta_Bernoulli_Config := (others => <>)) return Beta_Bernoulli_Result
     with Pre => Cfg.Successes <= Cfg.Trials
                 and then Cfg.Burn_In < Cfg.Steps;

end Gibbs_Sampling;
