--  Standalone test suite for Hybrid_Monte_Carlo (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Hybrid_Monte_Carlo; use Hybrid_Monte_Carlo;

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

   function In_0_1_Open_Closed (X : Real) return Boolean is
   begin
      --  Accept rate in (0, 1]
      return X > 0.0 and then X <= 1.0;
   end In_0_1_Open_Closed;

   Cfg_Std : constant Config :=
     (N_Samples    => 8_000,
      Burn_In      => 1_000,
      Epsilon      => 0.1,
      L_Steps      => 10,
      Seed         => 42,
      Start        => 0.0,
      Keep_Samples => False);

   Cfg_Mu2 : constant Config :=
     (N_Samples    => 8_000,
      Burn_In      => 1_000,
      Epsilon      => 0.1,
      L_Steps      => 12,
      Seed         => 7,
      Start        => 0.0,
      Keep_Samples => False);

   Cfg_Wide : constant Config :=
     (N_Samples    => 10_000,
      Burn_In      => 1_500,
      Epsilon      => 0.2,
      L_Steps      => 15,
      Seed         => 99,
      Start        => 0.0,
      Keep_Samples => False);

   Cfg_Keep : constant Config :=
     (N_Samples    => 1_500,
      Burn_In      => 200,
      Epsilon      => 0.1,
      L_Steps      => 8,
      Seed         => 1,
      Start        => 0.0,
      Keep_Samples => True);

   Cfg_Small : constant Config :=
     (N_Samples    => 600,
      Burn_In      => 100,
      Epsilon      => 0.08,
      L_Steps      => 6,
      Seed         => 3,
      Start        => 1.0,
      Keep_Samples => False);

   Cfg_Fine : constant Config :=
     (N_Samples    => 5_000,
      Burn_In      => 500,
      Epsilon      => 0.05,
      L_Steps      => 20,
      Seed         => 55,
      Start        => 0.0,
      Keep_Samples => False);

   Cfg_Coarse : constant Config :=
     (N_Samples    => 5_000,
      Burn_In      => 500,
      Epsilon      => 0.25,
      L_Steps      => 5,
      Seed         => 56,
      Start        => 0.0,
      Keep_Samples => False);

begin
   Put_Line ("Hybrid_Monte_Carlo test suite (HMC / leapfrog Metropolis)");
   Put_Line ("==========================================================");

   ---------------------------------------------------------------------
   Section ("1. Kinetic / Hamiltonian / Accept_Probability");
   ---------------------------------------------------------------------
   declare
      K0  : constant Non_Negative := Kinetic_1D (0.0);
      K1  : constant Non_Negative := Kinetic_1D (2.0);
      H0  : constant Real := Hamiltonian_1D (1.0, 0.0);
      H1  : constant Real := Hamiltonian_1D (0.5, 1.0);
      A0  : constant Unit_Fraction := Accept_Probability (0.0);
      An  : constant Unit_Fraction := Accept_Probability (-0.69314718056);
      --  exp(+0.693…) ≈ 2 → clamped to 1
      Ap  : constant Unit_Fraction := Accept_Probability (0.69314718056);
      --  exp(−0.693) ≈ 0.5
      Aneg : constant Unit_Fraction := Accept_Probability (-1000.0);
      P2  : constant Point := [1.0, 2.0, -2.0];
      Kn  : constant Non_Negative := Kinetic_ND (P2);
      Hn  : constant Real := Hamiltonian_ND (3.0, P2);
   begin
      Check (Approx (Real (K0), 0.0, 1.0E-15), "Kinetic_1D(0)=0");
      Check (Approx (Real (K1), 2.0, 1.0E-12), "Kinetic_1D(2)=2");
      Check (Approx (H0, 1.0, 1.0E-15), "H(U=1,p=0)=1");
      Check (Approx (H1, 1.0, 1.0E-12), "H(U=0.5,p=1)=1");
      Check (Approx (Real (A0), 1.0, 1.0E-12), "Accept(ΔH=0)=1");
      Check (Approx (Real (An), 1.0, 1.0E-12), "Accept(negative ΔH)=1");
      Check (Approx (Real (Ap), 0.5, 1.0E-5), "Accept(ln2)≈0.5");
      Check (In_01 (Real (Ap)), "Accept mid in [0,1]");
      Check (Aneg = 1.0, "large negative ΔH ⇒ accept 1");
      Check (Accept_Probability (1000.0) < 1.0E-10,
             "large positive ΔH ⇒ accept ≈0");
      --  ‖p‖²/2 = (1+4+4)/2 = 4.5
      Check (Approx (Real (Kn), 4.5, 1.0E-12), "Kinetic_ND [1,2,-2]=4.5");
      Check (Approx (Hn, 7.5, 1.0E-12), "Hamiltonian_ND U=3 + K=4.5");
   end;

   ---------------------------------------------------------------------
   Section ("2. Potential / gradient educational targets");
   ---------------------------------------------------------------------
   declare
      U0 : constant Real := U_Std_Normal (0.0);
      U1 : constant Real := U_Std_Normal (1.0);
      G1 : constant Real := Grad_U_Std_Normal (1.0);
      Um : constant Real := U_Normal_Mu2 (2.0);
      Gm : constant Real := Grad_U_Normal_Mu2 (3.0);
      Uw : constant Real := U_Normal_Wide (2.0);
      Gw : constant Real := Grad_U_Normal_Wide (4.0);
      Q2 : constant Point := [1.0, -1.0];
      Un : constant Real := U_Iso_Normal_ND (Q2);
      Gn : constant Point := Grad_U_Iso_Normal_ND (Q2);
   begin
      Check (Approx (U0, 0.0, 1.0E-15), "U_Std_Normal(0)=0");
      Check (Approx (U1, 0.5, 1.0E-15), "U_Std_Normal(1)=1/2");
      Check (Approx (G1, 1.0, 1.0E-15), "Grad_U_Std_Normal(1)=1");
      Check (Approx (Um, 0.0, 1.0E-15), "U_Normal_Mu2(2)=0");
      Check (Approx (Gm, 1.0, 1.0E-15), "Grad_U_Normal_Mu2(3)=1");
      Check (Approx (Uw, 0.5, 1.0E-12), "U_Normal_Wide(2)=0.5");
      Check (Approx (Gw, 1.0, 1.0E-12), "Grad_U_Normal_Wide(4)=1");
      Check (Approx (Un, 1.0, 1.0E-12), "U_Iso_Normal_ND ‖q‖²/2");
      Check (Approx (Gn (1), 1.0, 1.0E-15), "Grad ND coord 1");
      Check (Approx (Gn (2), -1.0, 1.0E-15), "Grad ND coord 2");
   end;

   ---------------------------------------------------------------------
   Section ("3. Leapfrog_1D harmonic oscillator energy near-conservation");
   ---------------------------------------------------------------------
   declare
      Q : Real := 1.0;
      P : Real := 0.0;
      H_Before : Real;
      H_After  : Real;
      Qb : Real;
      Pb : Real;
   begin
      H_Before := Hamiltonian_1D (U_Std_Normal (Q), P);
      Leapfrog_1D (Q, P, Grad_U_Std_Normal'Access, 0.05, 20);
      H_After := Hamiltonian_1D (U_Std_Normal (Q), P);
      Check (abs (H_After - H_Before) < 0.05,
             "leapfrog modest ΔH on harmonic (ε=0.05,L=20)");
      Check (abs (Q) < 5.0 and then abs (P) < 5.0,
             "leapfrog state stayed bounded");

      --  Reversibility: forward then negate p, forward again ≈ start
      Q := 0.7;
      P := -0.3;
      Qb := Q;
      Pb := P;
      Leapfrog_1D (Q, P, Grad_U_Std_Normal'Access, 0.1, 5);
      P := -P;
      Leapfrog_1D (Q, P, Grad_U_Std_Normal'Access, 0.1, 5);
      P := -P;
      Check (Approx (Q, Qb, 1.0E-8), "leapfrog reversible in q");
      Check (Approx (P, Pb, 1.0E-8), "leapfrog reversible in p");
   end;

   ---------------------------------------------------------------------
   Section ("4. Leapfrog_Step_1D single step sanity");
   ---------------------------------------------------------------------
   declare
      Q : Real := 0.0;
      P : Real := 1.0;
      Q2 : Real;
      P2 : Real;
   begin
      Leapfrog_Step_1D (Q, P, Grad_U_Std_Normal'Access, 0.1);
      --  From (0,1): half kick p stays 1 (grad=0); drift q=0.1; half kick
      --  p := 1 - 0.05*0.1 = 0.995
      Check (Approx (Q, 0.1, 1.0E-12), "one step q≈0.1");
      Check (Approx (P, 0.995, 1.0E-12), "one step p≈0.995");

      Q2 := 0.0;
      P2 := 1.0;
      Leapfrog_1D (Q2, P2, Grad_U_Std_Normal'Access, 0.1, 1);
      Check (Approx (Q2, Q, 1.0E-15), "Leapfrog_1D L=1 = Step");
      Check (Approx (P2, P, 1.0E-15), "Leapfrog_1D L=1 p match");
   end;

   ---------------------------------------------------------------------
   Section ("5. Sample_1D standard normal moments");
   ---------------------------------------------------------------------
   declare
      R : constant Result :=
        Sample_1D (U_Std_Normal'Access, Grad_U_Std_Normal'Access, Cfg_Std);
      Rrun : constant Result :=
        Run (U_Std_Normal'Access, Grad_U_Std_Normal'Access, Cfg_Std);
   begin
      Check (Approx (R.Mean, 0.0, 0.15), "N(0,1) mean ≈ 0");
      Check (Approx (R.Variance, 1.0, 0.25), "N(0,1) var ≈ 1");
      Check (In_0_1_Open_Closed (Real (R.Accept_Rate)),
             "accept rate in (0,1]");
      Check (R.Accept_Rate > 0.5, "HMC accept often high for tuned ε,L");
      Check (R.N_Proposed = Cfg_Std.N_Samples, "proposed = N_Samples");
      Check (R.N_Kept = Cfg_Std.N_Samples - Cfg_Std.Burn_In, "kept count");
      Check (R.N_Accepted <= R.N_Proposed, "accepted ≤ proposed");
      Check (R.N_Accepted > 0, "some accepts");
      Check (R.Stored = 0, "Keep_Samples=False ⇒ Stored=0");
      Check (Approx (R.Mean, Rrun.Mean, 1.0E-12), "Run renames Sample_1D");
      Check (R.N_Accepted = Rrun.N_Accepted, "Run same accepts");
   end;

   ---------------------------------------------------------------------
   Section ("6. Sample_1D shifted / wide Gaussians");
   ---------------------------------------------------------------------
   declare
      Rm : constant Result :=
        Sample_1D
          (U_Normal_Mu2'Access, Grad_U_Normal_Mu2'Access, Cfg_Mu2);
      Rw : constant Result :=
        Sample_1D
          (U_Normal_Wide'Access, Grad_U_Normal_Wide'Access, Cfg_Wide);
   begin
      Check (Approx (Rm.Mean, 2.0, 0.2), "N(2,1) mean ≈ 2");
      Check (Approx (Rm.Variance, 1.0, 0.3), "N(2,1) var ≈ 1");
      Check (In_0_1_Open_Closed (Real (Rm.Accept_Rate)),
             "Mu2 accept in (0,1]");
      Check (Approx (Rw.Mean, 0.0, 0.35), "N(0,4) mean ≈ 0");
      Check (Approx (Rw.Variance, 4.0, 1.0), "N(0,4) var ≈ 4 (loose)");
      Check (In_0_1_Open_Closed (Real (Rw.Accept_Rate)),
             "wide accept in (0,1]");
      Check (Rw.Variance > 1.5, "wide variance clearly > 1");
   end;

   ---------------------------------------------------------------------
   Section ("7. Keep_Samples / seed reproducibility");
   ---------------------------------------------------------------------
   declare
      R1 : constant Result :=
        Sample_1D
          (U_Std_Normal'Access, Grad_U_Std_Normal'Access, Cfg_Keep);
      R2 : constant Result :=
        Sample_1D
          (U_Std_Normal'Access, Grad_U_Std_Normal'Access, Cfg_Keep);
      C3 : Config := Cfg_Keep;
      R3 : Result;
   begin
      C3.Seed := Cfg_Keep.Seed + 1;
      R3 := Sample_1D
        (U_Std_Normal'Access, Grad_U_Std_Normal'Access, C3);
      Check (R1.Stored = Cfg_Keep.N_Samples - Cfg_Keep.Burn_In,
             "stored = kept count");
      Check (R1.Stored > 0, "stored positive");
      Check (Approx (R1.Samples (1), R2.Samples (1), 1.0E-15),
             "same seed ⇒ identical first stored sample");
      Check (Approx (R1.Mean, R2.Mean, 1.0E-12),
             "same seed ⇒ identical mean");
      Check (Approx (Real (R1.Accept_Rate), Real (R2.Accept_Rate), 1.0E-12),
             "same seed ⇒ identical accept rate");
      Check (R1.Mean /= R3.Mean or else R1.N_Accepted /= R3.N_Accepted,
             "different seed changes chain");
      Check (Approx (R1.Mean, 0.0, 0.35), "keep-run mean ≈ 0 (loose)");
   end;

   ---------------------------------------------------------------------
   Section ("8. Sample_ND 2D isotropic Gaussian");
   ---------------------------------------------------------------------
   declare
      C2 : constant Config_ND (2) :=
        (D         => 2,
         N_Samples => 6_000,
         Burn_In   => 800,
         Epsilon   => 0.1,
         L_Steps   => 10,
         Seed      => 21,
         Start     => [0.0, 0.0]);
      R : constant Result_ND :=
        Sample_ND
          (U_Iso_Normal_ND'Access, Grad_U_Iso_Normal_ND'Access, C2);
   begin
      Check (Approx (R.Mean (1), 0.0, 0.2), "2D mean_1 ≈ 0");
      Check (Approx (R.Mean (2), 0.0, 0.2), "2D mean_2 ≈ 0");
      Check (Approx (R.Variance (1), 1.0, 0.35), "2D var_1 ≈ 1");
      Check (Approx (R.Variance (2), 1.0, 0.35), "2D var_2 ≈ 1");
      Check (In_0_1_Open_Closed (Real (R.Accept_Rate)),
             "2D accept in (0,1]");
      Check (R.N_Proposed = C2.N_Samples, "2D proposed count");
      Check (R.N_Kept = C2.N_Samples - C2.Burn_In, "2D kept count");
      Check (R.N_Accepted > 0, "2D some accepts");
   end;

   ---------------------------------------------------------------------
   Section ("9. Leapfrog_ND reversibility / Sample_ND D=1 vs 1D");
   ---------------------------------------------------------------------
   declare
      Q : Point := [0.5, -0.25];
      P : Point := [0.1, 0.2];
      Qb : constant Point := Q;
      Pb : constant Point := P;
      C1 : constant Config_ND (1) :=
        (D         => 1,
         N_Samples => 5_000,
         Burn_In   => 500,
         Epsilon   => 0.1,
         L_Steps   => 10,
         Seed      => 42,
         Start     => [0.0]);
      C1d : constant Config :=
        (N_Samples    => 5_000,
         Burn_In      => 500,
         Epsilon      => 0.1,
         L_Steps      => 10,
         Seed         => 42,
         Start        => 0.0,
         Keep_Samples => False);
      Rn : constant Result_ND :=
        Sample_ND
          (U_Iso_Normal_ND'Access, Grad_U_Iso_Normal_ND'Access, C1);
      R1 : constant Result :=
        Sample_1D
          (U_Std_Normal'Access, Grad_U_Std_Normal'Access, C1d);
   begin
      Leapfrog_ND (Q, P, Grad_U_Iso_Normal_ND'Access, 0.08, 7);
      for I in Q'Range loop
         P (I) := -P (I);
      end loop;
      Leapfrog_ND (Q, P, Grad_U_Iso_Normal_ND'Access, 0.08, 7);
      for I in Q'Range loop
         P (I) := -P (I);
      end loop;
      Check (Approx (Q (1), Qb (1), 1.0E-8), "ND leapfrog rev q1");
      Check (Approx (Q (2), Qb (2), 1.0E-8), "ND leapfrog rev q2");
      Check (Approx (P (1), Pb (1), 1.0E-8), "ND leapfrog rev p1");
      Check (Approx (P (2), Pb (2), 1.0E-8), "ND leapfrog rev p2");
      --  Same seed / ε / L / start: 1D and ND(D=1) should match closely
      Check (Approx (Rn.Mean (1), R1.Mean, 1.0E-10),
             "D=1 Sample_ND mean matches Sample_1D");
      Check (Approx (Rn.Variance (1), R1.Variance, 1.0E-10),
             "D=1 Sample_ND var matches Sample_1D");
      Check (Rn.N_Accepted = R1.N_Accepted,
             "D=1 Sample_ND accepts match Sample_1D");
   end;

   ---------------------------------------------------------------------
   Section ("10. ε / L sensitivity (still valid chains)");
   ---------------------------------------------------------------------
   declare
      Rf : constant Result :=
        Sample_1D
          (U_Std_Normal'Access, Grad_U_Std_Normal'Access, Cfg_Fine);
      Rc : constant Result :=
        Sample_1D
          (U_Std_Normal'Access, Grad_U_Std_Normal'Access, Cfg_Coarse);
   begin
      Check (Approx (Rf.Mean, 0.0, 0.2), "fine ε mean ≈ 0");
      Check (Approx (Rf.Variance, 1.0, 0.3), "fine ε var ≈ 1");
      Check (In_0_1_Open_Closed (Real (Rf.Accept_Rate)),
             "fine accept in (0,1]");
      Check (Approx (Rc.Mean, 0.0, 0.25), "coarse ε mean ≈ 0");
      Check (Approx (Rc.Variance, 1.0, 0.4), "coarse ε var ≈ 1");
      Check (In_0_1_Open_Closed (Real (Rc.Accept_Rate)),
             "coarse accept in (0,1]");
      Check (Rf.N_Accepted > 0 and then Rc.N_Accepted > 0,
             "both ε regimes accepted some proposals");
      Check (Rf.Variance > 0.0 and then Rc.Variance > 0.0,
             "both ε regimes positive variance");
      Check (abs (Real (Rf.Accept_Rate) - Real (Rc.Accept_Rate)) <= 1.0,
             "accept rates differ by at most 1 (trivial bound)");
   end;

   ---------------------------------------------------------------------
   Section ("11. Invalid arguments / defaults / far Start");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      Bad    : Config := Cfg_Small;
      C_Off  : constant Config :=
        (N_Samples    => 6_000,
         Burn_In      => 1_500,
         Epsilon      => 0.1,
         L_Steps      => 10,
         Seed         => 9,
         Start        => 5.0,
         Keep_Samples => False);
      R : constant Result :=
        Sample_1D
          (U_Std_Normal'Access, Grad_U_Std_Normal'Access, C_Off);
      Def : Config;
      Rs  : constant Result :=
        Sample_1D
          (U_Std_Normal'Access, Grad_U_Std_Normal'Access, Cfg_Small);
   begin
      Bad.Burn_In := Bad.N_Samples;
      Raised := False;
      begin
         declare
            Ignore : constant Result :=
              Sample_1D
                (U_Std_Normal'Access, Grad_U_Std_Normal'Access, Bad);
            pragma Unreferenced (Ignore);
         begin
            null;
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Burn_In >= N_Samples raises Invalid_Argument");

      Check (Approx (R.Mean, 0.0, 0.25), "far Start recovers mean≈0");
      Check (In_0_1_Open_Closed (Real (R.Accept_Rate)),
             "far Start accept in (0,1]");

      Check (Def.N_Samples = 10_000, "default N_Samples=10000");
      Check (Def.Burn_In = 1_000, "default Burn_In=1000");
      Check (Approx (Def.Epsilon, 0.1, 1.0E-15), "default Epsilon=0.1");
      Check (Def.L_Steps = 10, "default L_Steps=10");
      Check (Def.Seed = 42, "default Seed=42");
      Check (Approx (Def.Start, 0.0, 1.0E-15), "default Start=0");
      Check (Def.Keep_Samples = False, "default Keep_Samples=False");

      Check (Rs.N_Proposed = Cfg_Small.N_Samples, "small: proposed");
      Check (Rs.N_Kept = Cfg_Small.N_Samples - Cfg_Small.Burn_In,
             "small: kept");
      Check (In_01 (Real (Rs.Accept_Rate)), "small: accept in [0,1]");
      Check (Rs.Variance >= 0.0, "variance non-negative");
      Check (abs (Rs.Mean) < 10.0, "small-run mean not exploded");
      Check (Rs.Stored = 0, "small did not store");
   end;

   ---------------------------------------------------------------------
   Section ("12. Max caps / ND D=3 smoke / energy helper edge");
   ---------------------------------------------------------------------
   declare
      C3 : constant Config_ND (3) :=
        (D         => 3,
         N_Samples => 3_000,
         Burn_In   => 400,
         Epsilon   => 0.08,
         L_Steps   => 8,
         Seed      => 33,
         Start     => [0.0, 0.0, 0.0]);
      R3 : constant Result_ND :=
        Sample_ND
          (U_Iso_Normal_ND'Access, Grad_U_Iso_Normal_ND'Access, C3);
      Z : constant Point := [0.0, 0.0];
      Kz : constant Non_Negative := Kinetic_ND (Z);
   begin
      Check (R3.D = C3.D, "Result_ND D matches Config_ND");
      Check (C3.L_Steps = 8, "3D L_Steps=8 as configured");
      Check (R3.N_Proposed = C3.N_Samples, "3D proposed = N_Samples");
      Check (Approx (Real (Kz), 0.0, 1.0E-15), "Kinetic_ND zero vec");
      Check (Approx (R3.Mean (1), 0.0, 0.3), "3D mean_1≈0");
      Check (Approx (R3.Mean (2), 0.0, 0.3), "3D mean_2≈0");
      Check (Approx (R3.Mean (3), 0.0, 0.3), "3D mean_3≈0");
      Check (R3.Variance (1) > 0.3 and then R3.Variance (1) < 2.5,
             "3D var_1 in loose band");
      Check (In_0_1_Open_Closed (Real (R3.Accept_Rate)),
             "3D accept in (0,1]");
      Check (R3.N_Kept > 0, "3D kept > 0");
   end;

   New_Line;
   Put_Line ("==========================================================");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   if Fail_Count = 0 then
      Put_Line ("ALL PASSED");
   else
      Put_Line ("SOME FAILED");
   end if;
end Tests;
