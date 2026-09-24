--  Bitonic_Sorter — Ada 2023 educational package for Batcher's bitonic
--  mergesort sorting network. Sequentially simulates the classic
--  recursive BitonicSort / BitonicMerge construction with a direction
--  flag. Input length need not be a power of two: Sort pads to the next
--  power of two with ascending sentinels (Integer'Last), runs the
--  network, then trims back to the original length (friendlier for
--  tests than rejecting non-power-of-two sizes).
--  Reference: https://en.wikipedia.org/wiki/Bitonic_sorter

pragma Ada_2022;

package Bitonic_Sorter
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bound (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort / Compare_Swap.
   --  Padded working length is at most the next power of two ≤ 2^14
   --  when Max_Length = 10_000 (next power of two of 10_000 is 16_384).
   Max_Length : constant Positive := 10_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_Length, or when Compare_Swap indices
   --  fall outside A'Range.

   ---------------------------------------------------------------------------
   -- Comparator and sorting
   ---------------------------------------------------------------------------

   procedure Compare_Swap
     (A         : in out Element_Array;
      I, J      : Natural;
      Ascending : Boolean);
   --  One sorting-network wire: if Ascending, ensure A(I) ≤ A(J) by
   --  swapping when A(I) > A(J); if not Ascending, ensure A(I) ≥ A(J)
   --  by swapping when A(I) < A(J). Raises Invalid_Argument when I or J
   --  is outside A'Range, or when A'Length > Max_Length.

   procedure Sort (A : in out Element_Array);
   --  Ascending bitonic mergesort network simulation.
   --  Empty and singleton arrays are no-ops.
   --  When A'Length is not a power of two, copies into a work buffer
   --  padded with Integer'Last sentinels up to the next power of two,
   --  runs BitonicSort / BitonicMerge, then writes the first A'Length
   --  sorted values back into A (sentinels discarded).
   --  Raises Invalid_Argument when A'Length > Max_Length.
   --  Comparator count is O(n (log n)²) on the (padded) length n.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

   function Next_Power_Of_Two (N : Natural) return Natural;
   --  Smallest power of two ≥ N. Returns 1 when N = 0.
   --  Exposed for tests and documentation of the padding policy.

   function Is_Power_Of_Two (N : Natural) return Boolean;
   --  True iff N is 1, 2, 4, 8, ... (False for 0).

end Bitonic_Sorter;
