--  Fibonacci_Search — Ada/SPARK Level 4 educational package for the
--  Fibonacci search technique on a sorted ascending Integer array.
--  Splits the search interval into unequal parts sized by consecutive
--  Fibonacci numbers, choosing the next probe with addition and
--  subtraction only (no division). Division-free alternative to binary
--  search; worst-case O(log n) comparisons. Sentinel 0 when the key is
--  absent (indices are always 1 .. N).
--
--  SPARK port of Ada-Fibonacci-Search: hard Max_N bound, no exceptions,
--  contracts and Is_Sorted replace Invalid_Argument / unchecked sortedness.
--  Non-SPARK sibling allows arbitrary A'First and sentinel A'First−1;
--  this port requires A'First = 1 and returns 0 on a miss.
--
--  Reference: https://en.wikipedia.org/wiki/Fibonacci_search_technique

package Fibonacci_Search
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
   --  Ext_Index covers exclusive front-eliminated offsets up to N.

   --  Fibonacci values for N ≤ Max_N reach at most F_11 = 89 (F_12 = 144).
   subtype Fib_Nat is Natural range 0 .. 144;

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
   -- Algorithm sketch (Wikipedia / Lourakis formulation)
   ---------------------------------------------------------------------------
   --  Assume Is_Sorted (A) and In_Bounds (A).
   --  Let n = A'Length. Find the smallest Fibonacci number F_m ≥ n and
   --  keep the triple (fibM, fibMm1, fibMm2) = (F_m, F_{m−1}, F_{m−2}).
   --  Maintain an eliminated-front offset (initially 0 in 1-based space).
   --  While fibM > 1:
   --    probe i = min(offset + fibMm2, n);
   --    if A(i) < Key, discard the left part including i and reduce the
   --      triple by one Fibonacci step, offset ← i;
   --    if A(i) > Key, discard the right part from i and reduce by two
   --      steps;
   --    if A(i) = Key, return i.
   --  Finally compare the single remaining candidate when fibMm1 ≠ 0.
   --  Miss / empty → sentinel 0. All arithmetic is + / − only.

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
   --  Fibonacci search for Key. Returns any index I in 1 .. A'Last with
   --  A(I) = Key, or 0 if Key is absent. Duplicates: any matching index
   --  is acceptable (not necessarily leftmost / rightmost).

end Fibonacci_Search;
