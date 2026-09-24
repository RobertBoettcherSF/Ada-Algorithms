--  sjn_main.adb
--  Full implementation of Non-Preemptive and Preemptive SJN scheduling.

with Ada.Text_IO;       use Ada.Text_IO;
with Ada.Float_Text_IO; use Ada.Float_Text_IO;

procedure SJN_Main is

   type Time_Unit is new Natural;

   -- Represents a process/job in the system
   type Job is record
      ID              : Positive;
      Arrival_Time    : Time_Unit;
      Burst_Time      : Time_Unit;
      Remaining_Time  : Time_Unit;
      Completion_Time : Time_Unit;
      Waiting_Time    : Time_Unit;
      Turnaround_Time : Time_Unit;
      Is_Completed    : Boolean;
   end record;

   type Job_Array is array (Positive range <>) of Job;

   -- Helper procedure to cleanly output the simulation results
   procedure Print_Metrics (Jobs : Job_Array; Title : String) is
      Total_Waiting    : Time_Unit := 0;
      Total_Turnaround : Time_Unit := 0;
   begin
      Put_Line ("===================================================================");
      Put_Line (Title);
      Put_Line ("===================================================================");
      Put_Line ("Job ID | Arrival | Burst | Completion | Turnaround | Waiting");
      Put_Line ("-------------------------------------------------------------------");
      
      for I in Jobs'Range loop
         Put (Integer'Image (Jobs (I).ID) & ASCII.HT & " | ");
         Put (Integer'Image (Integer (Jobs (I).Arrival_Time)) & ASCII.HT & " | ");
         Put (Integer'Image (Integer (Jobs (I).Burst_Time)) & ASCII.HT & " | ");
         Put (Integer'Image (Integer (Jobs (I).Completion_Time)) & ASCII.HT & " | ");
         Put (Integer'Image (Integer (Jobs (I).Turnaround_Time)) & ASCII.HT & " | ");
         Put_Line (Integer'Image (Integer (Jobs (I).Waiting_Time)));

         Total_Waiting    := Total_Waiting + Jobs (I).Waiting_Time;
         Total_Turnaround := Total_Turnaround + Jobs (I).Turnaround_Time;
      end loop;
      
      Put_Line ("-------------------------------------------------------------------");
      Put ("Average Waiting Time   : ");
      Put (Item => Float (Total_Waiting) / Float (Jobs'Length), Fore => 1, Aft => 2, Exp => 0);
      New_Line;
      Put ("Average Turnaround Time: ");
      Put (Item => Float (Total_Turnaround) / Float (Jobs'Length), Fore => 1, Aft => 2, Exp => 0);
      New_Line (2);
   end Print_Metrics;


   -- =========================================================================
   -- VARIANT 1: Non-Preemptive Shortest Job Next (Basic SJF)
   -- =========================================================================
   procedure Run_Non_Preemptive_SJN (Input_Jobs : Job_Array) is
      Jobs            : Job_Array := Input_Jobs;
      Current_Time    : Time_Unit := 0;
      Completed_Count : Natural   := 0;
      Shortest_Idx    : Integer;
      Min_Burst       : Time_Unit;
   begin
      while Completed_Count < Jobs'Length loop
         Shortest_Idx := -1;
         Min_Burst    := Time_Unit'Last;

         -- Find the arrived job with the absolute shortest burst time
         for I in Jobs'Range loop
            if not Jobs (I).Is_Completed and then Jobs (I).Arrival_Time <= Current_Time then
               if Jobs (I).Burst_Time < Min_Burst then
                  Min_Burst    := Jobs (I).Burst_Time;
                  Shortest_Idx := I;
               elsif Jobs (I).Burst_Time = Min_Burst then
                  -- Tie-breaker: If burst times are equal, favor the one that arrived first
                  if Shortest_Idx /= -1 and then Jobs (I).Arrival_Time < Jobs (Shortest_Idx).Arrival_Time then
                     Shortest_Idx := I;
                  end if;
               end if;
            end if;
         end loop;

         if Shortest_Idx = -1 then
            -- CPU is idle, advance time
            Current_Time := Current_Time + 1;
         else
            -- Process executes to completion without interruption
            Current_Time := Current_Time + Jobs (Shortest_Idx).Burst_Time;
            
            Jobs (Shortest_Idx).Completion_Time := Current_Time;
            Jobs (Shortest_Idx).Turnaround_Time := Jobs (Shortest_Idx).Completion_Time - Jobs (Shortest_Idx).Arrival_Time;
            Jobs (Shortest_Idx).Waiting_Time    := Jobs (Shortest_Idx).Turnaround_Time - Jobs (Shortest_Idx).Burst_Time;
            Jobs (Shortest_Idx).Is_Completed    := True;
            
            Completed_Count := Completed_Count + 1;
         end if;
      end loop;

      Print_Metrics (Jobs, "Variant 1: Non-Preemptive SJN (Runs to completion)");
   end Run_Non_Preemptive_SJN;


   -- =========================================================================
   -- VARIANT 2: Preemptive Shortest Job Next (Shortest Remaining Time First)
   -- =========================================================================
   procedure Run_Preemptive_SJN (Input_Jobs : Job_Array) is
      Jobs            : Job_Array := Input_Jobs;
      Current_Time    : Time_Unit := 0;
      Completed_Count : Natural   := 0;
      Shortest_Idx    : Integer;
      Min_Remaining   : Time_Unit;
   begin
      -- Simulated clock ticks, evaluating preemptions every unit of time
      while Completed_Count < Jobs'Length loop
         Shortest_Idx  := -1;
         Min_Remaining := Time_Unit'Last;

         -- Dynamically find the arrived job with the shortest remaining time
         for I in Jobs'Range loop
            if not Jobs (I).Is_Completed and then Jobs (I).Arrival_Time <= Current_Time then
               if Jobs (I).Remaining_Time < Min_Remaining then
                  Min_Remaining := Jobs (I).Remaining_Time;
                  Shortest_Idx  := I;
               elsif Jobs (I).Remaining_Time = Min_Remaining then
                  -- Tie-breaker: FCFS for equal remaining times
                  if Shortest_Idx /= -1 and then Jobs (I).Arrival_Time < Jobs (Shortest_Idx).Arrival_Time then
                     Shortest_Idx := I;
                  end if;
               end if;
            end if;
         end loop;

         if Shortest_Idx = -1 then
            -- CPU is idle
            Current_Time := Current_Time + 1;
         else
            -- Execute chosen process for 1 time unit
            Jobs (Shortest_Idx).Remaining_Time := Jobs (Shortest_Idx).Remaining_Time - 1;
            Current_Time := Current_Time + 1;

            -- Check if process has finished after this tick
            if Jobs (Shortest_Idx).Remaining_Time = 0 then
               Jobs (Shortest_Idx).Completion_Time := Current_Time;
               Jobs (Shortest_Idx).Turnaround_Time := Jobs (Shortest_Idx).Completion_Time - Jobs (Shortest_Idx).Arrival_Time;
               Jobs (Shortest_Idx).Waiting_Time    := Jobs (Shortest_Idx).Turnaround_Time - Jobs (Shortest_Idx).Burst_Time;
               Jobs (Shortest_Idx).Is_Completed    := True;
               
               Completed_Count := Completed_Count + 1;
            end if;
         end if;
      end loop;

      Print_Metrics (Jobs, "Variant 2: Preemptive SJN (Shortest Remaining Time First)");
   end Run_Preemptive_SJN;


   -- =========================================================================
   -- Main Execution / Test Data
   -- =========================================================================
   -- We set Remaining_Time = Burst_Time initially for all jobs
   Test_Jobs : constant Job_Array :=
     (1 => (ID => 1, Arrival_Time => 0, Burst_Time => 8, Remaining_Time => 8, Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
      2 => (ID => 2, Arrival_Time => 1, Burst_Time => 4, Remaining_Time => 4, Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
      3 => (ID => 3, Arrival_Time => 2, Burst_Time => 9, Remaining_Time => 9, Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
      4 => (ID => 4, Arrival_Time => 3, Burst_Time => 5, Remaining_Time => 5, Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));

begin
   Put_Line ("Starting Shortest Job Next (SJN) / Shortest Job First (SJF) Simulations");
   New_Line;
   
   -- Run and compare both variants on the identical dataset
   Run_Non_Preemptive_SJN (Test_Jobs);
   Run_Preemptive_SJN (Test_Jobs);

end SJN_Main;
