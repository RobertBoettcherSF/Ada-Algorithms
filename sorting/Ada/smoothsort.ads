--  Smoothsort — Ada 2023 educational package for Dijkstra's smoothsort
--  (1981), an adaptive in-place variant of heapsort built on Leonardo
--  heaps ("stretches"). Best case O(n) on already-sorted input; worst
--  case O(n log n). Not a stable sort.
--  Reference: https://en.wikipedia.org/wiki/Smoothsort

pragma Ada_2022;

package Smoothsort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bound (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   Max_Length : constant Positive := 100_000;

   --  Highest Leonardo order accepted by Leonardo (L(K) fits in Natural).
   Max_Leonardo_Order : constant Natural := 40;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_Length, or when Leonardo is asked for
   --  an order above Max_Leonardo_Order.

   ---------------------------------------------------------------------------
   -- Leonardo numbers  L(0) = L(1) = 1,  L(k) = L(k-1) + L(k-2) + 1
   ---------------------------------------------------------------------------

   function Leonardo (K : Natural) return Natural;
   --  Return the K-th Leonardo number.
   --  Raises Invalid_Argument when K > Max_Leonardo_Order.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  In-place ascending Smoothsort using Dijkstra's Leonardo-heap
   --  construction (grow stretches with sift/trinkle, then shrink with
   --  semitrinkle). Empty and singleton arrays are no-ops.
   --  Adaptive: already-sorted input is processed in essentially linear
   --  time; arbitrary input is O(n log n).
   --  Raises Invalid_Argument when A'Length > Max_Length.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Smoothsort;
