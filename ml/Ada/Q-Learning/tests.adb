with Ada.Text_IO; use Ada.Text_IO;
with Q_Learning;

procedure Tests is
   --  Domain specific types for testing the Q-Learning implementation
   type Test_State is (S1, S2, S3);
   type Test_Action is (A1, A2, A3);
   type Test_Value is digits 6;

   package Test_QL is new Q_Learning
     (State_Type  => Test_State,
      Action_Type => Test_Action,
      Value_Type  => Test_Value);

   use Test_QL;

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   Table   : Q_Table := [others => [others => 0.0]];
   Table_B : Q_Table := [others => [others => 0.0]];

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS - " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL - " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   function Is_Close (A, B : Test_Value) return Boolean is
   begin
      return abs (A - B) < 0.0001;
   end Is_Close;

   procedure Reset_Tables is
   begin
      for S in Test_State loop
         for A in Test_Action loop
            Table (S, A)   := 0.0;
            Table_B (S, A) := 0.0;
         end loop;
      end loop;
   end Reset_Tables;

begin
   Put_Line ("Starting Q-Learning Test Suite...");
   
   --  TEST 1: Max_Q_Value Basic functionality
   Put_Line ("TEST 1 - Max_Q_Value Basic");
   Reset_Tables;
   Check ("1.1 Empty table returns 0.0", Is_Close (Max_Q_Value (Table, S1), 0.0));
   Table (S1, A2) := 5.5;
   Table (S1, A3) := 2.1;
   Check ("1.2 Finds highest positive value", Is_Close (Max_Q_Value (Table, S1), 5.5));
   Table (S2, A1) := -3.0;
   Table (S2, A3) := -1.0;
   -- A2 is still 0.0 for S2
   Check ("1.3 Correctly considers unmodified 0.0 as max over negatives", Is_Close (Max_Q_Value (Table, S2), 0.0));

   --  TEST 2: Best_Action Basic functionality
   Put_Line ("TEST 2 - Best_Action Basic");
   Reset_Tables;
   Check ("2.1 Empty table returns first action", Best_Action (Table, S1) = A1);
   Table (S1, A2) := 10.0;
   Check ("2.2 Returns action with highest value", Best_Action (Table, S1) = A2);
   Table (S1, A3) := 15.0;
   Check ("2.3 Action updates correctly on new maximum", Best_Action (Table, S1) = A3);

   --  TEST 3: Update_Q_Value with Zero Alpha (No learning)
   Put_Line ("TEST 3 - Update_Q_Value with Alpha = 0.0");
   Reset_Tables;
   Table (S1, A1) := 7.0;
   Update_Q_Value (Table, S1, A1, Reward => 100.0, Next_State => S2, Learning_Rate => 0.0, Discount_Factor => 0.9);
   Check ("3.1 Q-value unmodified when Alpha = 0.0", Is_Close (Table (S1, A1), 7.0));
   Update_Q_Value (Table, S1, A1, Reward => -50.0, Next_State => S3, Learning_Rate => 0.0, Discount_Factor => 0.1);
   Check ("3.2 Stable against negative rewards", Is_Close (Table (S1, A1), 7.0));
   Check ("3.3 Other table states remain unaffected", Is_Close (Table (S2, A1), 0.0));

   --  TEST 4: Update_Q_Value with Alpha = 1.0 (Full replacement)
   Put_Line ("TEST 4 - Update_Q_Value with Alpha = 1.0");
   Reset_Tables;
   Table (S1, A1) := 5.0;
   Table (S2, A2) := 20.0; -- Max_Q for S2
   Update_Q_Value (Table, S1, A1, Reward => 10.0, Next_State => S2, Learning_Rate => 1.0, Discount_Factor => 0.5);
   --  Target = 10.0 + 0.5 * 20.0 = 20.0
   Check ("4.1 Completes overwrites existing Q-value", Is_Close (Table (S1, A1), 20.0));
   Update_Q_Value (Table, S1, A1, Reward => 5.0, Next_State => S3, Learning_Rate => 1.0, Discount_Factor => 0.0);
   --  Target = 5.0 + 0.0 * 0 = 5.0
   Check ("4.2 Gamma 0 forces purely reward-based overwrite", Is_Close (Table (S1, A1), 5.0));
   Check ("4.3 Unrelated states still unmodified", Is_Close (Table (S1, A2), 0.0));

   --  TEST 5: Update_Q_Value with Gamma = 0.0 (Myopic evaluation)
   Put_Line ("TEST 5 - Update_Q_Value with Gamma = 0.0");
   Reset_Tables;
   Table (S2, A3) := 100.0; -- Max future state
   Update_Q_Value (Table, S1, A1, Reward => 10.0, Next_State => S2, Learning_Rate => 0.5, Discount_Factor => 0.0);
   --  Current = 0, Reward = 10, Future ignored -> 0 + 0.5 * (10 - 0) = 5.0
   Check ("5.1 Completely ignores huge future reward", Is_Close (Table (S1, A1), 5.0));
   Update_Q_Value (Table, S1, A1, Reward => 10.0, Next_State => S2, Learning_Rate => 0.5, Discount_Factor => 0.0);
   --  Current = 5, Reward = 10 -> 5 + 0.5 * (10 - 5) = 7.5
   Check ("5.2 Iterative update works correctly without future state", Is_Close (Table (S1, A1), 7.5));
   Update_Q_Value (Table, S3, A1, Reward => -2.0, Next_State => S2, Learning_Rate => 1.0, Discount_Factor => 0.0);
   Check ("5.3 Correctly processes negative rewards myopically", Is_Close (Table (S3, A1), -2.0));

   --  TEST 6: Update_Q_Value Standard Parameters
   Put_Line ("TEST 6 - Update_Q_Value Standard Parameters");
   Reset_Tables;
   Table (S1, A1) := 5.0;
   Table (S2, A1) := 20.0;
   Update_Q_Value (Table, S1, A1, Reward => 10.0, Next_State => S2, Learning_Rate => 0.1, Discount_Factor => 0.9);
   --  Target = 10.0 + 0.9*20.0 = 28.0; New = 5.0 + 0.1*(28.0 - 5.0) = 7.3
   Check ("6.1 Calculates mixed parameters accurately", Is_Close (Table (S1, A1), 7.3));
   Table (S2, A2) := 30.0; -- Increase next state's max
   Update_Q_Value (Table, S1, A1, Reward => 0.0, Next_State => S2, Learning_Rate => 0.1, Discount_Factor => 1.0);
   --  Target = 0.0 + 1.0*30.0 = 30.0; New = 7.3 + 0.1*(30.0 - 7.3) = 7.3 + 2.27 = 9.57
   Check ("6.2 Zero reward propagates future value", Is_Close (Table (S1, A1), 9.57));
   Check ("6.3 Next state remains unmodified", Is_Close (Table (S2, A2), 30.0));

   --  TEST 7: Double Q-Learning (Update A)
   Put_Line ("TEST 7 - Double Q-Learning Update A");
   Reset_Tables;
   Table (S2, A1)   := 10.0; -- Table A thinks A1 is best for S2
   Table_B (S2, A1) := 2.0;  -- Table B thinks A1 is terrible (value = 2.0)
   Update_Double_Q_Value (Table_A => Table, Table_B => Table_B, State => S1, Action => A1, 
                          Reward => 5.0, Next_State => S2, Learning_Rate => 0.5, Discount_Factor => 1.0, Update_A => True);
   --  Table A picks action A1. Table B evaluates A1 as 2.0.
   --  Target = 5.0 + 1.0 * 2.0 = 7.0. Current = 0.0. New_Q = 0.0 + 0.5 * 7.0 = 3.5.
   Check ("7.1 Table A updated correctly using Table B's evaluation", Is_Close (Table (S1, A1), 3.5));
   Check ("7.2 Table B remains totally unchanged", Is_Close (Table_B (S1, A1), 0.0));
   Check ("7.3 Overestimation in Table A is bypassed", Table (S1, A1) < 5.0);

   --  TEST 8: Double Q-Learning (Update B)
   Put_Line ("TEST 8 - Double Q-Learning Update B");
   Reset_Tables;
   Table_B (S3, A3) := 20.0; -- Table B thinks A3 is best for S3
   Table (S3, A3)   := 5.0;  -- Table A evaluates A3 as 5.0
   Update_Double_Q_Value (Table_A => Table, Table_B => Table_B, State => S1, Action => A2, 
                          Reward => 10.0, Next_State => S3, Learning_Rate => 1.0, Discount_Factor => 0.5, Update_A => False);
   --  Table B picks A3. Table A evaluates A3 as 5.0.
   --  Target = 10.0 + 0.5 * 5.0 = 12.5. Current = 0.0. New_Q = 12.5.
   Check ("8.1 Table B updated correctly using Table A's evaluation", Is_Close (Table_B (S1, A2), 12.5));
   Check ("8.2 Table A remains totally unchanged", Is_Close (Table (S1, A2), 0.0));
   Check ("8.3 Correct action slot updated", Is_Close (Table_B (S1, A1), 0.0));

   --  TEST 9: Epsilon-Greedy with Epsilon 0.0 (Pure Greedy)
   Put_Line ("TEST 9 - Epsilon Greedy with Epsilon 0.0");
   Reset_Tables;
   Table (S1, A3) := 50.0; -- Best action is A3
   Check ("9.1 Selects greedy action on high random roll", Epsilon_Greedy_Action (Table, S1, 0.0, 0.99, A1) = A3);
   Check ("9.2 Selects greedy action on low random roll", Epsilon_Greedy_Action (Table, S1, 0.0, 0.0, A2) = A3);
   Check ("9.3 Ignores the Random_Action argument entirely", Epsilon_Greedy_Action (Table, S1, 0.0, 0.5, A1) = A3);

   --  TEST 10: Epsilon-Greedy with Epsilon 1.0 (Pure Random)
   Put_Line ("TEST 10 - Epsilon Greedy with Epsilon 1.0");
   Reset_Tables;
   Table (S1, A3) := 50.0; -- Best action is A3
   Check ("10.1 Forces purely random selection", Epsilon_Greedy_Action (Table, S1, 1.0, 0.1, A1) = A1);
   Check ("10.2 Disregards the Q-table highest value", Epsilon_Greedy_Action (Table, S1, 1.0, 0.99, A2) = A2);
   Check ("10.3 Behaves predictably based on arguments passed", Epsilon_Greedy_Action (Table, S1, 1.0, 0.5, A3) = A3);

   --  TEST 11: Epsilon-Greedy Middle Threshold
   Put_Line ("TEST 11 - Epsilon Greedy Middle Boundary");
   Reset_Tables;
   Table (S1, A2) := 10.0;
   Check ("11.1 Random threshold < Epsilon behaves randomly", Epsilon_Greedy_Action (Table, S1, 0.5, 0.49, A1) = A1);
   Check ("11.2 Random threshold > Epsilon behaves greedily", Epsilon_Greedy_Action (Table, S1, 0.5, 0.51, A3) = A2);
   Check ("11.3 Random threshold << Epsilon safely returns random", Epsilon_Greedy_Action (Table, S1, 0.5, 0.1, A3) = A3);

   --  TEST 12: Max_Q_Value all negative
   Put_Line ("TEST 12 - Max_Q_Value Edge Cases (Negative values)");
   Reset_Tables;
   Table (S1, A1) := -10.0;
   Table (S1, A2) := -5.0;
   Table (S1, A3) := -20.0;
   Check ("12.1 Correctly extracts max when all are negative", Is_Close (Max_Q_Value (Table, S1), -5.0));
   Table (S2, A1) := -1.0;
   Table (S2, A2) := -1.0;
   Table (S2, A3) := -1.0;
   Check ("12.2 Identifies correct max on uniformity", Is_Close (Max_Q_Value (Table, S2), -1.0));
   Table (S3, A1) := -50.0;
   Check ("12.3 Ignores other states containing negatives", Is_Close (Max_Q_Value (Table, S3), 0.0));

   --  TEST 13: Best_Action Negative & Tie-Breaker
   Put_Line ("TEST 13 - Best_Action Negative & Tie-Breaker Edge Cases");
   Check ("13.1 Returns best action for purely negative state", Best_Action (Table, S1) = A2);
   Check ("13.2 Resolves tie by falling back to early action index", Best_Action (Table, S2) = A1);
   Table (S3, A2) := 50.0;
   Table (S3, A3) := 50.0;
   Check ("13.3 Resolves positive tie predictably", Best_Action (Table, S3) = A2);

   --  TEST 14: Double Q-Learning Edge Cases
   Put_Line ("TEST 14 - Double Q-Learning Mixed Extremes");
   Reset_Tables;
   Table_B (S2, A1) := -100.0; -- Table B hates A1
   Table (S2, A1)   := 100.0;  -- Table A loves A1
   Update_Double_Q_Value (Table_A => Table, Table_B => Table_B, State => S1, Action => A1, 
                          Reward => 0.0, Next_State => S2, Learning_Rate => 1.0, Discount_Factor => 1.0, Update_A => True);
   Check ("14.1 Massive penalty applied by decoupled evaluation table B", Is_Close (Table (S1, A1), -100.0));
   Check ("14.2 Table A's evaluation stays entirely untainted", Is_Close (Table (S2, A1), 100.0));
   Check ("14.3 Validates anti-overestimation property", Table (S1, A1) < 0.0);

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
