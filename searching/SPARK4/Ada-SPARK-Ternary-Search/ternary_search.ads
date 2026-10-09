--  Ternary_Search — Ada/SPARK Level 4 educational package for ternary
--  search. Primary: find an index of a maximum in a unimodal discrete
--  Integer array by repeated trisection. Secondary: optional key search
--  in a sorted ascending array (binary search is usually preferable).
--  Overflow-safe thirds-points:
--
--      m1 = Lo + ⌊(Hi − Lo) / 3⌋
--      m2 = Hi − ⌊(Hi − Lo) / 3⌋
--
--  O(log n) probes (base 3/2 shrinkage) on strictly unimodal input plus O(1) for the
--  final window. Sentinel 0 when a sorted key is absent (0 is never a
--  live index; A may start at any origin in 1 .. Max_N).
--
--  SPARK port of Ada-Ternary-Search: hard Max_N bound, no exceptions,
--  contracts and Is_Unimodal / Is_Sorted replace Invalid_Argument /
--  unchecked shape. Like the non-SPARK sibling it accepts any A'First
--  (within Live_Index); Find returns 0 on a miss instead of A'First−1.
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

   --  Live indices are A'First .. A'Last within 1 .. Max_N. 0 is the absent sentinel
   --  for Find (and unused by Find_Maximum_Index, which always returns
   --  a live index under its Pre).
   subtype Index is Natural range 0 .. Max_N;
   subtype Ext_Index is Natural range 0 .. Max_N + 1;

   subtype Live_Index is Positive range 1 .. Max_N;
   --  Element_Array may start at any origin inside 1 .. Max_N.

   type Element_Array is array (Live_Index range <>) of Integer;

   ---------------------------------------------------------------------------
   -- Shape / unimodality / sortedness guards (expression functions — Pre)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'Length <= Max_N)
   with Global => null;
   --  Shape guard used by every entry point: at most Max_N elements,
   --  any origin (Live_Index already keeps non-empty bounds in
   --  1 .. Max_N).

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
   --    else (equal) read A(m1+1) and A(m2-1): if A rises after m1,
   --    Lo ← m1 + 1; if A falls before m2, Hi ← m2 − 1 (a strictly
   --    unimodal array does both, so it stays O(log n)); if neither, the
   --    window is a true plateau and the final linear scan covers the
   --    whole [Lo, Hi] window (O(n), unavoidable on plateau inputs).
   --  Finish with a linear scan of the tiny window; any plateau index OK.
   --  Sorted Find: trisect a nondecreasing array looking for Key; miss → 0.

   ---------------------------------------------------------------------------
   -- Primary API — unimodal maximum
   ---------------------------------------------------------------------------

   --  Probes counts the elements of A that the search reads (each read
   --  site counts once). It is the cost the named algorithm is about:
   --  tests pin it exactly per branch, so a linear scan cannot pass.
   type Max_Result is record
      Index_Of_Max : Index;
      Probes       : Natural;
   end record;

   function Find_Maximum_Counted (A : Element_Array) return Max_Result
     with
       Global => null,
       Pre    =>
         In_Bounds (A)
         and then A'Length >= 1
         and then Is_Unimodal (A),
       Post   =>
         Find_Maximum_Counted'Result.Index_Of_Max in A'Range;

   function Find_Maximum_Index (A : Element_Array) return Index is
     (Find_Maximum_Counted (A).Index_Of_Max)
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
         (if Find'Result > 0 then
            Find'Result in A'Range
            and then A (Find'Result) = Key);
   --  Ternary search for Key in a nondecreasing array. Returns any index
   --  I in A'Range with A(I) = Key, or 0 if Key is absent (or A empty).
   --  Prefer binary search in production code; this form is pedagogical.

end Ternary_Search;
