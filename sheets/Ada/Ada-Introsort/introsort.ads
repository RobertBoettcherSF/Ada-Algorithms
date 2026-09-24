--  Introsort — Ada 2023 educational package for Musser introspective sort:
--  hybrid of quicksort + heapsort + insertion sort.
--  Average performance like quicksort; worst-case O(n log n) via heapsort
--  depth cutoff; small partitions finished with insertion sort.
--  In-place, unstable, ascending. Helpers are inlined (no sibling withs).
--  Reference: https://en.wikipedia.org/wiki/Introsort

pragma Ada_2022;

package Introsort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   Max_N : constant Positive := 100_000;

   --  Partitions of this size or smaller are finished with insertion sort
   --  (classic Musser / SGI / libstdc++ threshold).
   Insertion_Threshold : constant Positive := 16;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Musser introsort / Wikipedia)
   ---------------------------------------------------------------------------
   --  procedure sort(A):
   --      maxdepth ← 2 × ⌊log₂(length(A))⌋
   --      introsort(A, maxdepth)
   --
   --  procedure introsort(A, maxdepth):
   --      n ← length(A)
   --      if n ≤ Insertion_Threshold:
   --          insertionsort(A)
   --      else if maxdepth = 0:
   --          heapsort(A)          -- guarantees O(n log n) worst case
   --      else:
   --          p ← partition(A)     -- median-of-three pivot
   --          introsort(left of p,  maxdepth − 1)
   --          introsort(right of p, maxdepth − 1)
   --
   --  Depth factor 2 is the classic Musser / GNU libstdc++ choice.
   --  Pivot: median of first, middle, and last (median-of-three).
   --  Partition: Hoare scheme around that pivot.
   --  Heapsort / insertion helpers are private and inlined — do not
   --  `with` Heapsort or Insertion_Sort packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending in-place introsort (unstable).
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Introsort;
