--  Quicksort — Ada 2023 educational package for classic in-place quicksort
--  (Tony Hoare, 1959/1961). Median-of-three pivot + Hoare partition.
--  Average O(n log n); worst O(n²). Unstable, ascending.
--  Reference: https://en.wikipedia.org/wiki/Quicksort

pragma Ada_2022;

package Quicksort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   Max_N : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic quicksort / Wikipedia)
   ---------------------------------------------------------------------------
   --  procedure sort(A):
   --      if length(A) ≤ 1: return
   --      p ← partition(A)   -- median-of-three + Hoare
   --      sort(left of p)
   --      sort(right of p)
   --
   --  Pivot: median of first, middle, and last (median-of-three), placed
   --  at Lo so sorted / reverse inputs avoid pathological O(n²) splits.
   --  Partition: Hoare scheme — returns index P such that every element in
   --  A(Lo .. P) ≤ every element in A(P+1 .. Hi). Recurse on both sides.
   --  Unstable; in-place aside from O(log n) average recursion stack.
   --  Do not `with` sibling Ada-* sort packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending in-place quicksort (unstable).
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Quicksort;
