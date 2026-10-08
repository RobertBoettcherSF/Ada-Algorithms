--  Odd_Even_Sort — Ada/SPARK Level 4 educational package for sequential
--  odd–even transposition sort (brick sort / parity sort) on an Integer
--  array. Alternating odd/even adjacent compare-swaps (Wikipedia 0-based
--  odd-then-even order). Related to bubble sort; designed for parallel
--  neighbour processors. Sequential O(n²), O(1) extra space; stable when
--  the swap predicate is strict `>`. Not Batcher's odd–even mergesort.
--
--  SPARK port of Ada-Odd-Even-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling allows arbitrary A'First, raises on oversized n, and loops
--  until a clean cycle; this port requires A'First = 1, uses
--  Pre => In_Bounds (A), caps outer odd–even phases for termination, and
--  proves sortedness via a final gap-1 bubble finish (same proof role as
--  Comb_Sort / Shell_Sort). Full multiset / permutation equality is
--  verified by tests rather than claimed as a Level-4 postcondition
--  (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Odd%E2%80%93even_sort

package Odd_Even_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 10_000) so Level 4 can discharge array / arithmetic VCs.
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
   -- Algorithm sketch (Wikipedia sequential listing, 0-based odd then even)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Cap outer cycles at Max_N (n ≤ Max_N suffices
   --  in theory; the cap discharges termination under Level 4):
   --    Each cycle:
   --      Odd phase:  compare/swap 1-based indices (2,3), (4,5), …
   --                  (= Wikipedia 0-based offsets 1,3,5, …)
   --      Even phase: compare/swap 1-based indices (1,2), (3,4), …
   --                  (= Wikipedia 0-based offsets 0,2,4, …)
   --    Stop early when a full cycle performs no swaps.
   --  After the capped odd–even phase, a final gap-1 bubble finish
   --  (shrinking unsorted suffix + early exit) establishes Is_Sorted —
   --  same proof role as Comb_Sort's Bubble_Finish / Shell's gap-1
   --  insertion. Swap only when A(I) > A(I+1) (strict `>`; never `>=`)
   --  so equal keys keep relative order (stable).
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
   --  Ascending in-place odd–even (brick) sort + gap-1 bubble finish.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Odd_Even_Sort;
