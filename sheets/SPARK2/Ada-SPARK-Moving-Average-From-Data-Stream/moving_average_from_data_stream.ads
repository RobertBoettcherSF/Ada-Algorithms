pragma SPARK_Mode (On);

package Moving_Average_From_Data_Stream is
   Window_Size : constant := 5;
   subtype Sample_Index is Positive range 1 .. Window_Size;
   subtype Sample_Count is Positive range 1 .. Window_Size;
   subtype Sample_Value is Integer range -10 .. 10;
   type Sample_Array is array (Sample_Index) of Sample_Value;

   function Average (Samples : Sample_Array; Count : Sample_Count) return Integer
     with Global => null;
end Moving_Average_From_Data_Stream;
