pragma SPARK_Mode (On);

package Kth_Largest_Element_In_A_Stream is
   Stream_Length : constant := 8;
   subtype Value is Integer range -100 .. 100;
   subtype K_Range is Positive range 1 .. Stream_Length;
   type Stream_Array is array (Positive range 1 .. Stream_Length) of Value;

   function Kth_Largest (Stream : Stream_Array; K : K_Range) return Value
     with Pre => K <= Stream_Length;
end Kth_Largest_Element_In_A_Stream;
