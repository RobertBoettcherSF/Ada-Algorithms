--  Krauss_Matching_Wildcards — Ada 2023 educational package for the
--  Krauss wildcard-matching algorithm (Windows / glob style).
--  Non-recursive pointer/bookmark matching of patterns containing
--  '*' (any sequence) and '?' (exactly one character).
--  Primary source:
--  https://en.wikipedia.org/wiki/Krauss_matching_wildcards_algorithm

pragma Ada_2022;

package Krauss_Matching_Wildcards
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   --  Reserved for malformed patterns. Under the Windows/glob grammar used
   --  here every Pattern is well-formed (no escapes, no character classes),
   --  so Match never raises Invalid_Argument.
   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Matching (case-sensitive)
   ---------------------------------------------------------------------------

   --  True iff Text matches Pattern under Windows/glob wildcard rules:
   --    '*'  matches any sequence of zero or more characters (greedy via
   --         linear bookmark backtracking, not exponential recursion);
   --    '?'  matches exactly one character;
   --    any other character matches itself literally (case-sensitive).
   --  Empty Pattern matches only empty Text (documented choice; not POSIX
   --  fnmatch empty-pattern quirks). Consecutive '*' are collapsed by the
   --  bookmark logic and behave as a single '*'.
   function Match (Pattern, Text : String) return Boolean
     with Global => null;

   --  Alias for Match (API convenience).
   function Is_Match (Pattern, Text : String) return Boolean
     renames Match;

end Krauss_Matching_Wildcards;
