--  Interpolation_Search — Ada/SPARK Level 4 educational package for
--  interpolation search (also called predictive search) on a sorted
--  ascending Integer array. Estimates the next probe by linear
--  interpolation between the current bounds — the telephone-directory
--  analogy: open near where the name "should" be given the first and
--  last entries still in play. Overflow-safe probe:
--
--      pos = Lo + ⌊(Key − A(Lo)) · (Hi − Lo) / (A(Hi) − A(Lo))⌋
--
--  Average O(log log n) probes on uniformly distributed keys; worst
--  case O(n) (e.g. exponentially growing keys) — the search loop is
--  therefore bounded by Max_N iterations. Sentinel 0 when the key is
--  absent (indices are always 1 .. N).
--
--  SPARK port of Ada-Interpolation-Search: hard Max_N bound, no
--  exceptions, contracts and Is_Sorted replace Invalid_Argument /
--  unchecked sortedness. Non-SPARK sibling allows arbitrary A'First and
--  sentinel A'First−1; this port requires A'First = 1 and returns 0 on
--  a miss.
--
--  Reference: https://en.wikipedia.org/wiki/Interpolation_search

package Interpolation_Search
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
   --  Ext_Index covers Lo / Hi cursors that may briefly become Hi + 1
   --  after a failed probe (then the loop exits).

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
   -- Algorithm sketch (Wikipedia interpolation / predictive search)
   ---------------------------------------------------------------------------
   --  Assume Is_Sorted (A) and In_Bounds (A).
   --  Lo ← 1, Hi ← A'Last; while Lo ≤ Hi and Key ∈ [A(Lo), A(Hi)]:
   --    if A(Hi) = A(Lo), the remaining window is an equal-value run
   --      (hit Lo or miss);
   --    else estimate
   --      Pos ← Lo + ⌊(Key − A(Lo)) · (Hi − Lo) / (A(Hi) − A(Lo))⌋
   --    with Long_Long_Integer intermediates for the multiply, clamp to
   --    [Lo, Hi], compare A(Pos) with Key and shrink Lo or Hi.
   --  Empty arrays return 0. Worst-case O(n) ⇒ loop bound Max_N.
   --  Sheet / synonym alias: "Predictive search".

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
   --  Interpolation (predictive) search for Key. Returns any index I in
   --  1 .. A'Last with A(I) = Key, or 0 if Key is absent (or A empty).
   --  Duplicates: any matching index is acceptable.

end Interpolation_Search;
