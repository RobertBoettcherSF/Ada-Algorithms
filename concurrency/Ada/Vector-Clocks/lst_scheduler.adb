-- lst_scheduler.adb
-- Implementation of the Least Slack Time (LST) Scheduler

with Ada.Text_IO; use Ada.Text_IO;

package body LST_Scheduler is

   procedure Init (Self : in out Scheduler) is
   begin
      Self.Count := 0;
   end Init;

   -- One of the simplest acceptance tests for a sporadic job is calculating
   -- the amount of slack time between the release time and deadline of the job.
   function Acceptance_Test (Arrival, Burst, Deadline : Natural) return Boolean is
   begin
      -- Returns True if slack >= 0 at arrival time
      return Deadline >= (Arrival + Burst);
   end Acceptance_Test;

   procedure Add_Task (Self     : in out Scheduler;
                       ID       : Task_ID;
                       Category : Job_Category;
                       Arrival  : Natural;
                       Burst    : Natural;
                       Deadline : Natural) is
   begin
      if Self.Count < Self.Max_Tasks then
         -- Apply the Acceptance Test for Sporadic Jobs
         if Category = Sporadic and then not Acceptance_Test (Arrival, Burst, Deadline) then
            Put_Line ("Rejected Sporadic Task" & Task_ID'Image (ID) & 
                      ": Fails acceptance test (Negative Initial Slack).");
            return;
         end if;

         Self.Count := Self.Count + 1;
         Self.Tasks (Self.Count) := (ID             => ID,
                                     Category       => Category,
                                     Arrival_Time   => Arrival,
                                     Burst_Time     => Burst,
                                     Remaining_Time => Burst,
                                     Deadline       => Deadline,
                                     Is_Completed   => False);
      else
         Put_Line ("Scheduler capacity reached. Cannot add Task" & Task_ID'Image (ID));
      end if;
   end Add_Task;

   procedure Run_Simulation (Self       : in out Scheduler;
                             Mode       : Scheduling_Mode;
                             Total_Time : Natural) is
      Current_Time     : Natural := 0;
      Active_Task      : Natural := 0;
      Last_Active_Task : Natural := 0;
      Min_Slack        : Integer;
      Slack            : Integer;
      All_Done         : Boolean;
   begin
      Put_Line ("");
      Put_Line ("=== Starting LST Scheduling Simulation ===");
      Put_Line ("Mode: " & Scheduling_Mode'Image (Mode));
      Put_Line ("------------------------------------------");

      while Current_Time < Total_Time loop
         
         -- Check if all tasks in the queue are completed
         All_Done := True;
         for I in 1 .. Self.Count loop
            if not Self.Tasks (I).Is_Completed then
               All_Done := False;
               exit;
            end if;
         end loop;
         
         if All_Done then
            Put_Line ("Time" & Natural'Image (Current_Time) & " : All tasks completed.");
            exit;
         end if;

         Last_Active_Task := Active_Task;

         -- Task Selection Logic
         -- If non-preemptive (uninterruptible) and a task is currently running, keep it
         if Mode = Non_Preemptive and then Active_Task /= 0 and then not Self.Tasks (Active_Task).Is_Completed then
            null; -- Retain Active_Task, bypass preemption
         else
            Active_Task := 0;
            Min_Slack   := Integer'Last;

            for I in 1 .. Self.Count loop
               if not Self.Tasks (I).Is_Completed and then Self.Tasks (I).Arrival_Time <= Current_Time then
                  
                  -- Formal Slack Calculation: d - t - e' (Deadline - Current - Remaining)
                  Slack := Self.Tasks (I).Deadline - Current_Time - Self.Tasks (I).Remaining_Time;
                  
                  if Slack < 0 then
                     Put_Line ("WARNING: Task" & Task_ID'Image (Self.Tasks (I).ID) & " missed its deadline! Slack: " & Integer'Image(Slack));
                  end if;

                  if Slack < Min_Slack then
                     Min_Slack   := Slack;
                     Active_Task := I;
                  elsif Slack = Min_Slack then
                     -- Tie breaking for identical slacks: favor the currently running task to prevent context-switching thrashing
                     if I = Last_Active_Task then
                        Active_Task := I;
                     end if;
                  end if;
               end if;
            end loop;
         end if;

         -- Execution Phase
         if Active_Task /= 0 then
            -- Recalculate pure slack here just for accurate logging 
            Slack := Self.Tasks (Active_Task).Deadline - Current_Time - Self.Tasks (Active_Task).Remaining_Time;
            
            Put_Line ("Time" & Natural'Image (Current_Time) & " : Executing Task" & 
                      Task_ID'Image (Self.Tasks (Active_Task).ID) &
                      " | Slack:" & Integer'Image (Slack) & 
                      " | Remaining:" & Natural'Image (Self.Tasks (Active_Task).Remaining_Time));
            
            Self.Tasks (Active_Task).Remaining_Time := Self.Tasks (Active_Task).Remaining_Time - 1;
            
            -- Check for task completion
            if Self.Tasks (Active_Task).Remaining_Time = 0 then
               Self.Tasks (Active_Task).Is_Completed := True;
               Put_Line ("Time" & Natural'Image (Current_Time + 1) & " : Task" & 
                         Task_ID'Image (Self.Tasks (Active_Task).ID) & " Completed!");
               
               if Mode = Non_Preemptive then
                  Active_Task := 0; -- Release the processor for the next cycle
               end if;
            end if;
         else
            Put_Line ("Time" & Natural'Image (Current_Time) & " : CPU Idle");
         end if;

         Current_Time := Current_Time + 1;
      end loop;
      
      Put_Line ("=== End of Simulation ===");
   end Run_Simulation;

   procedure Demo is
      Sched : Scheduler (Max_Tasks => 5);
   begin
      Sched.Init;
      
      -- Add tasks simulating standard periodic requests 
      Sched.Add_Task (ID => 1, Category => Periodic, Arrival => 0, Burst => 3, Deadline => 7);
      Sched.Add_Task (ID => 2, Category => Periodic, Arrival => 2, Burst => 3, Deadline => 8);
      
      -- Add sporadic tasks checking the acceptance tests 
      Sched.Add_Task (ID => 3, Category => Sporadic, Arrival => 4, Burst => 2, Deadline => 10);
      
      -- This Sporadic task lacks enough slack time to be accepted without missing a deadline
      Sched.Add_Task (ID => 4, Category => Sporadic, Arrival => 5, Burst => 4, Deadline => 7);

      -- Run Preemptive (Strict LST - Provides optimal schedulable utilization)
      declare
         Sched_Preempt : Scheduler := Sched;
      begin
         Sched_Preempt.Run_Simulation (Mode => Preemptive, Total_Time => 15);
      end;
      
      -- Run Non-Preemptive (Uninterruptible Processes - Suboptimal check)
      declare
         Sched_Non_Pre : Scheduler := Sched;
      begin
         Sched_Non_Pre.Run_Simulation (Mode => Non_Preemptive, Total_Time => 15);
      end;
      
   end Demo;

end LST_Scheduler;
