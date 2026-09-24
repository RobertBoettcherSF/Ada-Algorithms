pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Shortest_Remaining_Time; use Shortest_Remaining_Time;

procedure Tests is
   Values   : Remaining_Array := (8, 3, 5, 0);
   Selected : Job_Id;
   Work     : Remaining_Time := 2;
begin
   Selected := Select_Shortest (Values);
   if Selected /= 4 then raise Program_Error; end if;
   Run_One_Tick (Work);
   if Work /= 1 then raise Program_Error; end if;
   Put_Line ("Shortest-remaining-time: PASS");
end Tests;
