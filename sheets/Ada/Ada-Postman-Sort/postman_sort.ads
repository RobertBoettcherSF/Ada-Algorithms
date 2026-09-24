--  Postman_Sort — Ada 2023 educational package for MSD (most-significant-
--  digit) postal / pigeonhole distribution sort. Stable ascending sort of
--  nonnegative Integer keys; default base 10, optional base in 2 .. 256.
--  Sibling of LSD Radix_Sort; related to bucket sort and pigeonhole sort.
--  References:
--    https://en.wikipedia.org/wiki/Postman_sort
--    https://en.wikipedia.org/wiki/Bucket_sort (Postman's sort variant)

pragma Ada_2022;

package Postman_Sort
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bound (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Sort / Sort_Base.
   Max_Length : constant Positive := 100_000;

   --  Inclusive upper bound on the radix / base for Sort_Base.
   Max_Base : constant Positive := 256;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   subtype Base_Range is Positive range 2 .. Max_Base;

   Invalid_Argument : exception;
   --  Raised when:
   --    * A'Length > Max_Length;
   --    * any element is negative (signed keys are not accepted — see
   --      Signed-integer policy below);
   --    * Base is outside Base_Range (caught by subtype constraint when
   --      callers pass a constrained Base_Range value).

   ---------------------------------------------------------------------------
   -- Signed-integer policy (nonnegative only)
   ---------------------------------------------------------------------------
   --  Postman / MSD digit distribution extracts
   --  d = (key / base^p) mod base, which is well-defined for nonnegative
   --  keys. This package therefore accepts only keys in 0 .. Integer'Last.
   --  Negative values raise Invalid_Argument before any distribution.
   --
   --  Alternative (not implemented): a two's-complement key transform that
   --  XOR/flips the sign bit so signed Integers order as unsigned bit
   --  patterns, then restore after sorting.

   ---------------------------------------------------------------------------
   -- Relation to radix, bucket, and pigeonhole sorts
   ---------------------------------------------------------------------------
   --  * LSD radix sort (sibling package) walks digits least → most and
   --    composes stable counting-sort passes. Postman sort walks most →
   --    least, recursively sorting each pigeonhole (MSD / "top-down" radix).
   --  * Bucket sort scatters into bins then sorts each bin; Postman's sort
   --    is the hierarchical / multi-attribute bucket variant used by letter-
   --    sorting machines (domestic vs international, then region, then
   --    route, …). Wikipedia lists it under Bucket sort variants.
   --  * Pigeonhole sort is the extreme of one key per hole; Postman allows
   --    many keys per digit bucket and recurses on the next digit.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Stable ascending MSD postman sort with base 10 (decimal digits).
   --  Distribute by most significant digit into pigeonholes, recursively
   --  sort each non-empty bucket by the next digit, then concatenate.
   --  Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_Length or any A (I) < 0.

   procedure Sort_Base (A : in out Element_Array; Base : Base_Range);
   --  Same as Sort, but with an explicit radix Base in 2 .. 256
   --  (e.g. 256 for byte-sized digits). Empty / singleton are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_Length or any A (I) < 0.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Postman_Sort;
