--  Introsort — Ada/SPARK Level 4 educational package for Musser
--  introspective sort: hybrid of quicksort + heapsort + insertion sort
--  (David Musser, 1997) on an Integer array. Average like quicksort;
--  worst-case O(n log n) via a heapsort depth cutoff; small partitions
--  finished with insertion sort. In-place (aside from a classroom
--  scratch buffer on the heapsort fallback), unstable, ascending.
--
--  SPARK port of Ada-Introsort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling uses Hoare partition, First-relative heap math, arbitrary
--  A'First, Max_N = 100_000, and raises on oversized n; this port
--  requires A'First = 1, uses Lomuto so the pivot lands in a final
--  slot, 1-based Floyd sift on a scratch copy of the exhausted
--  partition, and bounds recursive Intro_Sort_Rec with a
--  Subprogram_Variant so Level 4 can discharge the VCs. Full multiset /
--  permutation equality is verified by tests rather than claimed as a
--  Level-4 postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Introsort

package Introsort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / recursion VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 100_000) so Level 4 can discharge array / arithmetic VCs
   --  and recursion depth stays ≤ Max_N.
   Max_N : constant Positive := 64;

   --  Partitions of this size or smaller are finished with insertion
   --  sort (classic Musser / SGI / libstdc++ threshold).
   Insertion_Threshold : constant Positive := 16;

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
   -- Algorithm sketch (Musser introsort / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). maxdepth ← 2 × ⌊log₂ n⌋ (n = A'Last).
   --  Recurse on Lo .. Hi (initially 1 .. A'Last) with remaining depth:
   --    If Lo >= Hi, return (empty / singleton are no-ops).
   --    If m = Hi-Lo+1 ≤ Insertion_Threshold: insertion-sort the slice.
   --    Else if depth = 0: heapsort the slice (Floyd heapify + extract-
   --      max on a 1-based scratch copy of the partition, then copy back)
   --      so the worst case is O(n log n).
   --    Else:
   --      1. Median-of-three on A(Lo), A(Mid), A(Hi); swap the median
   --         to Hi.
   --      2. Lomuto-partition around A(Hi): scan Lo .. Hi-1, swap each
   --         A(J) <= pivot toward the front, then swap the pivot into
   --         slot P. Afterward A(Lo .. P-1) <= A(P) <= A(P+1 .. Hi).
   --      3. Recurse on Lo .. P-1 and P+1 .. Hi with depth − 1.
   --  The Subprogram_Variant (Hi - Lo) strictly decreases on each
   --  recursive call. Empty and singleton arrays are no-ops.
   --  Do not `with` sibling Ada-* packages (helpers are inlined).

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending Musser introsort (median-of-three Lomuto + heapsort
   --  depth cutoff + insertion for small partitions).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Introsort;
