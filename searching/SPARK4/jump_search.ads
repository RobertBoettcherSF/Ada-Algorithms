--  Jump_Search — Ada/SPARK Level 4 educational package for jump search
--  (also called block search) on a sorted ascending Integer array.
--  Advances by fixed-size jumps of length
--
--      m = ⌊√n⌋
--
--  (or an explicit Step), then finishes with a short linear scan of the
--  candidate block. Worst-case O(√n) comparisons. Sentinel 0 when the key
--  is absent (indices are always 1 .. N).
--
--  SPARK port of Ada-Jump-Search: hard Max_N bound, no exceptions,
--  contracts and Is_Sorted replace Invalid_Argument / unchecked sortedness.
--  Non-SPARK sibling allows arbitrary A'First and sentinel A'First−1;
--  this port requires A'First = 1 and returns 0 on a miss.
--
--  Reference: https://en.wikipedia.org/wiki/Jump_search

package Jump_Search
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
   --  Ext_Index covers exclusive jump cursors up to N + 1.

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
   -- Algorithm sketch (Wikipedia jump / block search)
   ---------------------------------------------------------------------------
   --  Assume Is_Sorted (A) and In_Bounds (A).
   --  Let n = A'Length and m = ⌊√n⌋ (or caller Step).
   --  Jump: prev ← 0, curr ← m; while A(min(curr, n)) < Key, advance
   --    prev ← curr, curr ← curr + m (overflow-safe, capped); if prev ≥ n
   --    the key is absent. Linear: scan indices prev+1 .. min(curr, n)
   --    for Key (early exit when A(i) > Key). Empty arrays return 0.
   --  Optimal m = √n balances the jump and linear phases → O(√n).

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
   --  Jump / block search for Key. Block size m = ⌊√(A'Length)⌋ when
   --  A is non-empty. Returns any index I in 1 .. A'Last with A(I) = Key,
   --  or 0 if Key is absent. Duplicates: any matching index is acceptable.

   function Find
     (A    : Element_Array;
      Key  : Integer;
      Step : Positive) return Index
   with
     Global => null,
     Pre    => In_Bounds (A) and then Is_Sorted (A),
     Post   =>
       Find'Result <= A'Last
       and then (if Find'Result > 0 then A (Find'Result) = Key);
   --  Same contract as Find, but uses Step as the jump / block size
   --  instead of ⌊√n⌋. Step is Positive (zero is not representable) —
   --  the non-SPARK sibling raised Invalid_Argument on Step = 0.

end Jump_Search;
