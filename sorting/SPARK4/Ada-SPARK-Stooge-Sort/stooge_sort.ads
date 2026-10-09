--  Stooge_Sort — Ada/SPARK Level 4 educational package for the deliberately
--  inefficient recursive sorting algorithm named after The Three Stooges.
--  Recurrence T(n) = 3 T(⌈2n/3⌉) + Θ(1) yields
--  Θ(n^(log 3 / log 1.5)) ≈ Θ(n^2.709). Pessimal but still faster than
--  Slowsort; keep Max_N tiny.
--
--  SPARK port of Ada-Stooge-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling raises on oversized n; this port takes any A'First in
--  1 .. Max_N, uses Pre => In_Bounds (A), and bounds recursive
--  Stooge_Range with Subprogram_Variant => (Decreases => Hi - Lo). The
--  recursion itself is proved: Stooge_Range's postcondition says the
--  slice Lo .. Hi is sorted and holds the same values with the same
--  counts (a ghost counting argument: after the second call the last
--  third holds the largest values, after the third call the first two
--  thirds are sorted below them). Sort is only that recursion; there is
--  no fallback pass. Sort's public Post states sortedness and
--  permutation (Is_Perm, counted with Occ).
--
--  Reference: https://en.wikipedia.org/wiki/Stooge_sort

package Stooge_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; recursion is expensive — keep Max_N tiny)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Same as the non-SPARK sibling (Max_N = 24)
   --  so demos stay interactive; Level 4 VCs stay within automated SMT reach.
   Max_N : constant Positive := 24;

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
   -- Algorithm sketch (The Three Stooges / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Recurse on Lo .. Hi (initially A'First .. A'Last):
   --    1. If A(Lo) > A(Hi), swap them.
   --    2. If L := Hi - Lo + 1 > 2:
   --         T := floor(L / 3)
   --         Stooge-sort A(Lo .. Hi-T)     -- first ⌈2L/3⌉
   --         Stooge-sort A(Lo+T .. Hi)     -- last  ⌈2L/3⌉
   --         Stooge-sort A(Lo .. Hi-T)     -- first ⌈2L/3⌉ again
   --  Using T = floor(L/3) makes the recursive span L - T = ceil(2L/3),
   --  which is required for correctness (e.g. L=5 must recurse on 4).
   --  Subprogram_Variant (Hi - Lo) strictly decreases on each recursive
   --  call. Empty and singleton arrays are no-ops.
   --  Level 4: Stooge_Range proves RTE / termination / frame, that the
   --  slice is sorted, and that element counts are preserved.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A) and then Is_Perm (A, A'Old);
   --  Ascending Stooge sort (in-place recursive 2/3–2/3–2/3); the
   --  recursion alone discharges Is_Sorted at Level 4.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness and that A holds the values of A'Old, each
   --  equally often (Is_Perm).

end Stooge_Sort;
