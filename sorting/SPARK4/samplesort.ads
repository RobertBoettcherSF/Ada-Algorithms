--  Samplesort — Ada/SPARK Level 4 educational package for Wikipedia
--  samplesort: sample Num_Buckets-1 pivots, distribute into static
--  buckets, insertion-sort each bucket, concatenate. Expected near
--  O(n log n) with balanced buckets; O(n²) worst when buckets are
--  unbalanced (insertion finish).
--
--  SPARK port of Ada-Samplesort: hard Max_N bound, fixed Num_Buckets,
--  no exceptions, no Ada tasks / Parallel variant, no Oversampling
--  API — a single Sort procedure. Non-SPARK sibling uses Data_Element,
--  Sequential / Parallel / Oversampling variants, Quick_Sort buckets,
--  exceptions (Invalid_Bucket_Count / Invalid_Oversample_Factor), and
--  arbitrary A'First; this port requires A'First = 1, Integer
--  Element_Array, static Work (1 .. Max_N) + Counts / Borders, and
--  proves sortedness via a final gap-1 bubble finish (same proof role
--  as Flashsort / Strand_Sort / Comb_Sort). Full multiset /
--  permutation equality is verified by tests rather than claimed as a
--  Level-4 postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Samplesort

package Samplesort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity / bucket bounds (classroom; static work vector)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than typical non-SPARK
   --  siblings so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   --  Fixed classroom bucket count. Sibling takes Num_Buckets as a
   --  parameter (and may spawn one task per bucket); this port fixes
   --  Num_Buckets = 8 so storage is static.
   Num_Buckets : constant Positive := 8;

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
   -- Algorithm sketch (Wikipedia samplesort + bubble finish)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A).
   --  1. If n < Num_Buckets, skip sampling (Bubble_Finish sorts).
   --  2. Choose Num_Buckets-1 pivots from equally spaced samples
   --     (deterministic stride = n / Num_Buckets; no RNG).
   --  3. Sort pivots (insertion on the small pivot vector).
   --  4. Count / distribute elements into Num_Buckets static buckets
   --     in Work (1 .. Max_N) via Starts / Counts borders.
   --  5. Insertion-sort each non-empty bucket in Work.
   --  6. Copy Work back into A (concatenate).
   --  7. Final gap-1 bubble finish proves Is_Sorted (Flashsort /
   --     Strand L4 pattern). Samplesort phase posts only In_Bounds /
   --     RTE.
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
   --  Ascending educational samplesort + gap-1 bubble finish.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Samplesort;
