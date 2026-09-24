--  Trigram_Search — Ada 2023 educational package for character trigram
--  (n-gram of size 3) extraction and approximate / fuzzy string matching
--  via unique trigram sets and the Sørensen–Dice coefficient.
--  Case-sensitive; no case folding. Contiguous overlapping character
--  windows of length 3; punctuation and blanks are ordinary characters.
--  Primary sources:
--  https://en.wikipedia.org/wiki/N-gram
--  https://en.wikipedia.org/wiki/S%C3%B8rensen%E2%80%93Dice_coefficient
--  Sibling sheets (README only — do not `with`): Substring_Search,
--  Longest_Common_Substring, Aho_Corasick.

pragma Ada_2022;

package Trigram_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum string length accepted by every entry point. Trigram work is
   --  O(n) to extract and O(u²) to uniquify in the simple educational
   --  implementation (u ≤ n−2). Tests stay well below Max_Len except the
   --  deliberate Invalid_Argument cases.
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
   --  Character trigrams of S are the overlapping windows
   --    S(i .. i+2)  for i = S'First .. S'Last − 2
   --  (zero windows when S'Length < 3). This package prefers *unique*
   --  trigram *sets* T_S (educational / Dice standard): duplicates from
   --  repeated windows collapse to one set element. Shared_Trigrams and
   --  Dice_Coefficient therefore use set cardinality, not multiset counts.
   --  Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Counts
   ---------------------------------------------------------------------------

   function Trigram_Count (S : String) return Natural
     with Global => null;
   --  Number of overlapping character trigram *occurrences*
   --  (windows): max (0, S'Length − 2). Case-sensitive; no folding.
   --  Raises Invalid_Argument when S'Length > Max_Len.

   function Unique_Trigram_Count (S : String) return Natural
     with Global => null;
   --  Cardinality |T_S| of the unique trigram set of S. Equal to
   --  Trigram_Count when every window is distinct; smaller when repeats
   --  occur (e.g. "aaa" → one unique trigram "aaa").
   --  Raises Invalid_Argument when S'Length > Max_Len.

   function Shared_Trigrams (A, B : String) return Natural
     with Global => null;
   --  Unique-set intersection size |T_A ∩ T_B|. Returns 0 when either
   --  string has fewer than 3 characters (empty unique sets).
   --  Raises Invalid_Argument when A'Length or B'Length > Max_Len.

   ---------------------------------------------------------------------------
   -- Similarity
   ---------------------------------------------------------------------------

   function Dice_Coefficient (A, B : String) return Float
     with Global => null;
   --  Sørensen–Dice coefficient over unique trigram sets:
   --    2 |T_A ∩ T_B| / (|T_A| + |T_B|)
   --  Edge cases (evaluated before the formula):
   --    • both empty (A'Length = 0 and B'Length = 0) → 1.0
   --    • either string has Length < 3 (including one empty) → 0.0
   --  Otherwise the formula applies; result is in [0.0, 1.0].
   --  Identical strings of length ≥ 3 → 1.0. Case-sensitive.
   --  Raises Invalid_Argument when A'Length or B'Length > Max_Len.

   ---------------------------------------------------------------------------
   -- Fuzzy containment / membership
   ---------------------------------------------------------------------------

   function Contains_Trigram (Haystack, Needle : String) return Boolean
     with Global => null;
   --  Educational fuzzy containment: True iff every unique trigram of
   --  Needle appears in the unique trigram set of Haystack
   --  (T_Needle ⊆ T_Haystack). When Needle'Length < 3 the unique set is
   --  empty, so the result is True (vacuous subset). When Needle has
   --  trigrams but Haystack'Length < 3, the result is False.
   --  Raises Invalid_Argument when either length exceeds Max_Len.

   function Has_Trigram (Haystack : String; Tri : String) return Boolean
     with Global => null;
   --  True iff Tri is a length-3 string that occurs as a contiguous
   --  substring of Haystack (i.e. Tri ∈ T_Haystack). Raises
   --  Invalid_Argument when Haystack'Length > Max_Len, or when
   --  Tri'Length /= 3.

end Trigram_Search;
