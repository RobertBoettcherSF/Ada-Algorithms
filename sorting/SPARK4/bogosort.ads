--  Bogosort — Ada/SPARK Level 4 educational package for the generate-and-test
--  "stupid sort" / permutation sort. Deterministic next-permutation
--  enumeration (not random shuffle). Extremely inefficient; Max_N is tiny
--  by design (factorial growth).
--
--  SPARK port of Ada-Bogosort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling uses Max_N = 10, allows arbitrary A'First, and raises on
--  oversized n; this port requires A'First = 1, uses Max_N = 8, bounds
--  the next-permutation loop by Max_N! + 1, and proves sortedness via a
--  final gap-1 bubble finish (same proof role as Comb_Sort / Odd_Even /
--  Shell / Strand / Patience / Stooge). Full multiset / permutation
--  equality is verified by tests rather than claimed as a Level-4
--  postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Bogosort

package Bogosort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; factorial work — keep Max_N tiny)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 10) so n! stays feasible in tests and Level-4 VCs.
   --  8! = 40_320; tests should keep reverse cases ≤ 7.
   Max_N : constant Positive := 8;

   --  Upper bound on next-permutation steps: Max_N! + 1.
   --  Any multiset has ≤ n! distinct permutations; +1 allows the
   --  Is_Sorted exit after a full wrap.
   Max_Perm_Steps : constant Positive := 40_321;

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
   -- Algorithm sketch (next-permutation generate-and-test + bubble finish)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A).
   --  While not Is_Sorted (A), advance A to the next lexicographic
   --  multiset permutation (wrap last → first). Bound the loop by
   --  Max_Perm_Steps (= Max_N! + 1) so termination proves under Level 4.
   --  Prefer exit when already Is_Sorted (no wasted next step).
   --  After the bogo phase, a final gap-1 bubble finish (shrinking unsorted
   --  suffix + early exit) establishes Is_Sorted — same proof role as
   --  Comb_Sort's Bubble_Finish / Strand / Patience / Stooge. Next-
   --  permutation posts that would fight Level 4 are intentionally limited
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
   --  Ascending deterministic bogosort (next-permutation) + gap-1 bubble
   --  finish. Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Bogosort;
