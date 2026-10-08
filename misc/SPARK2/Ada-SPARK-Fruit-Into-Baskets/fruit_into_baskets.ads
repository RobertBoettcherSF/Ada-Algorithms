pragma Ada_2022;

package Fruit_Into_Baskets with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Fruit is Integer range 1 .. 4;
   subtype Result is Natural range 0 .. Length;
   type Input_Array is array (Index) of Fruit;
   function Maximum (Input : Input_Array) return Result with Global => null;
end Fruit_Into_Baskets;
