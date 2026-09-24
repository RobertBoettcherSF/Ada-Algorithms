--  Bead_Sort — Ada 2023 educational package for bead sort (gravity sort)
--  on nonnegative Natural arrays with bounded length and value.
--  Hardware / physical models can approach O(n); this software simulation
--  is O(n · M) time and O(M) auxiliary space (M = max value).
--  Reference: https://en.wikipedia.org/wiki/Bead_sort

pragma Ada_2022;

package Bead_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   Max_N : constant Positive := 1_024;

   --  Maximum element value accepted by Sort (rods 1 .. Max_Value).
   --  Software bead sort needs Θ(M) rod counters and Θ(n·M) drop work in
   --  the worst case; keep M modest so demos stay interactive.
   Max_Value : constant Natural := 1_024;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Nonnegative integers (including 0 = zero beads). Wikipedia's original
   --  presentation targets positive integers; allowing 0 is natural for a
   --  rod model and matches common software simulations.
   type Element_Array is array (Natural range <>) of Natural;

   Invalid_Argument : exception;
   --  Raised when:
   --    * A'Length > Max_N; or
   --    * some A(I) > Max_Value.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (abacus / gravity model)
   ---------------------------------------------------------------------------
   --  1. Find M = max(A). Allocate rod counters Rod(1 .. M) := 0.
   --  2. For each a_i, drop one bead on each of rods 1 .. a_i
   --     (increment Rod(1), …, Rod(a_i)). Zero values drop nothing.
   --  3. Those counters already encode gravity: Rod(j) is the settled
   --     height of beads on rod j (how many input values are ≥ j).
   --  4. Reconstruct ascending order: for height H = n downto 1, the
   --     value at that row is the number of rods with Rod(j) ≥ H
   --     (top rows have few beads → small values; bottom → large).
   --
   --  Related to counting sort: Rod(j) equals the count of elements with
   --  value ≥ j. Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending bead sort (gravity simulation via rod counts).
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N or any value
   --  exceeds Max_Value.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Bead_Sort;
