-- src/buddy_allocators.ads
-- Version 0.03
-- Description: Package specification for the Buddy Memory Allocation algorithm.
-- Time Complexity: O(log N) for both Allocation and Deallocation.
-- Space Complexity: O(N) internal metadata overhead backed by a static array.

package Buddy_Allocators is

   -- Specifies the mathematical ruleset used for dividing and merging blocks.
   type Variant_Type is (Binary, Fibonacci, Weighted);
   
   -- Abstract memory address. Uses -1 as a distinct null value.
   type Address is new Integer range -1 .. Integer'Last;
   Null_Address : constant Address := -1;

   -- Domain-specific exceptions for strict error handling.
   Allocation_Error     : exception;
   Deallocation_Error   : exception;
   Initialization_Error : exception;

   -- Internal Node identifier for the binary tree structure.
   type Node_Id is new Natural;
   Null_Node : constant Node_Id := 0;

   -- Metadata record for a single memory partition.
   -- We store tree traversal links (Left, Right, Parent) to allow 
   -- O(log N) merging when blocks are deallocated.
   type Block_Node is record
      Is_Active   : Boolean := False;       -- True if this metadata slot is currently used
      Addr        : Address := 0;           -- Starting memory address of this block
      Size        : Positive := 1;          -- Capacity of this block
      Is_Free     : Boolean := False;       -- True if available for user allocation
      Is_Leaf     : Boolean := False;       -- True if block is NOT split into smaller buddies
      Left_Child  : Node_Id := Null_Node;   -- ID of the left buddy
      Right_Child : Node_Id := Null_Node;   -- ID of the right buddy
      Parent      : Node_Id := Null_Node;   -- ID of the parent block (used for merging)
   end record;

   -- Statically sized array to hold tree nodes. 
   -- This prevents dynamic memory allocation overhead and fragmentation within the allocator itself.
   Max_Nodes : constant := 8192;
   type Node_Array is array (Node_Id range 1 .. Max_Nodes) of Block_Node;

   -- The main state record containing the memory pool and its metadata.
   type Pool (Variant : Variant_Type) is record
      Nodes : Node_Array;
      Count : Node_Id := 0; 
   end record;

   -- =========================================================================
   -- Public API
   -- =========================================================================

   -- Initializes the pool. Total_Size must be valid for the chosen variant 
   -- (e.g., a power of 2 for Binary, a Fibonacci number for Fibonacci).
   procedure Initialize (P : in out Pool; Total_Size : Positive);

   -- Finds the smallest valid block for the requested Size.
   -- Splits larger blocks recursively if necessary.
   -- Returns Null_Address if no block is large enough.
   function Allocate (P : in out Pool; Size : Positive) return Address;

   -- Frees the block at the given address and recursively merges it with 
   -- its buddy if the buddy is also free. Raises Deallocation_Error on invalid address.
   procedure Deallocate (P : in out Pool; Addr : Address);

   -- =========================================================================
   -- Public Helpers (exposed for testing/validation)
   -- =========================================================================
   function Is_Power_Of_2 (N : Positive) return Boolean;
   function Is_Valid_Initial_Size (Variant : Variant_Type; Size : Positive) return Boolean;

end Buddy_Allocators;
