pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Moving_Average; use Moving_Average;

procedure Tests is
   Samples : constant Sample_Array := (2, 4, 6, 8, 10);
begin
   if Average (Samples) /= 6 then raise Program_Error; end if;
   Put_Line ("Moving_Average: PASS");
end Tests;
