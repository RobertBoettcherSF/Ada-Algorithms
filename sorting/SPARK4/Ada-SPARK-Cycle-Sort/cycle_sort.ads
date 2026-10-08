--  Cycle_Sort — Ada/SPARK Level 4 educational package for classic
--  write-optimal in-place cycle sort on an Integer array. Factors the
--  permutation into cycles and rotates each so every element is written
--  at most once to its final position. Typical Θ(n²) comparisons, O(1)
--  extra space; not stable under duplicate skipping.
--
--  SPARK port of Ada-Cycle-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling allows arbitrary A'First and raises on oversized n; this port
--  requires A'First = 1 and uses Pre => In_Bounds (A). Full multiset /
--  permutation equality is verified by tests rather than claimed as a
--  Level-4 postcondition (sortedness is proved). Write counting is an
--  optional out-parameter with light contracts.
--
--  Reference: https://en.wikipedia.org/wiki/Cycle_sort

package Cycle_Sort
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
   -- Algorithm sketch (classic cycle sort / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). For each Cycle_Start from 1 through A'Last-1:
   --    1. Hold Item := A(Cycle_Start).
   --    2. Count how many elements in Cycle_Start+1 .. A'Last are strictly
   --       smaller than Item; that count plus Cycle_Start is destination Pos.
   --    3. If Pos = Cycle_Start, the item is already placed — skip.
   --    4. Otherwise skip past equal duplicates at Pos, write Item there,
   --       and take the displaced value as the new Item (one write).
   --    5. Repeat destination-finding and writes until Pos returns to
   --       Cycle_Start, completing the cycle.
   --  After cycle starts 1 .. n-1, the last element is already in place.
   --  Empty and singleton arrays are no-ops. Unstable when duplicates
   --  force skipping past equal keys. Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending classic in-place cycle sort (write-optimal).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

   procedure Sort_Counting_Writes
     (A      : in out Element_Array;
      Writes : out Natural)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Same as Sort, also returning the number of writes performed to A.
   --  Each misplaced element is written once to its final slot; already-
   --  correct elements contribute zero writes. Light contracts: sortedness
   --  is proved; the exact write tally is checked by tests.

end Cycle_Sort;
