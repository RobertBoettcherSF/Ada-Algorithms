--  Bayesian_Statistics — Ada 2023 educational survey package for Wikipedia
--  "Bayesian statistics": probability as degree of belief, Bayes' theorem
--  event updates, Beta–Bernoulli / Binomial conjugates, Normal–known-
--  variance conjugate, MAP / posterior mean, equal-tailed credible
--  intervals, and simple discrete evidence / Bayes factors.
--  Classic texts: Gelman et al., Bayesian Data Analysis; Lee, Bayesian
--  Statistics: An Introduction.
--  Related siblings (README only, no deps): Ada-Nested-Sampling,
--  Ada-Estimation-Theory, Ada-Kalman-Filter.

pragma Ada_2022;

package Bayesian_Statistics
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable probability / incomplete-beta arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;
   subtype Open_Unit is Real range Real'Model_Small .. 1.0 - Real'Model_Small;

   Max_Hypotheses : constant Positive := 64;

   subtype Hypothesis_Count is Natural range 0 .. Max_Hypotheses;
   subtype Hypothesis_Index is Positive range 1 .. Max_Hypotheses;

   type Real_Array is array (Hypothesis_Index range <>) of Real;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers / constants
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Safe_Log (X : Real) return Real
     with Global => null;
   --  Natural log; large negative sentinel when X <= 0.

   function Log_Sum (A, B : Real) return Real
     with Global => null;
   --  Stable log(exp(A)+exp(B)).

   ---------------------------------------------------------------------------
   -- Seeded RNG (LCG) — used by optional Monte Carlo credible checks
   ---------------------------------------------------------------------------

   type RNG_State is mod 2**32;

   procedure Seed_RNG (State : out RNG_State; Seed : Natural)
     with Global => null;

   function Next_Unit (State : in out RNG_State) return Unit_Interval
     with Global => null;
   --  Uniform on [0, 1).

   ---------------------------------------------------------------------------
   -- Events / Bayes' theorem
   ---------------------------------------------------------------------------

   function Is_Valid_Probability (P : Real) return Boolean
     with Global => null;
   --  True iff P ∈ [0, 1].

   function Posterior_Prob
     (Prior_A              : Unit_Interval;
      Likelihood_B_Given_A : Unit_Interval;
      Evidence_B           : Real) return Unit_Interval
     with Global => null;
   --  P(A|B) = P(B|A) P(A) / P(B).
   --  Raises Invalid_Argument if Prior_A or Likelihood not in [0,1],
   --  or if Evidence_B <= 0, or if the numerator / Evidence exceeds 1
   --  beyond a tiny numerical tolerance (clamped otherwise).

   function Posterior_Prob_Complement
     (Prior_A                  : Unit_Interval;
      Likelihood_B_Given_A     : Unit_Interval;
      Likelihood_B_Given_Not_A : Unit_Interval) return Unit_Interval
     with Global => null;
   --  P(A|B) = P(B|A)P(A) / (P(B|A)P(A) + P(B|¬A)P(¬A)).
   --  Classic disease / false-positive form. Raises Invalid_Argument
   --  if any argument is outside [0,1], or if the denominator is 0.

   function Evidence_From_Complement
     (Prior_A                  : Unit_Interval;
      Likelihood_B_Given_A     : Unit_Interval;
      Likelihood_B_Given_Not_A : Unit_Interval) return Unit_Interval
     with Global => null;
   --  P(B) = P(B|A)P(A) + P(B|¬A)(1−P(A)).

   ---------------------------------------------------------------------------
   -- Beta–Bernoulli / Binomial conjugate
   ---------------------------------------------------------------------------

   type Beta_Params is record
      Alpha : Real := 1.0;
      Beta  : Real := 1.0;
   end record;
   --  Prior / posterior Beta(α, β); α > 0, β > 0 enforced at use.

   function Beta_Update
     (Prior     : Beta_Params;
      Successes : Natural;
      Trials    : Natural) return Beta_Params
     with Pre => Successes <= Trials, Global => null;
   --  After s successes in n Bernoulli / Binomial trials:
   --  Beta(α+s, β+n−s). Raises Invalid_Argument if Successes > Trials
   --  or if Prior parameters are non-positive.

   function Beta_Mean (P : Beta_Params) return Unit_Interval
     with Global => null;
   --  E[θ] = α / (α+β).

   function Beta_Mode (P : Beta_Params) return Unit_Interval
     with Global => null;
   --  MAP for Bernoulli likelihood: (α−1)/(α+β−2) when α,β > 1;
   --  otherwise returns the unique mode at a boundary (0 if α<1,β≥1;
   --  1 if β<1,α≥1; 0.5 if α=β=1 flat). Raises Invalid_Argument if
   --  α≤0 or β≤0.

   function Beta_Variance (P : Beta_Params) return Non_Negative
     with Global => null;
   --  Var(θ) = αβ / ((α+β)² (α+β+1)).

   function Beta_PDF (X : Unit_Interval; P : Beta_Params) return Non_Negative
     with Global => null;
   --  f(x) = x^{α−1}(1−x)^{β−1} / B(α,β).  At endpoints returns 0
   --  when the corresponding exponent is positive; may be large when
   --  α or β < 1.

   function Beta_Log_PDF
     (X : Open_Unit; P : Beta_Params) return Real
     with Global => null;
   --  log PDF on (0,1); more stable for extreme parameters.

   function Regularized_Incomplete_Beta
     (X : Unit_Interval; A, B : Real) return Unit_Interval
     with Global => null;
   --  I_x(a,b) = B_x(a,b)/B(a,b) = CDF of Beta(a,b) at x.
   --  Series / continued-fraction (Lentz); raises Invalid_Argument
   --  if A or B ≤ 0.

   function Beta_Quantile
     (P_Level : Unit_Interval; P : Beta_Params) return Unit_Interval
     with Global => null;
   --  Inverse CDF via bisection on Regularized_Incomplete_Beta.
   --  P_Level=0 → 0; P_Level=1 → 1.

   type Credible_Interval is record
      Lower, Upper : Unit_Interval := 0.0;
      Level        : Unit_Interval := 0.95;
   end record;

   function Equal_Tailed_Credible_Interval
     (P     : Beta_Params;
      Level : Unit_Interval := 0.95) return Credible_Interval
     with Pre => Level > 0.0 and then Level < 1.0, Global => null;
   --  Equal-tailed (1−α)/2 and 1−(1−α)/2 quantiles of Beta posterior.
   --  Raises Invalid_Argument if Level not in (0,1).

   function Contains
     (CI : Credible_Interval; Value : Unit_Interval) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Normal conjugate (known observation variance)
   ---------------------------------------------------------------------------

   type Normal_Params is record
      Mu      : Real := 0.0;
      Sigma2  : Positive_Real := 1.0;
   end record;
   --  N(μ, σ²) with σ² > 0.

   function Normal_Conjugate_Update
     (Prior          : Normal_Params;
      Sample_Mean    : Real;
      N              : Positive;
      Obs_Variance   : Positive_Real) return Normal_Params
     with Pre => N >= 1 and then Obs_Variance > 0.0
       and then Prior.Sigma2 > 0.0,
          Global => null;
   --  Prior N(μ0, τ0²), likelihood of mean x̄ ~ N(x̄, σ²/n) with known σ²:
   --  posterior precision 1/τn² = 1/τ0² + n/σ²;
   --  μn = τn² (μ0/τ0² + n x̄ / σ²).

   function Normal_PDF (X : Real; P : Normal_Params) return Non_Negative
     with Global => null;

   ---------------------------------------------------------------------------
   -- Evidence / Bayes factors (discrete hypotheses)
   ---------------------------------------------------------------------------

   function Discrete_Evidence
     (Likelihoods : Real_Array;
      Priors      : Real_Array) return Non_Negative
     with Global => null;
   --  Z = Σ_i P(D|H_i) P(H_i).  Arrays must share the same index
   --  bounds and length ≥ 1; priors must be non-negative and sum > 0;
   --  likelihoods ≥ 0. Raises Invalid_Argument / Capacity_Exceeded.

   function Bayes_Factor
     (Likelihood_H1, Likelihood_H2 : Real) return Positive_Real
     with Global => null;
   --  BF_12 = P(D|H1) / P(D|H2). Raises Invalid_Argument if H2
   --  likelihood is 0 (or either is negative).

   function Posterior_Odds
     (Prior_Odds, Bayes_Factor_12 : Real) return Positive_Real
     with Global => null;
   --  Posterior odds = prior odds × BF_12.

end Bayesian_Statistics;
