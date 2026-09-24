-- mark_compact.adb
-- Implementation of the Mark-Compact garbage collection algorithms.

package body Mark_Compact is

   procedure Init_Heap (Heap : out Heap_Array) is
   begin
      for I in Heap'Range loop
         Heap(I) := (Allocated => False, Marked => False, 
                     Forwarding_Address => Null_Address, 
                     Refs => (others => Null_Address), Data_Value => 0);
      end loop;
   end Init_Heap;

   function Allocate (Heap : in out Heap_Array; Val : Integer) return Address is
   begin
      for I in Heap'Range loop
         if not Heap(I).Allocated then
            Heap(I).Allocated := True;
            Heap(I).Marked := False;
            Heap(I).Data_Value := Val;
            Heap(I).Forwarding_Address := Null_Address;
            Heap(I).Refs := (others => Null_Address);
            return I;
         end if;
      end loop;
      raise Heap_Overflow;
   end Allocate;

   procedure Mark (Heap : in out Heap_Array; Roots : Root_Array) is
      -- We use an explicit stack to prevent recursion depth issues (DFS)
      Stack : array (1 .. Max_Heap_Size) of Address;
      Top : Natural := 0;
      Curr : Address;
   begin
      -- Push valid roots onto stack and mark them
      for I in Roots'Range loop
         if Roots(I) /= Null_Address then
            if not Heap(Roots(I)).Allocated then
               raise Invalid_Address;
            end if;
            if not Heap(Roots(I)).Marked then
               Top := Top + 1;
               Stack(Top) := Roots(I);
               Heap(Roots(I)).Marked := True;
            end if;
         end if;
      end loop;

      -- Depth-First Search for reachable objects
      while Top > 0 loop
         Curr := Stack(Top);
         Top := Top - 1;
         
         for J in Heap(Curr).Refs'Range loop
            declare
               Ref : Address := Heap(Curr).Refs(J);
            begin
               if Ref /= Null_Address and then Heap(Ref).Allocated then
                  -- Avoid infinite loops on cyclic references
                  if not Heap(Ref).Marked then
                     Heap(Ref).Marked := True;
                     Top := Top + 1;
                     Stack(Top) := Ref;
                  end if;
               end if;
            end;
         end loop;
      end loop;
   end Mark;

   --------------------------------------------------------------------------
   -- LISP 2 (Sliding Compaction)
   --------------------------------------------------------------------------
   procedure Compact_LISP2 (Heap : in out Heap_Array) is
      Free_Ptr : Address := 1;
   begin
      -- Pass 1: Compute forwarding addresses for all marked objects
      for I in Heap'Range loop
         if Heap(I).Allocated and then Heap(I).Marked then
            Heap(I).Forwarding_Address := Free_Ptr;
            if Free_Ptr < Heap'Last then
               Free_Ptr := Free_Ptr + 1;
            end if;
         end if;
      end loop;

      -- Pass 2: Update references in marked objects to their new locations
      for I in Heap'Range loop
         if Heap(I).Allocated and then Heap(I).Marked then
            for J in Heap(I).Refs'Range loop
               declare
                  Ref : Address := Heap(I).Refs(J);
               begin
                  if Ref /= Null_Address and then Heap(Ref).Allocated and then Heap(Ref).Marked then
                     Heap(I).Refs(J) := Heap(Ref).Forwarding_Address;
                  end if;
               end;
            end loop;
         end if;
      end loop;

      -- Pass 3: Move the objects and clean up
      for I in Heap'Range loop
         if Heap(I).Allocated and then Heap(I).Marked then
            declare
               Dest : constant Address := Heap(I).Forwarding_Address;
            begin
               if Dest /= I then
                  Heap(Dest) := Heap(I);
               end if;
               -- Clear metadata for next GC cycle
               Heap(Dest).Marked := False;
               Heap(Dest).Forwarding_Address := Null_Address;
            end;
         end if;
      end loop;

      -- Nullify the remainder of the heap
      -- Only nullify if Free_Ptr is within heap bounds
      if Free_Ptr <= Heap'Last then
         for I in Free_Ptr .. Heap'Last loop
            Heap(I).Allocated := False;
            Heap(I).Marked := False;
            Heap(I).Refs := (others => Null_Address);
         end loop;
      end if;
   end Compact_LISP2;

   --------------------------------------------------------------------------
   -- TWO-FINGER (Swapping Compaction)
   --
   -- This algorithm uses two pointers working from opposite ends of the heap:
   -- - Free: Starts at the beginning, points to the next hole (unallocated slot)
   -- - Scan: Starts at the end, searches backward for live objects
   --
   -- When Scan finds a live object and Free finds a hole, the object is
   -- moved (swapped) into the hole. This compacts the heap in two passes:
   -- 1. First pass: Move live objects from end to holes at front
   -- 2. Second pass: Update all references to use new addresses
   --
   -- Time Complexity: O(n) where n is the number of heap objects
   -- Space Complexity: O(1) - in-place, no additional storage needed
   -- Order Preservation: No - does not maintain original allocation order
   -- Requirement: Works only with fixed-size objects (which our model uses)
   --------------------------------------------------------------------------
   procedure Compact_Two_Finger (Heap : in out Heap_Array) is
      -- Free pointer: starts at beginning, finds holes to fill
      Free : Address := Heap'First;
      -- Scan pointer: starts at end, finds live objects to move
      Scan : Address := Heap'Last;
      High_Water_Mark : Address := Heap'First;
   begin
      -- Find the top-most allocated block to prevent scanning empty upper bounds
      while Scan >= Free and then not Heap(Scan).Allocated loop
         Scan := Scan - 1;
      end loop;

      if Scan < Free then
         return; -- Heap is completely empty
      end if;

      -- Pass 1: Swap live objects from the end into holes at the beginning
      while Free < Scan loop
         -- Advance 'Free' to the next hole (unmarked/unallocated block)
         while Free < Scan and then (Heap(Free).Allocated and then Heap(Free).Marked) loop
            Free := Free + 1;
         end loop;

         -- Move 'Scan' down to the next live object
         while Free < Scan and then not (Heap(Scan).Allocated and then Heap(Scan).Marked) loop
            Scan := Scan - 1;
         end loop;

         if Free < Scan then
            -- Move the live object into the hole
            Heap(Free) := Heap(Scan);
            -- Leave a forwarding address in the old location (tombstone)
            Heap(Scan).Allocated := False; 
            Heap(Scan).Forwarding_Address := Free;
            
            Free := Free + 1;
            Scan := Scan - 1;
         end if;
      end loop;

      -- Determine where the compacted live objects end
      if Heap(Free).Allocated and then Heap(Free).Marked then
         High_Water_Mark := Free;
      else
         High_Water_Mark := Free - 1;
      end if;

      -- Pass 2: Update references in the compacted region
      for I in Heap'First .. High_Water_Mark loop
         if Heap(I).Allocated and then Heap(I).Marked then
            for J in Heap(I).Refs'Range loop
               declare
                  Ref : Address := Heap(I).Refs(J);
               begin
                  -- If a reference points to an object that was moved (past High_Water_Mark)
                  if Ref > High_Water_Mark then
                     Heap(I).Refs(J) := Heap(Ref).Forwarding_Address;
                  end if;
               end;
            end loop;
            -- Unmark object for next GC cycle
            Heap(I).Marked := False;
         end if;
      end loop;

      -- Clear the remainder of the heap
      for I in High_Water_Mark + 1 .. Heap'Last loop
         Heap(I).Allocated := False;
         Heap(I).Marked := False;
         Heap(I).Refs := (others => Null_Address);
      end loop;
   end Compact_Two_Finger;

end Mark_Compact;
