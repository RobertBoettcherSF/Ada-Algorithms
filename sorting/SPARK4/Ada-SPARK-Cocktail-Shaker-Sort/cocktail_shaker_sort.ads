--  Cocktail_Shaker_Sort — Ada/SPARK Level 4 educational package for
--  cocktail shaker sort (bidirectional bubble / cocktail / shaker sort)
--  on an Integer array. Alternating forward (max to Hi) and backward
--  (min to Lo) adjacent-swap passes shrink a Lo..Hi window; early exit
--  on a clean (swap-free) pass. Best near O(n), average/worst O(n²),
--  O(1) extra space; stable when the swap predicate is strict `>`.
--
--  SPARK port of Ada-Cocktail-Shaker-Sort: hard Max_N bound, no
--  exceptions, In_Bounds / Is_Sorted contracts replace Invalid_Argument.
--  Non-SPARK sibling allows arbitrary A'First, raises on oversized n,
--  and loops until the window collapses; this port requires A'First = 1,
--  uses Pre => In_Bounds (A), and proves sortedness of the shaker passes
--  themselves (window invariant; Hi - Lo is the loop variant). Full multiset /
--  permutation equality is verified by tests rather than claimed as a
--  Level-4 postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Cocktail_shaker_sort

package Cocktail_Shaker_Sort
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
   -- Algorithm sketch (classic cocktail / bidirectional bubble / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Maintain an active window [Lo .. Hi]
   --  (initially 1 .. A'Last). While Lo < Hi:
   --      Forward pass:  for I in Lo .. Hi-1, swap if A(I) > A(I+1);
   --                     then Hi := Hi - 1  (largest key bubbled to Hi).
   --      Backward pass: for I in reverse Lo+1 .. Hi, swap if A(I-1) > A(I);
   --                     then Lo := Lo + 1  (smallest key bubbled to Lo).
   --    Stop early when a pass performs no swaps (the window is sorted).
   --  Proof: A(1 .. Lo-1) stays sorted and <= the rest, A(Hi+1 .. A'Last)
   --  stays sorted and >= the rest; Hi - Lo decreases every round. This
   --  proves Is_Sorted directly (no extra bubble sort at the end).
   --  Swap only when A(I) > A(I+1) (strict `>`; never `>=`) so equal
   --  keys keep relative order (stable).
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
   --  Ascending in-place cocktail shaker (bidirectional bubble) sort.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Cocktail_Shaker_Sort;
