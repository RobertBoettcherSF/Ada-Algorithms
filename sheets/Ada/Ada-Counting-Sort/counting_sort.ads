--  Counting_Sort — Ada 2023 educational package for classic counting sort
--  on Integer arrays with a bounded key range.
--  Time O(n + k) where n = length and k = (max - min + 1).
--  Stable: elements are placed into the output from right to left.
--  Reference: https://en.wikipedia.org/wiki/Counting_sort

pragma Ada_2022;

package Counting_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   Max_Length : constant Positive := 100_000;

   --  Maximum inclusive key span (max - min + 1) accepted by Sort.
   --  Counting sort allocates a count table of that size; huge spans
   --  would exhaust memory / time even for tiny n.
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
   -- Algorithm sketch (classic / Wikipedia stable form)
   ---------------------------------------------------------------------------
   --  1. Find Min and Max among A (or use 0..k when keys are nonnegative).
   --  2. Count occurrences of each key in [Min, Max] into Count[0 .. k-1].
   --  3. Prefix-sum Count so Count(j) is the exclusive end index of key j
   --     (number of elements with key <= j, as a 0-based offset).
   --  4. Scan A from right to left: for each item, decrement Count(key) and
   --     write the item into Output at that position — preserves relative
   --     order of equal keys (stability).
   --  5. Copy Output back into A.
   --
   --  Contrast with pigeonhole sort: pigeonhole moves items into per-key
   --  hole lists/segments then concatenates; counting sort keeps only a
   --  numeric count table, derives destinations via prefix sums, and moves
   --  each item once into its final slot. Same O(n+k) class; different
   --  auxiliary structure. Do not `with` the pigeonhole package.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending classic counting sort. Empty and singleton arrays are no-ops.
   --  Stable for equal keys (right-to-left placement into the output).
   --  Raises Invalid_Argument when A'Length > Max_Length or the value
   --  range exceeds Max_Range.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Counting_Sort;
