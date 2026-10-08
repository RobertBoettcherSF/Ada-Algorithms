pragma Ada_2022;

package Pangram with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Text is array (Index) of Character;

   function Is_Pangram (Input : Text; Length : Length_Type) return Boolean
     with Global => null;
end Pangram;
