with Ada.Text_IO; use Ada.Text_IO;
with Ada.Containers;
with Ada.Assertions;
with Eclat_Algorithm; use Eclat_Algorithm;

procedure Tests is
   use type Item_Sets.Set;
   use type Ada.Containers.Count_Type;

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

   -- Helper to create an Item_Sets.Set from an array of Positive
   type Item_Array is array (Positive range <>) of Positive;
   function To_Set (Arr : Item_Array) return Item_Sets.Set is
      S : Item_Sets.Set := Item_Sets.Empty_Set;
   begin
      for X of Arr loop
         S.Insert (Item_ID (X));
      end loop;
      return S;
   end To_Set;

   -- Helper to lookup Support of a specific itemset in the Results vector
   function Get_Support (Results : Itemset_Vectors.Vector; Arr : Item_Array) return Natural is
      Target : constant Item_Sets.Set := To_Set (Arr);
   begin
      for R of Results loop
         if R.Items = Target then
            return Natural (R.Support);
         end if;
      end loop;
      return 0; -- Not found
   end Get_Support;

   DB : Vertical_DB;
   R  : Itemset_Vectors.Vector;

begin
   -- TEST 1 - Empty Database Behavior
   Put_Line ("TEST 1 - Empty Database Behavior");
   Clear (DB);
   Check ("1.1 Item_Count is 0", Item_Count (DB) = 0);
   R := Mine_Standard (DB, Min_Sup => 2);
   Check ("1.2 Mine_Standard returns empty on empty DB", R.Is_Empty);
   R := Mine_Diffset (DB, Min_Sup => 2);
   Check ("1.3 Mine_Diffset returns empty on empty DB", R.Is_Empty);

   -- TEST 2 - Item Addition and Idempotency
   Put_Line ("TEST 2 - Item Addition and Idempotency");
   Clear (DB);
   Add_Item_TID (DB, Item => 1, TID => 1);
   Add_Item_TID (DB, Item => 1, TID => 2);
   Check ("2.1 Item_Count is 1", Item_Count (DB) = 1);
   Add_Item_TID (DB, Item => 1, TID => 2); -- Add duplicate TID
   Check ("2.2 Item_Count still 1 after duplicate TID", Item_Count (DB) = 1);
   R := Mine_Standard (DB, Min_Sup => 1);
   Check ("2.3 Support is exactly 2 despite duplicate addition", Get_Support (R, [1 => 1]) = 2);

   -- TEST 3 - Single Item Filtering (Min_Sup thresholds)
   Put_Line ("TEST 3 - Single Item Filtering");
   Clear (DB);
   Add_Item_TID (DB, Item => 5, TID => 10);
   Add_Item_TID (DB, Item => 5, TID => 20);
   Add_Item_TID (DB, Item => 5, TID => 30);
   R := Mine_Standard (DB, Min_Sup => 2);
   Check ("3.1 Single item found when Min_Sup <= actual (Std)", Get_Support (R, [1 => 5]) = 3);
   R := Mine_Diffset (DB, Min_Sup => 2);
   Check ("3.2 Single item found when Min_Sup <= actual (Diff)", Get_Support (R, [1 => 5]) = 3);
   R := Mine_Standard (DB, Min_Sup => 4);
   Check ("3.3 Item discarded when Min_Sup > actual (Std)", Get_Support (R, [1 => 5]) = 0);

   -- TEST 4 - Two Items, Standard Eclat Intersection
   Put_Line ("TEST 4 - Two Items, Standard Eclat Intersection");
   Clear (DB);
   -- Item 1 is in TIDs 1, 2, 3
   Add_Item_TID (DB, 1, 1); Add_Item_TID (DB, 1, 2); Add_Item_TID (DB, 1, 3);
   -- Item 2 is in TIDs 2, 3, 4
   Add_Item_TID (DB, 2, 2); Add_Item_TID (DB, 2, 3); Add_Item_TID (DB, 2, 4);
   R := Mine_Standard (DB, Min_Sup => 1);
   Check ("4.1 Item 1 support is 3", Get_Support (R, [1 => 1]) = 3);
   Check ("4.2 Item 2 support is 3", Get_Support (R, [1 => 2]) = 3);
   Check ("4.3 Itemset {1,2} support is 2", Get_Support (R, [1, 2]) = 2);

   -- TEST 5 - Two Items, Diffset (dEclat) Logic
   Put_Line ("TEST 5 - Two Items, Diffset (dEclat) Logic");
   R := Mine_Diffset (DB, Min_Sup => 1);
   Check ("5.1 Item 1 support is 3 (Diffset)", Get_Support (R, [1 => 1]) = 3);
   Check ("5.2 Item 2 support is 3 (Diffset)", Get_Support (R, [1 => 2]) = 3);
   Check ("5.3 Itemset {1,2} support is 2 (Diffset)", Get_Support (R, [1, 2]) = 2);

   -- TEST 6 - Disjoint Items (No Intersection)
   Put_Line ("TEST 6 - Disjoint Items (No Intersection)");
   Clear (DB);
   Add_Item_TID (DB, 1, 1); Add_Item_TID (DB, 1, 2);
   Add_Item_TID (DB, 2, 3); Add_Item_TID (DB, 2, 4);
   R := Mine_Standard (DB, Min_Sup => 1);
   Check ("6.1 Item 1 found", Get_Support (R, [1 => 1]) = 2);
   Check ("6.2 Item 2 found", Get_Support (R, [1 => 2]) = 2);
   Check ("6.3 Intersection {1,2} is non-existent (Support = 0)", Get_Support (R, [1, 2]) = 0);

   -- TEST 7 - Subset Relationship (One item's TIDs fully within another)
   Put_Line ("TEST 7 - Subset Relationship");
   Clear (DB);
   -- Item 1: 1, 2, 3, 4. Item 2: 2, 3
   Add_Item_TID (DB, 1, 1); Add_Item_TID (DB, 1, 2); Add_Item_TID (DB, 1, 3); Add_Item_TID (DB, 1, 4);
   Add_Item_TID (DB, 2, 2); Add_Item_TID (DB, 2, 3);
   R := Mine_Diffset (DB, Min_Sup => 2);
   Check ("7.1 Item 1 Support = 4", Get_Support (R, [1 => 1]) = 4);
   Check ("7.2 Item 2 Support = 2", Get_Support (R, [1 => 2]) = 2);
   Check ("7.3 {1,2} Support equals Subset Item Support", Get_Support (R, [1, 2]) = 2);

   -- TEST 8 - Three Items (Testing Level 3+ Diffset Recursion)
   Put_Line ("TEST 8 - Three Items, Level 3+ dEclat");
   Clear (DB);
   -- T1: 1,2,3 | T2: 1,2,3 | T3: 1,2 | T4: 1,3 | T5: 2,3
   Add_Item_TID (DB, 1, 1); Add_Item_TID (DB, 1, 2); Add_Item_TID (DB, 1, 3); Add_Item_TID (DB, 1, 4);
   Add_Item_TID (DB, 2, 1); Add_Item_TID (DB, 2, 2); Add_Item_TID (DB, 2, 3); Add_Item_TID (DB, 2, 5);
   Add_Item_TID (DB, 3, 1); Add_Item_TID (DB, 3, 2); Add_Item_TID (DB, 3, 4); Add_Item_TID (DB, 3, 5);
   R := Mine_Diffset (DB, Min_Sup => 1);
   Check ("8.1 {1,2,3} Support is correctly computed at Level 3 as 2", Get_Support (R, [1, 2, 3]) = 2);
   Check ("8.2 {1,2} Support is 3", Get_Support (R, [1, 2]) = 3);
   Check ("8.3 {2,3} Support is 3", Get_Support (R, [2, 3]) = 3);

   -- TEST 9 - Identical Output Count (Standard vs Diffset)
   Put_Line ("TEST 9 - Identical Output Count");
   declare
      R_Std, R_Diff : Itemset_Vectors.Vector;
   begin
      R_Std  := Mine_Standard (DB, Min_Sup => 2);
      R_Diff := Mine_Diffset (DB, Min_Sup => 2);
      Check ("9.1 Vectors have same length", R_Std.Length = R_Diff.Length);
      Check ("9.2 Std found exact combinations", Get_Support (R_Std, [1, 3]) = 3);
      Check ("9.3 Diff found exact combinations", Get_Support (R_Diff, [1, 3]) = 3);
   end;

   -- TEST 10 - Invalid Parameter Exception Handling
   Put_Line ("TEST 10 - Invalid Parameter Exception Handling");
   declare
      Exception_Raised : Boolean := False;
   begin
      begin
         R := Mine_Standard (DB, Min_Sup => 0);
      exception
         when Invalid_Min_Support | Ada.Assertions.Assertion_Error => Exception_Raised := True;
      end;
      Check ("10.1 Mine_Standard correctly raises on Min_Sup=0", Exception_Raised);
      
      Exception_Raised := False;
      begin
         R := Mine_Diffset (DB, Min_Sup => 0);
      exception
         when Invalid_Min_Support | Ada.Assertions.Assertion_Error => Exception_Raised := True;
      end;
      Check ("10.2 Mine_Diffset correctly raises on Min_Sup=0", Exception_Raised);
      
      -- Trivial assertion to round out test to 3 assertions
      Check ("10.3 DB Item Count untouched", Item_Count (DB) = 3);
   end;

   -- TEST 11 - Extremely High Min_Sup Filter
   Put_Line ("TEST 11 - Extremely High Min_Sup Filter");
   R := Mine_Standard (DB, Min_Sup => 10);
   Check ("11.1 Standard Eclat returns empty when Min_Sup unattainable", R.Is_Empty);
   R := Mine_Diffset (DB, Min_Sup => 10);
   Check ("11.2 Diffset dEclat returns empty when Min_Sup unattainable", R.Is_Empty);
   Check ("11.3 Item_Count still correct", Item_Count(DB) = 3);

   -- TEST 12 - Missing / Gap TIDs
   Put_Line ("TEST 12 - Missing / Gap TIDs");
   Clear (DB);
   Add_Item_TID (DB, 7, 100);
   Add_Item_TID (DB, 7, 200);
   Add_Item_TID (DB, 8, 200);
   Add_Item_TID (DB, 8, 300);
   R := Mine_Diffset (DB, Min_Sup => 1);
   Check ("12.1 Supports non-sequential TIDs (Item 7)", Get_Support (R, [1 => 7]) = 2);
   Check ("12.2 Supports non-sequential TIDs (Item 8)", Get_Support (R, [1 => 8]) = 2);
   Check ("12.3 Intersection correctly identifies overlap at 200", Get_Support (R, [7, 8]) = 1);

   -- TEST 13 - Missing / Gap Items
   Put_Line ("TEST 13 - Missing / Gap Items");
   Clear (DB);
   Add_Item_TID (DB, 10, 1);
   Add_Item_TID (DB, 90, 1);
   Add_Item_TID (DB, 15, 1);
   R := Mine_Diffset (DB, Min_Sup => 1);
   Check ("13.1 Ordered sets handle non-sequential Items {10}", Get_Support (R, [1 => 10]) = 1);
   Check ("13.2 Ordered sets handle non-sequential Items {90}", Get_Support (R, [1 => 90]) = 1);
   -- Because we rely on Ordered_Sets, the array helper needs elements in ascending order:
   Check ("13.3 Output Itemsets are properly ordered internally {10,15,90}", Get_Support (R, [10, 15, 90]) = 1);

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
