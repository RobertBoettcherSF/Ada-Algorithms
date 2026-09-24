pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Min_Cost_Climbing_Stairs; use Min_Cost_Climbing_Stairs;

procedure Tests is
   Costs : constant Cost_Array := (10, 15, 20, 5, 8, 12);
begin
   if Compute (Costs) /= 32 then raise Program_Error; end if;
   Put_Line ("Min cost climbing stairs: PASS");
end Tests;
