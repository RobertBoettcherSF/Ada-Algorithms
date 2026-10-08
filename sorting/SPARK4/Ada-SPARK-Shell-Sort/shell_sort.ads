--  Shell_Sort — Ada/SPARK Level 4 educational package for classic
--  Shellsort (Shell's method, 1959) on an Integer array. In-place
--  diminishing-gap insertion sort; not stable in general. Fixed Ciura
--  gap prefix sized for Max_N (no dynamic float gap generation).
--
--  SPARK port of Ada-Shell-Sort: hard Max_N bound, no exceptions,
--  In_Bounds / Is_Sorted contracts replace Invalid_Argument. Non-SPARK
--  sibling allows arbitrary A'First, raises on oversized n, and extends
--  Ciura with floor(2.25·h) for n > 701; this port requires A'First = 1,
--  uses Pre => In_Bounds (A), and a fixed descending gap table that fits
--  Max_N. Full multiset / permutation equality is verified by tests
--  rather than claimed as a Level-4 postcondition (sortedness is proved
--  via the final gap-1 insertion pass).
--
--  Reference: https://en.wikipedia.org/wiki/Shellsort

package Shell_Sort
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
   -- Algorithm sketch (classic Shellsort / Wikipedia)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). For each gap h in a fixed decreasing sequence
   --  that ends with 1, h-sort A: insertion-sort each interleaved
   --  subsequence A(i), A(i+h), A(i+2h), … . After the final h = 1 pass
   --  the array is fully sorted (ordinary insertion sort).
   --
   --  Gap table (Ciura prefix that fits Max_N = 64; descending):
   --    57, 23, 10, 4, 1
   --  (Sibling also has 701, 301, 132 and a floor(2.25·h) extension for
   --  large n — omitted here because Max_N < 132.)
   --  Empty and singleton arrays are no-ops.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending classic in-place Shellsort (fixed Ciura gaps + gap-1).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Shell_Sort;
