with Ada.Text_IO; use Ada.Text_IO;
with Apriori;     use Apriori;

procedure Tests is
   --  Bring the equality operator for the ordered set into visibility
   use type Apriori.Item_Sets.Set;

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

   type Int_Array is array (Positive range <>) of Positive;

   function Make_Set (Arr : Int_Array) return Item_Set is
      S : Item_Set;
   begin
      for X of Arr loop
         S.Insert (X);
      end loop;
      return S;
   end Make_Set;

   function Has_Set (List : Frequent_Item_Sets; Target : Item_Set) return Boolean is
   begin
      for L of List loop
         if L.Items = Target then
            return True;
         end if;
      end loop;
      return False;
   end Has_Set;

   function Has_Set_With_Count (List : Frequent_Item_Sets; Target : Item_Set; Count : Support_Count) return Boolean is
   begin
      for L of List loop
         if L.Items = Target and then L.Count = Count then
            return True;
         end if;
      end loop;
      return False;
   end Has_Set_With_Count;

   function Has_Rule (List : Rule_List; Ant, Con : Int_Array; Conf : Float) return Boolean is
      Epsilon : constant Float := 0.001;
      Ant_Set : constant Item_Set := Make_Set (Ant);
      Con_Set : constant Item_Set := Make_Set (Con);
   begin
      for R of List loop
         if R.Antecedent = Ant_Set and then R.Consequent = Con_Set then
            if abs (Float (R.Confidence) - Conf) < Epsilon then
               return True;
            end if;
         end if;
      end loop;
      return False;
   end Has_Rule;

