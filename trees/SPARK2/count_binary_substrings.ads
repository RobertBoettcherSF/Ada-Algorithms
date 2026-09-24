pragma Ada_2022;
package Count_Binary_Substrings with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   subtype Count_Type is Natural range 0 .. 1024;
   type Text is array (Index) of Character;
   procedure Count_Substrings (Input : Text; Length : Length_Type; Result : out Count_Type)
     with Global => null;
end Count_Binary_Substrings;
