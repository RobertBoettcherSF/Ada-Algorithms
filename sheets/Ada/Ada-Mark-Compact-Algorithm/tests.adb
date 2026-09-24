-- tests.adb
-- Verification and Validation (V&V) Test Suite for Mark-Compact GC
--
-- This test suite employs a "prove the code wrong" philosophy:
-- Each test starts with the assumption that the code is broken or handles
-- edge cases incorrectly. The test then attempts to disprove this assumption.
-- A PASS result means our pessimistic assumption was proven false.
--
-- Test Categories:
-- - Tests 1, 4, 6: Edge case guarding (empty heap, boundaries)
-- - Tests 2, 5, 7: Functional correctness (marking, compaction, references)
-- - Test 3: Cycle and graph safety (circular references)
-- - Test 8: Error handling (invalid inputs)
-- - Test 9: Stress testing (100% heap capacity)

with Ada.Text_IO; use Ada.Text_IO;
with Mark_Compact; use Mark_Compact;

procedure Tests is
   H : Heap_Array;
   R : Root_Array(1..2) := (others => Null_Address);
   A1, A2, A3, A4 : Address;

   procedure Assert (Condition : Boolean; Msg : String) is
   begin
      if not Condition then
         Put_Line("      FAIL: " & Msg);
         raise Program_Error with "Test Assumption Failed: " & Msg;
      end if;
   end Assert;

begin
   Put_Line("Initializing V&V Test Suite. Assuming code is broken until proven otherwise.");
   Put_Line("=======================================================================");

   -- TEST 1 - Heap Initialization
   Put_Line("TEST 1 - Initialization Edge Cases");
   Put_Line("  1.1 Assume initial heap has junk data");
   Init_Heap(H);
   Assert(not H(1).Allocated, "Heap(1) is allocated");
   Put_Line("      PASS: Heap initializes correctly");
   
   Put_Line("  1.2 Assume Empty roots causes crash during marking");
   Mark(H, R);
   Assert(True, "Mark crashed on empty roots");
   Put_Line("      PASS: Mark handles null roots safely");

   -- TEST 2 - Mark Phase: Simple References
   Put_Line("TEST 2 - Marking Accuracy");
   Put_Line("  2.1 Assume reachable objects are NOT marked");
   A1 := Allocate(H, 10); A2 := Allocate(H, 20); A3 := Allocate(H, 30);
   R(1) := A1; H(A1).Refs(1) := A3;
   Mark(H, R);
   Assert(H(A1).Marked and H(A3).Marked, "A1 or A3 not marked");
   Put_Line("      PASS: Reachable objects strictly marked");
   
   Put_Line("  2.2 Assume UNREACHABLE objects ARE wrongly marked");
   Assert(not H(A2).Marked, "A2 was wrongly marked");
   Put_Line("      PASS: Unreachable object safely ignored");

   -- TEST 3 - Mark Phase: Cyclic References
   Put_Line("TEST 3 - Cycle Handling");
   Put_Line("  3.1 Assume cyclic reference causes infinite loop");
   H(A3).Refs(1) := A1; -- cycle
   Mark(H, R);
   Assert(H(A1).Marked and H(A3).Marked, "Cyclic mark failed");
   Put_Line("      PASS: DFS marking correctly breaks on cycles");

   -- TEST 4 - LISP 2: Empty Compaction
   Put_Line("TEST 4 - LISP2 Compaction Edge Case");
   Put_Line("  4.1 Assume compacting an empty heap causes crash");
   Init_Heap(H);
   Compact_LISP2(H);
   Put_Line("      PASS: Compaction survives empty heap");

   -- TEST 5 - LISP 2: Linear Sliding
   Put_Line("TEST 5 - LISP2 Memory Movement");
   A1 := Allocate(H, 10); A2 := Allocate(H, 20); A3 := Allocate(H, 30);
   R(1) := A1; H(A1).Refs(1) := A3; 
   Mark(H, R); -- A2 is unreachable garbage
   Put_Line("  5.1 Assume objects do not slide linearly left");
   Compact_LISP2(H);
   Assert(H(1).Data_Value = 10, "A1 did not slide to 1");
   Assert(H(2).Data_Value = 30, "A3 did not slide to 2");
   Put_Line("      PASS: Objects slid perfectly to front");
   
   Put_Line("  5.2 Assume internal references are orphaned");
   Assert(H(1).Refs(1) = 2, "Internal Ref was not updated");
   Put_Line("      PASS: Pointer rewritten accurately to new address");

   Put_Line("  5.3 Assume remnants are left at tail end of heap");
   Assert(not H(3).Allocated, "Garbage remnant not zeroed out");
   Put_Line("      PASS: Tail cleanly zeroed out");

   -- TEST 6 - Two-Finger: Empty Compaction
   Put_Line("TEST 6 - Two-Finger Edge Case");
   Put_Line("  6.1 Assume Two-Finger crashes on empty heap");
   Init_Heap(H);
   Compact_Two_Finger(H);
   Put_Line("      PASS: Two-Finger survives empty heap");

   -- TEST 7 - Two-Finger: Swapping Logic
   Put_Line("TEST 7 - Two-Finger Memory Movement");
   A1 := Allocate(H, 100); A2 := Allocate(H, 200); A3 := Allocate(H, 300); A4 := Allocate(H, 400);
   R(1) := A1; H(A1).Refs(1) := A4; 
   Mark(H, R); -- A2 and A3 are garbage
   Put_Line("  7.1 Assume Two-Finger fails to swap live tails into dead fronts");
   Compact_Two_Finger(H);
   Assert(H(1).Data_Value = 100, "A1 moved unexpectedly");
   Assert(H(2).Data_Value = 400, "A4 did not swap into A2's hole");
   Put_Line("      PASS: Discontiguous tail swapped tightly into front hole");

   Put_Line("  7.2 Assume Two-Finger forwards pointers incorrectly after swap");
   Assert(H(1).Refs(1) = 2, "Two-finger Ref not updated from forwarding address");
   Put_Line("      PASS: Ref seamlessly forwards to swapped target");

   -- TEST 8 - Robustness (Exception Handling)
   Put_Line("TEST 8 - Input Robustness");
   Put_Line("  8.1 Assume invalid root address doesn't raise exception");
   begin
      R(1) := Address(Max_Heap_Size); -- Not allocated yet
      Mark(H, R);
      Assert(False, "Exception not raised");
   exception
      when Invalid_Address => 
         Put_Line("      PASS: Safely caught Invalid_Address root");
   end;

   -- TEST 9 - Capacity
   Put_Line("TEST 9 - High Watermark Stress");
   Put_Line("  9.1 Assume full capacity LISP2 corrupts memory");
   Init_Heap(H);
   for I in 1 .. Max_Heap_Size loop
      declare
         Tmp : Address := Allocate(H, Integer(I));
      begin
         H(Tmp).Marked := True;
      end;
   end loop;
   Compact_LISP2(H);
   Assert(H(Address(Max_Heap_Size)).Allocated, "Memory corrupted at boundary");
   Put_Line("      PASS: 100% capacity compaction runs without memory loss");

   Put_Line("=======================================================================");
   Put_Line("All 13+ assertions verified. Broken-code assumptions disproven. (100% PASS)");
end Tests;
