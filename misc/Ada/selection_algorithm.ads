--  Selection_Algorithm — Ada 2023 educational package for the selection
--  problem (k-th order statistic): find the k-th smallest element in an
--  unordered Integer array via in-place Quickselect (median-of-three
--  pivot, Lomuto partition). Average O(n), worst O(n²); O(1) extra space
--  for Select_Kth. Reference:
--  https://en.wikipedia.org/wiki/Selection_algorithm
--  Sibling sheets (README only — do not `with`): Quickselect, Introselect.

pragma Ada_2022;

package Selection_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Select_Kth / Select_Kth_Copy /
   --  Median. Quickselect is O(n) on average; this guard is pedagogical.
   --  Tests stay well below Max_N except the deliberate Invalid_Argument
   --  cases.
   Max_N : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length = 0, A'Length > Max_N, or K not in 1 .. A'Length.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Quickselect / Wikipedia selection algorithm)
   ---------------------------------------------------------------------------
   --  Goal: return the K-th smallest element of A (1-based order
   --  statistic). K = 1 → minimum; K = n → maximum; special case
   --  median via Median.
   --  Pivot: median-of-three of A(Lo), A(Mid), A(Hi) — deterministic,
   --  random-free (avoids the sorted-array worst case of a fixed end
   --  pivot on many inputs).
   --  Partition: Lomuto — after partitioning, pivot sits at index P;
   --  every element left of P is ≤ pivot, every element right is ≥.
   --  Recur only into the side that contains rank K (iterative loop).
   --  Select_Kth rearranges A in place; Select_Kth_Copy works on a copy.
   --  Do not `with` sibling Ada-* packages (Quickselect / Introselect).

   ---------------------------------------------------------------------------
   -- Selection
   ---------------------------------------------------------------------------

   function Select_Kth (A : in out Element_Array; K : Positive) return Integer;
   --  In-place Quickselect: rearranges A so that the K-th smallest
   --  element (1-based) ends at its final rank position and is returned.
   --  After return, A(A'First + K - 1) equals the result (for contiguous
   --  index ranges), elements before that index are ≤ it, and elements
   --  after are ≥ it. Raises Invalid_Argument when A is empty,
   --  A'Length > Max_N, or K > A'Length.

   function Select_Kth_Copy (A : Element_Array; K : Positive) return Integer;
   --  Non-mutating wrapper: copies A, runs Select_Kth on the copy, and
   --  returns the K-th smallest. Original A is unchanged. Same
   --  Invalid_Argument rules as Select_Kth. Uses O(n) temporary space.

   function Median (A : in out Element_Array) return Integer;
   --  In-place median via Select_Kth. For odd n = A'Length, returns the
   --  middle element (rank K = (n + 1) / 2). For even n, returns the
   --  lower middle (rank K = n / 2). Raises Invalid_Argument when A is
   --  empty or A'Length > Max_N. Rearranges A like Select_Kth.

end Selection_Algorithm;
