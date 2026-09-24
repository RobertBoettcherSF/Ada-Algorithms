--  Substring_Search — Ada 2023 educational survey of exact single-pattern
--  string-searching algorithms (Wikipedia "String-searching algorithm").
--  Thin self-contained sketches of Naive, Knuth–Morris–Pratt (LPS),
--  Rabin–Karp (rolling hash + verify), and Boyer–Moore–Horspool
--  (simplified BM / bad-character only). Specialized sibling repos hold
--  fuller treatments; this package does not `with` them.
--  Reference: https://en.wikipedia.org/wiki/String-searching_algorithm

pragma Ada_2022;

package Substring_Search
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / alphabet / rolling-hash defaults
   ---------------------------------------------------------------------------

   --  Educational bounds (tests stay well below these).
   Max_Pattern_Length : constant Positive := 4_096;
   Max_Text_Length    : constant Positive := 100_000;

   --  Horspool skip table indexes Character'Pos; |Σ| = 256 (Latin-1).
   Alphabet_Size : constant Positive := 256;
   subtype Alphabet_Index is Natural range 0 .. Alphabet_Size - 1;

   --  Rabin–Karp polynomial rolling hash defaults.
   Default_Base    : constant Positive := 256;
   Default_Modulus : constant Positive := 1_000_000_007;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for an empty pattern, Pattern / Text above Max_*_Length, or
   --  (Rabin–Karp) Modulus < 2. Empty text with a non-empty pattern is
   --  valid and yields no matches.

   ---------------------------------------------------------------------------
   -- Result / table / method types
   ---------------------------------------------------------------------------

   --  1-based starting offsets into Text viewed as 1 .. Text'Length
   --  (i.e. position P means match at Text (Text'First + P - 1)).
   type Match_Index_Array is array (Positive range <>) of Positive;

   --  KMP LPS / π (prefix / failure) table: LPS (I) = length of the longest
   --  proper prefix of Pattern (1 .. I) that is also a suffix. LPS (1) = 0.
   type LPS_Array is array (Positive range <>) of Natural;

   --  Horspool bad-character / skip table over the full Character alphabet.
   type Bad_Character_Table is array (Alphabet_Index) of Natural;

   --  Dispatcher method selector for Search (Pattern, Text, Method).
   type Search_Method is
     (Naive, KMP, Rabin_Karp, Boyer_Moore_Horspool);

   ---------------------------------------------------------------------------
   -- Preprocess helpers (exported for teaching / unit tests)
   ---------------------------------------------------------------------------

   function Build_LPS (Pattern : String) return LPS_Array
     with Global => null;
   --  O(m) LPS / π table for Knuth–Morris–Pratt.
   --  Raises Invalid_Argument if Pattern is empty or too long.

   function Build_Bad_Character (Pattern : String) return Bad_Character_Table
     with Global => null;
   --  O(|Σ| + m) Horspool skip table. Raises Invalid_Argument if Pattern
   --  is empty or longer than Max_Pattern_Length.

   ---------------------------------------------------------------------------
   -- Exact single-pattern searchers
   ---------------------------------------------------------------------------

   function Naive_Search (Pattern, Text : String) return Match_Index_Array
     with Global => null;
   --  Brute-force O((n−m+1)·m): try every alignment. Oracle for the rest.
   --  Overlapping matches included, sorted ascending. Empty pattern →
   --  Invalid_Argument; empty text → empty result.

   function KMP_Search (Pattern, Text : String) return Match_Index_Array
     with Global => null;
   --  Knuth–Morris–Pratt: Build_LPS then scan left-to-right. Text index
   --  only advances; on mismatch the pattern index falls back via LPS.
   --  Total O(n+m). Same empty-pattern / result contract as Naive_Search.

   function Rabin_Karp_Search
     (Pattern, Text : String;
      Base          : Positive := Default_Base;
      Modulus       : Positive := Default_Modulus)
      return Match_Index_Array
     with Global => null;
   --  Rabin–Karp: polynomial rolling hash filter, then character-by-character
   --  verify (no false positives). Average O(n+m); worst O(nm) on collisions.
   --  Raises Invalid_Argument if Pattern empty, lengths exceed Max_*, or
   --  Modulus < 2.

   function Boyer_Moore_Horspool_Search
     (Pattern, Text : String) return Match_Index_Array
     with Global => null;
   --  Horspool (simplified Boyer–Moore): bad-character skip only; compare
   --  right-to-left; after every attempt shift by Bm_Bc of the text char
   --  under the last pattern position. Average sublinear; worst O(nm).

   ---------------------------------------------------------------------------
   -- Optional dispatcher
   ---------------------------------------------------------------------------

   function Search
     (Pattern, Text : String;
      Method        : Search_Method := Naive) return Match_Index_Array
     with Global => null;
   --  Dispatch to Naive_Search / KMP_Search / Rabin_Karp_Search /
   --  Boyer_Moore_Horspool_Search. All methods share the same result
   --  contract (1-based starts, overlapping hits, empty pattern raises).

end Substring_Search;
