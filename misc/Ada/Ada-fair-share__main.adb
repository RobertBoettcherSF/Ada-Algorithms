with Ada.Text_IO;
with Fair_Share_Scheduler;

procedure Main is
   use Fair_Share_Scheduler;

   Sched : Scheduler(Traditional_Unix_FSS);
begin
   Ada.Text_IO.Put_Line("Fair-Share Scheduler Demo");
   Ada.Text_IO.New_Line;

   -- Initialize the scheduler
   Initialize(Sched);

   -- Add some users with different share allocations
   Add_User(Sched, User_ID(1), 2.0);  -- User 1 gets 2 shares
   Add_User(Sched, User_ID(2), 1.0);  -- User 2 gets 1 share
   Add_User(Sched, User_ID(3), 1.0);  -- User 3 gets 1 share

   -- Add processes for each user
   Add_Process(Sched, Process_ID(1), User_ID(1), 10.0);
   Add_Process(Sched, Process_ID(2), User_ID(1), 10.0);
   Add_Process(Sched, Process_ID(3), User_ID(2), 10.0);
   Add_Process(Sched, Process_ID(4), User_ID(3), 10.0);

   Ada.Text_IO.Put_Line("Added 4 processes across 3 users with shares 2:1:1");
   Ada.Text_IO.New_Line;

   -- Simulate scheduling for 10 time slices
   for I in 1 .. 10 loop
      declare
         Next_Proc : Process_ID := Select_Next_Process(Sched);
      begin
         if Next_Proc /= Null_Process then
            Ada.Text_IO.Put_Line("Time slice" & Integer'Image(I) & ": Running process" & 
                                Process_ID'Image(Next_Proc));
            Tick(Sched, 1.0);
         else
            Ada.Text_IO.Put_Line("Time slice" & Integer'Image(I) & ": No process to run");
         end if;
      end;
   end loop;

   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line("Demo complete!");
end Main;
