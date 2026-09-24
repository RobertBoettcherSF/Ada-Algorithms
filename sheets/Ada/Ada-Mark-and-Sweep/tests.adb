-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Mark_And_Sweep; use Mark_And_Sweep;

procedure Tests is
   Heap : Heap_Array;
   Idx1, Idx2, Idx3 : Object_Index;
   
   -- Helper to print test results cleanly
   procedure Report(Assertion_Name : String; Result : Boolean) is
   begin
      if Result then
         Put_Line("    PASS : " & Assertion_Name);
      else
         Put_Line("    FAIL : " & Assertion_Name);
      end if;
   end Report;

begin
   Put_Line("==================================================");
   Put_Line("   GARBAGE COLLECTION V&V TEST SUITE (15 TESTS)   ");
   Put_Line("==================================================");
   Put_Line("Assumption: Code fails to manage memory safely.");
   Put_Line("Goal: Tests PASS by proving this assumption FALSE." & ASCII.LF);

   -------------------------------------------------
   -- RECURSIVE VARIANTS
   -------------------------------------------------
   Put_Line("TEST 1 - Recursive: Empty & Unrooted Memory");
   Reset_Heap(Heap);
   Allocate(Heap, Idx1);
   Allocate(Heap, Idx2);
   Recursive_Mark_And_Sweep(Heap, Roots => (1 .. 0 => Null_Ptr));
   Report("1.1 Assert all unrooted objects are freed", Count_Allocated(Heap) = 0);

   Put_Line("TEST 2 - Recursive: Simple Root Preservation");
   Reset_Heap(Heap);
   Allocate(Heap, Idx1);
   Allocate(Heap, Idx2); -- unrooted
   Recursive_Mark_And_Sweep(Heap, Roots => (1 => Idx1));
   Report("2.1 Assert rooted object remains", Count_Allocated(Heap) = 1);
   Report("2.2 Assert correct object was preserved", Heap(Idx1).Is_Allocated = True);

   Put_Line("TEST 3 - Recursive: Deep Chain Preservation");
   Reset_Heap(Heap);
   Allocate(Heap, Idx1); Allocate(Heap, Idx2); Allocate(Heap, Idx3);
   Add_Reference(Heap, Idx1, Idx2, 1);
   Add_Reference(Heap, Idx2, Idx3, 1);
   Recursive_Mark_And_Sweep(Heap, Roots => (1 => Idx1));
   Report("3.1 Assert fully linked chain survives", Count_Allocated(Heap) = 3);

   Put_Line("TEST 4 - Recursive: Cycle Handling");
   Reset_Heap(Heap);
   Allocate(Heap, Idx1); Allocate(Heap, Idx2);
   Add_Reference(Heap, Idx1, Idx2, 1);
   Add_Reference(Heap, Idx2, Idx1, 1); -- Cycle!
   Recursive_Mark_And_Sweep(Heap, Roots => (1 => Idx1));
   Report("4.1 Assert algorithm doesn't hang and cycle survives", Count_Allocated(Heap) = 2);

   Put_Line("TEST 5 - Recursive: Unreachable Cycle Destruction");
   Reset_Heap(Heap);
   Allocate(Heap, Idx1); Allocate(Heap, Idx2);
   Add_Reference(Heap, Idx1, Idx2, 1);
   Add_Reference(Heap, Idx2, Idx1, 1);
   -- No roots passed!
   Recursive_Mark_And_Sweep(Heap, Roots => (1 .. 0 => Null_Ptr));
   Report("5.1 Assert unrooted cycles are destroyed", Count_Allocated(Heap) = 0);

   -------------------------------------------------
   -- ITERATIVE VARIANTS
   -------------------------------------------------
   Put_Line("TEST 6 - Iterative: Basic Functionality");
   Reset_Heap(Heap);
   Allocate(Heap, Idx1); Allocate(Heap, Idx2); Allocate(Heap, Idx3);
   Add_Reference(Heap, Idx1, Idx3, 2);
   Iterative_Mark_And_Sweep(Heap, Roots => (1 => Idx1));
   Report("6.1 Assert only root and its child remain", Count_Allocated(Heap) = 2);

   Put_Line("TEST 7 - Iterative: Null Roots Tolerance");
   Reset_Heap(Heap);
   Allocate(Heap, Idx1);
   Iterative_Mark_And_Sweep(Heap, Roots => (1 => Null_Ptr));
   Report("7.1 Assert Null_Ptr in root set safely sweeps all", Count_Allocated(Heap) = 0);

   Put_Line("TEST 8 - Iterative: Self-Referential Object");
   Reset_Heap(Heap);
   Allocate(Heap, Idx1);
   Add_Reference(Heap, Idx1, Idx1, 1);
   Iterative_Mark_And_Sweep(Heap, Roots => (1 => Idx1));
   Report("8.1 Assert self-referential roots survive without crash", Count_Allocated(Heap) = 1);

   Put_Line("TEST 9 - Iterative: Multiple Disjoint Roots");
   Reset_Heap(Heap);
   Allocate(Heap, Idx1); Allocate(Heap, Idx2); Allocate(Heap, Idx3);
   Iterative_Mark_And_Sweep(Heap, Roots => (1 => Idx1, 2 => Idx3));
   Report("9.1 Assert disjoint root trees are preserved", Count_Allocated(Heap) = 2);

   -------------------------------------------------
   -- TRICOLOR VARIANTS
   -------------------------------------------------
   Put_Line("TEST 10 - Tricolor: Basic Allocation");
   Reset_Heap(Heap);
   Allocate(Heap, Idx1); Allocate(Heap, Idx2);
   Add_Reference(Heap, Idx2, Idx1, 1);
   Tricolor_Mark_And_Sweep(Heap, Roots => (1 => Idx2));
   Report("10.1 Assert tricolor algorithm preserves linked nodes", Count_Allocated(Heap) = 2);

   Put_Line("TEST 11 - Tricolor: Complex Graph with Cycles");
   Reset_Heap(Heap);
   Allocate(Heap, Idx1); Allocate(Heap, Idx2); Allocate(Heap, Idx3);
   Add_Reference(Heap, Idx1, Idx2, 1);
   Add_Reference(Heap, Idx2, Idx3, 1);
   Add_Reference(Heap, Idx3, Idx1, 1);
   Tricolor_Mark_And_Sweep(Heap, Roots => (1 => Idx1));
   Report("11.1 Assert black/gray propagation handles dense cycles", Count_Allocated(Heap) = 3);

   Put_Line("TEST 12 - Tricolor: Dangling Color Reset Verification");
   Reset_Heap(Heap);
   Allocate(Heap, Idx1);
   Tricolor_Mark_And_Sweep(Heap, Roots => (1 => Idx1));
   Report("12.1 Assert colors reset to White after sweep", Heap(Idx1).Color = White);

   -------------------------------------------------
   -- ROBUSTNESS & ERROR HANDLING
   -------------------------------------------------
   Put_Line("TEST 13 - Error Handling: Out of Memory");
   Reset_Heap(Heap);
   begin
      for I in 1 .. 1001 loop
         Allocate(Heap, Idx1);
      end loop;
      Report("13.1 Assert Out_Of_Memory raised", False);
   exception
      when Out_Of_Memory => Report("13.1 Assert Out_Of_Memory raised", True);
      when others => Report("13.1 Assert Out_Of_Memory raised", False);
   end;

   Put_Line("TEST 14 - Error Handling: Invalid Reference Slots");
   Reset_Heap(Heap);
   Allocate(Heap, Idx1); Allocate(Heap, Idx2);
   begin
      Add_Reference(Heap, Idx1, Idx2, 5); -- Max is 2
      Report("14.1 Assert Invalid_Reference raised on bad slot", False);
   exception
      when Invalid_Reference => Report("14.1 Assert Invalid_Reference raised on bad slot", True);
      when others => Report("14.1 Assert Invalid_Reference raised on bad slot", False);
   end;

   Put_Line("TEST 15 - Error Handling: Reference to Unallocated");
   Reset_Heap(Heap);
   begin
      Add_Reference(Heap, 999, Null_Ptr, 1);
      Report("15.1 Assert Invalid_Reference on unallocated 'From' node", False);
   exception
      when Invalid_Reference => Report("15.1 Assert Invalid_Reference on unallocated 'From' node", True);
      when others => Report("15.1 Assert Invalid_Reference on unallocated 'From' node", False);
   end;

end Tests;
