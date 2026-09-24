with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Semi_Space_Collector; use Semi_Space_Collector;

procedure Tests is
   H : Heap;
   Roots : Root_Set (1 .. 3) := (others => Null_Id);
begin
   Put_Line ("========================================");
   Put_Line ("V&V TEST SUITE: SEMI-SPACE GC");
   Put_Line ("Assumption: Code is broken/non-functional.");
   Put_Line ("Goal: Disprove assumption through verification.");
   Put_Line ("========================================");

   --  TEST 1: Initialization Integrity
   Put_Line ("TEST 1 - Initialization Integrity");
   Put_Line ("  1.1 Assert Heap starts empty");
   Initialize (H);
   Assert (Active_Space_Usage (H) = 0, "Heap not empty");
   Put_Line ("  1.2 Assert Space_A is default active");
   Assert (Get_Current_Space (H) = Space_A, "Wrong default space");
   Put_Line ("      PASS");

   --  TEST 2: Basic Allocation
   Put_Line ("TEST 2 - Basic Allocation");
   Put_Line ("  2.1 Assert Alloc_Ptr increments correctly");
   declare
      N1 : constant Object_Id := Allocate (H, Val => 100);
   begin
      Assert (Active_Space_Usage (H) = 1, "Usage did not increment");
      Put_Line ("  2.2 Assert Node values persist accurately");
      Assert (Get_Node(H, N1).Value = 100, "Node data corrupted");
   end;
   Put_Line ("      PASS");

   --  TEST 3: OOM Boundary condition
   Put_Line ("TEST 3 - OOM Boundary (Space_Size = 1024)");
   Put_Line ("  3.1 Assert Out_Of_Memory raised on 1025th allocation");
   Initialize (H);
   begin
      for I in 1 .. 1025 loop
         declare
            Dummy : Object_Id := Allocate (H, I);
            pragma Warnings (Off, Dummy);
         begin
            null;
         end;
      end loop;
      Assert (False, "OOM not raised!");
   exception
      when Out_Of_Memory =>
         Put_Line ("      PASS");
   end;

   --  TEST 4: Garbage Collection (No Roots)
   Put_Line ("TEST 4 - GC with Empty Root Set");
   Put_Line ("  4.1 Assert all unreferenced memory is reclaimed");
   Initialize (H);
   declare
      N1 : Object_Id := Allocate (H, 50);
      N2 : Object_Id := Allocate (H, 60);
      pragma Warnings (Off, N1);
      pragma Warnings (Off, N2);
   begin
      Roots := (others => Null_Id);
      Collect_Cheney (H, Roots);
      Assert (Active_Space_Usage (H) = 0, "Memory leak detected");
      Put_Line ("  4.2 Assert active space swapped");
      Assert (Get_Current_Space (H) = Space_B, "Space swap failed");
   end;
   Put_Line ("      PASS");

   --  TEST 5: Garbage Collection (1 Root)
   Put_Line ("TEST 5 - Cheney GC with 1 Root");
   Put_Line ("  5.1 Assert referenced memory is preserved");
   Initialize (H);
   declare
      N1 : constant Object_Id := Allocate (H, 999);
      N2 : Object_Id := Allocate (H, 888);
      pragma Warnings (Off, N2);
   begin
      Roots := (1 => N1, others => Null_Id);
      Collect_Cheney (H, Roots);
      Assert (Active_Space_Usage (H) = 1, "Wrong object count copied");
      Put_Line ("  5.2 Assert root pointer is updated to new address");
      Assert (Roots(1) = 0, "Root not repointed");
      Assert (Get_Node(H, Roots(1)).Value = 999, "Data corrupted in To-Space");
   end;
   Put_Line ("      PASS");

   --  TEST 6: Linked List Traversal
   Put_Line ("TEST 6 - Cheney GC on Linked List");
   Put_Line ("  6.1 Assert deep linear references are copied");
   Initialize (H);
   declare
      N3 : constant Object_Id := Allocate (H, 3);
      N2 : constant Object_Id := Allocate (H, 2, Left => N3);
      N1 : constant Object_Id := Allocate (H, 1, Left => N2);
   begin
      Roots := (1 => N1, others => Null_Id);
      Collect_Cheney (H, Roots);
      Assert (Active_Space_Usage (H) = 3, "List copy failed");
      Assert (Get_Node(H, Roots(1)).Value = 1, "Head invalid");
      Assert (Get_Node(H, Get_Node(H, Roots(1)).Left).Value = 2, "Mid invalid");
   end;
   Put_Line ("      PASS");

   --  TEST 7: Binary Tree Traversal
   Put_Line ("TEST 7 - Cheney GC on Binary Tree");
   Put_Line ("  7.1 Assert breadth-first tree copy preserves structure");
   Initialize (H);
   declare
      N2 : constant Object_Id := Allocate (H, 20);
      N3 : constant Object_Id := Allocate (H, 30);
      N1 : constant Object_Id := Allocate (H, 10, Left => N2, Right => N3);
   begin
      Roots := (1 => N1, others => Null_Id);
      Collect_Cheney (H, Roots);
      Assert (Active_Space_Usage (H) = 3, "Tree copy failed");
      Assert (Get_Node(H, Get_Node(H, Roots(1)).Right).Value = 30, "Right node broken");
   end;
   Put_Line ("      PASS");

   --  TEST 8: Cyclic References (Cheney)
   Put_Line ("TEST 8 - Cheney GC on Cyclic Graph");
   Put_Line ("  8.1 Assert no infinite loop on cyclical pointers");
   Initialize (H);
   declare
      N1 : constant Object_Id := Allocate (H, 100);
      N2 : constant Object_Id := Allocate (H, 200, Left => N1);
   begin
      -- Creating cycle: N1 -> N2 -> N1
      if Get_Current_Space (H) = Space_A then
         H.A(Integer(N1)).Left := N2;
      else
         H.B(Integer(N1)).Left := N2;
      end if;
      Roots := (1 => N1, others => Null_Id);
      Collect_Cheney (H, Roots);
      Assert (Active_Space_Usage (H) = 2, "Cycle duplicated memory");
   end;
   Put_Line ("      PASS");

   --  TEST 9: Forwarding Pointer Integrity
   Put_Line ("TEST 9 - Shared Reference Forwarding");
   Put_Line ("  9.1 Assert multiple roots to same object don't duplicate it");
   Initialize (H);
   declare
      N1 : constant Object_Id := Allocate (H, 777);
   begin
      Roots := (1 => N1, 2 => N1, 3 => N1);
      Collect_Cheney (H, Roots);
      Assert (Active_Space_Usage (H) = 1, "Object duplicated instead of shared");
      Assert (Roots(1) = Roots(2), "Root references diverged");
   end;
   Put_Line ("      PASS");

   --  TEST 10: Recursive GC Variant
   Put_Line ("TEST 10 - Standard Recursive GC Variant");
   Put_Line ("  10.1 Assert recursive variant correctly handles basic tree");
   Initialize (H);
   declare
      N2 : constant Object_Id := Allocate (H, 20);
      N3 : constant Object_Id := Allocate (H, 30);
      N1 : constant Object_Id := Allocate (H, 10, Left => N2, Right => N3);
   begin
      Roots := (1 => N1, others => Null_Id);
      Collect_Recursive (H, Roots);
      Assert (Active_Space_Usage (H) = 3, "Recursive copy failed");
      Assert (Get_Node(H, Roots(1)).Value = 10, "Root data invalid");
   end;
   Put_Line ("      PASS");

   --  TEST 11: Cyclic References (Recursive)
   Put_Line ("TEST 11 - Recursive GC on Cyclic Graph");
   Put_Line ("  11.1 Assert recursive variant avoids infinite call stack");
   Initialize (H);
   declare
      N1 : constant Object_Id := Allocate (H, 500);
      N2 : constant Object_Id := Allocate (H, 600, Left => N1);
   begin
      if Get_Current_Space (H) = Space_A then
         H.A(Integer(N1)).Right := N2; -- Make cycle
      else
         H.B(Integer(N1)).Right := N2; -- Make cycle
      end if;
      Roots := (1 => N1, others => Null_Id);
      Collect_Recursive (H, Roots);
      Assert (Active_Space_Usage (H) = 2, "Cycle failed in recursive");
   end;
   Put_Line ("      PASS");

   --  TEST 12: Null Pointers in Roots
   Put_Line ("TEST 12 - Null Root Handling");
   Put_Line ("  12.1 Assert GC safely ignores Null_Id in Root_Set");
   Initialize (H);
   Roots := (others => Null_Id);
   Collect_Cheney (H, Roots);
   Assert (Roots(1) = Null_Id, "Null_Id mutated");
   Put_Line ("      PASS");

   --  TEST 13: Memory Full Survival
   Put_Line ("TEST 13 - Garbage Collection Survival Rate");
   Put_Line ("  13.1 Assert GC successfully defragments a fragmented heap");
   Initialize (H);
   declare
      Last_Node : Object_Id := Null_Id;
   begin
      -- Fill heap completely, keeping only the last allocated node
      for I in 0 .. 1023 loop
         Last_Node := Allocate (H, I);
      end loop;
      Roots := (1 => Last_Node, others => Null_Id);
      Collect_Cheney (H, Roots);
      -- Should only have 1 node left (the one we kept a reference to)
      Assert (Active_Space_Usage (H) = 1, "Defragmentation failed");
   end;
   Put_Line ("      PASS");
   
   Put_Line ("========================================");
   Put_Line ("ALL 13 TESTS PASSED. ASSUMPTION DISPROVED.");
   Put_Line ("========================================");

end Tests;
