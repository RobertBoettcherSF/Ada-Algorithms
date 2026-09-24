pragma Ada_2022;
package Rotate_String with SPARK_Mode => On is
   subtype Length_Type is Natural range 0 .. 32;
   subtype Index is Positive range 1 .. 32;
   type Text is array (Index) of Character;
   procedure Is_Rotation (Left, Right : Text; Length : Length_Type; Result : out Boolean)
     with Global => null;
end Rotate_String;
