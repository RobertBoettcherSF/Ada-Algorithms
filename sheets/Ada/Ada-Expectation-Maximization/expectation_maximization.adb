--  Expectation_Maximization body — EM helpers, Bernoulli mixture, univariate GMM.

pragma Ada_2022;

with Ada.Numerics.Generic_Elementary_Functions;
with Ada.Numerics.Float_Random;

package body Expectation_Maximization
  with SPARK_Mode => Off
is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Real);
   package RNG renames Ada.Numerics.Float_Random;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Log (X : Real) return Real is
   begin
      if X <= 0.0 then
         raise Invalid_Argument;
      end if;
      return Math.Log (X);
   end Log;

   function Exp (X : Real) return Real is
   begin
      --  Soft clamp extreme exponents to avoid overflow.
      if X > 700.0 then
         return Math.Exp (700.0);
      elsif X < -700.0 then
         return 0.0;
      else
         return Math.Exp (X);
      end if;
   end Exp;

   function Gaussian_Pdf (X, Mu, Sigma2 : Real) return Real is
      Diff : constant Real := X - Mu;
      Norm : Real;
   begin
      if Sigma2 <= 0.0 then
         raise Degenerate_Geometry;
      end if;
      Norm := 1.0 / Math.Sqrt (Two_Pi * Sigma2);
      return Norm * Exp (-(Diff * Diff) / (2.0 * Sigma2));
   end Gaussian_Pdf;

   function Log_Gaussian (X, Mu, Sigma2 : Real) return Real is
      Diff : constant Real := X - Mu;
   begin
      if Sigma2 <= 0.0 then
         raise Degenerate_Geometry;
      end if;
      return -0.5 * (Math.Log (Two_Pi * Sigma2)
        + (Diff * Diff) / Sigma2);
   end Log_Gaussian;

   function Log_Sum_Exp (Values : Weight_Vector; K : Component_Count)
     return Real
   is
      Max_V : Real := Values (1);
      Acc   : Real := 0.0;
   begin
      if K < 1 then
         raise Invalid_Argument;
      end if;
      for J in 2 .. K loop
         if Values (J) > Max_V then
            Max_V := Values (J);
         end if;
      end loop;
      if Max_V <= Log_Floor / 2.0 then
         return Log_Floor;
      end if;
      for J in 1 .. K loop
         Acc := Acc + Exp (Values (J) - Max_V);
      end loop;
      if Acc <= 0.0 then
         return Log_Floor;
      end if;
      return Max_V + Math.Log (Acc);
   end Log_Sum_Exp;

   function Clamp_Prob (P : Real; Eps : Real := Prob_Eps) return Real is
   begin
      if P < Eps then
         return Eps;
      elsif P > 1.0 - Eps then
         return 1.0 - Eps;
      else
         return P;
      end if;
   end Clamp_Prob;

   function Normalize_Weights (W : Weight_Vector; K : Component_Count)
     return Weight_Vector
   is
      S   : Real := 0.0;
      Out_W : Weight_Vector := [others => 0.0];
   begin
      for J in 1 .. K loop
         if W (J) > 0.0 then
            S := S + W (J);
         end if;
      end loop;
      if S <= 0.0 then
         raise Degenerate_Geometry;
      end if;
      for J in 1 .. K loop
         if W (J) > 0.0 then
            Out_W (J) := W (J) / S;
         else
            Out_W (J) := 0.0;
         end if;
      end loop;
      return Out_W;
   end Normalize_Weights;



   function Clamp_Count (X : Real; Trials : Positive) return Real is
      C : Real := X;
   begin
      if C < 0.0 then
         C := 0.0;
      elsif C > Real (Trials) then
         C := Real (Trials);
      end if;
      return C;
   end Clamp_Count;

   --  log p^x (1-p)^{m-x}  (binomial coefficient omitted; cancels in γ).
   function Log_Binom_Kernel
     (X : Real; P : Real; Trials : Positive) return Real
   is
      XX : constant Real := Clamp_Count (X, Trials);
      PP : constant Real := Clamp_Prob (P);
      M  : constant Real := Real (Trials);
   begin
      return XX * Math.Log (PP) + (M - XX) * Math.Log (1.0 - PP);
   end Log_Binom_Kernel;

   procedure Check_Capacity (N : Natural) is
   begin
      if N > Max_N then
         raise Capacity_Exceeded;
      end if;
   end Check_Capacity;

   procedure Validate_Bernoulli (Params : Bernoulli_Mixture) is
      S : Real := 0.0;
   begin
      if Params.K < 1 then
         raise Invalid_Argument;
      end if;
      for J in 1 .. Params.K loop
         if Params.Pi (J) < 0.0 then
            raise Invalid_Argument;
         end if;
         S := S + Params.Pi (J);
         if Params.P (J) <= 0.0 or else Params.P (J) >= 1.0 then
            --  Allow boundary only after clamp elsewhere; reject NaN-ish.
            if Params.P (J) < 0.0 or else Params.P (J) > 1.0 then
               raise Invalid_Argument;
            end if;
         end if;
      end loop;
      if S <= 0.0 then
         raise Degenerate_Geometry;
      end if;
   end Validate_Bernoulli;

   procedure Validate_GMM (Params : GMM_Params) is
      S : Real := 0.0;
   begin
      if Params.K < 1 then
         raise Invalid_Argument;
      end if;
      for J in 1 .. Params.K loop
         if Params.Pi (J) < 0.0 then
            raise Invalid_Argument;
         end if;
         S := S + Params.Pi (J);
         if Params.Sigma2 (J) <= 0.0 then
            raise Degenerate_Geometry;
         end if;
      end loop;
      if S <= 0.0 then
         raise Degenerate_Geometry;
      end if;
   end Validate_GMM;

   -------------------------------------------------------------------------
   -- Bernoulli mixture
   -------------------------------------------------------------------------

   function Bernoulli_Log_Likelihood
     (Data   : Sample;
      Params : Bernoulli_Mixture;
      Trials : Positive := 1) return Real
   is
      K   : constant Component_Count := Params.K;
      Acc : Real := 0.0;
      Logs : Weight_Vector;
      Pi_N : Weight_Vector;
   begin
      if Data'Length = 0 then
         raise Invalid_Argument;
      end if;
      Validate_Bernoulli (Params);
      Pi_N := Normalize_Weights (Params.Pi, K);
      for I in Data'Range loop
         for J in 1 .. K loop
            Logs (J) := Math.Log (Clamp_Prob (Pi_N (J), Prob_Eps / Real (K)))
              + Log_Binom_Kernel (Data (I), Params.P (J), Trials);
         end loop;
         --  Clear unused slots for Log_Sum_Exp max scan safety.
         for J in K + 1 .. Max_K loop
            Logs (J) := Log_Floor;
         end loop;
         Acc := Acc + Log_Sum_Exp (Logs, K);
      end loop;
      return Acc;
   end Bernoulli_Log_Likelihood;

   procedure Bernoulli_E_Step
     (Data   : Sample;
      Params : Bernoulli_Mixture;
      Gamma  : out Responsibility_Matrix;
      Trials : Positive := 1)
   is
      K    : constant Component_Count := Params.K;
      Pi_N : Weight_Vector;
      Logs : Weight_Vector;
      LSE  : Real;
   begin
      if Data'Length = 0 or else K < 1 then
         raise Invalid_Argument;
      end if;
      if Gamma'Length (1) /= Data'Length
        or else Gamma'First (1) /= Data'First
        or else Gamma'Length (2) < K
        or else Gamma'First (2) /= 1
      then
         raise Invalid_Argument;
      end if;
      Validate_Bernoulli (Params);
      Pi_N := Normalize_Weights (Params.Pi, K);

      for I in Data'Range loop
         for J in 1 .. K loop
            Logs (J) := Math.Log (Clamp_Prob (Pi_N (J), Prob_Eps / Real (K)))
              + Log_Binom_Kernel (Data (I), Params.P (J), Trials);
         end loop;
         for J in K + 1 .. Max_K loop
            Logs (J) := Log_Floor;
         end loop;
         LSE := Log_Sum_Exp (Logs, K);
         for J in 1 .. K loop
            Gamma (I, J) := Exp (Logs (J) - LSE);
         end loop;
         for J in K + 1 .. Gamma'Last (2) loop
            Gamma (I, J) := 0.0;
         end loop;
      end loop;
   end Bernoulli_E_Step;

   function Bernoulli_M_Step
     (Data   : Sample;
      Gamma  : Responsibility_Matrix;
      K      : Component_Count;
      Trials : Positive := 1) return Bernoulli_Mixture
   is
      N      : constant Real := Real (Data'Length);
      M      : constant Real := Real (Trials);
      Result : Bernoulli_Mixture;
      Nk     : Real;
      Wx     : Real;
   begin
      if Data'Length = 0 or else K < 1 then
         raise Invalid_Argument;
      end if;
      if Gamma'Length (1) /= Data'Length
        or else Gamma'First (1) /= Data'First
        or else Gamma'Length (2) < K
      then
         raise Invalid_Argument;
      end if;

      Result.K := K;
      Result.Pi := [others => 0.0];
      Result.P := [others => 0.5];

      for J in 1 .. K loop
         Nk := 0.0;
         Wx := 0.0;
         for I in Data'Range loop
            Nk := Nk + Gamma (I, J);
            Wx := Wx + Gamma (I, J) * Clamp_Count (Data (I), Trials);
         end loop;
         if Nk <= 0.0 then
            Result.Pi (J) := Prob_Eps / Real (K);
            Result.P (J) := 0.5;
         else
            Result.Pi (J) := Nk / N;
            --  p = (expected heads) / (expected trials)
            Result.P (J) := Clamp_Prob (Wx / (Nk * M));
         end if;
      end loop;
      Result.Pi := Normalize_Weights (Result.Pi, K);
      return Result;
   end Bernoulli_M_Step;

   function Bernoulli_EM_Fit
     (Data          : Sample;
      Init          : Bernoulli_Mixture;
      Trials        : Positive := 1;
      Max_Iter      : Positive := 100;
      Tol           : Real := 1.0E-8;
      Raise_On_Fail : Boolean := False) return Fit_Result
   is
      K     : constant Component_Count := Init.K;
      Params : Bernoulli_Mixture := Init;
      Gamma : Responsibility_Matrix (Data'Range, 1 .. K);
      Prev_LL, Curr_LL : Real;
      Iter  : Natural := 0;
      Done  : Boolean := False;
      Outcome : Fit_Result (Kind => Bernoulli_Model);
   begin
      Check_Capacity (Data'Length);
      if Data'Length = 0 or else K < 1 then
         raise Invalid_Argument;
      end if;
      Validate_Bernoulli (Init);

      --  Clamp / normalize start.
      Params.Pi := Normalize_Weights (Params.Pi, K);
      for J in 1 .. K loop
         Params.P (J) := Clamp_Prob (Params.P (J));
      end loop;

      Curr_LL := Bernoulli_Log_Likelihood (Data, Params, Trials);

      for T in 1 .. Max_Iter loop
         Iter := T;
         Prev_LL := Curr_LL;
         Bernoulli_E_Step (Data, Params, Gamma, Trials);
         Params := Bernoulli_M_Step (Data, Gamma, K, Trials);
         Curr_LL := Bernoulli_Log_Likelihood (Data, Params, Trials);
         if abs (Curr_LL - Prev_LL) < Tol then
            Done := True;
            exit;
         end if;
      end loop;

      if not Done and then Raise_On_Fail then
         raise Did_Not_Converge;
      end if;

      Outcome.Bernoulli := Params;
      Outcome.Iterations := Iter;
      Outcome.Log_Likelihood := Curr_LL;
      Outcome.Converged := Done;
      return Outcome;
   end Bernoulli_EM_Fit;

   -------------------------------------------------------------------------
   -- GMM
   -------------------------------------------------------------------------

   function GMM_Log_Likelihood
     (Data : Sample; Params : GMM_Params) return Real
   is
      K    : constant Component_Count := Params.K;
      Acc  : Real := 0.0;
      Logs : Weight_Vector;
      Pi_N : Weight_Vector;
   begin
      if Data'Length = 0 then
         raise Invalid_Argument;
      end if;
      Validate_GMM (Params);
      Pi_N := Normalize_Weights (Params.Pi, K);
      for I in Data'Range loop
         for J in 1 .. K loop
            Logs (J) := Math.Log (Clamp_Prob (Pi_N (J), Prob_Eps / Real (K)))
              + Log_Gaussian (Data (I), Params.Mu (J), Params.Sigma2 (J));
         end loop;
         for J in K + 1 .. Max_K loop
            Logs (J) := Log_Floor;
         end loop;
         Acc := Acc + Log_Sum_Exp (Logs, K);
      end loop;
      return Acc;
   end GMM_Log_Likelihood;

   procedure GMM_E_Step
     (Data   : Sample;
      Params : GMM_Params;
      Gamma  : out Responsibility_Matrix)
   is
      K    : constant Component_Count := Params.K;
      Pi_N : Weight_Vector;
      Logs : Weight_Vector;
      LSE  : Real;
   begin
      if Data'Length = 0 or else K < 1 then
         raise Invalid_Argument;
      end if;
      if Gamma'Length (1) /= Data'Length
        or else Gamma'First (1) /= Data'First
        or else Gamma'Length (2) < K
        or else Gamma'First (2) /= 1
      then
         raise Invalid_Argument;
      end if;
      Validate_GMM (Params);
      Pi_N := Normalize_Weights (Params.Pi, K);

      for I in Data'Range loop
         for J in 1 .. K loop
            Logs (J) := Math.Log (Clamp_Prob (Pi_N (J), Prob_Eps / Real (K)))
              + Log_Gaussian (Data (I), Params.Mu (J), Params.Sigma2 (J));
         end loop;
         for J in K + 1 .. Max_K loop
            Logs (J) := Log_Floor;
         end loop;
         LSE := Log_Sum_Exp (Logs, K);
         for J in 1 .. K loop
            Gamma (I, J) := Exp (Logs (J) - LSE);
         end loop;
         for J in K + 1 .. Gamma'Last (2) loop
            Gamma (I, J) := 0.0;
         end loop;
      end loop;
   end GMM_E_Step;

   function GMM_M_Step
     (Data  : Sample;
      Gamma : Responsibility_Matrix;
      K     : Component_Count) return GMM_Params
   is
      N      : constant Real := Real (Data'Length);
      Result : GMM_Params;
      Nk     : Real;
      Wx     : Real;
      Wxx    : Real;
      Diff   : Real;
   begin
      if Data'Length = 0 or else K < 1 then
         raise Invalid_Argument;
      end if;
      if Gamma'Length (1) /= Data'Length
        or else Gamma'First (1) /= Data'First
        or else Gamma'Length (2) < K
      then
         raise Invalid_Argument;
      end if;

      Result.K := K;
      Result.Pi := [others => 0.0];
      Result.Mu := [others => 0.0];
      Result.Sigma2 := [others => 1.0];

      for J in 1 .. K loop
         Nk := 0.0;
         Wx := 0.0;
         for I in Data'Range loop
            Nk := Nk + Gamma (I, J);
            Wx := Wx + Gamma (I, J) * Data (I);
         end loop;
         if Nk <= Variance_Eps then
            Result.Pi (J) := Prob_Eps / Real (K);
            Result.Mu (J) := 0.0;
            Result.Sigma2 (J) := 1.0;
         else
            Result.Pi (J) := Nk / N;
            Result.Mu (J) := Wx / Nk;
            Wxx := 0.0;
            for I in Data'Range loop
               Diff := Data (I) - Result.Mu (J);
               Wxx := Wxx + Gamma (I, J) * Diff * Diff;
            end loop;
            Result.Sigma2 (J) := Wxx / Nk;
            if Result.Sigma2 (J) < Variance_Eps then
               Result.Sigma2 (J) := Variance_Eps;
            end if;
         end if;
      end loop;
      Result.Pi := Normalize_Weights (Result.Pi, K);
      return Result;
   end GMM_M_Step;

   procedure Sample_Mean_Var (Data : Sample; Mean, Var : out Real) is
      N : constant Real := Real (Data'Length);
      Acc : Real := 0.0;
      Diff : Real;
   begin
      if Data'Length = 0 then
         raise Invalid_Argument;
      end if;
      for I in Data'Range loop
         Acc := Acc + Data (I);
      end loop;
      Mean := Acc / N;
      Acc := 0.0;
      for I in Data'Range loop
         Diff := Data (I) - Mean;
         Acc := Acc + Diff * Diff;
      end loop;
      if Data'Length = 1 then
         Var := Variance_Eps;
      else
         Var := Acc / N;
         if Var < Variance_Eps then
            Var := Variance_Eps;
         end if;
      end if;
   end Sample_Mean_Var;

   function Random_Init_GMM
     (Data : Sample;
      K    : Component_Count;
      Seed : Natural := 1) return GMM_Params
   is
      Gen    : RNG.Generator;
      Params : GMM_Params;
      Mean, Var : Real;
      Span   : Real;
      U      : Real;
      Offset : Natural;
      Idx    : Sample_Index;
      Used   : array (Data'Range) of Boolean := [others => False];
      Attempts : Natural;
   begin
      Check_Capacity (Data'Length);
      if Data'Length = 0 or else K < 1 then
         raise Invalid_Argument;
      end if;
      if K > Data'Length then
         raise Invalid_Argument;
      end if;

      RNG.Reset (Gen, Integer (Seed));
      Sample_Mean_Var (Data, Mean, Var);
      Span := Math.Sqrt (Var);

      Params.K := K;
      Params.Pi := [others => 0.0];
      Params.Mu := [others => 0.0];
      Params.Sigma2 := [others => 1.0];

      for J in 1 .. K loop
         Params.Pi (J) := 1.0 / Real (K);
         Params.Sigma2 (J) := Var;
         --  Spaced indices across the sample (quantile-like), then seeded jitter.
         if K = 1 then
            Offset := Data'Length / 2;
         else
            Offset := ((J - 1) * (Data'Length - 1)) / (K - 1);
         end if;
         --  Seeded perturbation of the spaced slot.
         U := Real (RNG.Random (Gen));
         declare
            Jitter_Off : constant Integer :=
              Integer (U * Real (Data'Length / (2 * K) + 1)) -
              Integer (Data'Length / (4 * K) + 1);
            Cand : Integer := Integer (Offset) + Jitter_Off;
         begin
            if Cand < 0 then
               Cand := 0;
            elsif Cand >= Data'Length then
               Cand := Data'Length - 1;
            end if;
            Offset := Natural (Cand);
         end;
         Idx := Data'First + Offset;
         if Idx > Data'Last then
            Idx := Data'Last;
         end if;
         Attempts := 0;
         while Used (Idx) and then Attempts < Data'Length loop
            if Idx < Data'Last then
               Idx := Idx + 1;
            else
               Idx := Data'First;
            end if;
            Attempts := Attempts + 1;
         end loop;
         Used (Idx) := True;
         Params.Mu (J) := Data (Idx)
           + (Real (RNG.Random (Gen)) - 0.5) * 0.05 * Span;
      end loop;

      return Params;
   end Random_Init_GMM;

   function GMM_EM_Fit
     (Data          : Sample;
      Init          : GMM_Params;
      Max_Iter      : Positive := 100;
      Tol           : Real := 1.0E-8;
      Raise_On_Fail : Boolean := False) return Fit_Result
   is
      K      : constant Component_Count := Init.K;
      Params : GMM_Params := Init;
      Gamma  : Responsibility_Matrix (Data'Range, 1 .. K);
      Prev_LL, Curr_LL : Real;
      Iter   : Natural := 0;
      Done   : Boolean := False;
      Outcome : Fit_Result (Kind => GMM_Model);
   begin
      Check_Capacity (Data'Length);
      if Data'Length = 0 or else K < 1 then
         raise Invalid_Argument;
      end if;
      Validate_GMM (Init);

      Params.Pi := Normalize_Weights (Params.Pi, K);
      for J in 1 .. K loop
         if Params.Sigma2 (J) < Variance_Eps then
            Params.Sigma2 (J) := Variance_Eps;
         end if;
      end loop;

      Curr_LL := GMM_Log_Likelihood (Data, Params);

      for T in 1 .. Max_Iter loop
         Iter := T;
         Prev_LL := Curr_LL;
         GMM_E_Step (Data, Params, Gamma);
         Params := GMM_M_Step (Data, Gamma, K);
         Curr_LL := GMM_Log_Likelihood (Data, Params);
         if abs (Curr_LL - Prev_LL) < Tol then
            Done := True;
            exit;
         end if;
      end loop;

      if not Done and then Raise_On_Fail then
         raise Did_Not_Converge;
      end if;

      Outcome.GMM := Params;
      Outcome.Iterations := Iter;
      Outcome.Log_Likelihood := Curr_LL;
      Outcome.Converged := Done;
      return Outcome;
   end GMM_EM_Fit;

   function Make_Equal_Bernoulli (K : Component_Count; P1, P2 : Real)
     return Bernoulli_Mixture
   is
      R : Bernoulli_Mixture;
   begin
      if K < 1 then
         raise Invalid_Argument;
      end if;
      R.K := K;
      R.Pi := [others => 0.0];
      R.P := [others => 0.5];
      for J in 1 .. K loop
         R.Pi (J) := 1.0 / Real (K);
         if J = 1 then
            R.P (J) := Clamp_Prob (P1);
         else
            R.P (J) := Clamp_Prob (P2);
         end if;
      end loop;
      return R;
   end Make_Equal_Bernoulli;

   function Make_GMM
     (K      : Component_Count;
      Pi     : Weight_Vector;
      Mu     : Mean_Vector;
      Sigma2 : Variance_Vector) return GMM_Params
   is
      R : GMM_Params;
   begin
      if K < 1 then
         raise Invalid_Argument;
      end if;
      R.K := K;
      R.Pi := Normalize_Weights (Pi, K);
      R.Mu := Mu;
      R.Sigma2 := Sigma2;
      for J in 1 .. K loop
         if R.Sigma2 (J) < Variance_Eps then
            R.Sigma2 (J) := Variance_Eps;
         end if;
      end loop;
      return R;
   end Make_GMM;

end Expectation_Maximization;
