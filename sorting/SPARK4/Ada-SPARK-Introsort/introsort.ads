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
--  discharge. The Post proves
--  sortedness and that the result holds the input's values, each
--  equally often (Is_Perm, counted with Occ).
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
   -- Permutation (multiset) model, used by the Post of Sort
   ---------------------------------------------------------------------------

   function Occ (A : Element_Array; V : Integer; Last : Natural) return Natural
   with
     Global             => null,
     Pre                => In_Bounds (A) and then Last <= A'Last,
     Post               => Occ'Result <= Last,
     Subprogram_Variant => (Decreases => Last);
   --  How many of A (A'First .. Last) equal V.

   function Occ (A : Element_Array; V : Integer; Last : Natural) return Natural is
     (if Last < A'First then 0
      else Occ (A, V, Last - 1) + (if A (Last) = V then 1 else 0));

   function Is_Perm (A, B : Element_Array) return Boolean is
     (A'First = B'First
      and then A'Last = B'Last
      and then (for all I in A'Range =>
                  Occ (A, A (I), A'Last) = Occ (B, A (I), B'Last))
      and then (for all I in B'Range =>
                  Occ (A, B (I), A'Last) = Occ (B, B (I), B'Last)))
   with
     Global => null,
     Pre    => In_Bounds (A) and then In_Bounds (B);
   --  A and B have the same bounds and hold the same values, each equally
   --  often. A value found in neither array counts 0 in both, so comparing
   --  the counts of the values of A and of B covers every value.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A) and then Is_Perm (A, A'Old);
   --  Ascending Musser introsort (median-of-three Lomuto + heapsort
   --  depth cutoff + insertion for small partitions).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness and that A holds the values of A'Old, each
   --  equally often (Is_Perm).

   --  Musser depth budget: 2 * floor(log2 N); at most 12 for N <= Max_N.
   subtype Depth_Limit is Natural range 0 .. 12;

   function Depth_Budget (N : Natural) return Depth_Limit
     with
       Global => null,
       Pre    => N <= Max_N;
   --  2 * floor(log2 N) for N >= 1 (the budget Sort uses); 0 for N = 0.

   procedure Sort_Traced
     (A              : in out Element_Array;
      Max_Depth      : Depth_Limit;
      Heap_Fallbacks : out Natural)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   =>
         In_Bounds (A)
         and then Is_Sorted (A)
         and then Is_Perm (A, A'Old)
         and then Heap_Fallbacks <= A'Length;
   --  Same introsort as Sort, but with an explicit depth budget and a
   --  count of slices finished by the depth-0 heapsort fallback.
   --  Sort (A) = Sort_Traced (A, Depth_Budget (A'Length), _).
   --  Max_Depth = 0 heapsorts the whole array when A'Length > 16.

end Introsort;
