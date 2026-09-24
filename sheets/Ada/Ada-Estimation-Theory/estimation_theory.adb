--  Estimation_Theory body — sample statistics, MoM, MLE, CRLB helpers.

pragma Ada_2022;

package body Estimation_Theory
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   procedure Require_Nonempty (X : Sample) is
   begin
      if X'Length = 0 then
         raise Invalid_Argument with "empty sample";
      end if;
      if X'Length > Max_N then
         raise Capacity_Exceeded with "sample longer than Max_N";
      end if;
   end Require_Nonempty;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   -------------------------------------------------------------------------
   -- Sample statistics
   -------------------------------------------------------------------------

   function Mean (X : Sample) return Real is
      S : Real := 0.0;
      N : constant Real := Real (X'Length);
   begin
      Require_Nonempty (X);
      for I in X'Range loop
         S := S + X (I);
      end loop;
      return S / N;
   end Mean;

   function Variance
     (X        : Sample;
      Unbiased : Boolean := True) return Real
   is
      M   : Real;
      Acc : Real := 0.0;
      N   : constant Natural := X'Length;
      Den : Real;
   begin
      Require_Nonempty (X);
      if Unbiased and then N < 2 then
         raise Degenerate_Geometry
           with "unbiased variance needs N >= 2";
      end if;
      M := Mean (X);
      for I in X'Range loop
         Acc := Acc + (X (I) - M) ** 2;
      end loop;
      if Unbiased then
         Den := Real (N - 1);
      else
         Den := Real (N);
      end if;
      return Acc / Den;
   end Variance;

   function Sample_Maximum (X : Sample) return Real is
      M : Real;
   begin
      Require_Nonempty (X);
      M := X (X'First);
      for I in X'Range loop
         if X (I) > M then
            M := X (I);
         end if;
      end loop;
      return M;
   end Sample_Maximum;

   function Sample_Minimum (X : Sample) return Real is
      M : Real;
   begin
      Require_Nonempty (X);
      M := X (X'First);
      for I in X'Range loop
         if X (I) < M then
            M := X (I);
         end if;
      end loop;
      return M;
   end Sample_Minimum;

   -------------------------------------------------------------------------
   -- Error metrics
   -------------------------------------------------------------------------

   function Bias (Estimate, Truth : Real) return Real is
   begin
      return Estimate - Truth;
   end Bias;

   function MSE (Estimate, Truth : Real) return Real is
      E : constant Real := Estimate - Truth;
   begin
      return E * E;
   end MSE;

   function Variance_Of_Estimator
     (Estimates : Sample;
      Mean_Est  : Real) return Real
   is
      Acc : Real := 0.0;
      N   : constant Real := Real (Estimates'Length);
   begin
      Require_Nonempty (Estimates);
      for I in Estimates'Range loop
         Acc := Acc + (Estimates (I) - Mean_Est) ** 2;
      end loop;
      return Acc / N;
   end Variance_Of_Estimator;

   function MSE_From_Bias_Var (B, V : Real) return Real is
   begin
      return B * B + V;
   end MSE_From_Bias_Var;

   -------------------------------------------------------------------------
   -- Method of moments
   -------------------------------------------------------------------------

   function MoM_Exponential_Rate (X : Sample) return Real is
      M : Real;
   begin
      Require_Nonempty (X);
      M := Mean (X);
      if M <= 0.0 then
         raise Degenerate_Geometry
           with "exponential MoM requires positive mean";
      end if;
      return 1.0 / M;
   end MoM_Exponential_Rate;

   function MoM_Uniform_Theta (X : Sample) return Real is
   begin
      Require_Nonempty (X);
      return 2.0 * Mean (X);
   end MoM_Uniform_Theta;

   -------------------------------------------------------------------------
   -- Maximum likelihood
   -------------------------------------------------------------------------

   function MLE_Gaussian_Mean (X : Sample) return Real is
   begin
      return Mean (X);
   end MLE_Gaussian_Mean;

   function MLE_Gaussian_Variance
     (X           : Sample;
      Known_Mean  : Boolean := False;
      Mu          : Real := 0.0) return Real
   is
      Acc : Real := 0.0;
      M   : Real;
      N   : constant Real := Real (X'Length);
   begin
      Require_Nonempty (X);
      if Known_Mean then
         M := Mu;
      else
         M := Mean (X);
      end if;
      for I in X'Range loop
         Acc := Acc + (X (I) - M) ** 2;
      end loop;
      return Acc / N;
   end MLE_Gaussian_Variance;

   function MLE_Bernoulli_P (X : Sample) return Real is
      S : Real := 0.0;
      N : constant Real := Real (X'Length);
   begin
      Require_Nonempty (X);
      for I in X'Range loop
         if not (Near (X (I), 0.0) or else Near (X (I), 1.0)) then
            raise Invalid_Argument
              with "Bernoulli sample entries must be 0 or 1";
         end if;
         S := S + X (I);
      end loop;
      return S / N;
   end MLE_Bernoulli_P;

   function MLE_Uniform_Theta (X : Sample) return Real is
   begin
      return Sample_Maximum (X);
   end MLE_Uniform_Theta;

   function MLE_AWGN_Constant (X : Sample) return Real is
   begin
      --  Wikipedia: Â_MLE = (1/N) Σ x[n] for x[n]=A+w[n], w~N(0,σ²).
      return Mean (X);
   end MLE_AWGN_Constant;

   function MLE_Exponential_Rate (X : Sample) return Real is
   begin
      return MoM_Exponential_Rate (X);
   end MLE_Exponential_Rate;

   -------------------------------------------------------------------------
   -- Fisher / CRLB
   -------------------------------------------------------------------------

   function Fisher_Info_Gaussian_Mean
     (N : Positive; Sigma2 : Real) return Real
   is
   begin
      if Sigma2 <= 0.0 then
         raise Degenerate_Geometry with "Sigma2 must be positive";
      end if;
      if N > Max_N then
         raise Capacity_Exceeded with "N > Max_N";
      end if;
      return Real (N) / Sigma2;
   end Fisher_Info_Gaussian_Mean;

   function CRLB_Gaussian_Mean
     (N : Positive; Sigma2 : Real) return Real
   is
   begin
      return 1.0 / Fisher_Info_Gaussian_Mean (N, Sigma2);
   end CRLB_Gaussian_Mean;

   function Fisher_Info_Bernoulli
     (N : Positive; P : Real) return Real
   is
      PQ : Real;
   begin
      if P <= 0.0 or else P >= 1.0 then
         raise Degenerate_Geometry with "Bernoulli p must be in (0,1)";
      end if;
      if N > Max_N then
         raise Capacity_Exceeded with "N > Max_N";
      end if;
      PQ := P * (1.0 - P);
      return Real (N) / PQ;
   end Fisher_Info_Bernoulli;

   function CRLB_Bernoulli
     (N : Positive; P : Real) return Real
   is
   begin
      return 1.0 / Fisher_Info_Bernoulli (N, P);
   end CRLB_Bernoulli;

   function Analytic_Var_Sample_Mean
     (N : Positive; Sigma2 : Real) return Real
   is
   begin
      if Sigma2 < 0.0 then
         raise Invalid_Argument with "Sigma2 must be nonnegative";
      end if;
      if N > Max_N then
         raise Capacity_Exceeded with "N > Max_N";
      end if;
      return Sigma2 / Real (N);
   end Analytic_Var_Sample_Mean;

   function Analytic_Var_Bernoulli_Proportion
     (N : Positive; P : Real) return Real
   is
   begin
      if P < 0.0 or else P > 1.0 then
         raise Invalid_Argument with "p must be in [0,1]";
      end if;
      if N > Max_N then
         raise Capacity_Exceeded with "N > Max_N";
      end if;
      return (P * (1.0 - P)) / Real (N);
   end Analytic_Var_Bernoulli_Proportion;

   function Bias_Uniform_Max_Analytic
     (Theta : Real; N : Positive) return Real
   is
   begin
      if Theta <= 0.0 then
         raise Invalid_Argument with "Theta must be positive";
      end if;
      if N > Max_N then
         raise Capacity_Exceeded with "N > Max_N";
      end if;
      --  E[max] − θ = N·θ/(N+1) − θ = −θ/(N+1).
      return -Theta / Real (N + 1);
   end Bias_Uniform_Max_Analytic;

   function Expected_Uniform_Max
     (Theta : Real; N : Positive) return Real
   is
   begin
      if Theta <= 0.0 then
         raise Invalid_Argument with "Theta must be positive";
      end if;
      if N > Max_N then
         raise Capacity_Exceeded with "N > Max_N";
      end if;
      return Real (N) * Theta / Real (N + 1);
   end Expected_Uniform_Max;

end Estimation_Theory;
