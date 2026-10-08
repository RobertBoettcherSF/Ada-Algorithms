--  Comb_Sort — Ada/SPARK Level 4 educational package for classic comb
--  sort (Dobosiewicz / Lacey–Box) on an Integer array. Bubble sort with
--  a shrinking gap (≈ /1.3 via gap := gap * 10 / 13). Large early gaps
--  move distant out-of-order keys ("turtles"); the final gap-1 phase is
--  ordinary bubble sort. Unstable. O(1) extra space.
--
--  SPARK port of Ada-Comb-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling raises on oversized n; both run the classic
--  until-gap-1-and-clean-pass loop. This port takes any A'First in
--  1 .. Max_N (the first gap is A'Length; passes run from A'First),
--  uses Pre => In_Bounds (A), proves termination with the
--  loop variant (Gap, Bound) and sortedness from the gap-1 passes inside
--  the same loop. Full multiset /
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

   --  Live indices lie in 1 .. Max_N (any A'First); Index includes 0 so
   --  an empty array may have Last = First - 1 = 0.
   subtype Index is Natural range 0 .. Max_N;

   --  Live slots; the index subtype carries the 1 .. Max_N origin range,
   --  In_Bounds adds the length.
   subtype Live_Index is Positive range 1 .. Max_N;

   type Element_Array is array (Live_Index range <>) of Integer;

   ---------------------------------------------------------------------------
   -- Shape / sortedness guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'Length <= Max_N
      and then A'First in 1 .. Max_N
      and then A'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard used by every entry point: at most Max_N elements, any
   --  origin with First in 1 .. Max_N (empty arrays use Last = First - 1).

   function Is_Sorted (A : Element_Array) return Boolean is
     (A'Length <= 1
      or else (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1)))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic comb sort)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Gap starts at n and shrinks by ≈ 1.3:
   --      gap := max(1, floor(gap * 10 / 13))
   --  For each gap > 1, one comb pass compares/swaps A(i) with A(i+gap).
   --  Once the gap is 1, gap-1 passes repeat in the same loop until one
   --  makes no swap (each stops one element earlier, since a gap-1 pass
   --  leaves the maximum at the end); they establish Is_Sorted.
   --  Termination: loop variant (Gap, Bound), no iteration cap.
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
   --  Ascending classic in-place comb sort (shrink ≈ 1.3, then gap-1 passes until no swap).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Comb_Sort;
