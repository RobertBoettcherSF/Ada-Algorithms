--  Quickselect — Ada/SPARK Level 4 educational package for Hoare's
--  selection algorithm (Tony Hoare): find the k-th smallest element in an
--  unordered Integer array via in-place Quickselect (median-of-three pivot,
--  Lomuto partition, iterative one-sided shrink). Average O(n), worst O(n²);
--  O(1) extra space for Select_Kth.
--
--  SPARK port of Ada-Quickselect: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Kth_Partitioned contracts replace Invalid_Argument.
--  Non-SPARK sibling allows arbitrary A'First, Max_N = 100_000, and raises
--  on oversized / empty / bad K; this port takes any A'First (A'Length <= Max_N), nonempty A
--  for Select_Kth, and uses Pre => In_Bounds (A) and then K <= A'Length.
--  Full multiset / permutation equality is verified by tests rather than
--  claimed as a Level-4 postcondition (the partition / order-statistic
--  property is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Quickselect

package Quickselect
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 100_000) so Level 4 can discharge array / arithmetic VCs.
   --  The outer Select_Kth loop runs at most Max_N - 1 times (Hi - Lo shrinks).
   Max_N : constant Positive := 64;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices are 1 .. N with N ≤ Max_N. Empty arrays use Last = 0
   --  (In_Bounds only); Select_Kth requires nonempty A.
   subtype Index is Natural range 0 .. Max_N;

   type Element_Array is array (Positive range <>) of Integer;

   ---------------------------------------------------------------------------
   -- Shape / order-statistic guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'Length <= Max_N)
   with Global => null;
   --  Shape guard used by every entry point: a length bound, any origin.

   --  Partition / order-statistic property after Select_Kth: with
   --  Target = A'First + K - 1 and T = A(Target), every element left of
   --  Target is ≤ T and every element right of Target is ≥ T.
   --  Weaker than "exactly K-1 elements are strictly smaller", but the
   --  educational Quickselect postcondition and Level-4-provable when the
   --  loop maintains the window partition invariant.
   function Is_Kth_Partitioned (A : Element_Array; K : Positive) return Boolean
   is
     ((for all I in A'Range =>
         (if I < A'First + (K - 1) then A (I) <= A (A'First + (K - 1))))
      and then
      (for all I in A'Range =>
         (if I > A'First + (K - 1) then A (I) >= A (A'First + (K - 1)))))
   with
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then A'Length >= 1
       and then K <= A'Length;

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Quickselect / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A), A'Length >= 1, K in 1 .. A'Length.
   --  Positions are 1 .. A'Length; position P is A (A'First + (P - 1)).
   --  Target := K (a position). Lo := 1; Hi := A'Length.
   --  While Lo < Hi (at most Max_N outer steps):
   --    1. If Hi - Lo >= 2: median-of-three on A(Lo), A(Mid), A(Hi);
   --       park the median at Hi (Lomuto pivot).
   --    2. Lomuto-partition A(Lo .. Hi) around A(Hi); pivot lands at P.
   --       Afterward A(Lo .. P-1) <= A(P) <= A(P+1 .. Hi).
   --    3. If P = Target, stop. If P > Target, Hi := P-1; else Lo := P+1.
   --  When Lo = Hi or P = Target, A(Target) is the K-th smallest and
   --  Is_Kth_Partitioned (A, K) holds. Sides are not fully sorted.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Selection
   ---------------------------------------------------------------------------

   procedure Select_Kth (A : in out Element_Array; K : Positive)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 1
         and then K <= A'Length,
       Post   =>
         In_Bounds (A)
         and then Is_Kth_Partitioned (A, K);
   --  In-place Quickselect: rearranges A so A(A'First + K - 1) holds the
   --  K-th smallest element (1-based order statistic) and the partition
   --  property Is_Kth_Partitioned holds. Multiset / permutation equality
   --  is checked by the test suite (not claimed here at Level 4).

   function Select_Kth_Copy (A : Element_Array; K : Positive) return Integer
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 1
         and then K <= A'Length;
   --  Non-mutating wrapper: copies A, runs Select_Kth on the copy, and
   --  returns the K-th smallest. Original A is unchanged. O(n) temporary.

   function Median (A : Element_Array) return Integer
     with
       Global => null,
       Pre    => In_Bounds (A) and then A'Length >= 1;
   --  Non-mutating median via Select_Kth_Copy. Odd n: rank (n+1)/2.
   --  Even n: lower middle rank n/2. Original A is unchanged.

end Quickselect;
