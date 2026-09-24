--  Zhu_Takaoka — Ada 2023 educational package for Wikipedia
--  "Zhu–Takaoka string matching algorithm" (Zhu & Takaoka, 1987).
--  Boyer–Moore variant: digram (two-character) bad-character shift table
--  ZT[a][b] plus classic good-suffix shifts. Faster average search on small
--  alphabets / short patterns; digram table is O(|Σ|²) to build and store.
--  Reference: http://www-igm.univ-mlv.fr/~lecroq/string/node20.html

pragma Ada_2022;

package Zhu_Takaoka
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / alphabet
   ---------------------------------------------------------------------------

   --  Educational bounds (tests stay well below these).
   Max_Pattern_Length : constant Positive := 4_096;
   Max_Text_Length    : constant Positive := 100_000;

   --  Digram bad-character table indexes Character'Pos values.
   --  Full Latin-1 / 8-bit Character set: |Σ| = 256 → 256×256 entries.
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
   -- Result type
   ---------------------------------------------------------------------------

   --  1-based starting offsets into Text viewed as 1 .. Text'Length
   --  (i.e. position P means match at Text (Text'First + P - 1)).
   type Match_Index_Array is array (Positive range <>) of Positive;

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Search (Pattern, Text : String) return Match_Index_Array
     with Global => null;
   --  Zhu–Takaoka: preprocess digram ZT and good-suffix tables, then scan
   --  windows right-to-left. Returns every starting position (overlapping
   --  matches included), sorted ascending. Raises Invalid_Argument if
   --  Pattern is empty or lengths exceed Max_*_Length.

   function Naive_Search (Pattern, Text : String) return Match_Index_Array
     with Global => null;
   --  Brute-force oracle O((n−m+1)·m) for tests. Same empty-pattern /
   --  length rules as Search; empty text → empty result.

end Zhu_Takaoka;
