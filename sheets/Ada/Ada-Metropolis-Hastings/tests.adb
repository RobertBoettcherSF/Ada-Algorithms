--  Standalone test suite for Metropolis_Hastings (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Metropolis_Hastings; use Metropolis_Hastings;

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

   function In_01 (X : Real) return Boolean is
   begin
      return X >= 0.0 and then X <= 1.0;
   end In_01;

   Cfg_Std : constant Config :=
     (Steps          => 25_000,
      Burn_In        => 5_000,
      Proposal_Sigma => 1.0,
      Seed           => 42,
      Start          => 0.0,
      Keep_Samples   => False);

   Cfg_Mu2 : constant Config :=
     (Steps          => 30_000,
      Burn_In        => 5_000,
      Proposal_Sigma => 1.2,
      Seed           => 7,
      Start          => 0.0,
      Keep_Samples   => False);

   Cfg_Wide : constant Config :=
     (Steps          => 40_000,
      Burn_In        => 8_000,
      Proposal_Sigma => 2.5,
      Seed           => 99,
      Start          => 0.0,
      Keep_Samples   => False);

   Cfg_Keep : constant Config :=
     (Steps          => 2_000,
      Burn_In        => 200,
      Proposal_Sigma => 1.0,
      Seed           => 1,
      Start          => 0.0,
      Keep_Samples   => True);

   Cfg_Ind : constant Config :=
     (Steps          => 30_000,
      Burn_In        => 3_000,
      Proposal_Sigma => 1.0,  -- must match Proposal_Std_Normal
      Seed           => 123,
      Start          => 0.0,
      Keep_Samples   => False);

   Cfg_Bern : constant Config :=
     (Steps          => 20_000,
      Burn_In        => 2_000,
      Proposal_Sigma => 1.0,
      Seed           => 11,
      Start          => 0.0,
      Keep_Samples   => False);

   Cfg_Small : constant Config :=
     (Steps          => 800,
      Burn_In        => 100,
      Proposal_Sigma => 0.8,
      Seed           => 3,
      Start          => 1.0,
      Keep_Samples   => False);

   Cfg_Tight : constant Config :=
     (Steps          => 15_000,
      Burn_In        => 2_000,
      Proposal_Sigma => 0.5,
      Seed           => 55,
      Start          => 0.0,
      Keep_Samples   => False);

   Cfg_Wide_Prop : constant Config :=
     (Steps          => 15_000,
      Burn_In        => 2_000,
      Proposal_Sigma => 3.0,
      Seed           => 56,
      Start          => 0.0,
      Keep_Samples   => False);

begin
   Put_Line ("Metropolis_Hastings test suite (MCMC / random-walk Metropolis)");
   Put_Line ("==============================================================");

   ---------------------------------------------------------------------
   Section ("1. Accept_Probability / Log_Hastings_Ratio");
   ---------------------------------------------------------------------
   declare
      A0  : constant Unit_Fraction := Accept_Probability (0.0);
      Ap  : constant Unit_Fraction := Accept_Probability (5.0);
      An  : constant Unit_Fraction := Accept_Probability (-0.69314718056);
      --  exp(-ln 2) ≈ 0.5
      Lr0 : constant Real := Log_Hastings_Ratio (0.0, 0.0, 0.0);
      Lr1 : constant Real := Log_Hastings_Ratio (1.0, 3.0, 0.0);
      Lr2 : constant Real := Log_Hastings_Ratio (0.0, 1.0, -0.5);
   begin
      Check (Approx (Real (A0), 1.0, 1.0E-12), "Accept_Probability(0)=1");
      Check (Approx (Real (Ap), 1.0, 1.0E-12), "Accept_Probability(+large)=1");
      Check (Approx (Real (An), 0.5, 1.0E-5), "Accept_Probability(-ln2)≈0.5");
      Check (In_01 (Real (An)), "negative log-alpha accept in [0,1]");
      Check (Approx (Lr0, 0.0, 1.0E-15), "Hastings ratio log 1 = 0");
      Check (Approx (Lr1, 2.0, 1.0E-15), "log π'-log π = 2");
      Check (Approx (Lr2, 0.5, 1.0E-15), "Hastings with q-ratio term");
      Check (Accept_Probability (-1000.0) < 1.0E-10,
             "very negative log-alpha ≈ 0");
      Check (Accept_Probability (0.0) = 1.0, "zero log-alpha is exactly 1");
   end;

   ---------------------------------------------------------------------
   Section ("2. Log density helpers");
   ---------------------------------------------------------------------
   declare
      L0 : constant Real := Log_Std_Normal (0.0);
      L1 : constant Real := Log_Std_Normal (1.0);
      L2 : constant Real := Log_Normal (2.0, 2.0, 1.0);
      Lf : constant Real := Log_Normal_Full (0.0, 0.0, 1.0);
      T0 : constant Real := Target_Std_Normal (0.0);
      T2 : constant Real := Target_Normal_Mu2 (2.0);
      Tw : constant Real := Target_Normal_Wide (0.0);
      Tb : constant Real := Target_Bimodal (0.0);
      Tb2 : constant Real := Target_Bimodal (2.0);
   begin
      Check (Approx (L0, 0.0, 1.0E-15), "log N(0) unnorm at 0 is 0");
      Check (Approx (L1, -0.5, 1.0E-12), "log N(0) unnorm at 1 is -1/2");
      Check (Approx (L2, 0.0, 1.0E-15), "log N(2,1) unnorm at 2 is 0");
      Check (Lf < 0.0, "full log N(0,1) at 0 is negative");
      Check (Approx (T0, L0, 1.0E-15), "Target_Std_Normal matches helper");
      Check (Approx (T2, 0.0, 1.0E-15), "Target_Normal_Mu2 peak at 2");
      Check (Approx (Tw, 0.0, 1.0E-15), "Target_Normal_Wide peak at 0");
      Check (Tb2 > Tb, "bimodal denser at mode ±2 than at 0");
      Check (Approx (Proposal_Std_Normal (0.0), Lf, 1.0E-10),
             "Proposal_Std_Normal = Log_Normal_Full(0,1)");
      Check (Log_Normal (0.0, 0.0, 2.0) >
             Log_Normal (10.0, 0.0, 2.0),
             "wide normal prefers center over far tail");
   end;

   ---------------------------------------------------------------------
   Section ("3. Sample_1D / Run — standard normal target");
   ---------------------------------------------------------------------
   declare
      R  : constant Result := Sample_1D (Target_Std_Normal'Access, Cfg_Std);
      R2 : constant Result := Run (Target_Std_Normal'Access, Cfg_Std);
   begin
      Check (R.N_Proposed = Cfg_Std.Steps, "proposed = Steps");
      Check (R.N_Kept = Cfg_Std.Steps - Cfg_Std.Burn_In, "kept = Steps-Burn");
      Check (R.N_Accepted <= R.N_Proposed, "accepted ≤ proposed");
      Check (In_01 (Real (R.Accept_Rate)), "accept rate in [0,1]");
      Check (R.Accept_Rate > 0.0, "accept rate > 0 for σ=1 Gaussian");
      Check (R.Accept_Rate < 1.0, "accept rate < 1 (some rejects)");
      Check (Approx (R.Mean, 0.0, 0.15), "N(0,1) mean ≈ 0 (loose)");
      Check (Approx (R.Variance, 1.0, 0.25), "N(0,1) var ≈ 1 (loose)");
      Check (R.Variance > 0.0, "variance positive");
      Check (Approx (R2.Mean, R.Mean, 1.0E-12), "Run renames Sample_1D");
      Check (Approx (Real (R2.Accept_Rate), Real (R.Accept_Rate), 1.0E-12),
             "Run same accept rate");
      Check (R.Stored = 0, "Keep_Samples=False ⇒ Stored=0");
   end;

   ---------------------------------------------------------------------
   Section ("4. Sample_1D — shifted / scaled Gaussians");
   ---------------------------------------------------------------------
   declare
      Rmu : constant Result :=
        Sample_1D (Target_Normal_Mu2'Access, Cfg_Mu2);
      Rw  : constant Result :=
        Sample_1D (Target_Normal_Wide'Access, Cfg_Wide);
   begin
      Check (Approx (Rmu.Mean, 2.0, 0.2), "N(2,1) mean ≈ 2");
      Check (Approx (Rmu.Variance, 1.0, 0.3), "N(2,1) var ≈ 1");
      Check (In_01 (Real (Rmu.Accept_Rate)), "mu2 accept in [0,1]");
      Check (Approx (Rw.Mean, 0.0, 0.25), "N(0,2) mean ≈ 0");
      Check (Approx (Rw.Variance, 4.0, 0.8), "N(0,2) var ≈ 4");
      Check (In_01 (Real (Rw.Accept_Rate)), "wide accept in [0,1]");
      Check (Rmu.N_Kept > 0, "mu2 kept samples > 0");
      Check (Rw.N_Kept > 0, "wide kept samples > 0");
   end;

   ---------------------------------------------------------------------
   Section ("5. Proposal scale vs acceptance rate");
   ---------------------------------------------------------------------
   declare
      Rt : constant Result :=
        Sample_1D (Target_Std_Normal'Access, Cfg_Tight);
      Rw : constant Result :=
        Sample_1D (Target_Std_Normal'Access, Cfg_Wide_Prop);
   begin
      Check (In_01 (Real (Rt.Accept_Rate)), "tight σ accept in [0,1]");
      Check (In_01 (Real (Rw.Accept_Rate)), "wide σ accept in [0,1]");
      Check (Rt.Accept_Rate > Rw.Accept_Rate,
             "smaller proposal σ ⇒ higher accept rate");
      Check (Approx (Rt.Mean, 0.0, 0.2), "tight-σ chain mean still ≈ 0");
      Check (Approx (Rw.Mean, 0.0, 0.25), "wide-σ chain mean still ≈ 0");
   end;

   ---------------------------------------------------------------------
   Section ("6. Keep_Samples storage");
   ---------------------------------------------------------------------
   declare
      R : constant Result :=
        Sample_1D (Target_Std_Normal'Access, Cfg_Keep);
      Expected : constant Natural := Cfg_Keep.Steps - Cfg_Keep.Burn_In;
   begin
      Check (R.Stored = Store_Count (Expected),
             "Stored equals post-burn-in count");
      Check (R.N_Kept = Expected, "N_Kept matches Stored when kept");
      Check (R.Stored >= 1, "at least one stored sample");
      --  crude: sample mean of stored close to Result.Mean
      declare
         S : Real := 0.0;
      begin
         for I in 1 .. R.Stored loop
            S := S + R.Samples (I);
         end loop;
         S := S / Real (R.Stored);
         Check (Approx (S, R.Mean, 1.0E-9),
                "stored samples mean matches Result.Mean");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("7. Independent Metropolis–Hastings");
   ---------------------------------------------------------------------
   declare
      R : constant Result :=
        Sample_1D_Independent
          (Target_Std_Normal'Access,
           Proposal_Std_Normal'Access,
           Cfg_Ind);
   begin
      Check (In_01 (Real (R.Accept_Rate)), "indep MH accept in [0,1]");
      Check (R.Accept_Rate > 0.0, "indep MH some accepts");
      Check (Approx (R.Mean, 0.0, 0.2), "indep MH N(0,1) mean ≈ 0");
      Check (Approx (R.Variance, 1.0, 0.45), "indep MH N(0,1) var ≈ 1");
      Check (R.N_Kept = Cfg_Ind.Steps - Cfg_Ind.Burn_In, "indep kept count");
   end;

   ---------------------------------------------------------------------
   Section ("8. Sample_ND isotropic RW (D=2)");
   ---------------------------------------------------------------------
   declare
      C2 : Config_ND (2);
      R2 : Result_ND (2);
   begin
      C2.Steps := 20_000;
      C2.Burn_In := 4_000;
      C2.Proposal_Sigma := 0.8;
      C2.Seed := 17;
      C2.Start := [0.0, 0.0];
      R2 := Sample_ND (Target_Iso_Normal_ND'Access, C2);
      Check (R2.N_Proposed = C2.Steps, "2D proposed = Steps");
      Check (In_01 (Real (R2.Accept_Rate)), "2D accept in [0,1]");
      Check (R2.Accept_Rate > 0.0, "2D accept > 0");
      Check (Approx (R2.Mean (1), 0.0, 0.2), "2D mean_x ≈ 0");
      Check (Approx (R2.Mean (2), 0.0, 0.2), "2D mean_y ≈ 0");
      Check (Approx (R2.Variance (1), 1.0, 0.35), "2D var_x ≈ 1");
      Check (Approx (R2.Variance (2), 1.0, 0.35), "2D var_y ≈ 1");
      Check (R2.N_Kept = C2.Steps - C2.Burn_In, "2D kept count");
   end;

   ---------------------------------------------------------------------
   Section ("9. Sample_ND (D=1 coincides with 1D idea)");
   ---------------------------------------------------------------------
   declare
      C1 : Config_ND (1);
      R1 : Result_ND (1);
   begin
      C1.Steps := 20_000;
      C1.Burn_In := 3_000;
      C1.Proposal_Sigma := 1.0;
      C1.Seed := 42;
      C1.Start := [1 => 0.0];
      R1 := Sample_ND (Target_Std_Normal_ND'Access, C1);
      Check (R1.N_Proposed = C1.Steps, "ND-1D proposed = Steps");
      Check (Approx (R1.Mean (1), 0.0, 0.2), "ND-1D mean ≈ 0");
      Check (Approx (R1.Variance (1), 1.0, 0.3), "ND-1D var ≈ 1");
      Check (In_01 (Real (R1.Accept_Rate)), "ND-1D accept in [0,1]");
   end;

   ---------------------------------------------------------------------
   Section ("10. Bernoulli discrete Metropolis");
   ---------------------------------------------------------------------
   declare
      R3 : constant Result := Sample_Bernoulli (0.3, Cfg_Bern);
      R7 : constant Result :=
        Sample_Bernoulli
          (0.7,
           (Steps          => 20_000,
            Burn_In        => 2_000,
            Proposal_Sigma => 1.0,
            Seed           => 12,
            Start          => 1.0,
            Keep_Samples   => False));
      R5 : constant Result :=
        Sample_Bernoulli
          (0.5,
           (Steps          => 15_000,
            Burn_In        => 1_000,
            Proposal_Sigma => 1.0,
            Seed           => 13,
            Start          => 0.0,
            Keep_Samples   => False));
   begin
      Check (Approx (R3.Mean, 0.3, 0.05), "Bernoulli(0.3) mean ≈ 0.3");
      Check (Approx (R7.Mean, 0.7, 0.05), "Bernoulli(0.7) mean ≈ 0.7");
      Check (Approx (R5.Mean, 0.5, 0.05), "Bernoulli(0.5) mean ≈ 0.5");
      Check (In_01 (Real (R3.Accept_Rate)), "Bern(0.3) accept in [0,1]");
      Check (In_01 (Real (R7.Accept_Rate)), "Bern(0.7) accept in [0,1]");
      Check (R3.Accept_Rate > 0.0 and then R3.Accept_Rate < 1.0,
             "Bern(0.3) accept strictly in (0,1)");
      --  For p=0.5, flip always accepted (π ratio = 1) ⇒ accept ≈ 1
      Check (R5.Accept_Rate > 0.95, "Bern(0.5) near-always accepts flips");
      Check (R3.Variance > 0.0, "Bernoulli variance positive");
      Check (Approx (R3.Variance, 0.3 * 0.7, 0.05),
             "Bern(0.3) var ≈ p(1-p)");
   end;

   ---------------------------------------------------------------------
   Section ("11. Tiny 1D Ising Metropolis");
   ---------------------------------------------------------------------
   declare
      Hot  : constant Ising_Result :=
        Sample_Ising_1D (N => 6, Beta => 0.1, Steps => 30_000,
                         Burn => 3_000, Seed => 21);
      Cold : constant Ising_Result :=
        Sample_Ising_1D (N => 6, Beta => 2.0, Steps => 30_000,
                         Burn => 3_000, Seed => 22);
      Tiny : constant Ising_Result :=
        Sample_Ising_1D (N => 2, Beta => 1.0, Steps => 20_000,
                         Burn => 2_000, Seed => 23);
   begin
      Check (In_01 (Real (Hot.Accept_Rate)), "hot Ising accept in [0,1]");
      Check (In_01 (Real (Cold.Accept_Rate)), "cold Ising accept in [0,1]");
      Check (Hot.Accept_Rate > Cold.Accept_Rate,
             "hotter (small β) ⇒ higher accept than cold");
      Check (abs (Hot.Mean_Magnetization) < 0.35,
             "hot Ising |m| small (disordered)");
      Check (abs (Cold.Mean_Magnetization) > abs (Hot.Mean_Magnetization),
             "cold |m| larger than hot (more ordered)");
      Check (Cold.Mean_Energy < Hot.Mean_Energy,
             "cold mean energy lower than hot");
      Check (Tiny.N_Kept > 0, "Ising N=2 kept > 0");
      Check (In_01 (Real (Tiny.Accept_Rate)), "Ising N=2 accept in [0,1]");
      Check (abs (Tiny.Mean_Magnetization) <= 1.0 + 1.0E-9,
             "magnetization in [-1,1]");
   end;

   ---------------------------------------------------------------------
   Section ("12. Invalid arguments / edge configs");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Raised := False;
      begin
         declare
            R : constant Result :=
              Sample_1D
                (Target_Std_Normal'Access,
                 (Steps => 100, Burn_In => 100, Proposal_Sigma => 1.0,
                  Seed => 1, Start => 0.0, Keep_Samples => False));
            pragma Unreferenced (R);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Burn_In >= Steps raises Invalid_Argument");

      Raised := False;
      begin
         declare
            R : constant Result := Sample_Bernoulli (0.0, Cfg_Small);
            pragma Unreferenced (R);
         begin
            null;
         end;
      exception
         when Constraint_Error | Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Bernoulli p=0 rejected");

      Raised := False;
      begin
         declare
            R : constant Ising_Result :=
              Sample_Ising_1D (N => 1, Beta => 1.0);
            pragma Unreferenced (R);
         begin
            null;
         end;
      exception
         when Constraint_Error | Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Ising N=1 rejected");
   end;

   ---------------------------------------------------------------------
   Section ("13. Bimodal target / seed reproducibility");
   ---------------------------------------------------------------------
   declare
      Cb : constant Config :=
        (Steps          => 40_000,
         Burn_In        => 5_000,
         Proposal_Sigma => 1.5,
         Seed           => 77,
         Start          => 0.0,
         Keep_Samples   => False);
      R1 : constant Result := Sample_1D (Target_Bimodal'Access, Cb);
      R2 : constant Result := Sample_1D (Target_Bimodal'Access, Cb);
      C2 : Config := Cb;
      R3 : Result;
   begin
      C2.Seed := 78;
      R3 := Sample_1D (Target_Bimodal'Access, C2);
      Check (Approx (R1.Mean, R2.Mean, 1.0E-12),
             "same seed ⇒ identical mean");
      Check (Approx (Real (R1.Accept_Rate), Real (R2.Accept_Rate), 1.0E-12),
             "same seed ⇒ identical accept rate");
      Check (R1.Mean /= R3.Mean or else
             R1.N_Accepted /= R3.N_Accepted,
             "different seed changes chain");
      Check (In_01 (Real (R1.Accept_Rate)), "bimodal accept in [0,1]");
      --  Symmetric bimodal about 0 ⇒ mean near 0 (may be slow; loose)
      Check (Approx (R1.Mean, 0.0, 0.6), "bimodal mean ≈ 0 (very loose)");
      Check (R1.Variance > 1.0, "bimodal variance > 1 (spread across modes)");
   end;

   ---------------------------------------------------------------------
   Section ("14. Small run smoke / API field sanity");
   ---------------------------------------------------------------------
   declare
      R : constant Result :=
        Sample_1D (Target_Std_Normal'Access, Cfg_Small);
   begin
      Check (R.N_Proposed = Cfg_Small.Steps, "small: proposed count");
      Check (R.N_Kept = Cfg_Small.Steps - Cfg_Small.Burn_In, "small: kept");
      Check (In_01 (Real (R.Accept_Rate)), "small: accept in [0,1]");
      Check (R.N_Accepted <= Cfg_Small.Steps, "small: accepted bound");
      Check (R.N_Proposed > R.N_Kept, "proposed exceeds kept (burn-in)");
      Check (R.Variance >= 0.0, "variance non-negative");
      Check (abs (R.Mean) < 10.0, "small-run mean not exploded");
      Check (R.Stored = 0, "small run did not store samples");
   end;

   ---------------------------------------------------------------------
   Section ("15. Config defaults / Start offset");
   ---------------------------------------------------------------------
   declare
      C_Off : constant Config :=
        (Steps          => 20_000,
         Burn_In        => 5_000,
         Proposal_Sigma => 1.0,
         Seed           => 9,
         Start          => 5.0,  -- far start; burn-in should forget
         Keep_Samples   => False);
      R : constant Result :=
        Sample_1D (Target_Std_Normal'Access, C_Off);
      Def : Config;
   begin
      Check (Approx (R.Mean, 0.0, 0.2), "far Start still recovers mean≈0");
      Check (Def.Steps = 10_000, "default Steps=10000");
      Check (Def.Burn_In = 1_000, "default Burn_In=1000");
      Check (Approx (Def.Proposal_Sigma, 1.0, 1.0E-15), "default σ=1");
      Check (Def.Seed = 42, "default Seed=42");
      Check (Approx (Def.Start, 0.0, 1.0E-15), "default Start=0");
      Check (Def.Keep_Samples = False, "default Keep_Samples=False");
   end;

   New_Line;
   Put_Line ("==============================================================");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;
end Tests;
