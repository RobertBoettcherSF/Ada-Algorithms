--  Bogosort — Ada 2023 educational package for the generate-and-test
--  "stupid sort" / permutation sort. Extremely inefficient; Max_N is tiny
--  by design (factorial growth).
--  Reference: https://en.wikipedia.org/wiki/Bogosort

pragma Ada_2022;

package Bogosort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   --  Deterministic bogosort may examine up to n! permutations; random
   --  bogosort has expected Θ(n · n!) work. Keep Max_N tiny so demos and
   --  tests stay interactive. Tests should use n ≤ 8.
   Max_N : constant Positive := 10;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (generate and test)
   ---------------------------------------------------------------------------
   --  Classic (randomized) bogosort:
   --    while A is not sorted loop
   --       shuffle A randomly
   --    end loop
   --  Expected comparisons ≈ (e − 1)·n! for distinct keys.
   --
   --  This package implements the *deterministic* educational variant:
   --    while A is not sorted loop
   --       advance A to the next lexicographic permutation (wrapping)
   --    end loop
   --  Using next-permutation enumeration makes Sort reproducible and
   --  terminates in at most n! steps for a fixed multiset. Prefer this
   --  over Fisher–Yates for unit tests. Do not `with` sibling Ada-*
   --  packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending deterministic bogosort (next-permutation generate-and-test).
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Bogosort;
