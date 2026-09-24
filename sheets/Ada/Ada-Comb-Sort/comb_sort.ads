--  Comb_Sort — Ada 2023 educational package for classic comb sort
--  (Dobosiewicz / Lacey–Box): bubble sort with a shrinking gap.
--  Shrink factor ≈ 1.3 via integer arithmetic gap := gap * 10 / 13.
--  Improves on bubble sort by moving "turtles" (small values near the
--  end) more than one position per swap. Unstable. O(1) extra space.
--  Reference: https://en.wikipedia.org/wiki/Comb_sort

pragma Ada_2022;

package Comb_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   --  Comb sort is typically much faster than bubble sort in practice,
   --  so a large educational bound is fine. The sort is in-place (O(1)
   --  auxiliary memory).
   Max_N : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic comb sort / Wikipedia)
   ---------------------------------------------------------------------------
   --  Comb sort is bubble sort with a shrinking gap. The gap starts at n
   --  and is repeatedly reduced by the shrink factor k ≈ 1.3:
   --
   --      gap := max(1, floor(gap / k))
   --
   --  using integer arithmetic: gap := max(1, gap * 10 / 13).
   --  For each gap, compare/swap A(i) with A(i+gap) across the array,
   --  tracking whether any swap occurred. Continue until gap = 1 and a
   --  full pass makes no swaps (final bubble-sort pass).
   --
   --  Large early gaps move distant out-of-order keys ("turtles") quickly;
   --  the final gap-1 stage is ordinary bubble sort on a nearly ordered
   --  array. Unstable: gapped swaps can reorder equal keys.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending in-place classic comb sort (shrink ≈ 1.3).
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Comb_Sort;
