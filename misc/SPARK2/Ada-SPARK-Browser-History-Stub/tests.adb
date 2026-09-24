pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Browser_History_Stub; use Browser_History_Stub;

procedure Tests is
   History : constant History_Array := (1 => 10, 2 => 20, 3 => 30, 4 => 40);
begin
   if Back_Target (History, 4, 2) /= 20 then raise Program_Error; end if;
   if Back_Target (History, 2, 4) /= 10 then raise Program_Error; end if;
   Put_Line ("Browser History: PASS");
end Tests;
