--  Cycle_Sort — Ada 2023 educational package for classic cycle sort
--  on Integer arrays with a bounded length.
--  In-place, unstable comparison sort that is theoretically optimal in
--  the number of writes to the original array (each element written at
--  most once to its final position). Typical Θ(n²) comparisons.
--  Reference: https://en.wikipedia.org/wiki/Cycle_sort

pragma Ada_2022;

package Cycle_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort / Sort_Counting_Writes.
   --  Cycle sort is Θ(n²) comparisons in the typical case, so callers
   --  should keep n modest in practice; Max_N is an educational upper
   --  guard. The sort is in-place (O(1) auxiliary memory).
   Max_N : constant Positive := 10_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic cycle sort / Wikipedia)
   ---------------------------------------------------------------------------
   --  Factor the permutation into cycles and rotate each cycle so every
   --  element is written to its final position at most once:
   --    1. For each cycle start index Cycle_Start from A'First through
   --       A'Last - 1, hold Item := A(Cycle_Start).
   --    2. Count how many elements in Cycle_Start+1 .. A'Last are strictly
   --       smaller than Item; that count plus Cycle_Start is the destination
   --       index Pos. (Do not double-count the cycle-start slot.)
   --    3. If Pos = Cycle_Start, the item is already placed — skip.
   --    4. Otherwise skip past equal already-placed duplicates at Pos
   --       (while Item = A(Pos) loop Pos := Pos + 1), write Item there,
   --       and take the displaced value as the new Item (one write).
   --    5. Repeat destination-finding and writes until Pos returns to
   --       Cycle_Start, completing the cycle.
   --  Empty and singleton arrays are no-ops. Unstable when duplicates
   --  force skipping past equal keys. Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending classic in-place cycle sort (write-optimal).
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Sort_Counting_Writes (A : in out Element_Array) return Natural;
   --  Same as Sort, but returns the number of writes performed to A.
   --  Each misplaced element is written exactly once to its final slot;
   --  already-correct elements contribute zero writes.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Cycle_Sort;
