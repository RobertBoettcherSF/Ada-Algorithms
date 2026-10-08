pragma Ada_2022;

package Top_K_Frequent_Elements with SPARK_Mode => On is
   subtype Index is Positive range 1 .. 8;
   subtype K_Index is Positive range 1 .. 8;
   subtype Value is Integer range 0 .. 7;
   type Input_Array is array (Index) of Value;

   function Kth_Most_Frequent (Input : Input_Array; K : K_Index) return Value
     with Global => null;
end Top_K_Frequent_Elements;
