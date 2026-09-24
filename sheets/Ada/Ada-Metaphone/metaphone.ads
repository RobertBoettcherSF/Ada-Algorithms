--  Metaphone — Ada 2023 educational package for the original Metaphone
--  phonetic algorithm (Lawrence Philips, 1990): approximate English
--  pronunciation keys using the 16-consonant alphabet
--  0 B F H J K L M N P R S T W X Y (digit 0 stands for TH / theta).
--  Codes are variable length and truncated to Max_Code_Len (4).
--  Variant: original Metaphone as commonly ported (Apache Commons Codec
--  Metaphone / Brogden; not PHP Metaphone, not Double Metaphone).
--  Primary sources:
--    Lawrence Philips, "Hanging on the Metaphone", Computer Language,
--      Dec. 1990, pp. 39–43.
--    https://en.wikipedia.org/wiki/Metaphone
--  Sibling sheets (README only — do not `with`): Soundex, NYSIIS,
--  Double_Metaphone (later sheet), Levenshtein_Distance.

pragma Ada_2022;

package Metaphone
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum length of an Encode / Codes_Match input string. Metaphone
   --  itself is O(n) in the input length; the bound is pedagogical —
   --  tests stay well below Max_Len except the deliberate
   --  Invalid_Argument cases.
   Max_Len : constant Positive := 10_000;

   --  Educational truncation length used by classic ports (Apache Commons
   --  Codec default). Encode returns an unpadded code of length
   --  1 .. Max_Code_Len (shorter codes are allowed; no padding).
   Max_Code_Len : constant Positive := 4;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when:
   --    * the input string is empty (Word'Length = 0);
   --    * Word'Length > Max_Len;
   --    * after stripping non-letters, no A–Z letter remains;
   --    * after applying Metaphone rules, the code would be empty
   --      (e.g. WHY — original Metaphone / Commons yields "").
   --  Non-letter characters are otherwise ignored (educational choice).

   ---------------------------------------------------------------------------
   -- Algorithm sketch (original Metaphone / Commons Codec)
   ---------------------------------------------------------------------------
   --  Alphabet of code symbols:
   --    0 B F H J K L M N P R S T W X Y
   --    (and leading vowels A E I O U when the word starts with a vowel)
   --    Digit '0' (zero) represents TH (ASCII stand-in for theta).
   --  Steps:
   --    1. Strip non-letters; fold to upper case.
   --    2. Length-1 word → that letter (early return).
   --    3. Prefix exceptions:
   --         KN|GN|PN|AE|WR → drop first letter;
   --         X → S;  WH → W.
   --    4. Left-to-right scan (stop at Max_Code_Len code symbols):
   --         * drop adjacent duplicate letters except C;
   --         * vowels kept only if at position 0 of the working string;
   --         * B silent after M at end (…MB);
   --         * C: SCI/SCE/SCY silent; SCH→K; CIA|CH→X; CI|CE|CY→S; else K;
   --         * D: DGE|DGI|DGY→J (skip GE/GI/GY); else T;
   --         * G: silent before H at end / before consonant; silent GN|GNED;
   --           else GE|GI|GY→J; else K;
   --         * H: silent at end or after C/S/P/T/G; else kept before vowel;
   --         * K silent after C; P→F before H; Q→K; V→F; Z→S;
   --         * S: SH|SIO|SIA→X else S;
   --         * T: TIA|TIO→X; TCH silent; TH→0; else T;
   --         * W|Y kept only before a vowel; X→KS.
   --    5. Truncate to Max_Code_Len (unpadded).
   --  Consequence: John→JN; Schmidt→SKMT; Smith→SM0; howl→HL.
   --  This is NOT Double Metaphone (separate sheet).

   ---------------------------------------------------------------------------
   -- Encode / Match
   ---------------------------------------------------------------------------

   function Encode (Word : String) return String
     with Global => null;
   --  Original Metaphone code of Word. Non-letters are skipped; letters
   --  are folded to upper case. Result is an unpadded uppercase string
   --  of length 1 .. Max_Code_Len drawn from the Metaphone alphabet
   --  (including digit '0' for TH).
   --  Raises Invalid_Argument when Word is empty, longer than Max_Len,
   --  letter-free after stripping, or encodes to the empty code.

   function Codes_Match (A, B : String) return Boolean
     with Global => null;
   --  True iff Encode (A) = Encode (B). Raises Invalid_Argument when
   --  either argument would make Encode raise.

end Metaphone;
