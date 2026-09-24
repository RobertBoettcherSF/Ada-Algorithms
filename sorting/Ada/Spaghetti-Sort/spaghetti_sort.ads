--  Spaghetti_Sort — Ada 2023 educational software simulation of
--  A. K. Dewdney's analog "spaghetti sort" (Scientific American).
--  Analog idea: cut uncooked spaghetti rods to lengths equal to the
--  keys, stand them upright on a table, then repeatedly lower a hand
--  from above to extract the current longest rod in O(1) parallel
--  time. True spaghetti sort is O(n) with parallel hardware; this
--  package provides two sequential software simulations.
--  Reference: https://en.wikipedia.org/wiki/Spaghetti_sort

pragma Ada_2022;

package Spaghetti_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by any Sort routine.
   Max_Length : constant Positive := 10_000;

   --  Maximum nonnegative key for the primary height-bin (counting)
   --  simulation. Keys must lie in 0 .. Max_Key.
   Max_Key : constant Natural := 10_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_Length, or (for Sort / Sort_Height)
   --  when any element is negative or greater than Max_Key.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Primary educational method: height-bin / counting simulation of
   --  spaghetti rods for nonnegative Integer keys in 0 .. Max_Key.
   --  Places each key into a "height" slot (rod length), then reads
   --  slots from shortest to tallest to produce a stable ascending
   --  order. Software cost is O(n + U) with U = Max_Key + 1, not the
   --  analog O(n). Raises Invalid_Argument on oversize length or
   --  out-of-range keys. Empty and singleton arrays are no-ops.

   procedure Sort_Height (A : in out Element_Array) renames Sort;
   --  Explicit alias for the height-bin primary method.

   procedure Sort_Extraction (A : in out Element_Array);
   --  Comparison-based max-extraction simulation for general Integers
   --  (positive, zero, or negative). Repeatedly finds the current
   --  maximum among remaining elements and appends it to a descending
   --  output, then reverses to ascending order. Mimics Dewdney's
   --  "lower the hand / pull the tallest rod" step without parallel
   --  hardware, so the software cost is O(n²) selection-like.
   --  Ascending; uses rightmost-max on ties so equal Integer keys keep relative order.
   --  Raises Invalid_Argument when A'Length > Max_Length.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Spaghetti_Sort;
