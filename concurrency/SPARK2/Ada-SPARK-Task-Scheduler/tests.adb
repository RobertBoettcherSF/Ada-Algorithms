with Task_Scheduler;
procedure Tests is
begin
   pragma Assert (Task_Scheduler.Schedule_Length (0, 3) = 0);
   pragma Assert (Task_Scheduler.Schedule_Length (3, 2) = 7);
   pragma Assert (Task_Scheduler.Schedule_Length (4, 0) = 4);
end Tests;
