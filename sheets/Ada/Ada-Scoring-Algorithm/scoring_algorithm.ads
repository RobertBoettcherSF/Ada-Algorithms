--  Scoring_Algorithm — Ada 2023 educational package for Wikipedia
--  "Scoring algorithm" / Fisher's scoring: Newton-like MLE iteration using
--  the score V(θ) and either observed information J or expected Fisher
--  information I.
--  θ_{m+1} = θ_m + J(θ_m)^{-1} V(θ_m)   (observed-information Newton)
--  θ_{m+1} = θ_m + I(θ_m)^{-1} V(θ_m)   (Fisher scoring)
--  Concrete closed-form score/info for Bernoulli, Poisson, Normal mean
--  (known σ²), and Exponential rate; plus a generic scalar scoring engine.
--  Related: Score (statistics), Fisher information, Longford (1987).

pragma Ada_2022;

package Scoring_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Digits 12 for stable MLE / information arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Samples : constant Positive := 4096;
   subtype Sample_Count is Natural range 0 .. Max_Samples;
   subtype Sample_Index is Positive range 1 .. Max_Samples;

   --  Real-valued i.i.d. sample (Bernoulli as 0/1, counts, continuous, …).
   type Sample is array (Sample_Index range <>) of Real;

   type Scoring_Kind is (Fisher_Expected, Observed_Newton);

   type Scoring_Result is record
      Estimate    : Real := 0.0;
      Iterations  : Natural := 0;
      Converged   : Boolean := False;
      Last_Score  : Real := 0.0;
      Last_Info   : Real := 0.0;
      Kind        : Scoring_Kind := Fisher_Expected;
   end record;

   --  Access-to-function callbacks for the generic scalar engine.
   type Score_Fn is access function (Theta : Real; Data : Sample) return Real;
   type Info_Fn  is access function (Theta : Real; Data : Sample) return Real;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument      : exception;
   Singular_Information  : exception;
   Degenerate_Geometry   : exception renames Singular_Information;
   Capacity_Exceeded     : exception;
   Did_Not_Converge      : exception;
   Empty_Sample          : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;
   --  Interior clamp for Bernoulli p ∈ (eps, 1−eps).
   Prob_Eps    : constant Real := 1.0E-6;
   --  Absolute |Info| below which we treat information as singular.
   Info_Singularity : constant Real := 1.0E-14;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Clamp_Unit_Interval (P : Real; Eps : Real := Prob_Eps) return Real
     with Pre => Eps > 0.0 and then Eps < 0.5,
          Global => null,
          Post => Clamp_Unit_Interval'Result >= Eps
            and then Clamp_Unit_Interval'Result <= 1.0 - Eps;
   --  Map p into (Eps, 1−Eps) for stable Bernoulli starts / steps.

   function Sample_Mean (Data : Sample) return Real
     with Pre => Data'Length >= 1,
          Global => null;
   --  Raises Empty_Sample if Length = 0 (also Pre when checks on).

   function Sample_Sum (Data : Sample) return Real
     with Global => null;

   function Count_Successes (Data : Sample) return Natural
     with Global => null;
   --  Count of entries treated as success (value >= 0.5) for Bernoulli.

   ---------------------------------------------------------------------------
   -- Generic scalar step / iteration engine
   ---------------------------------------------------------------------------

   function Fisher_Step
     (Theta : Real;
      Score : Real;
      Info  : Real) return Real
     with Global => null;
   --  One update: Theta + Score/Info. Raises Singular_Information if
   --  |Info| < Info_Singularity.

   function Run_Scalar_Scoring
     (Data          : Sample;
      Start         : Real;
      Score_Of      : Score_Fn;
      Info_Of       : Info_Fn;
      Kind          : Scoring_Kind := Fisher_Expected;
      Max_Iter      : Positive := 50;
      Tol           : Real := 1.0E-10;
      Raise_On_Fail : Boolean := True;
      Lower         : Real := Real'First;
      Upper         : Real := Real'Last) return Scoring_Result
     with Pre => Data'Length >= 1
       and then Score_Of /= null
       and then Info_Of /= null
       and then Tol > 0.0
       and then Lower <= Upper,
          Global => null;
   --  Iterate θ ← θ + V/I (or V/J) until |Δθ| <= Tol or |V| <= Tol.
   --  After each update, project θ into [Lower, Upper] (optional domain
   --  bounds; defaults are unbounded). Score/info are re-evaluated at the
   --  projected point before the convergence check.
   --  Raises Empty_Sample / Singular_Information / Did_Not_Converge
   --  (latter only when Raise_On_Fail).

   ---------------------------------------------------------------------------
   -- Bernoulli / Binomial proportion θ = p ∈ (0,1)
   ---------------------------------------------------------------------------

   function Bernoulli_Score
     (P : Real; K : Natural; N : Positive) return Real
     with Pre => P > 0.0 and then P < 1.0 and then K <= N,
          Global => null;
   --  V(p) = k/p − (n−k)/(1−p).

   function Bernoulli_Fisher_Info
     (P : Real; N : Positive) return Real
     with Pre => P > 0.0 and then P < 1.0,
          Global => null,
          Post => Bernoulli_Fisher_Info'Result > 0.0;
   --  I(p) = n / (p(1−p)).

   function Bernoulli_Observed_Info
     (P : Real; K : Natural; N : Positive) return Real
     with Pre => P > 0.0 and then P < 1.0 and then K <= N,
          Global => null;
   --  J(p) = k/p² + (n−k)/(1−p)².

   function Bernoulli_MLE (K : Natural; N : Positive) return Real
     with Pre => K <= N,
          Global => null;
   --  ˆp = k/n (may be 0 or 1).

   function Bernoulli_Score_Sample (P : Real; Data : Sample) return Real
     with Pre => P > 0.0 and then P < 1.0 and then Data'Length >= 1,
          Global => null;

   function Bernoulli_Fisher_Info_Sample (P : Real; Data : Sample) return Real
     with Pre => P > 0.0 and then P < 1.0 and then Data'Length >= 1,
          Global => null;

   function Bernoulli_Observed_Info_Sample
     (P : Real; Data : Sample) return Real
     with Pre => P > 0.0 and then P < 1.0 and then Data'Length >= 1,
          Global => null;

   function Fit_Bernoulli
     (Data          : Sample;
      Start         : Real := 0.5;
      Kind          : Scoring_Kind := Fisher_Expected;
      Max_Iter      : Positive := 50;
      Tol           : Real := 1.0E-10;
      Raise_On_Fail : Boolean := True) return Scoring_Result
     with Pre => Data'Length >= 1 and then Tol > 0.0,
          Global => null;

   function Fit_Bernoulli_Counts
     (K             : Natural;
      N             : Positive;
      Start         : Real := 0.5;
      Kind          : Scoring_Kind := Fisher_Expected;
      Max_Iter      : Positive := 50;
      Tol           : Real := 1.0E-10;
      Raise_On_Fail : Boolean := True) return Scoring_Result
     with Pre => K <= N and then Tol > 0.0,
          Global => null;

   ---------------------------------------------------------------------------
   -- Poisson rate θ = λ > 0
   ---------------------------------------------------------------------------

   function Poisson_Score (Lambda : Real; Data : Sample) return Real
     with Pre => Lambda > 0.0 and then Data'Length >= 1,
          Global => null;
   --  V(λ) = −n + (Σ x_i)/λ.

   function Poisson_Fisher_Info (Lambda : Real; Data : Sample) return Real
     with Pre => Lambda > 0.0 and then Data'Length >= 1,
          Global => null,
          Post => Poisson_Fisher_Info'Result > 0.0;
   --  I(λ) = n/λ.

   function Poisson_Observed_Info (Lambda : Real; Data : Sample) return Real
     with Pre => Lambda > 0.0 and then Data'Length >= 1,
          Global => null;
   --  J(λ) = (Σ x_i)/λ².

   function Poisson_MLE (Data : Sample) return Real
     with Pre => Data'Length >= 1,
          Global => null;
   --  ˆλ = sample mean.

   function Fit_Poisson
     (Data          : Sample;
      Start         : Real := 1.0;
      Kind          : Scoring_Kind := Fisher_Expected;
      Max_Iter      : Positive := 50;
      Tol           : Real := 1.0E-10;
      Raise_On_Fail : Boolean := True) return Scoring_Result
     with Pre => Data'Length >= 1 and then Tol > 0.0,
          Global => null;

   ---------------------------------------------------------------------------
   -- Normal mean θ = μ (known variance σ²)
   ---------------------------------------------------------------------------

   function Normal_Mean_Score
     (Mu : Real; Sigma2 : Real; Data : Sample) return Real
     with Pre => Sigma2 > 0.0 and then Data'Length >= 1,
          Global => null;
   --  V(μ) = Σ(x_i − μ)/σ².

   function Normal_Mean_Fisher_Info
     (Sigma2 : Real; N : Positive) return Real
     with Pre => Sigma2 > 0.0,
          Global => null,
          Post => Normal_Mean_Fisher_Info'Result > 0.0;
   --  I(μ) = n/σ² (independent of μ).

   function Normal_Mean_Observed_Info
     (Sigma2 : Real; N : Positive) return Real
     with Pre => Sigma2 > 0.0,
          Global => null,
          Post => Normal_Mean_Observed_Info'Result > 0.0;
   --  J(μ) = n/σ² (= I for this model).

   function Normal_Mean_MLE (Data : Sample) return Real
     with Pre => Data'Length >= 1,
          Global => null;

   function Fit_Normal_Mean
     (Data          : Sample;
      Sigma2        : Real;
      Start         : Real := 0.0;
      Kind          : Scoring_Kind := Fisher_Expected;
      Max_Iter      : Positive := 50;
      Tol           : Real := 1.0E-10;
      Raise_On_Fail : Boolean := True) return Scoring_Result
     with Pre => Data'Length >= 1
       and then Sigma2 > 0.0
       and then Tol > 0.0;

   ---------------------------------------------------------------------------
   -- Exponential rate θ = λ > 0  (pdf f(x)=λ e^{−λx}, x>0)
   ---------------------------------------------------------------------------

   function Exponential_Score (Lambda : Real; Data : Sample) return Real
     with Pre => Lambda > 0.0 and then Data'Length >= 1,
          Global => null;
   --  V(λ) = n/λ − Σ x_i.

   function Exponential_Fisher_Info
     (Lambda : Real; Data : Sample) return Real
     with Pre => Lambda > 0.0 and then Data'Length >= 1,
          Global => null,
          Post => Exponential_Fisher_Info'Result > 0.0;
   --  I(λ) = n/λ².

   function Exponential_Observed_Info
     (Lambda : Real; Data : Sample) return Real
     with Pre => Lambda > 0.0 and then Data'Length >= 1,
          Global => null,
          Post => Exponential_Observed_Info'Result > 0.0;
   --  J(λ) = n/λ² (= I for the rate parameterization).

   function Exponential_MLE (Data : Sample) return Real
     with Pre => Data'Length >= 1,
          Global => null;
   --  ˆλ = 1 / sample mean (requires positive mean).

   function Fit_Exponential
     (Data          : Sample;
      Start         : Real := 1.0;
      Kind          : Scoring_Kind := Fisher_Expected;
      Max_Iter      : Positive := 50;
      Tol           : Real := 1.0E-10;
      Raise_On_Fail : Boolean := True) return Scoring_Result
     with Pre => Data'Length >= 1 and then Tol > 0.0,
          Global => null;

end Scoring_Algorithm;
