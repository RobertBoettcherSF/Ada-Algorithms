--  Comb_Sort — Ada/SPARK Level 4 educational package for classic comb
--  sort (Dobosiewicz / Lacey–Box) on an Integer array. Bubble sort with
--  a shrinking gap (≈ /1.3 via gap := gap * 10 / 13). Large early gaps
--  move distant out-of-order keys ("turtles"); the final gap-1 phase is
--  ordinary bubble sort. Unstable. O(1) extra space.
--
--  SPARK port of Ada-Comb-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling allows arbitrary A'First, raises on oversized n, and runs the
--  classic until-gap-1-and-clean-pass loop; this port requires A'First = 1,
--  uses Pre => In_Bounds (A), caps shrinking comb iterations for
--  termination, and proves sortedness via a final gap-1 bubble finish
--  (same role as Shell's gap-1 insertion pass). Full multiset /
--  permutation equality is verified by tests rather than claimed as a
--  Level-4 postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Comb_sort

package Comb_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 100_000) so Level 4 can discharge array / arithmetic VCs.
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
   -- Algorithm sketch (classic comb sort / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Gap starts at n and shrinks by ≈ 1.3:
   --      gap := max(1, floor(gap * 10 / 13))
   --  For each gap > 1, one comb pass compares/swaps A(i) with A(i+gap).
   --  Outer shrink iterations are capped (Max_N) so termination proves.
   --  After gaps > 1, a final gap-1 bubble finish (shrinking unsorted
   --  suffix + early exit) establishes Is_Sorted — same proof role as
   --  Shell_Sort's gap-1 Insertion_Pass.
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
   --  Ascending classic in-place comb sort (shrink ≈ 1.3 + gap-1 bubble).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Comb_Sort;
