pragma Ada_2022;

package Sliding_Window_Maximum with SPARK_Mode => On is
   Length : constant := 8;
   Window_Length : constant := 3;
   subtype Input_Index is Positive range 1 .. Length;
   subtype Output_Index is Positive range 1 .. 6;
   subtype Value is Integer range -20 .. 20;
   type Input_Array is array (Input_Index) of Value;
   type Output_Array is array (Output_Index) of Value;
   function Maximums (Input : Input_Array) return Output_Array with Global => null;
end Sliding_Window_Maximum;
