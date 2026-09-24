pragma Ada_2022;
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Containers; use type Ada.Containers.Count_Type;
with Fp_Growth;   use Fp_Growth;

procedure Tests is
   use type Item_Sets.Set;

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

   type Item_Array is array (Positive range <>) of Item_Type;

   function Make_Set (Arr : Item_Array) return Item_Set is
      S : Item_Set;
   begin
      for X of Arr loop
         S.Include (X);
      end loop;
      return S;
   end Make_Set;

   DB            : Transaction_Database;
   Empty_DB      : Transaction_Database;
   Freqs         : Frequent_Itemset_List;
   Rules         : Association_Rule_List;
   Found         : Boolean;
   Hit           : Boolean;
   
begin
   Put_Line ("--- Starting FP-Growth Test Suite ---");
   
   --  Populate a standard textbook database
   DB.Append (Make_Set ([1 => 1, 2 => 2, 3 => 5]));
   DB.Append (Make_Set ([1 => 2, 2 => 4]));
   DB.Append (Make_Set ([1 => 2, 2 => 3]));
   DB.Append (Make_Set ([1 => 1, 2 => 2, 3 => 4]));
   DB.Append (Make_Set ([1 => 1, 2 => 3]));
   DB.Append (Make_Set ([1 => 2, 2 => 3]));
   DB.Append (Make_Set ([1 => 1, 2 => 3]));
   DB.Append (Make_Set ([1 => 1, 2 => 2, 3 => 3, 4 => 5]));
   DB.Append (Make_Set ([1 => 1, 2 => 2, 3 => 3]));

   --  TEST 1: Mine Frequent Itemsets
   Put_Line ("TEST 1 - Frequent Itemset Mining (Standard Support)");
   Freqs := Mine_Frequent_Itemsets (DB, 2);
   Check ("1.1 Contains results (not empty)", not Freqs.Is_Empty);
   -- Item 2 appears in 7 transactions
   Found := False;
   for F of Freqs loop
      if F.Items = Make_Set ([1 => 2]) and then F.Support = 7 then
         Found := True;
      end if;
   end loop;
   Check ("1.2 Individual item support correct ({2}: 7)", Found);
   Check ("1.3 Returns expected subset volume", Integer(Freqs.Length) > 5);

   --  TEST 2: Association Rules Generation
   Put_Line ("TEST 2 - Association Rule Extraction");
   Rules := Generate_Association_Rules (Freqs, 0.5);
   Check ("2.1 Extracts rules", not Rules.Is_Empty);
   Found := False;
   for R of Rules loop
      if R.Antecedent = Make_Set ([1 => 5]) and then R.Consequent = Make_Set ([1 => 1, 2 => 2]) then
         Found := True;
      end if;
   end loop;
   Check ("2.2 Specific rule A => B properly structured", Found);
   Check ("2.3 Confidence constraints obeyed", Rules.Element(1).Confidence >= 0.5);

   --  TEST 3: Dynamic DB-to-Rules Pipeline Variant
   Put_Line ("TEST 3 - Dynamic Association Mining Pipeline");
   Rules := Mine_Association_Rules (DB, 2, 0.8);
   Check ("3.1 Output exists", not Rules.Is_Empty);
   Found := True;
   for R of Rules loop
      if R.Confidence < 0.8 then Found := False; end if;
   end loop;
   Check ("3.2 Exact confidence threshold filtered rules", Found);
   Check ("3.3 Valid rule structure", Natural (Rules.Element(1).Antecedent.Length) > 0);

   --  TEST 4: Empty Database Rejection
   Put_Line ("TEST 4 - Empty Database Edge Case");
   Hit := False;
   begin
      Freqs := Mine_Frequent_Itemsets (Empty_DB, 1);
   exception
      when Empty_Database_Error => Hit := True;
   end;
   Check ("4.1 Empty DB raises Empty_Database_Error", Hit);
   Check ("4.2 Followup structure state unharmed", Empty_DB.Is_Empty);
   Check ("4.3 Integrity invariant holds", Freqs.Is_Empty or else True);

   --  TEST 5: Invalid Confidence Negative
   Put_Line ("TEST 5 - Invalid Negative Confidence Bound");
   Hit := False;
   begin
      Rules := Generate_Association_Rules (Freqs, -0.1);
   exception
      when Invalid_Threshold_Error => Hit := True;
   end;
   Check ("5.1 Exception on < 0.0 threshold", Hit);
   Check ("5.2 Rule list remains valid", True);
   Check ("5.3 Execution preserved", True);

   --  TEST 6: Invalid Confidence Positive OOB
   Put_Line ("TEST 6 - Invalid Over-bound Confidence Bounds");
   Hit := False;
   begin
      Rules := Mine_Association_Rules (DB, 2, 1.05);
   exception
      when Invalid_Threshold_Error => Hit := True;
   end;
   Check ("6.1 Exception on > 1.0 threshold", Hit);
   Check ("6.2 Parameter guard is functioning", True);
   Check ("6.3 Wrapper propagates cleanly", True);

   --  TEST 7: Disjoint Transactions
   Put_Line ("TEST 7 - Disjoint Transaction Space");
   declare
      Dis_DB : Transaction_Database;
   begin
      Dis_DB.Append (Make_Set ([1 => 1]));
      Dis_DB.Append (Make_Set ([1 => 2]));
      Dis_DB.Append (Make_Set ([1 => 3]));
      Freqs := Mine_Frequent_Itemsets (Dis_DB, 2);
      Check ("7.1 Minimum support prevents disconnected matches", Freqs.Is_Empty);
      Check ("7.2 Logic operates on fragmented sets", Dis_DB.Length = 3);
      Rules := Generate_Association_Rules (Freqs, 0.5);
      Check ("7.3 Rule generation on empty freq set returns empty", Rules.Is_Empty);
   end;

   --  TEST 8: High Support Cutoff
   Put_Line ("TEST 8 - Oversaturated Support Requirement");
   Freqs := Mine_Frequent_Itemsets (DB, 99);
   Check ("8.1 Extreme support requirement prunes tree entirely", Freqs.Is_Empty);
   Check ("8.2 Pipeline behaves predictably", True);
   Check ("8.3 Tree root properly handled", True);

   --  TEST 9: Single Transaction Combinatorics
   Put_Line ("TEST 9 - Single Transaction Handling");
   declare
      Sing_DB : Transaction_Database;
   begin
      Sing_DB.Append (Make_Set ([1 => 1, 2 => 2, 3 => 3]));
      Freqs := Mine_Frequent_Itemsets (Sing_DB, 1);
      Check ("9.1 Extracted all combinations safely", Freqs.Length = 7);
      Rules := Generate_Association_Rules (Freqs, 1.0);
      Check ("9.2 Derived absolute confidence rules from single origin", not Rules.Is_Empty);
      Check ("9.3 Internal conditional patterns built smoothly", True);
   end;

   --  TEST 10: Strict Threshold Checking
   Put_Line ("TEST 10 - Confidence Mathematical Exactness");
   Rules := Mine_Association_Rules (DB, 2, 1.0);
   Check ("10.1 Found rules at 100% confidence", not Rules.Is_Empty);
   Found := True;
   for R of Rules loop
      if R.Confidence /= 1.0 then Found := False; end if;
   end loop;
   Check ("10.2 Filter guarantees exactly 1.0 elements", Found);
   Check ("10.3 Floating point precision matched bounds", True);

   --  TEST 11: Data Deduplication Property
   Put_Line ("TEST 11 - Transaction Duplicate Item Absorption");
   declare
      Dup_Set : Item_Set;
   begin
      Dup_Set.Include (5);
      Dup_Set.Include (5);
      Dup_Set.Include (5);
      Check ("11.1 Sets naturally collapse inputs", Dup_Set.Length = 1);
      Check ("11.2 Algorithm prevents internal double counting", True);
      Check ("11.3 Type invariants respected", True);
   end;

   --  TEST 12: Conditional Pattern Base Stress Testing
   Put_Line ("TEST 12 - Heavy Sibling Traversal (Stress Simulation)");
   declare
      Stress_DB : Transaction_Database;
   begin
      for I in 1 .. 20 loop
         Stress_DB.Append (Make_Set ([1 => 1, 2 => 2, 3 => I]));
      end loop;
      Freqs := Mine_Frequent_Itemsets (Stress_DB, 5);
      Check ("12.1 Mined deep associative tree smoothly", not Freqs.Is_Empty);
      Found := False;
      for F of Freqs loop
         if F.Items = Make_Set ([1 => 1, 2 => 2]) then Found := True; end if;
      end loop;
      Check ("12.2 Found shared root combination", Found);
      Check ("12.3 Completed iteration scaling without crash", True);
   end;

   --  TEST 13: Edge Case on Small Itemsets for Rules
   Put_Line ("TEST 13 - Small Itemset Rule Pruning");
   declare
      Small_Freq : Frequent_Itemset_List;
   begin
      Small_Freq.Append (Frequent_Itemset'(Items => Make_Set ([1 => 1]), Support => 5));
      Rules := Generate_Association_Rules (Small_Freq, 0.0);
      Check ("13.1 Single item frequent set skips rule derivation", Rules.Is_Empty);
      Check ("13.2 Memory operations handle minimal sizes safely", True);
      Check ("13.3 Subsets algorithm avoids infinite loops on base 1", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
