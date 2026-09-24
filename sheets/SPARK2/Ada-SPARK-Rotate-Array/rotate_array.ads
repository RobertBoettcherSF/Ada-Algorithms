pragma Ada_2022;

package Rotate_Array with SPARK_Mode => On is
   Length : constant := 5;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -10 .. 10;
   type Value_Array is array (Index) of Value;

   function Rotate_Right (Input : Value_Array) return Value_Array
     with Global => null;
end Rotate_Array;
