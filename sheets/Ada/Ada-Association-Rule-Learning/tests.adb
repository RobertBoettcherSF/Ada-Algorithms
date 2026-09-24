with Ada.Text_IO; use Ada.Text_IO;
with System.Assertions;
with Association_Rules; use Association_Rules;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

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

   -- Float comparison with tolerance
   function Float_Equal (Left, Right : Float; Tolerance : Float := 0.0001) return Boolean is
   begin
      return abs (Left - Right) <= Tolerance;
   end Float_Equal;

   -- Globals for the database and standard sets
   DB       : Database;
   Empty_DB : Database;
   T1, T2, T3, T4, T5 : Item_Set;
   S1, S2, S3, S4, S9 : Item_Set;
   S12, S23, S14      : Item_Set;
   R_1_to_2, R_4_to_1 : Association_Rule;
   
begin
   -- Initialize database
   -- T1: {1, 2, 3}
   -- T2: {1, 2}
   -- T3: {1, 3, 4}
   -- T4: {2, 3}
   -- T5: {1, 2, 3, 4}
   T1.Insert(1); T1.Insert(2); T1.Insert(3);
   T2.Insert(1); T2.Insert(2);
   T3.Insert(1); T3.Insert(3); T3.Insert(4);
   T4.Insert(2); T4.Insert(3);
   T5.Insert(1); T5.Insert(2); T5.Insert(3); T5.Insert(4);

   DB.Append(T1); DB.Append(T2); DB.Append(T3); DB.Append(T4); DB.Append(T5);

   S1.Insert(1); S2.Insert(2); S3.Insert(3); S4.Insert(4); S9.Insert(9);
   S12.Insert(1); S12.Insert(2);
   S23.Insert(2); S23.Insert(3);
   S14.Insert(1); S14.Insert(4);
   
   R_1_to_2 := (Antecedent => S1, Consequent => S2);
   R_4_to_1 := (Antecedent => S4, Consequent => S1);

   -- TEST 1 - Database Preconditions
   Put_Line ("TEST 1 - Database Preconditions (Empty DB handling)");
   declare
      Val : Support_Value;
      pragma Warnings (Off, Val);
   begin
      Val := Support (Empty_DB, S1);
      Check ("1.1 Empty DB Support (Should not reach here)", False);
   exception
      when System.Assertions.Assert_Failure => Check ("1.1 Empty DB Support throws Precondition", True);
      when others => Check ("1.1 Empty DB Support unexpected exception", False);
   end;
   declare
      Val : Support_Value;
      pragma Warnings (Off, Val);
   begin
      Val := Confidence (Empty_DB, R_1_to_2);
      Check ("1.2 Empty DB Confidence (Should not reach here)", False);
   exception
      when System.Assertions.Assert_Failure => Check ("1.2 Empty DB Confidence throws Precondition", True);
      when others => Check ("1.2 Empty DB Confidence unexpected exception", False);
   end;
   declare
      Val : Item_Set_List;
      pragma Warnings (Off, Val);
   begin
      Val := Apriori (Empty_DB, 0.5);
      Check ("1.3 Empty DB Apriori (Should not reach here)", False);
   exception
      when System.Assertions.Assert_Failure => Check ("1.3 Empty DB Apriori throws Precondition", True);
      when others => Check ("1.3 Empty DB Apriori unexpected exception", False);
   end;

   -- TEST 2 - Basic Support Calculations
   Put_Line ("TEST 2 - Support Calculations");
   Check ("2.1 Support {1} (4/5 = 0.8)", Float_Equal (Float(Support(DB, S1)), 0.8));
   Check ("2.2 Support {2} (4/5 = 0.8)", Float_Equal (Float(Support(DB, S2)), 0.8));
   Check ("2.3 Support {1, 2} (3/5 = 0.6)", Float_Equal (Float(Support(DB, S12)), 0.6));

   -- TEST 3 - Missing/Empty items Support
   Put_Line ("TEST 3 - Missing / Empty Elements");
   Check ("3.1 Support for absent {9} is 0.0", Float_Equal (Float(Support(DB, S9)), 0.0));
   declare
      S19 : Item_Set := S1;
      Empty_Set : Item_Set;
      Val : Support_Value;
      pragma Warnings (Off, Val);
   begin
      S19.Insert(9);
      Check ("3.2 Support for {1, 9} is 0.0", Float_Equal (Float(Support(DB, S19)), 0.0));
      Val := Support(DB, Empty_Set);
      Check ("3.3 Empty Itemset throws Precondition (Should not reach here)", False);
   exception
      when System.Assertions.Assert_Failure => Check ("3.3 Empty Itemset Support throws Precondition", True);
      when others => Check ("3.3 Empty Itemset unexpected exception", False);
   end;

   -- TEST 4 - Confidence Metric
   Put_Line ("TEST 4 - Confidence Calculation");
   -- Conf({1}->{2}) = Sup({1,2}) / Sup({1}) = 0.6 / 0.8 = 0.75
   Check ("4.1 Conf({1} -> {2}) is 0.75", Float_Equal (Float(Confidence(DB, R_1_to_2)), 0.75));
   -- Conf({2}->{1}) = Sup({1,2}) / Sup({2}) = 0.6 / 0.8 = 0.75
   Check ("4.2 Conf({2} -> {1}) is 0.75", Float_Equal (Float(Confidence(DB, (S2, S1))), 0.75));
   -- Conf({1,2}->{3}) = Sup({1,2,3}) / Sup({1,2}) = 0.4 / 0.6 = 0.6666...
   declare
      R_12_to_3 : constant Association_Rule := (Antecedent => S12, Consequent => S3);
   begin
      Check ("4.3 Conf({1,2} -> {3}) is ~0.666", Float_Equal (Float(Confidence(DB, R_12_to_3)), 0.6666, 0.001));
   end;

   -- TEST 5 - Lift Metric
   Put_Line ("TEST 5 - Lift Calculation");
   -- Lift({1}->{2}) = 0.75 / 0.8 = 0.9375
   Check ("5.1 Lift({1} -> {2}) is 0.9375", Float_Equal (Float(Lift(DB, R_1_to_2)), 0.9375));
   -- Lift({2}->{1}) = 0.75 / 0.8 = 0.9375
   Check ("5.2 Lift({2} -> {1}) is 0.9375", Float_Equal (Float(Lift(DB, (S2, S1))), 0.9375));
   -- Lift({4}->{1}) = Conf({4}->{1})/Sup({1}) = 1.0 / 0.8 = 1.25
   Check ("5.3 Lift({4} -> {1}) is 1.25", Float_Equal (Float(Lift(DB, R_4_to_1)), 1.25));

   -- TEST 6 - Conviction Metric
   Put_Line ("TEST 6 - Conviction Calculation");
   -- Conviction({1}->{2}) = (1 - 0.8) / (1 - 0.75) = 0.2 / 0.25 = 0.8
   Check ("6.1 Conviction({1} -> {2}) is 0.8", Float_Equal (Float(Conviction(DB, R_1_to_2)), 0.8));
   Check ("6.2 Conviction({2} -> {1}) is 0.8", Float_Equal (Float(Conviction(DB, (S2, S1))), 0.8));
   declare
      R_2_to_3 : constant Association_Rule := (Antecedent => S2, Consequent => S3);
      -- Conviction({2}->{3}): Sup(3)=0.8, Conf({2}->{3}) = 0.6/0.8 = 0.75 => 0.2/0.25 = 0.8
   begin
      Check ("6.3 Conviction({2} -> {3}) is 0.8", Float_Equal (Float(Conviction(DB, R_2_to_3)), 0.8));
   end;

   -- TEST 7 - Leverage Metric
   Put_Line ("TEST 7 - Leverage Calculation");
   -- Leverage({1}->{2}) = Sup(1,2) - Sup(1)*Sup(2) = 0.6 - (0.8 * 0.8) = -0.04
   Check ("7.1 Leverage({1} -> {2}) is -0.04", Float_Equal (Float(Leverage(DB, R_1_to_2)), -0.04));
   Check ("7.2 Leverage({2} -> {1}) is -0.04", Float_Equal (Float(Leverage(DB, (S2, S1))), -0.04));
   -- Leverage({4}->{1}) = 0.4 - (0.4 * 0.8) = 0.4 - 0.32 = 0.08
   Check ("7.3 Leverage({4} -> {1}) is 0.08", Float_Equal (Float(Leverage(DB, R_4_to_1)), 0.08));

   -- TEST 8 - Apriori Algorithm (Min Support 0.5)
   Put_Line ("TEST 8 - Apriori Frequent Itemsets");
   declare
      Freq : constant Item_Set_List := Apriori (DB, 0.5);
   begin
      -- Expected: {1}, {2}, {3}, {1,2}, {1,3}, {2,3} -> Total 6
      Check ("8.1 Finds exactly 6 frequent itemsets", Natural (Freq.Length) = 6);
      Check ("8.2 Result contains {1, 2}", Freq.Contains (S12));
      Check ("8.3 Result contains {2, 3}", Freq.Contains (S23));
   end;

   -- TEST 9 - Brute Force Verification (Min Support 0.5)
   Put_Line ("TEST 9 - Brute Force Alternative Variant");
   declare
      Freq : constant Item_Set_List := Brute_Force_Frequent_Itemsets (DB, 0.5);
   begin
      Check ("9.1 Brute Force finds exactly 6 itemsets", Natural (Freq.Length) = 6);
      Check ("9.2 Brute Force result contains {1, 2}", Freq.Contains (S12));
      Check ("9.3 Brute Force result contains {2, 3}", Freq.Contains (S23));
   end;

   -- TEST 10 - Rule Generation
   Put_Line ("TEST 10 - Association Rule Generation");
   declare
      Freq  : constant Item_Set_List := Apriori (DB, 0.5);
      Rules : constant Rule_List := Generate_Rules (DB, Freq, 0.7);
   begin
      -- Expected 6 rules (all 2-itemsets have 0.75 conf both ways):
      -- {1}->{2}, {2}->{1}, {1}->{3}, {3}->{1}, {2}->{3}, {3}->{2}
      Check ("10.1 Generated exactly 6 high-confidence rules", Natural (Rules.Length) = 6);
      Check ("10.2 First rule has valid confidence", Confidence(DB, Rules.Element(1)) >= 0.7);
      Check ("10.3 Last rule has valid confidence", Confidence(DB, Rules.Element(6)) >= 0.7);
   end;

   -- TEST 11 - Zero Support Errors
   Put_Line ("TEST 11 - Zero Support Exception Handling");
   declare
      R_Bad : constant Association_Rule := (Antecedent => S9, Consequent => S1);
      Val : Support_Value;
      pragma Warnings (Off, Val);
   begin
      Val := Confidence (DB, R_Bad);
      Check ("11.1 Confidence throws Zero_Support_Error", False);
   exception
      when Zero_Support_Error => Check ("11.1 Confidence throws Zero_Support_Error", True);
      when others => Check ("11.1 Unexpected exception in Confidence", False);
   end;
   declare
      R_Bad : constant Association_Rule := (Antecedent => S9, Consequent => S1);
      Val : Metric_Value;
      pragma Warnings (Off, Val);
   begin
      Val := Lift (DB, R_Bad);
      Check ("11.2 Lift throws Zero_Support_Error", False);
   exception
      when Zero_Support_Error => Check ("11.2 Lift throws Zero_Support_Error", True);
      when others => Check ("11.2 Unexpected exception in Lift", False);
   end;
   declare
      R_Bad : constant Association_Rule := (Antecedent => S1, Consequent => S9);
      Val : Metric_Value;
   begin
      Val := Conviction (DB, R_Bad);
      Check ("11.3 Conviction handles missing consequent safely (val=1.25)", Float_Equal(Float(Val), 1.25));
   end;

   -- TEST 12 - Perfect Confidence Errors (Division by Zero in Conviction)
   Put_Line ("TEST 12 - Perfect Confidence Exception Handling");
   declare
      Val : Metric_Value;
      pragma Warnings (Off, Val);
   begin
      -- {4}->{1} has Conf = 1.0
      Val := Conviction (DB, R_4_to_1);
      Check ("12.1 Conviction throws Perfect_Confidence_Error", False);
   exception
      when Perfect_Confidence_Error => Check ("12.1 Conviction throws Perfect_Confidence_Error", True);
      when others => Check ("12.1 Unexpected exception in Conviction", False);
   end;
   Check ("12.2 Lift calculates perfectly without error on Conf=1.0", Float_Equal(Float(Lift(DB, R_4_to_1)), 1.25));
   Check ("12.3 Confidence safely returns 1.0", Float_Equal(Float(Confidence(DB, R_4_to_1)), 1.0));

   -- TEST 13 - Invalid Preconditions Metric Testing (Empty Antecedent / Consequent)
   Put_Line ("TEST 13 - Invalid Rule Preconditions");
   declare
      Empty_Set : Item_Set;
      R_Empty_Ant : constant Association_Rule := (Antecedent => Empty_Set, Consequent => S1);
      Val : Support_Value;
      pragma Warnings (Off, Val);
   begin
      Val := Confidence (DB, R_Empty_Ant);
      Check ("13.1 Confidence throws Precondition for Empty Ant", False);
   exception
      when System.Assertions.Assert_Failure => Check ("13.1 Confidence throws Precondition", True);
      when others => Check ("13.1 Unexpected exception", False);
   end;
   declare
      Empty_Set : Item_Set;
      R_Empty_Con : constant Association_Rule := (Antecedent => S1, Consequent => Empty_Set);
      Val : Metric_Value;
      pragma Warnings (Off, Val);
   begin
      Val := Lift (DB, R_Empty_Con);
      Check ("13.2 Lift throws Precondition for Empty Con", False);
   exception
      when System.Assertions.Assert_Failure => Check ("13.2 Lift throws Precondition", True);
      when others => Check ("13.2 Unexpected exception", False);
   end;
   declare
      Empty_Set : Item_Set;
      R_Empty_Ant : constant Association_Rule := (Antecedent => Empty_Set, Consequent => S1);
      Val : Metric_Value;
      pragma Warnings (Off, Val);
   begin
      Val := Conviction (DB, R_Empty_Ant);
      Check ("13.3 Conviction throws Precondition for Empty Ant", False);
   exception
      when System.Assertions.Assert_Failure => Check ("13.3 Conviction throws Precondition", True);
      when others => Check ("13.3 Unexpected exception", False);
   end;

   -- TEST 14 - Edge Case Algorithms
   Put_Line ("TEST 14 - Edge Cases in Generation");
   declare
      Freq : constant Item_Set_List := Apriori (DB, 1.0);
   begin
      -- No itemset appears in 100% of transactions (max is 80%)
      Check ("14.1 Apriori with Support 1.0 returns empty", Freq.Is_Empty);
   end;
   declare
      Freq : constant Item_Set_List := Brute_Force_Frequent_Itemsets (DB, 1.0);
   begin
      Check ("14.2 Brute Force with Support 1.0 returns empty", Freq.Is_Empty);
   end;
   declare
      Empty_Freq : Item_Set_List;
      Rules      : constant Rule_List := Generate_Rules(DB, Empty_Freq, 0.1);
   begin
      Check ("14.3 Generate Rules handles empty input safely", Rules.Is_Empty);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
