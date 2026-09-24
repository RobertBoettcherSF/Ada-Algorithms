--  Ternary_Search — Ada/SPARK Level 4 educational package for ternary
--  search. Primary: find an index of a maximum in a unimodal discrete
--  Integer array by repeated trisection. Secondary: optional key search
--  in a sorted ascending array (binary search is usually preferable).
--  Overflow-safe thirds-points:
--
--      m1 = Lo + ⌊(Hi − Lo) / 3⌋
--      m2 = Hi − ⌊(Hi − Lo) / 3⌋
--
--  Worst-case O(log n) comparisons (base 3/2 shrinkage) plus O(1) for the
--  final window. Sentinel 0 when a sorted key is absent (indices 1 .. N).
--
--  SPARK port of Ada-Ternary-Search: hard Max_N bound, no exceptions,
--  contracts and Is_Unimodal / Is_Sorted replace Invalid_Argument /
--  unchecked shape. Non-SPARK sibling allows arbitrary A'First and
--  sentinel A'First−1; this port requires A'First = 1 and returns 0 on
--  a Find miss.
--
--  Reference: https://en.wikipedia.org/wiki/Ternary_search

package Ternary_Search
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

   --  Live indices are 1 .. N with N ≤ Max_N. 0 is the absent sentinel
   --  for Find (and unused by Find_Maximum_Index, which always returns
   --  a live index under its Pre).
   subtype Index is Natural range 0 .. Max_N;
   subtype Ext_Index is Natural range 0 .. Max_N + 1;

   type Element_Array is array (Positive range <>) of Integer;

   ---------------------------------------------------------------------------
   -- Shape / unimodality / sortedness guards (expression functions — Pre)
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

   function Is_Unimodal (A : Element_Array) return Boolean is
     (A'Length = 0
      or else
      (for some P in A'Range =>
         (for all I in A'First .. P =>
            (for all J in A'First .. P =>
               (if I < J then A (I) <= A (J))))
         and then
         (for all I in P .. A'Last =>
            (for all J in P .. A'Last =>
               (if I < J then A (I) >= A (J))))))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff there exists a peak index P such that A is nondecreasing
   --  on A'First .. P and nonincreasing on P .. A'Last (plateaus OK).
   --  Empty arrays are treated as unimodal (vacuous).

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Wikipedia ternary search — discrete unimodal peak)
   ---------------------------------------------------------------------------
   --  Assume Is_Unimodal (A), In_Bounds (A), and A'Length ≥ 1.
   --  While Hi − Lo > Threshold (= 2), set
   --    m1 ← Lo + ⌊(Hi − Lo)/3⌋
   --    m2 ← Hi − ⌊(Hi − Lo)/3⌋
   --  then:
   --    if A(m1) < A(m2), raise Lo ← m1 + 1 (peak cannot be ≤ m1);
   --    if A(m1) > A(m2), lower Hi ← m2 − 1 (peak cannot be ≥ m2);
   --    else shrink to [m1, m2] (equal / plateau).
   --  Finish with a linear scan of the tiny window; any plateau index OK.
   --  Sorted Find: trisect a nondecreasing array looking for Key; miss → 0.

   ---------------------------------------------------------------------------
   -- Primary API — unimodal maximum
   ---------------------------------------------------------------------------

   function Find_Maximum_Index (A : Element_Array) return Index
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 1
         and then Is_Unimodal (A),
       Post   =>
         Find_Maximum_Index'Result in A'Range;
   --  Return an index of a maximum element of unimodal A (any index in a
   --  flat peak plateau is acceptable). Full “Result is a global max”
   --  completeness is exercised by tests rather than claimed as a Level-4
   --  post without extra ghost lemmas.

   ---------------------------------------------------------------------------
   -- Secondary API — sorted key search (usually prefer binary search)
   ---------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Index
     with
       Global => null,
       Pre    => In_Bounds (A) and then Is_Sorted (A),
       Post   =>
         Find'Result <= A'Last
         and then (if Find'Result > 0 then A (Find'Result) = Key);
   --  Ternary search for Key in a nondecreasing array. Returns any index
   --  I in 1 .. A'Last with A(I) = Key, or 0 if Key is absent (or A empty).
   --  Prefer binary search in production code; this form is pedagogical.

end Ternary_Search;
