--  Rabin_Karp — Ada 2023 educational package for Wikipedia
--  "Rabin–Karp algorithm" (Karp & Rabin, 1987).
--  Exact string search via a polynomial rolling hash over a prime modulus:
--  filter candidate windows by hash equality, then verify character-by-character
--  so results never include false positives from hash collisions.
--  Reference: https://en.wikipedia.org/wiki/Rabin–Karp_algorithm

pragma Ada_2022;

package Rabin_Karp
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity / rolling-hash defaults
   ---------------------------------------------------------------------------

   --  Educational bounds (tests stay well below these).
   Max_Pattern_Length : constant Positive := 4_096;
   Max_Text_Length    : constant Positive := 100_000;

   --  Polynomial rolling hash: treat each window as a base-B number mod Q.
   --  B = 256 matches the 8-bit Character alphabet; Q is a large prime so
   --  accidental collisions are rare (still verified by exact compare).
   Default_Base    : constant Positive := 256;
   Default_Modulus : constant Positive := 1_000_000_007;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for an empty pattern, Pattern / Text above Max_*_Length, or
   --  Modulus < 2. Empty text with a non-empty pattern is valid and yields
   --  no matches.

   ---------------------------------------------------------------------------
   -- Result type
   ---------------------------------------------------------------------------

   --  1-based starting offsets into Text viewed as 1 .. Text'Length
   --  (i.e. position P means match at Text (Text'First + P - 1)).
   type Match_Index_Array is array (Positive range <>) of Positive;

   ---------------------------------------------------------------------------
   -- Search
   ---------------------------------------------------------------------------

   function Search
     (Pattern, Text : String;
      Base          : Positive := Default_Base;
      Modulus       : Positive := Default_Modulus)
      return Match_Index_Array
     with Global => null;
   --  Rabin–Karp: compute pattern hash H_p, then slide a window of length m
   --  across Text updating the window hash in O(1) via
   --    H ← ((H − T[i]·B^(m−1)) · B + T[i+m]) mod Q
   --  On each hash hit, compare characters exactly (no false positives in
   --  the returned array). Overlapping matches included, sorted ascending.
   --  Raises Invalid_Argument if Pattern is empty, lengths exceed Max_*,
   --  or Modulus < 2.

   function Naive_Search (Pattern, Text : String) return Match_Index_Array
     with Global => null;
   --  Brute-force oracle O((n−m+1)·m) for tests. Same empty-pattern /
   --  length rules as Search; empty text → empty result.

end Rabin_Karp;
