-------------------------------------------------------------------------------
--  Shortest Remaining Time (SRT) Scheduling Simulation
--  Implementation and Main Procedure File (.adb)
-------------------------------------------------------------------------------
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;
with Ada.Float_Text_IO;   use Ada.Float_Text_IO;

procedure SRT_Simulation is

   -- =========================================================================
   --  Reusable Scheduling Logic Package
   -- =========================================================================
   package SRT_Scheduler is
      type Process_ID is new Positive;

      type Process_Record is record
         ID               : Process_ID;
         Arrival_Time     : Natural;
         Burst_Time       : Natural;
         Remaining_Time   : Natural;
         Completion_Time  : Natural;
         Waiting_Time     : Natural;
         Turnaround_Time  : Natural;
      end record;

      type Process_Array is array (Positive range <>) of Process_Record;

      -- Both variants covered in the article
      type Scheduling_Variant is (Preemptive_SRT, Non_Preemptive_SJN);

      procedure Simulate
        (Processes        : in out Process_Array;
         Variant          : Scheduling_Variant := Preemptive_SRT;
         Context_Switch   : Natural := 0);

      procedure Print_Results (Processes : Process_Array);
   end SRT_Scheduler;

   package body SRT_Scheduler is

      procedure Simulate
        (Processes        : in out Process_Array;
         Variant          : Scheduling_Variant := Preemptive_SRT;
         Context_Switch   : Natural := 0)
      is
         Current_Time      : Natural := 0;
         Completed_Count   : Natural := 0;
         Total_Processes   : constant Natural := Processes'Length;
         Current_Run_Idx   : Integer := -1;
         Prev_Run_Idx      : Integer := -1;
         Min_Remaining     : Natural;
         Shortest_Idx      : Integer;
         Penalty_Remaining : Natural := 0;
      begin
         -- Initialize remaining times
         for I in Processes'Range loop
            Processes(I).Remaining_Time := Processes(I).Burst_Time;
         end loop;

         -- Unit-by-unit time simulation
         while Completed_Count < Total_Processes loop
            
            -- If CPU is handling a context switch, do not execute processes
            if Penalty_Remaining > 0 then
               Penalty_Remaining := Penalty_Remaining - 1;
               Current_Time := Current_Time + 1;
            else
               Min_Remaining := Natural'Last;
               Shortest_Idx := -1;

               -- 1. Find the best ready process to execute
               for I in Processes'Range loop
                  if Processes(I).Arrival_Time <= Current_Time and then
                     Processes(I).Remaining_Time > 0
                  then
                     if Variant = Preemptive_SRT then
                        -- Preemptive: Absolute lowest remaining time wins
                        if Processes(I).Remaining_Time < Min_Remaining then
                           Min_Remaining := Processes(I).Remaining_Time;
                           Shortest_Idx := I;
                        elsif Processes(I).Remaining_Time = Min_Remaining then
                           -- Tie-breaker: First arrival wins; if identical, lowest ID wins
                           if Shortest_Idx /= -1 then
                              if Processes(I).Arrival_Time < Processes(Shortest_Idx).Arrival_Time then
                                 Shortest_Idx := I;
                              elsif Processes(I).Arrival_Time = Processes(Shortest_Idx).Arrival_Time then
                                 if Processes(I).ID < Processes(Shortest_Idx).ID then
                                    Shortest_Idx := I;
                                 end if;
                              end if;
                           end if;
                        end if;
                     else
                        -- Non-Preemptive (Shortest Job Next)
                        if Current_Run_Idx /= -1 and then
                           Processes(Current_Run_Idx).Remaining_Time > 0
                        then
                           Shortest_Idx := Current_Run_Idx;
                           exit; -- Keep processing current job without preemption
                        else
                           -- No active job, pick the shortest ready job
                           if Processes(I).Remaining_Time < Min_Remaining then
                              Min_Remaining := Processes(I).Remaining_Time;
                              Shortest_Idx := I;
                           end if;
                        end if;
                     end if;
                  end if;
               end loop;

               -- 2. Handle Process Execution / Preemption
               if Shortest_Idx /= -1 then
                  -- Trigger a context switch penalty if process changed
                  if Prev_Run_Idx /= -1 and then 
                     Prev_Run_Idx /= Shortest_Idx and then 
                     Context_Switch > 0 
                  then
                     Penalty_Remaining := Context_Switch - 1;
                     Prev_Run_Idx := Shortest_Idx;
                     Current_Run_Idx := Shortest_Idx;
                     Current_Time := Current_Time + 1;
                  else
                     -- Execute process for 1 time unit
                     Prev_Run_Idx := Shortest_Idx;
                     Current_Run_Idx := Shortest_Idx;
                     Processes(Shortest_Idx).Remaining_Time := Processes(Shortest_Idx).Remaining_Time - 1;
                     Current_Time := Current_Time + 1;

                     -- Check for process completion
                     if Processes(Shortest_Idx).Remaining_Time = 0 then
                        Completed_Count := Completed_Count + 1;
                        Processes(Shortest_Idx).Completion_Time := Current_Time;
                        Processes(Shortest_Idx).Turnaround_Time :=
                          Processes(Shortest_Idx).Completion_Time - Processes(Shortest_Idx).Arrival_Time;
                        Processes(Shortest_Idx).Waiting_Time :=
                          Processes(Shortest_Idx).Turnaround_Time - Processes(Shortest_Idx).Burst_Time;
                        Current_Run_Idx := -1; -- Release CPU
                     end if;
                  end if;
               else
                  -- CPU is Idle
                  Current_Time := Current_Time + 1;
                  Current_Run_Idx := -1;
               end if;
            end if;
         end loop;
      end Simulate;

      procedure Print_Results (Processes : Process_Array) is
         Total_Wait : Natural := 0;
         Total_Turn : Natural := 0;
         Avg_Wait   : Float;
         Avg_Turn   : Float;
      begin
         Put_Line ("------------------------------------------------------------------");
         Put_Line (" ID | Arrival | Burst | Completion | Waiting Time | Turnaround ");
         Put_Line ("------------------------------------------------------------------");

         for I in Processes'Range loop
            Put (" ");
            Put (Integer(Processes(I).ID), 2);
            Put (" | ");
            Put (Processes(I).Arrival_Time, 7);
            Put (" | ");
            Put (Processes(I).Burst_Time, 5);
            Put (" | ");
            Put (Processes(I).Completion_Time, 10);
            Put (" | ");
            Put (Processes(I).Waiting_Time, 12);
            Put (" | ");
            Put (Processes(I).Turnaround_Time, 10);
            New_Line;

            Total_Wait := Total_Wait + Processes(I).Waiting_Time;
            Total_Turn := Total_Turn + Processes(I).Turnaround_Time;
         end loop;
         Put_Line ("------------------------------------------------------------------");

         Avg_Wait := Float(Total_Wait) / Float(Processes'Length);
         Avg_Turn := Float(Total_Turn) / Float(Processes'Length);

         Put ("Average Waiting Time:    ");
         Put (Avg_Wait, Fore => 1, Aft => 2, Exp => 0);
         New_Line;
         Put ("Average Turnaround Time: ");
         Put (Avg_Turn, Fore => 1, Aft => 2, Exp => 0);
         New_Line;
      end Print_Results;

   end SRT_Scheduler;

   use SRT_Scheduler;

   -- =========================================================================
   --  Test Drivers and Data Arrays 
   -- =========================================================================
   -- Positional initialization: ID, Arrival, Burst, Remaining, Completion, Wait, Turnaround
   Test_Set_SRT : Process_Array :=
     (1 => (1, 0, 8, 8, 0, 0, 0),
      2 => (2, 1, 4, 4, 0, 0, 0),
      3 => (3, 2, 9, 9, 0, 0, 0),
      4 => (4, 3, 5, 5, 0, 0, 0));

   Test_Set_SJN : Process_Array := Test_Set_SRT;
   
   Test_Set_CS  : Process_Array := Test_Set_SRT;

begin
   Put_Line ("=== 1. Shortest Remaining Time (SRT) - Preemptive ===");
   Simulate (Test_Set_SRT, Preemptive_SRT, Context_Switch => 0);
   Print_Results (Test_Set_SRT);
   New_Line;

   Put_Line ("=== 2. Shortest Job Next (SJN) - Non-Preemptive ===");
   Simulate (Test_Set_SJN, Non_Preemptive_SJN, Context_Switch => 0);
   Print_Results (Test_Set_SJN);
   New_Line;
   
   Put_Line ("=== 3. SRT Preemptive with Context Switch Penalty (1 unit) ===");
   Simulate (Test_Set_CS, Preemptive_SRT, Context_Switch => 1);
   Print_Results (Test_Set_CS);

end SRT_Simulation;
