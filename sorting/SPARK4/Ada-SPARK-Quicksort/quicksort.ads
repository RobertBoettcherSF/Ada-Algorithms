--  Quicksort — Ada/SPARK Level 4 educational package for classic
--  in-place quicksort (Tony Hoare, 1959/1961) on an Integer array.
--  Median-of-three pivot + Lomuto partition. Average O(n log n),
--  worst O(n²); unstable, ascending. Recursion depth ≤ Max_N.
--
--  SPARK port of Ada-Quicksort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling uses Hoare partition, allows arbitrary A'First, and raises
--  on oversized n; this port requires A'First = 1, uses Lomuto so the
--  pivot lands in a final slot, and bounds recursive Sort_Range with a
--  Subprogram_Variant so Level 4 can discharge the VCs. Full multiset /
--  permutation equality is verified by tests rather than claimed as a
--  Level-4 postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Quicksort

package Quicksort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / recursion VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 100_000) so Level 4 can discharge array / arithmetic VCs
   --  and recursion depth stays ≤ Max_N.
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

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic in-place quicksort / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Recurse on Lo .. Hi (initially 1 .. A'Last):
   --    If Lo >= Hi, return (empty / singleton are no-ops).
   --    1. Median-of-three on A(Lo), A(Mid), A(Hi); swap the median to Hi.
   --    2. Lomuto-partition around A(Hi): scan Lo .. Hi-1, swap each
   --       A(J) <= pivot toward the front, then swap the pivot into
   --       slot P. Afterward A(Lo .. P-1) <= A(P) <= A(P+1 .. Hi)
   --       (right side actually > A(P) because the scan uses `<=`).
   --    3. Recurse on Lo .. P-1 and P+1 .. Hi (skip empty sides).
   --  The Subprogram_Variant (Hi - Lo) strictly decreases on each
   --  recursive call. Empty and singleton arrays are no-ops.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending classic in-place quicksort (median-of-three + Lomuto).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Quicksort;
