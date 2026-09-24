with Ada.Text_IO; use Ada.Text_IO;
with Ada.Containers; use Ada.Containers;
with List_Scheduling; use List_Scheduling;

procedure Test_List_Scheduling is

   -- Test counter and result tracking
   Total_Tests : Natural := 0;
   Passed_Tests : Natural := 0;
   Failed_Tests : Natural := 0;

   -- Helper procedure to print test results with details
   procedure Print_Test_Result (Test_Name : String; Passed : Boolean; Details : String := "") is
   begin
      Total_Tests := Total_Tests + 1;
      if Passed then
         Passed_Tests := Passed_Tests + 1;
         Put_Line("[PASS] " & Test_Name);
         if Details'Length > 0 then
            Put_Line("        " & Details);
         end if;
      else
         Failed_Tests := Failed_Tests + 1;
         Put_Line("[FAIL] " & Test_Name);
         if Details'Length > 0 then
            Put_Line("        Expected: " & Details);
         end if;
      end if;
   end Print_Test_Result;

   -- Helper function to compute makespan from a schedule
   function Compute_Makespan (Schedule : Schedule_List) return Time_Type is
      Max_End : Time_Type := 0;
   begin
      for Item of Schedule loop
         if Item.End_Time > Max_End then
            Max_End := Item.End_Time;
         end if;
      end loop;
      return Max_End;
   end Compute_Makespan;

   -- Helper function to check if schedule is valid (no overlapping on same machine)
   function Is_Valid_Schedule (Schedule : Schedule_List) return Boolean is
      type Machine_Jobs is array (Machine_ID range 1 .. 100) of Schedule_List;
      Machine_Schedules : Machine_Jobs := (others => Schedule_Vectors.Empty_Vector);
   begin
      -- Group by machine
      for Item of Schedule loop
         if Item.Machine <= 100 then
            Machine_Schedules(Item.Machine).Append(Item);
         end if;
      end loop;
      
      -- Check each machine for overlaps
      for Mach in Machine_ID range 1 .. 100 loop
         declare
            Mach_Schedule : constant Schedule_List := Machine_Schedules(Mach);
            Mach_Len : constant Count_Type := Mach_Schedule.Length;
         begin
            for I in 1 .. Integer(Mach_Len) - 1 loop
               for J in I + 1 .. Integer(Mach_Len) loop
                  declare
                     Job_I : constant Job_Schedule := Mach_Schedule.Element(I);
                     Job_J : constant Job_Schedule := Mach_Schedule.Element(J);
                  begin
                     -- Check if jobs overlap
                     if Job_I.Start_Time < Job_J.End_Time and Job_J.Start_Time < Job_I.End_Time then
                        return False;
                     end if;
                  end;
               end loop;
            end loop;
         end;
      end loop;
      
      return True;
   end Is_Valid_Schedule;

   -- Helper to create a Job_Vectors.Vector from a list of Job_IDs
   function Create_Job_Vector (Jobs : Job_List) return Job_Vectors.Vector is
      Result : Job_Vectors.Vector;
   begin
      for J of Jobs loop
         Result.Append(J);
      end loop;
      return Result;
   end Create_Job_Vector;

