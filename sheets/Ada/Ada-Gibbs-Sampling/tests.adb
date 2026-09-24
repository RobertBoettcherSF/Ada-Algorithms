--  Standalone test suite for Gibbs_Sampling (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Gibbs_Sampling; use Gibbs_Sampling;

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

   function Approx (A, B : Real; Tol : Real) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   Cfg_Rho05 : constant Config :=
     (Steps        => 30_000,
      Burn_In      => 5_000,
      Seed         => 42,
      Rho          => 0.5,
      Start_X      => 0.0,
      Start_Y      => 0.0,
      Keep_Samples => False);

   Cfg_Rho08 : constant Config :=
     (Steps        => 40_000,
      Burn_In      => 5_000,
      Seed         => 7,
      Rho          => 0.8,
      Start_X      => 0.0,
      Start_Y      => 0.0,
      Keep_Samples => False);

   Cfg_Rho_Neg : constant Config :=
     (Steps        => 30_000,
      Burn_In      => 5_000,
      Seed         => 99,
      Rho          => -0.6,
      Start_X      => 0.0,
      Start_Y      => 0.0,
      Keep_Samples => False);

   Cfg_Keep : constant Config :=
     (Steps        => 2_500,
      Burn_In      => 500,
      Seed         => 1,
      Rho          => 0.3,
      Start_X      => 0.0,
      Start_Y      => 0.0,
      Keep_Samples => True);

   Cfg_Far : constant Config :=
     (Steps        => 25_000,
      Burn_In      => 8_000,
      Seed         => 11,
      Rho          => 0.4,
      Start_X      => 5.0,
      Start_Y      => -5.0,
      Keep_Samples => False);

   Cfg_Small : constant Config :=
     (Steps        => 1_200,
      Burn_In      => 200,
      Seed         => 3,
      Rho          => 0.2,
      Start_X      => 0.0,
      Start_Y      => 0.0,
      Keep_Samples => False);

   Cfg_Zero : constant Config :=
     (Steps        => 20_000,
      Burn_In      => 2_000,
      Seed         => 55,
      Rho          => 0.0,
      Start_X      => 0.0,
      Start_Y      => 0.0,
      Keep_Samples => False);

   BB_Std : constant Beta_Bernoulli_Config :=
     (Steps     => 20_000,
      Burn_In   => 2_000,
      Seed      => 42,
      Alpha     => 2.0,
      Beta_P    => 2.0,
      Successes => 7,
      Trials    => 10);

   BB_Flat : constant Beta_Bernoulli_Config :=
     (Steps     => 15_000,
      Burn_In   => 1_000,
      Seed      => 8,
      Alpha     => 1.0,
      Beta_P    => 1.0,
      Successes => 3,
      Trials    => 10);

begin
   Put_Line ("Gibbs_Sampling test suite (MCMC / heat-bath / bivariate Normal)");
   Put_Line ("===============================================================");

   ---------------------------------------------------------------------
   Section ("1. Conditional Normal helpers");

   declare
      Rho : constant Real := 0.5;
   begin
      Check (Approx (Conditional_Mean (Rho, 2.0), 1.0, 1.0E-12),
             "E[X|Y=2]=ρ·2 = 1.0 for ρ=0.5");
      Check (Approx (Conditional_Mean (Rho, -4.0), -2.0, 1.0E-12),
             "E[Y|X=-4]=ρ·(-4)=-2");
      Check (Approx (Conditional_Mean (0.0, 3.0), 0.0, 1.0E-12),
             "ρ=0 ⇒ conditional mean 0");
      Check (Approx (Conditional_Variance (Rho), 0.75, 1.0E-12),
             "Var=1−ρ²=0.75 for ρ=0.5");
      Check (Approx (Conditional_Variance (0.0), 1.0, 1.0E-12),
             "Var=1 for ρ=0");
      Check (Approx (Conditional_Variance (0.8), 0.36, 1.0E-12),
             "Var=1−0.64=0.36 for ρ=0.8");
      Check (Approx (Conditional_Std_Dev (Rho), 0.8660254037844386, 1.0E-6),
             "σ=√(1−ρ²) for ρ=0.5");
      Check (Approx (Conditional_Std_Dev (0.0), 1.0, 1.0E-12),
             "σ=1 for ρ=0");
      Check (Valid_Correlation (0.5), "Valid_Correlation(0.5)");
      Check (Valid_Correlation (-0.9), "Valid_Correlation(-0.9)");
      Check (Valid_Correlation (0.0), "Valid_Correlation(0)");
      Check (not Valid_Correlation (1.0), "not Valid_Correlation(1)");
      Check (not Valid_Correlation (-1.0), "not Valid_Correlation(-1)");
      Check (not Valid_Correlation (1.0 - Epsilon_Tol / 2.0),
             "reject |ρ| too close to 1");
      Check (Approx (Conditional_Variance (1.0), 0.0, 1.0E-15),
             "Var clamped to 0 at |ρ|=1");
      Check (Approx (Conditional_Mean (-0.6, 1.0), -0.6, 1.0E-12),
             "negative ρ conditional mean");
   end;

   ---------------------------------------------------------------------
   Section ("2. Config defaults / Pre conditions");

   declare
      Def : Config;
   begin
      Check (Def.Steps = 10_000, "default Steps=10000");
      Check (Def.Burn_In = 1_000, "default Burn_In=1000");
      Check (Def.Seed = 42, "default Seed=42");
      Check (Approx (Def.Rho, 0.5, 1.0E-15), "default Rho=0.5");
      Check (Approx (Def.Start_X, 0.0, 1.0E-15), "default Start_X=0");
      Check (Approx (Def.Start_Y, 0.0, 1.0E-15), "default Start_Y=0");
      Check (Def.Keep_Samples = False, "default Keep_Samples=False");
      Check (Cfg_Rho05.Burn_In < Cfg_Rho05.Steps, "Burn_In < Steps (rho05)");
      Check (Valid_Correlation (Cfg_Rho05.Rho), "rho05 valid");
      Check (Valid_Correlation (Cfg_Rho08.Rho), "rho08 valid");
      Check (Valid_Correlation (Cfg_Rho_Neg.Rho), "rho_neg valid");
   end;

   ---------------------------------------------------------------------
   Section ("3. Bivariate Normal ρ=0.5 — means & correlation");

   declare
      R : constant Result := Sample_Bivariate_Normal (Cfg_Rho05);
   begin
      Check (R.N_Kept = Cfg_Rho05.Steps - Cfg_Rho05.Burn_In,
             "N_Kept = Steps−Burn_In (ρ=0.5)");
      Check (Approx (R.Mean_X, 0.0, 0.08), "Mean_X ≈ 0 (ρ=0.5)");
      Check (Approx (R.Mean_Y, 0.0, 0.08), "Mean_Y ≈ 0 (ρ=0.5)");
      Check (Approx (R.Var_X, 1.0, 0.15), "Var_X ≈ 1 (ρ=0.5)");
      Check (Approx (R.Var_Y, 1.0, 0.15), "Var_Y ≈ 1 (ρ=0.5)");
      Check (Approx (R.Cov_XY, 0.5, 0.12), "Cov_XY ≈ ρ=0.5");
      Check (Approx (R.Correlation, 0.5, 0.12), "sample corr ≈ 0.5");
      Check (R.Stored = 0, "Stored=0 when Keep_Samples=False");
   end;

   ---------------------------------------------------------------------
   Section ("4. Bivariate Normal ρ=0.8");

   declare
      R : constant Result := Sample_Bivariate_Normal (Cfg_Rho08);
   begin
      Check (Approx (R.Mean_X, 0.0, 0.1), "Mean_X ≈ 0 (ρ=0.8)");
      Check (Approx (R.Mean_Y, 0.0, 0.1), "Mean_Y ≈ 0 (ρ=0.8)");
      Check (Approx (R.Correlation, 0.8, 0.12), "sample corr ≈ 0.8");
      Check (Approx (R.Cov_XY, 0.8, 0.15), "Cov_XY ≈ 0.8");
      Check (Approx (R.Var_X, 1.0, 0.2), "Var_X ≈ 1 (ρ=0.8)");
      Check (Approx (R.Var_Y, 1.0, 0.2), "Var_Y ≈ 1 (ρ=0.8)");
      Check (R.N_Kept > 30_000, "N_Kept large for ρ=0.8 run");
   end;

   ---------------------------------------------------------------------
   Section ("5. Negative correlation ρ=-0.6");

   declare
      R : constant Result := Sample_Bivariate_Normal (Cfg_Rho_Neg);
   begin
      Check (Approx (R.Mean_X, 0.0, 0.1), "Mean_X ≈ 0 (ρ=-0.6)");
      Check (Approx (R.Mean_Y, 0.0, 0.1), "Mean_Y ≈ 0 (ρ=-0.6)");
      Check (Approx (R.Correlation, -0.6, 0.12), "sample corr ≈ -0.6");
      Check (R.Cov_XY < 0.0, "Cov_XY negative for ρ=-0.6");
      Check (Approx (R.Var_X, 1.0, 0.2), "Var_X ≈ 1 (ρ=-0.6)");
   end;

   ---------------------------------------------------------------------
   Section ("6. Independent case ρ=0");

   declare
      R : constant Result := Sample_Bivariate_Normal (Cfg_Zero);
   begin
      Check (Approx (R.Mean_X, 0.0, 0.08), "Mean_X ≈ 0 (ρ=0)");
      Check (Approx (R.Mean_Y, 0.0, 0.08), "Mean_Y ≈ 0 (ρ=0)");
      Check (Approx (R.Correlation, 0.0, 0.08), "sample corr ≈ 0");
      Check (Approx (R.Cov_XY, 0.0, 0.08), "Cov_XY ≈ 0");
      Check (Approx (R.Var_X, 1.0, 0.15), "Var_X ≈ 1 (ρ=0)");
      Check (Approx (R.Var_Y, 1.0, 0.15), "Var_Y ≈ 1 (ρ=0)");
   end;

   ---------------------------------------------------------------------
   Section ("7. Run rename / Keep_Samples / far start");

   declare
      R_Run  : constant Result := Run (Cfg_Small);
      R_Keep : constant Result := Sample_Bivariate_Normal (Cfg_Keep);
      R_Far  : constant Result := Sample_Bivariate_Normal (Cfg_Far);
   begin
      Check (R_Run.N_Kept = Cfg_Small.Steps - Cfg_Small.Burn_In,
             "Run N_Kept correct");
      Check (Approx (R_Run.Mean_X, 0.0, 0.25), "Run Mean_X loose ≈0");
      Check (Approx (R_Run.Correlation, 0.2, 0.25), "Run corr loose ≈0.2");
      Check (R_Keep.Stored = Cfg_Keep.Steps - Cfg_Keep.Burn_In,
             "Keep_Samples stores all kept");
      Check (R_Keep.Stored > 0, "Stored > 0");
      Check (abs (R_Keep.Samples_X (1)) < 20.0, "stored X finite");
      Check (abs (R_Keep.Samples_Y (R_Keep.Stored)) < 20.0,
             "stored Y finite");
      Check (Approx (R_Far.Mean_X, 0.0, 0.12),
             "far Start still recovers Mean_X≈0");
      Check (Approx (R_Far.Mean_Y, 0.0, 0.12),
             "far Start still recovers Mean_Y≈0");
      Check (Approx (R_Far.Correlation, 0.4, 0.15),
             "far Start recovers corr≈0.4");
   end;

   ---------------------------------------------------------------------
   Section ("8. Seed reproducibility");

   declare
      C1 : constant Config := Cfg_Small;
      C2 : constant Config := Cfg_Small;
      C3 : Config := Cfg_Small;
      R1, R2, R3 : Result;
   begin
      R1 := Sample_Bivariate_Normal (C1);
      R2 := Sample_Bivariate_Normal (C2);
      C3.Seed := Cfg_Small.Seed + 1;
      R3 := Sample_Bivariate_Normal (C3);
      Check (Approx (R1.Mean_X, R2.Mean_X, 1.0E-14),
             "same seed ⇒ identical Mean_X");
      Check (Approx (R1.Mean_Y, R2.Mean_Y, 1.0E-14),
             "same seed ⇒ identical Mean_Y");
      Check (Approx (R1.Correlation, R2.Correlation, 1.0E-14),
             "same seed ⇒ identical Correlation");
      Check (Approx (R1.Cov_XY, R2.Cov_XY, 1.0E-14),
             "same seed ⇒ identical Cov_XY");
      Check (R1.N_Kept = R2.N_Kept, "same seed ⇒ same N_Kept");
      Check (not Approx (R1.Mean_X, R3.Mean_X, 1.0E-14)
                or else not Approx (R1.Correlation, R3.Correlation, 1.0E-14),
             "different seed usually changes result");
   end;

   ---------------------------------------------------------------------
   Section ("9. Beta–Bernoulli conjugate helpers");

   declare
      A : constant Positive_Real := 2.0;
      B : constant Positive_Real := 2.0;
      S : constant Natural := 7;
      N : constant Positive := 10;
      PM : constant Unit_Fraction := Posterior_Mean (A, B, S, N);
   begin
      Check (Approx (Real (Posterior_Alpha (A, S)), 9.0, 1.0E-12),
             "posterior α' = 2+7 = 9");
      Check (Approx (Real (Posterior_Beta (B, S, N)), 5.0, 1.0E-12),
             "posterior β' = 2+3 = 5");
      Check (Approx (Real (PM), 9.0 / 14.0, 1.0E-12),
             "posterior mean = 9/14");
      Check (Approx (Real (Posterior_Mean (1.0, 1.0, 0, 5)), 1.0 / 7.0,
                     1.0E-12),
             "flat prior 0/5 ⇒ mean 1/7");
      Check (Approx (Real (Posterior_Mean (1.0, 1.0, 5, 5)), 6.0 / 7.0,
                     1.0E-12),
             "flat prior 5/5 ⇒ mean 6/7");
      Check (Approx (Real (Posterior_Alpha (1.0, 0)), 1.0, 1.0E-12),
             "Alpha+0 unchanged");
      Check (Approx (Real (Posterior_Beta (3.0, 2, 2)), 3.0, 1.0E-12),
             "all successes ⇒ β' = Beta_P");
   end;

   ---------------------------------------------------------------------
   Section ("10. Sample_Beta_Bernoulli recovers posterior mean");

   declare
      R  : constant Beta_Bernoulli_Result := Sample_Beta_Bernoulli (BB_Std);
      PM : constant Real :=
        Real (Posterior_Mean
                (BB_Std.Alpha, BB_Std.Beta_P,
                 BB_Std.Successes, BB_Std.Trials));
      --  Exact Beta(9,5) variance = αβ/((α+β)²(α+β+1))
      Exact_Var : constant Real :=
        (9.0 * 5.0) / ((14.0 * 14.0) * 15.0);
      R2 : constant Beta_Bernoulli_Result := Sample_Beta_Bernoulli (BB_Flat);
      PM2 : constant Real :=
        Real (Posterior_Mean
                (BB_Flat.Alpha, BB_Flat.Beta_P,
                 BB_Flat.Successes, BB_Flat.Trials));
      Def_BB : Beta_Bernoulli_Config;
   begin
      Check (R.N_Kept = BB_Std.Steps - BB_Std.Burn_In,
             "BB N_Kept = Steps−Burn_In");
      Check (Approx (R.Mean_P, PM, 0.02), "BB Mean_P ≈ 9/14");
      Check (Approx (R.Var_P, Exact_Var, 0.01), "BB Var_P ≈ Beta var");
      Check (R.Mean_P > 0.0 and then R.Mean_P < 1.0, "BB mean in (0,1)");
      Check (R.Var_P > 0.0, "BB variance positive");
      Check (Approx (R2.Mean_P, PM2, 0.03), "flat BB Mean_P ≈ 4/12");
      Check (Def_BB.Steps = 10_000, "default BB Steps");
      Check (Def_BB.Burn_In = 1_000, "default BB Burn_In");
      Check (Def_BB.Seed = 42, "default BB Seed");
      Check (Approx (Def_BB.Alpha, 2.0, 1.0E-15), "default BB Alpha");
      Check (Approx (Def_BB.Beta_P, 2.0, 1.0E-15), "default BB Beta_P");
      Check (Def_BB.Successes = 7, "default BB Successes");
      Check (Def_BB.Trials = 10, "default BB Trials");
   end;

   ---------------------------------------------------------------------
   Section ("11. Beta–Bernoulli seed + edge counts");

   declare
      C_A : constant Beta_Bernoulli_Config := BB_Flat;
      C_B : constant Beta_Bernoulli_Config := BB_Flat;
      C_C : Beta_Bernoulli_Config := BB_Flat;
      RA, RB, RC : Beta_Bernoulli_Result;
      C_All : constant Beta_Bernoulli_Config :=
        (Steps     => 12_000,
         Burn_In   => 1_000,
         Seed      => 21,
         Alpha     => 2.0,
         Beta_P    => 2.0,
         Successes => 10,
         Trials    => 10);
      C_None : constant Beta_Bernoulli_Config :=
        (Steps     => 12_000,
         Burn_In   => 1_000,
         Seed      => 22,
         Alpha     => 2.0,
         Beta_P    => 2.0,
         Successes => 0,
         Trials    => 10);
      R_All  : Beta_Bernoulli_Result;
      R_None : Beta_Bernoulli_Result;
   begin
      RA := Sample_Beta_Bernoulli (C_A);
      RB := Sample_Beta_Bernoulli (C_B);
      C_C.Seed := BB_Flat.Seed + 99;
      RC := Sample_Beta_Bernoulli (C_C);
      Check (Approx (RA.Mean_P, RB.Mean_P, 1.0E-14),
             "BB same seed ⇒ identical Mean_P");
      Check (Approx (RA.Var_P, RB.Var_P, 1.0E-14),
             "BB same seed ⇒ identical Var_P");
      Check (not Approx (RA.Mean_P, RC.Mean_P, 1.0E-14),
             "BB different seed changes Mean_P");
      R_All := Sample_Beta_Bernoulli (C_All);
      R_None := Sample_Beta_Bernoulli (C_None);
      Check (R_All.Mean_P > 0.7, "all successes ⇒ high Mean_P");
      Check (R_None.Mean_P < 0.3, "zero successes ⇒ low Mean_P");
      Check (Approx (R_All.Mean_P,
                     Real (Posterior_Mean (2.0, 2.0, 10, 10)), 0.03),
             "all-success Mean_P ≈ 12/14");
      Check (Approx (R_None.Mean_P,
                     Real (Posterior_Mean (2.0, 2.0, 0, 10)), 0.03),
             "zero-success Mean_P ≈ 2/14");
   end;

   ---------------------------------------------------------------------
   Section ("12. Result / type smoke + Epsilon_Tol");

   declare
      R : Result;
      B : Beta_Bernoulli_Result;
      Rho_A : constant Real := 0.9;
      Nested : constant Real :=
        Conditional_Mean (Rho_A, Conditional_Mean (Rho_A, 1.0));
      Tol : constant Real := Epsilon_Tol;
   begin
      Check (R.N_Kept = 0, "default Result N_Kept=0");
      Check (R.Stored = 0, "default Result Stored=0");
      Check (B.N_Kept = 0, "default BB Result N_Kept=0");
      Check (abs (R.Mean_X) <= Tol, "default Result Mean_X near 0");
      Check (abs (R.Mean_Y) <= Tol, "default Result Mean_Y near 0");
      Check (abs (R.Var_X) <= Tol, "default Result Var_X near 0");
      Check (abs (R.Correlation) <= Tol, "default Result Corr near 0");
      Check (abs (B.Mean_P) <= Tol, "default BB Result Mean_P near 0");
      Check (Approx (Nested, Rho_A * Rho_A, 1.0E-12),
             "compose conditional means ρ²");
      Check (Approx (Conditional_Variance (0.5),
                     Conditional_Std_Dev (0.5) ** 2, 1.0E-5),
             "Var = σ² for ρ=0.5");
      Check (R.Samples_X'Length = Max_Store
               and then R.Samples_Y'Length = Max_Store,
             "Result sample arrays length = Max_Store");
   end;

   New_Line;
   Put_Line ("===============================================================");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;
end Tests;
