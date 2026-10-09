--  Odd_Even_Sort — Ada/SPARK Level 4 educational package for sequential
--  odd–even transposition sort (brick sort / parity sort) on an Integer
--  array. Alternating odd/even adjacent compare-swaps (Wikipedia 0-based
--  odd-then-even order). Related to bubble sort; designed for parallel
--  neighbour processors. Sequential O(n²), O(1) extra space; stable when
--  the swap predicate is strict `>`. Not Batcher's odd–even mergesort.
--
--  SPARK port of Ada-Odd-Even-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling raises on oversized n and loops until a clean cycle; this
--  port takes any A'First in 1 .. Max_N (phases follow the offset from
--  A'First, so a shifted array is swapped exactly like a 1-based one), uses
--  Pre => In_Bounds (A), keeps the sibling's loop until a clean cycle,
--  and proves that this loop sorts and terminates (no cap, no fallback
--  pass). The Post proves sortedness and that A
--  holds the values of A'Old, each equally often (Is_Perm, counted with
--  Occ).
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
   -- Algorithm sketch (Wikipedia sequential listing, 0-based odd then even)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Repeat cycles until one makes no swap:
   --    Each cycle:
   --      Odd phase:  compare/swap A'First-relative positions (2,3),
   --                  (4,5), … (= Wikipedia 0-based offsets 1,3,5, …)
   --      Even phase: compare/swap positions (1,2), (3,4), …
   --                  (= Wikipedia 0-based offsets 0,2,4, …)
   --    Position P is index A'First + P - 1.
   --    Stop when a full cycle performs no swaps.
   --  Proof: a swap-free cycle has seen every neighbour pair in order, so
   --  Is_Sorted holds on exit. Termination: the ghost Weight (A) = sum of
   --  (K - A'First + 1) * A (K) rises by A (I) - A (I + 1) >= 1 with every swap and is
   --  bounded, so it is the loop variant of the cycle loop.
   --  Swap only when A(I) > A(I+1) (strict `>`; never `>=`)
   --  so equal keys keep relative order (stable).
   --  Empty and singleton arrays are no-ops.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Permutation (multiset) model, used by the Post of Sort
   ---------------------------------------------------------------------------

   function Occ (A : Element_Array; V : Integer; Last : Natural) return Natural
   with
     Global             => null,
     Pre                => In_Bounds (A) and then Last <= A'Last,
     Post               => Occ'Result <= Last,
     Subprogram_Variant => (Decreases => Last);
   --  How many of A (A'First .. Last) equal V.

   function Occ (A : Element_Array; V : Integer; Last : Natural) return Natural is
     (if Last < A'First then 0
      else Occ (A, V, Last - 1) + (if A (Last) = V then 1 else 0));

   function Is_Perm (A, B : Element_Array) return Boolean is
     (A'First = B'First
      and then A'Last = B'Last
      and then (for all I in A'Range =>
                  Occ (A, A (I), A'Last) = Occ (B, A (I), B'Last))
      and then (for all I in B'Range =>
                  Occ (A, B (I), A'Last) = Occ (B, B (I), B'Last)))
   with
     Global => null,
     Pre    => In_Bounds (A) and then In_Bounds (B);
   --  A and B have the same bounds and hold the same values, each equally
   --  often. A value found in neither array counts 0 in both, so comparing
   --  the counts of the values of A and of B covers every value.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A) and then Is_Perm (A, A'Old);
   --  Ascending in-place odd–even (brick) sort (no finishing pass).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness and that A holds the values of A'Old, each
   --  equally often (Is_Perm).

end Odd_Even_Sort;
