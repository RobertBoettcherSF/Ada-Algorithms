--  semi_space_collector.ads
--  Specification for the Semi-Space Garbage Collector (Copying Collector)
--  Implements both Cheney's Iterative and standard Recursive variants.
--
--  This package provides a strongly-typed implementation of a two-space copying
--  garbage collector. It uses safe array indices instead of raw pointers, ensuring
--  memory safety by design.

package Semi_Space_Collector is

   --  Object_Id
   --  Strongly-typed object reference to prevent accidental integer arithmetic.
   --  This is the primary handle used to reference nodes in the heap.
   --  Range includes -1 for Null_Id and up to 1_000_000 for object references.
   type Object_Id is new Integer range -1 .. 1_000_000;
   
   --  Null_Id
   --  Sentinel value representing a null or invalid object reference.
   --  Used as the default value for uninitialized pointers.
   Null_Id : constant Object_Id := -1;

   --  Space_Selector
   --  Enumeration indicating which semi-space is currently active.
   --  The garbage collector works by swapping between two spaces:
   --    - Space_A: The initial active space
   --    - Space_B: The alternate space
   type Space_Selector is (Space_A, Space_B);

   --  Node_Kind
   --  Discriminant for the Node variant record.
   --  During garbage collection, nodes transition from Active to Forwarded state.
   --    - Active: Node contains user data (value and child pointers)
   --    - Forwarded: Node has been copied to To-Space, contains forwarding pointer
   type Node_Kind is (Active, Forwarded);
   
   --  Node
   --  Variant record representing a single memory cell in the heap.
   --  
   --  When Active: Contains user data (Value, Left, Right pointers)
   --  When Forwarded: Contains a forwarding pointer (New_Id) to the copied location
   --  
   --  The variant record allows the same memory location to serve different
   --  purposes during different phases of garbage collection.
   type Node (Kind : Node_Kind := Active) is record
      case Kind is
         when Active =>
            --  User data fields
            Value : Integer;
            Left  : Object_Id;
            Right : Object_Id;
         when Forwarded =>
            --  Forwarding pointer to the new location in To-Space
            New_Id : Object_Id;
      end case;
   end record;

   --  Space_Size
   --  Maximum number of nodes that can be allocated in each semi-space.
   --  Total heap capacity is 2 * Space_Size (one for each semi-space).
   Space_Size : constant Integer := 1024;
   
   --  Node_Array
   --  Array type for a single semi-space, holding Space_Size nodes.
   type Node_Array is array (0 .. Space_Size - 1) of Node;
   
   --  Root_Set
   --  Array type for holding root references passed to the garbage collector.
   --  Roots are the starting points for garbage collection traversal.
   type Root_Set is array (Positive range <>) of Object_Id;

   --  Heap
   --  The main garbage-collected heap structure.
   --  
   --  Contains two semi-spaces (A and B), a selector for the current active space,
   --  and an allocation pointer tracking the next available slot in the active space.
   --  
   --  During garbage collection, the roles of A and B are swapped, and Alloc_Ptr
   --  is reset to 0 in the new active space.
   type Heap is record
      A         : Node_Array;
      B         : Node_Array;
      Current   : Space_Selector := Space_A;
      Alloc_Ptr : Integer := 0;
   end record;

   --  Out_Of_Memory
   --  Exception raised when attempting to allocate beyond Space_Size in the active space.
   --  This indicates the heap is full and garbage collection is needed.
   Out_Of_Memory : exception;

   --  ========================================================================
   --  Core API
   --  ========================================================================

   --  Initialize
   --  Resets the heap to its initial state.
   --  
   --  Parameters:
   --    H - The heap to initialize (out parameter)
   --  
   --  Postcondition: Current = Space_A, Alloc_Ptr = 0
   procedure Initialize (H : out Heap);
   
   --  Allocate
   --  Allocates a new node in the currently active From-Space.
   --  
   --  Parameters:
   --    H     - The heap to allocate from (in out, modified)
   --    Val   - Integer value to store in the new node
   --    Left  - Left child pointer (default: Null_Id)
   --    Right - Right child pointer (default: Null_Id)
   --  
   --  Returns:
   --    Object_Id - The ID of the newly allocated node
   --  
   --  Raises:
   --    Out_Of_Memory - If the active space is full (Alloc_Ptr >= Space_Size)
   function Allocate (H     : in out Heap; 
                      Val   : Integer; 
                      Left  : Object_Id := Null_Id; 
                      Right : Object_Id := Null_Id) return Object_Id;

   --  ========================================================================
   --  Garbage Collection Variants
   --  ========================================================================

   --  Collect_Cheney
   --  VARIANT 1: Cheney's Algorithm (Iterative, Breadth-First)
   --  
   --  Uses the To-Space itself as a BFS queue to traverse the object graph.
   --  The allocation pointer serves as both queue head (Scan_Ptr) and queue tail.
   --  
   --  Advantages:
   --    - No risk of stack overflow (iterative implementation)
   --    - Efficient memory usage (uses To-Space as implicit queue)
   --    - Handles arbitrarily deep object graphs
   --  
   --  Parameters:
   --    H     - The heap to collect (in out, modified)
   --    Roots - Array of root references (in out, updated to new locations)
   --  
   --  Postcondition: All live objects have been copied to the new active space,
   --                 Roots contain updated pointers to new locations,
   --                 old space contains only forwarding pointers and garbage
   procedure Collect_Cheney (H : in out Heap; Roots : in out Root_Set);

   --  Collect_Recursive
   --  VARIANT 2: Standard Copying (Recursive, Depth-First)
   --  
   --  The naive recursive approach. Uses the call stack to traverse the object graph.
   --  
   --  Note: While simpler, this can cause stack overflow on very deep graphs.
   --  However, it handles cyclic graphs correctly via forwarding pointers.
   --  
   --  Parameters:
   --    H     - The heap to collect (in out, modified)
   --    Roots - Array of root references (in out, updated to new locations)
   --  
   --  Postcondition: Same as Collect_Cheney
   procedure Collect_Recursive (H : in out Heap; Roots : in out Root_Set);

   --  ========================================================================
   --  Helper/Inspection Functions
   --  ========================================================================

   --  Get_Node
   --  Retrieves a node from the currently active space.
   --  
   --  Parameters:
   --    H  - The heap to query
   --    Id - The Object_Id to retrieve
   --  
   --  Returns:
   --    Node - The node at the given ID in the active space
   function Get_Node (H : Heap; Id : Object_Id) return Node;

   --  Active_Space_Usage
   --  Returns the number of nodes currently allocated in the active space.
   --  
   --  Parameters:
   --    H - The heap to query
   --  
   --  Returns:
   --    Integer - Number of allocated nodes (0 to Space_Size)
   function Active_Space_Usage (H : Heap) return Integer;

   --  Get_Current_Space
   --  Returns which space is currently active (From-Space).
   --  
   --  Parameters:
   --    H - The heap to query
   --  
   --  Returns:
   --    Space_Selector - Space_A or Space_B
   function Get_Current_Space (H : Heap) return Space_Selector;

end Semi_Space_Collector;
