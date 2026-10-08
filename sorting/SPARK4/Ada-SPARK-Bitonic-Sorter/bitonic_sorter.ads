--  Bitonic_Sorter — Ada/SPARK Level 4 educational package for Batcher's
--  bitonic mergesort sorting network on an Integer array. Sequentially
--  simulates recursive Bitonic_Sort / Bitonic_Merge with a direction flag
--  (Wikipedia). Comparator count O(n (log n)²), parallel depth
--  O((log n)²). Classic construction assumes n = 2^k; this port pads a
--  static Work buffer (1 .. Max_N) to the next power of two with
--  Integer'Last sentinels, runs the network, copies the live prefix back,
--  then finishes with a gap-1 bubble so Is_Sorted proves at Level 4.
--
--  SPARK port of Ada-Bitonic-Sorter: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling uses Max_Length = 10_000, allows arbitrary A'First / 0-based
--  work buffers, raises on oversize, and exposes Compare_Swap /
--  Next_Power_Of_Two publicly. This port requires A'First = 1, uses a
--  fixed Work buffer of size Max_N, keeps Compare_Swap / power helpers
--  private, and proves sortedness via Bubble_Finish (same proof role as
--  Comb / Odd_Even / Strand / Stooge). Full multiset / permutation
--  equality is verified by tests rather than claimed as a Level-4
--  postcondition (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Bitonic_sorter

package Bitonic_Sorter
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Must be a power of two so padded work
   --  length stays ≤ Max_N. Smaller than the non-SPARK sibling
   --  (Max_Length = 10_000) so Level 4 can discharge array / arithmetic VCs.
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
   -- Algorithm sketch (Batcher / Wikipedia bitonic sorter)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). If n ≤ 1, return. Else:
   --    Copy A into static Work (1 .. Max_N); pad Work(n+1 .. P) with
   --    Integer'Last where P = next power of two ≥ n (P ≤ Max_N).
   --    Bitonic_Sort(Work, Low=1, Count=P, Ascending=True):
   --      if Count > 1: K := Count/2;
   --        Bitonic_Sort(Low, K, Ascending);
   --        Bitonic_Sort(Low+K, K, Descending);
   --        Bitonic_Merge(Low, Count, dir).
   --    Bitonic_Merge: pairwise Compare_Swap(i, i+K) then recurse halves.
   --    Copy Work(1 .. n) back into A.
   --  Network posts that would fight Level 4 are limited to In_Bounds /
   --  RTE / Subprogram_Variant; a final gap-1 Bubble_Finish establishes
   --  Is_Sorted (same proof role as Comb / Odd_Even / Strand / Stooge).
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
   --  Ascending bitonic mergesort network (static Work + sentinel pad)
   --  followed by a gap-1 bubble finish.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Bitonic_Sorter;
