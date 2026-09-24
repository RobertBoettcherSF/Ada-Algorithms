-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Regret_Theory; use Regret_Theory;

procedure Tests is
   M_Payoff : constant Matrix (1 .. 2, 1 .. 2) := ((10.0, 5.0), 
                                                   (8.0, 15.0));
   M_Cost   : constant Matrix (1 .. 2, 1 .. 2) := ((10.0, 5.0), 
                                                   (8.0, 15.0));
   Regrets  : Matrix (1 .. 2, 1 .. 2);
   Best     : Positive;
   Val      : Payoff_Value;

begin
   Put_Line ("Starting V&V Regret Theory Test Suite");
   Put_Line ("Assuming code is broken - Tests PASS when assumption is disproved.");
   Put_Line ("------------------------------------------------------");

   -- TEST 1
   Put_Line ("TEST 1 - Regret Matrix from Payoffs (Maximize)");
   Put_Line ("  1.1 Assert correct regret values calculated per state");
   Regrets := Regret_From_Payoffs (M_Payoff);
   Assert (Regrets (1, 1) = 0.0 and Regrets (2, 1) = 2.0, "State 1 regrets failed");
   Put_Line ("      PASS");
   Put_Line ("  1.2 Assert state 2 correctly calculates opportunity loss");
   Assert (Regrets (1, 2) = 10.0 and Regrets (2, 2) = 0.0, "State 2 regrets failed");
   Put_Line ("      PASS");

   -- TEST 2
   Put_Line ("TEST 2 - Regret Matrix from Costs (Minimize)");
   Put_Line ("  2.1 Assert lowest cost evaluates to 0 regret");
   Regrets := Regret_From_Costs (M_Cost);
   Assert (Regrets (2, 1) = 0.0 and Regrets (1, 2) = 0.0, "Zero cost regrets failed");
   Put_Line ("      PASS");

   -- TEST 3
   Put_Line ("TEST 3 - Minimax Regret Decision Execution (Payoff)");
   Put_Line ("  3.1 Assert the correct action is chosen to minimize max regret");
   Regrets := Regret_From_Payoffs (M_Payoff);
   Minimax_Regret (Regrets, Best, Val);
   Assert (Best = 2, "Wrong action chosen");
   Put_Line ("      PASS");
   Put_Line ("  3.2 Assert the correct minimax value is returned");
   Assert (Val = 2.0, "Wrong minimax value");
   Put_Line ("      PASS");

   -- TEST 4
   Put_Line ("TEST 4 - Minimax Regret Decision Execution (Cost)");
   Put_Line ("  4.1 Assert minimization of cost variant selects right action");
   Regrets := Regret_From_Costs (M_Cost);
   Minimax_Regret (Regrets, Best, Val);
   Assert (Best = 1, "Cost minimax logic failed");
   Put_Line ("      PASS");

   -- TEST 5
   Put_Line ("TEST 5 - Edge Case: 1x1 Matrix");
   Put_Line ("  5.1 Assert 1x1 resolves to action 1 with 0 regret");
   declare
      Mat : constant Matrix (1 .. 1, 1 .. 1) := (1 => (1 => 42.0));
   begin
      Minimax_Regret (Regret_From_Payoffs (Mat), Best, Val);
      Assert (Best = 1 and Val = 0.0, "1x1 case failed");
      Put_Line ("      PASS");
   end;

   -- TEST 6
   Put_Line ("TEST 6 - Edge Case: 1 Action, Multiple States");
   Put_Line ("  6.1 Assert regret is always 0 when there's no alternative");
   declare
      Mat : constant Matrix (1 .. 1, 1 .. 3) := (1 => (10.0, 20.0, 30.0));
   begin
      Minimax_Regret (Regret_From_Payoffs (Mat), Best, Val);
      Assert (Val = 0.0, "1xN matrix should have 0 regret");
      Put_Line ("      PASS");
   end;

   -- TEST 7
   Put_Line ("TEST 7 - Edge Case: Multiple Actions, 1 State");
   Put_Line ("  7.1 Assert best action correlates directly to max payoff");
   declare
      Mat : constant Matrix (1 .. 3, 1 .. 1) := ((1 => 10.0), (1 => 50.0), (1 => 20.0));
   begin
      Minimax_Regret (Regret_From_Payoffs (Mat), Best, Val);
      Assert (Best = 2, "Nx1 matrix decision failed");
      Put_Line ("      PASS");
   end;

   -- TEST 8
   Put_Line ("TEST 8 - Error Handling: Empty Matrix");
   Put_Line ("  8.1 Assert Empty_Matrix_Error raised for empty rows/cols");
   begin
      declare
         Empty_Mat : Matrix (1 .. 0, 1 .. 1);
         Dummy     : Matrix (1 .. 0, 1 .. 1);
      begin
         Dummy := Regret_From_Payoffs (Empty_Mat);
         Assert (False, "Exception not raised");
      end;
   exception
      when Empty_Matrix_Error =>
         Put_Line ("      PASS");
   end;

   -- TEST 9
   Put_Line ("TEST 9 - Logic Robustness: Tie-breaking");
   Put_Line ("  9.1 Assert first occurrence is returned during ties");
   declare
      Mat : constant Matrix (1 .. 2, 1 .. 2) := ((10.0, 10.0), (10.0, 10.0));
   begin
      Minimax_Regret (Regret_From_Payoffs (Mat), Best, Val);
      Assert (Best = 1, "Tie break did not favor first index");
      Put_Line ("      PASS");
   end;

   -- TEST 10
   Put_Line ("TEST 10 - Data Integrity: Negative Payoffs (Debt)");
   Put_Line ("  10.1 Assert negative numbers correctly evaluate regret magnitude");
   declare
      Mat : constant Matrix (1 .. 2, 1 .. 1) := ((1 => -10.0), 
                                                 (1 => -5.0));
      -- Dynamically sized to match Mat's result to avoid constraint errors
      Test_Regrets : constant Matrix := Regret_From_Payoffs (Mat);
   begin
      Assert (Test_Regrets (1, 1) = 5.0 and Test_Regrets (2, 1) = 0.0, "Negative regrets miscalculated");
      Put_Line ("      PASS");
   end;

   -- TEST 11
   Put_Line ("TEST 11 - Data Integrity: All Zeros");
   Put_Line ("  11.1 Assert zero-matrix returns zero-regret");
   declare
      Mat : constant Matrix (1 .. 2, 1 .. 2) := ((0.0, 0.0), (0.0, 0.0));
   begin
      Minimax_Regret (Regret_From_Payoffs (Mat), Best, Val);
      Assert (Val = 0.0, "Zero matrix failure");
      Put_Line ("      PASS");
   end;

   -- TEST 12
   Put_Line ("TEST 12 - Data Integrity: Non-Standard Array Bounds");
   Put_Line ("  12.1 Assert dynamic bounds (e.g. 5..6) are strictly handled");
   declare
      Mat : constant Matrix (5 .. 6, 8 .. 9) := ((10.0, 5.0), (8.0, 15.0));
   begin
      Minimax_Regret (Regret_From_Payoffs (Mat), Best, Val);
      Assert (Best = 6, "Dynamic bounds offset failure");
      Put_Line ("      PASS");
   end;

   -- TEST 13
   Put_Line ("TEST 13 - Core Invariant: Optimal choice regret is exactly 0");
   Put_Line ("  13.1 Assert the state's best choice ALWAYS yields 0.0 regret");
   declare
      Mat : constant Matrix (1 .. 2, 1 .. 2) := ((100.0, 20.0), (30.0, 400.0));
   begin
      Regrets := Regret_From_Payoffs (Mat);
      Assert (Regrets (1, 1) = 0.0 and Regrets (2, 2) = 0.0, "Optimal choice != 0 regret");
      Put_Line ("      PASS");
   end;
   
   -- TEST 14
   Put_Line ("TEST 14 - Core Invariant: Minimax is non-negative");
   Put_Line ("  14.1 Assert algorithm cannot return a negative minimax value");
   declare
      Mat : constant Matrix (1 .. 3, 1 .. 3) := ((1.0, 2.0, 3.0), (4.0, 5.0, 6.0), (7.0, 8.0, 9.0));
   begin
      Minimax_Regret (Regret_From_Payoffs (Mat), Best, Val);
      Assert (Val >= 0.0, "Minimax value was negative");
      Put_Line ("      PASS");
   end;

   Put_Line ("------------------------------------------------------");
   Put_Line ("ALL TESTS EXECUTED AND PASSED SUCCESSFULLY.");
end Tests;
