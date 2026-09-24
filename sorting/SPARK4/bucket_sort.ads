--  Bucket_Sort — Ada/SPARK Level 4 educational package for classic
--  bucket sort (bin sort) on a bounded-key Element array. Scatter
--  into Max_Buckets uniform-width bins, insertion-sort each bin,
--  gather. Average O(n) when keys are roughly uniform over
--  0 .. Max_Key; worst O(n²) with insertion sort inside a bin.
--
--  SPARK port of Ada-Bucket-Sort: hard Max_N bound, fixed key domain
--  0 .. Max_Key (no dynamic min/max span), static flat bucket store
--  (no heap / unbounded vectors), no exceptions, In_Bounds /
--  Is_Sorted contracts replace Invalid_Argument. Non-SPARK sibling
--  allows arbitrary Integer keys, Max_Length = 100_000, dynamic k =
--  min(n, Max_Buckets), and arbitrary A'First; this port requires
--  A'First = 1, Element in 0 .. Max_Key, fixed Max_Buckets, and uses
--  Pre => In_Bounds (A). Full multiset / permutation equality is
--  verified by tests rather than claimed as a Level-4 postcondition
--  (sortedness is proved via the final insertion pass, like the
--  Shellsort gap-1 argument).
--
--  Closest SPARK sort sibling that shares the same array shape and
--  key cap: Ada-SPARK-Counting-Sort. README links only — do not
--  `with` sibling packages here.
--
--  Reference: https://en.wikipedia.org/wiki/Bucket_sort

package Bucket_Sort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity / key-domain / bucket bounds (classroom; static store)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than the non-SPARK sibling
   --  (Max_Length = 100_000) so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   --  Inclusive upper bound on Element values. Sibling uses a dynamic
   --  Integer min..max span; this port fixes the closed key domain so
   --  bucket-index math is a single division by Bucket_Width.
   Max_Key : constant Natural := 255;

   --  Fixed classroom bucket count. Sibling uses k = min(n, 10_000).
   --  Store is a static flat array of size Max_Buckets * Max_N.
   Max_Buckets : constant Positive := 16;

   --  Uniform bin width over 0 .. Max_Key:
   --    Bucket_Of (X) = X / Bucket_Width  (result in 0 .. Max_Buckets-1).
   --  (Max_Key + 1) rem Max_Buckets = 0 so the last bin is full-width.
   Bucket_Width : constant Positive := (Max_Key + 1) / Max_Buckets;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Live indices are 1 .. N with N ≤ Max_N. Empty arrays use Last = 0.
   subtype Index is Natural range 0 .. Max_N;

   --  Educational keys: fixed span so bucket index is a static division.
   subtype Element is Natural range 0 .. Max_Key;

   type Element_Array is array (Positive range <>) of Element;

   subtype Bucket_Index is Natural range 0 .. Max_Buckets - 1;
   type Count_Array is array (Bucket_Index) of Natural;

   ---------------------------------------------------------------------------
   -- Shape / sortedness guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'First = 1 and then A'Last in 0 .. Max_N)
   with Global => null;
   --  Shape guard used by every entry point. Empty arrays have
   --  A'Last = 0 when A'First = 1 (rejects Last < 0).
   --  Element subtype already enforces keys in 0 .. Max_Key.

   function Is_Sorted (A : Element_Array) return Boolean is
     (for all I in A'First .. A'Last - 1 => A (I) <= A (I + 1))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Wikipedia / CLRS-style generic bucket sort)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A). Keys live in 0 .. Max_Key.
   --  1. Scatter each key X into bucket X / Bucket_Width
   --     (uniform bins; 0 → bucket 0, Max_Key → bucket Max_Buckets-1).
   --  2. Insertion-sort each non-empty bucket (stable, good for small bins).
   --  3. Gather buckets 0 .. Max_Buckets-1 back into A.
   --  4. Final insertion pass (Shell gap-1 pattern) proves Is_Sorted
   --     at Level 4 without claiming a full scatter/gather postcondition.
   --  Empty and singleton arrays are no-ops.
   --  Contrast with counting sort: that allocates one slot per key;
   --  bucket sort uses far fewer bins and finishes each with a
   --  comparison sort. Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array)
     with
       Global => null,
       Pre    => In_Bounds (A),
       Post   => In_Bounds (A) and then Is_Sorted (A);
   --  Ascending bucket sort (scatter / per-bucket insertion / gather).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness; multiset / permutation equality is
   --  checked by the test suite (not claimed here at Level 4).

end Bucket_Sort;
