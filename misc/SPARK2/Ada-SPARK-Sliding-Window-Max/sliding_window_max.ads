pragma Ada_2022;

package Sliding_Window_Max with SPARK_Mode => On is
   Length : constant := 5;
   Window_Length : constant := 3;
   subtype Input_Index is Positive range 1 .. Length;
   subtype Output_Index is Positive range 1 .. Length - Window_Length + 1;
   subtype Value is Integer range -10 .. 10;
   type Input_Array is array (Input_Index) of Value;
   type Output_Array is array (Output_Index) of Value;

   function Max_Window (Input : Input_Array) return Output_Array with Global => null;
end Sliding_Window_Max;
