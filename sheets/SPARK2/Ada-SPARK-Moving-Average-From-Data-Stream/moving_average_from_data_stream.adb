pragma SPARK_Mode (On);

package body Moving_Average_From_Data_Stream is
   function Average (Samples : Sample_Array; Count : Sample_Count) return Integer is
      Total : Integer := 0;
   begin
      for I in Sample_Index'First .. Count loop
         Total := Total + Samples (I);
      end loop;
      return Total / Integer (Count);
   end Average;
end Moving_Average_From_Data_Stream;
