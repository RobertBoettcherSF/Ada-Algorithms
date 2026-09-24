--  Patience_Sorting — Ada/SPARK Level 4 educational package for patience
--  sorting on an Integer array. Deal each element onto piles (leftmost
--  pile whose top >= element, else a new pile), then recover sorted order
--  by repeatedly taking the minimum among pile tops (k-way merge).
--  Number of piles equals the length of a longest increasing subsequence
--  under the classic >= placement rule (Wikipedia / Aldous–Diaconis).
--  Static node pool only (no unbounded heap).
--
--  SPARK port of Ada-Patience-Sorting: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling uses Max_N = 8192, allows arbitrary A'First, and raises on
--  oversized n; this port requires A'First = 1, uses a fixed node pool
--  and Top_Array of size Max_N, and proves sortedness via a final gap-1
--  bubble finish (same proof role as Comb_Sort / Odd_Even_Sort /
--  Shell_Sort / Strand_Sort). Full multiset / permutation equality is
--  verified by tests rather than claimed as a Level-4 postcondition
--  (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Patience_sorting

package Patience_Sorting
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 8_192) so Level 4 can discharge array / arithmetic VCs.
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
   -- Algorithm sketch (deal onto piles + k-way merge + bubble finish)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Allocate a fixed node pool of Max_N stack
   --  nodes and a Top_Array of at most Max_N pile tops.
   --  Phase 1 — Deal: each element X goes on the leftmost pile whose top
   --    is >= X (binary search on strictly increasing tops); else a new
   --    pile. Within a pile, newer tops are <= older tops.
   --  Phase 2 — Merge: repeatedly pop the pile with the smallest top
   --    (k-way merge) into A; empty piles are discarded by swap-with-last.
   --  After deal+merge, a final gap-1 bubble finish (shrinking unsorted
   --  suffix + early exit) establishes Is_Sorted — same proof role as
   --  Comb_Sort's Bubble_Finish / Odd_Even_Sort / Shell / Strand.
   --  Deal/merge posts that would fight Level 4 are intentionally limited
   --  to In_Bounds / RTE; sortedness is discharged by Bubble_Finish.
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
   --  Ascending patience sort (static node pool) + gap-1 bubble finish.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Patience_Sorting;
