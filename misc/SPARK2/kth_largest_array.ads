pragma Ada_2022;

package Kth_Largest_Array with SPARK_Mode => On is
   Length : constant := 8;
   subtype Index is Positive range 1 .. Length;
   subtype K_Range is Positive range 1 .. Length;
   subtype Value is Integer range -1000 .. 1000;
   type Input_Array is array (Index) of Value;
   function Kth_Largest (Input : Input_Array; K : K_Range) return Value with Global => null;
end Kth_Largest_Array;
