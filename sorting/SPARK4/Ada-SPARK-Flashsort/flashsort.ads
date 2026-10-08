--  Flashsort — Ada/SPARK Level 4 educational package for Neubert flashsort:
--  in-place histogram / cycle-following bucket sort for Integer keys.
--  Expected O(n) on uniform data; O(n²) worst case when insertion sort
--  finishes a badly balanced classification.
--
--  SPARK port of Ada-Flashsort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling uses Max_N = 100_000, allows arbitrary A'First, and raises on
--  oversized n; this port requires A'First = 1, uses a static Border_Array
--  (1 .. Max_N) for class borders (m ≤ Max_N), and proves sortedness via a
--  final gap-1 bubble finish (same proof role as Strand_Sort / Bucket_Sort /
--  Comb_Sort). Full multiset / permutation equality is verified by tests
--  rather than claimed as a Level-4 postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Flashsort

package Flashsort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity / class-count bounds (classroom; static border vector)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 100_000) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   --  Number of classes m = max(2, n / Class_Divisor), i.e. Neubert's
   --  m ≈ 0.1 n with a floor of 2 (need at least two classes so the
   --  interpolation formula can separate min from max).
   Class_Divisor : constant Positive := 10;

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
   -- Algorithm sketch (Neubert flashsort / Wikipedia + bubble finish)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A).
   --  1. Find min and max. If equal, return (already sorted).
   --  2. Choose m = max(2, n / Class_Divisor) classes.
   --  3. Histogram into static L(1 .. Max_N); prefix-sum so L(k) is the
   --     inclusive 1-based upper border of class k.
   --  4. Classify with
   --        K = 1 + floor((m-1)*(x-min)/(max-min))
   --     using Long_Long_Integer; permute into classes by cycle-following
   --     (educational; safe bounds / iteration caps for Level 4 RTE).
   --  5. Insertion-sort within each class.
   --  6. Final gap-1 bubble finish proves Is_Sorted (Strand / Bucket L4
   --     pattern). Flashsort phase posts only In_Bounds / RTE.
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
   --  Ascending educational flashsort + gap-1 bubble finish.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Flashsort;
