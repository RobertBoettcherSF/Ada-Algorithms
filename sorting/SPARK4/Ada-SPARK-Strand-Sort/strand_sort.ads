--  Strand_Sort — Ada/SPARK Level 4 educational package for strand sort on
--  an Integer array. Repeatedly extract a nondecreasing strand from the
--  remaining input and merge it into a sorted output (Wikipedia). Best
--  O(n) when already sorted; worst O(n²) when reverse-sorted; average
--  often cited around O(n log n). Static buffers only (no unbounded lists).
--
--  SPARK port of Ada-Strand-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling uses Max_N = 4096, allows arbitrary A'First, and raises on
--  oversized n; this port requires A'First = 1, uses fixed Input / Strand /
--  Output / Remaining buffers of size Max_N, and proves that the strand
--  phase sorts on its own (sorted strands, sorted merges, all N elements
--  merged within N outer iterations). Full multiset / permutation equality
--  is verified by tests rather than claimed as a Level-4 postcondition.
--
--  Reference: https://en.wikipedia.org/wiki/Strand_sort

package Strand_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 4_096) so Level 4 can discharge array / arithmetic VCs.
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
   -- Algorithm sketch (strand extraction + merge)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Allocate fixed buffers Input, Strand, Output,
   --  Remaining : Element_Array (1 .. Max_N). Copy A into Input.
   --  While Input_Len > 0 (capped at Max_N outer iterations):
   --    Extract a nondecreasing strand: take Input(1), then greedily append
   --    every subsequent element >= last taken; leftovers go to Remaining.
   --    Merge Strand into Output (stable two-way merge, prefer left on ≤).
   --    Replace Input with Remaining.
   --  Copy Output back into A.
   --  Level 4 proves each strand nondecreasing, each merge result
   --  nondecreasing, and Input empty after the capped outer loop (every
   --  iteration moves at least one element), so Output, copied back into A,
   --  is sorted. There is no fallback pass.
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
   --  Ascending strand sort (static buffers); the strand phase alone
   --  establishes Is_Sorted.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Strand_Sort;
