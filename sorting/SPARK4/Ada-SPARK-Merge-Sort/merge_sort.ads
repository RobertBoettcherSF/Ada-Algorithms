--  Merge_Sort — Ada/SPARK Level 4 educational package for classic
--  stable merge sort (von Neumann, 1945) on an Integer array. Time
--  Θ(n log n), auxiliary Θ(n) temp buffer; stable when the merge
--  prefers the left run on ties (L ≤ R).
--
--  SPARK port of Ada-Merge-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling uses top-down recursion and raises on oversized n; this port
--  takes any A'First in 1 .. Max_N (runs are aligned at A'First), uses a
--  fixed Temp
--  buffer of size Max_N, and implements iterative bottom-up merging so
--  Level 4 can discharge the VCs without deep recursive contracts.
--  The Post of Sort proves sortedness and that the result is a
--  permutation of the input (counts of every value, Is_Perm).
--
--  Reference: https://en.wikipedia.org/wiki/Merge_sort

package Merge_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; keeps indexes / loop VCs in SMT reach)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 100_000) so Level 4 can discharge array / arithmetic VCs.
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
   -- Algorithm sketch (classic bottom-up / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Allocate a fixed Temp : Element_Array
   --  (1 .. Max_N) (it covers every possible A'Range). Start with
   --  Width = 1 (unit runs are sorted). With N = A'Length:
   --  While Width < N:
   --    For each Lo = A'First, A'First+2·Width, … while
   --    Lo ≤ A'Last − Width:
   --      Mid := Lo + Width − 1
   --      Hi  := min (Lo + 2·Width − 1, A'Last)
   --      Stable-merge A(Lo .. Mid) with A(Mid+1 .. Hi) via Temp
   --      (prefer Left when Left ≤ Right so equal keys keep order).
   --    Width := 2 · Width
   --  Empty and singleton arrays are no-ops.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   ---------------------------------------------------------------------------
   -- Permutation (multiset) model, used by the Post of Sort
   ---------------------------------------------------------------------------

   function Occ
     (A : Element_Array; V : Integer; First : Positive; Last : Natural)
      return Natural
   with
     Global             => null,
     Pre                =>
       (if First <= Last then First >= A'First and then Last <= A'Last),
     Post               =>
       Occ'Result <= (if First <= Last then Last - First + 1 else 0),
     Subprogram_Variant => (Decreases => Last);
   --  How many of A (First .. Last) equal V (0 for an empty range).

   function Occ
     (A : Element_Array; V : Integer; First : Positive; Last : Natural)
      return Natural
   is
     (if Last < First then 0
      else Occ (A, V, First, Last - 1) + (if A (Last) = V then 1 else 0));

   function Is_Perm (A, B : Element_Array) return Boolean is
     (A'First = B'First
      and then A'Last = B'Last
      and then (for all I in A'Range =>
                  Occ (A, A (I), A'First, A'Last)
                  = Occ (B, A (I), B'First, B'Last))
      and then (for all I in B'Range =>
                  Occ (A, B (I), A'First, A'Last)
                  = Occ (B, B (I), B'First, B'Last)))
   with
     Global => null,
     Pre    => In_Bounds (A) and then In_Bounds (B);
   --  A and B have the same bounds and hold the same values, each equally
   --  often. A value found in neither array counts 0 in both, so comparing
   --  the counts of the values of A and of B covers every value.

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A) and then Is_Perm (A, A'Old);
   --  Ascending classic stable bottom-up merge sort.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness and that A holds the values of A'Old, each
   --  equally often (Is_Perm).

end Merge_Sort;
