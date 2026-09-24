--  Slowsort — Ada/SPARK Level 4 educational package for the humorous
--  "multiply and surrender" sorting algorithm (pessimal / reluctant).
--  Recurrence T(n) = 2 T(n/2) + T(n-1) + Θ(1) is not polynomial;
--  Max_N is tiny by design.
--
--  SPARK port of Ada-Slowsort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling allows arbitrary A'First, Max_N = 24, and raises on oversized
--  n; this port requires A'First = 1, uses Max_N = 16, Pre => In_Bounds
--  (A), and bounds recursive Slowsort_Range with Subprogram_Variant =>
--  (Decreases => J - I). The classic inductive "half-maxima then
--  surrender" sortedness argument fights automated Level 4, so Sort
--  finishes with a gap-1 Bubble_Finish (same split as Stooge / Comb /
--  Odd_Even / Strand) to prove Is_Sorted. Full multiset / permutation
--  equality is verified by tests rather than claimed as a Level-4
--  postcondition.
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

   --  Live indices are 1 .. N with N ≤ Max_N. Empty arrays use Last = 0.
   subtype Index is Natural range 0 .. Max_N;

   type Element_Array is array (Positive range <>) of Integer;

   ---------------------------------------------------------------------------
   -- Shape / sortedness guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'First = 1 and then A'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard used by every entry point. Empty arrays have
   --  A'Last = 0 when A'First = 1 (rejects Last < 0).

   function Is_Sorted (A : Element_Array) return Boolean is
     (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (multiply and surrender / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Recurse on I .. J (initially 1 .. A'Last):
   --    1. If I >= J, return.
   --    2. M := I + (J - I) / 2          -- floor((I+J)/2), overflow-safe
   --    3. Slowsort_Range (A, I, M)      -- multiply: left half
   --    4. Slowsort_Range (A, M+1, J)    -- multiply: right half
   --    5. If A(M) > A(J), swap          -- larger half-maximum at J
   --    6. Slowsort_Range (A, I, J-1)    -- surrender: rest
   --  Subprogram_Variant (J - I) strictly decreases on each recursive
   --  call. Empty and singleton arrays are no-ops.
   --  Level 4: Slowsort_Range proves RTE / termination / frame; Sort then
   --  runs a gap-1 bubble finish to prove Is_Sorted.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending Slowsort (in-place multiply-and-surrender), then a
   --  gap-1 bubble finish that discharges Is_Sorted at Level 4.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Slowsort;
