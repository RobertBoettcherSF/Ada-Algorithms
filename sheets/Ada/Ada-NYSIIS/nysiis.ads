--  NYSIIS — Ada 2023 educational package for the New York State
--  Identification and Intelligence System phonetic encoding of surnames
--  (Robert L. Taft, 1970). Maps similar-sounding names to the same
--  alphabetic key (e.g. Bishop → BASAP, Willis → WAL), truncated to at
--  most Max_Code_Len characters (original algorithm: 6).
--  Variant: original / strict NYSIIS as commonly implemented (Apache
--  Commons Codec Nysiis; dropby.com / Wikipedia Taft steps), with the
--  documented fix that trailing cleanup never drops the first key letter
--  (Ash → A; cf. CODEC-308).
--  Primary source: https://en.wikipedia.org/wiki/New_York_State_Identification_and_Intelligence_System
--  Sibling sheets (README only — do not `with`): Soundex,
--  Levenshtein_Distance, Dice_Coefficient, Jaro_Winkler_Distance.

pragma Ada_2022;

package NYSIIS
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum length of an Encode / Codes_Match input string. NYSIIS
   --  itself is O(n) in the input length; the bound is pedagogical —
   --  tests stay well below Max_Len except the deliberate
   --  Invalid_Argument cases.
   Max_Len : constant Positive := 10_000;

   --  Original Taft / strict NYSIIS truncates the key to this many
   --  characters. Encode returns an unpadded code of length 1 ..
   --  Max_Code_Len.
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
   -- Algorithm sketch (original / strict NYSIIS)
   ---------------------------------------------------------------------------
   --  Case-insensitive; non-letters are stripped first. Then:
   --    1. Prefix: MAC→MCC; KN→NN; K→C; PH|PF→FF; SCH→SSS
   --       (applied in that order; first match wins per pattern).
   --    2. Suffix: EE|IE→Y; DT|RT|RD|NT|ND→D
   --    3. Key starts with the (possibly rewritten) first letter.
   --    4. Scan remaining letters (sliding window), rewriting in place:
   --         EV→AF; else vowels→A; Q→G; Z→S; M→N;
   --         KN→NN else K→C; SCH→SSS; PH→FF;
   --         H→previous if previous or next is non-vowel;
   --         W→previous if previous is vowel;
   --       Append rewritten letter to the key iff it differs from the
   --       previous (rewritten) name letter (adjacent duplicates drop).
   --    5. If last key letter is S, remove it (never drop the first).
   --    6. If last two key letters are AY, replace with Y.
   --    7. If last key letter is A, remove it (never drop the first).
   --    8. Truncate to Max_Code_Len.
   --  Y is not treated as a vowel. Vowels = {A,E,I,O,U}.
   --  Consequence: Macintosh → MCANT; Ash → A; Westerlund → WASTAR.

   ---------------------------------------------------------------------------
   -- Encode / Match
   ---------------------------------------------------------------------------

   function Encode (Name : String) return String
     with Global => null;
   --  Original / strict NYSIIS code of Name. Non-letters are skipped;
   --  letters are folded to upper case. Result is an unpadded uppercase
   --  alphabetic string of length 1 .. Max_Code_Len.
   --  Raises Invalid_Argument when Name is empty, longer than Max_Len,
   --  or contains no A–Z letter.

   function Codes_Match (A, B : String) return Boolean
     with Global => null;
   --  True iff Encode (A) = Encode (B). Raises Invalid_Argument when
   --  either argument would make Encode raise (empty, overlong, or
   --  letter-free).

end NYSIIS;
