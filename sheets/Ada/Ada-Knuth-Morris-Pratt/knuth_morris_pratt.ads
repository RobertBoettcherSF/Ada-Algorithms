--  Knuth_Morris_Pratt — Ada 2023 educational package for Wikipedia
--  "Knuth–Morris–Pratt algorithm" (Knuth, Morris & Pratt, 1977).
--  Exact string search in O(n+m) using a longest-prefix-suffix (LPS /
--  π / failure) table so the text cursor never rewinds: mismatches jump
--  the pattern index via precomputed borders.
--  Reference: https://en.wikipedia.org/wiki/Knuth–Morris–Pratt_algorithm

pragma Ada_2022;

package Knuth_Morris_Pratt
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity
   ---------------------------------------------------------------------------

   --  Educational bounds (tests stay well below these).
   Max_Pattern_Length : constant Positive := 4_096;
   Max_Text_Length    : constant Positive := 100_000;

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

   --  LPS / π (prefix) table: LPS (I) = length of the longest proper
   --  prefix of Pattern (Pattern'First .. Pattern'First + I - 1) that is
   --  also a suffix of that prefix. Indexed 1 .. Pattern'Length; LPS (1)
   --  is always 0. Also called the failure function in textbooks.
   type LPS_Array is array (Positive range <>) of Natural;

   ---------------------------------------------------------------------------
   -- LPS / prefix (failure) table
   ---------------------------------------------------------------------------

   function Build_LPS (Pattern : String) return LPS_Array
     with Global => null;
   --  Preprocess Pattern into the classic non-negative LPS / π table in
   --  O(m). Raises Invalid_Argument if Pattern is empty or too long.

   function Prefix_Table (Pattern : String) return LPS_Array
     renames Build_LPS;
   --  Alias for Build_LPS (π / failure function).

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Search (Pattern, Text : String) return Match_Index_Array
     with Global => null;
   --  Knuth–Morris–Pratt: build LPS, then scan Text left-to-right. The
   --  text index only advances; on mismatch the pattern index falls back
   --  via LPS jumps (never re-reads earlier text characters). Returns
   --  every starting position (overlapping matches included), sorted
   --  ascending. Raises Invalid_Argument if Pattern is empty or lengths
   --  exceed Max_*_Length. Empty text → empty result. Total O(n+m).

   function Naive_Search (Pattern, Text : String) return Match_Index_Array
     with Global => null;
   --  Brute-force oracle O((n−m+1)·m) for tests. Same empty-pattern /
   --  length rules as Search; empty text → empty result.

end Knuth_Morris_Pratt;
