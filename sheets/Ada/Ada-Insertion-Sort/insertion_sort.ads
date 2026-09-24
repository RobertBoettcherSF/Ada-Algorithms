--  Insertion_Sort — Ada 2023 educational package for classic stable
--  in-place insertion sort on Integer arrays with a bounded length.
--  Best O(n), average/worst O(n²), O(1) extra space; stable and online.
--  Reference: https://en.wikipedia.org/wiki/Insertion_sort

pragma Ada_2022;

package Insertion_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   --  Insertion sort is O(n²) in the average/worst case, so callers should
   --  keep n modest in practice; Max_N is an educational upper guard.
   --  The sort is in-place (O(1) auxiliary memory).
   Max_N : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic array insertion sort / Wikipedia)
   ---------------------------------------------------------------------------
   --  Build a sorted prefix from left to right. For each index i from the
   --  second element through the end:
   --    1. Let Key := A(i).
   --    2. Shift every predecessor A(j) with A(j) > Key one slot right
   --       (strict `>` / Key < A(j) — never `>=` / `<=` — so equal keys
   --       stay in their original relative order: the sort is stable).
   --    3. Insert Key into the vacated slot.
   --  After i steps the prefix A'First .. A'First+i is sorted.
   --
   --  Adaptive / online: already-sorted input needs only n−1 comparisons
   --  (best O(n)); each new element can be inserted as it arrives.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending classic stable in-place insertion sort.
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Insertion_Sort;
