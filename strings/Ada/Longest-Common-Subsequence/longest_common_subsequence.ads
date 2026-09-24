--  Longest_Common_Subsequence — Ada 2023 educational package for the
--  longest common subsequence problem (non-contiguous shared sequence).
--  Classic DP: L(i,j) = L(i-1,j-1)+1 on match, else max(L(i-1,j), L(i,j-1)).
--  Contrast with the longest common *substring* problem (contiguous) is
--  documented in README — this package does not implement substring LCSS.
--  Primary source:
--  https://en.wikipedia.org/wiki/Longest_common_subsequence_problem

pragma Ada_2022;

package Longest_Common_Subsequence
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity
   ---------------------------------------------------------------------------

   --  Educational bound on each input string length. A fixed DP table of
   --  size (Max_Length+1)×(Max_Length+1) is allocated for Length / Find;
   --  inputs longer than Max_Length raise Invalid_Argument.
   Max_Length : constant Positive := 512;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_Length or B'Length > Max_Length.

   ---------------------------------------------------------------------------
   -- Length / Find (classic dynamic programming)
   ---------------------------------------------------------------------------

   function Length (A, B : String) return Natural
     with Global => null;
   --  Length of a longest common subsequence of A and B.
   --  Empty inputs or no shared characters → 0.
   --  Time / space Θ(|A|·|B|). Raises Invalid_Argument if either length
   --  exceeds Max_Length.

   function Find (A, B : String) return String
     with Global => null;
   --  One longest common subsequence of A and B, reconstructed by
   --  backtracking the DP table (Wikipedia-style).
   --  Tie-breaking when L(i,j-1) and L(i-1,j) are equal: prefer moving
   --  "up" (discard A[i]) rather than "left" (discard B[j]), i.e.
   --  follow left only when L(i,j-1) > L(i-1,j). Matches the Wikipedia
   --  backtrack pseudocode.
   --  No common subsequence → empty string "".
   --  Raises Invalid_Argument if either length exceeds Max_Length.

   ---------------------------------------------------------------------------
   -- Space-optimized length (two rolling rows)
   ---------------------------------------------------------------------------

   function Length_Space_Optimized (A, B : String) return Natural
     with Global => null;
   --  Same result as Length, but keeps only two rows of the DP table
   --  (Θ(min(|A|,|B|)) auxiliary space after swapping so the shorter
   --  string is the inner dimension). Time still Θ(|A|·|B|).
   --  Same Max_Length guard as Length / Find.

end Longest_Common_Subsequence;
