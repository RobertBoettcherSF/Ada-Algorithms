--  Quickselect — Ada 2023 educational package for Hoare's selection
--  algorithm (Tony Hoare): find the k-th smallest element in an unordered
--  Integer array via in-place Quickselect (median-of-three pivot, Lomuto
--  partition). Average O(n), worst O(n²); O(1) extra space for Select_Kth.
--  Reference: https://en.wikipedia.org/wiki/Quickselect
--  Sibling sheets (README only — do not `with`): Selection_Algorithm,
--  Introselect, Quicksort.

pragma Ada_2022;

package Quickselect
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum array length accepted by Select_Kth / Select_Kth_Copy /
   --  Median. Quickselect is O(n) on average; this guard is pedagogical.
   Max_N : constant Positive := 100_000;

   ---------------------------------------------------------------------------
   -- Domain
   ---------------------------------------------------------------------------

   type Element_Array is array (Natural range <>) of Integer;

   Invalid_Argument : exception;
   --  Raised when A'Length = 0, A'Length > Max_N, or K not in 1 .. A'Length.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Quickselect / Wikipedia)
   ---------------------------------------------------------------------------
   --  Goal: place / return the K-th smallest element of A (1-based order
   --  statistic). K = 1 → minimum; K = n → maximum; Median uses lower-
   --  middle for even n.
   --  Pivot: median-of-three of A(Lo), A(Mid), A(Hi) — deterministic,
   --  random-free (avoids the sorted-array worst case of a fixed end
   --  pivot on many inputs).
   --  Partition: Lomuto — after partitioning, pivot sits at index P;
   --  every element left of P is ≤ pivot, every element right is ≥.
   --  (Lomuto is required for the classic Quickselect loop, which assumes
   --  the partition return value is the pivot's final rank; Hoare's
   --  scheme does not guarantee that.)
   --  Recur only into the side that contains rank K (iterative loop).
   --  Select_Kth rearranges A in place; Select_Kth_Copy works on a copy.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Selection
   ---------------------------------------------------------------------------

   procedure Select_Kth (A : in out Element_Array; K : Positive);
   --  In-place Quickselect: rearranges A so that after return,
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

end Quickselect;
