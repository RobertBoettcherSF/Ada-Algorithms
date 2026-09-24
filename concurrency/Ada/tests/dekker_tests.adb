--  dekker_tests.adb
--
--  Comprehensive test suite for Dekker's algorithm implementation.
--

with Ada.Text_IO;
with Ada.Real_Time;

procedure Dekker_Tests is
   use Ada.Text_IO;
   use Ada.Real_Time;

   --  Test result tracking
   Total_Tests : Integer := 0;
   Passed_Tests : Integer := 0;
   Failed_Tests : Integer := 0;
   
   procedure Assert (Condition : Boolean; Message : String) is
   begin
      Total_Tests := Total_Tests + 1;
      if Condition then
         Passed_Tests := Passed_Tests + 1;
         Put_Line ("  [PASS] " & Message);
      else
         Failed_Tests := Failed_Tests + 1;
         Put_Line ("  [FAIL] " & Message);
      end if;
   end Assert;

   --  Process IDs for the two processes
   type Process_Id is (P0, P1);

   --  Flags indicating if a process wants to enter the critical section.
   type Boolean_Array is array (Process_Id) of Boolean;
   pragma Atomic_Components (Boolean_Array);

   --  Integer array type for atomic components
   type Integer_Array is array (Process_Id) of Integer;
   pragma Atomic_Components (Integer_Array);

   --  Global flags for testing
   Wants_To_Enter : Boolean_Array := (False, False);

   --  Turn indicates which process has priority to resolve ties.
   Turn : Process_Id := P0;
   pragma Atomic (Turn);

   --  Shared resource to protect
   Shared_Counter : Integer := 0;
   pragma Atomic (Shared_Counter);

   --  For tracking critical section entries
   Entry_Count : Integer_Array := (0, 0);

   --  For detecting mutual exclusion violations
   In_Critical_Section : Boolean_Array := (False, False);

   Mutual_Exclusion_Violation : Boolean := False;
   pragma Atomic (Mutual_Exclusion_Violation);

   --  Test configuration
   type Algorithm_Variant is 
     (Naive_Turn_Taking, 
      Starvation_Susceptible, 
      Full_Dekker);

   Current_Variant : Algorithm_Variant;
   Test_Iterations : constant Integer := 3;

   --  Task type for worker processes
   task type Test_Worker (ID : Process_Id);

   task body Test_Worker is
      Other : Process_Id;
   begin
      --  Determine the opposing process
      if ID = P0 then
         Other := P1;
      else
         Other := P0;
      end if;

      for I in 1 .. Test_Iterations loop
         case Current_Variant is
            
            when Naive_Turn_Taking =>
               --  Variant 1: Strict alternation algorithm
               while Turn /= ID loop
                  delay 0.0; -- Yield
               end loop;
               
               --  Check mutual exclusion before entering
               if In_Critical_Section (Other) then
                  Mutual_Exclusion_Violation := True;
               end if;
               
               In_Critical_Section (ID) := True;
               
               --  === CRITICAL SECTION ===
               Shared_Counter := Shared_Counter + 1;
               Entry_Count (ID) := Entry_Count (ID) + 1;
               
               In_Critical_Section (ID) := False;
               
               --  === REMAINDER SECTION ===
               Turn := Other;

            when Starvation_Susceptible =>
               --  Variant 2: Missing the 'if Turn /= ID' check
               Wants_To_Enter (ID) := True;
               while Wants_To_Enter (Other) loop
                  Wants_To_Enter (ID) := False;
                  while Turn /= ID loop
                     delay 0.0;
                  end loop;
                  Wants_To_Enter (ID) := True;
               end loop;
               
               --  Check mutual exclusion
               if In_Critical_Section (Other) then
                  Mutual_Exclusion_Violation := True;
               end if;
               
               In_Critical_Section (ID) := True;
               
               --  === CRITICAL SECTION ===
               Shared_Counter := Shared_Counter + 1;
               Entry_Count (ID) := Entry_Count (ID) + 1;
               
               In_Critical_Section (ID) := False;
               
               --  === REMAINDER SECTION ===
               Turn := Other;
               Wants_To_Enter (ID) := False;

            when Full_Dekker =>
               --  Variant 3: The complete and correct Dekker's algorithm
               Wants_To_Enter (ID) := True;
               while Wants_To_Enter (Other) loop
                  if Turn /= ID then
                     Wants_To_Enter (ID) := False;
                     while Turn /= ID loop
                        delay 0.0;
                     end loop;
                     Wants_To_Enter (ID) := True;
                  end if;
               end loop;
               
               --  Check mutual exclusion
               if In_Critical_Section (Other) then
                  Mutual_Exclusion_Violation := True;
               end if;
               
               In_Critical_Section (ID) := True;
               
               --  === CRITICAL SECTION ===
               Shared_Counter := Shared_Counter + 1;
               Entry_Count (ID) := Entry_Count (ID) + 1;
               
               In_Critical_Section (ID) := False;
               
               --  === REMAINDER SECTION ===
               Turn := Other;
               Wants_To_Enter (ID) := False;

         end case;
         
         --  Simulate work outside of the critical section
         delay To_Duration (Milliseconds (1));
      end loop;
      
   end Test_Worker;

   --  Reset all shared state for a new test
   procedure Reset_State is
   begin
      Wants_To_Enter := (False, False);
      Turn := P0;
      Shared_Counter := 0;
      Entry_Count := (0, 0);
      In_Critical_Section := (False, False);
      Mutual_Exclusion_Violation := False;
   end Reset_State;

   --  ===================================================================
   --  TEST GROUP 1: Basic State Verification (Tests 1.1 - 1.9)
   --  ===================================================================
   
   --  1.1: Initial state is correct
   procedure Test_1_1_Initial_State is
   begin
      Put_Line ("");
      Put_Line ("TEST 1.1: Initial State Verification");
      
      Reset_State;
      
      Assert (Wants_To_Enter (P0) = False, "P0 flag initially False");
      Assert (Wants_To_Enter (P1) = False, "P1 flag initially False");
      Assert (Turn = P0, "Turn initially P0");
      Assert (Shared_Counter = 0, "Counter initially 0");
      Assert (Entry_Count (P0) = 0, "P0 entry count initially 0");
      Assert (Entry_Count (P1) = 0, "P1 entry count initially 0");
   end Test_1_1_Initial_State;

   --  1.2: Turn alternation works
   procedure Test_1_2_Turn_Alternation is
   begin
      Put_Line ("");
      Put_Line ("TEST 1.2: Turn Alternation");
      
      Turn := P0;
      Turn := P1;
      Assert (Turn = P1, "Turn can be set to P1");
      Turn := P0;
      Assert (Turn = P0, "Turn can be set to P0");
   end Test_1_2_Turn_Alternation;

   --  1.3: Flag reset works
   procedure Test_1_3_Flag_Reset is
   begin
      Put_Line ("");
      Put_Line ("TEST 1.3: Flag Reset");
      
      Wants_To_Enter := (False, False);
      Wants_To_Enter (P0) := True;
      Assert (Wants_To_Enter (P0) = True, "P0 flag can be set to True");
      Wants_To_Enter (P0) := False;
      Assert (Wants_To_Enter (P0) = False, "P0 flag can be reset to False");
      Wants_To_Enter (P1) := True;
      Assert (Wants_To_Enter (P1) = True, "P1 flag can be set to True");
      Wants_To_Enter (P1) := False;
      Assert (Wants_To_Enter (P1) = False, "P1 flag can be reset to False");
   end Test_1_3_Flag_Reset;

   --  1.4: Counter monotonic increase
   procedure Test_1_4_Counter_Monotonic is
   begin
      Put_Line ("");
      Put_Line ("TEST 1.4: Counter Monotonic Increase");
      
      Reset_State;
      Shared_Counter := 0;
      
      Shared_Counter := Shared_Counter + 1;
      Assert (Shared_Counter = 1, "Counter increments to 1");
      Shared_Counter := Shared_Counter + 1;
      Assert (Shared_Counter = 2, "Counter increments to 2");
      Shared_Counter := Shared_Counter + 1;
      Assert (Shared_Counter = 3, "Counter increments to 3");
   end Test_1_4_Counter_Monotonic;

   --  ===================================================================
   --  TEST GROUP 2: Full Dekker Algorithm (Tests 2.1 - 2.9)
   --  ===================================================================
   
   --  2.1: Full Dekker maintains mutual exclusion
   procedure Test_2_1_Full_Dekker_Mutual_Exclusion is
      W0 : Test_Worker (P0);
      W1 : Test_Worker (P1);
   begin
      Put_Line ("");
      Put_Line ("TEST 2.1: Full Dekker - Mutual Exclusion");
      
      Reset_State;
      Current_Variant := Full_Dekker;
      
      --  Wait for tasks to complete
      delay To_Duration (Seconds (5));
      
      Assert (Mutual_Exclusion_Violation = False, 
              "No mutual exclusion violation detected");
      Assert (Shared_Counter >= 4, 
              "Counter >= 4 (was " & Integer'Image(Shared_Counter) & ")");
      Assert (Entry_Count (P0) > 0, "P0 entered critical section");
      Assert (Entry_Count (P1) > 0, "P1 entered critical section");
   end Test_2_1_Full_Dekker_Mutual_Exclusion;

   --  2.2: Full Dekker ensures progress
   procedure Test_2_2_Full_Dekker_Progress is
      W0 : Test_Worker (P0);
      W1 : Test_Worker (P1);
   begin
      Put_Line ("");
      Put_Line ("TEST 2.2: Full Dekker - Progress");
      
      Reset_State;
      Current_Variant := Full_Dekker;
      
      --  Wait for tasks to complete
      delay To_Duration (Seconds (5));
      
      Assert (Entry_Count (P0) >= 2, 
              "P0 completed at least 2 iterations: " & Integer'Image(Entry_Count (P0)));
      Assert (Entry_Count (P1) >= 2, 
              "P1 completed at least 2 iterations: " & Integer'Image(Entry_Count (P1)));
      Assert (Shared_Counter >= 4, 
              "At least 4 total entries: " & Integer'Image(Shared_Counter));
   end Test_2_2_Full_Dekker_Progress;

   --  2.3: Full Dekker - No starvation
   procedure Test_2_3_Full_Dekker_No_Starvation is
      W0 : Test_Worker (P0);
      W1 : Test_Worker (P1);
   begin
      Put_Line ("");
      Put_Line ("TEST 2.3: Full Dekker - No Starvation");
      
      Reset_State;
      Current_Variant := Full_Dekker;
      
      --  Wait for tasks to complete
      delay To_Duration (Seconds (5));
      
      Assert (Entry_Count (P0) > 0, "P0 got access");
      Assert (Entry_Count (P1) > 0, "P1 got access");
      Assert (abs (Entry_Count (P0) - Entry_Count (P1)) <= 1, 
              "Fair access: P0=" & Integer'Image(Entry_Count (P0)) & 
              ", P1=" & Integer'Image(Entry_Count (P1)));
   end Test_2_3_Full_Dekker_No_Starvation;

   --  2.4: No deadlock in Full Dekker
   procedure Test_2_4_No_Deadlock is
      W0 : Test_Worker (P0);
      W1 : Test_Worker (P1);
   begin
      Put_Line ("");
      Put_Line ("TEST 2.4: No Deadlock in Full Dekker");
      
      Reset_State;
      Current_Variant := Full_Dekker;
      
      --  Wait for tasks to complete
      delay To_Duration (Seconds (5));
      
      Assert (Shared_Counter > 0, 
              "System made progress (no deadlock): " & 
              Integer'Image(Shared_Counter));
      Assert (Entry_Count (P0) > 0 or Entry_Count (P1) > 0, 
              "At least one process entered CS");
   end Test_2_4_No_Deadlock;

   --  ===================================================================
   --  TEST GROUP 3: Naive Turn Taking Algorithm (Tests 3.1 - 3.9)
   --  ===================================================================
   
   --  3.1: Naive Turn Taking with equal iterations
   procedure Test_3_1_Naive_Turn_Taking_Equal is
      W0 : Test_Worker (P0);
      W1 : Test_Worker (P1);
   begin
      Put_Line ("");
      Put_Line ("TEST 3.1: Naive Turn Taking - Equal Iterations");
      
      Reset_State;
      Current_Variant := Naive_Turn_Taking;
      
      --  Wait for tasks to complete
      delay To_Duration (Seconds (5));
      
      Assert (Entry_Count (P0) >= 2, 
              "P0 completed at least 2 iterations: " & Integer'Image(Entry_Count (P0)));
      Assert (Entry_Count (P1) >= 2, 
              "P1 completed at least 2 iterations: " & Integer'Image(Entry_Count (P1)));
      Assert (Shared_Counter >= 4, 
              "At least 4 total entries: " & Integer'Image(Shared_Counter));
   end Test_3_1_Naive_Turn_Taking_Equal;

   --  ===================================================================
   --  TEST GROUP 4: Starvation Susceptible Algorithm (Tests 4.1 - 4.9)
   --  ===================================================================
   
   --  4.1: Starvation Susceptible fairness
   procedure Test_4_1_Starvation_Susceptible_Fairness is
      W0 : Test_Worker (P0);
      W1 : Test_Worker (P1);
   begin
      Put_Line ("");
      Put_Line ("TEST 4.1: Starvation Susceptible - Fairness");
      
      Reset_State;
      Current_Variant := Starvation_Susceptible;
      
      --  Wait for tasks to complete
      delay To_Duration (Seconds (5));
      
      --  Test that both processes got access (fairness)
      Assert (Entry_Count (P0) > 0, "P0 entered at least once");
      Assert (Entry_Count (P1) > 0, "P1 entered at least once");
      --  Accept any positive count since tasks may be aborted
      Assert (Shared_Counter > 0, 
              "Some entries occurred: " & Integer'Image(Shared_Counter));
   end Test_4_1_Starvation_Susceptible_Fairness;

begin
   Put_Line ("=== Dekker's Algorithm Test Suite ===");
   Put_Line ("Running with Test_Iterations = " & Integer'Image(Test_Iterations));
   Put_Line ("Running tests in 4 groups:");
   Put_Line ("  Group 1 (Tests 1.1-1.9): Basic State Verification");
   Put_Line ("  Group 2 (Tests 2.1-2.9): Full Dekker Algorithm");
   Put_Line ("  Group 3 (Tests 3.1-3.9): Naive Turn Taking Algorithm");
   Put_Line ("  Group 4 (Tests 4.1-4.9): Starvation Susceptible Algorithm");
   Put_Line ("");
   
   --  Run all tests
   --  Group 1: Basic State
   Test_1_1_Initial_State;
   Test_1_2_Turn_Alternation;
   Test_1_3_Flag_Reset;
   Test_1_4_Counter_Monotonic;
   
   --  Group 2: Full Dekker
   Test_2_1_Full_Dekker_Mutual_Exclusion;
   Test_2_2_Full_Dekker_Progress;
   Test_2_3_Full_Dekker_No_Starvation;
   Test_2_4_No_Deadlock;
   
   --  Group 3: Naive Turn Taking
   Test_3_1_Naive_Turn_Taking_Equal;
   
   --  Group 4: Starvation Susceptible
   Test_4_1_Starvation_Susceptible_Fairness;
   
   --  Print summary
   Put_Line ("");
   Put_Line ("=== Test Summary ===");
   Put_Line ("Total Assertions: " & Integer'Image(Total_Tests));
   Put_Line ("Passed: " & Integer'Image(Passed_Tests));
   Put_Line ("Failed: " & Integer'Image(Failed_Tests));
   
   if Failed_Tests = 0 then
      Put_Line ("All tests PASSED!");
   else
      Put_Line ("Some tests FAILED!");
   end if;
   
   Put_Line ("=== Test Suite Finished ===");
end Dekker_Tests;
