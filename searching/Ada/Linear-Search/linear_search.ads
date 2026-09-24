--  Linear_Search — Ada 2023 educational package for classic sequential
--  (linear) search on an unordered Integer array: scan left-to-right until
--  the first matching key, or report absence. Worst-case O(n) comparisons;
--  best case O(1) when the key is at A'First. No sortedness precondition.
--  Reference: https://en.wikipedia.org/wiki/Linear_search
--  Sibling sheets (README only — do not `with`): Binary_Search, Jump_Search.

pragma Ada_2022;

package Linear_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Find / Find_From / Contains.
   --  Linear search is O(n); this guard is pedagogical, not a hardware
   --  limit. Tests stay well below Max_N except the deliberate
   --  Invalid_Argument case.
   Max_N : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Unordered integer sequence. Indices are Natural; the array may
   --  start at any Natural bound (0- or 1-based).
   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N, or when Find_From is called with
   --  Start outside A'Range on a non-empty array.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Wikipedia basic iterative procedure)
   ---------------------------------------------------------------------------
   --  Given list A of n elements and target Key:
   --    for I in A'Range (or Start .. A'Last for Find_From):
   --       if A(I) = Key then return I;
   --    return sentinel A'First − 1  (absent / empty).
   --  First occurrence wins when duplicates exist.
   --  No sortedness required — unlike Binary_Search / Jump_Search.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Integer
     with Global => null;
   --  Classic left-to-right linear search. Returns the smallest index I
   --  in A'Range with A(I) = Key, or the sentinel A'First − 1 if Key is
   --  absent (including when A is empty).
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Find_From
     (A     : Element_Array;
      Key   : Integer;
      Start : Natural) return Integer
     with Global => null;
   --  Same as Find, but begins scanning at Start instead of A'First.
   --  Returns the smallest index I in Start .. A'Last with A(I) = Key,
   --  or the sentinel A'First − 1 if none. Useful for finding later
   --  occurrences after a prior hit.
   --  Raises Invalid_Argument when A'Length > Max_N, or when A is
   --  non-empty and Start not in A'Range.

   function Contains (A : Element_Array; Key : Integer) return Boolean
     with Global => null;
   --  True iff some element of A equals Key. Equivalent to
   --  Find (A, Key) /= A'First − 1, but returns a Boolean.
   --  Raises Invalid_Argument when A'Length > Max_N.

end Linear_Search;
