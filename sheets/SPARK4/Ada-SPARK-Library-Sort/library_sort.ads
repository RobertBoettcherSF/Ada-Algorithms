--  Library_Sort — Ada/SPARK Level 4 educational package for library sort
--  (gapped insertion sort, Bender–Farach-Colton–Mosteiro) on an Integer
--  array. Maintains a static working buffer of capacity (1+ε)·n with
--  ε = 1 ⇒ Cap = 2·n; binary-search insert + local shift into gaps;
--  rebalance/spread on doubling rounds and congestion; pack dense result
--  back into A. Average O(n log n) w.h.p. for suitable ε; auxiliary
--  Θ((1+ε)n) space (Wikipedia library sort).
--
--  SPARK port of Ada-Library-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling uses Max_N = 8192, allows arbitrary A'First, and raises on
--  oversized n; this port requires A'First = 1, uses a fixed Working
--  buffer of size Max_Cap = 2·Max_N, and proves sortedness via a final
--  gap-1 bubble finish (same proof role as Strand / Bitonic / Comb /
--  Odd_Even). Full multiset / permutation equality is verified by tests
--  rather than claimed as a Level-4 postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Library_sort

package Library_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 8_192) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   --  Gap factor ε = 1 ⇒ Cap(n) = (1+ε)·n = 2·n. Static Working buffer
   --  is sized for the largest Cap: Max_Cap = 2·Max_N = 128.
   Max_Cap : constant Positive := 2 * Max_N;

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
   -- Algorithm sketch (Wikipedia library sort / gapped insertion)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Cap := 2·n (ε = 1). Allocate static Working
   --  W(1 .. Max_Cap) of empty gaps; use only W(1 .. Cap).
   --  Place A(1); then for each remaining x:
   --    On doubling rounds (after 1, 2, 4, … insertions), rebalance:
   --      gather occupied values and spread them evenly across Cap.
   --    Binary-search W for an insertion index (gap at Mid → scan right
   --      then left for a nearest occupied neighbour).
   --    Insert x into a gap, or shift until a gap; on congestion,
   --      rebalance and retry (fallback: gather + append + spread).
   --  Pack occupied slots of W left-to-right back into A.
   --  Library phase posts only In_Bounds / RTE; a final gap-1
   --  Bubble_Finish establishes Is_Sorted (same proof role as Strand /
   --  Bitonic / Comb / Odd_Even). Empty and singleton arrays are no-ops.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending library sort (ε = 1, Cap = 2·n) + gap-1 bubble finish.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Library_Sort;
