--  Interpolation_Search — Ada 2023 educational package for interpolation
--  search (also called predictive search) on a sorted ascending Integer
--  array. Estimates the next probe by linear interpolation between the
--  current bounds — the telephone-directory analogy: open near where the
--  name "should" be given the first and last entries still in play.
--  Average O(log log n) probes on uniformly distributed keys; worst case
--  O(n) (e.g. exponentially growing keys).
--  Reference: https://en.wikipedia.org/wiki/Interpolation_search

pragma Ada_2022;

package Interpolation_Search
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
   -- Algorithm sketch
   ---------------------------------------------------------------------------
   --  Precondition: A is sorted in nondecreasing (ascending) order.
   --  While Lo <= Hi and Key is in A(Lo) .. A(Hi):
   --    if A(Hi) = A(Lo), handle the equal-run (hit Lo or miss);
   --    else estimate
   --      Pos := Lo + (Key - A(Lo)) * (Hi - Lo) / (A(Hi) - A(Lo))
   --    using a wider integer type for the multiply to avoid overflow;
   --    compare A(Pos) with Key and shrink Lo or Hi.
   --  Telephone-directory analogy: guess the page from how far the sought
   --  name sits between the first and last names still under the thumbs.
   --
   --  Sheet / synonym alias: "Predictive search".
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Integer;
   --  Interpolation (predictive) search for Key in sorted ascending A.
   --  Returns an index I in A'Range with A(I) = Key, or the sentinel
   --  A'First - 1 when Key is absent (or when A is empty).
   --  When duplicates exist, any matching index is acceptable (not
   --  necessarily the leftmost or rightmost).
   --  Raises Invalid_Argument when A'Length > Max_N.

end Interpolation_Search;
