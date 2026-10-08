--  Smoothsort — Ada/SPARK Level 4 educational package for Dijkstra's
--  smoothsort ideas: Leonardo heaps ("stretches") on an Integer array.
--  Adaptive in spirit (forest of Leonardo max-heaps); classroom extract
--  uses root-max selection + re-heapify rather than full trinkle /
--  semitrinkle (see README). Unstable; in-place aside from O(log n)
--  stretch metadata on the stack.
--
--  SPARK port of Ada-Smoothsort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling uses First-relative offsets, Max_Length = 100_000, bit-string
--  P / Up / Down / Trinkle / Semitrinkle, and raises on oversized n;
--  this port takes any A'First in 1 .. Max_N (stretch roots and child
--  roots are First-relative: the stretch rooted at R of order k starts
--  at R - L(k) + 1 >= A'First), Max_N = 64, a precomputed Leonardo
--  table, and Pre => In_Bounds (A). Full multiset / permutation equality
--  is verified by tests rather than claimed as a Level-4 postcondition
--  (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Smoothsort

package Smoothsort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / heap VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_Length = 100_000) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   --  Highest Leonardo order needed for Max_N (L(8) = 67 >= 64).
   --  Sibling exposes Max_Leonardo_Order = 40 for the large-n table.
   Max_Leonardo_Order : constant Natural := 8;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices lie in 1 .. Max_N (any A'First); Index includes 0 so
   --  an empty array may have Last = First - 1 = 0.
   subtype Index is Natural range 0 .. Max_N;

   subtype Leonardo_Order is Natural range 0 .. Max_Leonardo_Order;

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
   -- Leonardo numbers  L(0) = L(1) = 1,  L(k) = L(k-1) + L(k-2) + 1
   ---------------------------------------------------------------------------

   function Leonardo (K : Leonardo_Order) return Positive
   with
     Global => null,
     Post   => Leonardo'Result <= Max_N + 3;
   --  Return the K-th Leonardo number from the precomputed classroom table.
   --  L(8) = 67; all values fit comfortably for Max_N = 64.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classroom Leonardo-forest heapsort)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Indices are First-relative.
   --  1. Partition A'First .. A'Last into greedy Leonardo stretches; Dijkstra/
   --     Keith-layout sift on each ([Lt_{k-1}][Lt_{k-2}][root]).
   --  2. Extract-max loop: linear prefix-max scan (Level-4 stand-in for
   --     max-among-roots), swap with A(Last), shrink; proves Is_Sorted.
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
   --  Ascending in-place classroom Leonardo-forest heapsort.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Smoothsort;
