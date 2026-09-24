--  Standalone test suite for Nested_Sampling (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Nested_Sampling; use Nested_Sampling;

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
   Put_Line ("Nested_Sampling test suite");
   Put_Line ("==========================");

   ---------------------------------------------------------------------
   Section ("1. Near / Safe_Log / Log_Sum");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Near (1.0, 1.0), "Near equal");
      Check (Near (1.0, 1.0 + 1.0E-9), "Near tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 1.0E-10, 1.0E-9), "Near custom Tol");
      Check (not Near (0.0, 1.0E-6, 1.0E-9), "Near custom Tol reject");
      Check (Near (Safe_Log (1.0), 0.0, 1.0E-6), "Safe_Log(1)=0");
      Check (Safe_Log (0.0) < -1.0E20, "Safe_Log(0) sentinel");
      Check (Safe_Log (-1.0) < -1.0E20, "Safe_Log(neg) sentinel");
      Check (Near (Log_Sum (0.0, 0.0), Safe_Log (2.0), 1.0E-5),
             "Log_Sum(0,0)=log2");
      Check (Near (Log_Sum (-1.0E30, 0.0), 0.0, 1.0E-5),
             "Log_Sum(-inf,0)=0");
   end;

   ---------------------------------------------------------------------
   Section ("2. Prior_Volume X_i schedule");
   ---------------------------------------------------------------------
   declare
      N  : constant Positive := 100;
      X0 : constant Unit_Interval := Prior_Volume (0, N);
      X1 : constant Unit_Interval :=
        Prior_Volume (1, N, Exponential_Shrink);
      X2 : constant Unit_Interval :=
        Prior_Volume (2, N, Exponential_Shrink);
      Xd : constant Unit_Interval :=
        Prior_Volume (1, N, Debiased_Shrink);
      X10 : constant Unit_Interval :=
        Prior_Volume (10, N, Exponential_Shrink);
   begin
      Check (X0 = 1.0, "X_0 = 1");
      Check (X1 < 1.0 and then X1 > 0.98, "X_1 = exp(-1/N) ~0.99");
      Check (Approx (X1, 0.990049833749, 1.0E-6), "X_1 exact exp");
      Check (X2 < X1, "X_i decreasing");
      Check (Approx (Xd, 0.99, 1.0E-12), "debiased X_1=(1-1/N)");
      Check (Prior_Volume (0, 50, Debiased_Shrink) = 1.0, "debiased X_0=1");
      Check (X10 < X2, "X_10 < X_2");
      Check (Approx (X10, 0.904837418036, 1.0E-6), "X_10=exp(-0.1)");
   end;

   ---------------------------------------------------------------------
   Section ("3. Shell_Weight w_i and sum ≈ 1");
   ---------------------------------------------------------------------
   declare
      N     : constant Positive := 50;
      Sum_W : Real := 0.0;
      Xp, Xc : Unit_Interval;
      W     : Non_Negative;
   begin
      Check (Shell_Weight (1.0, 0.5) = 0.5, "w=0.5");
      Check (Shell_Weight (0.5, 0.5) = 0.0, "w=0 when equal");
      Check (Shell_Weight (0.3, 0.5) = 0.0, "w clamped if inverted");
      Xp := 1.0;
      for I in 1 .. 5 * N loop
         Xc := Prior_Volume (I, N, Exponential_Shrink);
         W := Shell_Weight (Xp, Xc);
         Sum_W := Sum_W + W;
         Xp := Xc;
      end loop;
      Check (Approx (Sum_W + Xp, 1.0, 1.0E-6), "sum w_i + X_j ≈ 1");
      Check (Sum_W > 0.9, "sum w_i covered most mass");
   end;

   ---------------------------------------------------------------------
   Section ("4. Built-in model metadata / analytic Z");
   ---------------------------------------------------------------------
   declare
      Z_Flat : constant Real := Analytic_Evidence (Flat_Unit);
      Z_Exp  : constant Real := Analytic_Evidence (Exponential_Unit);
      Z_G    : constant Real := Analytic_Evidence (Gaussian_Bump);
      T      : Param_Vector := [others => 0.0];
   begin
      Check (Model_Dim (Flat_Unit) = 1, "Flat dim=1");
      Check (Model_Dim (Exponential_Unit) = 1, "Exp dim=1");
      Check (Model_Dim (Gaussian_Bump) = 1, "Gauss dim=1");
      Check (Model_Low (Flat_Unit) (1) = 0.0, "Flat low=0");
      Check (Model_High (Flat_Unit) (1) = 1.0, "Flat high=1");
      Check (Model_Low (Gaussian_Bump) (1) = -5.0, "Gauss low=-5");
      Check (Model_High (Gaussian_Bump) (1) = 5.0, "Gauss high=5");
      Check (Z_Flat = 1.0, "analytic Flat Z=1");
      Check (Approx (Z_Exp, 0.6321205588285577, 1.0E-9),
             "analytic Exp Z=1-1/e");
      Check (Approx (Z_G, 0.2506628274, 1.0E-8), "analytic Gauss Z ref");
      T (1) := 0.5;
      Check (Built_In_Likelihood (Flat_Unit, T, 1) = 1.0, "Flat L=1");
      Check (Approx (Built_In_Likelihood (Exponential_Unit, T, 1),
                     0.606530659713, 1.0E-6),
             "Exp L(0.5)");
      T (1) := 0.0;
      Check (Built_In_Likelihood (Gaussian_Bump, T, 1) = 1.0,
             "Gauss L(0)=1");
      Check (Approx (Built_In_Prior_Density (Flat_Unit, T, 1), 1.0),
             "Flat prior dens=1");
      T (1) := 0.0;
      Check (Approx (Built_In_Prior_Density (Gaussian_Bump, T, 1), 0.1),
             "Gauss prior dens=1/10");
      T (1) := 10.0;
      Check (Built_In_Prior_Density (Gaussian_Bump, T, 1) = 0.0,
             "Gauss prior dens outside=0");
   end;

   ---------------------------------------------------------------------
   Section ("5. In_Prior_Box / Init_Live_From_Prior");
   ---------------------------------------------------------------------
   declare
      Low, High, Th : Param_Vector := [others => 0.0];
      Live          : Live_Set;
      St            : RNG_State;
      P             : Parameters;
   begin
      Low (1) := 0.0;
      High (1) := 1.0;
      Th (1) := 0.5;
      Check (In_Prior_Box (Th, Low, High, 1), "inside box");
      Th (1) := -0.1;
      Check (not In_Prior_Box (Th, Low, High, 1), "below low");
      Th (1) := 1.1;
      Check (not In_Prior_Box (Th, Low, High, 1), "above high");

      Seed_RNG (St, 42);
      P := (N_Live => 20, Max_Iters => 10, MCMC_Steps => 5,
            Tol => 1.0E-3, Seed => 42, Schedule => Exponential_Shrink,
            Add_Remainder => True, Dim => 1,
            Low => Low, High => High, Proposal_Scale => 0.1);
      Init_Live_From_Prior (Live, P, Likelihood_Flat'Access, St);
      Check (Live.Count = 20, "live count=20");
      Check (Live.Dim = 1, "live dim=1");
      declare
         All_In : Boolean := True;
         All_L1 : Boolean := True;
      begin
         for I in 1 .. Live_Index (Live.Count) loop
            if not In_Prior_Box
              (Live.Points (I).Theta, Low, High, 1)
            then
               All_In := False;
            end if;
            if Live.Points (I).L /= 1.0 then
               All_L1 := False;
            end if;
         end loop;
         Check (All_In, "all live in prior box");
         Check (All_L1, "all live L=1 for flat");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("6. Min_Likelihood_Index / Mean_Likelihood");
   ---------------------------------------------------------------------
   declare
      Live      : Live_Set;
      St        : RNG_State;
      P         : Parameters;
      Low, High : Param_Vector := [others => 0.0];
      Idx       : Live_Index;
      Mean      : Real;
      Is_Min    : Boolean := True;
      Lm        : Real;
   begin
      Low (1) := 0.0;
      High (1) := 1.0;
      Seed_RNG (St, 7);
      P := (N_Live => 10, Max_Iters => 5, MCMC_Steps => 5,
            Tol => 1.0E-3, Seed => 7, Schedule => Exponential_Shrink,
            Add_Remainder => False, Dim => 1,
            Low => Low, High => High, Proposal_Scale => 0.1);
      Init_Live_From_Prior (Live, P, Likelihood_Theta'Access, St);
      Idx := Min_Likelihood_Index (Live);
      Check (Idx in 1 .. Live_Index (Live.Count), "min index in range");
      Lm := Live.Points (Idx).L;
      for I in 1 .. Live_Index (Live.Count) loop
         if Live.Points (I).L < Lm then
            Is_Min := False;
         end if;
      end loop;
      Check (Is_Min, "min index has lowest L");
      Mean := Mean_Likelihood (Live);
      Check (Mean >= 0.0 and then Mean <= 1.0, "mean L in [0,1]");
   end;

   ---------------------------------------------------------------------
   Section ("7. Seeded RNG reproducibility");
   ---------------------------------------------------------------------
   declare
      S1, S2, S3 : RNG_State;
      A, B, C    : Unit_Interval;
      R          : Real;
   begin
      Seed_RNG (S1, 12345);
      Seed_RNG (S2, 12345);
      Seed_RNG (S3, 99999);
      A := Next_Unit (S1);
      B := Next_Unit (S2);
      C := Next_Unit (S3);
      Check (A = B, "same seed → same first draw");
      Check (A /= C, "different seed → different draw");
      Check (Next_Unit (S1) = Next_Unit (S2), "same seed sequence cont.");
      R := Next_Real (S1, 2.0, 5.0);
      Check (R >= 2.0 and then R < 5.0, "Next_Real in [2,5)");
      Seed_RNG (S1, 0);
      Check (Next_Unit (S1) >= 0.0, "seed 0 still works");
   end;

   ---------------------------------------------------------------------
   Section ("8. MCMC replace only accepts L > L*");
   ---------------------------------------------------------------------
   declare
      Live       : Live_Set;
      St         : RNG_State;
      P          : Parameters;
      Low, High  : Param_Vector := [others => 0.0];
      Acc        : Natural;
      L_Star     : Real;
      Worst      : Live_Index;
      New_L      : Real;
      Ok         : Boolean := True;
      Ls         : Real;
   begin
      Low (1) := 0.0;
      High (1) := 1.0;
      Seed_RNG (St, 99);
      P := (N_Live => 30, Max_Iters => 10, MCMC_Steps => 40,
            Tol => 1.0E-3, Seed => 99, Schedule => Exponential_Shrink,
            Add_Remainder => False, Dim => 1,
            Low => Low, High => High, Proposal_Scale => 0.25);
      Init_Live_From_Prior (Live, P, Likelihood_Exponential'Access, St);
      Worst := Min_Likelihood_Index (Live);
      L_Star := Live.Points (Worst).L;
      Replace_Lowest_MCMC
        (Live, L_Star, P, Likelihood_Exponential'Access, St, Acc);
      New_L := Live.Points (Worst).L;
      Check (New_L > L_Star or else Acc = 0,
             "replaced point L > L* (or rare fail)");
      Check (In_Prior_Box (Live.Points (Worst).Theta, Low, High, 1),
             "replaced point still in box");
      for K in 1 .. 15 loop
         Worst := Min_Likelihood_Index (Live);
         Ls := Live.Points (Worst).L;
         Replace_Lowest_MCMC
           (Live, Ls, P, Likelihood_Exponential'Access, St, Acc);
         if Live.Points (Worst).L <= Ls and then Acc > 0 then
            Ok := False;
         end if;
      end loop;
      Check (Ok, "series of MCMC replaces respect L*");
   end;

   ---------------------------------------------------------------------
   Section ("9. Flat model Z ≈ 1");
   ---------------------------------------------------------------------
   declare
      P         : Parameters;
      R         : Result;
      Low, High : Param_Vector := [others => 0.0];
   begin
      Low (1) := 0.0;
      High (1) := 1.0;
      P := (N_Live => 40, Max_Iters => 200, MCMC_Steps => 15,
            Tol => 1.0E-5, Seed => 1, Schedule => Exponential_Shrink,
            Add_Remainder => True, Dim => 1,
            Low => Low, High => High, Proposal_Scale => 0.2);
      R := Run_Nested_Sampling (P, Likelihood_Flat'Access);
      Check (R.Iters >= 1, "flat ran >=1 iter");
      Check (R.Num_Samples = Sample_Count (R.Iters), "samples=iters");
      Check (Approx (R.Evidence, 1.0, 0.08), "flat Z≈1 (tol 0.08)");
      Check (R.Evidence > 0.5, "flat Z > 0.5");
      Check (R.Evidence < 1.5, "flat Z < 1.5");

      R := Run_Built_In
        (Flat_Unit,
         (N_Live => 50, Max_Iters => 250, MCMC_Steps => 20,
          Tol => 1.0E-5, Seed => 2, Schedule => Debiased_Shrink,
          Add_Remainder => True, Dim => 1,
          Low => Low, High => High, Proposal_Scale => 0.2));
      Check (Approx (R.Evidence, 1.0, 0.08),
             "built-in flat Z≈1 debiased");
   end;

   ---------------------------------------------------------------------
   Section ("10. Z increases monotonically for positive L");
   ---------------------------------------------------------------------
   declare
      Live       : Live_Set;
      St         : RNG_State;
      P          : Parameters;
      Low, High  : Param_Vector := [others => 0.0];
      Z          : Real := 0.0;
      Xp, Xc     : Unit_Interval;
      W          : Non_Negative;
      Worst      : Live_Index;
      Acc        : Natural;
      Mono       : Boolean := True;
      Prev_Z     : Real := 0.0;
   begin
      Low (1) := 0.0;
      High (1) := 1.0;
      Seed_RNG (St, 3);
      P := (N_Live => 25, Max_Iters => 80, MCMC_Steps => 20,
            Tol => 0.0, Seed => 3, Schedule => Exponential_Shrink,
            Add_Remainder => False, Dim => 1,
            Low => Low, High => High, Proposal_Scale => 0.2);
      Init_Live_From_Prior (Live, P, Likelihood_Exponential'Access, St);
      Xp := 1.0;
      for Iter in 1 .. 80 loop
         Worst := Min_Likelihood_Index (Live);
         Xc := Prior_Volume (Iter, P.N_Live, P.Schedule);
         W := Shell_Weight (Xp, Xc);
         Z := Z + Live.Points (Worst).L * W;
         if Z + 1.0E-15 < Prev_Z then
            Mono := False;
         end if;
         Prev_Z := Z;
         Replace_Lowest_MCMC
           (Live, Live.Points (Worst).L, P,
            Likelihood_Exponential'Access, St, Acc);
         Xp := Xc;
      end loop;
      Check (Acc < 10_000, "MCMC Acc in sane range");
      Check (Mono, "Z monotone nondecreasing (L>0)");
      Check (Z > 0.3, "partial Exp Z > 0.3");
      Check (Z < 1.0, "partial Exp Z < 1");
   end;

   ---------------------------------------------------------------------
   Section ("11. Exponential toy Z within tolerance");
   ---------------------------------------------------------------------
   declare
      R         : Result;
      Z_Ref     : constant Real := Analytic_Evidence (Exponential_Unit);
      Low, High : Param_Vector := [others => 0.0];
   begin
      Low (1) := 0.0;
      High (1) := 1.0;
      R := Run_Built_In
        (Exponential_Unit,
         (N_Live => 60, Max_Iters => 400, MCMC_Steps => 30,
          Tol => 1.0E-6, Seed => 11, Schedule => Exponential_Shrink,
          Add_Remainder => True, Dim => 1,
          Low => Low, High => High, Proposal_Scale => 0.25));
      Check (Approx (R.Evidence, Z_Ref, 0.12),
             "Exp Z within 0.12 of 1-1/e");
      Check (R.Evidence > 0.4, "Exp Z lower bound");
      Check (R.Evidence < 0.9, "Exp Z upper bound");
      Check (R.Log_Evidence > Safe_Log (0.3), "log Z reasonable");
   end;

   ---------------------------------------------------------------------
   Section ("12. Gaussian bump Z within tolerance");
   ---------------------------------------------------------------------
   declare
      R         : Result;
      Z_Ref     : constant Real := Analytic_Evidence (Gaussian_Bump);
      Low, High : Param_Vector := [others => 0.0];
   begin
      Low (1) := -5.0;
      High (1) := 5.0;
      R := Run_Built_In
        (Gaussian_Bump,
         (N_Live => 80, Max_Iters => 500, MCMC_Steps => 40,
          Tol => 1.0E-6, Seed => 21, Schedule => Exponential_Shrink,
          Add_Remainder => True, Dim => 1,
          Low => Low, High => High, Proposal_Scale => 0.12));
      Check (Approx (R.Evidence, Z_Ref, 0.10),
             "Gauss Z within 0.10 of ref");
      Check (R.Evidence > 0.10, "Gauss Z lower");
      Check (R.Evidence < 0.45, "Gauss Z upper");
   end;

   ---------------------------------------------------------------------
   Section ("13. L(θ)=θ → Z≈1/2");
   ---------------------------------------------------------------------
   declare
      P         : Parameters;
      R         : Result;
      Low, High : Param_Vector := [others => 0.0];
   begin
      Low (1) := 0.0;
      High (1) := 1.0;
      P := (N_Live => 50, Max_Iters => 300, MCMC_Steps => 25,
            Tol => 1.0E-6, Seed => 33, Schedule => Exponential_Shrink,
            Add_Remainder => True, Dim => 1,
            Low => Low, High => High, Proposal_Scale => 0.2);
      R := Run_Nested_Sampling (P, Likelihood_Theta'Access);
      Check (Approx (R.Evidence, 0.5, 0.12), "L=θ Z≈1/2");
   end;

   ---------------------------------------------------------------------
   Section ("14. Remainder option");
   ---------------------------------------------------------------------
   declare
      P_On, P_Off   : Parameters;
      R_On, R_Off   : Result;
      Low, High     : Param_Vector := [others => 0.0];
   begin
      Low (1) := 0.0;
      High (1) := 1.0;
      P_On := (N_Live => 30, Max_Iters => 50, MCMC_Steps => 15,
               Tol => 0.0, Seed => 5, Schedule => Exponential_Shrink,
               Add_Remainder => True, Dim => 1,
               Low => Low, High => High, Proposal_Scale => 0.2);
      P_Off := P_On;
      P_Off.Add_Remainder := False;
      R_On := Run_Nested_Sampling (P_On, Likelihood_Flat'Access);
      R_Off := Run_Nested_Sampling (P_Off, Likelihood_Flat'Access);
      Check (R_On.Remainder > 0.0, "remainder positive when enabled");
      Check (R_Off.Remainder = 0.0, "remainder zero when disabled");
      Check (R_On.Evidence >= R_Off.Evidence - 1.0E-12,
             "Z with remainder >= Z without");
      Check (Approx (R_On.Evidence, R_Off.Evidence + R_On.Remainder, 1.0E-6),
             "Z_on = Z_off + remainder");
   end;

   ---------------------------------------------------------------------
   Section ("15. Seeded run reproducibility");
   ---------------------------------------------------------------------
   declare
      P         : Parameters;
      R1, R2, R3 : Result;
      Low, High : Param_Vector := [others => 0.0];
   begin
      Low (1) := 0.0;
      High (1) := 1.0;
      P := (N_Live => 25, Max_Iters => 60, MCMC_Steps => 10,
            Tol => 1.0E-4, Seed => 777, Schedule => Exponential_Shrink,
            Add_Remainder => True, Dim => 1,
            Low => Low, High => High, Proposal_Scale => 0.2);
      R1 := Run_Nested_Sampling (P, Likelihood_Flat'Access);
      R2 := Run_Nested_Sampling (P, Likelihood_Flat'Access);
      P.Seed := 778;
      R3 := Run_Nested_Sampling (P, Likelihood_Flat'Access);
      Check (R1.Evidence = R2.Evidence, "same seed → same Z");
      Check (R1.Iters = R2.Iters, "same seed → same iters");
      Check (R1.Num_Samples = R2.Num_Samples, "same seed → same samples");
      Check (R3.Iters >= 1, "diff seed runs complete");
      Check (R1.Final_X = R2.Final_X, "same seed → same Final_X");
   end;

   ---------------------------------------------------------------------
   Section ("16. Invalid arguments / capacity");
   ---------------------------------------------------------------------
   declare
      P         : Parameters;
      Low, High : Param_Vector := [others => 0.0];
      Raised    : Boolean;
   begin
      Low (1) := 0.0;
      High (1) := 1.0;
      P := (N_Live => 1, Max_Iters => 10, MCMC_Steps => 5,
            Tol => 1.0E-3, Seed => 1, Schedule => Exponential_Shrink,
            Add_Remainder => True, Dim => 1,
            Low => Low, High => High, Proposal_Scale => 0.1);
      Raised := False;
      begin
         declare
            R : Result;
            pragma Unreferenced (R);
         begin
            R := Run_Nested_Sampling (P, Likelihood_Flat'Access);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "N_Live=1 raises Invalid_Argument");

      P.N_Live := 10;
      P.Dim := 0;
      Raised := False;
      begin
         declare
            R : Result;
            pragma Unreferenced (R);
         begin
            R := Run_Nested_Sampling (P, Likelihood_Flat'Access);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Dim=0 raises Invalid_Argument");

      P.Dim := 1;
      Raised := False;
      begin
         declare
            R : Result;
            pragma Unreferenced (R);
         begin
            R := Run_Nested_Sampling (P, null);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "null likelihood raises Invalid_Argument");

      P.N_Live := Max_Live + 1;
      Raised := False;
      begin
         declare
            R : Result;
            pragma Unreferenced (R);
         begin
            R := Run_Nested_Sampling (P, Likelihood_Flat'Access);
         end;
      exception
         when Capacity_Exceeded =>
            Raised := True;
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "N_Live>Max_Live raises capacity/invalid");
   end;

   ---------------------------------------------------------------------
   Section ("17. Sample weights / Final_X / positive L saved");
   ---------------------------------------------------------------------
   declare
      R         : Result;
      Sum_W     : Real := 0.0;
      Low, High : Param_Vector := [others => 0.0];
      Pos_L     : Boolean := True;
   begin
      Low (1) := 0.0;
      High (1) := 1.0;
      R := Run_Built_In
        (Flat_Unit,
         (N_Live => 20, Max_Iters => 40, MCMC_Steps => 10,
          Tol => 0.0, Seed => 8, Schedule => Exponential_Shrink,
          Add_Remainder => False, Dim => 1,
          Low => Low, High => High, Proposal_Scale => 0.2));
      for I in 1 .. Sample_Index (R.Num_Samples) loop
         Sum_W := Sum_W + R.Samples (I).Weight;
         if R.Samples (I).L < 0.0 then
            Pos_L := False;
         end if;
      end loop;
      Check (R.Num_Samples > 0, "samples recorded");
      Check (Sum_W > 0.0, "sum sample weights > 0");
      Check (Approx (Sum_W + R.Final_X, 1.0, 1.0E-5),
             "sum w + Final_X ≈ 1");
      Check (Pos_L, "all saved L >= 0");
      Check (R.Final_X > 0.0 and then R.Final_X <= 1.0,
             "Final_X in (0,1]");
   end;

   ---------------------------------------------------------------------
   Section ("18. Tol early stop");
   ---------------------------------------------------------------------
   declare
      R_Loose, R_Tight : Result;
      Low, High        : Param_Vector := [others => 0.0];
   begin
      Low (1) := 0.0;
      High (1) := 1.0;
      R_Loose := Run_Built_In
        (Exponential_Unit,
         (N_Live => 40, Max_Iters => 500, MCMC_Steps => 15,
          Tol => 1.0E-2, Seed => 9, Schedule => Exponential_Shrink,
          Add_Remainder => True, Dim => 1,
          Low => Low, High => High, Proposal_Scale => 0.2));
      R_Tight := Run_Built_In
        (Exponential_Unit,
         (N_Live => 40, Max_Iters => 500, MCMC_Steps => 15,
          Tol => 1.0E-8, Seed => 9, Schedule => Exponential_Shrink,
          Add_Remainder => True, Dim => 1,
          Low => Low, High => High, Proposal_Scale => 0.2));
      Check (R_Loose.Iters <= R_Tight.Iters,
             "looser Tol stops no later than tighter");
      Check (R_Loose.Iters < 500, "loose Tol actually stops early");
   end;

   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("========================================");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   Put_Line ("========================================");
   if Fail_Count /= 0 then
      raise Program_Error with
        "Nested_Sampling tests failed:" & Fail_Count'Image;
   end if;
   pragma Assert (Fail_Count = 0);
end Tests;
