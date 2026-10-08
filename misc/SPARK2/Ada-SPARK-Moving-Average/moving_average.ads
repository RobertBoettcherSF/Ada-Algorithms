pragma SPARK_Mode (On);

package Moving_Average is
   Window_Size : constant := 5;
   subtype Index is Positive range 1 .. Window_Size;
   subtype Sample_Value is Integer range -10 .. 10;
   type Sample_Array is array (Index) of Sample_Value;

   function Average (Samples : Sample_Array) return Integer;
end Moving_Average;
