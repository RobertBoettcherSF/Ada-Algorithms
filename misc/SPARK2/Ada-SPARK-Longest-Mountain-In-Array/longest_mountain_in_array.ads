pragma SPARK_Mode (On);

package Longest_Mountain_In_Array is
   subtype Index is Positive range 1 .. 32;
   subtype Length_Type is Natural range 0 .. 32;
   subtype Value is Integer range -1_000 .. 1_000;
   type Values is array (Index) of Value;

   function Longest (Data : Values; Length : Length_Type) return Length_Type
     with Global => null;
end Longest_Mountain_In_Array;
