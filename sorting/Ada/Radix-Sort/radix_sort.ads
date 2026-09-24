--  Radix_Sort — Ada 2023 educational package for LSD (least-significant-
--  digit) radix sort with counting-sort digit passes. Stable ascending
--  sort of nonnegative Integer keys; default radix 10, optional base in
--  2 .. 256. Reference: https://en.wikipedia.org/wiki/Radix_sort

pragma Ada_2022;

package Radix_Sort
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
   --    * any element is negative (signed / two's-complement keys are not
   --      accepted — see Signed-integer policy below);
   --    * Base is outside Base_Range (caught by subtype constraint when
   --      callers pass a constrained Base_Range value).

   ---------------------------------------------------------------------------
   -- Signed-integer policy (nonnegative only)
   ---------------------------------------------------------------------------
   --  Classic LSD radix sort extracts digit d = (key / base^p) mod base,
   --  which is well-defined for nonnegative keys. This package therefore
   --  accepts only keys in 0 .. Integer'Last. Negative values raise
   --  Invalid_Argument before any digit pass.
   --
   --  Alternative (not implemented here): a two's-complement key transform
   --  that XOR/flips the sign bit so signed Integers order correctly as
   --  unsigned bit patterns, then restore after sorting. Prefer that when
   --  the domain must include negatives; it is orthogonal to LSD vs MSD.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Stable ascending LSD radix sort with base 10 (decimal digits).
   --  Counting-sort is used for each digit pass from least to most
   --  significant. Empty and singleton arrays are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_Length or any A (I) < 0.

   procedure Sort_Base (A : in out Element_Array; Base : Base_Range);
   --  Same as Sort, but with an explicit radix Base in 2 .. 256
   --  (e.g. 256 for byte-sized digits). Empty / singleton are no-ops.
   --  Raises Invalid_Argument when A'Length > Max_Length or any A (I) < 0.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

end Radix_Sort;
