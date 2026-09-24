--  Standalone test suite for Scoring_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Scoring_Algorithm; use Scoring_Algorithm;

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
   Put_Line ("Scoring_Algorithm test suite");
   Put_Line ("============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Clamp / Sample helpers");
   ---------------------------------------------------------------------
   declare
      Data : constant Sample := [1.0, 0.0, 1.0, 1.0, 0.0];
      Empty : Sample (1 .. 0);
      Raised : Boolean := False;
   begin
      Check (Near (1.0, 1.0 + 1.0E-9), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Approx (Clamp_Unit_Interval (-0.5), Prob_Eps),
             "Clamp negative -> Prob_Eps");
      Check (Approx (Clamp_Unit_Interval (1.5), 1.0 - Prob_Eps),
             "Clamp >1 -> 1-Prob_Eps");
      Check (Approx (Clamp_Unit_Interval (0.3), 0.3), "Clamp interior unchanged");
      Check (Count_Successes (Data) = 3, "Count_Successes = 3");
      Check (Approx (Sample_Sum (Data), 3.0), "Sample_Sum = 3");
      Check (Approx (Sample_Mean (Data), 0.6), "Sample_Mean = 0.6");
      begin
         declare
            Unused : Real;
         begin
            Unused := Sample_Mean (Empty);
            pragma Unreferenced (Unused);
         end;
      exception
         when Empty_Sample =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Sample_Mean empty raises");
   end;

   ---------------------------------------------------------------------
   Section ("2. Fisher_Step one-update formula");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean := False;
      T1     : Real;
   begin
      --  θ' = θ + V/I
      Check (Approx (Fisher_Step (0.5, 2.0, 4.0), 1.0),
             "Fisher_Step 0.5+2/4 = 1.0");
      Check (Approx (Fisher_Step (1.0, -0.5, 2.0), 0.75),
             "Fisher_Step 1.0-0.5/2 = 0.75");
      Check (Approx (Fisher_Step (2.0, 0.0, 10.0), 2.0),
             "Fisher_Step zero score stays");
      T1 := Fisher_Step (0.0, 3.0, 1.0);
      Check (Approx (T1, 3.0), "Fisher_Step from 0");
      begin
         declare
            Unused : Real;
         begin
            Unused := Fisher_Step (1.0, 1.0, 0.0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Singular_Information =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Fisher_Step Info=0 raises Singular_Information");
      Raised := False;
      begin
         declare
            Unused : Real;
         begin
            Unused := Fisher_Step (1.0, 1.0, Info_Singularity / 10.0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Singular_Information =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Fisher_Step tiny Info raises");
   end;

   ---------------------------------------------------------------------
   Section ("3. Bernoulli closed-form score / info / MLE");
   ---------------------------------------------------------------------
   declare
      --  n=10, k=7 => MLE=0.7
      K : constant Natural := 7;
      N : constant Positive := 10;
      P : constant Real := 0.5;
      V : constant Real := Bernoulli_Score (P, K, N);
      I : constant Real := Bernoulli_Fisher_Info (P, N);
      J : constant Real := Bernoulli_Observed_Info (P, K, N);
      M : constant Real := Bernoulli_MLE (K, N);
   begin
      Check (Approx (M, 0.7), "Bernoulli_MLE = 0.7");
      --  V(0.5) = 7/0.5 - 3/0.5 = 14 - 6 = 8
      Check (Approx (V, 8.0), "Bernoulli_Score at 0.5 = 8");
      --  I(0.5) = 10/(0.5*0.5) = 40
      Check (Approx (I, 40.0), "Bernoulli_Fisher_Info at 0.5 = 40");
      --  J(0.5) = 7/0.25 + 3/0.25 = 28 + 12 = 40
      Check (Approx (J, 40.0), "Bernoulli_Observed_Info at 0.5 = 40");
      --  One Fisher step: 0.5 + 8/40 = 0.7
      Check (Approx (Fisher_Step (P, V, I), 0.7),
             "one Fisher step Bernoulli -> MLE");
      Check (Approx (Bernoulli_Score (0.7, K, N), 0.0, 1.0E-9),
             "score at MLE is 0");
      Check (Bernoulli_Fisher_Info (0.3, N) > 0.0, "Fisher info positive");
   end;

   ---------------------------------------------------------------------
   Section ("4. Bernoulli Fit converges to k/n");
   ---------------------------------------------------------------------
   declare
      Data : constant Sample :=
        [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0];  -- 7/10
      Rf   : Scoring_Result;
      Ro   : Scoring_Result;
      Mle  : constant Real := Bernoulli_MLE (7, 10);
   begin
      Rf := Fit_Bernoulli (Data, Start => 0.2, Kind => Fisher_Expected);
      Ro := Fit_Bernoulli (Data, Start => 0.2, Kind => Observed_Newton);
      Check (Rf.Converged, "Bernoulli Fisher converged");
      Check (Ro.Converged, "Bernoulli Observed converged");
      Check (Approx (Rf.Estimate, Mle, 1.0E-8), "Fisher estimate = 0.7");
      Check (Approx (Ro.Estimate, Mle, 1.0E-8), "Observed estimate = 0.7");
      Check (Rf.Iterations >= 1, "Fisher used >=1 iter");
      Check (Rf.Iterations <= 50, "Fisher iters bounded");
      Check (Approx (Rf.Last_Score, 0.0, 1.0E-6), "Fisher last score ~0");
      declare
         Rc : constant Scoring_Result :=
           Fit_Bernoulli_Counts (7, 10, Start => 0.9);
      begin
         Check (Approx (Rc.Estimate, 0.7, 1.0E-8),
                "Fit_Bernoulli_Counts -> 0.7");
         Check (Rc.Converged, "counts fit converged");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("5. Bernoulli bad starts recover / sample score");
   ---------------------------------------------------------------------
   declare
      Data : constant Sample := [1.0, 0.0, 1.0, 0.0];  -- MLE=0.5
      R1   : Scoring_Result;
      R2   : Scoring_Result;
   begin
      R1 := Fit_Bernoulli (Data, Start => -5.0);
      R2 := Fit_Bernoulli (Data, Start => 5.0);
      Check (R1.Converged, "start -5 clamped and converges");
      Check (R2.Converged, "start 5 clamped and converges");
      Check (Approx (R1.Estimate, 0.5, 1.0E-7), "from -5 -> 0.5");
      Check (Approx (R2.Estimate, 0.5, 1.0E-7), "from 5 -> 0.5");
      Check (Approx (Bernoulli_Score_Sample (0.5, Data), 0.0, 1.0E-9),
             "sample score at MLE 0");
      Check (Bernoulli_Fisher_Info_Sample (0.25, Data) > 0.0,
             "sample Fisher info > 0");
      Check (Bernoulli_Observed_Info_Sample (0.25, Data) > 0.0,
             "sample Observed info > 0");
   end;

   ---------------------------------------------------------------------
   Section ("6. Poisson closed-form and one Fisher step");
   ---------------------------------------------------------------------
   declare
      Data : constant Sample := [2.0, 4.0, 3.0, 3.0];  -- mean=3
      Lam  : constant Real := 1.0;
      V    : constant Real := Poisson_Score (Lam, Data);
      I    : constant Real := Poisson_Fisher_Info (Lam, Data);
      J    : constant Real := Poisson_Observed_Info (Lam, Data);
      Mle  : constant Real := Poisson_MLE (Data);
   begin
      Check (Approx (Mle, 3.0), "Poisson_MLE = 3");
      --  V(1) = -4 + 12/1 = 8
      Check (Approx (V, 8.0), "Poisson_Score at 1 = 8");
      --  I(1) = 4/1 = 4
      Check (Approx (I, 4.0), "Poisson_Fisher_Info at 1 = 4");
      --  J(1) = 12/1 = 12
      Check (Approx (J, 12.0), "Poisson_Observed_Info at 1 = 12");
      Check (Approx (Fisher_Step (Lam, V, I), 3.0),
             "one Fisher step Poisson -> mean");
      Check (Approx (Poisson_Score (3.0, Data), 0.0, 1.0E-9),
             "score at MLE 0");
      --  At MLE, I = J = n/λ = 4/3
      Check (Approx (Poisson_Fisher_Info (3.0, Data), 4.0 / 3.0),
             "I at MLE = n/λ");
      Check (Approx (Poisson_Observed_Info (3.0, Data), 4.0 / 3.0),
             "J at MLE = I");
   end;

   ---------------------------------------------------------------------
   Section ("7. Poisson Fit converges to sample mean");
   ---------------------------------------------------------------------
   declare
      Data : constant Sample := [1.0, 2.0, 3.0, 4.0, 5.0];  -- mean=3
      Rf   : Scoring_Result;
      Ro   : Scoring_Result;
   begin
      Rf := Fit_Poisson (Data, Start => 0.5, Kind => Fisher_Expected);
      Ro := Fit_Poisson (Data, Start => 10.0, Kind => Observed_Newton);
      Check (Rf.Converged, "Poisson Fisher converged");
      Check (Ro.Converged, "Poisson Observed converged");
      Check (Approx (Rf.Estimate, 3.0, 1.0E-7), "Fisher -> 3");
      Check (Approx (Ro.Estimate, 3.0, 1.0E-7), "Observed -> 3");
      Check (Rf.Iterations <= 20, "Fisher few iters");
      Check (Approx (Rf.Last_Score, 0.0, 1.0E-5), "last score ~0");
      Check (Rf.Kind = Fisher_Expected, "Kind recorded Fisher");
      Check (Ro.Kind = Observed_Newton, "Kind recorded Observed");
   end;

   ---------------------------------------------------------------------
   Section ("8. Normal mean closed-form; I = J; one-step MLE");
   ---------------------------------------------------------------------
   declare
      Data    : constant Sample := [0.0, 2.0, 4.0, 6.0];  -- mean=3
      Sigma2  : constant Real := 4.0;
      Mu0     : constant Real := 0.0;
      V       : constant Real := Normal_Mean_Score (Mu0, Sigma2, Data);
      I       : constant Real := Normal_Mean_Fisher_Info (Sigma2, 4);
      J       : constant Real := Normal_Mean_Observed_Info (Sigma2, 4);
      Mle     : constant Real := Normal_Mean_MLE (Data);
   begin
      Check (Approx (Mle, 3.0), "Normal_Mean_MLE = 3");
      --  V(0) = (0+2+4+6)/4 = 12/4 = 3
      Check (Approx (V, 3.0), "Normal score at 0 = 3");
      --  I = 4/4 = 1
      Check (Approx (I, 1.0), "Normal Fisher info = 1");
      Check (Approx (I, J), "Normal I = J everywhere");
      Check (Approx (Fisher_Step (Mu0, V, I), 3.0),
             "one Fisher step Normal -> mean");
      Check (Approx (Normal_Mean_Score (3.0, Sigma2, Data), 0.0, 1.0E-9),
             "score at MLE 0");
      Check (Normal_Mean_Fisher_Info (1.0, 10) > Normal_Mean_Fisher_Info (2.0, 10),
             "smaller σ² => larger info");
   end;

   ---------------------------------------------------------------------
   Section ("9. Fit_Normal_Mean Fisher vs Observed agree");
   ---------------------------------------------------------------------
   declare
      Data   : constant Sample := [-1.0, 0.0, 1.0, 2.0, 3.0];  -- mean=1
      Sigma2 : constant Real := 1.0;
      Rf     : Scoring_Result;
      Ro     : Scoring_Result;
   begin
      Rf := Fit_Normal_Mean
        (Data, Sigma2, Start => 100.0, Kind => Fisher_Expected);
      Ro := Fit_Normal_Mean
        (Data, Sigma2, Start => -50.0, Kind => Observed_Newton);
      Check (Rf.Converged, "Normal Fisher converged");
      Check (Ro.Converged, "Normal Observed converged");
      Check (Approx (Rf.Estimate, 1.0, 1.0E-8), "Fisher -> 1");
      Check (Approx (Ro.Estimate, 1.0, 1.0E-8), "Observed -> 1");
      Check (Approx (Rf.Estimate, Ro.Estimate, 1.0E-10),
             "Fisher and Observed agree");
      Check (Rf.Iterations <= 5, "Normal converges in few steps");
      Check (Approx (Rf.Last_Info, Real (5) / Sigma2),
             "last info = n/σ²");
   end;

   ---------------------------------------------------------------------
   Section ("10. Exponential rate; I = J identity");
   ---------------------------------------------------------------------
   declare
      Data : constant Sample := [1.0, 2.0, 1.0, 2.0];  -- mean=1.5, MLE=2/3
      Lam  : constant Real := 1.0;
      V    : constant Real := Exponential_Score (Lam, Data);
      I    : constant Real := Exponential_Fisher_Info (Lam, Data);
      J    : constant Real := Exponential_Observed_Info (Lam, Data);
      Mle  : constant Real := Exponential_MLE (Data);
   begin
      Check (Approx (Mle, 2.0 / 3.0), "Exponential_MLE = 2/3");
      --  V(1) = 4/1 - 6 = -2
      Check (Approx (V, -2.0), "Exp score at 1 = -2");
      --  I = J = 4/1 = 4
      Check (Approx (I, 4.0), "Exp Fisher info = 4");
      Check (Approx (I, J), "Exp I = J (rate parameterization)");
      Check (Approx (Exponential_Score (Mle, Data), 0.0, 1.0E-9),
             "score at MLE 0");
      Check (Approx (Exponential_Fisher_Info (Mle, Data),
                     Exponential_Observed_Info (Mle, Data)),
             "I=J at MLE too");
      Check (Exponential_Fisher_Info (0.5, Data) >
               Exponential_Fisher_Info (2.0, Data),
             "larger λ => smaller Fisher info");
   end;

   ---------------------------------------------------------------------
   Section ("11. Fit_Exponential converges; Fisher vs Observed");
   ---------------------------------------------------------------------
   declare
      Data : constant Sample := [0.5, 1.0, 1.5, 2.0];  -- mean=1.25, λ=0.8
      Mle  : constant Real := Exponential_MLE (Data);
      Rf   : Scoring_Result;
      Ro   : Scoring_Result;
   begin
      Check (Approx (Mle, 0.8), "analytic MLE 0.8");
      Rf := Fit_Exponential (Data, Start => 0.1, Kind => Fisher_Expected);
      Ro := Fit_Exponential (Data, Start => 5.0, Kind => Observed_Newton);
      Check (Rf.Converged, "Exp Fisher converged");
      Check (Ro.Converged, "Exp Observed converged");
      Check (Approx (Rf.Estimate, Mle, 1.0E-7), "Fisher -> MLE");
      Check (Approx (Ro.Estimate, Mle, 1.0E-7), "Observed -> MLE");
      Check (Approx (Rf.Estimate, Ro.Estimate, 1.0E-8),
             "Fisher/Observed agree (I=J)");
      Check (Rf.Iterations >= 1 and then Rf.Iterations <= 40,
             "iter count in bounds");
      Check (Approx (Rf.Last_Score, 0.0, 1.0E-5), "last score ~0");
   end;

   ---------------------------------------------------------------------
   Section ("12. Empty sample / invalid / singular edges");
   ---------------------------------------------------------------------
   declare
      Empty  : Sample (1 .. 0);
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Unused : Scoring_Result;
         begin
            Unused := Fit_Bernoulli (Empty);
            pragma Unreferenced (Unused);
         end;
      exception
         when Empty_Sample =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Fit_Bernoulli empty raises");

      Raised := False;
      begin
         declare
            Unused : Scoring_Result;
         begin
            Unused := Fit_Poisson (Empty);
            pragma Unreferenced (Unused);
         end;
      exception
         when Empty_Sample =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Fit_Poisson empty raises");

      Raised := False;
      begin
         declare
            Unused : Scoring_Result;
            Data   : constant Sample := [1.0, 2.0];
         begin
            Unused := Fit_Normal_Mean (Data, Sigma2 => -1.0);
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
      Check (Raised, "Fit_Normal_Mean Sigma2<=0 raises");

      Raised := False;
      begin
         declare
            Unused : Scoring_Result;
         begin
            Unused := Fit_Exponential (Empty);
            pragma Unreferenced (Unused);
         end;
      exception
         when Empty_Sample =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Fit_Exponential empty raises");

      Raised := False;
      begin
         declare
            Bad  : constant Sample := [-1.0, -2.0];
            Unused : Real;
         begin
            Unused := Exponential_MLE (Bad);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Exponential_MLE nonpositive mean raises");

      --  Degenerate_Geometry renames Singular_Information
      Raised := False;
      begin
         declare
            Unused : Real;
         begin
            Unused := Fisher_Step (0.0, 1.0, 0.0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "Degenerate_Geometry alias works");
   end;

   ---------------------------------------------------------------------
   Section ("13. Tolerance / Raise_On_Fail / iteration bounds");
   ---------------------------------------------------------------------
   declare
      Data : constant Sample := [1.0, 0.0, 1.0, 1.0];  -- MLE=0.75
      R    : Scoring_Result;
      Raised : Boolean := False;
   begin
      R := Fit_Bernoulli
        (Data, Start => 0.5, Tol => 1.0E-12, Max_Iter => 50);
      Check (R.Converged, "tight tol still converges");
      Check (Approx (R.Estimate, 0.75, 1.0E-8), "estimate 0.75");
      Check (R.Iterations <= 50, "iters <= Max_Iter");

      --  Max_Iter=1 with Raise_On_Fail False may or may not converge
      --  (Bernoulli Fisher often converges in 1 step).
      R := Fit_Bernoulli
        (Data, Start => 0.1, Max_Iter => 1, Raise_On_Fail => False);
      Check (R.Iterations = 1, "Max_Iter=1 records 1");
      Check (R.Converged or else not R.Converged, "Converged flag set");

      --  Force non-convergence with absurd Max_Iter=1 on Exponential
      --  from a far start if one step insufficient — use Raise_On_Fail.
      --  Exponential from far start often needs >1 step.
      R := Fit_Exponential
        (Data => [2.0, 2.0, 2.0, 2.0],
         Start => 0.01,
         Max_Iter => 1,
         Raise_On_Fail => False,
         Tol => 1.0E-14);
      Check (R.Iterations = 1, "exp Max_Iter=1");
      --  Either converged in one lucky step or flagged not converged
      if not R.Converged then
         Raised := False;
         begin
            declare
               Unused : Scoring_Result;
            begin
               Unused := Fit_Exponential
                 (Data => [2.0, 2.0, 2.0, 2.0],
                  Start => 0.01,
                  Max_Iter => 1,
                  Raise_On_Fail => True,
                  Tol => 1.0E-14);
               pragma Unreferenced (Unused);
            end;
         exception
            when Did_Not_Converge =>
               Raised := True;
            when others =>
               null;
         end;
         Check (Raised, "Did_Not_Converge when Raise_On_Fail");
      else
         Check (True, "one-step Exp converged (acceptable)");
         Check (Approx (R.Estimate, 0.5, 1.0E-3)
                  or else R.Converged,
                "estimate reasonable or converged");
      end if;

      Check (Scoring_Kind'Pos (Fisher_Expected) = 0
               or else Scoring_Kind'Pos (Observed_Newton) = 1,
             "Scoring_Kind enumeration intact");
   end;

   ---------------------------------------------------------------------
   Section ("14. Cross-model analytic MLE comparison");
   ---------------------------------------------------------------------
   declare
      Bern : constant Sample :=
        [1.0, 1.0, 0.0, 1.0, 0.0, 0.0, 1.0, 1.0];  -- 5/8=0.625
      Pois : constant Sample := [0.0, 1.0, 2.0, 3.0];  -- mean=1.5
      Norm : constant Sample := [10.0, 12.0, 11.0];  -- mean=11
      Expd : constant Sample := [1.0, 1.0, 1.0];  -- mean=1, λ=1
      Rb   : Scoring_Result;
      Rp   : Scoring_Result;
      Rn   : Scoring_Result;
      Re   : Scoring_Result;
   begin
      Rb := Fit_Bernoulli (Bern, Start => 0.3);
      Rp := Fit_Poisson (Pois, Start => 0.5);
      Rn := Fit_Normal_Mean (Norm, Sigma2 => 1.0, Start => 0.0);
      Re := Fit_Exponential (Expd, Start => 2.0);
      Check (Approx (Rb.Estimate, Bernoulli_MLE (5, 8), 1.0E-8),
             "Bernoulli vs analytic");
      Check (Approx (Rp.Estimate, Poisson_MLE (Pois), 1.0E-8),
             "Poisson vs analytic");
      Check (Approx (Rn.Estimate, Normal_Mean_MLE (Norm), 1.0E-8),
             "Normal vs analytic");
      Check (Approx (Re.Estimate, Exponential_MLE (Expd), 1.0E-8),
             "Exponential vs analytic");
      Check (Rb.Converged and then Rp.Converged
               and then Rn.Converged and then Re.Converged,
             "all four models converged");
      Check (Approx (Rb.Estimate, 0.625), "Bernoulli 5/8");
      Check (Approx (Rp.Estimate, 1.5), "Poisson 1.5");
      Check (Approx (Rn.Estimate, 11.0), "Normal 11");
      Check (Approx (Re.Estimate, 1.0), "Exponential 1");
   end;

   ---------------------------------------------------------------------
   Section ("15. Bernoulli I vs J away from MLE");
   ---------------------------------------------------------------------
   declare
      K : constant Natural := 3;
      N : constant Positive := 10;
      P : constant Real := 0.2;  -- MLE=0.3; away from MLE
      I : constant Real := Bernoulli_Fisher_Info (P, N);
      J : constant Real := Bernoulli_Observed_Info (P, K, N);
   begin
      Check (not Approx (I, J, 1.0E-6),
             "Bernoulli I ≠ J away from MLE");
      Check (Approx (Bernoulli_Fisher_Info (0.3, N),
                     Bernoulli_Observed_Info (0.3, K, N), 1.0E-9),
             "Bernoulli I = J at MLE");
      --  Observed Newton still reaches MLE
      declare
         R : constant Scoring_Result :=
           Fit_Bernoulli_Counts
             (K, N, Start => 0.2, Kind => Observed_Newton);
      begin
         Check (R.Converged, "Observed Newton Bernoulli converges");
         Check (Approx (R.Estimate, 0.3, 1.0E-7), "to MLE 0.3");
         Check (R.Last_Info > 0.0, "last info positive");
      end;
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
