--  Slowsort — Ada/SPARK Level 4 educational package for the humorous
--  "multiply and surrender" sorting algorithm (pessimal / reluctant).
--  Recurrence T(n) = 2 T(n/2) + T(n-1) + Θ(1) is not polynomial;
--  Max_N is tiny by design.
--
--  SPARK port of Ada-Slowsort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling has Max_N = 24 and raises on oversized n; this port takes any
--  A'First in 1 .. Max_N, uses Max_N = 16, Pre => In_Bounds
--  (A), and bounds recursive Slowsort_Range with Subprogram_Variant =>
--  (Decreases => J - I). Slowsort_Range is proved to sort its range on
--  its own (pairwise order plus "no element above the range's entry
--  maximum", which carries the surrender step); there is no fallback
--  pass. The Post of Sort also proves permutation (Is_Perm, counted
--  with Occ): Slowsort_Range keeps the multiset of the whole array.
--
--  Reference: https://en.wikipedia.org/wiki/Slowsort

package Slowsort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity bound (classroom; superpolynomial — keep Max_N tiny)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_N = 24) so demos stay interactive and Level 4 VCs stay within
   --  automated SMT reach. Prefer n << Max_N in tests.
   Max_N : constant Positive := 16;

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
   -- Algorithm sketch (multiply and surrender / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Recurse on I .. J (initially A'First .. A'Last):
   --    1. If I >= J, return.
   --    2. M := I + (J - I) / 2          -- floor((I+J)/2), overflow-safe
   --    3. Slowsort_Range (A, I, M)      -- multiply: left half
   --    4. Slowsort_Range (A, M+1, J)    -- multiply: right half
   --    5. If A(M) > A(J), swap          -- larger half-maximum at J
   --    6. Slowsort_Range (A, I, J-1)    -- surrender: rest
   --  Subprogram_Variant (J - I) strictly decreases on each recursive
   --  call. Empty and singleton arrays are no-ops.
   --  Level 4: Slowsort_Range proves RTE, termination, frame, pairwise
   --  sortedness of A (I .. J), the entry-maximum bound and the multiset
   --  (Same_Occ); Sort's Is_Sorted and Is_Perm follow directly.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A) and then Is_Perm (A, A'Old);
   --  Ascending Slowsort (in-place multiply-and-surrender); the
   --  recursion alone establishes Is_Sorted (proved at Level 4).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness and that A holds the values of A'Old, each
   --  equally often (Is_Perm).

end Slowsort;
