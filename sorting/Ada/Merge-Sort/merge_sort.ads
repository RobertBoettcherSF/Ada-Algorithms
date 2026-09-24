--  Merge_Sort — Ada 2023 educational package for classic top-down stable
--  merge sort (von Neumann, 1945) on Integer arrays with a bounded length.
--  Time Θ(n log n); auxiliary space Θ(n); stable for equal keys.
--  Reference: https://en.wikipedia.org/wiki/Merge_sort

pragma Ada_2022;

package Merge_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   --  Unlike Slowsort, merge sort is Θ(n log n), so a large educational
   --  bound is fine. Temp buffer of size n is allocated once per Sort.
   Max_N : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic top-down / Wikipedia)
   ---------------------------------------------------------------------------
   --  To sort A[Lo .. Hi] (inclusive):
   --    1. If Lo >= Hi (length ≤ 1), return — already sorted.
   --    2. Mid := (Lo + Hi) / 2
   --    3. Recursively sort A[Lo .. Mid] and A[Mid+1 .. Hi]
   --    4. Stable-merge the two sorted halves into a temp buffer, then
   --       copy the merged run back into A[Lo .. Hi].
   --
   --  Stability: when Left(I) <= Right(J), take from Left (prefer the
   --  earlier equal). That preserves relative order of equal keys.
   --  Divide-and-conquer invented by John von Neumann in 1945.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending classic top-down stable merge sort.
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Merge_Sort;
