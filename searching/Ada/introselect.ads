--  Introselect — Ada 2023 educational package for Musser introspective
--  selection: hybrid of Quickselect + median-of-medians (BFPRT) fallback.
--  Practical average ~O(n); worst-case O(n) intent via MoM pivot when the
--  introspective depth budget is exhausted. O(1) extra space for Select_Kth
--  aside from MoM recursion O(log n).
--  Reference: https://en.wikipedia.org/wiki/Introselect
--  Sibling sheets (README only — do not `with`): Quickselect,
--  Selection_Algorithm, Introsort, Quicksort.

pragma Ada_2022;

package Introselect
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Select_Kth / Select_Kth_Copy /
   --  Median. This guard is pedagogical.
   Max_N : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length = 0, A'Length > Max_N, or K not in 1 .. A'Length.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Introselect / Musser 1997 / Wikipedia)
   ---------------------------------------------------------------------------
   --  Goal: place / return the K-th smallest element of A (1-based order
   --  statistic). K = 1 → minimum; K = n → maximum; Median uses lower-
   --  middle for even n.
   --  Start like Quickselect: median-of-three + Lomuto partition, shrink
   --  to the side that contains rank K (iterative loop).
   --  Depth budget: maxdepth ← 2 × ⌊log₂ n⌋ (classic Musser / introsort
   --  analogue). Each Quickselect step consumes one unit of depth.
   --  Fallback: when depth reaches 0, choose the pivot via Blum–Floyd–
   --  Pratt–Rivest–Tarjan median of medians (groups of 5), place it at Hi
   --  for Lomuto, partition, then restore a fresh depth budget on the
   --  remaining subproblem (MoM guarantees constant-fraction progress).
   --  Select_Kth rearranges A in place; Select_Kth_Copy works on a copy.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Selection
   ---------------------------------------------------------------------------

   procedure Select_Kth (A : in out Element_Array; K : Positive);
   --  In-place introselect: rearranges A so that after return,
   --  A(A'First + K - 1) holds the K-th smallest element (1-based order
   --  statistic). Elements before that index are ≤ it; elements after
   --  are ≥ it (partition property). Raises Invalid_Argument when A is
   --  empty, A'Length > Max_N, or K > A'Length.

   function Select_Kth_Copy (A : Element_Array; K : Positive) return Integer;
   --  Non-mutating wrapper: copies A, runs Select_Kth on the copy, and
   --  returns the K-th smallest. Original A is unchanged. Same
   --  Invalid_Argument rules as Select_Kth. Uses O(n) temporary space.

   function Median (A : in out Element_Array) return Integer;
   --  In-place median via Select_Kth. For odd n = A'Length, returns the
   --  middle element (rank K = (n + 1) / 2). For even n, returns the
   --  lower middle (rank K = n / 2). Raises Invalid_Argument when A is
   --  empty or A'Length > Max_N. Rearranges A like Select_Kth.

end Introselect;
