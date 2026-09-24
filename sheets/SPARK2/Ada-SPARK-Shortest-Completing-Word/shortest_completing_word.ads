pragma Ada_2022;
package Shortest_Completing_Word with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Text is array (Index) of Character;
   procedure Is_Completing (Plate, Word : Text; Plate_Length, Word_Length : Length_Type;
                            Result : out Boolean)
     with Global => null;
end Shortest_Completing_Word;
