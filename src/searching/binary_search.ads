--  Binary_Search — Ada 2023 educational package for classic iterative
--  binary search (half-interval / logarithmic search / binary chop) on a
--  sorted ascending Integer array, plus leftmost / rightmost variants for
--  duplicate keys. Overflow-safe midpoint: mid = lo + (hi − lo) / 2.
--  Worst-case O(log n) comparisons. Sentinel A'First − 1 when absent.
--  Reference: https://en.wikipedia.org/wiki/Binary_search_algorithm
--  Do not `with` Uniform_Binary_Search / Fibonacci_Search siblings.

pragma Ada_2022;

package Binary_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Find / Find_First / Find_Last.
   --  Binary search is O(log n); this guard is pedagogical, not a
   --  hardware limit. Tests stay well below Max_N except the deliberate
   --  Invalid_Argument case.
   Max_N : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Wikipedia classic iterative procedure)
   ---------------------------------------------------------------------------
   --  Assume A is sorted ascending: A(A'First) ≤ … ≤ A(A'Last).
   --  Find: set L ← A'First, R ← A'Last; while L ≤ R, take
   --    m ← L + ⌊(R − L)/2⌋ (overflow-safe; avoid (L+R)/2),
   --    then branch on A(m) ? Key and shrink [L,R]. Return any matching
   --    index, or the sentinel A'First − 1 if the interval empties.
   --  Find_First / Find_Last: half-open bound searches that return the
   --    leftmost / rightmost equal key (or the same sentinel if absent).
   --  Empty arrays return the sentinel immediately.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Integer
     with Global => null;
   --  Classic iterative binary search. Returns any index I in A'Range
   --  with A(I) = Key, or the sentinel A'First − 1 if Key is absent.
   --  Raises Invalid_Argument when A'Length > Max_N.
   --  Precondition (unchecked): A is sorted nondecreasing.

   function Find_First (A : Element_Array; Key : Integer) return Integer
     with Global => null;
   --  Leftmost index of Key (lower-bound style). Same sentinel / bounds
   --  rules as Find. Precondition (unchecked): A sorted nondecreasing.

   function Find_Last (A : Element_Array; Key : Integer) return Integer
     with Global => null;
   --  Rightmost index of Key (upper-bound − 1 style). Same sentinel /
   --  bounds rules as Find. Precondition (unchecked): A sorted
   --  nondecreasing.

end Binary_Search;
