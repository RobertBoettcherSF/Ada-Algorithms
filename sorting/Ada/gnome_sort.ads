--  Gnome_Sort — Ada 2023 educational package for classic gnome sort
--  (stupid sort): garden-gnome adjacent compare / swap / step.
--  Equivalent to insertion sort but moving elements by swaps.
--  O(n²) average/worst, O(n) best when nearly sorted; O(1) extra space.
--  Reference: https://en.wikipedia.org/wiki/Gnome_sort

pragma Ada_2022;

package Gnome_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   --  Gnome sort is O(n²) in the average/worst case, so callers should
   --  keep n modest in practice (tests use reverse/random n ≤ ~500).
   --  Max_N is an educational upper guard. The sort is in-place (O(1)
   --  auxiliary memory).
   Max_N : constant Positive := 10_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic gnome / stupid sort)
   ---------------------------------------------------------------------------
   --  The garden gnome looks at the pot at Pos and the previous one:
   --    if Pos = A'First or else A(Pos) >= A(Pos-1) then
   --       Pos := Pos + 1;          -- in order (or first pot): step forward
   --    else
   --       swap A(Pos) and A(Pos-1); Pos := Pos - 1;  -- fix and step back
   --    end if;
   --  until Pos > A'Last.
   --
   --  Ascending uses `>=` when deciding to advance so equal keys are not
   --  swapped backward — the sort is stable-ish (equal relative order is
   --  preserved). Using strict `>` when advancing would swap equals and
   --  lose that property. Empty and singleton arrays are no-ops.
   --  Related to insertion sort via adjacent swaps. Do not `with` sibling
   --  Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending in-place classic gnome (stupid) sort.
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Gnome_Sort;
