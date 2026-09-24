pragma SPARK_Mode (On);

package body Accumulator is

   function Current_Mean (E : Engine) return Sample_Value is
      Calculated : constant Total_Value := E.Total / Total_Value (E.Count);
   begin
      --  Guaranteed within bounds by precondition and math constraints
      return Sample_Value (Calculated);
   end Current_Mean;

   procedure Add_Sample (E : in out Engine; S : Sample_Value) is
   begin
      E.Total := E.Total + Total_Value (S);
      E.Count := E.Count + 1;
   end Add_Sample;

   procedure Reset (E : out Engine) is
   begin
      E := (Total => 0, Count => 0);
   end Reset;

end Accumulator;
