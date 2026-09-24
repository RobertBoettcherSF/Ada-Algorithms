pragma Ada_2022;

package Monotonic_Stack with SPARK_Mode => On is
   Length : constant := 5;
   No_Greater : constant := -11;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -10 .. 10;
   subtype Result_Value is Integer range No_Greater .. 10;
   type Input_Array is array (Index) of Value;
   type Result_Array is array (Index) of Result_Value;

   function Next_Greater (Input : Input_Array) return Result_Array with Global => null;
end Monotonic_Stack;
