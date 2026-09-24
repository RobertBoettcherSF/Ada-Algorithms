--  Merge_Sort — Ada/SPARK Level 4 educational package for classic
--  stable merge sort (von Neumann, 1945) on an Integer array. Time
--  Θ(n log n), auxiliary Θ(n) temp buffer; stable when the merge
--  prefers the left run on ties (L ≤ R).
--
--  SPARK port of Ada-Merge-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling uses top-down recursion, allows arbitrary A'First, and raises
--  on oversized n; this port requires A'First = 1, uses a fixed Temp
--  buffer of size Max_N, and implements iterative bottom-up merging so
--  Level 4 can discharge the VCs without deep recursive contracts.
--  Full multiset / permutation equality is verified by tests rather
--  than claimed as a Level-4 postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Merge_sort

package Merge_Sort
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
   -- Algorithm sketch (classic bottom-up / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Allocate a fixed Temp : Element_Array
   --  (1 .. Max_N). Start with Width = 1 (unit runs are sorted).
   --  While Width < N:
   --    For each Lo = 1, 1+2·Width, … while Lo ≤ N − Width:
   --      Mid := Lo + Width − 1
   --      Hi  := min (Lo + 2·Width − 1, N)
   --      Stable-merge A(Lo .. Mid) with A(Mid+1 .. Hi) via Temp
   --      (prefer Left when Left ≤ Right so equal keys keep order).
   --    Width := 2 · Width
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
   --  Ascending classic stable bottom-up merge sort.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Merge_Sort;
