--  Bitap_Algorithm — Ada 2023 educational package for the Bitap
--  (shift-and / shift-or / Baeza-Yates–Gonnet) exact and approximate
--  string matching algorithm. Exact search uses a single bit-vector R;
--  approximate search (Wu–Manber) maintains R[0 .. K] for Levenshtein
--  distance ≤ K (insertions, deletions, substitutions). Pattern length
--  is bounded by the educational machine-word width (Unsigned_64).
--  Case-sensitive Character matching; no folding.
--  Reference: https://en.wikipedia.org/wiki/Bitap_algorithm
--  Sibling sheets (README only — do not `with`): Substring_Search,
--  Trigram_Search, Aho_Corasick.

pragma Ada_2022;

package Bitap_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Capacity bounds (educational; raise Invalid_Argument on overflow)
   ---------------------------------------------------------------------------

   --  Maximum text length accepted by every entry point.
   Max_Text_Len : constant Positive := 100_000;

   --  Maximum pattern length: educational bit-width limit for a single
   --  Interfaces.Unsigned_64 state word (bits 0 .. 62). Patterns longer
   --  than Max_Pattern_Len raise Invalid_Argument.
   Max_Pattern_Len : constant Positive := 63;

   ---------------------------------------------------------------------------
   -- Sentinel / exceptions
   ---------------------------------------------------------------------------

   --  Returned by Find_Exact / Find_Approx when no match exists.
   Not_Found : constant Integer := -1;

   Invalid_Argument : exception;
   --  Raised when Pattern is empty, Pattern'Length > Max_Pattern_Len,
   --  Text'Length > Max_Text_Len, or K > Max_Pattern_Len.

   ---------------------------------------------------------------------------
   -- Algorithm sketch
   ---------------------------------------------------------------------------
   --  Exact (shift-and): precompute Pattern_Mask[c] with bit i set iff
   --  Pattern (Pattern'First + i) = c. State R tracks which pattern
   --  prefixes match the current text suffix:
   --    R ← ((R ≪ 1) ∨ 1) ∧ Pattern_Mask[Text(j)]
   --  A hit ends at j when bit (m−1) of R is set; start = j − m + 1.
   --  Approximate (Wu–Manber): maintain R[0 .. K]; R[d] allows ≤ d edits
   --  (match / substitution / insertion / deletion). K = 0 reduces to
   --  exact. Do not `with` sibling Ada-* packages.

   ---------------------------------------------------------------------------
   -- Exact search
   ---------------------------------------------------------------------------

   function Find_Exact (Text, Pattern : String) return Integer
     with Global => null;
   --  First Ada start index of an exact occurrence of Pattern in Text
   --  (Bitap / shift-and), or Not_Found. Case-sensitive.
   --  Raises Invalid_Argument when Pattern is empty, Pattern'Length >
   --  Max_Pattern_Len, or Text'Length > Max_Text_Len.

   function Contains_Exact (Text, Pattern : String) return Boolean
     with Global => null;
   --  True iff Find_Exact (Text, Pattern) /= Not_Found.
   --  Same Invalid_Argument contract as Find_Exact.

   ---------------------------------------------------------------------------
   -- Approximate search (Levenshtein ≤ K)
   ---------------------------------------------------------------------------

   function Find_Approx
     (Text, Pattern : String;
      K             : Natural) return Integer
     with Global => null;
   --  First Ada start index of a contiguous substring of Text whose
   --  Levenshtein distance to Pattern is ≤ K (classic Wu–Manber Bitap:
   --  insertions, deletions, and substitutions). K = 0 reduces to
   --  Find_Exact. Empty Text → Not_Found. Case-sensitive.
   --  Raises Invalid_Argument when Pattern is empty, Pattern'Length >
   --  Max_Pattern_Len, Text'Length > Max_Text_Len, or K > Max_Pattern_Len.

end Bitap_Algorithm;
