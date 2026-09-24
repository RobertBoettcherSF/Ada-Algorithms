pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Softmin;

procedure Tests is
begin
   if Softmin.Value (0, 8) /= 2 then raise Program_Error; end if;
   if Softmin.Value (-8, 4) /= -5 then raise Program_Error; end if;
   Put_Line ("Softmin: PASS");
end Tests;
