pragma Ada_2022;

package Pancake_Sort with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range -100 .. 100;
   type Input_Array is array (Index) of Value;

   function Sort (Input : Input_Array) return Input_Array
     with Global => null;
end Pancake_Sort;
