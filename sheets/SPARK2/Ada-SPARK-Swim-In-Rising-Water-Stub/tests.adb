pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Swim_In_Rising_Water_Stub; use Swim_In_Rising_Water_Stub;

procedure Tests is
   Heights : constant Grid := ((0, 3), (1, 2));
begin
   if Minimum_Time (Heights) /= 2 then raise Program_Error; end if;
   Put_Line ("Swim in rising water: PASS");
end Tests;
