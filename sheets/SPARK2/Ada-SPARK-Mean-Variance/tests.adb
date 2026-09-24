pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Mean_Variance; use Mean_Variance;

procedure Tests is
   Samples : constant Sample_Array := (-2, -1, 0, 1, 2);
begin
   if Mean (Samples) /= 0 then raise Program_Error; end if;
   if Variance (Samples) /= 2 then raise Program_Error; end if;
   Put_Line ("Mean_Variance: PASS");
end Tests;
