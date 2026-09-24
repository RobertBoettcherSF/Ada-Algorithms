--  Binary_Search — Ada/SPARK Level 4 educational package for classic
--  iterative binary search (half-interval / logarithmic search / binary
--  chop) on a sorted ascending Integer array, plus leftmost / rightmost
--  variants for duplicate keys. Overflow-safe midpoint:
--
--      mid = lo + (hi − lo) / 2
--
--  Worst-case O(log n) comparisons. Sentinel 0 when the key is absent
--  (indices are always 1 .. N).
--
--  SPARK port of Ada-Binary-Search: hard Max_N bound, no exceptions,
--  contracts and Is_Sorted replace Invalid_Argument / unchecked sortedness.
--  Non-SPARK sibling allows arbitrary A'First and sentinel A'First−1;
--  this port requires A'First = 1 and returns 0 on a miss.
--
--  Reference: https://en.wikipedia.org/wiki/Binary_search_algorithm

package Binary_Search
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

   --  Live indices are 1 .. N with N ≤ Max_N. 0 is the absent sentinel.
   subtype Index is Natural range 0 .. Max_N;
   subtype Ext_Index is Natural range 0 .. Max_N + 1;
   --  Ext_Index covers the half-open upper bound Last + 1 used by
   --  Find_First / Find_Last.

   type Element_Array is array (Positive range <>) of Integer;

   ---------------------------------------------------------------------------
   -- Sortedness / shape guards (expression functions — usable in Pre)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'First = 1 and then A'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard used by every entry point. Empty arrays have
   --  A'Last = 0 when A'First = 1 (rejects Last < 0).

   function Is_Sorted (A : Element_Array) return Boolean is
     (for all I in A'Range =>
        (for all J in A'Range =>
           (if I < J then A (I) <= A (J))))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is sorted nondecreasing on A'Range.
   --  Empty arrays are sorted (universal quantifier over empty range).

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Wikipedia classic iterative procedure)
   ---------------------------------------------------------------------------
   --  Assume Is_Sorted (A) and In_Bounds (A).
   --  Find: L ← 1, R ← A'Last; while L ≤ R, take
   --    m ← L + ⌊(R − L)/2⌋ (overflow-safe; never (L+R)/2),
   --    then branch on A(m) ? Key and shrink [L,R]. Return any matching
   --    index, or 0 if the interval empties.
   --  Find_First / Find_Last: half-open bound searches that return the
   --    leftmost / rightmost equal key (or 0 if absent).
   --  Empty arrays (A'Length = 0) return 0 immediately.

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Index
     with
       Global => null,
       Pre    => In_Bounds (A) and then Is_Sorted (A),
       Post   =>
         Find'Result <= A'Last
         and then (if Find'Result > 0 then A (Find'Result) = Key);
   --  Classic iterative binary search. Returns any index I in 1 .. A'Last
   --  with A(I) = Key, or 0 if Key is absent.

   function Find_First (A : Element_Array; Key : Integer) return Index
     with
       Global => null,
       Pre    => In_Bounds (A) and then Is_Sorted (A),
       Post   =>
         Find_First'Result <= A'Last
         and then (if Find_First'Result > 0 then
                     A (Find_First'Result) = Key
                     and then (for all K in 1 .. Find_First'Result - 1 =>
                                 A (K) < Key));
   --  Leftmost index of Key (lower-bound style). Same sentinel / bounds
   --  as Find.

   function Find_Last (A : Element_Array; Key : Integer) return Index
     with
       Global => null,
       Pre    => In_Bounds (A) and then Is_Sorted (A),
       Post   =>
         Find_Last'Result <= A'Last
         and then (if Find_Last'Result > 0 then
                     A (Find_Last'Result) = Key
                     and then (for all K in Find_Last'Result + 1 .. A'Last =>
                                 A (K) > Key));
   --  Rightmost index of Key (upper-bound − 1 style). Same sentinel /
   --  bounds as Find.

end Binary_Search;
