pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Tribonacci_Number; use Tribonacci_Number;

procedure Tests is
begin
   if Compute (0) /= 0 or else Compute (1) /= 1 or else Compute (2) /= 1 or else Compute (10) /= 149 then
      raise Program_Error;
   end if;
   Put_Line ("Tribonacci_Number: PASS");
end Tests;
