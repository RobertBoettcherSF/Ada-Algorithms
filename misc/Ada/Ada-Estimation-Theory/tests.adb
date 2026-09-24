--  Standalone test suite for Estimation_Theory (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Estimation_Theory; use Estimation_Theory;

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

   function Approx (A, B : Real; Tol : Real := 1.0E-6) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

begin
   Put_Line ("Estimation_Theory test suite");
   Put_Line ("============================");

   ---------------------------------------------------------------------
   Section ("1. Near helper");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-9), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-10, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
   end;

   ---------------------------------------------------------------------
   Section ("2. Sample Mean");
   ---------------------------------------------------------------------
   declare
      X1 : constant Sample := [3.0];
      X2 : constant Sample := [1.0, 2.0, 3.0, 4.0, 5.0];
      X3 : constant Sample := [-2.0, -1.0, 0.0, 1.0, 2.0];
      Raised : Boolean := False;
   begin
      Check (Approx (Mean (X1), 3.0), "Mean singleton");
      Check (Approx (Mean (X2), 3.0), "Mean 1..5 = 3");
      Check (Approx (Mean (X3), 0.0), "Mean symmetric = 0");
      Check (Approx (Mean ([10.0, 20.0]), 15.0), "Mean pair");
      begin
         declare
            Empty : Sample (1 .. 0);
            Unused : Real;
         begin
            Unused := Mean (Empty);
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
      Check (Raised, "Mean empty raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("3. Sample Variance (population and unbiased)");
   ---------------------------------------------------------------------
   declare
      X : constant Sample := [2.0, 4.0, 4.0, 4.0, 5.0, 5.0, 7.0, 9.0];
      --  mean=5; Σ(x-μ)² = 0+1+1+1+0+0+4+16=32
      --  pop 32/8=4; unbiased 32/7 ≈ 4.571428
      V_Pop : constant Real := Variance (X, Unbiased => False);
      V_Unb : constant Real := Variance (X, Unbiased => True);
      Y : constant Sample := [1.0, 1.0, 1.0];
      Raised : Boolean := False;
   begin
      Check (Approx (Mean (X), 5.0), "Variance fixture mean=5");
      Check (Approx (V_Pop, 4.0), "population variance = 4");
      Check (Approx (V_Unb, 32.0 / 7.0, 1.0E-9), "unbiased variance = 32/7");
      Check (V_Unb > V_Pop, "unbiased > population for N>1");
      Check (Approx (Variance (Y, False), 0.0), "zero variance identical");
      Check (Approx (Variance (Y, True), 0.0), "zero unbiased identical");
      begin
         declare
            Sing : constant Sample := [42.0];
            Unused : Real;
         begin
            Unused := Variance (Sing, Unbiased => True);
            pragma Unreferenced (Unused);
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "unbiased variance N=1 raises Degenerate_Geometry");
      Check (Approx (Variance ([42.0], Unbiased => False), 0.0),
             "population variance N=1 = 0");
   end;

   ---------------------------------------------------------------------
   Section ("4. Sample min / max");
   ---------------------------------------------------------------------
   declare
      X : constant Sample := [3.0, -1.0, 7.5, 0.0, 2.0];
   begin
      Check (Approx (Sample_Maximum (X), 7.5), "Sample_Maximum");
      Check (Approx (Sample_Minimum (X), -1.0), "Sample_Minimum");
      Check (Approx (Sample_Maximum ([5.0]), 5.0), "max singleton");
      Check (Approx (Sample_Minimum ([5.0]), 5.0), "min singleton");
   end;

   ---------------------------------------------------------------------
   Section ("5. Bias / MSE / Variance_Of_Estimator / MSE identity");
   ---------------------------------------------------------------------
   declare
      Ests : constant Sample := [1.0, 2.0, 3.0, 4.0];
      --  mean est = 2.5; truth=2 → avg bias = 0.5
      --  pop var about 2.5: ((-1.5)^2+(-0.5)^2+(0.5)^2+(1.5)^2)/4 = 5/4=1.25
      M_Est : constant Real := Mean (Ests);
      V_Est : constant Real := Variance_Of_Estimator (Ests, M_Est);
      B     : constant Real := Bias (M_Est, 2.0);
      Mse_P : constant Real := MSE (3.0, 1.0);
   begin
      Check (Approx (Bias (5.0, 3.0), 2.0), "Bias(5,3)=2");
      Check (Approx (Bias (1.0, 4.0), -3.0), "Bias negative");
      Check (Approx (Mse_P, 4.0), "MSE(3,1)=4");
      Check (Approx (MSE (0.0, 0.0), 0.0), "MSE zero");
      Check (Approx (M_Est, 2.5), "MC mean of estimates");
      Check (Approx (V_Est, 1.25), "Var of estimator MC");
      Check (Approx (B, 0.5), "Bias of mean estimate vs truth 2");
      Check (Approx (MSE_From_Bias_Var (B, V_Est), B * B + V_Est),
             "MSE = Bias² + Var identity");
      Check (Approx (MSE_From_Bias_Var (0.0, 2.0), 2.0),
             "unbiased MSE = Var");
      Check (Approx (MSE_From_Bias_Var (3.0, 0.0), 9.0),
             "zero-var MSE = Bias²");
   end;

   ---------------------------------------------------------------------
   Section ("6. Method of moments — Exponential rate");
   ---------------------------------------------------------------------
   declare
      --  Exp(λ=2) mean=0.5; synthetic mean 0.5 → λ̂=2
      X : constant Sample := [0.25, 0.5, 0.75];
      --  mean = 0.5 → λ = 2
      Raised : Boolean := False;
   begin
      Check (Approx (MoM_Exponential_Rate (X), 2.0), "MoM Exp λ=2");
      Check (Approx (MLE_Exponential_Rate (X), 2.0), "MLE Exp = MoM");
      Check (Near (MoM_Exponential_Rate (X), MLE_Exponential_Rate (X)),
             "Exp MoM equals MLE");
      Check (Approx (MoM_Exponential_Rate ([1.0, 1.0, 1.0, 1.0]), 1.0),
             "MoM Exp unit mean → λ=1");
      begin
         declare
            Bad : constant Sample := [-1.0, -2.0];
            Unused : Real;
         begin
            Unused := MoM_Exponential_Rate (Bad);
            pragma Unreferenced (Unused);
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Exp MoM nonpositive mean raises");
   end;

   ---------------------------------------------------------------------
   Section ("7. Method of moments — Uniform[0,θ]");
   ---------------------------------------------------------------------
   declare
      X : constant Sample := [1.0, 2.0, 3.0];
      --  mean=2 → θ̂_MoM = 4
   begin
      Check (Approx (MoM_Uniform_Theta (X), 4.0), "MoM Uniform θ=2·mean");
      Check (Approx (MoM_Uniform_Theta ([0.0, 10.0]), 10.0),
             "MoM Uniform endpoints");
      Check (Approx (MoM_Uniform_Theta ([5.0]), 10.0),
             "MoM Uniform singleton");
   end;

   ---------------------------------------------------------------------
   Section ("8. MLE Gaussian mean / variance");
   ---------------------------------------------------------------------
   declare
      X : constant Sample := [0.0, 2.0, 4.0, 6.0];
      --  mean=3; Σ(x-3)²=9+1+1+9=20; MLE σ²=20/4=5
      --  known μ=3 same; known μ=0: Σx²=0+4+16+36=56 → 14
   begin
      Check (Approx (MLE_Gaussian_Mean (X), 3.0), "MLE Gaussian mean");
      Check (Near (MLE_Gaussian_Mean (X), Mean (X)),
             "Gaussian mean MLE = sample mean");
      Check (Approx (MLE_Gaussian_Variance (X, Known_Mean => False), 5.0),
             "MLE σ² unknown mean");
      Check (Approx (MLE_Gaussian_Variance (X, True, 3.0), 5.0),
             "MLE σ² known μ=3");
      Check (Approx (MLE_Gaussian_Variance (X, True, 0.0), 14.0),
             "MLE σ² known μ=0");
      Check (Approx (MLE_Gaussian_Variance (X, False),
                    Variance (X, Unbiased => False)),
             "MLE σ² = population variance");
      Check (Near (MLE_Gaussian_Mean ([7.0]), 7.0), "MLE mean singleton");
   end;

   ---------------------------------------------------------------------
   Section ("9. MLE Bernoulli p");
   ---------------------------------------------------------------------
   declare
      X : constant Sample := [1.0, 0.0, 1.0, 1.0, 0.0];
      Raised : Boolean := False;
   begin
      Check (Approx (MLE_Bernoulli_P (X), 0.6), "Bernoulli p̂=3/5");
      Check (Approx (MLE_Bernoulli_P ([0.0, 0.0, 0.0]), 0.0), "all zeros");
      Check (Approx (MLE_Bernoulli_P ([1.0, 1.0]), 1.0), "all ones");
      Check (Near (MLE_Bernoulli_P (X), Mean (X)),
             "Bernoulli MLE = sample proportion");
      begin
         declare
            Bad : constant Sample := [0.0, 0.5, 1.0];
            Unused : Real;
         begin
            Unused := MLE_Bernoulli_P (Bad);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Bernoulli non-0/1 raises Invalid_Argument");
   end;

   ---------------------------------------------------------------------
   Section ("10. Uniform[0,θ] MLE = max ≠ MoM");
   ---------------------------------------------------------------------
   declare
      X : constant Sample := [1.0, 2.0, 3.0, 4.0];
      --  MLE = 4; MoM = 2·2.5 = 5
      Mle : constant Real := MLE_Uniform_Theta (X);
      Mom : constant Real := MoM_Uniform_Theta (X);
   begin
      Check (Approx (Mle, 4.0), "Uniform MLE = sample max");
      Check (Approx (Mom, 5.0), "Uniform MoM = 2·mean");
      Check (Mle /= Mom, "Uniform MLE ≠ MoM (classic)");
      Check (Near (Mle, Sample_Maximum (X)), "MLE Uniform aliases max");
      Check (Mle < Mom, "for this sample MLE < MoM");
   end;

   ---------------------------------------------------------------------
   Section ("11. AWGN constant-in-noise (Wikipedia)");
   ---------------------------------------------------------------------
   declare
      --  x[n] = A + w[n]; A=5; synthetic noise mean ~0
      X : constant Sample :=
        [4.8, 5.1, 5.0, 4.9, 5.2, 5.0, 4.7, 5.3];
      A_Hat : constant Real := MLE_AWGN_Constant (X);
      Sigma2 : constant Real := 0.04;  -- illustrative known σ²
      N : constant Positive := X'Length;
   begin
      Check (Near (A_Hat, Mean (X)), "AWGN MLE = sample mean");
      Check (Approx (A_Hat, 5.0, 0.15), "AWGN MLE near true A=5");
      Check (Near (MLE_AWGN_Constant (X), MLE_Gaussian_Mean (X)),
             "AWGN MLE = Gaussian-mean MLE");
      Check (Approx (Analytic_Var_Sample_Mean (N, Sigma2),
                     Sigma2 / Real (N)),
             "AWGN var(Â)=σ²/N");
      Check (Approx (CRLB_Gaussian_Mean (N, Sigma2),
                     Analytic_Var_Sample_Mean (N, Sigma2)),
             "AWGN sample mean attains CRLB");
      Check (Approx (Fisher_Info_Gaussian_Mean (N, Sigma2),
                     Real (N) / Sigma2),
             "AWGN Fisher I=N/σ²");
   end;

   ---------------------------------------------------------------------
   Section ("12. CRLB Gaussian mean — efficiency of sample mean");
   ---------------------------------------------------------------------
   declare
      N : constant Positive := 100;
      S2 : constant Real := 4.0;
      I  : constant Real := Fisher_Info_Gaussian_Mean (N, S2);
      C  : constant Real := CRLB_Gaussian_Mean (N, S2);
      V  : constant Real := Analytic_Var_Sample_Mean (N, S2);
      Raised : Boolean := False;
   begin
      Check (Approx (I, 25.0), "I(μ)=N/σ²=100/4=25");
      Check (Approx (C, 0.04), "CRLB=σ²/N=0.04");
      Check (Approx (V, 0.04), "var(x̄)=σ²/N attains CRLB");
      Check (Near (C, V), "sample mean is efficient (CRLB)");
      Check (Approx (CRLB_Gaussian_Mean (1, 1.0), 1.0), "CRLB N=1");
      Check (Approx (Fisher_Info_Gaussian_Mean (50, 2.0), 25.0),
             "Fisher another N,σ²");
      begin
         declare
            Unused : Real;
         begin
            Unused := Fisher_Info_Gaussian_Mean (10, 0.0);
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
      Check (Raised, "Fisher σ²=0 raises");
   end;

   ---------------------------------------------------------------------
   Section ("13. CRLB Bernoulli — proportion attains bound");
   ---------------------------------------------------------------------
   declare
      N : constant Positive := 50;
      P : constant Real := 0.3;
      I : constant Real := Fisher_Info_Bernoulli (N, P);
      C : constant Real := CRLB_Bernoulli (N, P);
      V : constant Real := Analytic_Var_Bernoulli_Proportion (N, P);
      Raised : Boolean := False;
   begin
      Check (Approx (I, Real (N) / (P * (1.0 - P))),
             "I(p)=N/(p(1-p))");
      Check (Approx (C, P * (1.0 - P) / Real (N)),
             "CRLB=p(1-p)/N");
      Check (Near (C, V), "Bernoulli p̂ attains CRLB");
      Check (Approx (Analytic_Var_Bernoulli_Proportion (100, 0.5), 0.0025),
             "Var(p̂) at p=0.5, N=100");
      Check (Approx (CRLB_Bernoulli (100, 0.5), 0.0025),
             "CRLB at p=0.5, N=100");
      begin
         declare
            Unused : Real;
         begin
            Unused := Fisher_Info_Bernoulli (10, 0.0);
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
      Check (Raised, "Fisher Bernoulli p=0 raises");
   end;

   ---------------------------------------------------------------------
   Section ("14. Bias of Uniform[0,θ] maximum (Wikipedia)");
   ---------------------------------------------------------------------
   declare
      Theta : constant Real := 10.0;
      N     : constant Positive := 4;
      --  E[max]=4*10/5=8; Bias=8-10=-2= -10/5
      E_Max : constant Real := Expected_Uniform_Max (Theta, N);
      B     : constant Real := Bias_Uniform_Max_Analytic (Theta, N);
      X     : constant Sample := [2.0, 5.0, 7.0, 9.0];
      Mle   : constant Real := MLE_Uniform_Theta (X);
   begin
      Check (Approx (E_Max, 8.0), "E[max]=Nθ/(N+1)=8");
      Check (Approx (B, -2.0), "Bias(max)=−θ/(N+1)=−2");
      Check (B < 0.0, "Uniform max is negatively biased");
      Check (Approx (Bias (Mle, Theta), Mle - Theta),
             "pointwise bias of this sample max");
      Check (Mle < Theta, "sample max ≤ θ (here strict)");
      Check (Approx (Bias_Uniform_Max_Analytic (1.0, 1), -0.5),
             "N=1 Bias=−θ/2");
      Check (Approx (Expected_Uniform_Max (1.0, 1), 0.5),
             "N=1 E[max]=θ/2");
      Check (Approx (Bias_Uniform_Max_Analytic (Theta, 99),
                    -Theta / 100.0),
             "large-N Bias → 0");
   end;

   ---------------------------------------------------------------------
   Section ("15. MSE identity Bias²+Var across estimators");
   ---------------------------------------------------------------------
   declare
      --  Analytic: Uniform max Bias² + Var should equal MSE.
      --  For Uniform[0,θ], Var(max)= N·θ² / ((N+1)² (N+2))
      Theta : constant Real := 6.0;
      N     : constant Positive := 3;
      B     : constant Real := Bias_Uniform_Max_Analytic (Theta, N);
      --  Var = N θ² / ((N+1)² (N+2)) = 3*36 / (16*5) = 108/80 = 1.35
      V_Max : constant Real :=
        Real (N) * Theta ** 2
        / (Real (N + 1) ** 2 * Real (N + 2));
      Mse_U : constant Real := MSE_From_Bias_Var (B, V_Max);
      --  Gaussian mean unbiased: Bias=0, MSE=Var=σ²/N
      S2 : constant Real := 9.0;
      Ng : constant Positive := 16;
      Vg : constant Real := Analytic_Var_Sample_Mean (Ng, S2);
   begin
      Check (Approx (V_Max, 1.35, 1.0E-9), "analytic Var(Uniform max)");
      Check (Approx (Mse_U, B * B + V_Max), "Uniform MSE = Bias²+Var");
      Check (Mse_U > V_Max, "biased estimator MSE > Var");
      Check (Approx (MSE_From_Bias_Var (0.0, Vg), Vg),
             "unbiased Gaussian MSE = Var = CRLB");
      Check (Approx (Vg, CRLB_Gaussian_Mean (Ng, S2)),
             "Gaussian MSE attains CRLB");
      Check (Approx (B * B, 2.25), "Bias² for Uniform N=3 θ=6");
   end;

   ---------------------------------------------------------------------
   Section ("16. Empty sample and capacity exceptions");
   ---------------------------------------------------------------------
   declare
      Raised_Mean : Boolean := False;
      Raised_Var  : Boolean := False;
      Raised_Max  : Boolean := False;
      Raised_Bern : Boolean := False;
   begin
      begin
         declare
            E : Sample (1 .. 0);
            U : Real;
         begin
            U := Mean (E);
            pragma Unreferenced (U);
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised_Mean := True;
         when others =>
            null;
      end;
      Check (Raised_Mean, "empty Mean raises");

      begin
         declare
            E : Sample (1 .. 0);
            U : Real;
         begin
            U := Variance (E, False);
            pragma Unreferenced (U);
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised_Var := True;
         when others =>
            null;
      end;
      Check (Raised_Var, "empty Variance raises");

      begin
         declare
            E : Sample (1 .. 0);
            U : Real;
         begin
            U := Sample_Maximum (E);
            pragma Unreferenced (U);
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised_Max := True;
         when others =>
            null;
      end;
      Check (Raised_Max, "empty Sample_Maximum raises");

      begin
         declare
            E : Sample (1 .. 0);
            U : Real;
         begin
            U := MLE_Bernoulli_P (E);
            pragma Unreferenced (U);
         end;
      exception
         when Invalid_Argument | Constraint_Error =>
            Raised_Bern := True;
         when others =>
            null;
      end;
      Check (Raised_Bern, "empty Bernoulli MLE raises");
   end;

   ---------------------------------------------------------------------
   Section ("17. Cross-checks MLE=MoM Gaussian / Exp; AWGN fixture");
   ---------------------------------------------------------------------
   declare
      G : constant Sample := [-1.0, 0.0, 1.0, 2.0, 3.0];
      E : constant Sample := [0.5, 1.0, 1.5, 2.0];
      --  AWGN fixture: known A=2, σ²=1; samples around 2
      Awgn : constant Sample :=
        [1.2, 2.5, 1.8, 2.1, 2.4, 1.9, 2.0, 2.3, 1.7, 2.1];
      A_Hat : constant Real := MLE_AWGN_Constant (Awgn);
      N_A   : constant Positive := Awgn'Length;
   begin
      Check (Near (MLE_Gaussian_Mean (G), Mean (G)),
             "Gaussian MLE mean ≡ Mean");
      Check (Near (MLE_Exponential_Rate (E), MoM_Exponential_Rate (E)),
             "Exp MLE ≡ MoM");
      Check (Approx (MLE_Gaussian_Variance (G, False),
                     Variance (G, False)),
             "Gaussian MLE σ² ≡ pop Variance");
      Check (Approx (A_Hat, Mean (Awgn)), "AWGN fixture MLE=mean");
      Check (Approx (A_Hat, 2.0, 0.2), "AWGN fixture near A=2");
      Check (Approx (CRLB_Gaussian_Mean (N_A, 1.0), 0.1),
             "AWGN fixture CRLB=0.1");
      Check (Near (Analytic_Var_Sample_Mean (N_A, 1.0),
                   CRLB_Gaussian_Mean (N_A, 1.0)),
             "AWGN fixture attains CRLB analytically");
      Check (Approx (MLE_Bernoulli_P ([1.0, 0.0, 1.0, 0.0]), 0.5),
             "fair coin proportion");
   end;

   New_Line;
   Put_Line ("============================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL TESTS PASSED");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;

   pragma Assert (Fail_Count = 0);
end Tests;
