--  Phonetic_Algorithms — Ada 2023 educational *survey* of classical
--  phonetic name encodings: American Soundex, original NYSIIS, original
--  Metaphone, and Match Rating Approach (MRA) encoding. Self-contained
--  inline implementations — there is **no** `with` of sibling Ada-*
--  packages. Double Metaphone and Daitch–Mokotoff Soundex are named in
--  the README only (dedicated sibling sheets).
--  Primary source: https://en.wikipedia.org/wiki/Phonetic_algorithm
--  Sibling sheets (README only — do not `with`): Soundex, NYSIIS,
--  Metaphone, Match_Rating_Approach, Double_Metaphone,
--  Daitch_Mokotoff_Soundex.

pragma Ada_2022;

package Phonetic_Algorithms
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum length of an input string for every encoder. Each encoder
   --  is O(n) in the input length; the bound is pedagogical — tests stay
   --  well below Max_Len except the deliberate Invalid_Argument cases.
   Max_Len : constant Positive := 10_000;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when:
   --    * the input string is empty (Length = 0);
   --    * Length > Max_Len;
   --    * after stripping non-letters, no A–Z letter remains;
   --    * Metaphone would produce an empty code (e.g. WHY).
   --  Non-letter characters are otherwise ignored (educational choice).

   ---------------------------------------------------------------------------
   -- Survey sketch
   ---------------------------------------------------------------------------
   --  Phonetic algorithms map similar-sounding names to shared keys for
   --  approximate matching / indexing. This mini-suite keeps each encoder
   --  correct but scoped (truncation limits as classically published).
   --  Implementations are educational and self-contained — do not `with`
   --  sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Encoders
   ---------------------------------------------------------------------------

   function Soundex (Name : String) return String
     with Global => null;
   --  American Soundex / NARA / Wikipedia: always exactly 4 characters
   --  (one uppercase letter + three digits '0'..'6', right-padded with
   --  '0'). H/W do not reset Prev (Ashcraft → A261). Non-letters skipped;
   --  letters folded to upper case. Raises Invalid_Argument when Name is
   --  empty, longer than Max_Len, or letter-free after stripping.

   function NYSIIS (Name : String) return String
     with Global => null;
   --  Original / strict Taft NYSIIS (Apache Commons Codec style),
   --  truncated to at most 6 characters, unpadded. Trailing cleanup
   --  never drops the first key letter (Ash → A). Raises
   --  Invalid_Argument when Name is empty, overlong, or letter-free.

   function Metaphone (Word : String) return String
     with Global => null;
   --  Original Lawrence Philips Metaphone (Commons Codec / Brogden),
   --  truncated to at most 4 code symbols, unpadded. Digit '0' stands
   --  for TH (theta). Not Double Metaphone. Raises Invalid_Argument when
   --  Word is empty, overlong, letter-free, or encodes to empty.

   function Match_Rating_Encode (Name : String) return String
     with Global => null;
   --  Western Airlines / Wikipedia MRA codex: strip non-letters, drop
   --  vowels (keep leading vowel), collapse adjacent duplicates, then
   --  keep first 3 + last 3 when longer than 6. Unpadded length 1..6.
   --  Raises Invalid_Argument when Name is empty, overlong, or
   --  letter-free. Full MRA similarity comparison lives in the dedicated
   --  Match_Rating_Approach sibling (README only).

   ---------------------------------------------------------------------------
   -- Equality helpers
   ---------------------------------------------------------------------------

   function Codes_Match_Soundex (A, B : String) return Boolean
     with Global => null;
   --  True iff Soundex (A) = Soundex (B). Raises Invalid_Argument when
   --  either argument would make Soundex raise.

   function Codes_Match_NYSIIS (A, B : String) return Boolean
     with Global => null;
   --  True iff NYSIIS (A) = NYSIIS (B). Raises Invalid_Argument when
   --  either argument would make NYSIIS raise.

   function Codes_Match_Metaphone (A, B : String) return Boolean
     with Global => null;
   --  True iff Metaphone (A) = Metaphone (B). Raises Invalid_Argument
   --  when either argument would make Metaphone raise.

end Phonetic_Algorithms;
