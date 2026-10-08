--  Stooge_Sort — Ada/SPARK Level 4 educational package for the deliberately
--  inefficient recursive sorting algorithm named after The Three Stooges.
--  Recurrence T(n) = 3 T(⌈2n/3⌉) + Θ(1) yields
--  Θ(n^(log 3 / log 1.5)) ≈ Θ(n^2.709). Pessimal but still faster than
--  Slowsort; keep Max_N tiny.
--
--  SPARK port of Ada-Stooge-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling allows arbitrary A'First and raises on oversized n; this port
--  requires A'First = 1, uses Pre => In_Bounds (A), and bounds recursive
--  Stooge_Range with Subprogram_Variant => (Decreases => Hi - Lo). The
--  recursion itself is proved: Stooge_Range's postcondition says the
--  slice Lo .. Hi is sorted and holds the same values with the same
--  counts (a ghost counting argument: after the second call the last
--  third holds the largest values, after the third call the first two
--  thirds are sorted below them). Sort is only that recursion; there is
--  no fallback pass. Sort's public Post states sortedness; the count
--  preservation is proved inside the body and also checked by tests.
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
   -- Algorithm sketch (The Three Stooges / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Recurse on Lo .. Hi (initially 1 .. A'Last):
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
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending Stooge sort (in-place recursive 2/3–2/3–2/3); the
   --  recursion alone discharges Is_Sorted at Level 4.
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; count preservation is proved on the body's
   --  Stooge_Range and checked by the test suite.

end Stooge_Sort;
