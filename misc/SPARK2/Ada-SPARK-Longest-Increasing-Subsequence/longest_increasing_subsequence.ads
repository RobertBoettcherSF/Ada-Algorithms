pragma SPARK_Mode (On);

package Longest_Increasing_Subsequence is
   Element_Count : constant := 8;
   subtype Index is Positive range 1 .. Element_Count;
   subtype Element is Integer range -100 .. 100;
   subtype Result is Natural range 0 .. Element_Count;
   type Element_Array is array (Index) of Element;

   function Compute (Values : Element_Array) return Result;
end Longest_Increasing_Subsequence;
