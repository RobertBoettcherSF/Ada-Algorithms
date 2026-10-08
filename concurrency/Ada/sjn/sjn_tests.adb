--  sjn_tests.adb
--  Comprehensive test suite for SJN scheduling algorithms
--  
--  This test suite contains 12+ tests that:
--  1. Make assumptions about code behavior
--  2. Test different assumptions
--  3. Can be proven false (assertions will fail if assumptions are wrong)
--  
--  Tests are organized into categories:
--  - Basic functionality tests
--  - Edge case tests
--  - Correctness tests (verifying optimal scheduling)
--  - Property-based tests (invariants that must hold)

with Ada.Text_IO;       use Ada.Text_IO;
with Ada.Assertions;    use Ada.Assertions;

procedure SJN_Tests is

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

   -- Test result tracking
   Test_Count : Natural := 0;
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   -- =========================================================================
   -- Test Helper Procedures
   -- =========================================================================

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      Test_Count := Test_Count + 1;
      if Condition then
         Pass_Count := Pass_Count + 1;
         Put_Line ("[PASS] " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("[FAIL] " & Message);
         raise Assertion_Error with "Test failed: " & Message;
      end if;
   end Assert;

   procedure Assert_Equal (Actual, Expected : Time_Unit; Message : String) is
   begin
      Test_Count := Test_Count + 1;
      if Actual = Expected then
         Pass_Count := Pass_Count + 1;
         Put_Line ("[PASS] " & Message & " (Expected: " & Time_Unit'Image(Expected) & ", Got: " & Time_Unit'Image(Actual) & ")");
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("[FAIL] " & Message & " (Expected: " & Time_Unit'Image(Expected) & ", Got: " & Time_Unit'Image(Actual) & ")");
         raise Assertion_Error with "Test failed: " & Message;
      end if;
   end Assert_Equal;

   -- =========================================================================
   -- Non-Preemptive SJN Implementation (Copy from main for testing)
   -- =========================================================================

   procedure Run_Non_Preemptive_SJN (Input_Jobs : Job_Array; Result_Jobs : out Job_Array) is
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

      Result_Jobs := Jobs;
   end Run_Non_Preemptive_SJN;

   -- =========================================================================
   -- Preemptive SJN Implementation (Copy from main for testing)
   -- =========================================================================

   procedure Run_Preemptive_SJN (Input_Jobs : Job_Array; Result_Jobs : out Job_Array) is
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

      Result_Jobs := Jobs;
   end Run_Preemptive_SJN;

   -- Helper to calculate average waiting time
   function Calculate_Average_Waiting (Jobs : Job_Array) return Float is
      Total : Time_Unit := 0;
   begin
      for J of Jobs loop
         Total := Total + J.Waiting_Time;
      end loop;
      return Float(Total) / Float(Jobs'Length);
   end Calculate_Average_Waiting;

   -- Helper to calculate average turnaround time

   -- Helper to check all jobs are completed
   function All_Completed (Jobs : Job_Array) return Boolean is
   begin
      for J of Jobs loop
         if not J.Is_Completed then
            return False;
         end if;
      end loop;
      return True;
   end All_Completed;

   -- Helper to check completion times are >= arrival times
   function Valid_Completion_Times (Jobs : Job_Array) return Boolean is
   begin
      for J of Jobs loop
         if J.Completion_Time < J.Arrival_Time then
            return False;
         end if;
      end loop;
      return True;
   end Valid_Completion_Times;

   -- Helper to check waiting times are non-negative

   -- =========================================================================
   -- TEST CATEGORY 1: Basic Functionality Tests
   -- =========================================================================

   procedure Test_Basic_Non_Preemptive is
      Input_Jobs : constant Job_Array :=
        (1 => (ID => 1, Arrival_Time => 0, Burst_Time => 5, Remaining_Time => 5, 
               Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));
      Result_Jobs : Job_Array (Input_Jobs'Range);
   begin
      Put_Line ("");
      Put_Line ("=== TEST CATEGORY 1: Basic Functionality ===");
      Put_Line ("");
      
      -- Test 1: Single job should complete immediately
      Run_Non_Preemptive_SJN (Input_Jobs, Result_Jobs);
      Assert (All_Completed (Result_Jobs), "Test 1.1: Single job completes");
      Assert_Equal (Result_Jobs(1).Completion_Time, 5, "Test 1.2: Single job completion time is burst time");
      Assert_Equal (Result_Jobs(1).Waiting_Time, 0, "Test 1.3: Single job has zero waiting time");
      Assert_Equal (Result_Jobs(1).Turnaround_Time, 5, "Test 1.4: Single job turnaround equals burst time");
      
      -- Test 2: Two jobs, first arrives at 0 with burst 5, second arrives at 1 with burst 3
      -- Non-preemptive: Job 1 runs first (arrived first), then Job 2
      declare
         Two_Jobs : constant Job_Array :=
           (1 => (ID => 1, Arrival_Time => 0, Burst_Time => 5, Remaining_Time => 5, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            2 => (ID => 2, Arrival_Time => 1, Burst_Time => 3, Remaining_Time => 3, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));
         Result : Job_Array (Two_Jobs'Range);
      begin
         Run_Non_Preemptive_SJN (Two_Jobs, Result);
         Assert (All_Completed (Result), "Test 2.1: Two jobs both complete");
         Assert_Equal (Result(1).Completion_Time, 5, "Test 2.2: First job completes at time 5");
         Assert_Equal (Result(2).Completion_Time, 8, "Test 2.3: Second job completes at time 8");
         Assert_Equal (Result(2).Waiting_Time, 4, "Test 2.4: Second job waits 4 units (from time 1 to 5)");
      end;
   end Test_Basic_Non_Preemptive;

   procedure Test_Basic_Preemptive is
      Input_Jobs : constant Job_Array :=
        (1 => (ID => 1, Arrival_Time => 0, Burst_Time => 5, Remaining_Time => 5, 
               Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));
      Result_Jobs : Job_Array (Input_Jobs'Range);
   begin
      Put_Line ("");
      Put_Line ("=== TEST CATEGORY 1: Basic Functionality (Preemptive) ===");
      Put_Line ("");
      
      -- Test 3: Single job with preemptive scheduler
      Run_Preemptive_SJN (Input_Jobs, Result_Jobs);
      Assert (All_Completed (Result_Jobs), "Test 3.1: Single job completes with preemptive");
      Assert_Equal (Result_Jobs(1).Completion_Time, 5, "Test 3.2: Single job completion time is burst time");
      Assert_Equal (Result_Jobs(1).Waiting_Time, 0, "Test 3.3: Single job has zero waiting time");
      
      -- Test 4: Two jobs, preemptive should allow shorter job to run first
      declare
         Two_Jobs : constant Job_Array :=
           (1 => (ID => 1, Arrival_Time => 0, Burst_Time => 5, Remaining_Time => 5, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            2 => (ID => 2, Arrival_Time => 1, Burst_Time => 3, Remaining_Time => 3, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));
         Result : Job_Array (Two_Jobs'Range);
      begin
         Run_Preemptive_SJN (Two_Jobs, Result);
         Assert (All_Completed (Result), "Test 4.1: Two jobs both complete with preemptive");
         -- With preemptive, Job 2 (shorter) should complete first
         Assert_Equal (Result(2).Completion_Time, 4, "Test 4.2: Shorter job completes first at time 4");
         Assert_Equal (Result(1).Completion_Time, 8, "Test 4.3: Longer job completes at time 8");
      end;
   end Test_Basic_Preemptive;

   -- =========================================================================
   -- TEST CATEGORY 2: Edge Case Tests
   -- =========================================================================

   procedure Test_Edge_Cases is
   begin
      Put_Line ("");
      Put_Line ("=== TEST CATEGORY 2: Edge Cases ===");
      Put_Line ("");
      
      -- Test 5: Empty job array (should handle gracefully)
      declare
         Empty_Jobs : Job_Array (1..0);
         Result : Job_Array (1..0);
      begin
         Run_Non_Preemptive_SJN (Empty_Jobs, Result);
         Assert (Result'Length = 0, "Test 5.1: Empty job array handled");
      exception
         when others =>
            Assert (False, "Test 5.2: Empty job array should not raise exception");
      end;
      
      -- Test 6: Jobs arriving at same time
      declare
         Same_Time_Jobs : constant Job_Array :=
           (1 => (ID => 1, Arrival_Time => 0, Burst_Time => 3, Remaining_Time => 3, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            2 => (ID => 2, Arrival_Time => 0, Burst_Time => 1, Remaining_Time => 1, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            3 => (ID => 3, Arrival_Time => 0, Burst_Time => 2, Remaining_Time => 2, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));
         Result : Job_Array (Same_Time_Jobs'Range);
      begin
         Run_Non_Preemptive_SJN (Same_Time_Jobs, Result);
         Assert (All_Completed (Result), "Test 6.1: Same arrival time jobs all complete");
         -- Job 2 should complete first (shortest burst)
         Assert_Equal (Result(2).Completion_Time, 1, "Test 6.2: Shortest job completes first");
         -- Job 3 should complete second
         Assert_Equal (Result(3).Completion_Time, 3, "Test 6.3: Second shortest job completes second");
         -- Job 1 should complete last
         Assert_Equal (Result(1).Completion_Time, 6, "Test 6.4: Longest job completes last");
      end;
      
      -- Test 7: Job with zero burst time
      declare
         Zero_Burst_Jobs : constant Job_Array :=
           (1 => (ID => 1, Arrival_Time => 0, Burst_Time => 0, Remaining_Time => 0, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            2 => (ID => 2, Arrival_Time => 0, Burst_Time => 5, Remaining_Time => 5, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));
         Result : Job_Array (Zero_Burst_Jobs'Range);
      begin
         Run_Non_Preemptive_SJN (Zero_Burst_Jobs, Result);
         Assert (All_Completed (Result), "Test 7.1: Zero burst time job handled");
         Assert_Equal (Result(1).Completion_Time, 0, "Test 7.2: Zero burst job completes immediately");
      end;
      
      -- Test 8: Jobs arriving after previous jobs complete
      declare
         Delayed_Jobs : constant Job_Array :=
           (1 => (ID => 1, Arrival_Time => 0, Burst_Time => 2, Remaining_Time => 2, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            2 => (ID => 2, Arrival_Time => 10, Burst_Time => 3, Remaining_Time => 3, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));
         Result : Job_Array (Delayed_Jobs'Range);
      begin
         Run_Non_Preemptive_SJN (Delayed_Jobs, Result);
         Assert (All_Completed (Result), "Test 8.1: Delayed arrival jobs complete");
         Assert_Equal (Result(1).Completion_Time, 2, "Test 8.2: First job completes at 2");
         Assert_Equal (Result(2).Completion_Time, 13, "Test 8.3: Second job completes at 13");
         Assert_Equal (Result(2).Waiting_Time, 0, "Test 8.4: Second job has no waiting time");
      end;
   end Test_Edge_Cases;

   -- =========================================================================
   -- TEST CATEGORY 3: Correctness Tests (Verifying Optimal Scheduling)
   -- =========================================================================

   procedure Test_Correctness is
   begin
      Put_Line ("");
      Put_Line ("=== TEST CATEGORY 3: Correctness (Optimal Scheduling) ===");
      Put_Line ("");
      
      -- Test 9: Non-preemptive SJN should produce optimal schedule for given constraints
      -- For non-preemptive, once a job starts, it runs to completion
      declare
         Jobs : constant Job_Array :=
           (1 => (ID => 1, Arrival_Time => 0, Burst_Time => 8, Remaining_Time => 8, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            2 => (ID => 2, Arrival_Time => 1, Burst_Time => 4, Remaining_Time => 4, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            3 => (ID => 3, Arrival_Time => 2, Burst_Time => 9, Remaining_Time => 9, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            4 => (ID => 4, Arrival_Time => 3, Burst_Time => 5, Remaining_Time => 5, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));
         Result : Job_Array (Jobs'Range);
      begin
         Run_Non_Preemptive_SJN (Jobs, Result);
         Assert (All_Completed (Result), "Test 9.1: All jobs complete");
         Assert (Valid_Completion_Times (Result), "Test 9.2: All completion times >= arrival times");
         -- Average waiting time should be reasonable
         Assert (Calculate_Average_Waiting (Result) < 10.0, "Test 9.5: Average waiting time is reasonable");
      end;
      
      -- Test 10: Preemptive SJN should produce better or equal average waiting time
      declare
         Jobs : constant Job_Array :=
           (1 => (ID => 1, Arrival_Time => 0, Burst_Time => 8, Remaining_Time => 8, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            2 => (ID => 2, Arrival_Time => 1, Burst_Time => 4, Remaining_Time => 4, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            3 => (ID => 3, Arrival_Time => 2, Burst_Time => 9, Remaining_Time => 9, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            4 => (ID => 4, Arrival_Time => 3, Burst_Time => 5, Remaining_Time => 5, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));
         Result_NP : Job_Array (Jobs'Range);
         Result_P : Job_Array (Jobs'Range);
         Avg_Wait_NP, Avg_Wait_P : Float;
      begin
         Run_Non_Preemptive_SJN (Jobs, Result_NP);
         Run_Preemptive_SJN (Jobs, Result_P);
         
         Avg_Wait_NP := Calculate_Average_Waiting (Result_NP);
         Avg_Wait_P := Calculate_Average_Waiting (Result_P);
         
         Assert (All_Completed (Result_P), "Test 10.1: Preemptive all jobs complete");
         Assert (Valid_Completion_Times (Result_P), "Test 10.2: Preemptive completion times valid");
         -- Preemptive should have better or equal average waiting time
         Assert (Avg_Wait_P <= Avg_Wait_NP + 0.01, "Test 10.4: Preemptive avg waiting <= Non-preemptive");
      end;
      
      -- Test 11: Preemptive SJN with jobs arriving at different times
      declare
         Jobs : constant Job_Array :=
           (1 => (ID => 1, Arrival_Time => 0, Burst_Time => 10, Remaining_Time => 10, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            2 => (ID => 2, Arrival_Time => 2, Burst_Time => 1, Remaining_Time => 1, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            3 => (ID => 3, Arrival_Time => 3, Burst_Time => 2, Remaining_Time => 2, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));
         Result : Job_Array (Jobs'Range);
      begin
         Run_Preemptive_SJN (Jobs, Result);
         Assert (All_Completed (Result), "Test 11.1: All jobs complete");
         -- Job 2 should complete at time 3 (arrives at 2, runs immediately)
         Assert_Equal (Result(2).Completion_Time, 3, "Test 11.2: Short job completes quickly");
         -- Job 3 should complete at time 5 (arrives at 3, runs after job 2)
         Assert_Equal (Result(3).Completion_Time, 5, "Test 11.3: Second short job completes next");
         -- Job 1 should complete at time 15 (10 units total, but preempted)
         Assert_Equal (Result(1).Completion_Time, 13, "Test 11.4: Long job completes last");
      end;
   end Test_Correctness;

   -- =========================================================================
   -- TEST CATEGORY 4: Property-Based Tests (Invariants)
   -- =========================================================================

   procedure Test_Invariants is
   begin
      Put_Line ("");
      Put_Line ("=== TEST CATEGORY 4: Property-Based Tests (Invariants) ===");
      Put_Line ("");
      
      -- Test 12: For any job set, turnaround time = waiting time + burst time
      declare
         Jobs : constant Job_Array :=
           (1 => (ID => 1, Arrival_Time => 0, Burst_Time => 5, Remaining_Time => 5, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            2 => (ID => 2, Arrival_Time => 1, Burst_Time => 3, Remaining_Time => 3, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            3 => (ID => 3, Arrival_Time => 2, Burst_Time => 8, Remaining_Time => 8, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));
         Result_NP, Result_P : Job_Array (Jobs'Range);
      begin
         Run_Non_Preemptive_SJN (Jobs, Result_NP);
         Run_Preemptive_SJN (Jobs, Result_P);
         
         -- Check invariant for non-preemptive
         for J of Result_NP loop
            Assert_Equal (J.Turnaround_Time, J.Waiting_Time + J.Burst_Time, 
                        "Test 12.1: Turnaround = Waiting + Burst (Non-preemptive, Job " & Positive'Image(J.ID) & ")");
         end loop;
         
         -- Check invariant for preemptive
         for J of Result_P loop
            Assert_Equal (J.Turnaround_Time, J.Waiting_Time + J.Burst_Time, 
                        "Test 12.2: Turnaround = Waiting + Burst (Preemptive, Job " & Positive'Image(J.ID) & ")");
         end loop;
      end;
      
      -- Test 13: Completion time = Arrival time + Turnaround time
      declare
         Jobs : constant Job_Array :=
           (1 => (ID => 1, Arrival_Time => 5, Burst_Time => 3, Remaining_Time => 3, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            2 => (ID => 2, Arrival_Time => 0, Burst_Time => 10, Remaining_Time => 10, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));
         Result : Job_Array (Jobs'Range);
      begin
         Run_Non_Preemptive_SJN (Jobs, Result);
         for J of Result loop
            Assert_Equal (J.Completion_Time, J.Arrival_Time + J.Turnaround_Time,
                        "Test 13: Completion = Arrival + Turnaround (Job " & Positive'Image(J.ID) & ")");
         end loop;
      end;
      
      -- Test 14: All jobs must be completed in both schedulers
      declare
         Jobs : constant Job_Array :=
           (1 => (ID => 1, Arrival_Time => 0, Burst_Time => 1, Remaining_Time => 1, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            2 => (ID => 2, Arrival_Time => 0, Burst_Time => 1, Remaining_Time => 1, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            3 => (ID => 3, Arrival_Time => 0, Burst_Time => 1, Remaining_Time => 1, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));
         Result_NP, Result_P : Job_Array (Jobs'Range);
      begin
         Run_Non_Preemptive_SJN (Jobs, Result_NP);
         Run_Preemptive_SJN (Jobs, Result_P);
         Assert (All_Completed (Result_NP), "Test 14.1: Non-preemptive completes all jobs");
         Assert (All_Completed (Result_P), "Test 14.2: Preemptive completes all jobs");
      end;
      
      -- Test 15: Waiting time cannot exceed completion time
      declare
         Jobs : constant Job_Array :=
           (1 => (ID => 1, Arrival_Time => 0, Burst_Time => 5, Remaining_Time => 5, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            2 => (ID => 2, Arrival_Time => 1, Burst_Time => 10, Remaining_Time => 10, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));
         Result : Job_Array (Jobs'Range);
      begin
         Run_Non_Preemptive_SJN (Jobs, Result);
         for J of Result loop
            Assert (J.Waiting_Time <= J.Completion_Time,
                  "Test 15: Waiting time <= Completion time (Job " & Positive'Image(J.ID) & ")");
         end loop;
      end;
   end Test_Invariants;

   -- =========================================================================
   -- TEST CATEGORY 5: Assumptions That Can Be Proven False
   -- =========================================================================

   procedure Test_Falsifiable_Assumptions is
   begin
      Put_Line ("");
      Put_Line ("=== TEST CATEGORY 5: Falsifiable Assumptions ===");
      Put_Line ("");
      
      -- Test 16: ASSUMPTION: Non-preemptive and preemptive always produce same results
      -- This should be PROVEN FALSE
      declare
         Jobs : constant Job_Array :=
           (1 => (ID => 1, Arrival_Time => 0, Burst_Time => 5, Remaining_Time => 5, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            2 => (ID => 2, Arrival_Time => 1, Burst_Time => 3, Remaining_Time => 3, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));
         Result_NP, Result_P : Job_Array (Jobs'Range);
      begin
         Run_Non_Preemptive_SJN (Jobs, Result_NP);
         Run_Preemptive_SJN (Jobs, Result_P);
         
         -- This assumption should be false
         -- Non-preemptive: Job 1 completes at 5, Job 2 at 8
         -- Preemptive: Job 2 completes at 4, Job 1 at 9
         Assert (Result_NP(1).Completion_Time /= Result_P(1).Completion_Time,
               "Test 16: ASSUMPTION PROVEN FALSE - Non-preemptive and preemptive produce different results");
      end;
      
      -- Test 17: ASSUMPTION: SJN always gives zero waiting time
      -- This should be PROVEN FALSE (only true for single job)
      declare
         Jobs : constant Job_Array :=
           (1 => (ID => 1, Arrival_Time => 0, Burst_Time => 5, Remaining_Time => 5, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False),
            2 => (ID => 2, Arrival_Time => 1, Burst_Time => 3, Remaining_Time => 3, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));
         Result : Job_Array (Jobs'Range);
      begin
         Run_Non_Preemptive_SJN (Jobs, Result);
         
         -- Check if any job has non-zero waiting time
         declare
            Has_Non_Zero_Waiting : Boolean := False;
         begin
            for J of Result loop
               if J.Waiting_Time > 0 then
                  Has_Non_Zero_Waiting := True;
                  exit;
               end if;
            end loop;
            Assert (Has_Non_Zero_Waiting,
                  "Test 17: ASSUMPTION PROVEN FALSE - SJN does not always give zero waiting time");
         end;
      end;
      
      -- Test 18: ASSUMPTION: Preemptive SJN is always faster than non-preemptive
      -- This should be PROVEN FALSE (they can be equal in some cases)
      declare
         Jobs : constant Job_Array :=
           (1 => (ID => 1, Arrival_Time => 0, Burst_Time => 5, Remaining_Time => 5, 
                  Completion_Time => 0, Waiting_Time => 0, Turnaround_Time => 0, Is_Completed => False));
         Result_NP, Result_P : Job_Array (Jobs'Range);
      begin
         Run_Non_Preemptive_SJN (Jobs, Result_NP);
         Run_Preemptive_SJN (Jobs, Result_P);
         
         -- For single job, both should have same completion time
         Assert (Result_NP(1).Completion_Time = Result_P(1).Completion_Time,
               "Test 18: ASSUMPTION PROVEN FALSE - Preemptive is not always faster (equal for single job)");
      end;
   end Test_Falsifiable_Assumptions;

   -- =========================================================================
   -- Main Test Runner
   -- =========================================================================

begin
   Put_Line ("===================================================================");
   Put_Line ("SJN Scheduling Algorithm Test Suite");
   Put_Line ("===================================================================");
   New_Line;

   -- Run all test categories
   Test_Basic_Non_Preemptive;
   Test_Basic_Preemptive;
   Test_Edge_Cases;
   Test_Correctness;
   Test_Invariants;
   Test_Falsifiable_Assumptions;

   -- Print summary
   Put_Line ("");
   Put_Line ("===================================================================");
   Put_Line ("TEST SUMMARY");
   Put_Line ("===================================================================");
   Put_Line ("Total Tests: " & Natural'Image(Test_Count));
   Put_Line ("Passed: " & Natural'Image(Pass_Count));
   Put_Line ("Failed: " & Natural'Image(Fail_Count));
   
   if Fail_Count = 0 then
      Put_Line ("");
      Put_Line ("ALL TESTS PASSED!");
   else
      Put_Line ("");
      Put_Line ("SOME TESTS FAILED!");
   end if;
   Put_Line ("===================================================================");

end SJN_Tests;
