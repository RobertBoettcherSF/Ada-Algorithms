--  Ternary_Search — Ada 2023 educational package for ternary search.
--  Primary: find the index of the maximum in a unimodal discrete array by
--  repeatedly trisecting the index range. Secondary: optional key search in
--  a sorted ascending array (binary search is usually preferable).
--  Reference: https://en.wikipedia.org/wiki/Ternary_search

pragma Ada_2022;

package Ternary_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Find_Maximum_Index and Find.
   Max_N : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when:
   --    * Find_Maximum_Index is called on an empty array; or
   --    * A'Length > Max_N for Find_Maximum_Index or Find.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (unimodal peak)
   ---------------------------------------------------------------------------
   --  Assume A is unimodal: there exists a peak index P such that A is
   --  (non-)strictly increasing on A'First .. P and (non-)strictly
   --  decreasing on P .. A'Last. While Hi - Lo > Threshold, set
   --    m1 = Lo + (Hi - Lo) / 3
   --    m2 = Hi - (Hi - Lo) / 3
   --  compare A(m1) and A(m2), and shrink toward the side that can still
   --  contain the maximum. Finish with a linear scan of the tiny window.
   --
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Primary API — unimodal maximum
   ---------------------------------------------------------------------------

   function Find_Maximum_Index (A : Element_Array) return Natural;
   --  Return an index of a maximum element of unimodal A (any index in a
   --  flat peak plateau is acceptable).
   --  Raises Invalid_Argument when A is empty or A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Secondary API — sorted key search (usually prefer binary search)
   ---------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Integer;
   --  Ternary search for Key in a nondecreasing (sorted ascending) array.
   --  Returns an index I in A'Range with A(I) = Key, or the sentinel
   --  A'First - 1 when Key is absent (or when A is empty).
   --  Raises Invalid_Argument when A'Length > Max_N.
   --  Note: binary search uses one midpoint and is typically preferred;
   --  this form is included for pedagogical comparison.

end Ternary_Search;
