pragma SPARK_Mode (On);
with Ada.Text_IO; use Ada.Text_IO;
with Shortest_Job_Next; use Shortest_Job_Next;

procedure Tests is
   Bursts   : Burst_Array := (9, 4, 7, 2);
   Selected : Job_Id;
begin
   Selected := Select_Shortest (Bursts);
   if Selected /= 4 then raise Program_Error; end if;
   Put_Line ("Shortest-job-next: PASS");
end Tests;
