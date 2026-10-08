--  Counting_Sort — Ada/SPARK Level 4 educational package for classic
--  counting sort on a bounded-key Element array. Time O(n + k) with
--  k = Max_Key + 1. Reconstruction emit over a fixed count table.
--
--  SPARK port of Ada-Counting-Sort: hard Max_N bound, fixed count table
--  over 0 .. Max_Key (no dynamic min/max span), no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling allows arbitrary Integer keys, Max_Range = 100_000, and
--  arbitrary A'First; this port requires A'First = 1, Element in
--  0 .. Max_Key, and uses Pre => In_Bounds (A). Full multiset /
--  permutation equality is verified by tests rather than claimed as a
--  Level-4 postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Counting_sort

package Counting_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity / key-domain bounds (classroom; static count table)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_Length = 100_000) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   --  Inclusive upper bound on Element values. Count table is
   --  array (0 .. Max_Key) — size 256. Sibling uses dynamic
   --  Max_Range = 100_000 over arbitrary Integer min..max.
   Max_Key : constant Natural := 255;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices are 1 .. N with N ≤ Max_N. Empty arrays use Last = 0.
   subtype Index is Natural range 0 .. Max_N;

   --  Educational keys: fixed span so the count table is a static array.
   subtype Element is Natural range 0 .. Max_Key;

   type Element_Array is array (Positive range <>) of Element;

   subtype Count_Index is Element;
   type Count_Array is array (Count_Index) of Natural;

   ---------------------------------------------------------------------------
   -- Shape / sortedness guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'First = 1 and then A'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard used by every entry point. Empty arrays have
   --  A'Last = 0 when A'First = 1 (rejects Last < 0).
   --  Element subtype already enforces keys in 0 .. Max_Key.

   function Is_Sorted (A : Element_Array) return Boolean is
     (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic counting sort / Wikipedia reconstruction)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Keys live in 0 .. Max_Key.
   --  1. Histogram: Hist (K) := occurrences of key K in A.
   --  2. Emit: for K in 0 .. Max_Key, write Hist (K) copies of K into A
   --     left-to-right (CDF expansion / reconstruction).
   --  When Element is the key, equal keys are identical so content-level
   --  stability is vacuous; the non-SPARK sibling uses reverse-scan place
   --  for satellite stability. Empty and singleton arrays are no-ops.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending classic counting sort (histogram → emit by ascending key).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Counting_Sort;
