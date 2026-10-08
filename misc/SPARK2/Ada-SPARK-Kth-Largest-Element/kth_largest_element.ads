pragma Ada_2022;

package Kth_Largest_Element with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype K_Index is Positive range 1 .. 8;
   subtype Value is Integer range -100 .. 100;
   type Input_Array is array (Index) of Value;

   function Kth_Largest (Input : Input_Array; K : K_Index) return Value
     with Global => null;
end Kth_Largest_Element;
