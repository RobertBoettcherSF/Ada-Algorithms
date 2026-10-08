--  Insertion_Sort — Ada/SPARK Level 4 educational package for classic
--  stable in-place insertion sort on an Integer array. Best O(n),
--  average/worst O(n²), O(1) extra space; stable and online.
--
--  SPARK port of Ada-Insertion-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling raises on oversized n; this port takes any A'First in
--  1 .. Max_N (indices are First-relative) and uses Pre => In_Bounds
--  (A). Full multiset / permutation equality is verified by tests
--  rather than claimed as a Level-4 postcondition (sortedness is
--  proved).
--
--  Reference: https://en.wikipedia.org/wiki/Insertion_sort

package Insertion_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 100_000) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices lie in 1 .. Max_N (any A'First); Index includes 0 so
   --  an empty array may have Last = First - 1 = 0.
   subtype Index is Natural range 0 .. Max_N;

   --  Live slots; the index subtype carries the 1 .. Max_N origin range,
   --  In_Bounds adds the length.
   subtype Live_Index is Positive range 1 .. Max_N;

   type Element_Array is array (Live_Index range <>) of Integer;

   ---------------------------------------------------------------------------
   -- Shape / sortedness guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'Length <= Max_N
      and then A'First in 1 .. Max_N
      and then A'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard used by every entry point: at most Max_N elements, any
   --  origin with First in 1 .. Max_N (empty arrays use Last = First - 1).

   function Is_Sorted (A : Element_Array) return Boolean is
     (A'Length <= 1
      or else (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1)))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic array insertion sort / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Build a sorted prefix from left to right.
   --  For each index I from A'First + 1 through A'Last:
   --    1. Let Key := A(I).
   --    2. Shift every predecessor A(J) with A(J) > Key one slot right
   --       (strict `>` / Key < A(J) — never `>=` / `<=` — so equal keys
   --       stay in their original relative order: the sort is stable).
   --    3. Insert Key into the vacated slot.
   --  After the outer step for I, the prefix A(A'First .. I) is sorted.
   --  Empty and singleton arrays are no-ops.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending classic stable in-place insertion sort.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Insertion_Sort;
