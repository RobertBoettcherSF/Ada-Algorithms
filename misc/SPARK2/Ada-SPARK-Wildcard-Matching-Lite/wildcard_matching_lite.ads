pragma Ada_2022;

package Wildcard_Matching_Lite with SPARK_Mode => On is
   Max_Length : constant := 16;
   subtype Length is Natural range 0 .. Max_Length;
   subtype Index is Positive range 1 .. Max_Length;
   type Text is array (Index) of Character;

   function Matches
     (Input, Pattern : Text; NI, NP : Length) return Boolean
     with Global => null;
end Wildcard_Matching_Lite;
