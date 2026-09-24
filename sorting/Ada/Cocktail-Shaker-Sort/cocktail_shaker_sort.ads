--  Cocktail_Shaker_Sort — Ada 2023 educational package for cocktail
--  shaker sort (bidirectional bubble sort / cocktail sort / shaker sort):
--  bubble sort that alternates forward and backward passes, shrinking
--  the active lo..hi window after each pass. O(n²) average/worst, near
--  O(n) on mostly ordered input; O(1) extra space.
--  Reference: https://en.wikipedia.org/wiki/Cocktail_shaker_sort

pragma Ada_2022;

package Cocktail_Shaker_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   --  Cocktail shaker sort is O(n²) in the average/worst case, so callers
   --  should keep n modest in practice (tests use reverse/random n ≤ ~500).
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
   -- Algorithm sketch (cocktail / bidirectional bubble sort)
   ---------------------------------------------------------------------------
   --  Maintain an active window [Lo .. Hi]. Each round:
   --    Forward pass:  for I in Lo .. Hi-1, swap if A(I) > A(I+1);
   --                   then Hi := Hi - 1  (largest key bubbled to Hi).
   --    Backward pass: for I in reverse Lo .. Hi-1, swap if A(I) > A(I+1);
   --                   then Lo := Lo + 1  (smallest key bubbled to Lo).
   --  Stop early when a pass performs no swaps (array already ordered
   --  inside the remaining window). Empty and singleton arrays are no-ops.
   --  Still a bubble-sort relative: adjacent compares/swaps only.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending in-place cocktail shaker (bidirectional bubble) sort.
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Cocktail_Shaker_Sort;
