--  Selection_Sort — Ada/SPARK Level 4 educational package for classic
--  in-place selection sort on an Integer array. Always Θ(n²) comparisons,
--  at most n − 1 swaps, O(1) extra space; not stable under the swap
--  formulation.
--
--  SPARK port of Ada-Selection-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling allows arbitrary A'First and raises on oversized n; this port
--  requires A'First = 1 and uses Pre => In_Bounds (A). Full multiset /
--  permutation equality is verified by tests rather than claimed as a
--  Level-4 postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Selection_sort

package Selection_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_Length = 10_000) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices are 1 .. N with N ≤ Max_N. Empty arrays use Last = 0.
   subtype Index is Natural range 0 .. Max_N;

   type Element_Array is array (Positive range <>) of Integer;

   ---------------------------------------------------------------------------
   -- Shape / sortedness guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'First = 1 and then A'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard used by every entry point. Empty arrays have
   --  A'Last = 0 when A'First = 1 (rejects Last < 0).

   function Is_Sorted (A : Element_Array) return Boolean is
     (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   function Is_Sorted_Descending (A : Element_Array) return Boolean is
     (for all I in A'First .. A'Last - 1 => A (I) >= A (I + 1))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nonincreasing on A'Range.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic array selection sort / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Grow a sorted prefix from left to right.
   --  For each index I from 1 through A'Last - 1:
   --    1. Find Min_Index := argmin of A (I .. A'Last).
   --    2. Swap A (I) with A (Min_Index).
   --  After the outer step for I, A (1 .. I) holds the I smallest
   --  elements in order, and every element of the prefix is ≤ every
   --  element of the remaining suffix. Empty / singleton are no-ops.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending classic in-place selection sort (min of suffix → prefix).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

   procedure Sort_Descending (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted_Descending (A);
   --  Same structure as Sort, selecting the maximum of each unsorted
   --  suffix so the result is nonincreasing. Empty / singleton no-ops.

end Selection_Sort;
