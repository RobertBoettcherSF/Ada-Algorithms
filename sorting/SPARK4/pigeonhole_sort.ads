--  Pigeonhole_Sort — Ada/SPARK Level 4 educational package for pigeonhole
--  sort on an Integer array with a bounded key span. Time O(n + N) with
--  N = max − min + 1. Stable count + prefix + scatter into a work buffer.
--
--  SPARK port of Ada-Pigeonhole-Sort: hard Max_N / Max_Range bounds, static
--  Counts (0 .. Max_Range−1) and Work (1 .. Max_N), no exceptions,
--  In_Bounds / Keys_In_Range / Is_Sorted contracts replace
--  Invalid_Argument. Non-SPARK sibling uses Max_Length = Max_Range =
--  100_000, allows arbitrary A'First, and raises on oversized n / span;
--  this port requires A'First = 1, Pre => In_Bounds (A) and then
--  Keys_In_Range (A), and proves sortedness via a final gap-1 bubble
--  finish (same proof role as Flashsort / Strand_Sort / Comb_Sort).
--  Full multiset / permutation equality is verified by tests rather than
--  claimed as a Level-4 postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Pigeonhole_sort

package Pigeonhole_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity / key-span bounds (classroom; static count + work tables)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_Length = 100_000) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   --  Maximum inclusive key span (max − min + 1). Count table is
   --  array (0 .. Max_Range − 1) — size 256. Sibling uses Max_Range =
   --  100_000 over arbitrary Integer min..max.
   Max_Range : constant Positive := 256;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices are 1 .. N with N ≤ Max_N. Empty arrays use Last = 0.
   subtype Index is Natural range 0 .. Max_N;

   type Element_Array is array (Positive range <>) of Integer;

   subtype Hole_Index is Natural range 0 .. Max_Range - 1;
   type Count_Array is array (Hole_Index) of Natural;

   --  Static work buffer: live slots are 1 .. N with N ≤ Max_N.
   type Work_Array is array (Positive range 1 .. Max_N) of Integer;

   ---------------------------------------------------------------------------
   -- Shape / key-span / sortedness guards
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'First = 1 and then A'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard used by every entry point. Empty arrays have
   --  A'Last = 0 when A'First = 1 (rejects Last < 0).

   function Keys_In_Range (A : Element_Array) return Boolean
     with
       Global => null,
       Pre    => In_Bounds (A);
   --  True when A is empty/singleton, or (max − min + 1) ≤ Max_Range.
   --  Span is computed with Long_Long_Integer so Integer'First .. Last
   --  cannot wrap. Body-implemented (not an expression function) so the
   --  min/max scan stays readable and proveable.

   function Is_Sorted (A : Element_Array) return Boolean is
     (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Wikipedia pigeonhole + bubble finish)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A) and Keys_In_Range (A).
   --  1. Find Min and Max among A (Long_Long_Integer span check).
   --  2. N_holes = Max − Min + 1 ≤ Max_Range pigeonholes.
   --  3. Count: Counts (key − Min) += 1 for each item.
   --  4. Prefix: convert counts into starting offsets in Work.
   --  5. Stable scatter left-to-right into Work hole segments.
   --  6. Copy Work (1 .. n) back into A.
   --  7. Final gap-1 bubble finish proves Is_Sorted (Flashsort L4 pattern).
   --  Empty and singleton arrays are no-ops.
   --  Contrast with counting sort: pigeonhole *moves items into holes*
   --  then concatenates; counting builds a count table and emits keys.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then Keys_In_Range (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending educational pigeonhole sort + gap-1 bubble finish.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Pigeonhole_Sort;
