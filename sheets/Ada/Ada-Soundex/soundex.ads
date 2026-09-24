--  Soundex — Ada 2023 educational package for the classical American
--  Soundex phonetic encoding of surnames: a letter plus three digits
--  (e.g. Robert → R163). Keeps the first A–Z letter, maps consonants to
--  digits, drops vowels / H / W / Y after the first letter, collapses
--  adjacent equal digit codes (H/W do not separate equal codes; vowels
--  and Y do), and pads with '0' to length 4.
--  Variant: American Soundex / NARA / Wikipedia (Ashcraft → A261).
--  Primary source: https://en.wikipedia.org/wiki/Soundex
--  Sibling sheets (README only — do not `with`): Levenshtein_Distance,
--  Dice_Coefficient, Jaro_Winkler_Distance, String_Metrics.

pragma Ada_2022;

package Soundex
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum length of an Encode / Codes_Match input string. Soundex
   --  itself is O(n) in the input length; the bound is pedagogical —
   --  tests stay well below Max_Len except the deliberate
   --  Invalid_Argument cases.
   Max_Len : constant Positive := 10_000;

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
   -- Result type
   ---------------------------------------------------------------------------

   subtype Code_String is String (1 .. 4);
   --  Always exactly four characters: one uppercase letter followed by
   --  three digits from the set {'0'..'6'}, padded with '0' on the right
   --  when fewer than three consonant codes are produced.

   ---------------------------------------------------------------------------
   -- Algorithm sketch (American Soundex / NARA / Wikipedia)
   ---------------------------------------------------------------------------
   --  Letter → digit map (case-insensitive):
   --    B F P V           → 1
   --    C G J K Q S X Z   → 2
   --    D T               → 3
   --    L                 → 4
   --    M N               → 5
   --    R                 → 6
   --    A E I O U H W Y   → 0  (dropped after the first letter)
   --  Steps:
   --    1. Walk Name left-to-right; ignore non A–Z characters.
   --    2. Retain the first letter (uppercased) as Code(1).
   --    3. Remember that letter's map code as Prev.
   --    4. For each later letter with map code c:
   --         * if c = 0 and letter is H or W: skip, Prev unchanged
   --           (H/W do not separate — equal codes still collapse);
   --         * if c = 0 and letter is A/E/I/O/U/Y: skip, Prev := 0
   --           (vowels/Y separate — equal codes on each side are kept);
   --         * if c = Prev: skip (adjacent duplicate);
   --         * else append digit c and set Prev := c.
   --       Stop at 3 digits.
   --    5. Pad remaining digit slots with '0'.
   --  Consequence: Ashcraft → A261 (not A226). Do not `with` siblings.

   ---------------------------------------------------------------------------
   -- Encode / Match
   ---------------------------------------------------------------------------

   function Encode (Name : String) return Code_String
     with Global => null;
   --  American Soundex code of Name. Non-letters are skipped; letters
   --  are folded to upper case. Result is always length 4.
   --  Raises Invalid_Argument when Name is empty, longer than Max_Len,
   --  or contains no A–Z letter.

   function Codes_Match (A, B : String) return Boolean
     with Global => null;
   --  True iff Encode (A) = Encode (B). Raises Invalid_Argument when
   --  either argument would make Encode raise (empty, overlong, or
   --  letter-free).

end Soundex;
