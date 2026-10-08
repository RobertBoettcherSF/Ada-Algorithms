pragma Ada_2022;

package Reverse_Pairs with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -100 .. 100;
   type Input_Array is array (Index) of Value;

   function Count (Input : Input_Array) return Natural
     with Global => null;
end Reverse_Pairs;
