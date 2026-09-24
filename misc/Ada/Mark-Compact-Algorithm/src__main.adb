-- main.adb
-- Demonstration program for the Mark-Compact Garbage Collection algorithm.
--
-- This program demonstrates the basic usage of the mark-compact GC:
-- 1. Initialize a heap
-- 2. Allocate objects
-- 3. Create an object graph with references
-- 4. Run the mark phase from root references
-- 5. Run compaction to reclaim unused memory
--
-- The demo creates 3 objects where Obj1 -> Obj3, and only Obj1 is reachable
-- from the root. After mark-compact, Obj2 (unreachable) should be reclaimed.

with Ada.Text_IO; use Ada.Text_IO;
with Mark_Compact; use Mark_Compact;

procedure Main is
   Heap : Heap_Array;
   Roots : Root_Array(1 .. 1);
   Obj1, Obj2, Obj3 : Address;
begin
   Put_Line("--- Mark-Compact GC Demo ---");
   Init_Heap(Heap);

   -- Allocate objects
   Obj1 := Allocate(Heap, 100);
   Obj2 := Allocate(Heap, 200);
   Obj3 := Allocate(Heap, 300);

   -- Create graph: Obj1 -> Obj3
   Heap(Obj1).Refs(1) := Obj3;

   -- Root points only to Obj1
   Roots(1) := Obj1;

   -- Execute Mark Phase
   Mark(Heap, Roots);
   Put_Line("Mark phase completed. (Obj2 is unreachable)");

   -- Execute Compaction (LISP 2 variant)
   Compact_LISP2(Heap);
   Put_Line("LISP 2 Compaction completed.");
   
   if Heap(1).Data_Value = 100 and Heap(2).Data_Value = 300 then
      Put_Line("Heap successfully compacted! Obj2 was collected.");
   end if;

end Main;
