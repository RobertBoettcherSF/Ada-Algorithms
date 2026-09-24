pragma Ada_2022;
package Burrows_Wheeler_Transform with SPARK_Mode => On is
   Max_Length : constant := 8;
   subtype Index is Positive range 1 .. Max_Length;
   subtype Rotation_Offset is Natural range 0 .. Max_Length - 1;
   type Text is array (Index) of Character;

   function Rotation_Character
     (Input : Text; Start : Index; Offset : Rotation_Offset)
      return Character
     with Global => null;

   function Rotation_Less (Input : Text; Left, Right : Index) return Boolean
     with Global => null;
end Burrows_Wheeler_Transform;
