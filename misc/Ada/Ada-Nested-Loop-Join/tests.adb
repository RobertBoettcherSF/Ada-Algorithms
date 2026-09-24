with Ada.Text_IO; use Ada.Text_IO;
with Nested_Loop_Join; use Nested_Loop_Join;
with Ada.Exceptions;

procedure Tests is
   Total_Tests : Integer := 0;
   Passed_Tests : Integer := 0;

   -- Custom assertion logic enforcing pessimistic testing mindset
   procedure Assert (Condition : Boolean; Assumption : String) is
   begin
      Total_Tests := Total_Tests + 1;
      Put ("  " & Assumption);
      if Condition then
         Put_Line (" -> PASS (Assumption disproven)");
         Passed_Tests := Passed_Tests + 1;
      else
         Put_Line (" -> FAIL (Assumption proved true! Code broken)");
      end if;
   end Assert;

   -- Reusable Mock Data
   Empty_Rel : Tuple_Array (1 .. 0);
   Outer_Mock : Tuple_Array := ((1, 10), (2, 20), (3, 30));
   Inner_Mock : Tuple_Array := ((2, 200), (3, 300), (3, 301), (4, 400));
   -- Notice Key=3 has a 1-to-N match in Inner_Mock
   
   Idx : Inner_Index;
   Res : Joined_Relation;
begin
   Put_Line ("--- V&V PESSIMISTIC TEST SUITE ---");

   Put_Line ("TEST 1 - Naive Join Edge Cases");
   Res := Naive_Nested_Loop_Join (Empty_Rel, Empty_Rel);
   Assert (Natural(Res.Length) = 0, "1.1 Assume fails/crashes on Double Empty relations");
   
   Res := Naive_Nested_Loop_Join (Outer_Mock, Empty_Rel);
   Assert (Natural(Res.Length) = 0, "1.2 Assume ignores Empty Inner and returns garbage");
   
   Res := Naive_Nested_Loop_Join (Empty_Rel, Inner_Mock);
   Assert (Natural(Res.Length) = 0, "1.3 Assume ignores Empty Outer and throws Bounds error");

   Put_Line ("TEST 2 - Naive Join Core Logic");
   Res := Naive_Nested_Loop_Join (Outer_Mock, Inner_Mock);
   Assert (Natural(Res.Length) = 3, "2.1 Assume fails to process 1-to-N matches (expect 3 tuples)");
   -- Expected IDs: 2 matched once, 3 matched twice.
   Assert (Res.Element(1).Outer_Key = 2 and Res.Element(2).Outer_Key = 3, "2.2 Assume returned tuples are disorganized or wrong");

   Put_Line ("TEST 3 - Block Nested Join Invalid States");
   begin
      Res := Block_Nested_Loop_Join (Outer_Mock, Inner_Mock, 0);
      Assert (False, "3.1 Assume size 0 causes infinite loop (Constraint_Error ignored)");
   exception
      when Invalid_Block_Size =>
         Assert (True, "3.1 Assume size 0 causes infinite loop (Caught Invalid_Block_Size)");
   end;

   Put_Line ("TEST 4 - Block Nested Join Valid Boundaries");
   Res := Block_Nested_Loop_Join (Outer_Mock, Inner_Mock, 1);
   Assert (Natural(Res.Length) = 3, "4.1 Assume size 1 breaks logic (should act like Naive)");

   Res := Block_Nested_Loop_Join (Outer_Mock, Inner_Mock, 100);
   Assert (Natural(Res.Length) = 3, "4.2 Assume block > array length crashes program");

   Res := Block_Nested_Loop_Join (Outer_Mock, Inner_Mock, 2);
   Assert (Natural(Res.Length) = 3, "4.3 Assume block size not strictly divisible drops tuples");

   Put_Line ("TEST 5 - Index Construction");
   Idx := Build_Index (Empty_Rel);
   Assert (Idx.Is_Empty, "5.1 Assume empty index construction throws null pointer");

   Idx := Build_Index (Inner_Mock);
   Assert (Natural(Idx.Length) = 3, "5.2 Assume index drops duplicate keys (Keys 2, 3, 4 = 3 buckets)");
   Assert (Natural(Idx.Element(3).Length) = 2, "5.3 Assume inner vector does not stack 1-to-N duplicates");

   Put_Line ("TEST 6 - Index Join Edge Cases & Core Logic");
   Res := Index_Nested_Loop_Join (Outer_Mock, Build_Index (Empty_Rel));
   Assert (Natural(Res.Length) = 0, "6.1 Assume missing keys crash index lookup");

   Res := Index_Nested_Loop_Join (Outer_Mock, Idx);
   Assert (Natural(Res.Length) = 3, "6.2 Assume index lookup fails to return all multi-matches");
   Assert (Res.Element(3).Inner_Data = 301, "6.3 Assume index joins fetch the wrong payload data");

   Put_Line ("----------------------------------");
   Put_Line ("Total: " & Integer'Image(Total_Tests) & " | Passed: " & Integer'Image(Passed_Tests));
   if Total_Tests = Passed_Tests then
      Put_Line ("STATUS: SUCCEEDED. All pessimistic assumptions disproven.");
   else
      Put_Line ("STATUS: FAILED. Bugs detected.");
   end if;
end Tests;
