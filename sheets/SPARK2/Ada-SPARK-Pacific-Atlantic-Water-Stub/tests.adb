pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Pacific_Atlantic_Water_Stub; use Pacific_Atlantic_Water_Stub;

procedure Tests is
   Heights : constant Height_Map :=
     (1 => (1 => 1, 2 => 2, 3 => 3),
      2 => (1 => 8, 2 => 9, 3 => 4),
      3 => (1 => 7, 2 => 6, 3 => 5));
begin
   if Pacific_Atlantic_Water_Stub.Count (Heights) /= 7 then raise Program_Error; end if;
   Put_Line ("Pacific Atlantic water stub: PASS");
end Tests;
