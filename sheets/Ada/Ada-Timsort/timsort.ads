--  Timsort — Ada 2023 educational package for a hybrid stable sort
--  derived from merge sort and insertion sort (Tim Peters, 2002).
--  Finds natural runs, extends short ones with binary insertion, then
--  merges according to simplified Timsort stack invariants.
--  Worst Θ(n log n); near-linear on nearly sorted input.
--  Reference: https://en.wikipedia.org/wiki/Timsort
--  Educational sketch — not identical to CPython (no galloping, simplified
--  merge buffer). Do not `with` Merge_Sort or Insertion_Sort packages.

pragma Ada_2022;

package Timsort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   --  Timsort is Θ(n log n) worst case, so a large educational bound is fine.
   --  One temp buffer of size n is allocated once per Sort for merging.
   Max_N : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (educational Timsort / Wikipedia)
   ---------------------------------------------------------------------------
   --  1. Compute minrun from n (classic power-of-two related):
   --       r := 0; while n >= 64: r |= n & 1; n >>= 1; return n + r
   --     so minrun ∈ [32, 64] for n ≥ 64, and minrun = n for n < 64.
   --  2. Scan left to right identifying natural ascending or strictly
   --     descending runs. Reverse descending runs in place (strictly
   --     descending excludes equals → stability). Extend short runs to
   --     minrun with binary insertion sort.
   --  3. Push each finished run onto a stack. After each push, merge
   --     according to classic stack invariants (X = newest / top,
   --     Y = second, Z = third):
   --       • while ≥ 3 runs and |Z| ≤ |Y| + |X|: merge Y with the
   --         smaller of X and Z (prefer Z+Y when |Z| < |X|, else Y+X);
   --       • else while ≥ 2 runs and |Y| ≤ |X|: merge Y+X.
   --     After the scan, collapse the stack by repeatedly merging the
   --     top two runs until one run remains.
   --  4. Stable merge of adjacent runs via a temp buffer (prefer left
   --     when equal so relative order of equal keys is preserved).
   --
   --  Skipped vs full CPython Timsort: galloping mode, merge-collapse
   --  power-law refinements (Powersort), and shrunk-run / smaller-buffer
   --  merge tricks. Helpers are inlined — no sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending educational Timsort (stable hybrid).
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Timsort;
