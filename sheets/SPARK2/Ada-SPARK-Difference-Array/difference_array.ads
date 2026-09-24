pragma Ada_2022;

package Difference_Array with SPARK_Mode => On is
   Length : constant := 5;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 10;
   subtype Difference is Integer range -10 .. 10;
   type Input_Array is array (Index) of Value;
   type Difference_Values is array (Index) of Difference;

   function Compute (Input : Input_Array) return Difference_Values
     with Global => null;
end Difference_Array;
