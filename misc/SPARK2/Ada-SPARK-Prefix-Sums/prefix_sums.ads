pragma Ada_2022;

package Prefix_Sums with SPARK_Mode => On is
   Length : constant := 5;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range 0 .. 10;
   subtype Sum is Integer range 0 .. 50;
   type Input_Array is array (Index) of Value;
   type Sum_Array is array (Index) of Sum;

   function Compute (Input : Input_Array) return Sum_Array with Global => null;
end Prefix_Sums;
