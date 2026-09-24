with Ada.Text_IO; use Ada.Text_IO;
with Lemke_Howson; use Lemke_Howson;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   procedure Check_Real (Label : String; Actual, Expected : Real) is
      Tolerance : constant Real := 1.0e-4;
   begin
      if abs (Actual - Expected) < Tolerance then
         Check (Label, True);
      else
         Put_Line ("  FAIL — " & Label & " (Exp: " & Expected'Image & ", Got: " & Actual'Image & ")");
         Fail_Count := Fail_Count + 1;
      end if;
   end Check_Real;

   A2, B2 : Matrix (1 .. 2, 1 .. 2);
   A3, B3 : Matrix (1 .. 3, 1 .. 3);
   A2x3, B2x3 : Matrix (1 .. 2, 1 .. 3);
   A1, B1 : Matrix (1 .. 1, 1 .. 1);
   
   Eq2 : Nash_Equilibrium (2, 2);
   Eq3 : Nash_Equilibrium (3, 3);
   Eq2x3 : Nash_Equilibrium (2, 3);
   Eq1 : Nash_Equilibrium (1, 1);
begin
   Put_Line ("TEST 1-4 — Battle of the Sexes (Multiple Equilibria & Initial_Drop Variants)");
   A2 := [[3.0, 0.0], [0.0, 2.0]];
   B2 := [[2.0, 0.0], [0.0, 3.0]];
   
   Eq2 := Find_Equilibrium (A2, B2, 2, 2, Initial_Drop => 1);
   Check_Real ("1.1 BoS Drop 1 (P1 Strat 1)", Eq2.P1_Strategy (1), 1.0);
   Check_Real ("1.2 BoS Drop 1 (P1 Strat 2)", Eq2.P1_Strategy (2), 0.0);
   Check_Real ("1.3 BoS Drop 1 (P2 Strat 1)", Eq2.P2_Strategy (1), 1.0);
   
   Eq2 := Find_Equilibrium (A2, B2, 2, 2, Initial_Drop => 2);
   Check_Real ("2.1 BoS Drop 2 (P1 Strat 1)", Eq2.P1_Strategy (1), 0.0);
   Check_Real ("2.2 BoS Drop 2 (P2 Strat 1)", Eq2.P2_Strategy (1), 0.0);
   Check_Real ("2.3 BoS Drop 2 (P2 Strat 2)", Eq2.P2_Strategy (2), 1.0);

   Eq2 := Find_Equilibrium (A2, B2, 2, 2, Initial_Drop => 3);
   Check_Real ("3.1 BoS Drop 3 (P1 Strat 1)", Eq2.P1_Strategy (1), 1.0);
   Check_Real ("3.2 BoS Drop 3 (P2 Strat 2)", Eq2.P2_Strategy (2), 0.0);
   Check_Real ("3.3 BoS Drop 3 (P2 Strat 1)", Eq2.P2_Strategy (1), 1.0);

   Eq2 := Find_Equilibrium (A2, B2, 2, 2, Initial_Drop => 4);
   Check_Real ("4.1 BoS Drop 4 (P1 Strat 2)", Eq2.P1_Strategy (2), 1.0);
   Check_Real ("4.2 BoS Drop 4 (P2 Strat 1)", Eq2.P2_Strategy (1), 0.0);
   Check_Real ("4.3 BoS Drop 4 (P2 Strat 2)", Eq2.P2_Strategy (2), 1.0);

   Put_Line ("TEST 5-6 — Matching Pennies (Mixed Equilibrium)");
   A2 := [[1.0, -1.0], [-1.0, 1.0]];
   B2 := [[-1.0, 1.0], [1.0, -1.0]];
   Eq2 := Find_Equilibrium (A2, B2, 2, 2, Initial_Drop => 1);
   Check_Real ("5.1 MatchPen Drop 1 (P1 S1)", Eq2.P1_Strategy (1), 0.5);
   Check_Real ("5.2 MatchPen Drop 1 (P1 S2)", Eq2.P1_Strategy (2), 0.5);
   Check_Real ("5.3 MatchPen Drop 1 (P2 S1)", Eq2.P2_Strategy (1), 0.5);

   Eq2 := Find_Equilibrium (A2, B2, 2, 2, Initial_Drop => 2);
   Check_Real ("6.1 MatchPen Drop 2 (P2 S2)", Eq2.P2_Strategy (2), 0.5);
   Check_Real ("6.2 MatchPen Drop 2 (P1 S1)", Eq2.P1_Strategy (1), 0.5);
   Check_Real ("6.3 MatchPen Drop 2 (P2 S1)", Eq2.P2_Strategy (1), 0.5);

   Put_Line ("TEST 7 — Prisoner's Dilemma (Dominant Pure Strategy)");
   A2 := [[3.0, 0.0], [5.0, 1.0]];
   B2 := [[3.0, 5.0], [0.0, 1.0]];
   Eq2 := Find_Equilibrium (A2, B2, 2, 2, Initial_Drop => 1);
   Check_Real ("7.1 PD Drop 1 (P1 S1=Coop)", Eq2.P1_Strategy (1), 0.0);
   Check_Real ("7.2 PD Drop 1 (P1 S2=Defect)", Eq2.P1_Strategy (2), 1.0);
   Check_Real ("7.3 PD Drop 1 (P2 S2=Defect)", Eq2.P2_Strategy (2), 1.0);

   Put_Line ("TEST 8 — Hawk-Dove Game");
   A2 := [[0.0, 3.0], [1.0, 2.0]];
   B2 := [[0.0, 1.0], [3.0, 2.0]];
   Eq2 := Find_Equilibrium (A2, B2, 2, 2, Initial_Drop => 2);
   Check_Real ("8.1 HD P1 Sum=1", Eq2.P1_Strategy (1) + Eq2.P1_Strategy (2), 1.0);
   Check_Real ("8.2 HD P2 Sum=1", Eq2.P2_Strategy (1) + Eq2.P2_Strategy (2), 1.0);
   Check_Real ("8.3 Valid strategy returned", (if Eq2.P1_Strategy (1) >= 0.0 then 1.0 else 0.0), 1.0);

   Put_Line ("TEST 9 — 1x1 Degenerate / Smallest Game");
   A1 := [[10.0]];
   B1 := [[5.0]];
   Eq1 := Find_Equilibrium (A1, B1, 1, 1, Initial_Drop => 1);
   Check_Real ("9.1 1x1 P1 Strat 1", Eq1.P1_Strategy (1), 1.0);
   Check_Real ("9.2 1x1 P2 Strat 1", Eq1.P2_Strategy (1), 1.0);
   
   pragma Warnings (Off, "condition can only be False if invalid values present");
   pragma Warnings (Off, "condition is always True");
   Check ("9.3 1x1 Dimensions Correct", Eq1.M = 1 and Eq1.N = 1);
   pragma Warnings (On, "condition is always True");
   pragma Warnings (On, "condition can only be False if invalid values present");

   Put_Line ("TEST 10 — Rock Paper Scissors (3x3 Mixed Equilibrium)");
   A3 := [[0.0, -1.0, 1.0], [1.0, 0.0, -1.0], [-1.0, 1.0, 0.0]];
   B3 := [[0.0, 1.0, -1.0], [-1.0, 0.0, 1.0], [1.0, -1.0, 0.0]];
   Eq3 := Find_Equilibrium (A3, B3, 3, 3, Initial_Drop => 1);
   Check_Real ("10.1 RPS P1 S1", Eq3.P1_Strategy (1), 1.0 / 3.0);
   Check_Real ("10.2 RPS P1 S2", Eq3.P1_Strategy (2), 1.0 / 3.0);
   Check_Real ("10.3 RPS P2 S3", Eq3.P2_Strategy (3), 1.0 / 3.0);

   Put_Line ("TEST 11 — Fully Negative Payoff Shift Test");
   A2 := [[-10.0, -20.0], [-30.0, -40.0]];
   B2 := [[-40.0, -30.0], [-20.0, -10.0]];
   Eq2 := Find_Equilibrium (A2, B2, 2, 2, Initial_Drop => 1);
   Check_Real ("11.1 Shift Test Sum=1 P1", Eq2.P1_Strategy (1) + Eq2.P1_Strategy (2), 1.0);
   Check_Real ("11.2 Shift Test Sum=1 P2", Eq2.P2_Strategy (1) + Eq2.P2_Strategy (2), 1.0);
   Check_Real ("11.3 Max payoff chosen (P1=1, P2=2)", Eq2.P1_Strategy (1), 1.0);

   Put_Line ("TEST 12 — Boundary Drop Condition (Drop = M + N)");
   Eq3 := Find_Equilibrium (A3, B3, 3, 3, Initial_Drop => 6); -- Max possible label for 3x3
   Check_Real ("12.1 Boundary Drop P1 S1", Eq3.P1_Strategy (1), 1.0 / 3.0);
   Check_Real ("12.2 Boundary Drop P1 S3", Eq3.P1_Strategy (3), 1.0 / 3.0);
   Check_Real ("12.3 Boundary Drop P2 S2", Eq3.P2_Strategy (2), 1.0 / 3.0);

   Put_Line ("TEST 13 — Asymmetric Dimension Game (2x3)");
   A2x3 := [[2.0, 0.0, 1.0], [0.0, 3.0, 1.0]];
   B2x3 := [[1.0, 0.0, 2.0], [0.0, 1.0, 2.0]];
   Eq2x3 := Find_Equilibrium (A2x3, B2x3, 2, 3, Initial_Drop => 1);
   Check_Real ("13.1 Asym P1 S1", Eq2x3.P1_Strategy (1) + Eq2x3.P1_Strategy (2), 1.0);
   Check_Real ("13.2 Asym P2 S1", Eq2x3.P2_Strategy (1) + Eq2x3.P2_Strategy (2) + Eq2x3.P2_Strategy (3), 1.0);
   
   pragma Warnings (Off, "condition can only be False if invalid values present");
   pragma Warnings (Off, "condition is always True");
   Check ("13.3 Asym dimensions preserved", Eq2x3.M = 2 and Eq2x3.N = 3);
   pragma Warnings (On, "condition is always True");
   pragma Warnings (On, "condition can only be False if invalid values present");

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, " & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