begin
   --  TEST 1 — Frequent Item Sets (Absolute)
   Put_Line ("TEST 1 — Frequent Item Sets (Absolute)");
   declare
      DB : Database;
      FS : Frequent_Item_Sets;
   begin
      DB.Append (Make_Set ([1, 2, 3, 4]));
      DB.Append (Make_Set ([1, 2, 4]));
      DB.Append (Make_Set ([1, 2]));
      DB.Append (Make_Set ([2, 3, 4]));
      DB.Append (Make_Set ([2, 3]));
      DB.Append (Make_Set ([3, 4]));
      DB.Append (Make_Set ([2, 4]));

      FS := Find_Frequent_Item_Sets (DB, 3);
      Check ("1.1 Total identified frequent sets is 8", Natural (FS.Length) = 8);
      Check ("1.2 Contains {1, 2} with exactly support count 3", Has_Set_With_Count (FS, Make_Set ([1, 2]), 3));
      Check ("1.3 Excludes pruned candidate {1, 3}", not Has_Set (FS, Make_Set ([1, 3])));
   end;

   --  TEST 2 — Frequent Item Sets (Ratio Support)
   Put_Line ("TEST 2 — Frequent Item Sets (Ratio Support)");
   declare
      DB : Database;
      FS : Frequent_Item_Sets;
   begin
      DB.Append (Make_Set ([1, 2, 3, 4]));
      DB.Append (Make_Set ([1, 2, 4]));
      DB.Append (Make_Set ([1, 2]));
      DB.Append (Make_Set ([2, 3, 4]));
      DB.Append (Make_Set ([2, 3]));
      DB.Append (Make_Set ([3, 4]));
      DB.Append (Make_Set ([2, 4]));

      FS := Find_Frequent_Item_Sets (DB, 0.428); -- Approx 3 out of 7
      Check ("2.1 Total identified frequent sets is 8", Natural (FS.Length) = 8);
      Check ("2.2 Contains {3, 4} with count 3", Has_Set_With_Count (FS, Make_Set ([3, 4]), 3));
      Check ("2.3 Excludes pruned candidate {1, 4}", not Has_Set (FS, Make_Set ([1, 4])));
   end;

   --  TEST 3 — Association Rules Generation
   Put_Line ("TEST 3 — Association Rules Generation");
   declare
      DB    : Database;
      FS    : Frequent_Item_Sets;
      Rules : Rule_List;
   begin
      DB.Append (Make_Set ([1, 2, 3, 4]));
      DB.Append (Make_Set ([1, 2, 4]));
      DB.Append (Make_Set ([1, 2]));
      DB.Append (Make_Set ([2, 3, 4]));
      DB.Append (Make_Set ([2, 3]));
      DB.Append (Make_Set ([3, 4]));
      DB.Append (Make_Set ([2, 4]));
      FS := Find_Frequent_Item_Sets (DB, 3);
      Rules := Generate_Association_Rules (FS, Natural (DB.Length), 0.75);

      Check ("3.1 Has 100% confidence rule {1} => {2}", Has_Rule (Rules, [1], [2], 1.0));
      Check ("3.2 Has 80% confidence rule {4} => {2}", Has_Rule (Rules, [4], [2], 0.8));
      Check ("3.3 Excludes 50% confidence rule {2} => {1}", not Has_Rule (Rules, [2], [1], 0.5));
   end;

   --  TEST 4 — Maximal Item Sets
   Put_Line ("TEST 4 — Maximal Item Sets");
   declare
      DB  : Database;
      FS  : Frequent_Item_Sets;
      Max : Frequent_Item_Sets;
   begin
      DB.Append (Make_Set ([1, 2, 3, 4]));
      DB.Append (Make_Set ([1, 2, 4]));
      DB.Append (Make_Set ([1, 2]));
      DB.Append (Make_Set ([2, 3, 4]));
      DB.Append (Make_Set ([2, 3]));
      DB.Append (Make_Set ([3, 4]));
      DB.Append (Make_Set ([2, 4]));
      FS := Find_Frequent_Item_Sets (DB, 3);
      Max := Find_Maximal_Item_Sets (FS);

      Check ("4.1 Derived 4 maximal item sets", Natural (Max.Length) = 4);
      Check ("4.2 Contains maximal set {1, 2}", Has_Set (Max, Make_Set ([1, 2])));
      Check ("4.3 Subsets like {2} are omitted", not Has_Set (Max, Make_Set ([2])));
   end;

   --  TEST 5 — Closed Item Sets
   Put_Line ("TEST 5 — Closed Item Sets");
   declare
      DB  : Database;
      FS  : Frequent_Item_Sets;
      Cls : Frequent_Item_Sets;
   begin
      DB.Append (Make_Set ([1, 2, 3, 4]));
      DB.Append (Make_Set ([1, 2, 4]));
      DB.Append (Make_Set ([1, 2]));
      DB.Append (Make_Set ([2, 3, 4]));
      DB.Append (Make_Set ([2, 3]));
      DB.Append (Make_Set ([3, 4]));
      DB.Append (Make_Set ([2, 4]));
      FS := Find_Frequent_Item_Sets (DB, 3);
      Cls := Find_Closed_Item_Sets (FS);

      Check ("5.1 Derived exactly 7 closed item sets", Natural (Cls.Length) = 7);
      Check ("5.2 Preserves closed set {2}", Has_Set (Cls, Make_Set ([2])));
      Check ("5.3 Rejects non-closed subset {1}", not Has_Set (Cls, Make_Set ([1])));
   end;

   --  TEST 6 — Exception: Empty Database
   Put_Line ("TEST 6 — Exception: Empty Database");
   declare
      DB     : Database;
      FS     : Frequent_Item_Sets;
      Caught : Boolean := False;
   begin
      Check ("6.1 Initiated with fully empty DB", Natural (DB.Length) = 0);
      begin
         FS := Find_Frequent_Item_Sets (DB, 2);
      exception
         when Empty_Database => Caught := True;
      end;
      Check ("6.2 Raised Empty_Database accurately", Caught);
      Check ("6.3 FS construction safely aborted", Natural (FS.Length) = 0);
   end;

   --  TEST 7 — Exception: Invalid Min Support
   Put_Line ("TEST 7 — Exception: Invalid Min Support");
   declare
      DB     : Database;
      FS     : Frequent_Item_Sets;
      Caught : Boolean := False;
   begin
      DB.Append (Make_Set ([1, 2]));
      Check ("7.1 Initiated valid DB but Min_Support = 0", True);
      begin
         FS := Find_Frequent_Item_Sets (DB, 0);
      exception
         when Invalid_Min_Support => Caught := True;
      end;
      Check ("7.2 Raised Invalid_Min_Support accurately", Caught);
      Check ("7.3 Action aborted cleanly", Natural (FS.Length) = 0);
   end;

   --  TEST 8 — Exception: Empty Item Sets Rule Generation
   Put_Line ("TEST 8 — Exception: Empty Item Sets for Rule Generation");
   declare
      FS     : Frequent_Item_Sets;
      Rules  : Rule_List;
      Caught : Boolean := False;
   begin
      Check ("8.1 Initiated zero frequent sets", Natural (FS.Length) = 0);
      begin
         Rules := Generate_Association_Rules (FS, 10, 0.5);
      exception
         when Empty_Item_Sets => Caught := True;
      end;
      Check ("8.2 Raised Empty_Item_Sets properly", Caught);
      Check ("8.3 Resulting rules are empty", Natural (Rules.Length) = 0);
   end;

   --  TEST 9 — Disjoint Database (No overlapping items)
   Put_Line ("TEST 9 — Disjoint Database");
   declare
      DB : Database;
      FS : Frequent_Item_Sets;
   begin
      DB.Append (Make_Set ([1, 2]));
      DB.Append (Make_Set ([3, 4]));
      DB.Append (Make_Set ([5, 6]));
      FS := Find_Frequent_Item_Sets (DB, 2);
      Check ("9.1 Execution completes without exception", True);
      Check ("9.2 Freq sets length is precisely 0", Natural (FS.Length) = 0);
      Check ("9.3 Does not contain artifact items like {1}", not Has_Set (FS, Make_Set ([1])));
   end;

   --  TEST 10 — Uniform Database (Identical Transactions)
   Put_Line ("TEST 10 — Uniform Database");
   declare
      DB : Database;
      FS : Frequent_Item_Sets;
   begin
      DB.Append (Make_Set ([1, 2, 3]));
      DB.Append (Make_Set ([1, 2, 3]));
      FS := Find_Frequent_Item_Sets (DB, 2);
      Check ("10.1 All subsets derived correctly (Length=7)", Natural (FS.Length) = 7);
      Check ("10.2 Max superset {1, 2, 3} explicitly found", Has_Set_With_Count (FS, Make_Set ([1, 2, 3]), 2));
      Check ("10.3 Subset {2} is properly recognized", Has_Set_With_Count (FS, Make_Set ([2]), 2));
   end;

   --  TEST 11 — Single Item Database
   Put_Line ("TEST 11 — Single Item Database");
   declare
      DB : Database;
      FS : Frequent_Item_Sets;
   begin
      DB.Append (Make_Set ([42]));
      DB.Append (Make_Set ([42]));
      DB.Append (Make_Set ([42]));
      FS := Find_Frequent_Item_Sets (DB, 2);
      Check ("11.1 Processes strictly single item edge case", Natural (FS.Length) = 1);
      Check ("11.2 Detects the only target node {42}", Has_Set (FS, Make_Set ([42])));
      Check ("11.3 Computed final support matches array size (3)", Has_Set_With_Count (FS, Make_Set ([42]), 3));
   end;

   --  TEST 12 — High Confidence Strict Filtering
   Put_Line ("TEST 12 — High Confidence Rule Filter");
   declare
      DB    : Database;
      FS    : Frequent_Item_Sets;
      Rules : Rule_List;
   begin
      DB.Append (Make_Set ([1, 2]));
      DB.Append (Make_Set ([1, 2]));
      DB.Append (Make_Set ([1, 2]));
      DB.Append (Make_Set ([1, 3]));
      FS := Find_Frequent_Item_Sets (DB, 3);
      Rules := Generate_Association_Rules (FS, Natural (DB.Length), 0.99);
      Check ("12.1 Only perfect deterministic rules accepted", Natural (Rules.Length) = 1);
      Check ("12.2 Valid rule is {2} => {1}", Has_Rule (Rules, [2], [1], 1.0));
      Check ("12.3 Rejects rules hovering below exactly 1.0", not Has_Rule (Rules, [1], [2], 0.75));
   end;

   --  TEST 13 — Large Single Transaction Combinatorics
   Put_Line ("TEST 13 — Large Single Transaction");
   declare
      DB   : Database;
      FS   : Frequent_Item_Sets;
      Maxi : Frequent_Item_Sets;
   begin
      DB.Append (Make_Set ([1, 2, 3, 4, 5]));
      FS := Find_Frequent_Item_Sets (DB, 1);
      Maxi := Find_Maximal_Item_Sets (FS);
      Check ("13.1 Expanded 2^5 - 1 = 31 subsets gracefully", Natural (FS.Length) = 31);
      Check ("13.2 Correctly identified singular maximal item set", Natural (Maxi.Length) = 1);
      Check ("13.3 Maximal itemset integrates all 5 factors", Has_Set (Maxi, Make_Set ([1, 2, 3, 4, 5])));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
