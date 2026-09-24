--  String_Metrics — Ada 2023 educational *survey* of classical string
--  distance / similarity functions. Self-contained implementations of
--  Levenshtein, restricted Damerau–Levenshtein (OSA), Hamming,
--  Jaro–Winkler similarity, Sørensen–Dice (unique character bigrams),
--  and a normalized Levenshtein similarity helper.
--  Case-sensitive Character equality; no Unicode normalization.
--  Primary source: https://en.wikipedia.org/wiki/String_metric
--  Sibling sheets (README only — do not `with`): Levenshtein_Distance,
--  Damerau_Levenshtein_Distance, Jaro_Winkler_Distance, Dice_Coefficient,
--  Trigram_Search.

pragma Ada_2022;

package String_Metrics
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum length of either input string. Classical edit-distance DP
   --  is O(m·n) time; this survey keeps Max_Len modest so full tables /
   --  rolling rows stay affordable in teaching demos. Tests stay well
   --  below Max_Len except the deliberate Invalid_Argument cases.
   Max_Len : constant Positive := 1_000;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when A'Length > Max_Len or B'Length > Max_Len, or when
   --  Hamming is called with unequal lengths. Empty strings are valid
   --  for every entry point except Hamming (empty/empty is equal length
   --  and returns 0).

   ---------------------------------------------------------------------------
   -- Survey sketch
   ---------------------------------------------------------------------------
   --  Distances (Natural) measure edit cost / disagreement count.
   --  Similarities (Float in [0,1]) measure agreement; higher is closer.
   --  Not every “string metric” in the loose sense fulfils the triangle
   --  inequality (see README). Implementations are educational and
   --  self-contained — do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Distances
   ---------------------------------------------------------------------------

   function Levenshtein (A, B : String) return Natural
     with Global => null;
   --  Classical unit-cost Levenshtein (edit) distance: minimum number of
   --  single-character insertions, deletions, and substitutions that
   --  transform A into B. Empty/empty → 0; empty vs length-k → k.
   --  Symmetric. Time O(|A|·|B|); auxiliary space O(min(|A|,|B|)).
   --  Raises Invalid_Argument when A'Length or B'Length > Max_Len.

   function Damerau_Levenshtein_OSA (A, B : String) return Natural
     with Global => null;
   --  Optimal string alignment (OSA / restricted Damerau–Levenshtein):
   --  Levenshtein plus adjacent transposition under the OSA constraint
   --  that each substring participates in at most one edit. Unit cost 1.
   --  Contrast: "ab"/"ba" → 1 here, 2 under classical Levenshtein.
   --  Raises Invalid_Argument when A'Length or B'Length > Max_Len.

   function Hamming (A, B : String) return Natural
     with Global => null;
   --  Hamming distance: number of positions at which equal-length strings
   --  differ. Requires A'Length = B'Length (including empty/empty → 0).
   --  Raises Invalid_Argument on unequal lengths or when either length
   --  exceeds Max_Len.

   ---------------------------------------------------------------------------
   -- Similarities
   ---------------------------------------------------------------------------

   function Jaro_Winkler_Similarity
     (A, B : String; P : Float := 0.1) return Float
     with Global => null;
   --  Jaro–Winkler similarity in [0.0, 1.0]: Jaro matching window
   --  floor(max(|A|,|B|)/2)−1 (clamped ≥ 0) plus Winkler common-prefix
   --  boost (prefix length capped at 4) with scale P (default 0.1).
   --  Empty/empty → 1.0; exactly one empty → 0.0; identical → 1.0.
   --  Raises Invalid_Argument when A'Length or B'Length > Max_Len.
   --  Note: Jaro–Winkler distance (1 − similarity) is not a metric in
   --  the mathematical sense (triangle inequality may fail).

   function Dice_Bigram (A, B : String) return Float
     with Global => null;
   --  Sørensen–Dice coefficient over *unique* character bigram sets:
   --    DSC = 2 |T_A ∩ T_B| / (|T_A| + |T_B|)
   --  Contiguous overlapping windows of length 2; duplicates collapse.
   --  Both empty → 1.0; either length < 2 with the other nonempty and
   --  no shared bigrams → 0.0 when the denominator is positive, else
   --  handled as documented (both length < 2 and not both empty → 0.0
   --  when unique sets are empty). Raises Invalid_Argument when either
   --  length exceeds Max_Len.

   function Normalized_Levenshtein_Similarity (A, B : String) return Float
     with Global => null;
   --  Normalized similarity derived from Levenshtein:
   --    both empty → 1.0
   --    otherwise  → 1 − Levenshtein(A,B) / max(|A|,|B|)
   --  Result in [0.0, 1.0]. Identical nonempty strings → 1.0.
   --  Raises Invalid_Argument when A'Length or B'Length > Max_Len.

end String_Metrics;
