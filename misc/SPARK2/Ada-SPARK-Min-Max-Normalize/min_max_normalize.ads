pragma SPARK_Mode (On);

package Min_Max_Normalize is
   Sample_Count : constant := 5;
   subtype Index is Positive range 1 .. Sample_Count;
   subtype Sample_Value is Integer range 0 .. 10;
   subtype Normalized_Value is Integer range 0 .. 100;
   type Sample_Array is array (Index) of Sample_Value;

   function Normalize (Samples : Sample_Array; Position : Index)
     return Normalized_Value;
end Min_Max_Normalize;
