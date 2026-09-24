pragma SPARK_Mode (On);

package Kth_Largest_In_Stream_Stub is
   Capacity : constant := 5;
   subtype Stream_Index is Positive range 1 .. Capacity;
   subtype Rank is Positive range 1 .. Capacity;
   subtype Value is Integer range 0 .. 100;
   type Stream_Array is array (Stream_Index) of Value;

   function Kth_Largest
     (Values : Stream_Array; K : Rank) return Value with Global => null;
end Kth_Largest_In_Stream_Stub;
