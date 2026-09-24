--  Longest_Common_Substring — Ada 2023 educational package for the
--  longest common substring problem (contiguous shared fragment).
--  Dynamic-programming table L(i,j) tracks the longest common *suffix*
--  of the prefixes A(1..i) and B(1..j); the global maximum is the LCSS
--  length. Contrast with the longest common *subsequence* problem
--  (non-contiguous) is documented in README only — this package does
--  not implement subsequence LCS.
--  Primary source:
--  https://en.wikipedia.org/wiki/Longest_common_substring_problem

pragma Ada_2022;

package Longest_Common_Substring
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity
   ---------------------------------------------------------------------------

   --  Educational bound on each input string length. A fixed DP table of
   --  size (Max_Length+1)×(Max_Length+1) is allocated on the stack; inputs
   --  longer than Max_Length raise Invalid_Argument.
   Max_Length : constant Positive := 256;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_Length or B'Length > Max_Length.

   ---------------------------------------------------------------------------
   -- Length / Find (dynamic programming)
   ---------------------------------------------------------------------------

   function Length (A, B : String) return Natural
     with Global => null;
   --  Length of a longest common contiguous substring of A and B.
   --  Empty inputs or no shared characters → 0.
   --  Time / space Θ(|A|·|B|). Raises Invalid_Argument if either length
   --  exceeds Max_Length.

   function Find (A, B : String) return String
     with Global => null;
   --  One longest common contiguous substring of A and B.
   --  Tie-breaking: when several substrings share the maximal length,
   --  return the one whose match ends at the smallest 1-based index in A;
   --  if still tied, the one that ends at the smallest 1-based index in B
   --  (first hit in row-major DP scan over i then j, updating only when
   --  L(i,j) is strictly greater than the best so far).
   --  No common substring → empty string "".
   --  Raises Invalid_Argument if either length exceeds Max_Length.

   ---------------------------------------------------------------------------
   -- Brute-force oracle (small strings)
   ---------------------------------------------------------------------------

   function Brute_Force_Length (A, B : String) return Natural
     with Global => null;
   --  O(|A|²·|B|) educational oracle: try every substring of A and test
   --  membership in B. Intended for cross-checking DP on small inputs.
   --  Same Max_Length guard as Length / Find.

end Longest_Common_Substring;
