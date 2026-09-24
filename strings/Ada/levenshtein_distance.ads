--  Levenshtein_Distance — Ada 2023 educational package for the classical
--  unit-cost Levenshtein edit distance between two Character strings:
--  the minimum number of single-symbol insertions, deletions, or
--  substitutions needed to transform one string into the other.
--  Wagner–Fischer dynamic programming; optional Similarity helper.
--  Primary source: https://en.wikipedia.org/wiki/Levenshtein_distance
--  Sibling sheets (README only — do not `with`): Longest_Common_Subsequence,
--  Trigram_Search, Longest_Common_Substring.

pragma Ada_2022;

package Levenshtein_Distance
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum length of either input string. Classical DP is O(m·n) time
   --  and (naively) O(m·n) space; this package uses a two-row rolling
   --  formulation so auxiliary space is O(min(m,n)). The bound is
   --  pedagogical — tests stay well below Max_Len except the deliberate
   --  Invalid_Argument cases.
   Max_Len : constant Positive := 2_000;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_Len or B'Length > Max_Len. Empty strings
   --  are valid and do not raise.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Wagner–Fischer / Wikipedia recurrence)
   ---------------------------------------------------------------------------
   --  Let D(i,j) be the distance between the prefixes A[1..i] and B[1..j].
   --    D(i,0) = i,   D(0,j) = j
   --    D(i,j) = min( D(i-1,j)+1,          -- delete A[i]
   --                  D(i,j-1)+1,          -- insert B[j]
   --                  D(i-1,j-1)+δ )       -- substitute / match
   --  where δ = 0 if A[i] = B[j], else 1. Answer is D(m,n).
   --  Unit cost for insert, delete, and substitute (classical Levenshtein).
   --  Case-sensitive Character equality; no Unicode normalization.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Distance / Similarity
   ---------------------------------------------------------------------------

   function Distance (A, B : String) return Natural
     with Global => null;
   --  Classical unit-cost Levenshtein distance between A and B: the
   --  minimum number of single-character insertions, deletions, and
   --  substitutions that transform A into B (or vice versa — the
   --  distance is symmetric). Empty/empty → 0. Empty vs length-k → k.
   --  Time O(|A|·|B|); auxiliary space O(min(|A|,|B|)) via two-row DP.
   --  Raises Invalid_Argument when A'Length or B'Length > Max_Len.

   function Similarity (A, B : String) return Float
     with Global => null;
   --  Normalized similarity derived from Distance:
   --    both empty → 1.0
   --    otherwise  → 1 − Distance(A,B) / max(|A|,|B|)
   --  Result lies in [0.0, 1.0]. Identical nonempty strings → 1.0.
   --  Raises Invalid_Argument when A'Length or B'Length > Max_Len.

end Levenshtein_Distance;
