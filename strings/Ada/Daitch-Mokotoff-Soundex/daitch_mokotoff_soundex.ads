--  Daitch_Mokotoff_Soundex — Ada 2023 educational package for the
--  Daitch–Mokotoff Soundex (D–M Soundex) phonetic encoding of surnames:
--  six digits, zero-padded, with multi-character n-gram rules and
--  branching alternate mappings (e.g. Peters → 734000|739400).
--  Variant: Apache Commons Codec DaitchMokotoffSoundex / JewishGen table.
--  Primary sources:
--    https://en.wikipedia.org/wiki/Daitch–Mokotoff_Soundex
--    JewishGen Soundex Coding / Avotaynu (Mokotoff)
--    Apache Commons Codec dmrules.txt (educational rule table)
--  Sibling sheets (README only — do not `with`): Soundex, Double_Metaphone,
--  Metaphone, NYSIIS, Levenshtein_Distance.

pragma Ada_2022;

package Daitch_Mokotoff_Soundex
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum length of an Encode / Codes_Match input string. D–M Soundex
   --  itself is O(n · B) in the input length and branch count; the bound is
   --  pedagogical — tests stay well below Max_Len except the deliberate
   --  Invalid_Argument cases.
   Max_Len : constant Positive := 10_000;

   --  DM codes are always exactly six digit characters, zero-padded.
   Code_Length : constant := 6;

   --  Upper bound on branching alternate encodings retained for one name.
   --  Commons / Wikipedia examples stay ≤ 10; 16 leaves headroom for
   --  educational multi-branch surnames without unbounded growth.
   Max_Codes : constant Positive := 16;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when:
   --    * the input string is empty (Name'Length = 0);
   --    * Name'Length > Max_Len;
   --    * after stripping non-letters (and optional Latin-1 folding), no
   --      A–Z letter remains.
   --  Non-letter characters are otherwise ignored (spaces, hyphens,
   --  punctuation, digits) — multi-word surnames are coded as one word
   --  (e.g. "Ben Aron" → Benaron).

   ---------------------------------------------------------------------------
   -- Result types
   ---------------------------------------------------------------------------

   subtype Code_String is String (1 .. Code_Length);
   --  Always exactly six characters from {'0'..'9'}, right-padded with '0'
   --  when fewer than six coded digits are produced.

   type Code_List is array (Positive range <>) of Code_String;
   --  One or more distinct 6-digit codes in discovery order (primary first).
   --  Length is in 1 .. Max_Codes.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (D–M / Commons Codec / JewishGen)
   ---------------------------------------------------------------------------
   --  1. Strip non-letters; fold Latin-1 accents to ASCII where mapped;
   --     fold letters to lower case for matching. Require ≥1 letter.
   --  2. Left-to-right longest-match against the coding table (multi-char
   --     n-grams like SCH, TSH, RS first). Context columns:
   --       start-of-name / before-vowel (AEIOU) / other.
   --  3. Empty replacement = not coded (NC); still updates the previous
   --     replacement token so the next digit is not collapsed against the
   --     earlier one.
   --  4. Adjacent identical replacement strings collapse, except MN/NM
   --     which force both digits (Kleinmann → 586660).
   --  5. Branching letters (C, CH, CK, J, RS, RZ, …) fork alternate codes;
   --     Primary_Encode keeps the first branch only.
   --  6. Pad each code with trailing '0' to length 6.
   --  Consequence: Peters → 734000|739400; Moskowitz = Moskovitz → 645740;
   --  Auerbach → 097400|097500.

   ---------------------------------------------------------------------------
   -- Encode / Match
   ---------------------------------------------------------------------------

   function Encode (Name : String) return Code_List
     with Global => null;
   --  All D–M Soundex codes of Name (branching enabled), length 1 ..
   --  Max_Codes, primary first. Non-letters skipped; letters folded.
   --  Raises Invalid_Argument when Name is empty, longer than Max_Len, or
   --  letter-free after cleaning.

   function Primary_Encode (Name : String) return Code_String
     with Global => null;
   --  First / primary 6-digit code (branching disabled — first alternate
   --  mapping at each fork). Same exceptions as Encode.

   function Codes_Match (A, B : String) return Boolean
     with Global => null;
   --  True iff any code of A equals any code of B (cross product of
   --  Encode (A) and Encode (B)). Raises Invalid_Argument when either
   --  argument would make Encode raise.

end Daitch_Mokotoff_Soundex;
