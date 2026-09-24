--  Heapsort — Ada 2023 educational package for classic in-place heapsort
--  on a binary max-heap (Floyd bottom-up heapify + extract-max).
--  Guarantees O(n log n) comparisons/swaps; in-place; not stable.
--  Reference: https://en.wikipedia.org/wiki/Heapsort

pragma Ada_2022;

package Heapsort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bound (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort / Heapify.
   Max_Length : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_Length.

   ---------------------------------------------------------------------------
   -- Indexing note (0-based vs 1-based vs Ada arbitrary bounds)
   ---------------------------------------------------------------------------
   --  Wikipedia / CLRS often present child formulas for fixed bases:
   --
   --    0-based:  Left(i) = 2*i + 1,   Right(i) = 2*i + 2,
   --              Parent(i) = floor((i - 1) / 2)
   --    1-based:  Left(i) = 2*i,       Right(i) = 2*i + 1,
   --              Parent(i) = floor(i / 2)
   --
   --  Ada unconstrained arrays may start at any A'First. This package
   --  therefore uses *logical* 0-based offsets relative to A'First:
   --
   --    Logical(I)     = I - A'First
   --    Left_Abs(I)    = A'First + 2 * Logical(I) + 1
   --    Right_Abs(I)   = A'First + 2 * Logical(I) + 2
   --    Parent_Abs(I)  = A'First + (Logical(I) - 1) / 2   (I > A'First)
   --
   --  Equivalent to the 0-based formulas with I remapped onto 0 .. n-1.
   --  Never apply 1-based formulas to a 0-based slice (or vice versa).

   ---------------------------------------------------------------------------
   -- Heap primitives
   ---------------------------------------------------------------------------

   procedure Sift_Down
     (A         : in out Element_Array;
      Root      : Natural;
      Heap_Last : Natural);
   --  Repair the max-heap property at Root within the inclusive heap
   --  range A (A'First .. Heap_Last), assuming both child subheaps (if
   --  present) already satisfy the property. Swaps Root downward until
   --  it is >= both children or becomes a leaf.
   --  Pre: A'First <= Root <= Heap_Last <= A'Last (when A'Length > 0).

   procedure Heapify (A : in out Element_Array);
   --  Floyd bottom-up build: sift down every non-leaf from the parent of
   --  A'Last down to A'First, producing a binary max-heap in place.
   --  O(n). Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_Length.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Classic in-place ascending heapsort:
   --    1. Heapify (A)  — build max-heap (largest at A'First);
   --    2. For Heap_Last from A'Last downto A'First + 1:
   --         swap A (A'First) with A (Heap_Last);
   --         Sift_Down (A, A'First, Heap_Last - 1).
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_Length.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Heapsort;
