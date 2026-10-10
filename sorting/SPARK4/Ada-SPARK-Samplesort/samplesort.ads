--  Samplesort — Ada/SPARK Level 4 educational package for Wikipedia
--  samplesort: sample Num_Buckets-1 pivots, cut the array into buckets
--  in place (one partition per pivot), insertion-sort each bucket.
--  O(p n + n²/p) with balanced buckets (p = Num_Buckets); O(n²) worst
--  when most keys fall into one bucket.
--
--  SPARK port of Ada-Samplesort: hard Max_N bound, fixed Num_Buckets,
--  no exceptions, no Ada tasks / Parallel variant, no Oversampling
--  API — a single Sort procedure. Non-SPARK sibling uses Data_Element,
--  Sequential / Parallel / Oversampling variants, Quick_Sort buckets,
--  exceptions (Invalid_Bucket_Count / Invalid_Oversample_Factor), and
--  arbitrary A'First; this port takes any A'First (A'Length <= Max_N), Integer
--  Element_Array, in-place buckets, and proves that the samplesort
--  steps themselves sort (no fallback pass). The Post of Sort also
--  proves that the result is a permutation of the input (counts of every
--  value, Is_Perm).
--
--  Reference: https://en.wikipedia.org/wiki/Samplesort

package Samplesort
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Capacity / bucket bounds (classroom)
   ---------------------------------------------------------------------------

   --  Hard bound on array length. Smaller than typical non-SPARK
   --  siblings so Level 4 can discharge array / arithmetic VCs.
   Max_N : constant Positive := 64;

   --  Fixed classroom bucket count. Sibling takes Num_Buckets as a
   --  parameter (and may spawn one task per bucket); this port fixes
   --  Num_Buckets = 8 so the pivot vector is static.
   Num_Buckets : constant Positive := 8;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Positions 1 .. N (N = A'Length <= Max_N) at any origin: position
   --  K is A (A'First + (K - 1)).
   subtype Index is Natural range 0 .. Max_N;

   type Element_Array is array (Positive range <>) of Integer;

   ---------------------------------------------------------------------------
   -- Shape / sortedness guards (expression functions — usable in contracts)
   ---------------------------------------------------------------------------

   function In_Bounds (A : Element_Array) return Boolean is
     (A'Length <= Max_N)
   with Global => null;
   --  Shape guard used by every entry point: a length bound, any origin.

   function Is_Sorted (A : Element_Array) return Boolean is
     (for all I in A'Range => (if I < A'Last then A (I) <= A (I + 1)))
   with
     Global => null,
     Pre    => In_Bounds (A);
   --  True iff A is adjacent-nondecreasing on A'Range (empty / singleton
   --  vacuous). Equivalent to pairwise sortedness on a total order.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (samplesort with in-place buckets)
   ---------------------------------------------------------------------------
   --  Assume In_Bounds (A).
   --  1. If n < Num_Buckets there are no pivots: the whole array is
   --     one bucket (step 4).
   --  2. Choose Num_Buckets-1 pivots from equally spaced samples
   --     (deterministic stride = n / Num_Buckets; no RNG) and sort them.
   --  3. For each pivot in order: partition the not yet placed suffix
   --     so the keys <= pivot come first; insertion-sort that bucket
   --     in place.
   --  4. Insertion-sort the last bucket (keys above every pivot).
   --  Proof: the placed prefix is sorted and no larger than any key
   --  still to place, so each sorted bucket extends it.
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
   --  Ascending educational samplesort (in-place buckets).
   --  Empty and singleton arrays are no-ops.
   --  Post proves sortedness and that A holds the values of A'Old, each
   --  equally often (Is_Perm).

end Samplesort;
