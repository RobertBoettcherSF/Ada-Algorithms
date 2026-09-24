--  Double_Metaphone — Ada 2023 educational package for Lawrence Philips'
--  Double Metaphone (C/C++ Users Journal, June 2000): approximate phonetic
--  keys with a primary and an optional alternate code (truncate to 4).
--  Accounts for English spelling irregularities of Slavic, Germanic,
--  Celtic, Greek, French, Italian, Spanish, Chinese, and other origins.
--  Variant: Apache Commons Codec DoubleMetaphone semantics (educational).
--  Primary sources:
--    Lawrence Philips, "The Double Metaphone Search Algorithm",
--      C/C++ Users Journal, June 2000.
--    https://en.wikipedia.org/wiki/Metaphone (Double Metaphone section)
--  Sibling sheets (README only — do not `with`): Metaphone (original),
--  Soundex, NYSIIS, Levenshtein_Distance.

pragma Ada_2022;

package Double_Metaphone
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum length of an Encode / Codes_Match input string. Double
   --  Metaphone itself is O(n) in the input length; the bound is
   --  pedagogical — tests stay well below Max_Len except the deliberate
   --  Invalid_Argument cases.
   Max_Len : constant Positive := 10_000;

   --  Educational truncation length used by classic ports (Apache Commons
   --  Codec default). Each key is truncated to Max_Code_Len (unpadded).
   Max_Code_Len : constant Positive := 4;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when:
   --    * the input string is empty (Word'Length = 0);
   --    * Word'Length > Max_Len;
   --    * after folding / cleaning, no A–Z letter remains.
   --  Non-letter characters other than space are ignored in the working
   --  buffer (spaces are kept so VAN / VON / SAN patterns work). Digit
   --  '0' may appear in codes (TH → 0).

   ---------------------------------------------------------------------------
   -- Result type
   ---------------------------------------------------------------------------

   --  Primary is always set (Primary_Length in 1 .. Max_Code_Len).
   --  Alternate_Length may equal Primary_Length with the same characters
   --  (no alternate divergence), or differ; when Alternate_Length = 0 the
   --  alternate is empty (rare; Commons usually fills both in parallel).
   --  Primary / Alternate fields are blank-padded past their Length fields;
   --  callers should use the Length fields or the Primary / Alternate
   --  functions (which return unpadded slices).
   type Codes is record
      Primary           : String (1 .. Max_Code_Len) := [others => ' '];
      Alternate         : String (1 .. Max_Code_Len) := [others => ' '];
      Primary_Length    : Natural := 0;
      Alternate_Length  : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Algorithm sketch (Double Metaphone / Commons Codec)
   ---------------------------------------------------------------------------
   --  1. Trim, fold letters to upper case; keep spaces; drop other
   --     non-letters (educational). Require ≥1 A–Z letter.
   --  2. Silent-start skip: GN|KN|PN|WR|PS → begin at index 1.
   --  3. Slavo-Germanic flag: contains W|K|CZ|WITZ.
   --  4. Left-to-right scan until both keys reach Max_Code_Len:
   --       vowels → leading 'A' only; B→P; Ç→S; C/CH/CC/… complex;
   --       D/DG→J|TK|T; F; G/GH/GN/…; H between vowels; J (Jose/San);
   --       K; L (Spanish LL); M (UMB); N; Ñ→N; P/PH→F; Q→K;
   --       R (French silent); S/SH/SC/…; T/TH→0|T; V→F; W/WH/WR;
   --       X→S|KS; Z/ZH→J|S|TS.
   --  5. Truncate each key to Max_Code_Len (unpadded).
   --  Consequence: Smith→SM0/XMT; Schmidt→XMT/SMT (share XMT);
   --  Jose→HS; jumped→JMPT/AMPT; The→0/T.

   ---------------------------------------------------------------------------
   -- Encode / Match
   ---------------------------------------------------------------------------

   function Encode (Word : String) return Codes
     with Global => null;
   --  Double Metaphone primary and alternate keys of Word. Non-letters
   --  other than space are skipped; letters are folded to upper case.
   --  Primary always has length 1 .. Max_Code_Len. Alternate may equal
   --  primary when there is no divergence.
   --  Raises Invalid_Argument when Word is empty, longer than Max_Len,
   --  or letter-free after cleaning.

   function Primary (Word : String) return String
     with Global => null;
   --  Unpadded primary key (length 1 .. Max_Code_Len). Same exceptions.

   function Alternate (Word : String) return String
     with Global => null;
   --  Unpadded alternate key (length 0 .. Max_Code_Len). Empty string when
   --  Alternate_Length = 0. Same exceptions as Encode.

   function Codes_Match (A, B : String) return Boolean
     with Global => null;
   --  True iff any key of A equals any key of B (primary/alternate cross
   --  product, ignoring empty alternate). So Smith matches Schmidt via
   --  shared XMT. Raises Invalid_Argument when either argument would make
   --  Encode raise.

end Double_Metaphone;
