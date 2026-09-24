--  tests.adb
--  Test suite validating V&V assumptions. Fails when bugs are present.
--  Tests assume failure by default; passing them disproves the assumption.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Garbage_Collection; use Garbage_Collection;

procedure Tests is
   N1, N2, N3, N4 : Node_ID;
begin
   Put_Line ("=======================================");
   Put_Line ("STARTING GARBAGE COLLECTION TEST SUITE");
   Put_Line ("=======================================");

   -- TEST 1 - Initialization & State
   Put_Line ("TEST 1 - Initialization State");
   Garbage_Collection.Initialize;
   Put_Line ("  1.1 Assert Initial Memory is Empty");
   Assert (Get_Allocated_Count = 0, "Heap not empty on init");
   Put_Line ("      PASS");

   -- TEST 2 - Basic Allocation
   Put_Line ("TEST 2 - Basic Allocation");
   N1 := Allocate;
   Put_Line ("  2.1 Assert Allocation Succeeds");
   Assert (Is_Allocated (N1), "Node not marked active");
   Put_Line ("  2.2 Assert Allocated Count = 1");
   Assert (Get_Allocated_Count = 1, "Count mismatch");
   Put_Line ("      PASS");

   -- TEST 3 - Out of Memory Exception
   Put_Line ("TEST 3 - Out Of Memory Edge Case");
   Put_Line ("  3.1 Assert allocating past limit raises Out_Of_Memory_Error");
   begin
      for I in 2 .. 101 loop -- Max is 100
         N2 := Allocate;
      end loop;
      Assert (False, "Did not raise Out_Of_Memory_Error");
   exception
      when Out_Of_Memory_Error =>
         Put_Line ("      PASS");
   end;

   -- Reset for Mark and Sweep tests
   Garbage_Collection.Initialize;

   -- TEST 4 - Mark and Sweep: No Roots
   Put_Line ("TEST 4 - Mark & Sweep: No Roots");
   N1 := Allocate; N2 := Allocate;
   Run_Mark_And_Sweep;
   Put_Line ("  4.1 Assert unconnected objects are swept");
   Assert (Get_Allocated_Count = 0, "Unreachable objects were not swept");
   Put_Line ("      PASS");

   -- TEST 5 - Mark and Sweep: Root Preservation
   Put_Line ("TEST 5 - Mark & Sweep: Root Preservation");
   N1 := Allocate; 
   Add_Root (N1);
   Run_Mark_And_Sweep;
   Put_Line ("  5.1 Assert Root object is preserved");
   Assert (Is_Allocated (N1), "Root object swept incorrectly");
   Put_Line ("  5.2 Assert Age is incremented (Generational feature)");
   Assert (Get_Age (N1) = 1, "Age not incremented");
   Put_Line ("      PASS");

   -- TEST 6 - Mark and Sweep: Chained Graph
   Put_Line ("TEST 6 - Mark & Sweep: Chained Preservation");
   Garbage_Collection.Initialize;
   N1 := Allocate; N2 := Allocate; N3 := Allocate;
   Add_Root (N1);
   Add_Edge (N1, N2, Tracing);
   Add_Edge (N2, N3, Tracing);
   Run_Mark_And_Sweep;
   Put_Line ("  6.1 Assert N1, N2, N3 are preserved");
   Assert (Get_Allocated_Count = 3, "Chained objects not properly traced");
   Put_Line ("      PASS");

   -- TEST 7 - Mark and Sweep: Cycles without root
   Put_Line ("TEST 7 - Mark & Sweep: Unreachable Cycles");
   Garbage_Collection.Initialize;
   N1 := Allocate; N2 := Allocate;
   Add_Edge (N1, N2, Tracing);
   Add_Edge (N2, N1, Tracing); -- Circular reference
   Run_Mark_And_Sweep;
   Put_Line ("  7.1 Assert cycle without root is swept");
   Assert (Get_Allocated_Count = 0, "Circular unrooted reference leaked");
   Put_Line ("      PASS");

   -- TEST 8 - Reference Counting: Increment
   Put_Line ("TEST 8 - Ref Counting: Increment");
   Garbage_Collection.Initialize;
   N1 := Allocate; N2 := Allocate;
   Add_Edge (N1, N2, Ref_Counting);
   Put_Line ("  8.1 Assert Edge target gets Ref Count + 1");
   Assert (Get_Ref_Count (N2) = 1, "Ref count not incremented");
   Put_Line ("      PASS");

   -- TEST 9 - Reference Counting: Decrement and Free
   Put_Line ("TEST 9 - Ref Counting: Free on Zero");
   Remove_Edge (N1, N2, Ref_Counting);
   Put_Line ("  9.1 Assert Node is freed when ref count reaches zero");
   Assert (not Is_Allocated (N2), "Node not freed by ref count");
   Put_Line ("      PASS");

   -- TEST 10 - Reference Counting: Cascading Deletes
   Put_Line ("TEST 10 - Ref Counting: Cascading Delete");
   Garbage_Collection.Initialize;
   N1 := Allocate; N2 := Allocate; N3 := Allocate;
   Add_Root (N1); 
   Add_Edge (N1, N2, Ref_Counting);
   Add_Edge (N2, N3, Ref_Counting);
   Remove_Root (N1); -- This drops N1 to 0, which should cascade drop N2, then N3.
   Put_Line ("  10.1 Assert cascading delete clears all objects");
   Assert (Get_Allocated_Count = 0, "Cascading delete failed in Ref Counting");
   Put_Line ("      PASS");

   -- TEST 11 - Reference Counting: The Cycle Leak Trap
   Put_Line ("TEST 11 - Ref Counting: Known Weakness (Cycle Leaks)");
   Garbage_Collection.Initialize;
   N1 := Allocate; N2 := Allocate;
   Add_Edge (N1, N2, Ref_Counting);
   Add_Edge (N2, N1, Ref_Counting);
   -- Add both to roots to keep them alive initially
   Add_Root (N1); Add_Root (N2);
   -- Now remove both from roots - the cycle should keep them alive (leak)
   Remove_Root (N1); Remove_Root (N2);
   Put_Line ("  11.1 Assert circular references leak in pure Ref Counting");
   Assert (Get_Allocated_Count = 2, "Cycle didn't leak - unexpected behavior!");
   Put_Line ("      PASS");

   -- TEST 12 - Generational GC: Minor Collection
   Put_Line ("TEST 12 - Generational GC: Minor cycle");
   Garbage_Collection.Initialize;
   N1 := Allocate; 
   Add_Root (N1);
   Run_Mark_And_Sweep; -- Promotes N1 to Age 1 (Old Gen)
   N2 := Allocate;     -- N2 is Age 0 (Young Gen), no roots
   Run_Minor_Collection;
   Put_Line ("  12.1 Assert young unreferenced object is swept");
   Assert (not Is_Allocated (N2), "Young object not swept");
   Put_Line ("  12.2 Assert old object is kept safe");
   Assert (Is_Allocated (N1), "Old object swept during minor collection");
   Put_Line ("      PASS");

   -- TEST 13 - Generational GC: Remembered Sets Simulation
   Put_Line ("TEST 13 - Generational GC: Old to Young refs");
   N3 := Allocate; -- N3 is Age 0
   Add_Edge (N1, N3, Tracing); -- N1 (Age 1) -> N3 (Age 0)
   Run_Minor_Collection;
   Put_Line ("  13.1 Assert young object referenced by old is preserved");
   Assert (Is_Allocated (N3), "Remembered set failed, N3 swept");
   Put_Line ("      PASS");

   -- TEST 14 - Edge Case: Invalid Nodes
   Put_Line ("TEST 14 - Edge Case: Invalid Node Reference");
   Put_Line ("  14.1 Assert Exception raised on Invalid Edge");
   begin
      Add_Edge (Null_Node, N1, Tracing);
      Assert (False, "Allowed Null_Node as edge origin");
   exception
      when Invalid_Node_Error =>
         Put_Line ("      PASS");
   end;

   -- TEST 15 - Edge Case: Max Edges Array Overflow
   Put_Line ("TEST 15 - Edge Case: Max Edge Overflow");
   Garbage_Collection.Initialize;
   N1 := Allocate;
   Put_Line ("  15.1 Assert Exception on too many references");
   begin
      for I in 1 .. 6 loop -- Max_Refs is 5
         Add_Edge (N1, Allocate, Tracing);
      end loop;
      Assert (False, "Allowed exceeding Max_Edges");
   exception
      when Max_Edges_Error =>
         Put_Line ("      PASS");
   end;

   Put_Line ("=======================================");
   Put_Line ("ALL 15 TESTS PASSED. Assumptions disproved.");
   Put_Line ("=======================================");
end Tests;
