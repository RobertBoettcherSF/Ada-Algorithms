--  semi_space_collector.adb
--  Implementation of the Semi-Space Garbage Collector
--
--  This package implements a two-space copying garbage collector with two
--  algorithm variants: Cheney's iterative algorithm and standard recursive GC.
--  Both variants use forwarding pointers to handle cyclic references safely.

package body Semi_Space_Collector is

   -----------------------------------------------------------------------------
   --  Initialize
   --  Resets the heap to its initial state with Space_A as the active space
   --  and the allocation pointer at 0.
   -----------------------------------------------------------------------------
   procedure Initialize (H : out Heap) is
   begin
      H.Current := Space_A;
      H.Alloc_Ptr := 0;
   end Initialize;

   -----------------------------------------------------------------------------
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
   -----------------------------------------------------------------------------
   function Allocate (H     : in out Heap; 
                      Val   : Integer; 
                      Left  : Object_Id := Null_Id; 
                      Right : Object_Id := Null_Id) return Object_Id is
      New_Id : Object_Id;
   begin
      if H.Alloc_Ptr >= Space_Size then
         raise Out_Of_Memory;
      end if;

      New_Id := Object_Id (H.Alloc_Ptr);
      
      --  Allocate in the currently active From-Space
      if H.Current = Space_A then
         H.A (Integer (New_Id)) := (Kind => Active, Value => Val, Left => Left, Right => Right);
      else
         H.B (Integer (New_Id)) := (Kind => Active, Value => Val, Left => Left, Right => Right);
      end if;
      
      H.Alloc_Ptr := H.Alloc_Ptr + 1;
      return New_Id;
   end Allocate;

   -----------------------------------------------------------------------------
   --  VARIANT 1: Cheney's Algorithm (Iterative)
   --  
   --  Cheney's algorithm is an iterative, breadth-first copying garbage collector.
   --  It uses the To-Space itself as a queue, with the allocation pointer serving
   --  as both the queue head (Scan_Ptr) and queue tail (Alloc_Ptr).
   --  
   --  Key insight: The region between Scan_Ptr and Alloc_Ptr in To-Space contains
   --  nodes that have been copied but whose children have not yet been processed.
   --  This eliminates the need for an explicit queue data structure.
   --  
   --  Advantages:
   --    - No risk of stack overflow (iterative)
   --    - Efficient memory usage (uses To-Space as queue)
   --    - Handles arbitrarily deep object graphs
   --  
   --  Parameters:
   --    H     - The heap to collect (in out, modified)
   --    Roots - Array of root references (in out, updated to new locations)
   -----------------------------------------------------------------------------
   procedure Collect_Cheney (H : in out Heap; Roots : in out Root_Set) is
      Old_Current : constant Space_Selector := H.Current;
      Scan_Ptr    : Integer := 0;

      --  Copy
      --  Copies a single node from From-Space to To-Space and leaves a forwarding
      --  pointer in the original location. If the node has already been copied
      --  (forwarding pointer exists), returns the new ID directly.
      --  
      --  Parameters:
      --    Id - The Object_Id to copy
      --  
      --  Returns:
      --    Object_Id - The ID of the node in To-Space (new or existing)
      function Copy (Id : Object_Id) return Object_Id is
         Old_Node : Node;
         New_Id   : Object_Id;
      begin
         if Id = Null_Id then
            return Null_Id;
         end if;

         --  Fetch node from From-Space
         Old_Node := (if Old_Current = Space_A then H.A (Integer (Id)) else H.B (Integer (Id)));

         --  If already copied, return the forwarding address
         if Old_Node.Kind = Forwarded then
            return Old_Node.New_Id;
         end if;

         if H.Alloc_Ptr >= Space_Size then
            raise Out_Of_Memory;
         end if;

         New_Id := Object_Id (H.Alloc_Ptr);
         
         --  Copy to To-Space
         if H.Current = Space_A then
            H.A (Integer (New_Id)) := Old_Node;
         else
            H.B (Integer (New_Id)) := Old_Node;
         end if;
         H.Alloc_Ptr := H.Alloc_Ptr + 1;

         --  Leave forwarding pointer in From-Space
         --  This is crucial for:
         --    1. Detecting already-copied nodes (prevents duplication)
         --    2. Handling cyclic references (prevents infinite loops)
         if Old_Current = Space_A then
            H.A (Integer (Id)) := (Kind => Forwarded, New_Id => New_Id);
         else
            H.B (Integer (Id)) := (Kind => Forwarded, New_Id => New_Id);
         end if;

         return New_Id;
      end Copy;

   begin
      --  Step 1: Swap spaces
      --  The old From-Space becomes To-Space, and vice versa
      H.Current := (if H.Current = Space_A then Space_B else Space_A);
      H.Alloc_Ptr := 0;

      --  Step 2: Copy all roots (This enqueues them in To-Space)
      --  Each root is copied to To-Space, leaving a forwarding pointer in From-Space
      for I in Roots'Range loop
         Roots (I) := Copy (Roots (I));
      end loop;

      --  Step 3: Scan To-Space (Cheney's BFS traversal queue)
      --  The region [Scan_Ptr .. Alloc_Ptr-1] in To-Space is the implicit queue
      --  of nodes whose children need to be processed
      while Scan_Ptr < H.Alloc_Ptr loop
         declare
            N : Node := (if H.Current = Space_A then H.A (Scan_Ptr) else H.B (Scan_Ptr));
         begin
            --  Update children with new locations, copying them if necessary
            --  Copy() handles both the copy operation and forwarding pointer checks
            N.Left  := Copy (N.Left);
            N.Right := Copy (N.Right);
            
            --  Write updated node back to To-Space
            if H.Current = Space_A then
               H.A (Scan_Ptr) := N;
            else
               H.B (Scan_Ptr) := N;
            end if;
         end;
         Scan_Ptr := Scan_Ptr + 1;
      end loop;
      
      --  Collection complete!
      --  All live objects have been copied to To-Space (now the active space)
      --  From-Space (old active space) now contains only forwarding pointers and garbage
   end Collect_Cheney;

   -----------------------------------------------------------------------------
   --  VARIANT 2: Standard Recursive Collection
   --  
   --  A depth-first, recursive copying garbage collector.
   --  
   --  This is the "naive" approach that uses the call stack to traverse the
   --  object graph. While simpler to understand, it can cause stack overflow
   --  on very deep object graphs.
   --  
   --  The key to handling cycles is placing the forwarding pointer BEFORE
   --  recursively copying children. This ensures that if we encounter the
   --  same node again through a different path, we detect the forwarding
   --  pointer and return the new ID immediately.
   --  
   --  Parameters:
   --    H     - The heap to collect (in out, modified)
   --    Roots - Array of root references (in out, updated to new locations)
   -----------------------------------------------------------------------------
   procedure Collect_Recursive (H : in out Heap; Roots : in out Root_Set) is
      Old_Current : constant Space_Selector := H.Current;

      --  Copy_Rec
      --  Recursively copies a node and its entire reachable subtree.
      --  
      --  The forwarding pointer is placed BEFORE the recursive calls to handle
      --  cyclic graphs. Without this, infinite recursion would occur on cycles.
      --  
      --  Parameters:
      --    Id - The Object_Id to copy
      --  
      --  Returns:
      --    Object_Id - The ID of the node in To-Space
      function Copy_Rec (Id : Object_Id) return Object_Id is
         Old_Node : Node;
         New_Id   : Object_Id;
      begin
         if Id = Null_Id then
            return Null_Id;
         end if;

         Old_Node := (if Old_Current = Space_A then H.A (Integer (Id)) else H.B (Integer (Id)));

         if Old_Node.Kind = Forwarded then
            return Old_Node.New_Id;
         end if;

         if H.Alloc_Ptr >= Space_Size then
            raise Out_Of_Memory;
         end if;

         --  Allocate space in To-Space
         New_Id := Object_Id (H.Alloc_Ptr);
         H.Alloc_Ptr := H.Alloc_Ptr + 1;
         
         --  CRITICAL: Leave forwarding pointer immediately to handle cyclic graphs
         --  This must be done BEFORE the recursive calls below
         if Old_Current = Space_A then
            H.A (Integer (Id)) := (Kind => Forwarded, New_Id => New_Id);
         else
            H.B (Integer (Id)) := (Kind => Forwarded, New_Id => New_Id);
         end if;

         --  Recursively copy children (Depth-First)
         --  The forwarding pointer above prevents infinite recursion on cycles
         Old_Node.Left  := Copy_Rec (Old_Node.Left);
         Old_Node.Right := Copy_Rec (Old_Node.Right);

         --  Write completed node to To-Space
         if H.Current = Space_A then
            H.A (Integer (New_Id)) := Old_Node;
         else
            H.B (Integer (New_Id)) := Old_Node;
         end if;

         return New_Id;
      end Copy_Rec;
   begin
      --  Swap spaces
      H.Current := (if H.Current = Space_A then Space_B else Space_A);
      H.Alloc_Ptr := 0;

      --  Traverse roots recursively
      for I in Roots'Range loop
         Roots (I) := Copy_Rec (Roots (I));
      end loop;
   end Collect_Recursive;

   -----------------------------------------------------------------------------
   --  Helpers
   -----------------------------------------------------------------------------

   --  Get_Node
   --  Retrieves a node from the currently active space.
   --  
   --  Parameters:
   --    H  - The heap to query
   --    Id - The Object_Id to retrieve
   --  
   --  Returns:
   --    Node - The node at the given ID in the active space
   function Get_Node (H : Heap; Id : Object_Id) return Node is
   begin
      if H.Current = Space_A then
         return H.A (Integer (Id));
      else
         return H.B (Integer (Id));
      end if;
   end Get_Node;

   --  Active_Space_Usage
   --  Returns the number of nodes currently allocated in the active space.
   --  This is simply the value of the allocation pointer.
   --  
   --  Parameters:
   --    H - The heap to query
   --  
   --  Returns:
   --    Integer - Number of allocated nodes (0 to Space_Size)
   function Active_Space_Usage (H : Heap) return Integer is
   begin
      return H.Alloc_Ptr;
   end Active_Space_Usage;

   --  Get_Current_Space
   --  Returns which space is currently active (From-Space).
   --  
   --  Parameters:
   --    H - The heap to query
   --  
   --  Returns:
   --    Space_Selector - Space_A or Space_B
   function Get_Current_Space (H : Heap) return Space_Selector is
   begin
      return H.Current;
   end Get_Current_Space;

end Semi_Space_Collector;
