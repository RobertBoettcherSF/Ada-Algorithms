with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Cheneys_Algorithm; use Cheneys_Algorithm;

procedure Tests is
   State : GC_State;
   Roots : Root_Set (1 .. 2);
   R1, R2, R3, R4, R5 : Reference;
begin
   Put_Line ("=======================================");
   Put_Line ("Running Cheney's Algorithm Test Suite");
   Put_Line ("Philosophy: Assuming code is non-functional.");
   Put_Line ("Tests PASS when assumption is disproved.");
   Put_Line ("=======================================");

   -- TEST 1
   Put_Line ("TEST 1 - Initialization Bounds");
   Put_Line ("  1.1 [Assertion: Assume Free pointer is uninitialized/random]");
   Initialize (State);
   Assert (Get_Free_Pointer (State) = 1, "Assumption valid: Free pointer is not 1");
   Put_Line ("     PASS");

   -- TEST 2
   Put_Line ("TEST 2 - Single Object Allocation");
   Put_Line ("  1.1 [Assertion: Assume Allocate fails to move Free pointer]");
   R1 := Allocate (State, 42);
   Assert (Get_Free_Pointer (State) = 2, "Assumption valid: Free pointer not incremented");
   Put_Line ("     PASS");

   -- TEST 3
   Put_Line ("TEST 3 - Payload Data Integrity");
   Put_Line ("  1.1 [Assertion: Assume Allocate corrupts payload data]");
   Assert (Get_Node(State, R1).Data = 42, "Assumption valid: Data corrupted");
   Put_Line ("     PASS");

   -- TEST 4
   Put_Line ("TEST 4 - Heap Exhaustion (OOM)");
   Put_Line ("  1.1 [Assertion: Assume bounds checking is missing (Constraint_Error expected)]");
   begin
      declare
         Dummy : Reference;
      begin
         for I in 2 .. Max_Heap_Size + 1 loop
            Dummy := Allocate (State, 99);
         end loop;
         Assert (False, "Assumption valid: OOM bypassed");
      end;
   exception
      when Out_Of_Memory =>
         Put_Line ("     PASS");
   end;

   -- TEST 5
   Put_Line ("TEST 5 - Garbage Collect with No Roots");
   Put_Line ("  1.1 [Assertion: Assume GC retains garbage when roots are empty]");
   Initialize(State);
   R1 := Allocate (State, 100); -- Garbage
   Roots(1) := Null_Reference; Roots(2) := Null_Reference;
   Collect (State, Roots);
   Assert (Get_Free_Pointer (State) = 1, "Assumption valid: Garbage was not collected");
   Put_Line ("     PASS");

   -- TEST 6
   Put_Line ("TEST 6 - Garbage Collect with One Root");
   Put_Line ("  1.1 [Assertion: Assume GC destroys active root data]");
   Initialize(State);
   Roots(1) := Allocate (State, 555);
   Roots(2) := Null_Reference;
   Collect (State, Roots);
   Assert (Get_Free_Pointer (State) = 2, "Assumption valid: Root was lost");
   Assert (Get_Node(State, Roots(1)).Data = 555, "Assumption valid: Root data corrupted");
   Put_Line ("     PASS");

   -- TEST 7
   Put_Line ("TEST 7 - Partial Garbage Collection");
   Put_Line ("  1.1 [Assertion: Assume unlinked object (garbage) survives collection]");
   Initialize(State);
   Roots(1) := Allocate (State, 111);
   R2 := Allocate (State, 222); -- Not linked, should vanish
   Roots(2) := Null_Reference;
   Collect (State, Roots);
   Assert (Get_Free_Pointer (State) = 2, "Assumption valid: R2 survived GC");
   Put_Line ("     PASS");

   -- TEST 8
   Put_Line ("TEST 8 - Linked Object Preservation");
   Put_Line ("  1.1 [Assertion: Assume GC fails to traverse child references]");
   Initialize(State);
   R2 := Allocate (State, 222); 
   Roots(1) := Allocate (State, 111, Ref_1 => R2); -- Linked
   Collect (State, Roots);
   Assert (Get_Free_Pointer (State) = 3, "Assumption valid: Child R2 lost");
   Assert (Get_Node(State, Get_Node(State, Roots(1)).Ref_1).Data = 222, "Assumption valid: Link broken");
   Put_Line ("     PASS");

   -- TEST 9
   Put_Line ("TEST 9 - Cyclic Reference Handling (A -> B -> A)");
   Put_Line ("  1.1 [Assertion: Assume cycles cause infinite recursion/duplication]");
   Initialize(State);
   R2 := Allocate (State, 200);
   R1 := Allocate (State, 100, Ref_1 => R2);
   -- Create cycle manually
   State.Spaces(State.From_ID).Memory(R2).Ref_1 := R1; 
   Roots(1) := R1;
   Collect (State, Roots);
   -- Should only consume 2 blocks total
   Assert (Get_Free_Pointer (State) = 3, "Assumption valid: Infinite loop or duplication occurred");
   Put_Line ("     PASS");

   -- TEST 10
   Put_Line ("TEST 10 - Shared Reference (Diamond Topology)");
   Put_Line ("  1.1 [Assertion: Assume shared nodes are duplicated incorrectly]");
   Initialize(State);
   R3 := Allocate (State, 300);
   Roots(1) := Allocate (State, 100, Ref_1 => R3);
   Roots(2) := Allocate (State, 200, Ref_1 => R3);
   Collect (State, Roots);
   Assert (Get_Free_Pointer (State) = 4, "Assumption valid: Shared node duplicated");
   Assert (Get_Node(State, Roots(1)).Ref_1 = Get_Node(State, Roots(2)).Ref_1, "Assumption valid: Nodes do not point to same child");
   Put_Line ("     PASS");

   -- TEST 11
   Put_Line ("TEST 11 - BFS Ordering Enforcement");
   Put_Line ("  1.1 [Assertion: Assume Cheney's BFS property is violated]");
   Initialize(State);
   R4 := Allocate (State, 400);
   R5 := Allocate (State, 500);
   R2 := Allocate (State, 200, Ref_1 => R4);
   R3 := Allocate (State, 300, Ref_1 => R5);
   Roots(1) := Allocate (State, 100, Ref_1 => R2, Ref_2 => R3);
   Roots(2) := Null_Reference;
   Collect (State, Roots);
   -- Tree: 100 -> (200->400, 300->500)
   -- BFS Order must strictly be: 100, 200, 300, 400, 500
   Assert (Get_Node(State, 1).Data = 100, "Assumption valid: BFS Node 1 incorrect");
   Assert (Get_Node(State, 2).Data = 200, "Assumption valid: BFS Node 2 incorrect");
   Assert (Get_Node(State, 3).Data = 300, "Assumption valid: BFS Node 3 incorrect");
   Assert (Get_Node(State, 4).Data = 400, "Assumption valid: BFS Node 4 incorrect");
   Assert (Get_Node(State, 5).Data = 500, "Assumption valid: BFS Node 5 incorrect");
   Put_Line ("     PASS");

   -- TEST 12
   Put_Line ("TEST 12 - Space Swapping (Ping-Pong)");
   Put_Line ("  1.1 [Assertion: Assume subsequent GCs fail to toggle Active spaces]");
   Initialize(State);
   Assert (Get_From_Space_ID (State) = Space_A, "Initial state bad");
   Collect (State, Roots);
   Assert (Get_From_Space_ID (State) = Space_B, "Assumption valid: GC did not swap to B");
   Collect (State, Roots);
   Assert (Get_From_Space_ID (State) = Space_A, "Assumption valid: GC did not swap back to A");
   Put_Line ("     PASS");

   -- TEST 13
   Put_Line ("TEST 13 - Self-Referential Robustness");
   Put_Line ("  1.1 [Assertion: Assume A->A pointers crash the collector]");
   Initialize(State);
   R1 := Allocate (State, 123);
   State.Spaces(State.From_ID).Memory(R1).Ref_1 := R1;
   Roots(1) := R1;
   Collect (State, Roots);
   Assert (Get_Node(State, Roots(1)).Ref_1 = Roots(1), "Assumption valid: Self-reference lost");
   Put_Line ("     PASS");

end Tests;
