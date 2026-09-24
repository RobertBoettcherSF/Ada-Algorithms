-- mark_compact.ads
-- Specification for the Mark-Compact Garbage Collection algorithm.
-- Includes both Sliding (LISP 2) and Swapping (Two-Finger) compaction variants.
--
-- This package provides a complete implementation of mark-compact garbage collection
-- with strong typing to prevent memory corruption. The Address type uses a constrained
-- integer range to ensure all memory accesses are bounds-checked at runtime.

package Mark_Compact is

   -- Memory Management Types
   -- Max_Heap_Size defines the maximum number of objects the heap can hold
   -- Address type includes an extra slot (Max_Heap_Size + 1) to accommodate
   -- the Free_Ptr variable in compaction algorithms, which needs to point
   -- one past the last valid heap address
   Max_Heap_Size : constant Positive := 1000;
   type Address is range 0 .. Max_Heap_Size + 1;
   Null_Address : constant Address := 0;

   -- Up to 4 references per object for the object graph
   type Reference_Array is array (1 .. 4) of Address;

   -- Represents an object in the heap memory
   type Object_Record is record
      Allocated          : Boolean := False;
      Marked             : Boolean := False;
      Forwarding_Address : Address := Null_Address;
      Refs               : Reference_Array := (others => Null_Address);
      Data_Value         : Integer := 0; 
   end record;

   -- The heap memory representation
   type Heap_Array is array (Address range 1 .. Address'Last) of Object_Record;

   -- Root array (e.g., variables on the stack pointing to the heap)
   type Root_Array is array (Positive range <>) of Address;

   -- Exceptions for edge cases
   Heap_Overflow : exception;
   Invalid_Address : exception;

   --------------------------------------------------------------------------
   -- HELPER SUBPROGRAMS
   --------------------------------------------------------------------------
   -- Initializes an empty heap
   procedure Init_Heap (Heap : out Heap_Array);
   
   -- Allocates a new object and returns its address
   function Allocate (Heap : in out Heap_Array; Val : Integer) return Address;

   --------------------------------------------------------------------------
   -- MARK PHASE (Common to all variants)
   --------------------------------------------------------------------------
   -- Traverses the object graph starting from roots, marking reachable objects
   procedure Mark (Heap : in out Heap_Array; Roots : Root_Array);

   --------------------------------------------------------------------------
   -- COMPACTION VARIANTS
   --------------------------------------------------------------------------
   -- Variant 1: LISP 2 Algorithm (Sliding Compaction)
   -- Moves objects to the beginning of the heap while preserving their relative order.
   -- Requires 3 passes over the heap. Best for general use.
   procedure Compact_LISP2 (Heap : in out Heap_Array);

   -- Variant 2: Two-Finger Algorithm (Swapping Compaction)
   -- Takes live objects from the end of the heap and moves them into holes
   -- at the beginning. Does not preserve object order. Requires 2 passes.
   -- Works exclusively for fixed-size objects (which our heap model uses).
   procedure Compact_Two_Finger (Heap : in out Heap_Array);

end Mark_Compact;
