-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Lemke_Howson; use Lemke_Howson;

procedure Tests is

   -- Validation Helper: Verifies mathematically if a profile is a valid Nash Equilibrium.
   procedure Assert_Is_Nash_Equilibrium
     (A, B : Matrix; Eq : Equilibrium; Test_Name : String)
   is
      Epsilon : constant Real := 1.0e-3;
      M : constant Positive := A'Length (1);
      N : constant Positive := A'Length (2);
      
      P1_Payoffs : Vector (1 .. M) := (others => 0.0);
      P2_Payoffs : Vector (1 .. N) := (others => 0.0);
      
      Max_P1_Payoff : Real := -1.0e9;
      Max_P2_Payoff : Real := -1.0e9;
   begin
      -- Calculate expected payoffs for pure strategies of P1
      for I in 1 .. M loop
         for J in 1 .. N loop
            P1_Payoffs (I) := P1_Payoffs (I) + (A (I, J) * Eq.P2 (J));
         end loop;
         if P1_Payoffs (I) > Max_P1_Payoff then Max_P1_Payoff := P1_Payoffs (I); end if;
      end loop;

      -- Validate P1's mixed strategy
      for I in 1 .. M loop
         if Eq.P1 (I) > Epsilon then
            Assert (abs (P1_Payoffs (I) - Max_P1_Payoff) < Epsilon,
                    "P1 plays sub-optimal strategy " & Integer'Image(I) & " in " & Test_Name);
         end if;
      end loop;

      -- Calculate expected payoffs for pure strategies of P2
      for J in 1 .. N loop
         for I in 1 .. M loop
            P2_Payoffs (J) := P2_Payoffs (J) + (B (I, J) * Eq.P1 (I));
         end loop;
         if P2_Payoffs (J) > Max_P2_Payoff then Max_P2_Payoff := P2_Payoffs (J); end if;
      end loop;

      -- Validate P2's mixed strategy
      for J in 1 .. N loop
         if Eq.P2 (J) > Epsilon then
            Assert (abs (P2_Payoffs (J) - Max_P2_Payoff) < Epsilon,
                    "P2 plays sub-optimal strategy " & Integer'Image(J) & " in " & Test_Name);
         end if;
      end loop;
   end Assert_Is_Nash_Equilibrium;

begin
   Put_Line ("Starting Lemke-Howson V&V Test Suite...");
   Put_Line ("Assuming code is BROKEN. A PASS means the algorithm disproved the assumption.");
   Put_Line ("------------------------------------------------------");

   -- TEST 1
   Put_Line ("TEST 1 - Matching Pennies (Standard 2x2)");
   Put_Line ("  1.1 Assert output computes mathematically valid Nash Equilibrium");
   declare
      A : constant Matrix (1..2, 1..2) := ((1.0, -1.0), (-1.0, 1.0));
      B : constant Matrix (1..2, 1..2) := ((-1.0, 1.0), (1.0, -1.0));
      Eq : constant Equilibrium := Solve (A, B);
   begin
      Assert_Is_Nash_Equilibrium (A, B, Eq, "Matching Pennies");
      Put_Line ("      PASS");
   end;

   -- TEST 2
   Put_Line ("TEST 2 - Battle of the Sexes");
   Put_Line ("  2.1 Assert finds valid equilibrium with dropped label 1");
   declare
      A : constant Matrix (1..2, 1..2) := ((3.0, 0.0), (0.0, 2.0));
      B : constant Matrix (1..2, 1..2) := ((2.0, 0.0), (0.0, 3.0));
      Eq : constant Equilibrium := Solve (A, B, Dropped_Label => 1);
   begin
      Assert_Is_Nash_Equilibrium (A, B, Eq, "Battle of Sexes (Drop 1)");
      Put_Line ("      PASS");
   end;

   -- TEST 3
   Put_Line ("TEST 3 - Variant Execution: Battle of the Sexes (Alternative Drop)");
   Put_Line ("  3.1 Assert dropping label 2 still results in a valid equilibrium");
   declare
      A : constant Matrix (1..2, 1..2) := ((3.0, 0.0), (0.0, 2.0));
      B : constant Matrix (1..2, 1..2) := ((2.0, 0.0), (0.0, 3.0));
      Eq : constant Equilibrium := Solve (A, B, Dropped_Label => 2);
   begin
      Assert_Is_Nash_Equilibrium (A, B, Eq, "Battle of Sexes (Drop 2)");
      Put_Line ("      PASS");
   end;

   -- TEST 4
   Put_Line ("TEST 4 - Prisoner's Dilemma (Pure Strategy NE)");
   Put_Line ("  4.1 Assert convergence to pure defect strategy");
   declare
      A : constant Matrix (1..2, 1..2) := ((-1.0, -3.0), (0.0, -2.0));
      B : constant Matrix (1..2, 1..2) := ((-1.0, 0.0), (-3.0, -2.0));
      Eq : constant Equilibrium := Solve (A, B);
   begin
      Assert_Is_Nash_Equilibrium (A, B, Eq, "Prisoner's Dilemma");
      Put_Line ("      PASS");
   end;

   -- TEST 5
   Put_Line ("TEST 5 - Negative Values Normalization");
   Put_Line ("  5.1 Assert algorithm safely normalizes deeply negative payoff matrix");
   declare
      A : constant Matrix (1..2, 1..2) := ((-100.0, -50.0), (-20.0, -90.0));
      B : constant Matrix (1..2, 1..2) := ((-90.0, -100.0), (-50.0, -20.0));
      Eq : constant Equilibrium := Solve (A, B);
   begin
      Assert_Is_Nash_Equilibrium (A, B, Eq, "Negative Values");
      Put_Line ("      PASS");
   end;

   -- TEST 6
   Put_Line ("TEST 6 - Zero Payoffs Edge Case");
   Put_Line ("  6.1 Assert matrix of pure zeros returns uniform/valid equilibrium");
   declare
      A : constant Matrix (1..2, 1..2) := ((0.0, 0.0), (0.0, 0.0));
      B : constant Matrix (1..2, 1..2) := ((0.0, 0.0), (0.0, 0.0));
      Eq : constant Equilibrium := Solve (A, B);
   begin
      Assert_Is_Nash_Equilibrium (A, B, Eq, "Zero Payoffs");
      Put_Line ("      PASS");
   end;

   -- TEST 7
   Put_Line ("TEST 7 - Rock-Paper-Scissors (3x3 Matrix)");
   Put_Line ("  7.1 Assert scales to larger symmetric dimensions (3x3)");
   declare
      A : constant Matrix (1..3, 1..3) := ((0.0, -1.0, 1.0), (1.0, 0.0, -1.0), (-1.0, 1.0, 0.0));
      B : constant Matrix (1..3, 1..3) := ((0.0, 1.0, -1.0), (-1.0, 0.0, 1.0), (1.0, -1.0, 0.0));
      Eq : constant Equilibrium := Solve (A, B);
   begin
      Assert_Is_Nash_Equilibrium (A, B, Eq, "Rock-Paper-Scissors");
      Put_Line ("      PASS");
   end;

   -- TEST 8
   Put_Line ("TEST 8 - Asymmetric Dimensions (2x3)");
   Put_Line ("  8.1 Assert functions mathematically correct on uneven games");
   declare
      A : constant Matrix (1..2, 1..3) := ((3.0, 1.0, 2.0), (1.0, 3.0, 2.0));
      B : constant Matrix (1..2, 1..3) := ((1.0, 3.0, 2.0), (3.0, 1.0, 2.0));
      Eq : constant Equilibrium := Solve (A, B);
   begin
      Assert_Is_Nash_Equilibrium (A, B, Eq, "Asymmetric 2x3");
      Put_Line ("      PASS");
   end;

   -- TEST 9
   Put_Line ("TEST 9 - Invalid Input: Empty Matrix");
   Put_Line ("  9.1 Assert throws Invalid_Input on zero rows");
   begin
      declare
         A : constant Matrix (1..0, 1..2) := (others => (others => 0.0));
         B : constant Matrix (1..0, 1..2) := (others => (others => 0.0));
         Eq : Equilibrium := Solve (A, B);
      begin
         Assert (False, "Failed to catch empty matrix");
      end;
   exception
      when Invalid_Input => Put_Line ("      PASS");
   end;

   -- TEST 10
   Put_Line ("TEST 10 - Invalid Input: Dimensional Mismatch");
   Put_Line ("  10.1 Assert throws Invalid_Input when A and B differ in shape");
   begin
      declare
         A : constant Matrix (1..2, 1..2) := (others => (others => 0.0));
         B : constant Matrix (1..3, 1..2) := (others => (others => 0.0));
         Eq : Equilibrium := Solve (A, B);
      begin
         Assert (False, "Failed to catch dimension mismatch");
      end;
   exception
      when Invalid_Input => Put_Line ("      PASS");
   end;

   -- TEST 11
   Put_Line ("TEST 11 - Invalid Input: Invalid Dropped Label Range");
   Put_Line ("  11.1 Assert throws Invalid_Input for Label > M+N");
   begin
      declare
         A : constant Matrix (1..2, 1..2) := ((1.0, 1.0), (1.0, 1.0));
         B : constant Matrix (1..2, 1..2) := ((1.0, 1.0), (1.0, 1.0));
         Eq : Equilibrium := Solve (A, B, Dropped_Label => 5);
      begin
         Assert (False, "Failed to catch out-of-bounds Dropped_Label");
      end;
   exception
      when Invalid_Input => Put_Line ("      PASS");
   end;

   -- TEST 12
   Put_Line ("TEST 12 - Large Numeric Stability");
   Put_Line ("  12.1 Assert pivoting remains stable with very large floats");
   declare
      A : constant Matrix (1..2, 1..2) := ((1.0e6, -1.0e6), (-1.0e6, 1.0e6));
      B : constant Matrix (1..2, 1..2) := ((-1.0e6, 1.0e6), (1.0e6, -1.0e6));
      Eq : constant Equilibrium := Solve (A, B);
   begin
      Assert_Is_Nash_Equilibrium (A, B, Eq, "Large Numbers");
      Put_Line ("      PASS");
   end;

   -- TEST 13
   Put_Line ("TEST 13 - Micro Numeric Stability");
   Put_Line ("  13.1 Assert pivoting remains stable with extremely small fractions");
   declare
      A : constant Matrix (1..2, 1..2) := ((1.0e-6, -1.0e-6), (-1.0e-6, 1.0e-6));
      B : constant Matrix (1..2, 1..2) := ((-1.0e-6, 1.0e-6), (1.0e-6, -1.0e-6));
      Eq : constant Equilibrium := Solve (A, B);
   begin
      Assert_Is_Nash_Equilibrium (A, B, Eq, "Small Numbers");
      Put_Line ("      PASS");
   end;

   -- TEST 14
   Put_Line ("TEST 14 - Trivial Game (1x1)");
   Put_Line ("  14.1 Assert algorithm processes the lowest dimensional limit gracefully");
   declare
      A : constant Matrix (1..1, 1..1) := (1 => (1 => 1.0));
      B : constant Matrix (1..1, 1..1) := (1 => (1 => 1.0));
      Eq : constant Equilibrium := Solve (A, B);
   begin
      Assert_Is_Nash_Equilibrium (A, B, Eq, "1x1 Limit");
      Put_Line ("      PASS");
   end;

   -- TEST 15
   Put_Line ("TEST 15 - Dropped Label Crossing Matrix Boundary");
   Put_Line ("  15.1 Assert dropping a label from Player 2's strategy space works (M < Lbl <= M+N)");
   declare
      A : constant Matrix (1..2, 1..2) := ((3.0, 0.0), (0.0, 2.0));
      B : constant Matrix (1..2, 1..2) := ((2.0, 0.0), (0.0, 3.0));
      Eq : constant Equilibrium := Solve (A, B, Dropped_Label => 3);
   begin
      Assert_Is_Nash_Equilibrium (A, B, Eq, "Battle of Sexes (Drop 3)");
      Put_Line ("      PASS");
   end;

   Put_Line ("------------------------------------------------------");
   Put_Line ("ALL TESTS COMPLETED SUCCESSFULLY.");
end Tests;
