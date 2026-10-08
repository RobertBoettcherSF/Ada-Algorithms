pragma SPARK_Mode (On);

package Mean_Variance is
   Sample_Count : constant := 5;
   subtype Index is Positive range 1 .. Sample_Count;
   subtype Sample_Value is Integer range -2 .. 2;
   type Sample_Array is array (Index) of Sample_Value;

   function Mean (Samples : Sample_Array) return Integer
     with Post => Mean'Result in Sample_Value;
   function Variance (Samples : Sample_Array) return Integer;
end Mean_Variance;
