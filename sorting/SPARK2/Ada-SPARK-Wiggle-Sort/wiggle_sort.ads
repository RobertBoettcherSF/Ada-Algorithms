pragma Ada_2022;

package Wiggle_Sort with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype Value is Integer range -100 .. 100;
   type Input_Array is array (Index) of Value;

   function Wiggle (Input : Input_Array) return Input_Array
     with Global => null;
end Wiggle_Sort;
