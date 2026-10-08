pragma Ada_2022;
package Repeated_String_Match with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Positive_Length is Positive range 1 .. 32;
   subtype Index is Positive range 1 .. 32;
   subtype Repeat_Type is Natural range 0 .. 32;
   type Text is array (Index) of Character;

   --  Target (1 .. LB) occurs in the endless repetition of Source (1 .. LA) starting at offset S.
   function Matches_At (Source, Target : Text; LA, LB : Positive_Length; S : Natural) return Boolean is
     (for all J in 1 .. LB => Target (J) = Source ((S + J - 1) mod LA + 1))
     with Pre => S < LA;

   --  Copies of Source needed to hold Target when it starts at offset S: ceiling ((S + LB) / LA).
   function Needed (LA, LB : Positive_Length; S : Natural) return Natural is ((S + LB + LA - 1) / LA)
     with Pre => S < LA;

   --  Result = the fewest copies of Source (1 .. Source_Length) whose concatenation contains
   --  Target (1 .. Target_Length), or 0 when no number of copies does. Every occurrence starts at some
   --  offset S < Source_Length inside a copy, and Needed grows with S, so the first matching offset wins.
   procedure Repeat_Count (Source, Target : Text; Source_Length, Target_Length : Positive_Length;
                           Result : out Repeat_Type)
     with Global => null,
          Post   =>
            (if Result = 0 then
               (for all S in 0 .. Source_Length - 1 =>
                  not Matches_At (Source, Target, Source_Length, Target_Length, S))
             else
               (for some S in 0 .. Source_Length - 1 =>
                  Matches_At (Source, Target, Source_Length, Target_Length, S)
                  and then Result = Needed (Source_Length, Target_Length, S)
                  and then (for all S2 in 0 .. S - 1 =>
                              not Matches_At (Source, Target, Source_Length, Target_Length, S2))));
end Repeated_String_Match;
