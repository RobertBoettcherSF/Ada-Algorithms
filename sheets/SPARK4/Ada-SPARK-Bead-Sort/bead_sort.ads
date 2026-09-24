--  Bead_Sort — Ada/SPARK Level 4 educational package for bead sort
--  (gravity sort) on a bounded Natural array. Software simulation is
--  O(n · M) with M = max value; static Rods (1 .. Max_Value).
--
--  SPARK port of Ada-Bead-Sort: hard Max_N / Max_Value bounds, static
--  rod counters, no exceptions, In_Bounds / Values_Ok / Is_Sorted
--  contracts replace Invalid_Argument. Non-SPARK sibling uses
--  Max_N = Max_Value = 1_024, allows arbitrary A'First, and raises on
--  oversized n / values; this port requires A'First = 1, Pre =>
--  In_Bounds (A) and then Values_Ok (A), and proves sortedness via a
--  final gap-1 bubble finish (same proof role as Pigeonhole_Sort /
--  Strand_Sort / Comb_Sort / Flashsort). Full multiset / permutation
--  equality is verified by tests rather than claimed as a Level-4
--  postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Bead_sort

package Bead_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity / value-domain bounds (classroom; static rod table)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 1_024) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   --  Inclusive upper bound on Natural values. Rod table is
   --  array (1 .. Max_Value) — size 64. Sibling uses Max_Value = 1_024.
   Max_Value : constant Natural := 64;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices are 1 .. N with N ≤ Max_N. Empty arrays use Last = 0.
   subtype Index is Natural range 0 .. Max_N;

   --  Nonnegative integers (including 0 = zero beads). Wikipedia's
   --  original presentation targets positive integers; allowing 0 is
   --  natural for a rod model and matches common software simulations.
   type Element_Array is array (Positive range <>) of Natural;

   subtype Rod_Index is Positive range 1 .. Max_Value;
   type Rod_Array is array (Rod_Index) of Natural;

   ---------------------------------------------------------------------------
   -- Shape / value / sortedness guards
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'First = 1 and then A'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard used by every entry point. Empty arrays have
   --  A'Last = 0 when A'First = 1 (rejects Last < 0).

   function Values_Ok (A : Element_Array) return Boolean is
     (for all I in A'Range => A (I) <= Max_Value)
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff every live element is ≤ Max_Value (fits the static rods).

   function Is_Sorted (A : Element_Array) return Boolean is
     (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (abacus / gravity + bubble finish)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A) and Values_Ok (A).
   --  1. Find M = max(A). Static Rods (1 .. Max_Value) := 0.
   --  2. For each a_i > 0, increment Rods (1 .. a_i) (drop beads).
   --  3. Counters encode gravity: Rods (j) = #{ inputs ≥ j }.
   --  4. Reconstruct ascending: for H = n downto 1, A(idx) = count of
   --     rods with Rods (J) ≥ H (top rows → small values).
   --  5. Final gap-1 bubble finish proves Is_Sorted (Pigeonhole L4 pattern).
   --  Empty and singleton arrays are no-ops. All-zero arrays skip rods.
   --  Related to counting sort: Rods (j) is the ≥-j cumulative count.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A) and then Values_Ok (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending educational bead sort + gap-1 bubble finish.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Bead_Sort;
