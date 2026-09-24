--  Bucket_Sort — Ada 2023 educational package for Wikipedia "Bucket sort".
--  Scatter Integer keys into k buckets, insertion-sort each bucket, gather.
--  Average O(n) when k ≈ n and keys are roughly uniform over [min, max].
--  Reference: https://en.wikipedia.org/wiki/Bucket_sort

pragma Ada_2022;

package Bucket_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort.
   Max_Length : constant Positive := 100_000;

   --  Maximum number of buckets. Sort uses k = min(n, Max_Buckets).
   Max_Buckets : constant Positive := 10_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_Length.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Wikipedia / CLRS-style generic bucket sort)
   ---------------------------------------------------------------------------
   --  1. Find Min and Max among A. If Min = Max, the array is already sorted.
   --  2. Choose k = min(n, Max_Buckets) empty buckets.
   --  3. Scatter: map key x into bucket
   --        floor((k-1) * (x - Min) / (Max - Min))
   --     so Min → bucket 0 and Max → bucket k-1.
   --  4. Sort each non-empty bucket with insertion sort (stable).
   --  5. Gather: concatenate buckets 0 .. k-1 back into A.
   --
   --  Contrast with counting / pigeonhole sort: those allocate one slot per
   --  distinct key in [Min, Max]; bucket sort uses far fewer buckets and
   --  finishes each bin with a comparison sort. Do not `with` those packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Ascending bucket sort. Empty and singleton arrays are no-ops.
   --  Stable for equal keys (left-to-right scatter + insertion sort).
   --  Raises Invalid_Argument when A'Length > Max_Length.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Bucket_Sort;
