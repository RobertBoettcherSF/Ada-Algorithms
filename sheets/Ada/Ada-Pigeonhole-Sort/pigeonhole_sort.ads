--  Pigeonhole_Sort — Ada 2023 educational package for pigeonhole sort
--  on Integer arrays with a small key range.
--  Time O(n + N) where n = length and N = (max - min + 1).
--  Stable when items are placed into per-hole queues (left-to-right).
--  Reference: https://en.wikipedia.org/wiki/Pigeonhole_sort

pragma Ada_2022;

package Pigeonhole_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   Max_Length : constant Positive := 100_000;

   --  Maximum inclusive key span (max - min + 1) accepted by Sort.
   --  Pigeonhole sort allocates one hole per key in [min, max]; huge
   --  spans would exhaust memory / time even for tiny n.
   Max_Range : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when:
   --    * A'Length > Max_Length; or
   --    * (max - min + 1) > Max_Range for the values present in A.

   ---------------------------------------------------------------------------
   -- Algorithm sketch
   ---------------------------------------------------------------------------
   --  1. Find Min and Max among A.
   --  2. Allocate N = Max - Min + 1 pigeonholes (one per key).
   --  3. Place each item into the hole for its key (stable queues /
   --     contiguous hole segments via counts + left-to-right scatter).
   --  4. Read holes back into A in increasing key order.
   --
   --  Contrast with counting sort: pigeonhole *moves items into holes*
   --  (lists / hole segments) and concatenates them; counting sort builds
   --  an auxiliary count array, then uses prefix sums to compute each
   --  item's final destination and moves it there once. When keys equal
   --  values (pure Integer sort), both reconstruct the same multiset;
   --  the structural difference remains the hole lists vs. count table.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending pigeonhole sort. Empty and singleton arrays are no-ops.
   --  Stable for equal keys (left-to-right placement into each hole).
   --  Raises Invalid_Argument when A'Length > Max_Length or the value
   --  range exceeds Max_Range.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Pigeonhole_Sort;