begin
   New_Line;
   Put_Line("========================================================================");
   Put_Line("  List Scheduling Algorithm Test Suite");
   Put_Line("  Testing assumptions about code behavior");
   Put_Line("========================================================================");
   New_Line;

   -- ========================================================================
   -- CATEGORY 1: Assumptions that code does NOTHING (Edge Cases)
   -- These tests verify the code handles edge cases correctly
   -- ========================================================================
   Put_Line("--- Category 1: Code Does Nothing (Edge Cases) ---");
   Put_Line("Testing: Code handles minimal/empty inputs gracefully");
   New_Line;

   -- Test 1: ASSUMPTION - With empty input, code does nothing
   -- PROVING: Code correctly handles empty job lists without crashing
   declare
      Empty_Jobs : Job_List(1 .. 0);
      Empty_Durations : Job_Duration_Array(1 .. 0);
      Result : Schedule_List;
   begin
      Result := Basic_List_Scheduling(Empty_Jobs, Empty_Durations, 1);
      Print_Test_Result("Test 1: Empty job list handled gracefully", 
                        Result.Length = 0,
                        "Schedule is empty");
   end;

   -- Test 2: ASSUMPTION - With single job, code does minimal work
   -- PROVING: Code correctly schedules a single job without errors
   declare
      Single_Job : constant Job_List(1 .. 1) := (1 => 1);
      Single_Duration : constant Job_Duration_Array(1 .. 1) := (1 => 10);
      Result : Schedule_List;
   begin
      Result := Basic_List_Scheduling(Single_Job, Single_Duration, 1);
      Print_Test_Result("Test 2: Single job scheduled correctly",
                        Result.Length = 1 and then 
                        Result.First_Element.Job = 1 and then
                        Result.First_Element.Start_Time = 0 and then
                        Result.First_Element.End_Time = 10,
                        "Job 1 on machine 1, time 0-10");
   end;

   -- ========================================================================
   -- CATEGORY 2: Assumptions that code does it WRONG (Correctness Tests)
   -- These tests verify the code produces correct/optimal results
   -- ========================================================================
   New_Line;
   Put_Line("--- Category 2: Code Does It Right (Correctness) ---");
   Put_Line("Testing: Code produces correct, valid schedules");
   New_Line;

   -- Test 3: ASSUMPTION - Basic scheduling might produce invalid schedules
   -- PROVING FALSE: Basic scheduling produces valid schedules (no overlaps)
   declare
      Jobs_3 : constant Job_List(1 .. 3) := (1, 2, 3);
      Durations_3 : constant Job_Duration_Array(1 .. 3) := (10, 5, 8);
      Result : Schedule_List;
      Makespan_3 : Time_Type;
   begin
      Result := Basic_List_Scheduling(Jobs_3, Durations_3, 1);
      Makespan_3 := Compute_Makespan(Result);
      Print_Test_Result("Test 3: Basic scheduling produces valid sequential schedule",
                        Result.Length = 3 and then
                        Makespan_3 = 23 and then
                        Is_Valid_Schedule(Result),
                        "3 jobs, makespan=23, no overlaps");
   end;

   -- Test 4: ASSUMPTION - Parallel execution might overlap jobs on same machine
   -- PROVING FALSE: Code correctly assigns jobs to different machines
   declare
      Jobs_4 : constant Job_List(1 .. 4) := (1, 2, 3, 4);
      Durations_4 : constant Job_Duration_Array(1 .. 4) := (5, 10, 3, 7);
      Result : Schedule_List;
      Makespan_4 : Time_Type;
   begin
      Result := Basic_List_Scheduling(Jobs_4, Durations_4, 2);
      Makespan_4 := Compute_Makespan(Result);
      Print_Test_Result("Test 4: Parallel execution on 2 machines - no overlaps",
                        Result.Length = 4 and then
                        Makespan_4 <= 17 and then
                        Is_Valid_Schedule(Result),
                        "4 jobs on 2 machines, makespan<=17");
   end;

   -- Test 5: ASSUMPTION - LPT might not sort correctly
   -- PROVING FALSE: LPT correctly sorts by descending duration
   declare
      Durations_5 : constant Job_Duration_Array(1 .. 3) := (1, 5, 3);
      Result : Schedule_List;
   begin
      Result := LPT_Scheduling(Durations_5, 1);
      Print_Test_Result("Test 5: LPT sorts by descending duration (5, 3, 1)",
                        Result.Length = 3 and then
                        Result.Element(1).Job = 2 and then
                        Result.Element(2).Job = 3 and then
                        Result.Element(3).Job = 1,
                        "Order: Job2(5), Job3(3), Job1(1)");
   end;

   -- Test 6: ASSUMPTION - LPT might not outperform basic scheduling
   -- PROVING FALSE: LPT produces better or equal makespan than basic
   declare
      Jobs_6 : constant Job_Duration_Array(1 .. 4) := (10, 1, 1, 1);
      Result_LPT : Schedule_List;
      Result_Basic : Schedule_List;
      Jobs_List : constant Job_List(1 .. 4) := (1, 2, 3, 4);
      Makespan_LPT : Time_Type;
      Makespan_Basic : Time_Type;
   begin
      Result_LPT := LPT_Scheduling(Jobs_6, 2);
      Result_Basic := Basic_List_Scheduling(Jobs_List, Jobs_6, 2);
      Makespan_LPT := Compute_Makespan(Result_LPT);
      Makespan_Basic := Compute_Makespan(Result_Basic);
      Print_Test_Result("Test 6: LPT makespan <= Basic makespan",
                        Makespan_LPT <= Makespan_Basic,
                        "LPT: " & Time_Type'Image(Makespan_LPT) & 
                        ", Basic: " & Time_Type'Image(Makespan_Basic));
   end;

   -- ========================================================================
   -- CATEGORY 3: Assumptions about Dependencies (DAG Tests)
   -- ========================================================================
   New_Line;
   Put_Line("--- Category 3: Dependency Handling (DAG) ---");
   Put_Line("Testing: Code respects precedence constraints");
   New_Line;

   -- Test 7: ASSUMPTION - HLF might ignore dependencies
   -- PROVING FALSE: HLF respects precedence constraints
   declare
      DAG_7 : DAG_Array(1 .. 2);
      Result : Schedule_List;
      Job1_End : Time_Type := 0;
      Job2_Start : Time_Type := 0;
   begin
      -- Job 1 -> Job 2 (Job 2 depends on Job 1)
      DAG_7(1) := (Duration => 10, Predecessors => Job_Vectors.Empty_Vector, 
                    Successors => Create_Job_Vector((1 => 2)));
      DAG_7(2) := (Duration => 5, Predecessors => Create_Job_Vector((1 => 1)), 
                    Successors => Job_Vectors.Empty_Vector);
      
      Result := HLF_Scheduling(DAG_7, 2);
      
      -- Find job 1 and job 2 in the schedule
      for Item of Result loop
         if Item.Job = 1 then
            Job1_End := Item.End_Time;
         elsif Item.Job = 2 then
            Job2_Start := Item.Start_Time;
         end if;
      end loop;
      
      Print_Test_Result("Test 7: HLF respects dependencies (Job2 starts after Job1)",
                        Job2_Start >= Job1_End,
                        "Job1 ends at " & Time_Type'Image(Job1_End) & 
                        ", Job2 starts at " & Time_Type'Image(Job2_Start));
   end;

   -- Test 8: ASSUMPTION - HLF might not handle complex DAGs
   -- PROVING FALSE: HLF correctly handles parallel branches
   declare
      DAG_8 : DAG_Array(1 .. 4);
      Result : Schedule_List;
   begin
      -- Job 1 -> Job 2, Job 1 -> Job 3, Job 2 -> Job 4, Job 3 -> Job 4
      DAG_8(1) := (Duration => 5, Predecessors => Job_Vectors.Empty_Vector, 
                   Successors => Create_Job_Vector((1 => 2, 2 => 3)));
      DAG_8(2) := (Duration => 3, Predecessors => Create_Job_Vector((1 => 1)), 
                   Successors => Create_Job_Vector((1 => 4)));
      DAG_8(3) := (Duration => 4, Predecessors => Create_Job_Vector((1 => 1)), 
                   Successors => Create_Job_Vector((1 => 4)));
      DAG_8(4) := (Duration => 2, Predecessors => Create_Job_Vector((1 => 2, 2 => 3)), 
                   Successors => Job_Vectors.Empty_Vector);
      
      Result := HLF_Scheduling(DAG_8, 2);
      Print_Test_Result("Test 8: HLF handles parallel branches correctly",
                        Result.Length = 4 and then
                        Compute_Makespan(Result) <= 12 and then
                        Is_Valid_Schedule(Result),
                        "4 jobs with dependencies, makespan<=12");
   end;

   -- ========================================================================
   -- CATEGORY 4: Heterogeneous Machine Tests (HEFT)
   -- ========================================================================
   New_Line;
   Put_Line("--- Category 4: Heterogeneous Machines (HEFT) ---");
   Put_Line("Testing: Code optimizes for machine-specific speeds");
   New_Line;

   -- Test 9: ASSUMPTION - HEFT might not choose fastest machine
   -- PROVING FALSE: HEFT assigns jobs to machine with earliest finish time
   declare
      DAG_9 : DAG_Array(1 .. 1);
      Durations_9 : Duration_Matrix(1 .. 1, 1 .. 2);
      Result : Schedule_List;
   begin
      DAG_9(1) := (Duration => 5, Predecessors => Job_Vectors.Empty_Vector, 
                     Successors => Job_Vectors.Empty_Vector);
      -- Job 1: Machine 1 = 10 (slow), Machine 2 = 5 (fast)
      Durations_9(1, 1) := 10;
      Durations_9(1, 2) := 5;
      
      Result := HEFT_Scheduling(DAG_9, Durations_9, 2);
      Print_Test_Result("Test 9: HEFT chooses fastest machine (Machine 2)",
                        Result.Length = 1 and then
                        Result.First_Element.Machine = 2 and then
                        Result.First_Element.End_Time = 5,
                        "Job on Machine 2 (fast), finishes at 5");
   end;

   -- Test 10: ASSUMPTION - HEFT might not handle dependencies with heterogeneous speeds
   -- PROVING FALSE: HEFT correctly schedules dependent jobs on heterogeneous machines
   declare
      DAG_10 : DAG_Array(1 .. 3);
      Durations_10 : Duration_Matrix(1 .. 3, 1 .. 2);
      Result : Schedule_List;
   begin
      -- Job 1 -> Job 2 -> Job 3
      DAG_10(1) := (Duration => 5, Predecessors => Job_Vectors.Empty_Vector, 
                    Successors => Create_Job_Vector((1 => 2)));
      DAG_10(2) := (Duration => 3, Predecessors => Create_Job_Vector((1 => 1)), 
                    Successors => Create_Job_Vector((1 => 3)));
      DAG_10(3) := (Duration => 2, Predecessors => Create_Job_Vector((1 => 2)), 
                    Successors => Job_Vectors.Empty_Vector);
      
      -- Heterogeneous durations: each job runs faster on machine 2
      Durations_10(1, 1) := 10; Durations_10(1, 2) := 5;
      Durations_10(2, 1) := 6;  Durations_10(2, 2) := 3;
      Durations_10(3, 1) := 4;  Durations_10(3, 2) := 2;
      
      Result := HEFT_Scheduling(DAG_10, Durations_10, 2);
      Print_Test_Result("Test 10: HEFT handles dependencies + heterogeneous speeds",
                        Result.Length = 3 and then
                        Is_Valid_Schedule(Result),
                        "3 dependent jobs on heterogeneous machines");
   end;

   -- ========================================================================
   -- CATEGORY 5: Proving Assumptions FALSE (Negative Tests)
   -- These tests are EXPECTED to fail because they test false assumptions
   -- ========================================================================
   New_Line;
   Put_Line("--- Category 5: Proving Assumptions FALSE ---");
   Put_Line("Testing: These SHOULD fail to prove the assumptions are wrong");
   New_Line;

   -- Test 11: FALSE ASSUMPTION - Basic scheduling is always optimal
   -- We PROVE this FALSE by showing LPT can produce better makespan
   -- Use a case where Basic gives worse result: jobs ordered (1, 1, 1, 10) on 2 machines
   declare
      Jobs_11 : constant Job_List(1 .. 4) := (1, 2, 3, 4);
      Durations_11 : constant Job_Duration_Array(1 .. 4) := (1, 1, 1, 10);
      Result_Basic : Schedule_List;
      Result_LPT : Schedule_List;
      Makespan_Basic : Time_Type;
      Makespan_LPT : Time_Type;
   begin
      Result_Basic := Basic_List_Scheduling(Jobs_11, Durations_11, 2);
      Result_LPT := LPT_Scheduling(Durations_11, 2);
      Makespan_Basic := Compute_Makespan(Result_Basic);
      Makespan_LPT := Compute_Makespan(Result_LPT);
      
      -- This SHOULD FAIL because Basic scheduling is NOT always optimal
      -- Basic will schedule job 10 last, giving makespan=10
      -- LPT will schedule job 10 first, giving makespan=5
      Print_Test_Result("Test 11: [EXPECT FAIL] Basic is always optimal",
                        Makespan_Basic <= Makespan_LPT,
                        "Basic: " & Time_Type'Image(Makespan_Basic) & 
                        ", LPT: " & Time_Type'Image(Makespan_LPT) & 
                        " (LPT should be better, e.g., 5 vs 10)");
   end;

   -- Test 12: FALSE ASSUMPTION - LPT with 1 machine differs from Basic
   -- We PROVE this FALSE by showing they produce the same result
   declare
      Jobs_12 : constant Job_List(1 .. 3) := (1, 2, 3);
      Durations_12 : constant Job_Duration_Array(1 .. 3) := (5, 3, 7);
      Result_Basic : Schedule_List;
      Result_LPT : Schedule_List;
      Makespan_Basic : Time_Type;
      Makespan_LPT : Time_Type;
   begin
      Result_Basic := Basic_List_Scheduling(Jobs_12, Durations_12, 1);
      Result_LPT := LPT_Scheduling(Durations_12, 1);
      Makespan_Basic := Compute_Makespan(Result_Basic);
      Makespan_LPT := Compute_Makespan(Result_LPT);
      
      -- This SHOULD FAIL because with 1 machine, both algorithms produce same result
      Print_Test_Result("Test 12: [EXPECT FAIL] LPT differs from Basic on 1 machine",
                        Makespan_Basic /= Makespan_LPT,
                        "Basic: " & Time_Type'Image(Makespan_Basic) & 
                        ", LPT: " & Time_Type'Image(Makespan_LPT) & 
                        " (They should be equal)");
   end;

   -- Test 13: FALSE ASSUMPTION - Makespan can be less than longest job
   -- We PROVE this FALSE by showing makespan >= longest job duration
   declare
      Durations_13 : constant Job_Duration_Array(1 .. 4) := (2, 4, 6, 8);
      Result : Schedule_List;
      Makespan_13 : Time_Type;
   begin
      Result := LPT_Scheduling(Durations_13, 3);
      Makespan_13 := Compute_Makespan(Result);
      
      -- This SHOULD FAIL because makespan CANNOT be less than longest job
      Print_Test_Result("Test 13: [EXPECT FAIL] Makespan < longest job (8)",
                        Makespan_13 < 8,
                        "Makespan: " & Time_Type'Image(Makespan_13) & " (must be >= 8)");
   end;

   -- ========================================================================
   -- CATEGORY 6: Additional Correctness Tests
   -- ========================================================================
   New_Line;
   Put_Line("--- Category 6: Additional Correctness Tests ---");
   Put_Line("Testing: General correctness and validity");
   New_Line;

   -- Test 14: All algorithms produce valid schedules
   declare
      Jobs_14 : constant Job_List(1 .. 5) := (1, 2, 3, 4, 5);
      Durations_14 : constant Job_Duration_Array(1 .. 5) := (2, 4, 6, 8, 10);
      Result_Basic : Schedule_List;
      Result_LPT : Schedule_List;
   begin
      Result_Basic := Basic_List_Scheduling(Jobs_14, Durations_14, 3);
      Result_LPT := LPT_Scheduling(Durations_14, 3);
      
      Print_Test_Result("Test 14: All algorithms produce valid schedules",
                        Is_Valid_Schedule(Result_Basic) and then
                        Is_Valid_Schedule(Result_LPT),
                        "Both Basic and LPT produce valid schedules");
   end;

   -- Test 15: LPT with uniform durations
   declare
      Jobs_15 : constant Job_Duration_Array(1 .. 3) := (5, 5, 5);
      Result : Schedule_List;
      Makespan_15 : Time_Type;
   begin
      Result := LPT_Scheduling(Jobs_15, 2);
      Makespan_15 := Compute_Makespan(Result);
      Print_Test_Result("Test 15: LPT with uniform durations",
                        Result.Length = 3 and then
                        Makespan_15 = 10 and then
                        Is_Valid_Schedule(Result),
                        "3 jobs of duration 5 on 2 machines, makespan=10");
   end;

   -- Test 16: HLF with no dependencies behaves correctly
   declare
      DAG_16 : DAG_Array(1 .. 3);
      Result : Schedule_List;
      Makespan_16 : Time_Type;
   begin
      -- No dependencies - should behave like independent job scheduling
      DAG_16(1) := (Duration => 10, Predecessors => Job_Vectors.Empty_Vector, Successors => Job_Vectors.Empty_Vector);
      DAG_16(2) := (Duration => 5, Predecessors => Job_Vectors.Empty_Vector, Successors => Job_Vectors.Empty_Vector);
      DAG_16(3) := (Duration => 3, Predecessors => Job_Vectors.Empty_Vector, Successors => Job_Vectors.Empty_Vector);
      
      Result := HLF_Scheduling(DAG_16, 2);
      Makespan_16 := Compute_Makespan(Result);
      Print_Test_Result("Test 16: HLF with no dependencies",
                        Result.Length = 3 and then
                        Makespan_16 <= 13 and then
                        Is_Valid_Schedule(Result),
                        "3 independent jobs on 2 machines");
   end;

   -- ========================================================================
   -- SUMMARY
   -- ========================================================================
   New_Line;
   Put_Line("========================================================================");
   Put_Line("  TEST SUMMARY");
   Put_Line("========================================================================");
   Put("Total Tests: "); Put_Line(Natural'Image(Total_Tests));
   Put("Passed: "); Put_Line(Natural'Image(Passed_Tests));
   Put("Failed: "); Put_Line(Natural'Image(Failed_Tests));
   New_Line;
   Put_Line("Expected failures (proving false assumptions):");
   Put_Line("  - Test 11: Basic scheduling is NOT always optimal (LPT better)");
   Put_Line("  - Test 12: LPT and Basic are EQUAL on 1 machine");
   Put_Line("  - Test 13: Makespan CANNOT be less than longest job");
   New_Line;
   if Failed_Tests = 3 then
      Put_Line("✓ All expected failures occurred - code is working correctly!");
   elsif Failed_Tests > 3 then
      Put_Line("⚠ More failures than expected - check for bugs!");
   elsif Failed_Tests < 3 then
      Put_Line("⚠ Fewer failures than expected - some false assumptions may be true!");
   else
      Put_Line("✓ All tests passed!");
   end if;
   Put_Line("========================================================================");

end Test_List_Scheduling;
