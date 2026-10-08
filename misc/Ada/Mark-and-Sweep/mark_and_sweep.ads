-- src/mark_and_sweep.ads
-- %
-- @package Mark_And_Sweep
-- @summary A tracing garbage collector simulation implementing Mark and Sweep algorithms
--
-- @description
-- This package provides a custom memory management simulation with three variants
-- of the Mark and Sweep garbage collection algorithm. It models a heap with
-- objects that can reference each other, allowing testing of GC behavior in Ada.
--
-- The simulation uses a fixed-size heap (Max_Objects) with objects that can hold
-- up to Max_Refs_Per_Object references to other objects, simulating a binary
-- tree or graph structure.
--
-- @note
-- This is a simulation for educational and testing purposes. In production Ada,
-- memory management is typically manual or uses controlled types with Finalize.
--
-- @see https://en.wikipedia.org/wiki/Mark_and_sweep
-- %

package Mark_And_Sweep is

   -- ==========================================
   -- TYPE DEFINITIONS
   -- ==========================================

   -- @constant Max_Objects
   -- @summary Maximum number of objects the heap can hold
   -- @description Limits the simulation to a manageable size for testing
   Max_Objects : constant := 1000;

   -- @type Object_Index
   -- @summary Index type for referencing objects in the heap
   -- @description A new Integer type constrained to valid heap indices (0 .. Max_Objects)
   type Object_Index is new Integer range 0 .. Max_Objects;

   -- @constant Null_Ptr
   -- @summary Sentinel value representing a null or invalid object reference
   -- @description Convention: index 0 is reserved as null and not used for allocation
   Null_Ptr : constant Object_Index := 0;

   -- @constant Max_Refs_Per_Object
   -- @summary Maximum number of references each object can hold
   -- @description Set to 2 to simulate binary tree structures or simple graphs
   Max_Refs_Per_Object : constant := 2;

   -- @type Reference_Array
   -- @summary Array type for storing object references
   -- @description Fixed-size array holding Max_Refs_Per_Object object indices
   type Reference_Array is array (1 .. Max_Refs_Per_Object) of Object_Index;

   -- @type Color_Type
   -- @summary Enumeration of colors used in the Tri-color algorithm
   -- @description
   -- @value White Objects not yet visited (condemned if still white after mark phase)
   -- @value Gray Objects discovered but not yet fully processed
   -- @value Black Objects fully processed and confirmed reachable
   type Color_Type is (White, Gray, Black);

   -- @exception Out_Of_Memory
   -- @summary Raised when heap allocation fails
   -- @description Thrown by Allocate when no free slots remain in the heap
   Out_Of_Memory : exception;

   -- @exception Invalid_Reference
   -- @summary Raised when an invalid reference operation is attempted
   -- @description Thrown by Add_Reference for null sources, unallocated objects,
   -- or slot indices exceeding Max_Refs_Per_Object
   Invalid_Reference : exception;

   -- ==========================================
   -- DATA STRUCTURES
   -- ==========================================

   -- @type GC_Object
   -- @summary Represents a single garbage-collected object
   -- @description
   -- Each object tracks its allocation status, mark state (for naive/iterative GC),
   -- color state (for tri-color GC), and references to other objects.
   --
   -- @field Is_Allocated Boolean indicating if this heap slot is in use
   -- @field Marked Boolean used by naive and iterative algorithms (True = reachable)
   -- @field Color Color_Type used by tri-color algorithm
   -- @field Refs Reference_Array holding pointers to child objects
   type GC_Object is record
      Is_Allocated : Boolean         := False;
      Marked       : Boolean         := False; -- Used for Naive and Iterative
      Color        : Color_Type      := White; -- Used for Tri-color
      Refs         : Reference_Array := (others => Null_Ptr);
   end record;

   -- @type Heap_Array
   -- @summary The complete heap storage
   -- @description Array of all possible objects, indexed from 1 to Max_Objects
   -- @note Index 0 is intentionally unused (reserved for Null_Ptr)
   type Heap_Array is array (Object_Index range 1 .. Max_Objects) of GC_Object;

   -- @type Root_Set
   -- @summary Dynamic array of root object references
   -- @description Represents the set of root pointers that the GC must preserve.
   -- Objects reachable from any root will survive the collection.
   type Root_Set is array (Positive range <>) of Object_Index;

   -- ==========================================
   -- CORE OPERATIONS
   -- ==========================================

   -- @procedure Allocate
   -- @summary Allocates a new object in the heap
   -- @param Heap The heap to allocate from (in out)
   -- @param Idx Output parameter receiving the index of the allocated object
   -- @description
   -- Finds the first unallocated slot in the heap and initializes it.
   -- The new object starts unmarked (White) with all references set to Null_Ptr.
   --
   -- @raises Out_Of_Memory If no free slots remain in the heap
   --
   -- @example
   -- @code
   -- declare
   --   My_Heap : Heap_Array;
   --   Obj_Idx : Object_Index;
   -- begin
   --   Allocate(My_Heap, Obj_Idx);
   --   -- Obj_Idx now holds the index of a new, allocated object
   -- end;
   -- @endcode
   procedure Allocate (Heap : in out Heap_Array; Idx : out Object_Index);

   -- @procedure Add_Reference
   -- @summary Adds a reference from one object to another
   -- @param Heap The heap containing both objects (in out)
   -- @param From The source object index (must be allocated and non-null)
   -- @param To The target object index (the object being referenced)
   -- @param Slot The reference slot to use (1 .. Max_Refs_Per_Object)
   -- @description
   -- Establishes a directed reference from the From object to the To object
   -- at the specified slot. This creates the graph structure that the GC traverses.
   --
   -- @raises Invalid_Reference If From is Null_Ptr, From is not allocated,
   -- or Slot exceeds Max_Refs_Per_Object
   --
   -- @example
   -- @code
   -- declare
   --   My_Heap : Heap_Array;
   --   Obj1, Obj2 : Object_Index;
   -- begin
   --   Allocate(My_Heap, Obj1);
   --   Allocate(My_Heap, Obj2);
   --   Add_Reference(My_Heap, Obj1, Obj2, 1); -- Obj1 now references Obj2
   -- end;
   -- @endcode
   procedure Add_Reference (Heap : in out Heap_Array; From, To : Object_Index; Slot : Positive);

   -- @function Count_Allocated
   -- @summary Counts the number of currently allocated objects
   -- @param Heap The heap to count
   -- @return Natural The count of allocated (Is_Allocated = True) objects
   -- @description
   -- Iterates through the entire heap and counts objects where Is_Allocated is True.
   -- Useful for verifying GC behavior in tests.
   function Count_Allocated (Heap : Heap_Array) return Natural;

   -- @procedure Reset_Heap
   -- @summary Resets the entire heap to its initial state
   -- @param Heap The heap to reset (in out)
   -- @description
   -- Sets all objects to unallocated, unmarked, White, with null references.
   -- Useful for preparing a clean state between tests.
   procedure Reset_Heap (Heap : in out Heap_Array);

   -- ==========================================
   -- ALGORITHM VARIANTS
   -- ==========================================

   -- @procedure Recursive_Mark_And_Sweep
   -- @summary Naive recursive implementation of Mark and Sweep
   -- @param Heap The heap to collect (in out)
   -- @param Roots The set of root object indices to preserve
   -- @description
   -- Implements the classic depth-first search approach to mark and sweep:
   --
   -- 1. **Mark Phase**: Recursively traverses from each root, marking all
   --    reachable objects by setting their Marked flag to True.
   --    Uses the call stack for traversal.
   --
   -- 2. **Sweep Phase**: Iterates through the heap, freeing all unmarked objects
   --    and resetting the Marked flag on survivors.
   --
   -- @note This variant is susceptible to stack overflow on deeply nested
   -- object graphs. Use Iterative_Mark_And_Sweep for production systems
   -- with unbounded depth.
   --
   -- @see Iterative_Mark_And_Sweep For a stack-safe alternative
   procedure Recursive_Mark_And_Sweep (Heap : in out Heap_Array; Roots : Root_Set);

   -- @procedure Iterative_Mark_And_Sweep
   -- @summary Stack-based iterative implementation of Mark and Sweep
   -- @param Heap The heap to collect (in out)
   -- @param Roots The set of root object indices to preserve
   -- @description
   -- Implements an iterative version using an explicit stack array:
   --
   -- 1. **Mark Phase**: Uses a manually managed stack to traverse the object
   --    graph. Pushes unmarked, allocated objects onto the stack, then pops
   --    and marks them, pushing their unmarked children.
   --
   -- 2. **Sweep Phase**: Same as recursive variant - frees unmarked objects.
   --
   -- @note This variant provides bounded stack usage, making it suitable for
   -- real-time and embedded systems where stack overflow must be prevented.
   -- The stack size is bounded by Max_Objects.
   --
   -- @see Recursive_Mark_And_Sweep For the simpler recursive version
   procedure Iterative_Mark_And_Sweep (Heap : in out Heap_Array; Roots : Root_Set);

   -- @procedure Tricolor_Mark_And_Sweep
   -- @summary Dijkstra's Tri-color Mark and Sweep algorithm
   -- @param Heap The heap to collect (in out)
   -- @param Roots The set of root object indices to preserve
   -- @description
   -- Implements the tri-color marking algorithm with White, Gray, and Black states:
   --
   -- 1. **Initialization**: All objects start White (condemned).
   --
   -- 2. **Mark Phase**: Roots are colored Gray and pushed onto a work stack.
   --    While the stack is not empty:
   --    - Pop a Gray object
   --    - Color its White children Gray (they are now discovered)
   --    - Color the object Black (fully processed)
   --
   -- 3. **Sweep Phase**: White objects are reclaimed. Black and Gray objects
   --    are reset to White for the next collection cycle.
   --
   -- @note The tri-color approach is foundational for concurrent garbage
   -- collection algorithms, where the collector runs concurrently with
   -- mutator threads. The color states help maintain invariants during
   -- concurrent modification.
   --
   -- @see https://en.wikipedia.org/wiki/Tracing_garbage_collection#Tri-color_marking
   procedure Tricolor_Mark_And_Sweep (Heap : in out Heap_Array; Roots : Root_Set);

end Mark_And_Sweep;
