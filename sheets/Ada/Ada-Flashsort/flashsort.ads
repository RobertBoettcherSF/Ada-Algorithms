--  Flashsort — Ada 2023 educational package for Neubert flashsort:
--  in-place histogram / cycle-following bucket sort for Integer keys.
--  Expected O(n) on uniform data; O(n²) worst case when insertion sort
--  finishes a badly balanced classification.
--  Reference: https://en.wikipedia.org/wiki/Flashsort

pragma Ada_2022;

package Flashsort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   Max_N : constant Positive := 100_000;

   --  Number of classes m = max(2, n / Class_Divisor), i.e. Neubert's
   --  m ≈ 0.1 n with a floor of 2 (need at least two classes so the
   --  interpolation formula can separate min from max).
   Class_Divisor : constant Positive := 10;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Neubert flashsort / Wikipedia)
   ---------------------------------------------------------------------------
   --  1. Find min and max. If they are equal, the array is already sorted.
   --  2. Choose m classes (buckets), m = max(2, n / Class_Divisor).
   --  3. Count a histogram into L(1 .. m); prefix-sum so L(k) is the
   --     inclusive 1-based upper border of class k.
   --  4. Permute elements into their classes by cycle-following. The
   --     classification formula (integer arithmetic, floor via truncating
   --     division of nonnegatives) is
   --        K = 1 + floor((m-1) * (A(i) - min) / (max - min))
   --     so min maps to class 1 and max maps to class m.
   --  5. Insertion-sort within each class.
   --
   --  Extra memory is O(m) for the border vector L. Each element is moved
   --  at most once during the permutation. The sort is not stable.
   --  Do not `with` sibling Bucket_Sort / Counting_Sort packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending in-place flashsort (unstable).
   --  Empty and singleton arrays are no-ops; all-equal arrays return after
   --  the min/max scan.
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Flashsort;
