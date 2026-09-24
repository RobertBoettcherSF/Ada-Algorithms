pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Clamp;

procedure Tests is
begin
   if Clamp.Value (-4, 0, 10) /= 0 then raise Program_Error; end if;
   if Clamp.Value (14, 0, 10) /= 10 then raise Program_Error; end if;
   if Clamp.Value (6, 0, 10) /= 6 then raise Program_Error; end if;
   Put_Line ("Clamp: PASS");
end Tests;
