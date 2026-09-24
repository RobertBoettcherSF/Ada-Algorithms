--  Expectation_Maximization — Ada 2023 educational package for Wikipedia
--  "Expectation–maximization algorithm": generic EM iteration (E-step /
--  M-step) plus concrete mixture examples — (1) two-coin / Bernoulli
--  latent mixture, (2) univariate Gaussian mixture model (GMM).
--  Classic reference: Dempster, Laird & Rubin (1977). Likelihood is
--  monotone nondecreasing; converge when |ℓ^{t+1}−ℓ^t| < Tol.
--  Related siblings (README only, no deps): Ada-Baum-Welch,
--  Ada-Ordered-Subset-EM.

pragma Ada_2022;

package Expectation_Maximization
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Digits 12 for stable mixture / log-likelihood arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   Max_N : constant Positive := 4096;
   Max_K : constant Positive := 16;

   subtype Sample_Count is Natural range 0 .. Max_N;
   subtype Component_Count is Natural range 0 .. Max_K;
   subtype Sample_Index is Positive range 1 .. Max_N;
   subtype Component_Index is Positive range 1 .. Max_K;

   --  Observed continuous sample (GMM) or Bernoulli 0/1 encoded as Real.
   type Sample is array (Sample_Index range <>) of Real;

   --  Mixing weights / Bernoullis / means / variances (slots 1 .. K used).
   type Weight_Vector is array (Component_Index) of Real;
   type Prob_Vector is array (Component_Index) of Real;
   type Mean_Vector is array (Component_Index) of Real;
   type Variance_Vector is array (Component_Index) of Real;

   --  Responsibilities γ_{ik} — rows = samples, columns = components.
   type Responsibility_Matrix is
     array (Sample_Index range <>, Component_Index range <>) of Real;

   ---------------------------------------------------------------------------
   -- Model parameters
   ---------------------------------------------------------------------------

   --  Mixture of K Bernoullis: P(X=1 | Z=k) = P_k, P(Z=k) = Pi_k.
   type Bernoulli_Mixture is record
      K  : Component_Count := 2;
      Pi : Weight_Vector := [others => 0.0];
      P  : Prob_Vector := [others => 0.5];
   end record;

   --  Univariate GMM: θ = {π_k, μ_k, σ²_k}_{k=1..K}.
   type GMM_Params is record
      K      : Component_Count := 2;
      Pi     : Weight_Vector := [others => 0.0];
      Mu     : Mean_Vector := [others => 0.0];
      Sigma2 : Variance_Vector := [others => 1.0];
   end record;

   type Model_Kind is (Bernoulli_Model, GMM_Model);

   --  Fit outcome: Params (by kind) + iteration metadata.
   type Fit_Result (Kind : Model_Kind := GMM_Model) is record
      Iterations     : Natural := 0;
      Log_Likelihood : Real := 0.0;
      Converged      : Boolean := False;
      case Kind is
         when Bernoulli_Model =>
            Bernoulli : Bernoulli_Mixture;
         when GMM_Model =>
            GMM : GMM_Params;
      end case;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;
   Capacity_Exceeded   : exception;
   Did_Not_Converge    : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers / constants
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;
   --  Interior clamp for Bernoulli / mixing weights.
   Prob_Eps : constant Real := 1.0E-6;
   --  Floor for component variance σ² (avoids singularity).
   Variance_Eps : constant Real := 1.0E-6;
   --  Log-domain floor to avoid log(0).
   Log_Floor : constant Real := -1.0E30;
   Two_Pi : constant Real := 6.28318530718;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Log (X : Real) return Real
     with Pre => X > 0.0, Global => null;

   function Exp (X : Real) return Real
     with Global => null;

   function Gaussian_Pdf (X, Mu, Sigma2 : Real) return Real
     with Pre => Sigma2 > 0.0,
          Global => null,
          Post => Gaussian_Pdf'Result >= 0.0;
   --  N(x | μ, σ²) = (2πσ²)^{−1/2} exp(−(x−μ)²/(2σ²)).

   function Log_Sum_Exp (Values : Weight_Vector; K : Component_Count)
     return Real
     with Pre => K >= 1 and then K <= Max_K,
          Global => null;
   --  log Σ_{k=1..K} exp(Values(k)), numerically stable.

   function Clamp_Prob (P : Real; Eps : Real := Prob_Eps) return Real
     with Pre => Eps > 0.0 and then Eps < 0.5,
          Global => null,
          Post => Clamp_Prob'Result >= Eps
            and then Clamp_Prob'Result <= 1.0 - Eps;

   function Normalize_Weights (W : Weight_Vector; K : Component_Count)
     return Weight_Vector
     with Pre => K >= 1 and then K <= Max_K,
          Global => null;
   --  Renormalize first K entries to sum to 1; raises Degenerate_Geometry
   --  if sum ≤ 0.

   ---------------------------------------------------------------------------
   -- Bernoulli mixture (classic two-coin / latent Bernoulli)
   ---------------------------------------------------------------------------

   function Bernoulli_Log_Likelihood
     (Data   : Sample;
      Params : Bernoulli_Mixture;
      Trials : Positive := 1) return Real
     with Pre => Data'Length >= 1
       and then Params.K >= 1
       and then Params.K <= Max_K,
          Global => null;
   --  ℓ(θ) = Σ_i log Σ_k π_k Binom(x_i; Trials, p_k).
   --  Data(i) = number of heads in Trials flips (0 .. Trials).
   --  Trials=1 recovers plain Bernoulli.

   procedure Bernoulli_E_Step
     (Data   : Sample;
      Params : Bernoulli_Mixture;
      Gamma  : out Responsibility_Matrix;
      Trials : Positive := 1)
     with Pre => Data'Length >= 1
       and then Params.K >= 1
       and then Params.K <= Max_K
       and then Gamma'Length (1) = Data'Length
       and then Gamma'First (1) = Data'First
       and then Gamma'Length (2) >= Params.K
       and then Gamma'First (2) = 1,
          Global => null;
   --  γ_{ik} ∝ π_k p_k^{x_i} (1−p_k)^{Trials−x_i}; rows sum to 1.

   function Bernoulli_M_Step
     (Data   : Sample;
      Gamma  : Responsibility_Matrix;
      K      : Component_Count;
      Trials : Positive := 1) return Bernoulli_Mixture
     with Pre => Data'Length >= 1
       and then K >= 1
       and then K <= Max_K
       and then Gamma'Length (1) = Data'Length
       and then Gamma'First (1) = Data'First
       and then Gamma'Length (2) >= K
       and then Gamma'First (2) = 1,
          Global => null;
   --  π_k = N_k/N; p_k = (Σ_i γ_{ik} x_i) / (N_k · Trials) with clamps.

   function Bernoulli_EM_Fit
     (Data          : Sample;
      Init          : Bernoulli_Mixture;
      Trials        : Positive := 1;
      Max_Iter      : Positive := 100;
      Tol           : Real := 1.0E-8;
      Raise_On_Fail : Boolean := False) return Fit_Result
     with Pre => Data'Length >= 1
       and then Init.K >= 1
       and then Init.K <= Max_K
       and then Tol > 0.0
       and then Data'Length <= Max_N,
          Global => null;
   --  Iterate E/M until |Δℓ| < Tol. Result.Kind = Bernoulli_Model.
   --  Classic two-coin: each observation is heads-count in Trials flips.
   --  Raises Capacity_Exceeded / Invalid_Argument / Did_Not_Converge
   --  (latter only when Raise_On_Fail).

   ---------------------------------------------------------------------------
   -- Univariate Gaussian mixture model (GMM)
   ---------------------------------------------------------------------------

   function GMM_Log_Likelihood
     (Data : Sample; Params : GMM_Params) return Real
     with Pre => Data'Length >= 1
       and then Params.K >= 1
       and then Params.K <= Max_K,
          Global => null;
   --  ℓ(θ) = Σ_i log Σ_k π_k N(x_i | μ_k, σ²_k)  via log-sum-exp.

   procedure GMM_E_Step
     (Data   : Sample;
      Params : GMM_Params;
      Gamma  : out Responsibility_Matrix)
     with Pre => Data'Length >= 1
       and then Params.K >= 1
       and then Params.K <= Max_K
       and then Gamma'Length (1) = Data'Length
       and then Gamma'First (1) = Data'First
       and then Gamma'Length (2) >= Params.K
       and then Gamma'First (2) = 1,
          Global => null;
   --  γ_{ik} = π_k N(x_i|μ_k,σ²_k) / Σ_j …  (stable log-domain).

   function GMM_M_Step
     (Data  : Sample;
      Gamma : Responsibility_Matrix;
      K     : Component_Count) return GMM_Params
     with Pre => Data'Length >= 1
       and then K >= 1
       and then K <= Max_K
       and then Gamma'Length (1) = Data'Length
       and then Gamma'First (1) = Data'First
       and then Gamma'Length (2) >= K
       and then Gamma'First (2) = 1,
          Global => null;
   --  N_k=Σ γ; π=N_k/N; μ=Σ γ x / N_k; σ² clamped ≥ Variance_Eps.

   function Random_Init_GMM
     (Data : Sample;
      K    : Component_Count;
      Seed : Natural := 1) return GMM_Params
     with Pre => Data'Length >= 1
       and then K >= 1
       and then K <= Max_K
       and then Data'Length <= Max_N,
          Global => null;
   --  Seeded init: equal π, means from spaced sample quantiles / jitter,
   --  σ² from global sample variance (floored).

   function GMM_EM_Fit
     (Data          : Sample;
      Init          : GMM_Params;
      Max_Iter      : Positive := 100;
      Tol           : Real := 1.0E-8;
      Raise_On_Fail : Boolean := False) return Fit_Result
     with Pre => Data'Length >= 1
       and then Init.K >= 1
       and then Init.K <= Max_K
       and then Tol > 0.0
       and then Data'Length <= Max_N,
          Global => null;
   --  Iterate E/M until |Δℓ| < Tol. Result.Kind = GMM_Model.

   function Make_Equal_Bernoulli (K : Component_Count; P1, P2 : Real)
     return Bernoulli_Mixture
     with Pre => K >= 1 and then K <= Max_K,
          Global => null;
   --  Convenience: equal π, component 1 gets P1, others get P2 (K=2 usual).

   function Make_GMM
     (K      : Component_Count;
      Pi     : Weight_Vector;
      Mu     : Mean_Vector;
      Sigma2 : Variance_Vector) return GMM_Params
     with Pre => K >= 1 and then K <= Max_K,
          Global => null;

end Expectation_Maximization;
