pragma SPARK_Mode (On);

package body Moving_Average is
   function Average (Samples : Sample_Array) return Integer is
      Total : Integer := 0;
   begin
      for I in Index loop
         Total := Total + Samples (I);
      end loop;
      return Total / Window_Size;
   end Average;
end Moving_Average;
