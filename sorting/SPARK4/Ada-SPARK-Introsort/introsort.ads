--  Introsort — Ada/SPARK Level 4 educational package for Musser
--  introspective sort: hybrid of quicksort + heapsort + insertion sort
--  (David Musser, 1997) on an Integer array. Average like quicksort;
--  worst-case O(n log n) via a heapsort depth cutoff; small partitions
--  finished with insertion sort. In-place (the heapsort fallback
--  sifts directly on the slice Lo .. Hi), unstable, ascending.
--
--  SPARK port of Ada-Introsort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling uses Hoare partition, First-relative heap math, arbitrary
--  A'First, Max_N = 100_000, and raises on oversized n; this port
--  uses Lomuto so the pivot lands in a final slot, First-relative
--  Floyd sift in place on Lo..Hi (Has_Left before Left =
--  Lo+2*(I-Lo)+1 — no scratch copy, any A'First), and bounds
--  recursive Intro_Sort_Rec with a Subprogram_Variant so proofs
--  discharge. Full multiset /
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

   --  Live indices lie in 1 .. Max_N (any A'First); Index includes 0 so
   --  an empty array may have Last = First - 1 = 0.
   subtype Index is Natural range 0 .. Max_N;
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
   --  At most Max_N elements; any origin with First in 1 .. Max_N
   --  (empty arrays use Last = First - 1, possibly 0).

   function Is_Sorted (A : Element_Array) return Boolean is
     (A'Length <= 1
      or else (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1)))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Musser introsort / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). maxdepth ← 2 × ⌊log₂ n⌋ (n = A'Length).
   --  Recurse on Lo .. Hi (initially A'Range) with remaining depth:
   --    If Lo >= Hi, return (empty / singleton are no-ops).
   --    If m = Hi-Lo+1 ≤ Insertion_Threshold: insertion-sort the slice.
   --    Else if depth = 0: heapsort the slice in place (offset Floyd
   --      heapify + extract-max on Lo .. Hi, Has_Left before Left)
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
