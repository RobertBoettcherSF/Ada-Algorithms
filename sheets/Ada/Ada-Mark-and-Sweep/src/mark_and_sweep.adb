-- src/mark_and_sweep.adb
-- %
-- @file mark_and_sweep.adb
-- @summary Package body for Mark_And_Sweep garbage collection simulation
-- %

package body Mark_And_Sweep is

   -- ==========================================
   -- CORE OPERATIONS
   -- ==========================================

   -- @procedure Allocate
   -- @implementation
   -- Linear search through the heap for the first available slot.
   -- Initializes the object with default values: unmarked, White color,
   -- and all references set to Null_Ptr.
   --
   -- @timecomplexity O(n) where n is Max_Objects
   -- @spacecomplexity O(1)
   procedure Allocate (Heap : in out Heap_Array; Idx : out Object_Index) is
   begin
      for I in Heap'Range loop
         if not Heap(I).Is_Allocated then
            Heap(I).Is_Allocated := True;
            Heap(I).Marked       := False;
            Heap(I).Color        := White;
            Heap(I).Refs         := (others => Null_Ptr);
            Idx := I;
            return;
         end if;
      end loop;
      raise Out_Of_Memory;
   end Allocate;

   -- @procedure Add_Reference
   -- @implementation
   -- Validates the From object exists and is allocated, validates the Slot
   -- is within bounds, then sets the reference.
   --
   -- @timecomplexity O(1)
   -- @spacecomplexity O(1)
   --
   -- @note Does not validate that To is allocated - this allows creating
   -- references to objects that may be allocated later (weak references).
   procedure Add_Reference (Heap : in out Heap_Array; From, To : Object_Index; Slot : Positive) is
   begin
      if From = Null_Ptr or else not Heap(From).Is_Allocated then
         raise Invalid_Reference;
      end if;
      if Slot > Max_Refs_Per_Object then
         raise Invalid_Reference;
      end if;
      Heap(From).Refs(Slot) := To;
   end Add_Reference;

   -- @function Count_Allocated
   -- @implementation
   -- Simple linear scan counting allocated objects.
   --
   -- @timecomplexity O(n) where n is Max_Objects
   -- @spacecomplexity O(1)
   function Count_Allocated (Heap : Heap_Array) return Natural is
      Count : Natural := 0;
   begin
      for I in Heap'Range loop
         if Heap(I).Is_Allocated then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Allocated;

   -- @procedure Reset_Heap
   -- @implementation
   -- Resets each object in the heap to its initial state.
   --
   -- @timecomplexity O(n) where n is Max_Objects
   -- @spacecomplexity O(1)
   procedure Reset_Heap (Heap : in out Heap_Array) is
   begin
      for I in Heap'Range loop
         Heap(I).Is_Allocated := False;
         Heap(I).Marked       := False;
         Heap(I).Color        := White;
         Heap(I).Refs         := (others => Null_Ptr);
      end loop;
   end Reset_Heap;

   -- @procedure Standard_Sweep
   -- @summary Common sweep phase implementation for naive and iterative variants
   -- @param Heap The heap to sweep (in out)
   -- @description
   -- Iterates through all objects in the heap:
   -- - If allocated and marked: unmark it (object survives)
   -- - If allocated and unmarked: free it (object is reclaimed)
   -- - Unallocated objects are ignored
   --
   -- @timecomplexity O(n) where n is Max_Objects
   -- @spacecomplexity O(1)
   --
   -- @note This is used by both Recursive_Mark_And_Sweep and Iterative_Mark_And_Sweep
   -- as they share the same sweep logic. Only the mark phase differs.
   procedure Standard_Sweep (Heap : in out Heap_Array) is
   begin
      for I in Heap'Range loop
         if Heap(I).Is_Allocated then
            if Heap(I).Marked then
               Heap(I).Marked := False; -- Keep and unmark
            else
               Heap(I).Is_Allocated := False; -- Reclaim
            end if;
         end if;
      end loop;
   end Standard_Sweep;


   -- ==========================================
   -- VARIANT 1: RECURSIVE MARK AND SWEEP
   -- ==========================================

   -- @procedure Recursive_Mark_And_Sweep
   -- @implementation
   -- Uses a nested recursive Mark procedure to traverse the object graph.
   --
   -- The Mark procedure:
   -- - Returns immediately for Null_Ptr, unallocated, or already-marked objects
   -- - Marks the current object
   -- - Recursively marks all children (references from this object)
   --
   -- After marking from all roots, calls Standard_Sweep to reclaim unmarked objects.
   --
   -- @timecomplexity O(n + e) where n is objects, e is references (DFS traversal)
   -- @spacecomplexity O(d) where d is maximum depth of object graph (call stack)
   --
   -- @warning On deeply nested graphs, this may cause stack overflow.
   -- Consider using Iterative_Mark_And_Sweep for production use.
   procedure Recursive_Mark_And_Sweep (Heap : in out Heap_Array; Roots : Root_Set) is

      -- @procedure Mark
      -- @summary Recursively marks an object and all reachable objects
      -- @param Idx The object index to mark
      -- @description
      -- Base cases: return for null, unallocated, or already-marked objects.
      -- Otherwise, mark the object and recursively mark all its children.
      --
      -- @note The check for already-marked objects prevents infinite recursion
      -- on cyclic references (A -> B -> A).
      procedure Mark (Idx : Object_Index) is
      begin
         if Idx = Null_Ptr then return; end if;
         if not Heap(Idx).Is_Allocated then return; end if;
         if Heap(Idx).Marked then return; end if; -- Prevent infinite loops on cycles

         Heap(Idx).Marked := True;
         for I in 1 .. Max_Refs_Per_Object loop
            Mark(Heap(Idx).Refs(I));
         end loop;
      end Mark;

   begin
      -- Phase 1: Mark - Start from each root and mark all reachable objects
      for R of Roots loop
         Mark(R);
      end loop;

      -- Phase 2: Sweep - Reclaim all unmarked objects
      Standard_Sweep(Heap);
   end Recursive_Mark_And_Sweep;


   -- ==========================================
   -- VARIANT 2: ITERATIVE MARK AND SWEEP
   -- ==========================================

   -- @procedure Iterative_Mark_And_Sweep
   -- @implementation
   -- Uses an explicit stack to simulate recursion, avoiding call stack limits.
   --
   -- The algorithm:
   -- 1. Push all roots onto the stack
   -- 2. While stack is not empty:
   --    a. Pop an object from the stack
   --    b. If not already marked, mark it
   --    c. Push all unmarked children onto the stack
   -- 3. Call Standard_Sweep to reclaim unmarked objects
   --
   -- @timecomplexity O(n + e) where n is objects, e is references
   -- @spacecomplexity O(n) in worst case (all objects on stack simultaneously)
   --
   -- @note The stack is bounded by Max_Objects, providing predictable memory usage.
   -- This makes it suitable for real-time systems where stack overflow
   -- must be prevented.
   procedure Iterative_Mark_And_Sweep (Heap : in out Heap_Array; Roots : Root_Set) is

      -- @type Stack_Array
      -- @summary Fixed-size stack for iterative traversal
      -- @description Array-based stack with maximum size of Max_Objects
      type Stack_Array is array (1 .. Max_Objects) of Object_Index;

      Stack : Stack_Array;
      Top   : Natural := 0;
      Curr  : Object_Index;

      -- @procedure Push
      -- @summary Pushes an object onto the stack if it should be processed
      -- @param Idx The object index to potentially push
      -- @description
      -- Only pushes if the object is not null, is allocated, and is not yet marked.
      -- This prevents redundant processing and null reference errors.
      procedure Push (Idx : Object_Index) is
      begin
         if Idx /= Null_Ptr and then Heap(Idx).Is_Allocated and then not Heap(Idx).Marked then
            Top := Top + 1;
            Stack(Top) := Idx;
         end if;
      end Push;

   begin
      -- Phase 1: Mark - Push all roots and process iteratively
      for R of Roots loop
         Push(R);
      end loop;

      while Top > 0 loop
         Curr := Stack(Top);
         Top := Top - 1;

         if not Heap(Curr).Marked then
            Heap(Curr).Marked := True;
            for I in 1 .. Max_Refs_Per_Object loop
               Push(Heap(Curr).Refs(I));
            end loop;
         end if;
      end loop;

      -- Phase 2: Sweep - Reclaim all unmarked objects
      Standard_Sweep(Heap);
   end Iterative_Mark_And_Sweep;


   -- ==========================================
   -- VARIANT 3: TRI-COLOR MARK AND SWEEP
   -- ==========================================

   -- @procedure Tricolor_Mark_And_Sweep
   -- @implementation
   -- Implements Dijkstra's tri-color marking algorithm.
   --
   -- The algorithm maintains the following invariant:
   -- - No Black object points to a White object
   --
   -- This invariant allows concurrent collection because the mutator
   -- (application code) can only create new references from Black to White
   -- (which is safe) or modify references within Black objects.
   --
   -- Phases:
   -- 1. Initialize all objects to White
   -- 2. Color roots Gray and push onto work stack
   -- 3. While stack not empty:
   --    a. Pop a Gray object
   --    b. For each child:
   --       - If White: color Gray and push onto stack
   --    c. Color the object Black
   -- 4. Sweep: reclaim White objects, reset Black/Gray to White
   --
   -- @timecomplexity O(n + e) where n is objects, e is references
   -- @spacecomplexity O(n) for the gray stack
   --
   -- @note In a concurrent GC, the mutator would need to maintain the
   -- tri-color invariant during its execution. This simulation does not
   -- model concurrent mutation.
   --
   -- @see https://en.wikipedia.org/wiki/Tracing_garbage_collection#Tri-color_marking
   procedure Tricolor_Mark_And_Sweep (Heap : in out Heap_Array; Roots : Root_Set) is

      -- @type Gray_Stack
      -- @summary Stack for tracking Gray (discovered but unprocessed) objects
      -- @description Fixed-size array for the Gray set during marking
      type Gray_Stack is array (1 .. Max_Objects) of Object_Index;

      Grays : Gray_Stack;
      Top   : Natural := 0;
      Curr  : Object_Index;
      Child : Object_Index;

   begin
      -- Initialize all objects to White
      -- This ensures a clean state for the tri-color algorithm
      for I in Heap'Range loop
         Heap(I).Color := White;
      end loop;

      -- Mark Roots as Gray and add to work stack
      -- Roots are the starting points for traversal
      for R of Roots loop
         if R /= Null_Ptr and then Heap(R).Is_Allocated then
            Heap(R).Color := Gray;
            Top := Top + 1;
            Grays(Top) := R;
         end if;
      end loop;

      -- Process Gray objects
      -- For each Gray object, examine its children:
      -- - White children become Gray (discovered)
      -- - Gray children are already in the work set
      -- - Black children are already processed
      -- Then the current object becomes Black (fully processed)
      while Top > 0 loop
         Curr := Grays(Top);
         Top := Top - 1;

         -- Move children to Gray if they are White
         for I in 1 .. Max_Refs_Per_Object loop
            Child := Heap(Curr).Refs(I);
            if Child /= Null_Ptr and then Heap(Child).Is_Allocated then
               if Heap(Child).Color = White then
                  Heap(Child).Color := Gray;
                  Top := Top + 1;
                  Grays(Top) := Child;
               end if;
            end if;
         end loop;

         -- Blacken the current object (fully processed)
         Heap(Curr).Color := Black;
      end loop;

      -- Sweep Phase for Tri-color
      -- - White objects were never reached: reclaim them
      -- - Black and Gray objects are reachable: reset to White for next cycle
      for I in Heap'Range loop
         if Heap(I).Is_Allocated then
            if Heap(I).Color = White then
               Heap(I).Is_Allocated := False; -- Reclaim
            else
               Heap(I).Color := White; -- Reset for next GC cycle
            end if;
         end if;
      end loop;
   end Tricolor_Mark_And_Sweep;

end Mark_And_Sweep;
