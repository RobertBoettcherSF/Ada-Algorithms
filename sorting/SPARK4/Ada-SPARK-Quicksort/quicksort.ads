--  Quicksort — Ada/SPARK Level 4 educational package for classic
--  in-place quicksort (Tony Hoare, 1959/1961) on an Integer array.
--  Median-of-three pivot + Lomuto partition. Average O(n log n),
--  worst O(n²); unstable, ascending. Recursion depth ≤ Max_N.
--
--  SPARK port of Ada-Quicksort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling uses Hoare partition and raises on oversized n; this port
--  takes any A'First in 1 .. Max_N, uses Lomuto so the
--  pivot lands in a final slot, and bounds recursive Sort_Range with a
--  Subprogram_Variant so Level 4 can discharge the VCs. The Post of Sort
--  proves both sortedness and permutation (Is_Perm: every value occurs
--  equally often before and after).
--
--  Reference: https://en.wikipedia.org/wiki/Quicksort

package Quicksort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / recursion VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 100_000) so Level 4 can discharge array / arithmetic VCs
   --  and recursion depth stays ≤ Max_N.
   Max_N : constant Positive := 64;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices lie in 1 .. Max_N (any A'First); Index includes 0 so
   --  an empty array may have Last = First - 1 = 0.
   subtype Index is Natural range 0 .. Max_N;

   --  Live slots; the index subtype carries the 1 .. Max_N origin range,
   --  In_Bounds adds the length.
   subtype Live_Index is Positive range 1 .. Max_N;

   type Element_Array is array (Live_Index range <>) of Integer;

   ---------------------------------------------------------------------------
   -- Shape / sortedness guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'Length <= Max_N
      and then A'First in 1 .. Max_N
      and then A'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard used by every entry point: at most Max_N elements, any
   --  origin with First in 1 .. Max_N (empty arrays use Last = First - 1).

   function Is_Sorted (A : Element_Array) return Boolean is
     (A'Length <= 1
      or else (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1)))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (classic in-place quicksort / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Recurse on Lo .. Hi (initially A'First .. A'Last):
   --    If Lo >= Hi, return (empty / singleton are no-ops).
   --    1. Median-of-three on A(Lo), A(Mid), A(Hi); swap the median to Hi.
   --    2. Lomuto-partition around A(Hi): scan Lo .. Hi-1, swap each
   --       A(J) <= pivot toward the front, then swap the pivot into
   --       slot P. Afterward A(Lo .. P-1) <= A(P) <= A(P+1 .. Hi)
   --       (right side actually > A(P) because the scan uses `<=`).
   --    3. Recurse on Lo .. P-1 and P+1 .. Hi (skip empty sides).
   --  The Subprogram_Variant (Hi - Lo) strictly decreases on each
   --  recursive call. Empty and singleton arrays are no-ops.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Permutation (multiset) model, used by the Post of Sort
   ---------------------------------------------------------------------------

   function Occ (A : Element_Array; V : Integer; Last : Natural) return Natural
   with
     Global             => null,
     Pre                => In_Bounds (A) and then Last <= A'Last,
     Post               => Occ'Result <= Last,
     Subprogram_Variant => (Decreases => Last);
   --  How many of A (A'First .. Last) equal V.

   function Occ (A : Element_Array; V : Integer; Last : Natural) return Natural is
     (if Last < A'First then 0
      else Occ (A, V, Last - 1) + (if A (Last) = V then 1 else 0));

   function Is_Perm (A, B : Element_Array) return Boolean is
     (A'First = B'First
      and then A'Last = B'Last
      and then (for all I in A'Range =>
                  Occ (A, A (I), A'Last) = Occ (B, A (I), B'Last))
      and then (for all I in B'Range =>
                  Occ (A, B (I), A'Last) = Occ (B, B (I), B'Last)))
   with
     Global => null,
     Pre    => In_Bounds (A) and then In_Bounds (B);
   --  A and B have the same bounds and hold the same values, each equally
   --  often. A value found in neither array counts 0 in both, so comparing
   --  the counts of the values of A and of B covers every value.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A) and then Is_Perm (A, A'Old);
   --  Ascending classic in-place quicksort (median-of-three + Lomuto).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness and that the result is a permutation of
   --  the input (Is_Perm).

end Quicksort;
