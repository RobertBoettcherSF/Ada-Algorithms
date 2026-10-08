pragma Ada_2022;

package Keyboard_Row with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Text is array (Index) of Character;

   subtype Row_Number is Natural range 0 .. 3;

   function In_One_Row (Word : Text; Length : Length_Type) return Boolean
     with Global => null;
end Keyboard_Row;
