pragma SPARK_Mode (On);

package Argmax is
   Element_Count : constant := 5;
   subtype Index is Positive range 1 .. Element_Count;
   subtype Element is Integer range -100 .. 100;
   type Element_Array is array (Index) of Element;

   function Find (Values : Element_Array) return Index;
end Argmax;
