--  Slowsort — Ada 2023 educational package for the humorous "multiply and
--  surrender" sorting algorithm (pessimal / reluctant). Extremely slow;
--  Max_N is tiny by design.
--  Reference: https://en.wikipedia.org/wiki/Slowsort

pragma Ada_2022;

package Slowsort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   --  Slowsort's recurrence T(n) = 2 T(n/2) + T(n-1) + Θ(1) is not
   --  polynomial; even n ≈ 20 can take noticeable wall time. Keep Max_N
   --  tiny so demos and tests stay interactive.
   Max_N : constant Positive := 24;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (multiply and surrender)
   ---------------------------------------------------------------------------
   --  To sort A[i .. j] in place:
   --    1. If i >= j, return (already trivial).
   --    2. m := (i + j) / 2
   --    3. Slowsort A[i .. m]          -- multiply: recurse on left half
   --    4. Slowsort A[m+1 .. j]        -- multiply: recurse on right half
   --    5. If A[m] > A[j], swap them   -- put the larger of the two maxima
   --                                   -- at position j
   --    6. Slowsort A[i .. j-1]        -- surrender: recurse on the rest
   --
   --  Named "multiply and surrender" as a parody of divide-and-conquer:
   --  work is duplicated on both halves, then almost all of it is thrown
   --  away by re-sorting the prefix. Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending Slowsort (in-place multiply-and-surrender).
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Slowsort;
