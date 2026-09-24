pragma SPARK_Mode (On);

package Merge_Sorted_Array is
   subtype Index is Positive range 1 .. 32;
   subtype Length_Type is Natural range 0 .. 32;
   subtype Value is Integer range -1_000 .. 1_000;
   type Values is array (Index) of Value;

   function Merge_Sum (Left : Values; Right : Values; Length : Length_Type)
     return Integer
     with Global => null;
end Merge_Sorted_Array;
