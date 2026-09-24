pragma Ada_2022;

package Majority_Element_II with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype Value is Integer range -20 .. 20;
   subtype Result_Index is Positive range 1 .. 2;
   type Input_Array is array (Index) of Value;
   type Result_Array is array (Result_Index) of Value;

   function Find (Input : Input_Array) return Result_Array
     with Global => null;
end Majority_Element_II;
