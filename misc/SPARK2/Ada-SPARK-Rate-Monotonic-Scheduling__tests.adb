pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Rate_Monotonic_Scheduling; use Rate_Monotonic_Scheduling;

procedure Tests is
   Periods  : Period_Array := (40, 10, 20, 80);
   Selected : Task_Id;
begin
   Selected := Highest_Priority (Periods);
   if Selected /= 2 then raise Program_Error; end if;
   Put_Line ("Rate-monotonic: PASS");
end Tests;
