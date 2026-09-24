with Ada.Text_IO; use Ada.Text_IO;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Ada.Assertions; use Ada.Assertions;
with Sort_Merge_Join; use Sort_Merge_Join;

procedure Tests is

   function R(K : Integer; D : String) return Row is
   begin
      return (Key => Join_Key(K), Data => To_Unbounded_String(D));
   end R;

   Empty_Rel : Relation (1 .. 0);
   Res       : Joined_Relation;

begin
   Put_Line("Starting Test Suite for Sort-Merge Join");
   Put_Line("Assumption: Code is incorrect. Proof of correctness required via assertions.");
   Put_Line("=========================================================================");

   Put_Line("TEST 1 - Boundary & Empty Conditions");
   Put_Line("  1.1 [Assertion: Empty Left yields 0 records]");
   Res := Inner_Join(Empty_Rel, (1 => R(1,"A")));
   Assert (Natural(Res.Length) = 0, "Failed 1.1");
   Put_Line("      PASS");

   Put_Line("  1.2 [Assertion: Empty Right yields 0 records]");
   Res := Inner_Join((1 => R(1,"A")), Empty_Rel);
   Assert (Natural(Res.Length) = 0, "Failed 1.2");
   Put_Line("      PASS");

   Put_Line("  1.3 [Assertion: Both Empty yields 0 records]");
   Res := Inner_Join(Empty_Rel, Empty_Rel);
   Assert (Natural(Res.Length) = 0, "Failed 1.3");
   Put_Line("      PASS");

   Put_Line("TEST 2 - Functional Correctness (Standard Matches)");
   Put_Line("  2.1 [Assertion: No overlapping keys yields 0 records]");
   Res := Inner_Join((1 => R(1,"A")), (1 => R(2,"B")));
   Assert (Natural(Res.Length) = 0, "Failed 2.1");
   Put_Line("      PASS");

   Put_Line("  2.2 [Assertion: One-to-One match yields exactly 1 correct record]");
   Res := Inner_Join((1 => R(1,"L")), (1 => R(1,"R")));
   Assert (Natural(Res.Length) = 1 and then Res.Element(1).Left_Row.Data = "L", "Failed 2.2");
   Put_Line("      PASS");

   Put_Line("  2.3 [Assertion: Multiple distinct 1-1 matches yield N records]");
   Res := Inner_Join((1 => R(1,"A"), 2 => R(2,"B")), (1 => R(1,"X"), 2 => R(2,"Y")));
   Assert (Natural(Res.Length) = 2, "Failed 2.3");
   Put_Line("      PASS");

   Put_Line("TEST 3 - Complex Multiplicity (Cartesian Deduplication)");
   Put_Line("  3.1 [Assertion: One-to-Many match yields N records]");
   Res := Inner_Join((1 => R(1,"L")), (1 => R(1,"R1"), 2 => R(1,"R2")));
   Assert (Natural(Res.Length) = 2, "Failed 3.1");
   Put_Line("      PASS");

   Put_Line("  3.2 [Assertion: Many-to-One match yields N records]");
   Res := Inner_Join((1 => R(1,"L1"), 2 => R(1,"L2")), (1 => R(1,"R")));
   Assert (Natural(Res.Length) = 2, "Failed 3.2");
   Put_Line("      PASS");

   Put_Line("  3.3 [Assertion: Many-to-Many match yields Cartesian product (N*M)]");
   Res := Inner_Join((1 => R(1,"L1"), 2 => R(1,"L2")), (1 => R(1,"R1"), 2 => R(1,"R2")));
   Assert (Natural(Res.Length) = 4, "Failed 3.3");
   Put_Line("      PASS");

   Put_Line("TEST 4 - Error Handling and Variants");
   Put_Line("  4.1 [Assertion: Auto_Sort=True correctly sorts inverse inputs]");
   Res := Inner_Join((1 => R(2,"L2"), 2 => R(1,"L1")), (1 => R(1,"R1"), 2 => R(2,"R2")));
   Assert (Natural(Res.Length) = 2, "Failed 4.1");
   Put_Line("      PASS");

   Put_Line("  4.2 [Assertion: Auto_Sort=False on unsorted data raises Unsorted_Relation_Error]");
   begin
      Res := Inner_Join((1 => R(2,"L2"), 2 => R(1,"L1")), (1 => R(1,"R1")), Auto_Sort => False);
      Assert (False, "Should have raised exception");
   exception
      when Unsorted_Relation_Error => Put_Line("      PASS");
   end;

   Put_Line("  4.3 [Assertion: Unique_Key_Join succeeds on guaranteed unique keys]");
   Res := Unique_Key_Join((1 => R(1,"A"), 2 => R(2,"B")), (1 => R(1,"X")));
   Assert (Natural(Res.Length) = 1, "Failed 4.3");
   Put_Line("      PASS");

   Put_Line("  4.4 [Assertion: Unique_Key_Join raises Non_Unique_Key_Error for duplicate keys]");
   begin
      Res := Unique_Key_Join((1 => R(1,"A"), 2 => R(1,"B")), (1 => R(1,"X")));
      Assert (False, "Should have raised exception");
   exception
      when Non_Unique_Key_Error => Put_Line("      PASS");
   end;

   Put_Line("  4.5 [Assertion: Negative keys are correctly merged and sequenced]");
   Res := Inner_Join((1 => R(-5,"L1"), 2 => R(1,"L2")), (1 => R(-5,"R1")));
   Assert (Natural(Res.Length) = 1 and then Res.Element(1).Left_Row.Key = -5, "Failed 4.5");
   Put_Line("      PASS");

end Tests;
