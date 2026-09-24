--  Selection_Sort — Ada 2023 educational package for classic in-place
--  selection sort. Divides the array into a growing sorted prefix and
--  an unsorted suffix; each pass finds the minimum of the suffix and
--  swaps it into the next prefix slot. Uses O(n²) comparisons and at
--  most n − 1 swaps; not stable under the swap formulation.
--  Reference: https://en.wikipedia.org/wiki/Selection_sort

pragma Ada_2022;

package Selection_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bound (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort / Sort_Descending.
   Max_Length : constant Positive := 10_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_Length.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Classic in-place ascending selection sort:
   --  for I in A'First .. A'Last - 1, find the minimum in A (I .. A'Last)
   --  and swap it with A (I). Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_Length.
   --  Comparison count is always n(n − 1)/2 for length n ≥ 1;
   --  at most n − 1 swaps (often exactly that many when counting
   --  self-swaps as performed).

   procedure Sort_Descending (A : in out Element_Array);
   --  Same structure as Sort, but each pass selects the maximum of the
   --  unsorted suffix so the result is nonincreasing (descending).
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_Length.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

   function Is_Sorted_Descending (A : Element_Array) return Boolean;
   --  True iff A is nonincreasing (descending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Selection_Sort;
