--  Heapsort — Ada/SPARK Level 4 educational package for classic
--  in-place heapsort on a binary max-heap (Floyd bottom-up heapify +
--  extract-max). Guarantees O(n log n) comparisons/swaps; in-place;
--  not stable.
--
--  SPARK port of Ada-Heapsort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling uses First-relative (logical 0-based) child math, allows
--  arbitrary A'First, and raises on oversized n; this port requires
--  A'First = 1 so Parent = I/2, Left = 2*I, Right = 2*I+1, and uses
--  Pre => In_Bounds (A). Full multiset / permutation equality is
--  verified by tests rather than claimed as a Level-4 postcondition
--  (sortedness is proved).
--
--  Reference: https://en.wikipedia.org/wiki/Heapsort

package Heapsort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / heap VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_Length = 100_000) so Level 4 can discharge array / arithmetic VCs.
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
   -- Algorithm sketch (classic binary max-heap heapsort / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Indices are 1-based:
   --    Parent(I) = I/2,  Left(I) = 2*I,  Right(I) = 2*I+1.
   --  1. Heapify: sift down every non-leaf from N/2 down to 1 (Floyd).
   --  2. Extract-max: for Heap_Last from N downto 2:
   --       swap A(1) with A(Heap_Last); sift down A(1) in 1 .. Heap_Last-1.
   --  Empty and singleton arrays are no-ops.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Heap primitives
   ---------------------------------------------------------------------------

   procedure Sift_Down
     (A         : in out Element_Array;
      Root      : Index;
      Heap_Last : Index)
   with
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then Heap_Last in 1 .. A'Last
       and then Root in 1 .. Heap_Last,
     Post   =>
       In_Bounds (A)
       and then
         (for all K in Heap_Last + 1 .. A'Last => A (K) = A'Old (K));
   --  Repair the max-heap property at Root within A (1 .. Heap_Last),
   --  assuming both child subheaps (if present) already satisfy it.
   --  Swaps Root downward until it is >= both children or becomes a leaf.
   --  Frame: suffix past Heap_Last is unchanged. Full heap restoration
   --  is maintained inside Sort / Heapify via ghost helpers (body).

   procedure Heapify (A : in out Element_Array)
   with
     Global => null,
     Pre    => In_Bounds (A),
     Post   => In_Bounds (A);
   --  Floyd bottom-up build: sift down every non-leaf from A'Last/2
   --  down to 1, producing a binary max-heap in place. O(n).
   --  Empty and singleton arrays are no-ops.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
   with
     Global => null,
     Pre    => In_Bounds (A),
     Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Classic in-place ascending heapsort (Heapify + extract-max).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Heapsort;
