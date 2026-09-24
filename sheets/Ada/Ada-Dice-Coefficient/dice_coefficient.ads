--  Dice_Coefficient — Ada 2023 educational package for the classical
--  Sørensen–Dice coefficient (Dice's coefficient) as a string metric
--  over unique character *bigram* sets. Case-sensitive; no folding.
--  Contiguous overlapping character windows of length 2; punctuation
--  and blanks are ordinary characters. Strings of length < 2 yield
--  empty bigram sets.
--  Primary source:
--  https://en.wikipedia.org/wiki/S%C3%B8rensen%E2%80%93Dice_coefficient
--  Sibling sheets (README only — do not `with`): Trigram_Search,
--  Jaro_Winkler_Distance, Levenshtein_Distance.

pragma Ada_2022;

package Dice_Coefficient
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum length of either input string. Bigram work is O(n) to
   --  extract and O(u²) to uniquify in the simple educational
   --  implementation (u ≤ n−1). The bound is pedagogical — tests stay
   --  well below Max_Len except the deliberate Invalid_Argument cases.
   Max_Len : constant Positive := 10_000;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when any input string has Length > Max_Len. Short and empty
   --  strings are valid and are handled by the documented edge-case rules
   --  (they do not raise).

   ---------------------------------------------------------------------------
   -- Algorithm sketch
   ---------------------------------------------------------------------------
   --  Character bigrams of S are the overlapping windows
   --    S(i .. i+1)  for i = S'First .. S'Last − 1
   --  (zero windows when S'Length < 2). This package prefers *unique*
   --  bigram *sets* T_S (educational / Dice string-metric standard):
   --  duplicates from repeated windows collapse to one set element.
   --  Shared_Bigrams and Coefficient therefore use set cardinality, not
   --  multiset counts.
   --  Dice / Sørensen–Dice over sets:
   --    DSC(A,B) = 2 |T_A ∩ T_B| / (|T_A| + |T_B|)
   --  Related to Jaccard index J = |T_A ∩ T_B| / |T_A ∪ T_B|:
   --    DSC = 2J / (1 + J)   (when defined).
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Counts
   ---------------------------------------------------------------------------

   function Bigram_Count (S : String) return Natural
     with Global => null;
   --  Number of overlapping character bigram *occurrences*
   --  (windows): max (0, S'Length − 1). Case-sensitive; no folding.
   --  Raises Invalid_Argument when S'Length > Max_Len.

   function Unique_Bigram_Count (S : String) return Natural
     with Global => null;
   --  Cardinality |T_S| of the unique bigram set of S. Equal to
   --  Bigram_Count when every window is distinct; smaller when repeats
   --  occur (e.g. "aaa" → one unique bigram "aa").
   --  Raises Invalid_Argument when S'Length > Max_Len.

   function Shared_Bigrams (A, B : String) return Natural
     with Global => null;
   --  Unique-set intersection size |T_A ∩ T_B|. Returns 0 when either
   --  string has fewer than 2 characters (empty unique sets).
   --  Raises Invalid_Argument when A'Length or B'Length > Max_Len.

   ---------------------------------------------------------------------------
   -- Similarity
   ---------------------------------------------------------------------------

   function Coefficient (A, B : String) return Float
     with Global => null;
   --  Sørensen–Dice coefficient over unique character-bigram sets:
   --    2 |T_A ∩ T_B| / (|T_A| + |T_B|)
   --  Edge cases (evaluated before / with the formula):
   --    • both empty (A'Length = 0 and B'Length = 0) → 1.0
   --    • one empty, or denominator |T_A|+|T_B| = 0 → 0.0
   --      (includes two length-<2 nonempty strings whose bigram sets
   --      are both empty, e.g. "a" vs "b")
   --  Otherwise the formula applies; result is in [0.0, 1.0].
   --  Identical strings of length ≥ 2 → 1.0. Case-sensitive.
   --  Raises Invalid_Argument when A'Length or B'Length > Max_Len.

end Dice_Coefficient;
