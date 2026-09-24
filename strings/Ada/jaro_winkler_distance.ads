--  Jaro_Winkler_Distance — Ada 2023 educational package for the classical
--  Jaro similarity and Jaro–Winkler similarity / distance between two
--  Character strings. Matching window floor(max(|A|,|B|)/2)−1; common
--  prefix boost capped at 4 characters with scale p (default 0.1).
--  Case-sensitive; no Unicode normalization.
--  Primary source: https://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance
--  Sibling sheets (README only — do not `with`): Levenshtein_Distance,
--  Trigram_Search, Longest_Common_Subsequence.

pragma Ada_2022;

package Jaro_Winkler_Distance
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum length of either input string. Matching / transposition
   --  passes are O(|A|·|B|) in the naive educational scan within the
   --  matching window. The bound is pedagogical — tests stay well below
   --  Max_Len except the deliberate Invalid_Argument cases.
   Max_Len : constant Positive := 10_000;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_Len or B'Length > Max_Len. Empty strings
   --  are valid and do not raise.

   ---------------------------------------------------------------------------
   -- Constants
   ---------------------------------------------------------------------------

   --  Winkler prefix scale p. Standard value from Winkler's work.
   --  Should not exceed 0.25 (otherwise similarity can exceed 1 when the
   --  common prefix reaches the cap of 4).
   Default_P : constant Float := 0.1;

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Wikipedia Jaro / Jaro–Winkler)
   ---------------------------------------------------------------------------
   --  Matching window:
   --    w = floor(max(|A|,|B|)/2) − 1
   --  For very short strings max ≤ 1 this formula yields −1; this package
   --  clamps w to max(0, ·) so identical length-1 strings still match at
   --  the same index (distance 0). Characters match only if equal and not
   --  farther than w positions apart; each character is used at most once.
   --  Transpositions t = (mismatched order among matches) / 2.
   --  Jaro similarity:
   --    sim_j = 0 if m = 0
   --    sim_j = (1/3)·(m/|A| + m/|B| + (m−t)/m) otherwise
   --  Jaro–Winkler:
   --    sim_w = sim_j + ℓ·p·(1 − sim_j)
   --  where ℓ is the common prefix length capped at 4.
   --  Distance d_w = 1 − sim_w. Case-sensitive Character equality.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Similarity / Distance
   ---------------------------------------------------------------------------

   function Jaro_Similarity (A, B : String) return Float
     with Global => null;
   --  Classical Jaro similarity in [0.0, 1.0].
   --  Empty/empty → 1.0; exactly one empty → 0.0; identical → 1.0.
   --  Raises Invalid_Argument when A'Length or B'Length > Max_Len.

   function Jaro_Winkler_Similarity
     (A, B : String; P : Float := Default_P) return Float
     with Global => null;
   --  Jaro–Winkler similarity: Jaro plus common-prefix boost
   --  (prefix length capped at 4) with scale P (default Default_P = 0.1).
   --  Empty/empty → 1.0; exactly one empty → 0.0.
   --  Raises Invalid_Argument when A'Length or B'Length > Max_Len.

   function Jaro_Winkler_Distance
     (A, B : String; P : Float := Default_P) return Float
     with Global => null;
   --  Jaro–Winkler distance = 1 − Jaro_Winkler_Similarity(A, B, P).
   --  Exact match → 0.0; empty vs nonempty → 1.0.
   --  Raises Invalid_Argument when A'Length or B'Length > Max_Len.

end Jaro_Winkler_Distance;
