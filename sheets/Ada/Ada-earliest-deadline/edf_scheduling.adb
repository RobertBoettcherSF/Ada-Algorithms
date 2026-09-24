with Ada.Text_IO; use Ada.Text_IO;

package body EDF_Scheduling is

   -- Internal state tracking for each task in the system
   type Task_State is record
      Config            : Task_Config;
      Is_Active         : Boolean := False;
      Remaining_Time    : Time_Unit := 0;
      Absolute_Deadline : Time_Unit := 0;
      Virtual_Deadline  : Time_Unit := 0;
      Next_Release      : Time_Unit := 0;
   end record;

   Tasks : array (1 .. Max_Tasks) of Task_State;
   Task_Count : Natural := 0;

   Current_Time    : Time_Unit := 0;
   Running_Task    : Natural := 0; -- 0 indicates the system is idle
   
   Current_Variant : Scheduling_Variant := Standard_Preemptive;
   
   -- Scaling factor for EDF-VD (Mixed Criticality). 
   -- High criticality tasks use 50% of their deadline virtually.
   VD_Scaling      : constant Float := 0.5; 

   procedure Initialize (Variant : Scheduling_Variant) is
   begin
      Current_Variant := Variant;
      Task_Count := 0;
      Current_Time := 0;
      Running_Task := 0;
   end Initialize;

   procedure Add_Task (Config : Task_Config) is
   begin
      if Task_Count < Max_Tasks then
         Task_Count := Task_Count + 1;
         Tasks (Task_Count).Config := Config;
         Tasks (Task_Count).Is_Active := False;
         Tasks (Task_Count).Next_Release := Config.Release_Time;
      else
         Put_Line ("Error: Maximum number of tasks reached.");
      end if;
   end Add_Task;

   function Is_Schedulable return Boolean is
      Utilization : Float := 0.0;
   begin
      for I in 1 .. Task_Count loop
         if Tasks (I).Config.Type_Of_Task = Periodic then
            Utilization := Utilization +
               Float (Tasks (I).Config.Computation_Time) / Float (Tasks (I).Config.Period);
         end if;
      end loop;
      
      Put_Line ("System Utilization: " & Float'Image (Utilization));
      return Utilization <= 1.0;
   end Is_Schedulable;

   procedure Run_Simulation (Ticks : Time_Unit) is
      Earliest_Deadline : Time_Unit;
      Next_Task         : Natural;
      Target_Deadline   : Time_Unit;
      End_Time          : constant Time_Unit := Current_Time + Ticks;
   begin
      Put_Line ("--- Starting EDF Simulation ---");
      Put_Line ("Mode: " & Scheduling_Variant'Image (Current_Variant));
      
      while Current_Time < End_Time loop
         
         -- 1. Check for Task Arrivals/Releases
         for I in 1 .. Task_Count loop
            if not Tasks (I).Is_Active and then Current_Time >= Tasks (I).Next_Release then
               
               Tasks (I).Is_Active := True;
               Tasks (I).Remaining_Time := Tasks (I).Config.Computation_Time;
               Tasks (I).Absolute_Deadline := Current_Time + Tasks (I).Config.Deadline;

               -- EDF-VD logic: tighten deadlines for high-criticality tasks
               if Current_Variant = EDF_VD and then Tasks (I).Config.Criticality = High then
                  Tasks (I).Virtual_Deadline := Current_Time +
                     Time_Unit (Float (Tasks (I).Config.Deadline) * VD_Scaling);
               else
                  Tasks (I).Virtual_Deadline := Tasks (I).Absolute_Deadline;
               end if;

               Put_Line ("[Time" & Time_Unit'Image (Current_Time) & "] Task" & 
                         Task_ID'Image (Tasks (I).Config.ID) & " released. Absolute Deadline:" & 
                         Time_Unit'Image (Tasks (I).Absolute_Deadline));

               -- Calculate next cycle for periodic tasks
               if Tasks (I).Config.Type_Of_Task = Periodic then
                  Tasks (I).Next_Release := Tasks (I).Next_Release + Tasks (I).Config.Period;
               else
                  Tasks (I).Next_Release := Time_Unit'Last; -- Aperiodic tasks do not automatically re-release
               end if;
            end if;
         end loop;

         -- 2. Determine which task should run (The actual EDF scheduling decision)
         Next_Task := 0;
         Earliest_Deadline := Time_Unit'Last;

         if Current_Variant = Standard_Non_Preemptive and then
            Running_Task /= 0 and then
            Tasks (Running_Task).Is_Active
         then
            -- Non-preemptive: current task monopolizes the CPU until completion
            Next_Task := Running_Task;
         else
            -- Preemptive or Idle: find the active task with the closest deadline
            for I in 1 .. Task_Count loop
               if Tasks (I).Is_Active then
                  if Current_Variant = EDF_VD then
                     Target_Deadline := Tasks (I).Virtual_Deadline;
                  else
                     Target_Deadline := Tasks (I).Absolute_Deadline;
                  end if;

                  if Target_Deadline < Earliest_Deadline then
                     Earliest_Deadline := Target_Deadline;
                     Next_Task := I;
                  end if;
               end if;
            end loop;
         end if;

         -- Log Context Switches
         if Next_Task /= Running_Task then
            if Running_Task /= 0 and then Tasks (Running_Task).Is_Active then
               Put_Line ("[Time" & Time_Unit'Image (Current_Time) & "] Task" & 
                         Task_ID'Image (Tasks (Running_Task).Config.ID) & " preempted.");
            end if;
            
            Running_Task := Next_Task;
            
            if Running_Task /= 0 then
               Put_Line ("[Time" & Time_Unit'Image (Current_Time) & "] Task" & 
                         Task_ID'Image (Tasks (Running_Task).Config.ID) & " starts/resumes.");
            end if;
         end if;

         -- 3. Execute the Running Task
         if Running_Task /= 0 then
            Tasks (Running_Task).Remaining_Time := Tasks (Running_Task).Remaining_Time - 1;

            -- Check for completion
            if Tasks (Running_Task).Remaining_Time = 0 then
               Tasks (Running_Task).Is_Active := False;
               Put_Line ("[Time" & Time_Unit'Image (Current_Time + 1) & "] Task" & 
                         Task_ID'Image (Tasks (Running_Task).Config.ID) & " completed.");
               Running_Task := 0;
            end if;
         end if;

         -- 4. Check for Missed Deadlines (Tardiness mapping)
         for I in 1 .. Task_Count loop
            if Tasks (I).Is_Active and then Current_Time + 1 > Tasks (I).Absolute_Deadline then
               Put_Line ("  -> WARNING [Time" & Time_Unit'Image (Current_Time + 1) & 
                         "]: Task" & Task_ID'Image (Tasks (I).Config.ID) & " missed its deadline!");
               
               -- In a hard real-time system, we might abort here. 
               -- We allow the task to continue for soft real-time tardiness evaluation.
            end if;
         end loop;

         -- 5. Advance System Time
         Current_Time := Current_Time + 1;
      end loop;
      Put_Line ("--- Simulation Ended ---");
   end Run_Simulation;

end EDF_Scheduling;
