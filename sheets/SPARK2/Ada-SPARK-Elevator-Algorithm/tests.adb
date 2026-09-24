pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Elevator_Algorithm; use Elevator_Algorithm;

procedure Tests is
begin
   if Move_One_Step (3, 8) /= 4 then raise Program_Error; end if;
   if Move_One_Step (8, 3) /= 7 then raise Program_Error; end if;
   if Move_One_Step (5, 5) /= 5 then raise Program_Error; end if;
   Put_Line ("Elevator: PASS");
end Tests;
