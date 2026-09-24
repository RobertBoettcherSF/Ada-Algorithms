pragma Ada_2022;

package Sliding_Window_Median with SPARK_Mode => On is
   Input_Length : constant := 8;
   Window_Length : constant := 3;
   subtype Input_Index is Positive range 1 .. Input_Length;
   subtype Output_Index is Positive range 1 .. Input_Length - Window_Length + 1;
   subtype Value is Integer range -100 .. 100;
   type Input_Array is array (Input_Index) of Value;
   type Output_Array is array (Output_Index) of Value;

   function Medians (Input : Input_Array) return Output_Array
     with Global => null;
end Sliding_Window_Median;
