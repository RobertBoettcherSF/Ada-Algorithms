--  Linear_Search — Ada/SPARK Level 4 educational package for classic
--  sequential (linear) search on an unordered Integer array: scan
--  left-to-right until the first matching key, or report absence.
--  Worst-case O(n) comparisons; best case O(1) when the key is at
--  A'First. No sortedness precondition. Sentinel 0 when the key is
--  absent: 0 is outside every A'Range (indices are Live_Index >= 1),
--  so A may start at any origin.
--
--  SPARK port of Ada-Linear-Search: hard Max_N bound, no exceptions,
--  In_Bounds contracts replace Invalid_Argument. Like the non-SPARK
--  sibling it accepts any A'First (within Live_Index); it returns 0 on
--  a miss instead of A'First−1. Unlike Ada-SPARK-Binary-Search,
--  there is no Is_Sorted Pre — the input may be unordered.
--
--  Reference: https://en.wikipedia.org/wiki/Linear_search

package Linear_Search
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / loop variants in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 100_000) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices are A'First .. A'Last within 1 .. Max_N. 0 is the
   --  absent sentinel (never a live index).
   subtype Index is Natural range 0 .. Max_N;
   subtype Live_Index is Positive range 1 .. Max_N;

   type Element_Array is array (Live_Index range <>) of Integer;

   ---------------------------------------------------------------------------
   -- Shape guard (expression function — usable in Pre)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'Length <= Max_N)
   with Global => null;
   --  Shape guard used by every entry point: at most Max_N elements,
   --  any origin (Live_Index already keeps non-empty bounds in
   --  1 .. Max_N).

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Wikipedia basic iterative procedure)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). No sortedness required.
   --  Find: for I in A'Range, if A(I) = Key return I; else return 0.
   --  Find_From: same scan starting at Start instead of A'First.
   --  Contains: True iff Find (A, Key) > 0.
   --  First occurrence wins when duplicates exist.
   --  Empty arrays (A'Length = 0) return 0 / False immediately.

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Index
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   =>
         (if Find'Result > 0 then
                     Find'Result in A'Range
                     and then A (Find'Result) = Key
                     and then (for all K in A'First .. Find'Result - 1 =>
                                 A (K) /= Key)
                   else
                     (for all K in A'Range => A (K) /= Key));
   --  Classic left-to-right linear search. Returns the smallest index I
   --  in A'Range with A(I) = Key, or 0 if Key is absent.

   function Find_From
     (A     : Element_Array;
      Key   : Integer;
      Start : Index) return Index
   with
     Global => null,
     Pre    =>
       In_Bounds (A)
       and then (A'Length = 0 or else Start in A'Range),
     Post   =>
       (if Find_From'Result > 0 then
                   Find_From'Result in A'Range
                   and then Find_From'Result >= Start
                   and then A (Find_From'Result) = Key
                   and then (for all K in Start .. Find_From'Result - 1 =>
                               A (K) /= Key)
                 else
                   (A'Length = 0
                    or else (for all K in Start .. A'Last =>
                               A (K) /= Key)));
   --  Same as Find, but begins scanning at Start instead of A'First.
   --  Returns the smallest index I in Start .. A'Last with A(I) = Key,
   --  or 0 if none. Useful for finding later occurrences after a prior hit.
   --  Empty arrays return 0 without constraining Start.

   function Contains (A : Element_Array; Key : Integer) return Boolean
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => Contains'Result = (Find (A, Key) > 0);
   --  True iff some element of A equals Key.

end Linear_Search;
