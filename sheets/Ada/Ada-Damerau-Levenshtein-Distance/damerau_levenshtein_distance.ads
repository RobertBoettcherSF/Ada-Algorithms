--  Damerau_Levenshtein_Distance — Ada 2023 educational package for the
--  optimal string alignment (OSA / restricted Damerau–Levenshtein) edit
--  distance between two Character strings: the minimum number of
--  single-symbol insertions, deletions, substitutions, or adjacent
--  transpositions needed to transform one string into the other, under
--  the educational OSA constraint that each substring participates in at
--  most one edit. Unit cost 1 per operation. Optional Similarity helper.
--  Primary source: https://en.wikipedia.org/wiki/Damerau–Levenshtein_distance
--  Sibling sheets (README only — do not `with`): Levenshtein_Distance,
--  Longest_Common_Subsequence, Trigram_Search.

pragma Ada_2022;

package Damerau_Levenshtein_Distance
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum length of either input string. Classical OSA DP is O(m·n)
   --  time and (naively) O(m·n) space; this package uses a three-row
   --  rolling formulation so auxiliary space is O(min(m,n)). The bound is
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
   -- Algorithm sketch (OSA / restricted DL — Wikipedia recurrence)
   ---------------------------------------------------------------------------
   --  Let D(i,j) be the OSA distance between the prefixes A[1..i] and
   --  B[1..j].
   --    D(i,0) = i,   D(0,j) = j
   --    D(i,j) = min( D(i-1,j)+1,            -- delete A[i]
   --                  D(i,j-1)+1,            -- insert B[j]
   --                  D(i-1,j-1)+δ,          -- substitute / match
   --                  [optional transposition:]
   --                  D(i-2,j-2)+δ )         -- if i,j>1 and A[i]=B[j-1]
   --                                          -- and A[i-1]=B[j]
   --  where δ = 0 if A[i] = B[j], else 1. Answer is D(m,n).
   --  Unit cost for insert, delete, substitute, and adjacent transposition.
   --  OSA restriction: no substring is edited more than once (unlike
   --  unrestricted Damerau–Levenshtein). Case-sensitive Character equality;
   --  no Unicode normalization. Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Distance / Similarity
   ---------------------------------------------------------------------------

   function Distance (A, B : String) return Natural
     with Global => null;
   --  Optimal string alignment (OSA / restricted Damerau–Levenshtein)
   --  distance between A and B: the minimum number of single-character
   --  insertions, deletions, substitutions, and adjacent transpositions
   --  that transform A into B under the OSA constraint that each
   --  substring participates in at most one edit. Empty/empty → 0.
   --  Empty vs length-k → k. Symmetric. Time O(|A|·|B|); auxiliary space
   --  O(min(|A|,|B|)) via three-row DP.
   --  Raises Invalid_Argument when A'Length or B'Length > Max_Len.
   --  Contrast: ab/ba → 1 here, 2 under classical Levenshtein.
   --  Contrast: CA/ABC → 3 (OSA) vs 2 (unrestricted DL).

   function Similarity (A, B : String) return Float
     with Global => null;
   --  Normalized similarity derived from Distance:
   --    both empty → 1.0
   --    otherwise  → 1 − Distance(A,B) / max(|A|,|B|)
   --  Result lies in [0.0, 1.0]. Identical nonempty strings → 1.0.
   --  Raises Invalid_Argument when A'Length or B'Length > Max_Len.

end Damerau_Levenshtein_Distance;
