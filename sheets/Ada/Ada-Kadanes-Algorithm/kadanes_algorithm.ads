--  Kadanes_Algorithm — Ada 2023 educational package for Kadane's algorithm
--  (maximum contiguous subarray sum) in O(n) time and O(1) extra space.
--  Variant: empty subarrays are NOT admitted. An all-negative array yields
--  the largest (least negative) element as a length-1 subarray.
--  Empty input raises Invalid_Argument.
--  Primary sources:
--  https://en.wikipedia.org/wiki/Maximum_subarray_problem
--  https://en.wikipedia.org/wiki/Kadane%27s_algorithm

pragma Ada_2022;

package Kadanes_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   --  Element type for array entries and subarray sums.
   --  Integer is sufficient for the educational test suite; sums of up to
   --  Max_Length entries must stay within Integer'Range in client data.
   subtype Element is Integer;

   --  Educational bound on input length. Inputs longer than Max_Length
   --  raise Invalid_Argument (keeps brute-force oracles practical in tests).
   Max_Length : constant Positive := 10_000;

   type Element_Array is array (Positive range <>) of Element;

   --  One maximum contiguous subarray witness.
   --  First / Last are 1-based logical indices into the sequence
   --  (1 = first element of A, independent of A'First):
   --    A (A'First + First - 1) .. A (A'First + Last - 1).
   type Result is record
      Sum   : Element;
      First : Positive;
      Last  : Positive;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when A'Length = 0 (no nonempty subarray exists) or when
   --  A'Length > Max_Length.

   ---------------------------------------------------------------------------
   -- Kadane (linear scan)
   ---------------------------------------------------------------------------

   function Max_Subarray_Sum (A : Element_Array) return Element
     with Global => null;
   --  Maximum contiguous subarray sum of A in O(n) time / O(1) space.
   --  All-negative policy: returns the largest element of A (a length-1
   --  subarray). Raises Invalid_Argument if A is empty or oversize.

   function Max_Subarray (A : Element_Array) return Result
     with Global => null;
   --  Same scan as Max_Subarray_Sum, also returning 1-based First / Last
   --  of one maximizing subarray. On ties, the leftmost (smallest Last,
   --  then smallest First) witness from the left-to-right scan is kept —
   --  i.e. the first time Best_Sum is strictly improved.
   --  Raises Invalid_Argument if A is empty or oversize.

   ---------------------------------------------------------------------------
   -- Brute-force oracle (small n)
   ---------------------------------------------------------------------------

   function Brute_Force_Sum (A : Element_Array) return Element
     with Global => null;
   --  O(n²) educational oracle: try every i..j and track the max sum.
   --  Same empty / Max_Length / all-negative policy as Max_Subarray_Sum.
   --  Intended for cross-checking Kadane on small inputs.

   function Brute_Force (A : Element_Array) return Result
     with Global => null;
   --  O(n²) oracle returning Sum / First / Last. Tie-break: among all
   --  maximizing windows, prefer the smallest First, then the smallest Last
   --  (lexicographic on (First, Last)).

end Kadanes_Algorithm;
