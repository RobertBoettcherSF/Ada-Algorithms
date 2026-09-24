--  Fibonacci_Search — Ada 2023 educational package for the Fibonacci search
--  technique on a sorted ascending Integer array. Splits the search interval
--  into unequal parts sized by consecutive Fibonacci numbers, using only
--  addition and subtraction (no division) to choose the next probe.
--  Division-free alternative to binary search; O(log n) comparisons.
--  Reference: https://en.wikipedia.org/wiki/Fibonacci_search_technique

pragma Ada_2022;

package Fibonacci_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Find.
   Max_N : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Sorted ascending (nondecreasing) integer sequence. Indices are
   --  Natural; the array may start at any Natural bound (0- or 1-based).
   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Wikipedia / Lourakis formulation)
   ---------------------------------------------------------------------------
   --  Precondition: A is sorted in nondecreasing (ascending) order.
   --  Let n = A'Length. Find the smallest Fibonacci number F_m >= n, and
   --  keep the triple (fibM, fibMm1, fibMm2) = (F_m, F_{m-1}, F_{m-2}).
   --  Maintain an eliminated-front offset (initially −1 in 0-based space).
   --  While fibM > 1:
   --    probe i = min(offset + fibMm2, n − 1);
   --    if A(i) < Key, discard the left part including i and reduce the
   --      triple by one Fibonacci step (fibM ← fibMm1, …), offset ← i;
   --    if A(i) > Key, discard the right part from i and reduce by two
   --      steps (fibM ← fibMm2, …);
   --    if A(i) = Key, return i.
   --  Finally compare the single remaining candidate when fibMm1 ≠ 0.
   --  Miss / empty → sentinel A'First − 1.
   --
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Integer;
   --  Fibonacci search for Key in sorted ascending A.
   --  Returns an index I in A'Range with A(I) = Key, or the sentinel
   --  A'First - 1 when Key is absent (or when A is empty).
   --  When duplicates exist, any matching index is acceptable (not
   --  necessarily the leftmost or rightmost).
   --  Raises Invalid_Argument when A'Length > Max_N.

end Fibonacci_Search;
