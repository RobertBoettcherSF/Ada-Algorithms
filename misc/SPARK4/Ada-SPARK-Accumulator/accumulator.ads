pragma SPARK_Mode (On);

package Accumulator is

   type Sample_Value is range -10_000 .. 10_000;
   type Count_Type   is range 0 .. 1_000;
   type Total_Value  is range -10_000_000 .. 10_000_000;

   type Engine is record
      Total : Total_Value := 0;
      Count : Count_Type  := 0;
   end record;

   function Current_Mean (E : Engine) return Sample_Value with
     Pre  => E.Count > 0
             and then E.Total / Total_Value (E.Count) in
               Total_Value (Sample_Value'First) ..
               Total_Value (Sample_Value'Last);

   procedure Add_Sample (E : in out Engine; S : Sample_Value) with
     Pre  => E.Count < Count_Type'Last
             and then E.Total + Total_Value (S) in Total_Value'Range,
     Post => E.Count = E.Count'Old + 1
             and then E.Total = E.Total'Old + Total_Value (S);

   procedure Reset (E : out Engine) with
     Post => E.Count = 0 and then E.Total = 0;

end Accumulator;
