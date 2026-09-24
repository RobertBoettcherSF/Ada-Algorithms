--  Strand_Sort — Ada 2023 educational package for strand sort on Integer
--  arrays with a bounded length.
--  Best O(n) when already sorted; worst O(n²) when reverse-sorted;
--  average often cited around O(n log n).
--  Reference: https://en.wikipedia.org/wiki/Strand_sort

pragma Ada_2022;

package Strand_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   Max_N : constant Positive := 4_096;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (strand extraction + merge)
   ---------------------------------------------------------------------------
   --  1. Start with the unsorted input and an empty sorted output list.
   --  2. Extract a *strand*: take the first remaining element, then walk
   --     left-to-right and greedily append every subsequent element that is
   --     >= the last taken value (nondecreasing subsequence). Remove those
   --     elements from the input (array simulation via a work buffer).
   --  3. Merge the strand into the sorted output (two-way merge).
   --  4. Repeat until the input is empty; copy the output back into A.
   --
   --  Named "strand" sort because sorted increasing strands are pulled from
   --  the unsorted residue one at a time. Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending strand sort. Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Strand_Sort;
