--  Standalone test suite for Bayesian_Statistics (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Bayesian_Statistics; use Bayesian_Statistics;

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
   Put_Line ("Bayesian_Statistics test suite");
   Put_Line ("==============================");

   ---------------------------------------------------------------------
   Section ("1. Near / Safe_Log / Log_Sum / RNG");
   ---------------------------------------------------------------------
   declare
      S : RNG_State;
      U1, U2 : Unit_Interval;
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-9), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-10, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Approx (Safe_Log (1.0), 0.0, 1.0E-12), "Safe_Log(1)=0");
      Check (Safe_Log (0.0) < -1.0E20, "Safe_Log(0) sentinel");
      Check (Safe_Log (-1.0) < -1.0E20, "Safe_Log(-1) sentinel");
      Check (Approx (Log_Sum (0.0, Safe_Log (0.0)), 0.0, 1.0E-9),
             "Log_Sum(0,-inf)~0");
      Check (Approx (Log_Sum (0.0, 0.0), Safe_Log (2.0), 1.0E-9),
             "Log_Sum(0,0)=log2");
      Seed_RNG (S, 42);
      U1 := Next_Unit (S);
      U2 := Next_Unit (S);
      Check (U1 >= 0.0 and then U1 < 1.0, "Next_Unit in [0,1)");
      Check (U2 >= 0.0 and then U2 < 1.0, "Next_Unit second draw");
      Check (U1 /= U2, "RNG advances");
      Seed_RNG (S, 42);
      Check (Approx (Next_Unit (S), U1, 0.0), "RNG reproducible");
   end;

   ---------------------------------------------------------------------
   Section ("2. Bayes theorem — disease / false-positive example");
   ---------------------------------------------------------------------
   declare
      --  Classic base-rate fallacy numbers:
      --  P(D)=0.001, P(+|D)=0.99, P(+|¬D)=0.05
      Prior       : constant Unit_Interval := 0.001;
      Sens        : constant Unit_Interval := 0.99;
      FPR         : constant Unit_Interval := 0.05;
      Ev          : constant Unit_Interval :=
        Evidence_From_Complement (Prior, Sens, FPR);
      --  Ev = 0.99*0.001 + 0.05*0.999 = 0.00099 + 0.04995 = 0.05094
      Post        : constant Unit_Interval :=
        Posterior_Prob_Complement (Prior, Sens, FPR);
      Post2       : constant Unit_Interval :=
        Posterior_Prob (Prior, Sens, Ev);
      Expected    : constant Real := 0.00099 / 0.05094;
   begin
      Check (Is_Valid_Probability (0.0), "0 is valid prob");
      Check (Is_Valid_Probability (1.0), "1 is valid prob");
      Check (Is_Valid_Probability (0.5), "0.5 is valid prob");
      Check (not Is_Valid_Probability (-0.1), "neg invalid prob");
      Check (not Is_Valid_Probability (1.1), ">1 invalid prob");
      Check (Approx (Ev, 0.05094, 1.0E-10), "disease evidence P(+)");
      Check (Approx (Post, Expected, 1.0E-10), "disease posterior exact");
      Check (Approx (Post, 0.019435, 1.0E-6), "disease posterior ~1.94%");
      Check (Post < 0.05, "posterior still small despite + test");
      Check (Post > Prior, "positive test raises belief");
      Check (Approx (Post, Post2, 1.0E-12), "two Bayes forms agree");
      Check (Approx
        (Posterior_Prob_Complement (0.5, 0.8, 0.8), 0.5, 1.0E-12),
             "symmetric likelihood → prior");
      Check (Approx
        (Posterior_Prob_Complement (1.0, 0.7, 0.2), 1.0, 1.0E-12),
             "prior 1 stays 1");
      Check (Approx
        (Posterior_Prob_Complement (0.0, 0.7, 0.2), 0.0, 1.0E-12),
             "prior 0 stays 0");
   end;

   ---------------------------------------------------------------------
   Section ("3. Invalid probability / evidence exceptions");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            Dummy : Unit_Interval;
         begin
            Dummy := Posterior_Prob (0.5, 0.5, 0.0);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument => Raised := True;
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, "Posterior_Prob rejects Evidence=0");

      Raised := False;
      begin
         declare
            Dummy : Unit_Interval;
         begin
            Dummy := Posterior_Prob_Complement (0.0, 0.0, 0.0);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "complement form rejects zero evidence");

      Raised := False;
      begin
         declare
            Dummy : Beta_Params;
         begin
            Dummy := Beta_Update ((0.0, 1.0), 1, 2);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument => Raised := True;
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, "Beta_Update rejects non-positive alpha");

      Raised := False;
      begin
         declare
            Dummy : Beta_Params;
         begin
            Dummy := Beta_Update ((1.0, 1.0), 3, 2);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument => Raised := True;
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, "Beta_Update rejects Successes>Trials");

      Raised := False;
      begin
         declare
            Dummy : Positive_Real;
         begin
            Dummy := Bayes_Factor (1.0, 0.0);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument => Raised := True;
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, "Bayes_Factor rejects zero H2 likelihood");
   end;

   ---------------------------------------------------------------------
   Section ("4. Beta–Bernoulli conjugate update");
   ---------------------------------------------------------------------
   declare
      Prior : constant Beta_Params := (Alpha => 2.0, Beta => 2.0);
      Post  : constant Beta_Params := Beta_Update (Prior, 7, 10);
      Flat  : constant Beta_Params := (1.0, 1.0);
      After : constant Beta_Params := Beta_Update (Flat, 3, 3);
   begin
      Check (Approx (Post.Alpha, 9.0), "alpha' = 2+7");
      Check (Approx (Post.Beta, 5.0), "beta' = 2+3");
      Check (Approx (Beta_Mean (Prior), 0.5), "Beta(2,2) mean 1/2");
      Check (Approx (Beta_Mean (Post), 9.0 / 14.0, 1.0E-12),
             "posterior mean 9/14");
      Check (Approx (Beta_Mode (Post), 8.0 / 12.0, 1.0E-12),
             "MAP (9-1)/(14-2)=2/3");
      Check (Approx (Beta_Mode (Prior), 0.5), "Beta(2,2) mode 1/2");
      Check (Approx (Beta_Mode (Flat), 0.5), "Beta(1,1) mode midpoint");
      Check (Approx (After.Alpha, 4.0) and then Approx (After.Beta, 1.0),
             "3 successes / 3 trials on flat");
      Check (Approx (Beta_Mean (After), 0.8), "mean after all successes");
      Check (Beta_Variance (Post) > 0.0, "posterior variance > 0");
      Check (Beta_Variance (Post) < Beta_Variance (Prior),
             "data shrinks variance");
      declare
         Zero_Data : constant Beta_Params := Beta_Update (Prior, 0, 0);
      begin
         Check (Approx (Zero_Data.Alpha, Prior.Alpha)
                  and then Approx (Zero_Data.Beta, Prior.Beta),
                "0 trials leaves prior unchanged");
      end;
      Check (Approx (Beta_Mode ((0.5, 2.0)), 0.0), "mode at 0 when α<1");
      Check (Approx (Beta_Mode ((2.0, 0.5)), 1.0), "mode at 1 when β<1");
   end;

   ---------------------------------------------------------------------
   Section ("5. Beta PDF / incomplete beta / quantiles");
   ---------------------------------------------------------------------
   declare
      P   : constant Beta_Params := (2.0, 2.0);
      --  Beta(2,2) PDF = 6 x (1-x); at 0.5 → 1.5
      Pdf : constant Real := Beta_PDF (0.5, P);
      Cdf : constant Real :=
        Regularized_Incomplete_Beta (0.5, 2.0, 2.0);
      Q50 : constant Real := Beta_Quantile (0.5, P);
      Q00 : constant Real := Beta_Quantile (0.0, P);
      Q10 : constant Real := Beta_Quantile (1.0, P);
   begin
      Check (Approx (Pdf, 1.5, 1.0E-9), "Beta(2,2) PDF(0.5)=1.5");
      Check (Approx (Beta_PDF (0.0, P), 0.0), "PDF(0)=0 for α>1");
      Check (Approx (Beta_PDF (1.0, P), 0.0), "PDF(1)=0 for β>1");
      Check (Approx (Cdf, 0.5, 1.0E-6), "Beta(2,2) CDF(0.5)=0.5");
      Check (Approx
        (Regularized_Incomplete_Beta (0.0, 3.0, 5.0), 0.0),
             "I_0=0");
      Check (Approx
        (Regularized_Incomplete_Beta (1.0, 3.0, 5.0), 1.0),
             "I_1=1");
      Check (Approx (Q50, 0.5, 1.0E-5), "median of Beta(2,2)=0.5");
      Check (Approx (Q00, 0.0), "quantile 0 = 0");
      Check (Approx (Q10, 1.0), "quantile 1 = 1");
      Check (Beta_Log_PDF (0.5, P) < Safe_Log (Pdf) + 1.0E-6
               and then Beta_Log_PDF (0.5, P) > Safe_Log (Pdf) - 1.0E-6,
             "Log_PDF matches PDF");
      --  Uniform Beta(1,1): CDF(x)=x
      Check (Approx
        (Regularized_Incomplete_Beta (0.3, 1.0, 1.0), 0.3, 1.0E-6),
             "Beta(1,1) CDF(0.3)=0.3");
      Check (Approx
        (Regularized_Incomplete_Beta (0.7, 1.0, 1.0), 0.7, 1.0E-6),
             "Beta(1,1) CDF(0.7)=0.7");
      Check (Approx (Beta_Quantile (0.25, (1.0, 1.0)), 0.25, 1.0E-5),
             "Beta(1,1) quantile 0.25");
   end;

   ---------------------------------------------------------------------
   Section ("6. Equal-tailed credible intervals");
   ---------------------------------------------------------------------
   declare
      --  Synthetic: true p=0.4; observe Binomial with mean near 0.4
      True_P : constant Unit_Interval := 0.4;
      Prior  : constant Beta_Params := (1.0, 1.0);
      Post   : constant Beta_Params :=
        Beta_Update (Prior, Successes => 40, Trials => 100);
      CI95   : constant Credible_Interval :=
        Equal_Tailed_Credible_Interval (Post, 0.95);
      CI50   : constant Credible_Interval :=
        Equal_Tailed_Credible_Interval (Post, 0.50);
      Mean   : constant Unit_Interval := Beta_Mean (Post);
   begin
      Check (Approx (Mean, 41.0 / 102.0, 1.0E-12),
             "posterior mean after 40/100");
      Check (CI95.Lower < CI95.Upper, "95% CI ordered");
      Check (Contains (CI95, Mean), "95% CI contains posterior mean");
      Check (Contains (CI95, True_P),
             "95% CI contains true p=0.4 (synthetic)");
      Check (Approx (CI95.Level, 0.95), "CI level recorded");
      Check (CI50.Upper - CI50.Lower < CI95.Upper - CI95.Lower,
             "50% CI narrower than 95%");
      Check (Contains (CI50, Mean), "50% CI contains mean");
      Check (not Contains (CI50, 0.0), "50% CI excludes 0");
      Check (not Contains (CI50, 1.0), "50% CI excludes 1");
      --  Strong data around 0.9
      declare
         High : constant Beta_Params :=
           Beta_Update ((1.0, 1.0), 90, 100);
         CI   : constant Credible_Interval :=
           Equal_Tailed_Credible_Interval (High, 0.95);
      begin
         Check (CI.Lower > 0.8, "high-success CI lower > 0.8");
         Check (Contains (CI, Beta_Mean (High)),
                "high-success CI contains mean");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Normal conjugate (known variance)");
   ---------------------------------------------------------------------
   declare
      Prior : constant Normal_Params := (Mu => 0.0, Sigma2 => 1.0);
      --  Data mean 2.0, n=4, obs variance 1 → strong pull toward data
      Post  : constant Normal_Params :=
        Normal_Conjugate_Update
          (Prior, Sample_Mean => 2.0, N => 4, Obs_Variance => 1.0);
      --  Prec0=1, Prec_data=4, Prec_post=5, Var=0.2
      --  Mu = 0.2 * (0 + 4*2) = 1.6
      Weak  : constant Normal_Params :=
        Normal_Conjugate_Update
          (Prior, Sample_Mean => 2.0, N => 1, Obs_Variance => 100.0);
      Pdf0  : constant Real := Normal_PDF (0.0, Prior);
   begin
      Check (Approx (Post.Mu, 1.6, 1.0E-12), "posterior mean 1.6");
      Check (Approx (Post.Sigma2, 0.2, 1.0E-12), "posterior var 0.2");
      Check (Post.Mu > Prior.Mu, "mean moves toward data");
      Check (Post.Mu < 2.0, "mean shrinks toward prior (below x̄)");
      Check (Post.Sigma2 < Prior.Sigma2, "posterior tighter");
      Check (Weak.Mu < Post.Mu,
             "weaker data → less movement from prior");
      Check (Weak.Mu > Prior.Mu, "even weak data moves a little");
      Check (Approx (Pdf0, 0.398942280401, 1.0E-6),
             "N(0,1) PDF(0)=1/sqrt(2π)");
      Check (Normal_PDF (1.0, Prior) < Pdf0, "PDF falls away from mean");
      Check (Normal_PDF (Post.Mu, Post) >
               Normal_PDF (Prior.Mu, Post),
             "posterior density higher at post mean than prior mean");
   end;

   ---------------------------------------------------------------------
   Section ("8. Discrete evidence / Bayes factors");
   ---------------------------------------------------------------------
   declare
      L : constant Real_Array (1 .. 2) := [0.8, 0.2];
      P : constant Real_Array (1 .. 2) := [0.5, 0.5];
      Z : constant Real := Discrete_Evidence (L, P);
      BF : constant Real := Bayes_Factor (0.8, 0.2);
      Odds : constant Real := Posterior_Odds (1.0, BF);
      L3 : constant Real_Array (1 .. 3) := [0.1, 0.5, 0.9];
      P3 : constant Real_Array (1 .. 3) := [0.2, 0.3, 0.5];
      Z3 : constant Real := Discrete_Evidence (L3, P3);
   begin
      Check (Approx (Z, 0.5, 1.0E-12), "evidence 0.8*0.5+0.2*0.5=0.5");
      Check (Approx (BF, 4.0), "BF_12 = 0.8/0.2 = 4");
      Check (BF > 1.0, "BF>1 when data favor H1");
      Check (Approx (Odds, 4.0), "posterior odds = prior odds × BF");
      Check (Approx (Z3, 0.1 * 0.2 + 0.5 * 0.3 + 0.9 * 0.5, 1.0E-12),
             "three-hypothesis evidence");
      Check (Bayes_Factor (0.2, 0.8) < 1.0,
             "BF<1 when data favor H2");
      Check (Approx (Bayes_Factor (0.5, 0.5), 1.0), "BF=1 equal lik");
      Check (Approx
        (Posterior_Odds (2.0, 3.0), 6.0), "odds multiply");
   end;

   ---------------------------------------------------------------------
   Section ("9. More evidence / capacity / mismatch exceptions");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      L : constant Real_Array (1 .. 2) := [1.0, 1.0];
      P : constant Real_Array (2 .. 3) := [0.5, 0.5];
   begin
      Raised := False;
      begin
         declare
            Dummy : Non_Negative;
         begin
            Dummy := Discrete_Evidence (L, P);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Discrete_Evidence rejects mismatched bounds");

      Raised := False;
      begin
         declare
            Empty_L : Real_Array (1 .. 0);
            Empty_P : Real_Array (1 .. 0);
            Dummy   : Non_Negative;
         begin
            Dummy := Discrete_Evidence (Empty_L, Empty_P);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Discrete_Evidence rejects empty");

      Raised := False;
      begin
         declare
            Bad_L : constant Real_Array (1 .. 2) := [1.0, -0.1];
            Good_P : constant Real_Array (1 .. 2) := [0.5, 0.5];
            Dummy : Non_Negative;
         begin
            Dummy := Discrete_Evidence (Bad_L, Good_P);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument => Raised := True;
      end;
      Check (Raised, "Discrete_Evidence rejects negative lik");

      Raised := False;
      begin
         declare
            Dummy : Credible_Interval;
         begin
            Dummy := Equal_Tailed_Credible_Interval ((2.0, 2.0), 1.0);
            pragma Unreferenced (Dummy);
         end;
      exception
         when Invalid_Argument => Raised := True;
         when Constraint_Error => Raised := True;
      end;
      Check (Raised, "CI rejects Level=1");
   end;

   ---------------------------------------------------------------------
   Section ("10. Additional conjugate / theorem sanity");
   ---------------------------------------------------------------------
   declare
      --  Jeffreys prior Beta(0.5,0.5) update
      Jeff : constant Beta_Params := (0.5, 0.5);
      Post : constant Beta_Params := Beta_Update (Jeff, 5, 10);
      CI   : constant Credible_Interval :=
        Equal_Tailed_Credible_Interval (Post, 0.9);
      --  Perfect test
      Sure : constant Unit_Interval :=
        Posterior_Prob_Complement (0.01, 1.0, 0.0);
   begin
      Check (Approx (Post.Alpha, 5.5), "Jeffreys alpha update");
      Check (Approx (Post.Beta, 5.5), "Jeffreys beta update");
      Check (Approx (Beta_Mean (Post), 0.5), "symmetric Jeffreys post");
      Check (Contains (CI, 0.5), "0.9 CI contains 0.5");
      Check (Approx (Sure, 1.0), "zero FPR + positive → posterior 1");
      Check (Approx
        (Posterior_Prob (0.25, 0.4, 0.2), 0.5, 1.0E-12),
             "direct form 0.4*0.25/0.2=0.5");
      Check (Evidence_From_Complement (0.2, 0.9, 0.1) >
               Evidence_From_Complement (0.2, 0.5, 0.1),
             "higher sensitivity raises P(B)");
      --  Large α,β: mean ≈ mode
      declare
         Big : constant Beta_Params := (50.0, 50.0);
      begin
         Check (Near (Beta_Mean (Big), Beta_Mode (Big), 1.0E-3),
                "large equal Beta mean≈mode");
         Check (Approx (Beta_Mean (Big), 0.5), "Beta(50,50) mean 0.5");
      end;
      Check (Approx
        (Normal_Conjugate_Update
           ((5.0, 4.0), 5.0, 10, 1.0).Mu, 5.0, 1.0E-12),
             "data mean=prior mean → unchanged mu");
   end;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("==============================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL TESTS PASSED");
   else
      Put_Line ("SOME TESTS FAILED");
   end if;

   pragma Assert (Fail_Count = 0);
end Tests;
