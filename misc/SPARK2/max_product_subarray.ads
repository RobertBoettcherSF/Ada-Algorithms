pragma SPARK_Mode (On);

package Max_Product_Subarray is
   Element_Count : constant := 6;
   subtype Index is Positive range 1 .. Element_Count;
   subtype Element is Integer range -10 .. 10;
   subtype Result is Integer range -100_000 .. 100_000;
   type Element_Array is array (Index) of Element;

   function Compute (Values : Element_Array) return Result;
end Max_Product_Subarray;
