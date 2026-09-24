pragma Ada_2022;
package Kadanes_Algorithm with SPARK_Mode => On is
   Capacity : constant := 4;
   subtype Index is Positive range 1 .. Capacity;
   subtype Element is Integer range -100 .. 100;
   type Input is array (Index) of Element;
   function Maximum_Subarray (A : Input) return Integer;
end Kadanes_Algorithm;
