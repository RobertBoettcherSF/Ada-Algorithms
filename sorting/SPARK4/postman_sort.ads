--  Postman_Sort — Ada/SPARK Level 4 educational package for MSD (most-
--  significant-digit) postal / pigeonhole distribution sort. Stable
--  scatter into Base = 10 digit buckets, recurse on each bucket at the
--  next lower Exp, gather. Nonnegative Integer keys only.
--
--  SPARK port of Ada-Postman-Sort: hard Max_N bound, fixed Base = 10
--  (static digit arrays 0 .. 9), no Sort_Base, no exceptions,
--  In_Bounds / Keys_Ok / Is_Sorted contracts replace Invalid_Argument.
--  Non-SPARK sibling uses Max_Length = 100_000, Max_Base = 256, optional
--  Sort_Base, arbitrary A'First, and raises on negatives / oversize;
--  this port requires A'First = 1, Pre => In_Bounds (A) and then
--  Keys_Ok (A), and proves sortedness via a final gap-1 bubble finish
--  (same proof role as Flashsort / Strand_Sort / Pigeonhole_Sort).
--  Full multiset / permutation equality is verified by tests rather than
--  claimed as a Level-4 postcondition (sortedness is proved).
--
--  References:
--    https://en.wikipedia.org/wiki/Postman_sort
--    https://en.wikipedia.org/wiki/Bucket_sort (Postman's sort variant)

package Postman_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity / radix bounds (classroom; static work + digit tables)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_Length = 100_000) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   --  Fixed educational radix (decimal digits). Sibling offers Sort_Base
   --  with 2 .. Max_Base = 256. Count / start tables are 0 .. Base - 1.
   Base : constant Positive := 10;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices are 1 .. N with N ≤ Max_N. Empty arrays use Last = 0.
   subtype Index is Natural range 0 .. Max_N;

   type Element_Array is array (Positive range <>) of Integer;

   --  Decimal digit domain for the fixed Base = 10 classroom radix.
   subtype Digit_Index is Natural range 0 .. Base - 1;
   type Count_Array is array (Digit_Index) of Natural;

   --  Static work buffer: live slots are 1 .. N with N ≤ Max_N.
   type Work_Array is array (Positive range 1 .. Max_N) of Integer;

   ---------------------------------------------------------------------------
   -- Shape / nonnegative-key / sortedness guards
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'First = 1 and then A'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard used by every entry point. Empty arrays have
   --  A'Last = 0 when A'First = 1 (rejects Last < 0).

   function Keys_Ok (A : Element_Array) return Boolean is
     (for all I in A'Range => A (I) >= 0)
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  Nonnegative keys only. Digit extraction (key / Exp) mod Base is
   --  defined here for 0 .. Integer'Last. Empty arrays are vacuously ok.

   function Is_Sorted (A : Element_Array) return Boolean is
     (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (MSD postal distribution + bubble finish)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A) and Keys_Ok (A).
   --  1. Find Max among A; if Max = 0, already sorted (all zeros).
   --  2. Exp = Highest_Exp (Max) = largest Base^p with Exp <= Max.
   --  3. Histogram of digit d = (key / Exp) mod Base on the live range.
   --  4. Stable scatter left-to-right into digit buckets (Work buffer).
   --  5. Gather Work back into A.
   --  6. Recurse on each bucket with more than one element at Exp / Base
   --     (Subprogram_Variant decreases Exp). Stop at Exp = 1.
   --  7. Final gap-1 bubble finish proves Is_Sorted (Flashsort L4 pattern).
   --  Empty and singleton arrays are no-ops.
   --  Contrast: LSD radix walks least → most with flat counting passes;
   --  Postman walks most → least with recursive pigeonholes. Bucket sort
   --  is the one-level form; pigeonhole is one key per hole.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then Keys_Ok (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending educational MSD postman sort (base 10) + gap-1 bubble
   --  finish. Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Postman_Sort;
