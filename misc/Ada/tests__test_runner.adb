-------------------------------------------------------------------------------
--  Test Runner for SRT Scheduling Algorithm
--  This program tests various scenarios and validates the results
--  against expected values to ensure algorithm correctness.
-------------------------------------------------------------------------------
with Ada.Text_IO;         use Ada.Text_IO;
with Ada.Integer_Text_IO; use Ada.Integer_Text_IO;

procedure Test_Runner is

   -- =========================================================================
   --  Test Framework
   -- =========================================================================
   type Test_Result is (Pass, Fail);
   
   Total_Tests : Natural := 0;
   Passed_Tests : Natural := 0;
   Failed_Tests : Natural := 0;
   
   procedure Assert
     (Condition : Boolean;
      Test_Name : String;
      Message   : String := "")
   is
   begin
      Total_Tests := Total_Tests + 1;
      if Condition then
         Passed_Tests := Passed_Tests + 1;
         Put_Line ("  [PASS] " & Test_Name);
      else
         Failed_Tests := Failed_Tests + 1;
         Put_Line ("  [FAIL] " & Test_Name & " - " & Message);
      end if;
   end Assert;
   
   procedure Assert_Equal
     (Actual   : Natural;
      Expected : Natural;
      Test_Name : String)
   is
   begin
      Total_Tests := Total_Tests + 1;
      if Actual = Expected then
         Passed_Tests := Passed_Tests + 1;
         Put_Line ("  [PASS] " & Test_Name);
      else
         Failed_Tests := Failed_Tests + 1;
         Put_Line ("  [FAIL] " & Test_Name & " - Expected: " & 
                  Natural'Image(Expected) & ", Actual: " & 
                  Natural'Image(Actual));
      end if;
   end Assert_Equal;
   
   procedure Assert_Less
     (Actual   : Natural;
      Expected : Natural;
      Test_Name : String)
   is
   begin
      Total_Tests := Total_Tests + 1;
      if Actual < Expected then
         Passed_Tests := Passed_Tests + 1;
         Put_Line ("  [PASS] " & Test_Name);
      else
         Failed_Tests := Failed_Tests + 1;
         Put_Line ("  [FAIL] " & Test_Name & " - Expected: <" & 
                  Natural'Image(Expected) & ", Actual: " & 
                  Natural'Image(Actual));
      end if;
   end Assert_Less;
   
   procedure Print_Summary is
   begin
      New_Line;
      Put_Line ("========================================================================");
      Put_Line ("  Test Summary");
      Put_Line ("========================================================================");
      Put ("Total tests: ");
      Put (Total_Tests);
      New_Line;
      Put ("Passed: ");
      Put (Passed_Tests);
      New_Line;
      Put ("Failed: ");
      Put (Failed_Tests);
      New_Line;
      
      if Failed_Tests = 0 then
         Put_Line ("All tests passed!");
      else
         Put_Line ("Some tests failed.");
      end if;
   end Print_Summary;

   -- =========================================================================
   --  SRT Scheduler Package (Same as in main program)
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
      type Scheduling_Variant is (Preemptive_SRT, Non_Preemptive_SJN);

      procedure Simulate
        (Processes        : in out Process_Array;
         Variant          : Scheduling_Variant := Preemptive_SRT;
         Context_Switch   : Natural := 0);

      procedure Print_Results (Processes : Process_Array);
      
      -- Helper to get process by ID
      function Get_Process (Processes : Process_Array; ID : Process_ID) return Process_Record;
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
      
      function Get_Process (Processes : Process_Array; ID : Process_ID) return Process_Record is
         Result : Process_Record;
      begin
         for I in Processes'Range loop
            if Processes(I).ID = ID then
               return Processes(I);
            end if;
         end loop;
         return Result; -- Should not happen
      end Get_Process;

   end SRT_Scheduler;

   use SRT_Scheduler;

begin
   Put_Line ("========================================================================");
   Put_Line ("  SRT Scheduling Algorithm - Comprehensive Test Suite");
   Put_Line ("========================================================================");
   New_Line;

   -- =========================================================================
   --  TEST CATEGORY 1: Basic Functionality Tests
   -- =========================================================================
   Put_Line ("=== Category 1: Basic Functionality Tests ===");
   New_Line;

   -- Test 1: Single process should complete at its burst time
   declare
      Single_Process : Process_Array := (1 => (1, 0, 5, 5, 0, 0, 0));
   begin
      Simulate (Single_Process, Preemptive_SRT, 0);
      Assert_Equal (Single_Process(1).Completion_Time, 5, 
                    "Single process completes at burst time");
      Assert_Equal (Single_Process(1).Waiting_Time, 0, 
                    "Single process has zero waiting time");
      Assert_Equal (Single_Process(1).Turnaround_Time, 5, 
                    "Single process turnaround = burst time");
   end;

   -- Test 2: Two processes, shorter burst should complete first (preemptive)
   declare
      Two_Processes : Process_Array := 
        (1 => (1, 0, 10, 10, 0, 0, 0),
         2 => (2, 1, 3, 3, 0, 0, 0));
   begin
      Simulate (Two_Processes, Preemptive_SRT, 0);
      Assert_Less (Two_Processes(2).Completion_Time, Two_Processes(1).Completion_Time,
                  "Shorter process (P2) completes before longer (P1) in preemptive mode");
      Assert_Equal (Two_Processes(2).Completion_Time, 4,
                    "P2 completes at time 4 (arrives at 1, burst 3)");
   end;

   -- Test 3: Non-preemptive mode - first process runs to completion
   declare
      Two_Processes_NP : Process_Array := 
        (1 => (1, 0, 5, 5, 0, 0, 0),
         2 => (2, 1, 3, 3, 0, 0, 0));
   begin
      Simulate (Two_Processes_NP, Non_Preemptive_SJN, 0);
      Assert_Equal (Two_Processes_NP(1).Completion_Time, 5,
                    "P1 completes at time 5 in non-preemptive mode");
      Assert_Equal (Two_Processes_NP(2).Completion_Time, 8,
                    "P2 completes at time 8 (starts at 5, burst 3)");
      Assert_Equal (Two_Processes_NP(2).Waiting_Time, 4,
                    "P2 waits 4 units (from 1 to 5)");
   end;

   New_Line;

   -- =========================================================================
   --  TEST CATEGORY 2: Edge Cases
   -- =========================================================================
   Put_Line ("=== Category 2: Edge Cases ===");
   New_Line;

   -- Test 4: Processes arriving at same time - shorter burst first
   declare
      Same_Arrival : Process_Array := 
        (1 => (1, 0, 8, 8, 0, 0, 0),
         2 => (2, 0, 4, 4, 0, 0, 0));
   begin
      Simulate (Same_Arrival, Preemptive_SRT, 0);
      Assert_Less (Same_Arrival(2).Completion_Time, Same_Arrival(1).Completion_Time,
                  "Shorter burst (P2) completes first when arrival times are equal");
      Assert_Equal (Same_Arrival(2).Completion_Time, 4,
                    "P2 completes at time 4");
      Assert_Equal (Same_Arrival(1).Completion_Time, 12,
                    "P1 completes at time 12");
   end;

   -- Test 5: Same burst time - lower ID first (tie-breaker)
   declare
      Same_Burst : Process_Array := 
        (1 => (2, 0, 5, 5, 0, 0, 0),
         2 => (1, 0, 5, 5, 0, 0, 0));
   begin
      Simulate (Same_Burst, Preemptive_SRT, 0);
      -- P2 has ID=1, P1 has ID=2, so P2 should complete first
      Assert_Less (Same_Burst(2).Completion_Time, Same_Burst(1).Completion_Time,
                  "Lower ID process completes first when burst times are equal");
   end;

   -- Test 6: Process arriving after current completes
   declare
      Sequential : Process_Array := 
        (1 => (1, 0, 5, 5, 0, 0, 0),
         2 => (2, 5, 3, 3, 0, 0, 0));
   begin
      Simulate (Sequential, Preemptive_SRT, 0);
      Assert_Equal (Sequential(1).Completion_Time, 5,
                    "P1 completes at time 5");
      Assert_Equal (Sequential(2).Completion_Time, 8,
                    "P2 completes at time 8 (starts at 5)");
      Assert_Equal (Sequential(2).Waiting_Time, 0,
                    "P2 has zero waiting time (starts immediately)");
   end;

   -- Test 7: CPU idle when no processes are ready
   declare
      Late_Arrival : Process_Array := 
        (1 => (1, 5, 3, 3, 0, 0, 0));
   begin
      Simulate (Late_Arrival, Preemptive_SRT, 0);
      Assert_Equal (Late_Arrival(1).Completion_Time, 8,
                    "Process starting at 5 completes at 8");
      Assert_Equal (Late_Arrival(1).Waiting_Time, 0,
                    "Process has zero waiting time");
   end;

   New_Line;

   -- =========================================================================
   --  TEST CATEGORY 3: Context Switch Overhead
   -- =========================================================================
   Put_Line ("=== Category 3: Context Switch Overhead ===");
   New_Line;

   -- Test 8: Zero context switch penalty
   declare
      No_CS : Process_Array := 
        (1 => (1, 0, 5, 5, 0, 0, 0),
         2 => (2, 1, 3, 3, 0, 0, 0));
      With_CS : Process_Array := No_CS;
   begin
      Simulate (No_CS, Preemptive_SRT, 0);
      Simulate (With_CS, Preemptive_SRT, 1);
      -- With context switch, completion times should be later
      Assert_Less (No_CS(2).Completion_Time, With_CS(2).Completion_Time,
                  "Context switch penalty delays completion");
   end;

   -- Test 9: Context switch with penalty = 2
   declare
      CS2 : Process_Array := 
        (1 => (1, 0, 5, 5, 0, 0, 0),
         2 => (2, 1, 3, 3, 0, 0, 0));
   begin
      Simulate (CS2, Preemptive_SRT, 2);
      -- P2 should complete later than without context switch
      Assert_Less (4, CS2(2).Completion_Time,
                  "P2 completes after time 4 with context switch penalty");
   end;

   New_Line;

   -- =========================================================================
   --  TEST CATEGORY 4: Waiting and Turnaround Time Validation
   -- =========================================================================
   Put_Line ("=== Category 4: Waiting and Turnaround Time Validation ===");
   New_Line;

   -- Test 10: Turnaround = Completion - Arrival
   declare
      Turnaround_Test : Process_Array := 
        (1 => (1, 2, 5, 5, 0, 0, 0));
   begin
      Simulate (Turnaround_Test, Preemptive_SRT, 0);
      Assert_Equal (Turnaround_Test(1).Turnaround_Time, 
                    Turnaround_Test(1).Completion_Time - Turnaround_Test(1).Arrival_Time,
                    "Turnaround time = Completion - Arrival");
   end;

   -- Test 11: Waiting = Turnaround - Burst
   declare
      Waiting_Test : Process_Array := 
        (1 => (1, 0, 5, 5, 0, 0, 0),
         2 => (2, 1, 3, 3, 0, 0, 0));
   begin
      Simulate (Waiting_Test, Preemptive_SRT, 0);
      for I in Waiting_Test'Range loop
         Assert_Equal (Waiting_Test(I).Waiting_Time,
                      Waiting_Test(I).Turnaround_Time - Waiting_Test(I).Burst_Time,
                      "Waiting time = Turnaround - Burst for process " & 
                      Integer'Image(Integer(Waiting_Test(I).ID)));
      end loop;
   end;

   -- Test 12: First process has zero waiting time
   declare
      First_Process : Process_Array := 
        (1 => (1, 0, 5, 5, 0, 0, 0),
         2 => (2, 1, 3, 3, 0, 0, 0));
   begin
      Simulate (First_Process, Preemptive_SRT, 0);
      Assert_Equal (First_Process(1).Waiting_Time, 0,
                    "First process (P1) has zero waiting time");
   end;

   New_Line;

   -- =========================================================================
   --  TEST CATEGORY 5: Tests Designed to Prove Assumptions Wrong
   -- =========================================================================
   Put_Line ("=== Category 5: Tests Proving Wrong Assumptions ===");
   New_Line;

   -- Test 13: WRONG ASSUMPTION - All processes complete at arrival + burst
   -- Reality: Preemption causes some processes to complete later
   declare
      Preemption_Delay : Process_Array := 
        (1 => (1, 0, 10, 10, 0, 0, 0),
         2 => (2, 1, 3, 3, 0, 0, 0));
   begin
      Simulate (Preemption_Delay, Preemptive_SRT, 0);
      -- P1 is preempted, so it completes AFTER arrival + burst
      Assert_Less (10, Preemption_Delay(1).Completion_Time,
                  "WRONG ASSUMPTION PROVEN: P1 completes after arrival+burst due to preemption");
   end;

   -- Test 14: WRONG ASSUMPTION - Non-preemptive SJN is always faster than SRT
   -- Reality: SRT can have lower average waiting time
   declare
      SRT_Set : Process_Array := 
        (1 => (1, 0, 8, 8, 0, 0, 0),
         2 => (2, 1, 4, 4, 0, 0, 0),
         3 => (3, 2, 9, 9, 0, 0, 0),
         4 => (4, 3, 5, 5, 0, 0, 0));
      SJN_Set : Process_Array := SRT_Set;
      
      SRT_Avg_Wait : Natural := 0;
      SJN_Avg_Wait : Natural := 0;
   begin
      Simulate (SRT_Set, Preemptive_SRT, 0);
      Simulate (SJN_Set, Non_Preemptive_SJN, 0);
      
      -- Calculate average waiting times
      for I in SRT_Set'Range loop
         SRT_Avg_Wait := SRT_Avg_Wait + SRT_Set(I).Waiting_Time;
         SJN_Avg_Wait := SJN_Avg_Wait + SJN_Set(I).Waiting_Time;
      end loop;
      
      -- SRT should have lower or equal average waiting time
      Assert_Less (SRT_Avg_Wait, SJN_Avg_Wait,
                  "WRONG ASSUMPTION PROVEN: SRT has lower avg waiting than non-preemptive SJN");
   end;

   -- Test 15: WRONG ASSUMPTION - Context switch penalty doesn't affect results
   -- Reality: It does affect completion times
   declare
      No_Penalty : Process_Array := 
        (1 => (1, 0, 5, 5, 0, 0, 0),
         2 => (2, 1, 3, 3, 0, 0, 0));
      With_Penalty : Process_Array := No_Penalty;
   begin
      Simulate (No_Penalty, Preemptive_SRT, 0);
      Simulate (With_Penalty, Preemptive_SRT, 1);
      
      -- At least one process should complete later with penalty
      Assert (No_Penalty(1).Completion_Time < With_Penalty(1).Completion_Time or
              No_Penalty(2).Completion_Time < With_Penalty(2).Completion_Time,
              "WRONG ASSUMPTION PROVEN: Context switch penalty DOES affect results");
   end;

   New_Line;

   -- =========================================================================
   --  TEST CATEGORY 6: Algorithm Correctness (Code Example Validation)
   -- =========================================================================
   Put_Line ("=== Category 6: Code Example Validation ===");
   New_Line;

   -- Test 16: Validate the example from the main code (Preemptive SRT)
   declare
      Code_Example_SRT : Process_Array := 
        (1 => (1, 0, 8, 8, 0, 0, 0),
         2 => (2, 1, 4, 4, 0, 0, 0),
         3 => (3, 2, 9, 9, 0, 0, 0),
         4 => (4, 3, 5, 5, 0, 0, 0));
   begin
      Simulate (Code_Example_SRT, Preemptive_SRT, 0);
      
      -- Expected results based on manual calculation:
      -- P1: completion=17, waiting=9, turnaround=17
      -- P2: completion=5, waiting=0, turnaround=4
      -- P3: completion=26, waiting=17, turnaround=24
      -- P4: completion=10, waiting=2, turnaround=7
      
      Assert_Equal (Code_Example_SRT(2).Completion_Time, 5,
                    "P2 completes at time 5");
      Assert_Equal (Code_Example_SRT(2).Waiting_Time, 0,
                    "P2 has 0 waiting time");
      Assert_Equal (Code_Example_SRT(2).Turnaround_Time, 4,
                    "P2 turnaround is 4");
      
      Assert_Equal (Code_Example_SRT(4).Completion_Time, 10,
                    "P4 completes at time 10");
      Assert_Equal (Code_Example_SRT(4).Waiting_Time, 2,
                    "P4 waits 2 units");
      
      Assert_Equal (Code_Example_SRT(1).Completion_Time, 17,
                    "P1 completes at time 17");
      Assert_Equal (Code_Example_SRT(1).Waiting_Time, 9,
                    "P1 waits 9 units");
      
      Assert_Equal (Code_Example_SRT(3).Completion_Time, 26,
                    "P3 completes at time 26");
      Assert_Equal (Code_Example_SRT(3).Waiting_Time, 17,
                    "P3 waits 17 units");
   end;

   -- Test 17: Validate the example from the main code (Non-Preemptive SJN)
   declare
      Code_Example_SJN : Process_Array := 
        (1 => (1, 0, 8, 8, 0, 0, 0),
         2 => (2, 1, 4, 4, 0, 0, 0),
         3 => (3, 2, 9, 9, 0, 0, 0),
         4 => (4, 3, 5, 5, 0, 0, 0));
   begin
      Simulate (Code_Example_SJN, Non_Preemptive_SJN, 0);
      
      -- Expected results based on manual calculation:
      -- P1: completion=8, waiting=0, turnaround=8
      -- P2: completion=12, waiting=7, turnaround=11
      -- P3: completion=26, waiting=17, turnaround=24
      -- P4: completion=17, waiting=9, turnaround=14
      
      Assert_Equal (Code_Example_SJN(1).Completion_Time, 8,
                    "P1 completes at time 8");
      Assert_Equal (Code_Example_SJN(1).Waiting_Time, 0,
                    "P1 has 0 waiting time");
      
      Assert_Equal (Code_Example_SJN(2).Completion_Time, 12,
                    "P2 completes at time 12");
      Assert_Equal (Code_Example_SJN(2).Waiting_Time, 7,
                    "P2 waits 7 units");
      
      Assert_Equal (Code_Example_SJN(4).Completion_Time, 17,
                    "P4 completes at time 17");
      Assert_Equal (Code_Example_SJN(4).Waiting_Time, 9,
                    "P4 waits 9 units");
      
      Assert_Equal (Code_Example_SJN(3).Completion_Time, 26,
                    "P3 completes at time 26");
      Assert_Equal (Code_Example_SJN(3).Waiting_Time, 17,
                    "P3 waits 17 units");
   end;

   -- Test 18: Validate context switch example from main code
   declare
      Code_Example_CS : Process_Array := 
        (1 => (1, 0, 8, 8, 0, 0, 0),
         2 => (2, 1, 4, 4, 0, 0, 0),
         3 => (3, 2, 9, 9, 0, 0, 0),
         4 => (4, 3, 5, 5, 0, 0, 0));
   begin
      Simulate (Code_Example_CS, Preemptive_SRT, 1);
      
      -- With context switch penalty of 1, all completion times should be delayed
      -- compared to no penalty
      Assert_Less (5, Code_Example_CS(2).Completion_Time,
                  "P2 completes after time 5 with context switch");
      Assert_Less (10, Code_Example_CS(4).Completion_Time,
                  "P4 completes after time 10 with context switch");
      Assert_Less (17, Code_Example_CS(1).Completion_Time,
                  "P1 completes after time 17 with context switch");
   end;

   New_Line;

   -- =========================================================================
   --  Print Summary
   -- =========================================================================
   Print_Summary;

end Test_Runner;
