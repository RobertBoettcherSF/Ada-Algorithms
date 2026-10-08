pragma SPARK_Mode (On);
package Subarrays_With_K_Different_Integers is
   Element_Count : constant := 8;
   subtype Index is Positive range 1 .. Element_Count;
   subtype Value is Integer range 0 .. 7;
   type Element_Array is array (Index) of Value;
   subtype Different_Count is Natural range 0 .. Element_Count;
   subtype Answer is Natural range 0 .. 64;
   function Count (Values : Element_Array; K : Different_Count) return Answer;
end Subarrays_With_K_Different_Integers;
