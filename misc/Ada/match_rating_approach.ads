--  Match Rating Approach (MRA) — Ada 2023 educational package for the
--  Western Airlines (1977) phonetic algorithm for indexing and comparing
--  homophonous names. Produces an alphabetic personal numeric identifier
--  (PNI / codex) of at most 6 letters, plus a length-aware similarity
--  comparison against a minimum rating table.
--  Variant: Wikipedia / Western Airlines encoding and comparison; adjacent
--  duplicate consonant collapse (clearest reading of "remove the second
--  consonant of any double consonants"); Apache Commons Codec comparison
--  L→R / R→L position scrub used as the concrete similarity procedure
--  (matches the published Byrne/Boern, Smith/Smyth, Catherine/Kathryn
--  ratings).
--  Primary source: https://en.wikipedia.org/wiki/Match_rating_approach
--  Sibling sheets (README only — do not `with`): Soundex, NYSIIS,
--  Metaphone, Levenshtein_Distance.

pragma Ada_2022;

package Match_Rating_Approach
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum length of an Encode / Compare / Similarity_Rating input
   --  string. MRA itself is O(n) in the input length; the bound is
   --  pedagogical — tests stay well below Max_Len except the deliberate
   --  Invalid_Argument cases.
   Max_Len : constant Positive := 10_000;

   --  Encoded codex never exceeds this many alphabetic characters
   --  (first 3 + last 3 when the intermediate encoding is longer).
   Max_Code_Len : constant Positive := 6;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when:
   --    * the input string is empty (Name'Length = 0);
   --    * Name'Length > Max_Len;
   --    * after stripping non-letters, no A–Z letter remains.
   --  Non-letter characters are otherwise ignored (educational choice).

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Western Airlines / Wikipedia MRA)
   ---------------------------------------------------------------------------
   --  Encoding (codex / PNI):
   --    1. Strip non-letters; fold to upper case.
   --    2. Delete all vowels {A,E,I,O,U} unless the vowel begins the word
   --       (Y is NOT a vowel — kept as a consonant).
   --    3. Collapse adjacent duplicate letters (double consonants).
   --    4. If length > 6, keep first 3 and last 3 characters only.
   --  Comparison of two encodings EA, EB:
   --    1. If |len(EA) - len(EB)| >= 3 → no match (rating treated as 0).
   --    2. Minimum rating from sum = len(EA)+len(EB) (Table A):
   --         sum <= 4          → 5
   --         4 < sum <= 7      → 4
   --         7 < sum <= 11     → 3
   --         sum = 12          → 2
   --         sum > 12          → 1  (unreachable for Max_Code_Len=6)
   --    3. Similarity: scrub identical characters at the same offset from
   --       the left and from the right (Commons L→R / R→L procedure);
   --       rating = 6 - (length of the longer residual string).
   --    4. Match iff rating >= minimum rating.
   --  Classic: Byrne/Boern → BYRN/BRN rating 5 >= 4; Smith/Smyth →
   --  SMTH/SMYTH rating 5 >= 3; Catherine/Kathryn → CTHRN/KTHRYN
   --  rating 4 >= 3.

   ---------------------------------------------------------------------------
   -- Encode / Compare / Similarity
   ---------------------------------------------------------------------------

   function Encode (Name : String) return String
     with Global => null;
   --  MRA codex of Name. Non-letters are skipped; letters are folded to
   --  upper case. Result is an unpadded uppercase alphabetic string of
   --  length 1 .. Max_Code_Len.
   --  Raises Invalid_Argument when Name is empty, longer than Max_Len,
   --  or contains no A–Z letter.

   function Similarity_Rating (A, B : String) return Natural
     with Global => null;
   --  MRA similarity rating of Encode(A) vs Encode(B): 6 minus the
   --  unmatched residual length in the longer encoding after L→R/R→L
   --  scrubbing. Returns 0 when the encoded length difference is >= 3
   --  (comparison skipped). Raises Invalid_Argument when either argument
   --  would make Encode raise.

   function Compare (A, B : String) return Boolean
     with Global => null;
   --  True iff the MRA similarity rating of A and B is greater than or
   --  equal to the Table-A minimum for the sum of the encoded lengths
   --  (and the encoded length difference is < 3). Raises
   --  Invalid_Argument when either argument would make Encode raise.

   function Minimum_Rating (Sum_Length : Natural) return Natural
     with Global => null;
   --  Table A lookup: minimum similarity rating required for a given
   --  sum of encoded lengths. Exposed for documentation and tests.

end Match_Rating_Approach;
