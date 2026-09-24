--  Standalone test suite for Expectation_Maximization (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Expectation_Maximization; use Expectation_Maximization;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real := 1.0E-5) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Pi_Sum (Pi : Weight_Vector; K : Component_Count) return Real is
      S : Real := 0.0;
   begin
      for J in 1 .. K loop
         S := S + Pi (J);
      end loop;
      return S;
   end Pi_Sum;

   function Row_Sum
     (Gamma : Responsibility_Matrix; I : Sample_Index; K : Component_Count)
      return Real
   is
      S : Real := 0.0;
   begin
      for J in 1 .. K loop
         S := S + Gamma (I, J);
      end loop;
      return S;
   end Row_Sum;

begin
   Put_Line ("Expectation_Maximization test suite");
   Put_Line ("===================================");

   ---------------------------------------------------------------------
   Section ("1. Near / Log / Exp / Clamp_Prob");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean := False;
   begin
      Check (Near (1.0, 1.0 + 1.0E-9), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Approx (Log (Exp (1.0)), 1.0, 1.0E-9), "Log(Exp(1)) ≈ 1");
      Check (Approx (Exp (0.0), 1.0), "Exp(0) = 1");
      Check (Approx (Log (1.0), 0.0), "Log(1) = 0");
      Check (Approx (Clamp_Prob (-0.5), Prob_Eps), "Clamp neg -> Prob_Eps");
      Check (Approx (Clamp_Prob (1.5), 1.0 - Prob_Eps), "Clamp >1");
      Check (Approx (Clamp_Prob (0.3), 0.3), "Clamp interior");
      begin
         declare
            Unused : Real;
         begin
            Unused := Log (0.0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Log(0) raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("2. Gaussian_Pdf sanity");
   ---------------------------------------------------------------------
   declare
      P0 : constant Real := Gaussian_Pdf (0.0, 0.0, 1.0);
      P1 : constant Real := Gaussian_Pdf (1.0, 0.0, 1.0);
      P2 : constant Real := Gaussian_Pdf (0.0, 0.0, 4.0);
      Raised : Boolean := False;
   begin
      --  N(0|0,1) = 1/sqrt(2π) ≈ 0.398942
      Check (Approx (P0, 0.3989422804, 1.0E-6), "N(0|0,1) ≈ 0.39894");
      Check (P1 < P0, "N(1|0,1) < N(0|0,1)");
      Check (P1 > 0.0, "pdf positive away from mean");
      Check (P2 < P0, "wider variance lowers peak");
      Check (Approx (Gaussian_Pdf (5.0, 5.0, 1.0), P0, 1.0E-9),
             "location shift invariance of peak");
      begin
         declare
            Unused : Real;
         begin
            Unused := Gaussian_Pdf (0.0, 0.0, 0.0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Gaussian_Pdf sigma2=0 raises");
   end;

   ---------------------------------------------------------------------
   Section ("3. Log_Sum_Exp / Normalize_Weights");
   ---------------------------------------------------------------------
   declare
      V : Weight_Vector := [others => 0.0];
      W : Weight_Vector := [others => 0.0];
      R : Weight_Vector;
      Raised : Boolean := False;
   begin
      V (1) := 0.0;
      V (2) := 0.0;
      Check (Approx (Log_Sum_Exp (V, 2), Log (2.0), 1.0E-9),
             "LSE(0,0) = log 2");
      V (1) := 10.0;
      V (2) := -10.0;
      Check (Approx (Log_Sum_Exp (V, 2), 10.0, 1.0E-6),
             "LSE dominated by max");
      V (1) := 1000.0;
      V (2) := 1000.0;
      Check (Approx (Log_Sum_Exp (V, 2), 1000.0 + Log (2.0), 1.0E-4),
             "LSE stable for large equal values");
      W (1) := 1.0;
      W (2) := 3.0;
      R := Normalize_Weights (W, 2);
      Check (Approx (R (1), 0.25) and then Approx (R (2), 0.75),
             "Normalize_Weights 1:3 -> 0.25/0.75");
      Check (Approx (Pi_Sum (R, 2), 1.0), "normalized sum = 1");
      begin
         declare
            Z : constant Weight_Vector := [others => 0.0];
            Unused : Weight_Vector;
         begin
            Unused := Normalize_Weights (Z, 2);
            pragma Unreferenced (Unused);
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Normalize_Weights all-zero raises");
   end;

   ---------------------------------------------------------------------
   Section ("4. Bernoulli E-step responsibilities sum to 1");
   ---------------------------------------------------------------------
   declare
      --  Heads-counts in Trials=10 flips (classic two-coin sequences).
      Data : constant Sample :=
        [1.0, 9.0, 2.0, 8.0, 0.0, 10.0, 3.0, 7.0];
      Params : constant Bernoulli_Mixture :=
        Make_Equal_Bernoulli (2, 0.3, 0.8);
      Gamma  : Responsibility_Matrix (Data'Range, 1 .. 2);
      Ok     : Boolean := True;
   begin
      Bernoulli_E_Step (Data, Params, Gamma, Trials => 10);
      for I in Data'Range loop
         if not Approx (Row_Sum (Gamma, I, 2), 1.0, 1.0E-9) then
            Ok := False;
         end if;
         if Gamma (I, 1) < 0.0 or else Gamma (I, 2) < 0.0 then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "all Bernoulli γ rows sum to 1, nonnegative");
      Check (Gamma (1, 1) > Gamma (1, 2),
             "few heads prefers smaller p component");
      Check (Gamma (2, 2) > Gamma (2, 1),
             "many heads prefers larger p component");
   end;

   ---------------------------------------------------------------------
   Section ("5. Bernoulli M-step π sums to 1 / p in (0,1)");
   ---------------------------------------------------------------------
   declare
      Data : constant Sample :=
        [1.0, 2.0, 8.0, 9.0, 7.0, 0.0, 9.0, 8.0, 1.0, 10.0];
      Init : constant Bernoulli_Mixture :=
        Make_equal_Bernoulli (2, 0.4, 0.6);
      Gamma : Responsibility_Matrix (Data'Range, 1 .. 2);
      Updated : Bernoulli_Mixture;
   begin
      Bernoulli_E_Step (Data, Init, Gamma, Trials => 10);
      Updated := Bernoulli_M_Step (Data, Gamma, 2, Trials => 10);
      Check (Updated.K = 2, "M-step keeps K=2");
      Check (Approx (Pi_Sum (Updated.Pi, 2), 1.0, 1.0E-9), "π sums to 1");
      Check (Updated.P (1) > Prob_Eps and then Updated.P (1) < 1.0 - Prob_Eps,
             "p1 interior");
      Check (Updated.P (2) > Prob_Eps and then Updated.P (2) < 1.0 - Prob_Eps,
             "p2 interior");
      Check (Updated.Pi (1) > 0.0 and then Updated.Pi (2) > 0.0,
             "π_k > 0");
   end;

   ---------------------------------------------------------------------
   Section ("6. Bernoulli EM recovers two known biases");
   ---------------------------------------------------------------------
   declare
      --  Classic two-coin: 50 sequences of 10 flips ~p=0.3, 50 ~p=0.8
      Data : Sample (1 .. 100);
      Init : Bernoulli_Mixture;
      Fit  : Fit_Result (Bernoulli_Model);
      Lo, Hi : Real;
      Ok_Recover : Boolean;
   begin
      for I in 1 .. 50 loop
         Data (I) := Real (2 + (I mod 3));  -- 2,3,4 → mean 3/10 = 0.3
      end loop;
      for I in 51 .. 100 loop
         Data (I) := Real (7 + (I mod 3));  -- 7,8,9 → mean 8/10 = 0.8
      end loop;
      Init := Make_Equal_Bernoulli (2, 0.45, 0.55);
      Fit := Bernoulli_EM_Fit
        (Data, Init, Trials => 10, Max_Iter => 80, Tol => 1.0E-10);
      Check (Fit.Converged, "Bernoulli EM converged");
      Check (Fit.Iterations >= 1, "Bernoulli ran ≥1 iter");
      Check (Approx (Pi_Sum (Fit.Bernoulli.Pi, 2), 1.0, 1.0E-8),
             "fitted π sum 1");
      Lo := Real'Min (Fit.Bernoulli.P (1), Fit.Bernoulli.P (2));
      Hi := Real'Max (Fit.Bernoulli.P (1), Fit.Bernoulli.P (2));
      Ok_Recover := Approx (Lo, 0.3, 0.1) and then Approx (Hi, 0.8, 0.1);
      Check (Ok_Recover, "recovered biases ≈ 0.3 and ≈ 0.8");
      Check (Fit.Log_Likelihood < 0.0, "Bernoulli LL negative (as expected)");
   end;

   ---------------------------------------------------------------------
   Section ("7. Bernoulli log-likelihood nondecreasing");
   ---------------------------------------------------------------------
   declare
      Data : constant Sample :=
        [2.0, 8.0, 9.0, 1.0, 7.0, 3.0, 2.0, 8.0, 9.0, 10.0,
         1.0, 0.0, 8.0, 2.0, 9.0, 7.0, 3.0, 8.0, 1.0, 9.0];
      Params : Bernoulli_Mixture := Make_equal_Bernoulli (2, 0.35, 0.65);
      Gamma  : Responsibility_Matrix (Data'Range, 1 .. 2);
      Prev, Curr, Init_LL : Real;
      Mono : Boolean := True;
   begin
      Init_LL := Bernoulli_Log_Likelihood (Data, Params, Trials => 10);
      Prev := Init_LL;
      for T in 1 .. 15 loop
         Bernoulli_E_Step (Data, Params, Gamma, Trials => 10);
         Params := Bernoulli_M_Step (Data, Gamma, 2, Trials => 10);
         Curr := Bernoulli_Log_Likelihood (Data, Params, Trials => 10);
         if Curr + 1.0E-8 < Prev then
            Mono := False;
         end if;
         Prev := Curr;
      end loop;
      Check (Mono, "Bernoulli LL nondecreasing over 15 iters");
      Check (Curr + 1.0E-6 >= Init_LL,
             "LL improved or stable vs init");
      Check (Curr < 0.0, "binomial-mixture LL typically negative");
   end;

   ---------------------------------------------------------------------
   Section ("8. GMM E-step responsibilities sum to 1");
   ---------------------------------------------------------------------
   declare
      Data : constant Sample :=
        [-2.0, -1.5, -1.0, 4.0, 4.5, 5.0, 0.0];
      Pi : Weight_Vector := [others => 0.0];
      Mu : Mean_Vector := [others => 0.0];
      S2 : Variance_Vector := [others => 1.0];
      Params : GMM_Params;
      Gamma  : Responsibility_Matrix (Data'Range, 1 .. 2);
      Ok : Boolean := True;
   begin
      Pi (1) := 0.5; Pi (2) := 0.5;
      Mu (1) := -1.5; Mu (2) := 4.5;
      S2 (1) := 1.0; S2 (2) := 1.0;
      Params := Make_GMM (2, Pi, Mu, S2);
      GMM_E_Step (Data, Params, Gamma);
      for I in Data'Range loop
         if not Approx (Row_Sum (Gamma, I, 2), 1.0, 1.0E-8) then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "GMM γ rows sum to 1");
      Check (Gamma (1, 1) > Gamma (1, 2), "x=-2 prefers left component");
      Check (Gamma (5, 2) > Gamma (5, 1), "x=4.5 prefers right component");
      Check (Gamma (1, 1) >= 0.0 and then Gamma (1, 2) >= 0.0,
             "responsibilities nonnegative");
   end;

   ---------------------------------------------------------------------
   Section ("9. GMM M-step π sum / σ² > 0");
   ---------------------------------------------------------------------
   declare
      Data : constant Sample :=
        [-3.0, -2.5, -2.0, -1.5, 3.0, 3.5, 4.0, 4.5];
      Pi : Weight_Vector := [others => 0.0];
      Mu : Mean_Vector := [others => 0.0];
      S2 : Variance_Vector := [others => 1.0];
      Params, Updated : GMM_Params;
      Gamma : Responsibility_Matrix (Data'Range, 1 .. 2);
   begin
      Pi (1) := 0.5; Pi (2) := 0.5;
      Mu (1) := -2.0; Mu (2) := 4.0;
      S2 (1) := 1.0; S2 (2) := 1.0;
      Params := Make_GMM (2, Pi, Mu, S2);
      GMM_E_Step (Data, Params, Gamma);
      Updated := GMM_M_Step (Data, Gamma, 2);
      Check (Approx (Pi_Sum (Updated.Pi, 2), 1.0, 1.0E-9), "GMM π sum 1");
      Check (Updated.Sigma2 (1) > 0.0 and then Updated.Sigma2 (2) > 0.0,
             "σ² > 0");
      Check (Updated.Sigma2 (1) >= Variance_Eps, "σ²₁ ≥ eps");
      Check (Updated.Sigma2 (2) >= Variance_Eps, "σ²₂ ≥ eps");
      Check (Updated.Mu (1) < Updated.Mu (2), "means ordered left/right");
   end;

   ---------------------------------------------------------------------
   Section ("10. GMM recovers well-separated 1-D cluster means");
   ---------------------------------------------------------------------
   declare
      Data : Sample (1 .. 60);
      Pi : Weight_Vector := [others => 0.0];
      Mu : Mean_Vector := [others => 0.0];
      S2 : Variance_Vector := [others => 1.0];
      Init : GMM_Params;
      Fit  : Fit_Result (GMM_Model);
      M_Lo, M_Hi : Real;
   begin
      --  Cluster A ~ N(-5, 0.5²), cluster B ~ N(+5, 0.5²)
      for I in 1 .. 30 loop
         Data (I) := -5.0 + 0.15 * Real (I - 15);
      end loop;
      for I in 31 .. 60 loop
         Data (I) := 5.0 + 0.15 * Real (I - 45);
      end loop;
      Pi (1) := 0.5; Pi (2) := 0.5;
      Mu (1) := -1.0; Mu (2) := 1.0;  -- poor start, still separated
      S2 (1) := 4.0; S2 (2) := 4.0;
      Init := Make_GMM (2, Pi, Mu, S2);
      Fit := GMM_EM_Fit (Data, Init, Max_Iter => 100, Tol => 1.0E-10);
      Check (Fit.Converged, "GMM EM converged on separated clusters");
      M_Lo := Real'Min (Fit.GMM.Mu (1), Fit.GMM.Mu (2));
      M_Hi := Real'Max (Fit.GMM.Mu (1), Fit.GMM.Mu (2));
      Check (Approx (M_Lo, -5.0, 0.6), "low mean ≈ -5");
      Check (Approx (M_Hi, 5.0, 0.6), "high mean ≈ +5");
      Check (Approx (Pi_Sum (Fit.GMM.Pi, 2), 1.0, 1.0E-8), "π sum 1");
      Check (Fit.GMM.Sigma2 (1) > 0.0 and then Fit.GMM.Sigma2 (2) > 0.0,
             "fitted σ² > 0");
   end;

   ---------------------------------------------------------------------
   Section ("11. GMM log-likelihood nondecreasing");
   ---------------------------------------------------------------------
   declare
      Data : constant Sample :=
        [-4.0, -3.5, -3.0, -2.5, 2.0, 2.5, 3.0, 3.5, 0.0, 0.5];
      Pi : Weight_Vector := [others => 0.0];
      Mu : Mean_Vector := [others => 0.0];
      S2 : Variance_Vector := [others => 1.0];
      Params : GMM_Params;
      Gamma  : Responsibility_Matrix (Data'Range, 1 .. 2);
      Prev, Curr : Real;
      Mono : Boolean := True;
   begin
      Pi (1) := 0.4; Pi (2) := 0.6;
      Mu (1) := -2.0; Mu (2) := 2.0;
      S2 (1) := 2.0; S2 (2) := 2.0;
      Params := Make_GMM (2, Pi, Mu, S2);
      Prev := GMM_Log_Likelihood (Data, Params);
      for T in 1 .. 20 loop
         GMM_E_Step (Data, Params, Gamma);
         Params := GMM_M_Step (Data, Gamma, 2);
         Curr := GMM_Log_Likelihood (Data, Params);
         if Curr + 1.0E-7 < Prev then
            Mono := False;
         end if;
         Prev := Curr;
      end loop;
      Check (Mono, "GMM ℓ nondecreasing over 20 iters");
      Check (Curr > -1.0E30, "LL finite");
   end;

   ---------------------------------------------------------------------
   Section ("12. Single-component GMM → sample mean / variance");
   ---------------------------------------------------------------------
   declare
      Data : constant Sample := [1.0, 2.0, 3.0, 4.0, 5.0];
      Pi : Weight_Vector := [others => 0.0];
      Mu : Mean_Vector := [others => 0.0];
      S2 : Variance_Vector := [others => 1.0];
      Init : GMM_Params;
      Fit  : Fit_Result (GMM_Model);
      --  population-style mean 3, variance ((1-3)²+…+(5-3)²)/5 = 2
      True_Mean : constant Real := 3.0;
      True_Var  : constant Real := 2.0;
   begin
      Pi (1) := 1.0;
      Mu (1) := 0.0;
      S2 (1) := 1.0;
      Init := Make_GMM (1, Pi, Mu, S2);
      Fit := GMM_EM_Fit (Data, Init, Max_Iter => 50, Tol => 1.0E-12);
      Check (Fit.Converged, "K=1 GMM converges");
      Check (Approx (Fit.GMM.Mu (1), True_Mean, 1.0E-8), "μ = sample mean");
      Check (Approx (Fit.GMM.Sigma2 (1), True_Var, 1.0E-8),
             "σ² = sample variance (1/N)");
      Check (Approx (Fit.GMM.Pi (1), 1.0), "π₁ = 1");
   end;

   ---------------------------------------------------------------------
   Section ("13. Tol convergence flag / Max_Iter");
   ---------------------------------------------------------------------
   declare
      Data : constant Sample :=
        [-2.0, -1.0, 0.0, 1.0, 2.0, 8.0, 9.0, 10.0];
      Pi : Weight_Vector := [others => 0.0];
      Mu : Mean_Vector := [others => 0.0];
      S2 : Variance_Vector := [others => 1.0];
      Init : GMM_Params;
      Fit_Loose, Fit_Tight : Fit_Result (GMM_Model);
      Fit_Few : Fit_Result (GMM_Model);
      Raised : Boolean := False;
   begin
      Pi (1) := 0.5; Pi (2) := 0.5;
      Mu (1) := -1.0; Mu (2) := 8.0;
      S2 (1) := 1.0; S2 (2) := 1.0;
      Init := Make_GMM (2, Pi, Mu, S2);
      Fit_Loose := GMM_EM_Fit
        (Data, Init, Max_Iter => 100, Tol => 1.0E-3);
      Fit_Tight := GMM_EM_Fit
        (Data, Init, Max_Iter => 200, Tol => 1.0E-12);
      Check (Fit_Loose.Converged, "loose Tol converges");
      Check (Fit_Tight.Converged, "tight Tol converges");
      Check (Fit_Tight.Iterations >= Fit_Loose.Iterations,
             "tighter Tol needs ≥ iterations");
      Fit_Few := GMM_EM_Fit
        (Data, Init, Max_Iter => 1, Tol => 1.0E-30);
      Check (not Fit_Few.Converged, "Max_Iter=1 may not converge");
      begin
         declare
            Unused : Fit_Result :=
              GMM_EM_Fit
                (Data, Init, Max_Iter => 1, Tol => 1.0E-30,
                 Raise_On_Fail => True);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Did_Not_Converge =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Raise_On_Fail triggers Did_Not_Converge");
   end;

   ---------------------------------------------------------------------
   Section ("14. Invalid K / empty sample raises");
   ---------------------------------------------------------------------
   declare
      Empty : Sample (1 .. 0);
      Data  : constant Sample := [1.0, 2.0, 3.0];
      Raised_Empty : Boolean := False;
      Raised_K : Boolean := False;
      Raised_Bern : Boolean := False;
      Pi : Weight_Vector := [others => 0.0];
      Mu : Mean_Vector := [others => 0.0];
      S2 : Variance_Vector := [others => 1.0];
      Bad : GMM_Params;
      Init : GMM_Params;
   begin
      Pi (1) := 1.0;
      Mu (1) := 0.0;
      S2 (1) := 1.0;
      Init := Make_GMM (1, Pi, Mu, S2);
      begin
         declare
            Unused : Fit_Result :=
              GMM_EM_Fit (Empty, Init, Max_Iter => 5);
         begin
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised_Empty := True;
         when Constraint_Error =>
            Raised_Empty := True;
         when others =>
            null;
      end;
      Check (Raised_Empty, "empty GMM sample raises");

      Bad.K := 0;
      begin
         declare
            Unused : Real;
         begin
            Unused := GMM_Log_Likelihood (Data, Bad);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised_K := True;
         when Constraint_Error =>
            Raised_K := True;
         when others =>
            null;
      end;
      Check (Raised_K, "K=0 GMM raises");

      begin
         declare
            Unused : Bernoulli_Mixture;
         begin
            Unused := Make_Equal_Bernoulli (0, 0.2, 0.8);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised_Bern := True;
         when Constraint_Error =>
            Raised_Bern := True;
         when others =>
            null;
      end;
      Check (Raised_Bern, "Bernoulli K=0 raises");
   end;

   ---------------------------------------------------------------------
   Section ("15. Random_Init_GMM seeded / Fit from random init");
   ---------------------------------------------------------------------
   declare
      Data : Sample (1 .. 40);
      A, B : GMM_Params;
      Fit  : Fit_Result (GMM_Model);
      M_Lo, M_Hi : Real;
   begin
      for I in 1 .. 20 loop
         Data (I) := -3.0 + 0.1 * Real (I);
      end loop;
      for I in 21 .. 40 loop
         Data (I) := 6.0 + 0.1 * Real (I - 20);
      end loop;
      A := Random_Init_GMM (Data, 2, Seed => 42);
      B := Random_Init_GMM (Data, 2, Seed => 42);
      Check (A.K = 2, "Random_Init K=2");
      Check (Approx (A.Mu (1), B.Mu (1)) and then Approx (A.Mu (2), B.Mu (2)),
             "same seed -> same init means");
      Check (Approx (Pi_Sum (A.Pi, 2), 1.0, 1.0E-9), "init π sum 1");
      Check (A.Sigma2 (1) > 0.0 and then A.Sigma2 (2) > 0.0,
             "init σ² > 0");
      Fit := GMM_EM_Fit (Data, A, Max_Iter => 200, Tol => 1.0E-9);
      Check (Fit.Converged, "EM from Random_Init converges");
      M_Lo := Real'Min (Fit.GMM.Mu (1), Fit.GMM.Mu (2));
      M_Hi := Real'Max (Fit.GMM.Mu (1), Fit.GMM.Mu (2));
      Check (M_Lo < 0.0 and then M_Hi > 0.0,
             "recovered means on opposite sides");
   end;

   ---------------------------------------------------------------------
   Section ("16. Degenerate / capacity edge cases");
   ---------------------------------------------------------------------
   declare
      Data : constant Sample := [0.0, 1.0];
      Pi : Weight_Vector := [others => 0.0];
      Mu : Mean_Vector := [others => 0.0];
      S2 : Variance_Vector := [others => 1.0];
      Bad : GMM_Params;
      Raised_Deg : Boolean := False;
      Raised_Cap : Boolean := False;
      Huge : Sample (1 .. 1);
   begin
      Pi (1) := 0.0; Pi (2) := 0.0;  -- will fail normalize
      Mu (1) := 0.0; Mu (2) := 1.0;
      S2 (1) := 1.0; S2 (2) := 1.0;
      Bad.K := 2;
      Bad.Pi := Pi;
      Bad.Mu := Mu;
      Bad.Sigma2 := S2;
      begin
         declare
            Unused : Real;
         begin
            Unused := GMM_Log_Likelihood (Data, Bad);
            pragma Unreferenced (Unused);
         end;
      exception
         when Degenerate_Geometry =>
            Raised_Deg := True;
         when Invalid_Argument =>
            Raised_Deg := True;
         when others =>
            null;
      end;
      Check (Raised_Deg, "zero π mass raises degenerate/invalid");
      --  Capacity: Random_Init with K > N
      Huge (1) := 0.0;
      begin
         declare
            Unused : GMM_Params;
         begin
            Unused := Random_Init_GMM (Huge, 2, Seed => 1);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised_Cap := True;
         when Capacity_Exceeded =>
            Raised_Cap := True;
         when others =>
            null;
      end;
      Check (Raised_Cap, "K > N raises");
      Check (Raised_Deg, "zero-π path set Raised_Deg");
      declare
         Init_Full_K : constant GMM_Params :=
           Random_Init_GMM
             (Data => [1.0, 2.0, 3.0, 4.0], K => 2, Seed => 7);
      begin
         Check (Init_Full_K.K = 2, "Random_Init accepts K=2");
         Check (Init_Full_K.Sigma2 (1) >= Variance_Eps,
                "Random_Init σ² floored");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("17. Make helpers / Bernoulli LL finite");
   ---------------------------------------------------------------------
   declare
      B : constant Bernoulli_Mixture :=
        Make_Equal_Bernoulli (2, 0.25, 0.75);
      Data : constant Sample := [0.0, 1.0, 1.0, 0.0];
      LL : Real;
      Pi : Weight_Vector := [others => 0.0];
      Mu : Mean_Vector := [others => 0.0];
      S2 : Variance_Vector := [others => 1.0];
      G : GMM_Params;
   begin
      Check (B.K = 2, "Make_equal_Bernoulli K");
      Check (Approx (B.P (1), 0.25) and then Approx (B.P (2), 0.75),
             "Make_equal_Bernoulli probs");
      Check (Approx (B.Pi (1), 0.5) and then Approx (B.Pi (2), 0.5),
             "equal π");
      LL := Bernoulli_Log_Likelihood (Data, B);
      Check (LL < 0.0, "Bernoulli LL < 0");
      Check (LL > Log_Floor / 2.0, "Bernoulli LL not floor");
      Pi (1) := 0.3; Pi (2) := 0.7;
      Mu (1) := -1.0; Mu (2) := 2.0;
      S2 (1) := 0.5; S2 (2) := 1.5;
      G := Make_GMM (2, Pi, Mu, S2);
      Check (Approx (G.Pi (1) + G.Pi (2), 1.0), "Make_GMM normalizes π");
      Check (Approx (G.Mu (1), -1.0) and then Approx (G.Sigma2 (2), 1.5),
             "Make_GMM stores μ/σ²");
   end;

   New_Line;
   Put_Line ("===================================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL TESTS PASSED");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;

   pragma Assert (Fail_Count = 0);
end Tests;
