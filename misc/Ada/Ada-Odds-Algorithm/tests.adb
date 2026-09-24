--  Standalone test suite for Odds_Algorithm (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Odds_Algorithm; use Odds_Algorithm;

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
   Put_Line ("Odds_Algorithm test suite (Bruss / Wikipedia Odds algorithm)");
   Put_Line ("============================================================");

   ---------------------------------------------------------------------
   Section ("1. Near helper");
   ---------------------------------------------------------------------
   declare
   begin
      Check (Near (1.0, 1.0), "Near identical");
      Check (Near (1.0, 1.0 + 1.0E-9), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Near (0.0, 0.0, 0.0), "Near with zero tol equal");
      Check (not Near (0.0, 1.0E-12, 0.0), "Near zero tol rejects tiny");
   end;

   ---------------------------------------------------------------------
   Section ("2. Odds formula r = p/(1-p)");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
   begin
      Check (Approx (Odds (0.0), 0.0), "Odds(0) = 0");
      Check (Approx (Odds (0.5), 1.0), "Odds(0.5) = 1");
      Check (Approx (Odds (0.25), 1.0 / 3.0), "Odds(0.25) = 1/3");
      Check (Approx (Odds (0.75), 3.0), "Odds(0.75) = 3");
      Check (Approx (Odds (0.1), 0.1 / 0.9), "Odds(0.1) = 1/9");
      Check (Odds (0.9) > Odds (0.5), "Odds monotone in p");
      Raised := False;
      begin
         declare
            Unused : Real;
         begin
            Unused := Odds (1.0);
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
      Check (Raised, "Odds(1) raises Invalid_Argument");
      Raised := False;
      begin
         declare
            Unused : Real;
         begin
            Unused := Odds (-0.1);
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
      Check (Raised, "Odds(-0.1) raises");
      Raised := False;
      begin
         declare
            Unused : Real;
         begin
            Unused := Odds (1.5);
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
      Check (Raised, "Odds(1.5) raises");
   end;

   ---------------------------------------------------------------------
   Section ("3. Small-n hand-worked threshold (uniform 0.5)");
   ---------------------------------------------------------------------
   declare
      P   : constant Probability_Vector := Uniform_P (3, 0.5);
      Res : constant Odds_Result := Compute_Threshold (P);
   begin
      --  r_k = 1; first from end already R=1 => s=3
      Check (Res.Threshold_S = 3, "uniform 0.5 n=3 => s=3");
      Check (Approx (Res.R_Sum, 1.0), "R_s = 1");
      Check (Approx (Res.Q_Product, 0.5), "Q_s = 0.5");
      Check (Approx (Res.Win_Probability, 0.5), "w = 0.5");
      Check (not Res.Had_Sure_Success, "no sure success");
   end;

   ---------------------------------------------------------------------
   Section ("4. Hand-worked: r_4 alone reaches 1");
   ---------------------------------------------------------------------
   declare
      P   : constant Probability_Vector := [0.1, 0.2, 0.4, 0.5];
      Res : constant Odds_Result := Compute_Threshold (P);
   begin
      --  r_4 = 1 >= 1 => s=4, R=1, Q=0.5, w=0.5
      Check (Res.Threshold_S = 4, "p=(.1,.2,.4,.5) => s=4");
      Check (Approx (Res.R_Sum, 1.0), "R = 1");
      Check (Approx (Res.Q_Product, 0.5), "Q = 0.5");
      Check (Approx (Res.Win_Probability, 0.5), "w = Q*R = 0.5");
   end;

   ---------------------------------------------------------------------
   Section ("5. Sum never reaches 1 => s=1");
   ---------------------------------------------------------------------
   declare
      P   : constant Probability_Vector := [0.1, 0.1, 0.1];
      Res : constant Odds_Result := Compute_Threshold (P);
      R1  : constant Real := Odds (0.1);
      Exp_R : constant Real := 3.0 * R1;
      Exp_Q : constant Real := 0.9 ** 3;
   begin
      Check (Res.Threshold_S = 1, "tiny odds => s=1");
      Check (Approx (Res.R_Sum, Exp_R), "R = sum of all odds");
      Check (Approx (Res.Q_Product, Exp_Q), "Q = product all q");
      Check (Approx (Res.Win_Probability, Exp_Q * Exp_R), "w = Q*R");
      Check (Res.R_Sum < 1.0, "R_s < 1 as expected");
   end;

   ---------------------------------------------------------------------
   Section ("6. w = Q*R identity and uniform p=0.3");
   ---------------------------------------------------------------------
   declare
      P   : constant Probability_Vector := Uniform_P (5, 0.3);
      Res : constant Odds_Result := Compute_Threshold (P);
      R_K : constant Real := Odds (0.3);
   begin
      --  Need 3 terms: 3*r ≈ 1.2857 >= 1; 2*r ≈ 0.857 < 1 => s=3
      Check (Res.Threshold_S = 3, "uniform 0.3 n=5 => s=3");
      Check (Approx (Res.R_Sum, 3.0 * R_K), "R = 3*r");
      Check (Approx (Res.Q_Product, 0.7 ** 3), "Q = 0.7^3");
      Check (Approx (Res.Win_Probability, Res.Q_Product * Res.R_Sum),
             "w equals Q*R");
      Check (Res.R_Sum >= 1.0, "R_s >= 1");
   end;

   ---------------------------------------------------------------------
   Section ("7. p_k=0 contributes r=0");
   ---------------------------------------------------------------------
   declare
      P   : constant Probability_Vector := [0.0, 0.5, 0.0, 0.5];
      Res : constant Odds_Result := Compute_Threshold (P);
   begin
      Check (Approx (Odds (0.0), 0.0), "Odds(0)=0 again");
      --  From end: r_4=1 >=1 => s=4
      Check (Res.Threshold_S = 4, "zeros ignored; s=4 from last 0.5");
      Check (Approx (Res.R_Sum, 1.0), "R=1");
      --  Include a case where zeros pad the sum from the end
      declare
         P2  : constant Probability_Vector := [0.4, 0.0, 0.0, 0.4];
         R2  : constant Odds_Result := Compute_Threshold (P2);
         --  r=0.4/0.6≈0.6667; two from end: r4+r3=0.6667+0 <1;
         --  +r2=same; +r1 => R≈1.333, s=1
      begin
         Check (R2.Threshold_S = 1, "zeros do not inflate R; s=1");
         Check (Approx (R2.R_Sum, 2.0 * Odds (0.4)), "R = 2*odds(0.4)");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Should_Stop and Apply_Strategy");
   ---------------------------------------------------------------------
   declare
      Obs : constant Boolean_Array :=
        [False, True, False, True, False];
      --  indices 1..5; interesting at 2 and 4
   begin
      Check (not Should_Stop (1, True, 3), "K < s => no stop");
      Check (not Should_Stop (3, False, 3), "not interesting => no");
      Check (Should_Stop (3, True, 3), "K=s interesting => stop");
      Check (Should_Stop (5, True, 3), "K>s interesting => stop");
      Check (Apply_Strategy (Obs, 1) = 2, "from s=1 stop at first True=2");
      Check (Apply_Strategy (Obs, 3) = 4, "from s=3 stop at 4");
      Check (Apply_Strategy (Obs, 5) = 0, "s=5 none interesting => 0");
      Check (Apply_Strategy (Obs, 2) = 2, "s=2 stops on index 2");
      declare
         None : constant Boolean_Array :=
           [False, False, False];
      begin
         Check (Apply_Strategy (None, 1) = 0, "all false => 0");
         Check (Apply_Strategy (None, 2) = 0, "all false s=2 => 0");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("9. Strategy never stops if no success after s");
   ---------------------------------------------------------------------
   declare
      Obs : constant Boolean_Array :=
        [True, True, False, False, False];
   begin
      Check (Apply_Strategy (Obs, 3) = 0, "successes only before s => 0");
      Check (Apply_Strategy (Obs, 1) = 1, "s=1 stops on first True");
      Check (not Should_Stop (2, False, 1), "False never stops");
   end;

   ---------------------------------------------------------------------
   Section ("10. Invalid arguments raise");
   ---------------------------------------------------------------------
   declare
      Raised : Boolean;
      Empty  : Probability_Vector (1 .. 0);
   begin
      Raised := False;
      begin
         declare
            Unused : Odds_Result;
         begin
            Unused := Compute_Threshold (Empty);
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
      Check (Raised, "empty P raises");

      Raised := False;
      begin
         declare
            Bad : constant Probability_Vector := [0.2, 1.5, 0.1];
            Unused : Odds_Result;
         begin
            Unused := Compute_Threshold (Bad);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "p_k > 1 raises");

      Raised := False;
      begin
         declare
            Bad : constant Probability_Vector := [0.2, -0.1, 0.1];
            Unused : Odds_Result;
         begin
            Unused := Compute_Threshold (Bad);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            null;
      end;
      Check (Raised, "p_k < 0 raises");

      Raised := False;
      begin
         declare
            Unused : Probability_Vector := Uniform_P (2, 1.0);
         begin
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
      Check (Raised, "Uniform_P with p=1 raises");
   end;

   ---------------------------------------------------------------------
   Section ("11. Sure success p_k=1 special handling");
   ---------------------------------------------------------------------
   declare
      P   : constant Probability_Vector := [0.2, 1.0, 0.3];
      Res : constant Odds_Result := Compute_Threshold (P);
   begin
      --  From end: r_3≈0.428 <1; r_3+Huge >=1 => s=2
      Check (Res.Had_Sure_Success, "detects sure success");
      Check (Res.Threshold_S = 2, "sure at 2 forces s<=2");
      Check (Res.R_Sum >= 1.0, "R includes Huge_Odds");
      Check (Approx (Res.Q_Product, 0.0), "Q=0 when q_s*=0");
   end;

   ---------------------------------------------------------------------
   Section ("12. Secretary record probs; s/n ≈ 1/e for large n");
   ---------------------------------------------------------------------
   declare
      N100 : constant Positive := 100;
      P100 : constant Probability_Vector :=
        Secretary_Record_Probabilities (N100);
      R100 : constant Odds_Result := Compute_Threshold (P100);
      Ratio : constant Real := Real (R100.Threshold_S) / Real (N100);
      N10  : constant Positive := 10;
      P10  : constant Probability_Vector :=
        Secretary_Record_Probabilities (N10);
      R10  : constant Odds_Result := Compute_Threshold (P10);
   begin
      Check (Approx (P100 (1), 1.0), "record p_1 = 1");
      Check (Approx (P100 (2), 0.5), "record p_2 = 1/2");
      Check (Approx (P100 (100), 0.01), "record p_100 = 1/100");
      Check (Approx (P10 (5), 0.2), "record p_5 = 1/5");
      --  Classical secretary: s ≈ n/e ≈ 0.3679 n
      Check (Ratio > 0.30 and then Ratio < 0.45,
             "n=100: s/n in (0.30, 0.45) near 1/e");
      Check (R100.R_Sum >= 1.0, "secretary n=100 R_s >= 1");
      Check (R100.Win_Probability >= One_Over_E - 0.02,
             "secretary n=100 w near >= 1/e");
      Check (R10.Threshold_S <= 10,
             "n=10 threshold in range");
      --  Spot-check: for records, r_k = 1/(k-1) for k>=2
      Check (Approx (Odds (P10 (3)), 0.5), "Odds(1/3)=1/2");
   end;

   ---------------------------------------------------------------------
   Section ("13. Odds theorem: w >= 1/e when R_s >= 1");
   ---------------------------------------------------------------------
   declare
      F1 : constant Probability_Vector := [0.5, 0.5, 0.5, 0.5];
      F2 : constant Probability_Vector := [0.2, 0.3, 0.4, 0.5];
      F3 : constant Probability_Vector := [0.1, 0.2, 0.3, 0.8];
      F4 : constant Probability_Vector := Uniform_P (4, 0.4);
      F5 : constant Probability_Vector := [0.05, 0.15, 0.25, 0.35];
      All_Ok : Boolean := True;

      procedure Check_Fixture (F : Probability_Vector; Label : String) is
         Res : constant Odds_Result := Compute_Threshold (F);
      begin
         if Res.R_Sum >= 1.0 then
            if Res.Win_Probability + 1.0E-9 < One_Over_E then
               All_Ok := False;
            end if;
            Check (Res.Win_Probability >= One_Over_E - 1.0E-9,
                   Label & " w >= 1/e");
         else
            Check (True, Label & " R<1 skip bound (vacuous)");
         end if;
      end Check_Fixture;
   begin
      Check_Fixture (F1, "F1");
      Check_Fixture (F2, "F2");
      Check_Fixture (F3, "F3");
      Check_Fixture (F4, "F4");
      Check_Fixture (F5, "F5");
      Check (All_Ok, "all R>=1 fixtures satisfy w >= 1/e");
      --  Single-step that just hits R=1
      declare
         P : constant Probability_Vector := [0.5];
         R : constant Odds_Result := Compute_Threshold (P);
      begin
         Check (Approx (R.R_Sum, 1.0), "n=1 p=0.5 R=1");
         Check (R.Win_Probability >= One_Over_E - 1.0E-6
                  or else Approx (R.Win_Probability, 0.5),
                "n=1 w=0.5 >= 1/e");
         Check (Approx (R.Win_Probability, 0.5), "n=1 exact w=0.5");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("14. Monte Carlo win rate ≈ w");
   ---------------------------------------------------------------------
   declare
      P    : constant Probability_Vector := Uniform_P (4, 0.4);
      Res  : constant Odds_Result := Compute_Threshold (P);
      Emp  : constant Real :=
        Simulate_Win_Rate (P, Res.Threshold_S, 20_000, Seed => 42);
      Tol  : constant Real := 0.03;
   begin
      Check (Res.R_Sum >= 1.0, "MC fixture R>=1");
      Check (Approx (Emp, Res.Win_Probability, Tol),
             "MC win rate within 0.03 of w");
      Check (Emp > 0.2 and then Emp < 0.8, "MC rate in plausible band");
   end;

   declare
      P2   : constant Probability_Vector := [0.5, 0.5, 0.5];
      Res2 : constant Odds_Result := Compute_Threshold (P2);
      Emp2 : constant Real :=
        Simulate_Win_Rate (P2, Res2.Threshold_S, 15_000, Seed => 7);
   begin
      Check (Res2.Threshold_S = 3, "MC2 s=3");
      Check (Approx (Emp2, Res2.Win_Probability, 0.035),
             "MC2 win rate ≈ 0.5");
   end;

   ---------------------------------------------------------------------
   Section ("15. Uniform_P and single-element edge cases");
   ---------------------------------------------------------------------
   declare
      U : constant Probability_Vector := Uniform_P (1, 0.0);
      R : constant Odds_Result := Compute_Threshold (U);
   begin
      Check (U'Length = 1, "Uniform_P n=1 length");
      Check (Approx (U (1), 0.0), "Uniform_P value 0");
      Check (R.Threshold_S = 1, "p=0 alone => s=1");
      Check (Approx (R.R_Sum, 0.0), "R=0");
      Check (Approx (R.Win_Probability, 0.0), "w=0 (never succeeds)");
   end;
   declare
      U2 : constant Probability_Vector := Uniform_P (6, 0.25);
   begin
      Check (U2'Length = 6, "Uniform_P n=6");
      Check (Approx (U2 (3), 0.25), "Uniform_P mid entry");
      Check (Approx (U2 (6), 0.25), "Uniform_P last entry");
   end;

   ---------------------------------------------------------------------
   Section ("16. Apply_Strategy with threshold past last");
   ---------------------------------------------------------------------
   declare
      Obs : constant Boolean_Array := [True, True, True];
   begin
      --  Threshold_S > Last is allowed by Should_Stop logic via Apply
      Check (Apply_Strategy (Obs, 4) = 0, "s past end => never stop");
      Check (Apply_Strategy (Obs, 3) = 3, "s=last stops if interesting");
   end;

   ---------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------
   New_Line;
   Put_Line ("============================================================");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   pragma Assert (Fail_Count = 0);
   Put_Line ("All tests passed.");
end Tests;
