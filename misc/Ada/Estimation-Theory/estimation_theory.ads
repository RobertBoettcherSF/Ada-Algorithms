--  Estimation_Theory — Ada 2023 educational survey package for Wikipedia
--  "Estimation theory": estimators (sample mean / variance), method of
--  moments, maximum-likelihood for classic models, bias / variance / MSE,
--  and Cramér–Rao lower bound (CRLB) examples including AWGN constant-in-
--  noise and Uniform[0,θ] maximum (German-tank classroom example).
--  Classic texts: Kay, Fundamentals of Statistical Signal Processing:
--  Estimation Theory (1993); Lehmann & Casella, Theory of Point Estimation.
--  Related siblings (README only, no deps): Ada-Expectation-Maximization,
--  Ada-Scoring-Algorithm.

pragma Ada_2022;

package Estimation_Theory
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable sample / Fisher-information arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   Max_N : constant Positive := 8192;

   subtype Sample_Count is Natural range 0 .. Max_N;
   subtype Sample_Index is Positive range 1 .. Max_N;

   --  Observed i.i.d. sample (continuous or Bernoulli 0/1 encoded as Real).
   type Sample is array (Sample_Index range <>) of Real;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;
   Capacity_Exceeded   : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers / constants
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Sample statistics (Wikipedia Basics / Estimators)
   ---------------------------------------------------------------------------

   function Mean (X : Sample) return Real
     with Pre => X'Length >= 1 and then X'Length <= Max_N,
          Global => null;
   --  Sample mean  x̄ = (1/N) Σ x[i].  Raises Invalid_Argument if empty
   --  (Pre), Capacity_Exceeded if Length > Max_N.

   function Variance
     (X        : Sample;
      Unbiased : Boolean := True) return Real
     with Pre => X'Length >= 1 and then X'Length <= Max_N,
          Global => null,
          Post => Variance'Result >= 0.0;
   --  Sample variance about the sample mean.
   --  Unbiased=True  →  s² = 1/(N−1) Σ (x−x̄)²  (N≥2; N=1 raises
   --                    Degenerate_Geometry).
   --  Unbiased=False →  σ̂² = 1/N Σ (x−x̄)²      (MLE / population form).

   function Sample_Maximum (X : Sample) return Real
     with Pre => X'Length >= 1 and then X'Length <= Max_N,
          Global => null;
   --  max_i x[i] — MLE for Uniform[0,θ] upper endpoint.

   function Sample_Minimum (X : Sample) return Real
     with Pre => X'Length >= 1 and then X'Length <= Max_N,
          Global => null;

   ---------------------------------------------------------------------------
   -- Error metrics: bias, variance of estimator, MSE
   ---------------------------------------------------------------------------

   function Bias (Estimate, Truth : Real) return Real
     with Global => null;
   --  Pointwise bias contribution: Estimate − Truth.
   --  For Monte Carlo, average Bias over replicates.

   function MSE (Estimate, Truth : Real) return Real
     with Global => null,
          Post => MSE'Result >= 0.0;
   --  Squared error (Estimate − Truth)²; Monte Carlo mean → MSE.

   function Variance_Of_Estimator
     (Estimates : Sample;
      Mean_Est  : Real) return Real
     with Pre => Estimates'Length >= 1
       and then Estimates'Length <= Max_N,
          Global => null,
          Post => Variance_Of_Estimator'Result >= 0.0;
   --  Empirical Var(θ̂) = (1/M) Σ (θ̂_m − Mean_Est)² over Monte Carlo
   --  replicates (population form, matching CRLB comparisons).

   function MSE_From_Bias_Var (B, V : Real) return Real
     with Global => null,
          Post => MSE_From_Bias_Var'Result >= 0.0;
   --  Identity: MSE = Bias² + Var.

   ---------------------------------------------------------------------------
   -- Method of moments
   ---------------------------------------------------------------------------

   function MoM_Exponential_Rate (X : Sample) return Real
     with Pre => X'Length >= 1 and then X'Length <= Max_N,
          Global => null,
          Post => MoM_Exponential_Rate'Result > 0.0;
   --  Exp(λ) with mean 1/λ: λ̂_MoM = 1 / x̄.  Raises Degenerate_Geometry
   --  if x̄ ≤ 0.

   function MoM_Uniform_Theta (X : Sample) return Real
     with Pre => X'Length >= 1 and then X'Length <= Max_N,
          Global => null;
   --  Uniform[0,θ]: E[X]=θ/2 ⇒ θ̂_MoM = 2 · x̄.

   ---------------------------------------------------------------------------
   -- Maximum likelihood estimators (classic closed forms)
   ---------------------------------------------------------------------------

   function MLE_Gaussian_Mean (X : Sample) return Real
     with Pre => X'Length >= 1 and then X'Length <= Max_N,
          Global => null;
   --  N(μ,σ²) with known σ²: μ̂_MLE = x̄  (also AWGN constant-in-noise).

   function MLE_Gaussian_Variance
     (X           : Sample;
      Known_Mean  : Boolean := False;
      Mu          : Real := 0.0) return Real
     with Pre => X'Length >= 1 and then X'Length <= Max_N,
          Global => null,
          Post => MLE_Gaussian_Variance'Result >= 0.0;
   --  Known_Mean=True  →  σ̂² = (1/N) Σ (x−μ)².
   --  Known_Mean=False →  σ̂² = (1/N) Σ (x−x̄)²  (biased MLE).

   function MLE_Bernoulli_P (X : Sample) return Real
     with Pre => X'Length >= 1 and then X'Length <= Max_N,
          Global => null,
          Post => MLE_Bernoulli_P'Result >= 0.0
            and then MLE_Bernoulli_P'Result <= 1.0;
   --  Bern(p): p̂_MLE = sample proportion (mean of 0/1 data).
   --  Raises Invalid_Argument if any entry not in {0,1} (within tol).

   function MLE_Uniform_Theta (X : Sample) return Real
     with Pre => X'Length >= 1 and then X'Length <= Max_N,
          Global => null;
   --  Uniform[0,θ]: θ̂_MLE = max_i x[i]  (Wikipedia classroom example;
   --  biased low — see Bias_Uniform_Max_Analytic).

   function MLE_AWGN_Constant (X : Sample) return Real
     with Pre => X'Length >= 1 and then X'Length <= Max_N,
          Global => null;
   --  Wikipedia AWGN: x[n]=A+w[n], w~N(0,σ²) known → Â_MLE = sample mean.

   function MLE_Exponential_Rate (X : Sample) return Real
     with Pre => X'Length >= 1 and then X'Length <= Max_N,
          Global => null,
          Post => MLE_Exponential_Rate'Result > 0.0;
   --  Exp(λ): λ̂_MLE = 1/x̄  (= MoM for exponential family mean).

   ---------------------------------------------------------------------------
   -- Fisher information / Cramér–Rao lower bound examples
   ---------------------------------------------------------------------------

   function Fisher_Info_Gaussian_Mean
     (N : Positive; Sigma2 : Real) return Real
     with Pre => N >= 1 and then N <= Max_N and then Sigma2 > 0.0,
          Global => null,
          Post => Fisher_Info_Gaussian_Mean'Result > 0.0;
   --  I(μ) = N / σ²  for i.i.d. N(μ,σ²), σ² known.

   function CRLB_Gaussian_Mean
     (N : Positive; Sigma2 : Real) return Real
     with Pre => N >= 1 and then N <= Max_N and then Sigma2 > 0.0,
          Global => null,
          Post => CRLB_Gaussian_Mean'Result > 0.0;
   --  var(μ̂) ≥ σ²/N.  Sample mean attains the bound (efficient / MVUE).

   function Fisher_Info_Bernoulli
     (N : Positive; P : Real) return Real
     with Pre => N >= 1 and then N <= Max_N
       and then P > 0.0 and then P < 1.0,
          Global => null,
          Post => Fisher_Info_Bernoulli'Result > 0.0;
   --  I(p) = N / (p(1−p)).

   function CRLB_Bernoulli
     (N : Positive; P : Real) return Real
     with Pre => N >= 1 and then N <= Max_N
       and then P > 0.0 and then P < 1.0,
          Global => null,
          Post => CRLB_Bernoulli'Result > 0.0;
   --  var(p̂) ≥ p(1−p)/N.  Sample proportion attains the bound.

   function Analytic_Var_Sample_Mean
     (N : Positive; Sigma2 : Real) return Real
     with Pre => N >= 1 and then N <= Max_N and then Sigma2 >= 0.0,
          Global => null,
          Post => Analytic_Var_Sample_Mean'Result >= 0.0;
   --  var(x̄) = σ²/N  (AWGN / Gaussian mean).

   function Analytic_Var_Bernoulli_Proportion
     (N : Positive; P : Real) return Real
     with Pre => N >= 1 and then N <= Max_N
       and then P >= 0.0 and then P <= 1.0,
          Global => null,
          Post => Analytic_Var_Bernoulli_Proportion'Result >= 0.0;
   --  var(p̂) = p(1−p)/N.

   function Bias_Uniform_Max_Analytic
     (Theta : Real; N : Positive) return Real
     with Pre => Theta > 0.0 and then N >= 1 and then N <= Max_N,
          Global => null;
   --  For i.i.d. Uniform[0,θ]: E[max] = N·θ/(N+1), so
   --  Bias(θ̂_MLE) = E[max]−θ = −θ/(N+1)  (always underestimates).

   function Expected_Uniform_Max
     (Theta : Real; N : Positive) return Real
     with Pre => Theta > 0.0 and then N >= 1 and then N <= Max_N,
          Global => null,
          Post => Expected_Uniform_Max'Result > 0.0;
   --  E[X_{(N)}] = N·θ/(N+1).

end Estimation_Theory;
