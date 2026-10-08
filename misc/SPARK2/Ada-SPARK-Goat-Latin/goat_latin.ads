pragma Ada_2022;
package Goat_Latin with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   subtype Score_Type is Natural range 0 .. 2048;
   type Text is array (Index) of Character;
   procedure Goat_Length (Input : Text; Length : Length_Type; Result : out Score_Type)
     with Global => null;
end Goat_Latin;
