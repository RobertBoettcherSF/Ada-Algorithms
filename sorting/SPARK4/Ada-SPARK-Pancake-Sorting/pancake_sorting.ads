--  Pancake_Sorting — Ada/SPARK Level 4 educational package for sorting by
--  prefix reversals ("pancake flips"). A spatula may be inserted at any
--  point in a stack and used to reverse every pancake above it. The classic
--  selection-style algorithm brings the largest unsorted pancake to the top,
--  then flips it into place, using at most 2n − 3 flips.
--
--  SPARK port of Ada-Pancake-Sorting: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling allows arbitrary A'First, Max_Length = 10_000, and raises on
--  oversize / bad K; this port requires A'First = 1 and uses
--  Pre => In_Bounds (A). Full multiset / permutation equality is verified
--  by tests rather than claimed as a Level-4 postcondition (sortedness is
--  proved). Flip_Sequence uses fixed static storage (1 .. Max_Flips).
--
--  Reference: https://en.wikipedia.org/wiki/Pancake_sorting

package Pancake_Sorting
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_Length = 10_000) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   --  Static flip-buffer capacity. Classic algorithm uses ≤ 2n − 3 flips;
   --  2·Max_N is a simple static upper bound that covers Max_N = 64.
   Max_Flips : constant Positive := 2 * Max_N;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices are 1 .. N with N ≤ Max_N. Empty arrays use Last = 0.
   subtype Index is Natural range 0 .. Max_N;

   type Element_Array is array (Positive range <>) of Integer;

   --  Fixed flip buffer: only Flips (1 .. Count) is meaningful.
   type Flip_Sequence is array (1 .. Max_Flips) of Natural;

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

   function Classic_Flip_Bound (N : Natural) return Natural is
     (if N <= 1 then 0 else 2 * N - 3)
   with
     Global => null,
     Pre    => N <= Max_N;
   --  Upper bound of the classic algorithm: 0 when N ≤ 1, otherwise
   --  2N − 3. This is an upper bound on the pancake number P(N)
   --  for N ≥ 2, not the (generally smaller) exact P(N).

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic pancake sort / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Grow a sorted suffix from right to left.
   --  For each Size from A'Last down to 2:
   --    1. Find Max_At := rightmost argmax of A (1 .. Size).
   --    2. If Max_At = Size, the maximum is already placed — skip.
   --    3. Otherwise, if Max_At ≠ 1, Flip the prefix of length Max_At
   --       so the maximum moves to the front.
   --    4. Flip the prefix of length Size so the maximum lands at Size.
   --  After the step for Size, A (Size .. A'Last) is sorted and every
   --  element of A (1 .. Size − 1) is ≤ every element of that suffix.
   --  Empty / singleton are no-ops. At most 2n − 3 flips for n ≥ 2.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Prefix reversal
   ---------------------------------------------------------------------------

   procedure Flip (A : in out Element_Array; K : Natural)
     with
       Global => null,
       Pre    => In_Bounds (A) and then K <= A'Last,
       Post   =>
         In_Bounds (A)
         and then (for all I in 1 .. K => A (I) = A'Old (K - I + 1))
         and then (for all I in K + 1 .. A'Last => A (I) = A'Old (I));
   --  Reverse the prefix A (1 .. K). K = 0 or 1 is a no-op.
   --  Requires K ≤ A'Last (contract replaces Invalid_Argument).

   procedure Apply_Flips
     (A     : in out Element_Array;
      Flips : Flip_Sequence;
      Count : Natural)
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then Count <= Max_Flips
         and then (for all I in 1 .. Count => Flips (I) <= A'Last),
       Post   => In_Bounds (A);
   --  Apply Flips (1 .. Count) in order. Count = 0 is a no-op.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending classic pancake sort (prefix reversals, ≤ 2n − 3 flips).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

   procedure Sort
     (A     : in out Element_Array;
      Flips : out Flip_Sequence;
      Count : out Natural)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   =>
         In_Bounds (A)
         and then Is_Sorted (A)
         and then Count <= Classic_Flip_Bound (A'Length)
         and then Count <= Max_Flips
         and then (for all I in 1 .. Count => Flips (I) in 2 .. A'Last);
   --  Same as Sort, recording prefix lengths into Flips (1 .. Count).
   --  Remaining Flips slots are set to 0. Count ≤ Classic_Flip_Bound (N).

end Pancake_Sorting;
