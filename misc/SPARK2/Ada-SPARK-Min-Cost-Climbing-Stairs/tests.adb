pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Min_Cost_Climbing_Stairs; use Min_Cost_Climbing_Stairs;
with Own_Checks;

procedure Tests is
   Costs : constant Cost_Array := [10, 15, 20, 5, 8, 12];
begin
   --  top past step 6: step 2 (15) + step 4 (5) + step 5 (8) = 28
   if Compute (Costs) /= 28 then raise Program_Error; end if;
   Put_Line ("Min cost climbing stairs: PASS");
   Own_Checks;
end Tests;
