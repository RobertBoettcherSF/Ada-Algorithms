--  Stooge_Sort — Ada 2023 educational package for the deliberately
--  inefficient recursive sorting algorithm named after The Three Stooges.
--  Pessimal but still faster than Slowsort; keep Max_N tiny.
--  Reference: https://en.wikipedia.org/wiki/Stooge_sort

pragma Ada_2022;

package Stooge_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   --  Stooge sort's recurrence T(n) = 3 T(2n/3) + Θ(1) yields
   --  Θ(n^(log 3 / log 1.5)) ≈ Θ(n^2.709). Even moderate n is slow;
   --  keep Max_N tiny so demos and tests stay interactive.
   Max_N : constant Positive := 24;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (The Three Stooges)
   ---------------------------------------------------------------------------
   --  To sort A[i .. j] in place:
   --    1. If A[i] > A[j], swap them.
   --    2. If the length L := j - i + 1 is greater than 2:
   --         t := floor(L / 3)
   --         Stooge-sort A[i .. j-t]     -- first 2/3 (ceil rounding via t)
   --         Stooge-sort A[i+t .. j]     -- last  2/3
   --         Stooge-sort A[i .. j-t]     -- first 2/3 again
   --
   --  Using t = floor(L/3) makes the recursive span L - t = ceil(2L/3),
   --  which is required for correctness (e.g. L=5 must recurse on 4).
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending Stooge sort (in-place recursive 2/3–2/3–2/3).
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Stooge_Sort;
