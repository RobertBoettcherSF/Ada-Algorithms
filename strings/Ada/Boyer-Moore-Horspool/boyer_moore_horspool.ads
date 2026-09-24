--  Boyer_Moore_Horspool — Ada 2023 educational package for Wikipedia
--  "Boyer–Moore–Horspool algorithm" (Horspool, 1980; also called Simplified
--  Boyer–Moore / SBM). Exact string search that retains only the
--  bad-character shift of Boyer–Moore: after each attempt the window
--  advances by the shift keyed on the text character aligned under the
--  *last* pattern character. No good-suffix table.
--  Reference: https://en.wikipedia.org/wiki/Boyer–Moore–Horspool_algorithm

pragma Ada_2022;

package Boyer_Moore_Horspool
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / alphabet
   ---------------------------------------------------------------------------

   --  Educational bounds (tests stay well below these).
   Max_Pattern_Length : constant Positive := 4_096;
   Max_Text_Length    : constant Positive := 100_000;

   --  Bad-character / skip table indexes Character'Pos values.
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

   --  Horspool skip (bad-character) table: Bm_Bc (C) is the distance from
   --  the last pattern character to the rightmost occurrence of C in the
   --  pattern proper (indices 0 .. m-2). Characters absent from that
   --  prefix map to m. After every attempt (match or mismatch) the window
   --  advances by Bm_Bc (Text character under the last pattern position).
   type Bad_Character_Table is array (Alphabet_Index) of Natural;

   ---------------------------------------------------------------------------
   -- Preprocess table (exported for tests / teaching)
   ---------------------------------------------------------------------------

   function Build_Bad_Character (Pattern : String) return Bad_Character_Table
     with Global => null;
   --  O(|Σ| + m) Horspool skip table. Raises Invalid_Argument if Pattern
   --  is empty or longer than Max_Pattern_Length.

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Search (Pattern, Text : String) return Match_Index_Array
     with Global => null;
   --  Boyer–Moore–Horspool: preprocess the skip table, then scan windows
   --  (compare right-to-left). On every attempt — match or mismatch —
   --  shift by Bm_Bc of the text character aligned under the last pattern
   --  character. Returns every starting position (overlapping matches
   --  included), sorted ascending. Raises Invalid_Argument if Pattern is
   --  empty or lengths exceed Max_*_Length. Empty text → empty result.

   function Naive_Search (Pattern, Text : String) return Match_Index_Array
     with Global => null;
   --  Brute-force oracle O((n−m+1)·m) for tests. Same empty-pattern /
   --  length rules as Search; empty text → empty result.

end Boyer_Moore_Horspool;
