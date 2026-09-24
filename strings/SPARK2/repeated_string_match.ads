pragma Ada_2022;
package Repeated_String_Match with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   subtype Repeat_Type is Natural range 0 .. 32;
   type Text is array (Index) of Character;
   procedure Repeat_Count (Source, Target : Text; Source_Length, Target_Length : Length_Type;
                           Result : out Repeat_Type)
     with Global => null;
end Repeated_String_Match;
