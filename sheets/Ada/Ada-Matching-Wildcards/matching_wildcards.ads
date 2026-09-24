--  Matching_Wildcards — Ada 2023 educational survey of wildcard / glob
--  matching (* = any sequence, ? = one character). Self-contained sketches
--  of Krauss non-recursive star-bookmark matching and classic DP boolean
--  table matching, plus a Method dispatcher. Does not depend on the sibling
--  Krauss package (README link only).
--  Primary source:
--  https://en.wikipedia.org/wiki/Matching_wildcards

pragma Ada_2022;

package Matching_Wildcards
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
   -- Method taxonomy (survey)
   ---------------------------------------------------------------------------

   type Method_Kind is (Krauss, DP);
   --  Krauss : non-recursive star-bookmark walker (Kirk J. Krauss style).
   --  DP     : classic boolean dynamic-programming table (Richter / Snippets
   --           formulation on Wikipedia: Matching wildcards).

   function Method_Name (M : Method_Kind) return String
     with Global => null;

   function Method_Count return Positive
     with Global => null;

   function Describe (M : Method_Kind) return String
     with Global => null;

   ---------------------------------------------------------------------------
   -- Matching (case-sensitive Windows / glob semantics)
   ---------------------------------------------------------------------------
   --  '*'  matches any sequence of zero or more characters.
   --  '?'  matches exactly one character.
   --  Any other character matches itself literally (case-sensitive).
   --  Empty Pattern matches only empty Text.
   --  Matching is anchored (entire Pattern vs entire Text).

   function Match_Krauss (Pattern, Text : String) return Boolean
     with Global => null;

   function Match_DP (Pattern, Text : String) return Boolean
     with Global => null;

   --  Dispatch by Method_Kind. Default is Krauss (practical non-recursive).
   function Match
     (Pattern : String;
      Text    : String;
      Method  : Method_Kind := Krauss) return Boolean
     with Global => null;

   --  Alias for Match with default method.
   function Is_Match (Pattern, Text : String) return Boolean
     with Global => null;

end Matching_Wildcards;
