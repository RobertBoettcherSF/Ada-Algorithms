pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Nth_Ugly_Number; use Nth_Ugly_Number;

procedure Tests is
begin
   if Compute (1) /= 1 or else Compute (10) /= 12 or else Compute (32) /= 90 then
      raise Program_Error;
   end if;
   Put_Line ("Nth Ugly Number: PASS");
end Tests;
