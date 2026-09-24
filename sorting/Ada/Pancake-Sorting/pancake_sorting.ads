--  Pancake_Sorting — Ada 2023 educational package for sorting by
--  prefix reversals ("pancake flips"). A spatula may be inserted at
--  any point in a stack and used to reverse every pancake above it.
--  The classic selection-style algorithm brings the largest unsorted
--  pancake to the top, then flips it into place, using at most
--  2n − 3 flips. Works on general Integer arrays, not only
--  permutations of 1 .. n.
--  Reference: https://en.wikipedia.org/wiki/Pancake_sorting

pragma Ada_2022;

package Pancake_Sorting
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bound (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Flip / Sort / Apply_Flips.
   Max_Length : constant Positive := 10_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   --  Recorded prefix lengths K (1-based logical / document bounds)
   --  as passed to Flip. Only the slice
   --  Flips (Flips'First .. Flips'First + Count - 1) is meaningful.
   type Flip_Sequence is array (Positive range <>) of Natural;

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_Length, when Flip's K exceeds
   --  A'Length, or when a recorded-flip buffer is shorter than the
   --  number of flips the classic algorithm actually performs.

   ---------------------------------------------------------------------------
   -- Prefix reversal
   ---------------------------------------------------------------------------

   procedure Flip (A : in out Element_Array; K : Natural);
   --  Reverse the prefix of length K using 1-based logical / document
   --  bounds: the first K elements
   --  A (A'First .. A'First + K - 1), independent of A'First.
   --  On a 1-based array this is exactly A (1 .. K).
   --  K = 0 or 1 is a no-op. Raises Invalid_Argument if
   --  A'Length > Max_Length or K > A'Length.

   procedure Apply_Flips
     (A     : in out Element_Array;
      Flips : Flip_Sequence);
   --  Apply each recorded prefix reversal in index order.
   --  Empty Flips is a no-op. Raises Invalid_Argument on oversize A
   --  or on any K > A'Length.

   ---------------------------------------------------------------------------
   -- Sorting
   ---------------------------------------------------------------------------

   procedure Sort (A : in out Element_Array);
   --  Classic pancake sort (selection-style): for Size in n downto 2,
   --  locate a maximum of the prefix of length Size; Flip it to the
   --  front if it is not already there, then Flip that prefix to place
   --  the maximum at position Size. At most 2n − 3 flips for n ≥ 2
   --  (for n = 2 at most one flip; empty and singleton are no-ops).
   --  Produces nondecreasing (ascending) order. Works for general
   --  Integers, including negatives and duplicates — not only
   --  permutations. Raises Invalid_Argument when A'Length > Max_Length.

   procedure Sort
     (A     : in out Element_Array;
      Flips : out Flip_Sequence;
      Count : out Natural);
   --  Same as Sort, and records the prefix lengths actually flipped
   --  into Flips (indices Flips'First .. Flips'First + Count - 1).
   --  Count ≤ Classic_Flip_Bound (A'Length). Only those Count slots
   --  are written. Raises Invalid_Argument if Flips is shorter than
   --  the number of flips performed, or on oversize A.

   function Is_Sorted (A : Element_Array) return Boolean;
   --  True iff A is nondecreasing (ascending) in index order.
   --  Empty and singleton arrays are considered sorted.

   function Classic_Flip_Bound (N : Natural) return Natural;
   --  Upper bound of the classic algorithm: 0 when N ≤ 1, otherwise
   --  2N − 3. This is an upper bound on the pancake number P(N)
   --  for N ≥ 2, not the (generally smaller) exact P(N).

end Pancake_Sorting;
