--  Eytzinger_Binary_Search — Ada 2023 educational package for Eytzinger
--  (BFS / heap-layout) binary search, also known as multiplicative binary
--  search. A sorted ascending sequence is rearranged into complete-binary-
--  tree level order (heap indexing); search walks left/right children via
--  2i+1 / 2i+2 instead of recomputing (lo+hi)/2.
--  Primary source:
--  https://en.wikipedia.org/wiki/Eytzinger_binary_search
--  (related / redirect: Multiplicative binary search)

pragma Ada_2022;

package Eytzinger_Binary_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Build / Find.
   Max_N : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Integer sequence. Indices are Natural; arrays may be 0- or 1-based.
   --  Build expects Sorted in nondecreasing (ascending) order.
   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when:
   --    * Sorted'Length /= Layout'Length (Build);
   --    * length > Max_N (Build / Find);
   --    * Sorted_Index arguments are out of range.

   ---------------------------------------------------------------------------
   -- Algorithm sketch
   ---------------------------------------------------------------------------
   --  Layout: complete binary tree in an array (heap / BFS order).
   --    Root at offset 0; left child 2i+1; right child 2i+2 (0-based offsets
   --    from 'First). In-order traversal of this implicit tree recovers the
   --    sorted sequence.
   --
   --  Build (inorder → heap fill):
   --    Walk the heap shape in inorder, writing successive Sorted elements:
   --      procedure Fill (I) is
   --         Fill (2I+1);  Layout(I) := next Sorted;  Fill (2I+2);
   --    Equivalently: recursively place the median of each sorted subrange
   --    into successive BFS slots when the tree is perfect (n = 2^k−1);
   --    for general n the inorder-fill form guarantees the complete shape.
   --
   --  Find:
   --    Start at offset 0. While in range, compare Key with Layout(i);
   --    go left (2i+1) if Key is smaller, right (2i+2) if larger.
   --    Hit → layout index; miss → sentinel Layout'First − 1.
   --
   --  Sorted_Index maps a layout index back to the corresponding index in
   --  the original sorted array (same 'First / length as Layout).
   --
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Build / search
   ---------------------------------------------------------------------------

   procedure Build (Sorted : Element_Array; Layout : out Element_Array);
   --  Convert Sorted (ascending) into Eytzinger / BFS heap layout in Layout.
   --  Requires Layout'Length = Sorted'Length.
   --  Empty arrays are a no-op. Singleton copies the sole element.
   --  Raises Invalid_Argument on length mismatch or length > Max_N.
   --  Precondition (unchecked): Sorted is nondecreasing.

   function Find (Layout : Element_Array; Key : Integer) return Integer;
   --  Eytzinger binary search for Key in a Build-produced Layout.
   --  Returns an index I in Layout'Range with Layout(I) = Key, or the
   --  sentinel Integer (Layout'First) − 1 when absent (or Layout empty).
   --  When duplicates exist, any matching layout index is acceptable.
   --  Raises Invalid_Argument when Layout'Length > Max_N.

   function Sorted_Index
     (Layout_Index : Natural;
      Length       : Natural;
      First        : Natural := 0) return Integer;
   --  Map a layout absolute index back to the corresponding sorted-array
   --  absolute index for a length-Length Eytzinger layout whose 'First is
   --  First. Returns First + inorder-rank of the node.
   --  Raises Invalid_Argument if Length > Max_N, Length = 0, or
   --  Layout_Index is not in First .. First + Length − 1.

   ---------------------------------------------------------------------------
   -- Helpers (tests / README)
   ---------------------------------------------------------------------------

   function Classic_Binary_Search
     (Sorted : Element_Array; Key : Integer) return Integer;
   --  Standard iterative binary search on sorted ascending Sorted.
   --  Same hit/miss contract as Find, but indices refer to Sorted.
   --  Raises Invalid_Argument when Sorted'Length > Max_N.

   function Is_Sorted_Ascending (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (vacuously true if A'Length < 2).

end Eytzinger_Binary_Search;
