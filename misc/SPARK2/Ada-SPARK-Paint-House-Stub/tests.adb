pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Paint_House_Stub; use Paint_House_Stub;

procedure Tests is
   Costs : constant Cost_Matrix := ((17, 2, 17), (16, 16, 5), (14, 3, 19), (2, 4, 6));
begin
   if Compute (Costs) /= 12 then raise Program_Error; end if;
   Put_Line ("Paint house stub: PASS");
end Tests;
