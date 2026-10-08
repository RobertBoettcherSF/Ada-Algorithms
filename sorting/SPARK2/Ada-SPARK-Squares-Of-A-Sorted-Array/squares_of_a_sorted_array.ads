pragma Ada_2022;
package Squares_Of_A_Sorted_Array with SPARK_Mode => On is
   Length : constant := 32;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -32 .. 32;
   subtype Square_Value is Integer range 0 .. 1024;
   type Int_Array is array (Index) of Value;
   type Square_Array is array (Index) of Square_Value;
   function Squares (A : Int_Array) return Square_Array with Global => null;
end Squares_Of_A_Sorted_Array;
