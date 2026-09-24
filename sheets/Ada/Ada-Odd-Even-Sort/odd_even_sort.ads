--  Odd_Even_Sort — Ada 2023 educational package for odd–even sort
--  (odd–even transposition sort / brick sort / parity sort).
--  Sequential O(n²) comparison sort related to bubble sort; designed
--  for parallel processors with local neighbour connections.
--  Reference: https://en.wikipedia.org/wiki/Odd%E2%80%93even_sort

pragma Ada_2022;

package Odd_Even_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   --  Sequential odd–even sort is O(n²), so callers should keep n modest
   --  in practice (tests use reverse/random n ≤ ~500). Max_N is an
   --  educational upper guard. The sort is in-place (O(1) auxiliary
   --  memory).
   Max_N : constant Positive := 10_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Wikipedia sequential listing, 0-based)
   ---------------------------------------------------------------------------
   --  Repeat until a full cycle makes no swaps:
   --    1. Odd phase:  compare/swap 0-based offsets (1,2), (3,4), …
   --    2. Even phase: compare/swap 0-based offsets (0,1), (2,3), …
   --  Offsets are relative to A'First, so any A'First works:
   --    odd  → A(A'First+1) vs A(A'First+2), …
   --    even → A(A'First)   vs A(A'First+1), …
   --  Swap only when A(I) > A(I+1) (strict `>`; never `>=`) so equal
   --  keys keep their relative order (stable, like bubble sort).
   --  Empty and singleton arrays are already sorted (no-ops).
   --  Not Batcher's odd–even mergesort. Do not `with` sibling Ada-*
   --  packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending in-place odd–even (brick) sort.
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Odd_Even_Sort;
