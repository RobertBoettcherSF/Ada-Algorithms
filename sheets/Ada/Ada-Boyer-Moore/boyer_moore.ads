--  Boyer_Moore — Ada 2023 educational package for Wikipedia
--  "Boyer–Moore string-search algorithm" (Boyer & Moore, 1977).
--  Exact string search scanning each alignment window right-to-left and
--  shifting by max(bad-character, good-suffix). Average behaviour is often
--  sublinear in the text length; worst case remains O(n·m).
--  Reference: https://en.wikipedia.org/wiki/Boyer–Moore_string-search_algorithm

pragma Ada_2022;

package Boyer_Moore
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / alphabet
   ---------------------------------------------------------------------------

   --  Educational bounds (tests stay well below these).
   Max_Pattern_Length : constant Positive := 4_096;
   Max_Text_Length    : constant Positive := 100_000;

   --  Bad-character table indexes Character'Pos values.
   --  Full Latin-1 / 8-bit Character set: |Σ| = 256.
   Alphabet_Size : constant Positive := 256;

   subtype Alphabet_Index is Natural range 0 .. Alphabet_Size - 1;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for an empty pattern, or when Pattern / Text exceed the
   --  educational length bounds. Empty text with a non-empty pattern is
   --  valid and yields no matches.

   ---------------------------------------------------------------------------
   -- Result / table types
   ---------------------------------------------------------------------------

   --  1-based starting offsets into Text viewed as 1 .. Text'Length
   --  (i.e. position P means match at Text (Text'First + P - 1)).
   type Match_Index_Array is array (Positive range <>) of Positive;

   --  Bad-character (occurrence) shift: Bm_Bc (C) = distance from the last
   --  pattern character to the rightmost occurrence of character C in the
   --  pattern proper (indices 0 .. m-2). Characters absent from the pattern
   --  map to m. Used with the Lecroq adjustment
   --    bmBc[c] - m + 1 + i
   --  at mismatch index i (0-based).
   type Bad_Character_Table is array (Alphabet_Index) of Natural;

   --  Good-suffix (matching) shift: indices 0 .. m-1. Bm_Gs (I) is the
   --  shift used when the mismatch (or full match) occurs at 0-based
   --  pattern index I. Bm_Gs (0) is the period of the pattern (shift after
   --  a full match). Same table as Charras & Lecroq bmGs.
   type Good_Suffix_Array is array (Natural range <>) of Natural;

   ---------------------------------------------------------------------------
   -- Preprocess tables (exported for tests / teaching)
   ---------------------------------------------------------------------------

   function Build_Bad_Character (Pattern : String) return Bad_Character_Table
     with Global => null;
   --  O(|Σ| + m) bad-character table. Raises Invalid_Argument if Pattern
   --  is empty or longer than Max_Pattern_Length.

   function Build_Good_Suffix (Pattern : String) return Good_Suffix_Array
     with Global => null;
   --  O(m) good-suffix table, bounds 0 .. m-1. Raises Invalid_Argument if
   --  Pattern is empty or too long.

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Search (Pattern, Text : String) return Match_Index_Array
     with Global => null;
   --  Classic Boyer–Moore: preprocess bad-character and good-suffix tables,
   --  then scan windows right-to-left. On mismatch / match the window shifts
   --  by max(good-suffix, adjusted bad-character). Returns every starting
   --  position (overlapping matches included), sorted ascending. Raises
   --  Invalid_Argument if Pattern is empty or lengths exceed Max_*_Length.
   --  Empty text → empty result.

   function Naive_Search (Pattern, Text : String) return Match_Index_Array
     with Global => null;
   --  Brute-force oracle O((n−m+1)·m) for tests. Same empty-pattern /
   --  length rules as Search; empty text → empty result.

end Boyer_Moore;
