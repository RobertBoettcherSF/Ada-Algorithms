--  Bubble_Sort — Ada 2023 educational package for classic bubble sort
--  (sinking sort): repeated adjacent compares/swaps with a shrinking
--  unsorted suffix and early exit on a clean (swap-free) pass.
--  Stable when the swap predicate is strict `>` (not `>=`).
--  O(n²) average/worst, O(n) best (already sorted); O(1) extra space.
--  Reference: https://en.wikipedia.org/wiki/Bubble_sort

pragma Ada_2022;

package Bubble_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   --  Bubble sort is O(n²) in the average/worst case, so callers should
   --  keep n modest in practice (tests use reverse/random n ≤ ~500).
   --  Max_N is an educational upper guard. The sort is in-place (O(1)
   --  auxiliary memory).
   Max_N : constant Positive := 10_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic bubble sort / Wikipedia)
   ---------------------------------------------------------------------------
   --  Maintain an active upper bound Bound (initially A'Last). Each pass:
   --    For I in A'First .. Bound-1, if A(I) > A(I+1) then swap and
   --    record the last swap index. After the pass, Bound becomes the
   --    last swap index (everything after it is already in final place).
   --  Stop early when a pass performs no swaps (array fully ordered).
   --  Empty and singleton arrays are no-ops.
   --  Stability: using strict `>` (not `>=`) never reorders equal keys.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending in-place classic bubble sort with early exit and
   --  shrinking unsorted suffix (last-swap bound).
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Bubble_Sort;
