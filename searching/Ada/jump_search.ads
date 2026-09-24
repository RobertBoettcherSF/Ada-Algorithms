--  Jump_Search — Ada 2023 educational package for jump search (also called
--  block search) on a sorted ascending Integer array. Advances by fixed-size
--  jumps of length m = floor(sqrt(n)) (or an explicit Step) until a block that
--  can hold the key is found, then finishes with a short linear scan of that
--  block. Runs in O(√n) comparisons — better than linear search, worse than
--  binary search, but needs only one backward jump (useful when going back
--  is expensive relative to going forward).
--  Reference: https://en.wikipedia.org/wiki/Jump_search

pragma Ada_2022;

package Jump_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Find.
   Max_N : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   --  Sorted ascending (nondecreasing) integer sequence. Indices are
   --  Natural; the array may start at any Natural bound (0- or 1-based).
   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_N, or when the explicit Step overload is
   --  called with Step = 0.

   ---------------------------------------------------------------------------
   -- Algorithm sketch
   ---------------------------------------------------------------------------
   --  Precondition: A is sorted in nondecreasing (ascending) order.
   --  Let n = A'Length and m = floor(sqrt(n)) (or the caller-supplied Step).
   --  Jump forward over blocks of size m while A(min(i+m, last)) < Key.
   --  Then linearly scan the previous block for Key.
   --  Optimal block size is m = √n; both phases examine O(√n) elements,
   --  so the algorithm runs in O(√n) time.
   --
   --  Synonym: "block search".
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Find (A : Element_Array; Key : Integer) return Integer;
   --  Jump (block) search for Key in sorted ascending A, using block size
   --  m = floor(sqrt(A'Length)) when A is non-empty.
   --  Returns an index I in A'Range with A(I) = Key, or the sentinel
   --  A'First - 1 when Key is absent (or when A is empty).
   --  When duplicates exist, any matching index is acceptable (not
   --  necessarily the leftmost or rightmost).
   --  Raises Invalid_Argument when A'Length > Max_N.

   function Find
     (A    : Element_Array;
      Key  : Integer;
      Step : Natural) return Integer;
   --  Same contract as Find, but uses the given Step as the jump / block
   --  size instead of floor(sqrt(n)).
   --  Raises Invalid_Argument when A'Length > Max_N or Step = 0.

end Jump_Search;
