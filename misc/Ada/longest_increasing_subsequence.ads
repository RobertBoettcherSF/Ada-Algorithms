--  Longest_Increasing_Subsequence — Ada 2023 educational package for the
--  strictly increasing longest increasing subsequence (LIS) problem on
--  Integer arrays. Provides classic O(n²) DP length and O(n log n)
--  patience-sorting / tails + binary-search length with predecessor-based
--  reconstruction of one witness subsequence.
--  Primary source:
--  https://en.wikipedia.org/wiki/Longest_increasing_subsequence
--  Sibling contrast (README only; do not `with`): longest common
--  subsequence (LCS) — LIS of S equals LCS of S and sort(S).

pragma Ada_2022;

package Longest_Increasing_Subsequence
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   --  Soft limit for the O(n log n) routines (Length / Find).
   Max_Length : constant Positive := 10_000;

   --  Soft limit for the quadratic Length_DP routine (tests stay smaller).
   Max_Length_DP : constant Positive := 512;

   ---------------------------------------------------------------------------
   -- Types
   ---------------------------------------------------------------------------

   --  Input sequence and reconstructed LIS witness (element values).
   type Int_Array is array (Positive range <>) of Integer;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when the input is empty, Length/Find sees n > Max_Length, or
   --  Length_DP sees n > Max_Length_DP.

   ---------------------------------------------------------------------------
   -- Length_DP — classic O(n²) dynamic programming
   ---------------------------------------------------------------------------

   function Length_DP (A : Int_Array) return Positive
     with Global => null;
   --  Length of a strictly longest increasing subsequence of A.
   --  Recurrence: let L(i) be the LIS length ending at index i
   --  (1-based logical position into A). Then
   --    L(i) = 1 + max { L(j) | j < i and A(j) < A(i) }, or 1 if none.
   --  Answer = max_i L(i). Time Θ(n²), space Θ(n).
   --  Raises Invalid_Argument if A'Length = 0 or A'Length > Max_Length_DP.

   ---------------------------------------------------------------------------
   -- Length / Find — O(n log n) patience sorting (tails) + reconstruction
   ---------------------------------------------------------------------------

   function Length (A : Int_Array) return Positive
     with Global => null;
   --  Same length as Length_DP, computed with the patience / tails method:
   --  maintain an increasing array Tails where Tails(len) is the smallest
   --  tail value of any increasing subsequence of length len found so far;
   --  for each A(i) binary-search the first Tails entry ≥ A(i) and replace
   --  (or append). Time Θ(n log n), space Θ(n).
   --  Raises Invalid_Argument if A'Length = 0 or A'Length > Max_Length.

   function Find (A : Int_Array) return Int_Array
     with Global => null;
   --  One strictly increasing subsequence of A of length Length(A).
   --  Uses the same tails scan while recording predecessor indices, then
   --  walks predecessors from the end of a maximal-length chain.
   --  When several LIS exist, returns one valid witness (not necessarily
   --  lexicographically first). Empty result never occurs for non-empty A
   --  (singleton elements are always valid length-1 subsequences).
   --  Raises Invalid_Argument if A'Length = 0 or A'Length > Max_Length.

end Longest_Increasing_Subsequence;
