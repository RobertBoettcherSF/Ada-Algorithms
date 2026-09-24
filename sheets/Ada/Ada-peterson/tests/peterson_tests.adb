--  ====================================================================
--  Peterson Algorithm Test Suite
--  
--  This test suite verifies the correctness of Peterson's algorithm implementations.
--  Tests cover: mutual exclusion, progress, bounded waiting, and edge cases.
--  
--  To run: gnatmake -P peterson_tests.gpr && ./bin/peterson_tests
--  ====================================================================

with Ada.Text_IO;           use Ada.Text_IO;
with Ada.Real_Time;         use Ada.Real_Time;

procedure Peterson_Tests is

   --  ====================================================================
   --  Test Result Tracking
   --  ====================================================================
   type Test_Status is (PASSED, FAILED, SKIPPED);
   
   Total_Tests : Integer := 0;
   Passed_Tests : Integer := 0;
   Failed_Tests : Integer := 0;
   
   procedure Start_Test (Name : String) is
   begin
      Total_Tests := Total_Tests + 1;
      Put ("Test " & Integer'Image(Total_Tests) & ": " & Name & " ... ");
   end Start_Test;
   
   procedure End_Test (Status : Test_Status; Message : String := "") is
   begin
      case Status is
         when PASSED =>
            Passed_Tests := Passed_Tests + 1;
            Put_Line ("[PASS]");
         when FAILED =>
            Failed_Tests := Failed_Tests + 1;
            Put_Line ("[FAIL] " & Message);
         when SKIPPED =>
            Put_Line ("[SKIP] " & Message);
      end case;
   end End_Test;
   
   procedure Print_Summary is
   begin
      New_Line;
      Put_Line ("========================================");
      Put_Line ("Test Summary:");
      Put_Line ("  Total:  " & Integer'Image(Total_Tests));
      Put_Line ("  Passed: " & Integer'Image(Passed_Tests));
      Put_Line ("  Failed: " & Integer'Image(Failed_Tests));
      Put_Line ("  Skipped:" & Integer'Image(Total_Tests - Passed_Tests - Failed_Tests));
      Put_Line ("========================================");
      
      if Failed_Tests > 0 then
         Put_Line ("SOME TESTS FAILED!");
      else
         Put_Line ("ALL TESTS PASSED!");
      end if;
   end Print_Summary;

   --  Helper function to format time span as string (Ada 95 compatible)
   function Time_Span_To_String (TS : Time_Span) return String is
      Total_Seconds : constant Duration := to_Duration(TS);
      Seconds : constant Integer := Integer(Total_Seconds);
      Millis : constant Integer := Integer((Total_Seconds - Duration(Seconds)) * 1000.0);
   begin
      return Integer'Image(Seconds) & "s " & Integer'Image(Millis) & "ms";
   end Time_Span_To_String;

   --  ====================================================================
   --  Test 1: Strict Alternation - Basic Mutual Exclusion
   --  Assumption: Only one process should be in critical section at a time
   --  Test: Verify no concurrent access in strict alternation
   --  ====================================================================
   procedure Test_Strict_Alternation_Mutual_Exclusion is
      Turn : Integer range 0 .. 1 := 0;
      pragma Atomic (Turn);
      
      Critical_Count : Integer := 0;
      pragma Atomic (Critical_Count);
      
      Max_Concurrent : Integer := 0;
      pragma Atomic (Max_Concurrent);
      
      task type Test_Worker_Strict is
         entry Start (ID : Integer);
      end Test_Worker_Strict;
      
      task body Test_Worker_Strict is
         My_ID : Integer;
         Other : Integer;
         Current_Count : Integer;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;
         Other := 1 - My_ID;
         
         for I in 1 .. 5 loop
            -- Enter critical section
            while Turn /= My_ID loop
               delay 0.0;
            end loop;
            
            -- Track concurrent access
            Current_Count := Critical_Count + 1;
            Critical_Count := Current_Count;
            
            if Current_Count > Max_Concurrent then
               Max_Concurrent := Current_Count;
            end if;
            
            -- Simulate work
            delay 0.01;
            
            Critical_Count := Current_Count - 1;
            
            -- Exit critical section
            Turn := Other;
         end loop;
      end Test_Worker_Strict;
      
      Tasks : array (0 .. 1) of Test_Worker_Strict;
   begin
      Start_Test ("Strict Alternation - Mutual Exclusion");
      
      for I in Tasks'Range loop
         Tasks (I).Start (I);
      end loop;
      
      -- Wait for tasks to complete
      delay 2.0;
      
      -- Max concurrent should never exceed 1
      if Max_Concurrent <= 1 then
         End_Test (PASSED, "Max concurrent: " & Integer'Image(Max_Concurrent));
      else
         End_Test (FAILED, "Violation: " & Integer'Image(Max_Concurrent) & " concurrent accesses");
      end if;
   end Test_Strict_Alternation_Mutual_Exclusion;

   --  ====================================================================
   --  Test 2: Strict Alternation - Progress Guarantee
   --  Assumption: Both processes should make progress
   --  Test: Verify both processes complete their iterations
   --  ====================================================================
   procedure Test_Strict_Alternation_Progress is
      Turn : Integer range 0 .. 1 := 0;
      pragma Atomic (Turn);
      
      Completion_Count : array (0 .. 1) of Integer := (0, 0);
      pragma Atomic_Components (Completion_Count);
      
      task type Test_Worker_Progress is
         entry Start (ID : Integer);
      end Test_Worker_Progress;
      
      task body Test_Worker_Progress is
         My_ID : Integer;
         Other : Integer;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;
         Other := 1 - My_ID;
         
         for I in 1 .. 3 loop
            while Turn /= My_ID loop
               delay 0.0;
            end loop;
            
            -- Simulate work
            delay 0.01;
            
            Completion_Count (My_ID) := Completion_Count (My_ID) + 1;
            Turn := Other;
         end loop;
      end Test_Worker_Progress;
      
      Tasks : array (0 .. 1) of Test_Worker_Progress;
   begin
      Start_Test ("Strict Alternation - Progress");
      
      for I in Tasks'Range loop
         Tasks (I).Start (I);
      end loop;
      
      delay 2.0;
      
      -- Both should complete all iterations
      if Completion_Count (0) = 3 and Completion_Count (1) = 3 then
         End_Test (PASSED, "Both completed 3 iterations");
      else
         End_Test (FAILED, "P0: " & Integer'Image(Completion_Count(0)) & 
                  ", P1: " & Integer'Image(Completion_Count(1)));
      end if;
   end Test_Strict_Alternation_Progress;

   --  ====================================================================
   --  Test 3: 2-Process Peterson - Mutual Exclusion
   --  Assumption: Flag and Turn mechanism prevents concurrent access
   --  Test: Verify mutual exclusion with Peterson's algorithm
   --  ====================================================================
   procedure Test_Peterson_2_Mutual_Exclusion is
      Flag : array (0 .. 1) of Boolean := (False, False);
      pragma Atomic_Components (Flag);
      
      Turn : Integer range 0 .. 1 := 0;
      pragma Atomic (Turn);
      
      Critical_Count : Integer := 0;
      pragma Atomic (Critical_Count);
      
      Max_Concurrent : Integer := 0;
      pragma Atomic (Max_Concurrent);
      
      Violation_Occurred : Boolean := False;
      pragma Atomic (Violation_Occurred);
      
      task type Test_Peterson_Worker is
         entry Start (ID : Integer);
      end Test_Peterson_Worker;
      
      task body Test_Peterson_Worker is
         My_ID : Integer;
         Other : Integer;
         Current_Count : Integer;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;
         Other := 1 - My_ID;
         
         for I in 1 .. 5 loop
            -- Entry protocol
            Flag (My_ID) := True;
            
            -- Grant priority to the other process if they also want in
            Turn := Other;

            -- Wait until the other process doesn't want in, or it's our turn
            while Flag (Other) and then Turn = Other loop
               delay 0.0;
            end loop;
            
            -- Critical section
            Current_Count := Critical_Count + 1;
            Critical_Count := Current_Count;
            
            if Current_Count > 1 then
               Violation_Occurred := True;
            end if;
            
            if Current_Count > Max_Concurrent then
               Max_Concurrent := Current_Count;
            end if;
            
            delay 0.01;
            
            Critical_Count := Current_Count - 1;
            
            -- Exit protocol
            Flag (My_ID) := False;
         end loop;
      end Test_Peterson_Worker;
      
      Tasks : array (0 .. 1) of Test_Peterson_Worker;
   begin
      Start_Test ("2-Process Peterson - Mutual Exclusion");
      
      for I in Tasks'Range loop
         Tasks (I).Start (I);
      end loop;
      
      delay 2.0;
      
      if not Violation_Occurred and Max_Concurrent <= 1 then
         End_Test (PASSED, "No concurrent violations");
      else
         End_Test (FAILED, "Concurrent access detected");
      end if;
   end Test_Peterson_2_Mutual_Exclusion;

   --  ====================================================================
   --  Test 4: 2-Process Peterson - Bounded Waiting
   --  Assumption: No process should wait forever
   --  Test: Verify bounded waiting property
   --  ====================================================================
   procedure Test_Peterson_2_Bounded_Waiting is
      Flag : array (0 .. 1) of Boolean := (False, False);
      pragma Atomic_Components (Flag);
      
      Turn : Integer range 0 .. 1 := 0;
      pragma Atomic (Turn);
      
      Entry_Times : array (0 .. 1, 1 .. 5) of Time;
      Exit_Times : array (0 .. 1, 1 .. 5) of Time;
      
      task type Test_Bounded_Worker is
         entry Start (ID : Integer);
      end Test_Bounded_Worker;
      
      task body Test_Bounded_Worker is
         My_ID : Integer;
         Other : Integer;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;
         Other := 1 - My_ID;
         
         for I in 1 .. 5 loop
            -- Entry protocol
            Flag (My_ID) := True;
            Turn := Other;
            
            Entry_Times (My_ID, I) := Clock;
            
            while Flag (Other) and then Turn = Other loop
               delay 0.0;
            end loop;
            
            -- Critical section
            delay 0.01;
            
            Exit_Times (My_ID, I) := Clock;
            
            -- Exit protocol
            Flag (My_ID) := False;
         end loop;
      end Test_Bounded_Worker;
      
      Tasks : array (0 .. 1) of Test_Bounded_Worker;
      Max_Wait_Time : Time_Span := Milliseconds (0);
      Current_Wait : Time_Span;
   begin
      Start_Test ("2-Process Peterson - Bounded Waiting");
      
      for I in Tasks'Range loop
         Tasks (I).Start (I);
      end loop;
      
      delay 3.0;
      
      -- Check that no process waited more than 500ms for any entry
      for P in 0 .. 1 loop
         for I in 1 .. 5 loop
            if Exit_Times (P, I) > Entry_Times (P, I) then
               Current_Wait := Exit_Times (P, I) - Entry_Times (P, I);
               if Current_Wait > Max_Wait_Time then
                  Max_Wait_Time := Current_Wait;
               end if;
            end if;
         end loop;
      end loop;
      
      -- Bounded waiting should ensure reasonable wait times
      if Max_Wait_Time < Milliseconds (500) then
         End_Test (PASSED, "Max wait: " & Time_Span_To_String(Max_Wait_Time));
      else
         End_Test (FAILED, "Excessive wait: " & Time_Span_To_String(Max_Wait_Time));
      end if;
   end Test_Peterson_2_Bounded_Waiting;

   --  ====================================================================
   --  Test 5: 2-Process Peterson - Progress
   --  Assumption: Both processes should complete
   --  Test: Verify both processes make progress
   --  ====================================================================
   procedure Test_Peterson_2_Progress is
      Flag : array (0 .. 1) of Boolean := (False, False);
      pragma Atomic_Components (Flag);
      
      Turn : Integer range 0 .. 1 := 0;
      pragma Atomic (Turn);
      
      Completion_Count : array (0 .. 1) of Integer := (0, 0);
      pragma Atomic_Components (Completion_Count);
      
      task type Test_Progress_Worker is
         entry Start (ID : Integer);
      end Test_Progress_Worker;
      
      task body Test_Progress_Worker is
         My_ID : Integer;
         Other : Integer;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;
         Other := 1 - My_ID;
         
         for I in 1 .. 3 loop
            Flag (My_ID) := True;
            Turn := Other;
            
            while Flag (Other) and then Turn = Other loop
               delay 0.0;
            end loop;
            
            Completion_Count (My_ID) := Completion_Count (My_ID) + 1;
            
            Flag (My_ID) := False;
            delay 0.01;
         end loop;
      end Test_Progress_Worker;
      
      Tasks : array (0 .. 1) of Test_Progress_Worker;
   begin
      Start_Test ("2-Process Peterson - Progress");
      
      for I in Tasks'Range loop
         Tasks (I).Start (I);
      end loop;
      
      delay 2.0;
      
      if Completion_Count (0) >= 3 and Completion_Count (1) >= 3 then
         End_Test (PASSED, "Both completed");
      else
         End_Test (FAILED, "P0: " & Integer'Image(Completion_Count(0)) & 
                  ", P1: " & Integer'Image(Completion_Count(1)));
      end if;
   end Test_Peterson_2_Progress;

   --  ====================================================================
   --  Test 6: N-Process Peterson - Mutual Exclusion (4 processes)
   --  Assumption: Filter algorithm prevents concurrent access
   --  Test: Verify mutual exclusion with N processes
   --  ====================================================================
   procedure Test_Peterson_N_Mutual_Exclusion is
      N : constant := 4;
      
      Level : array (0 .. N - 1) of Integer := (others => 0);
      pragma Atomic_Components (Level);
      
      Last_To_Enter : array (1 .. N - 1) of Integer := (others => 0);
      pragma Atomic_Components (Last_To_Enter);
      
      Critical_Count : Integer := 0;
      pragma Atomic (Critical_Count);
      
      Max_Concurrent : Integer := 0;
      pragma Atomic (Max_Concurrent);
      
      Violation_Occurred : Boolean := False;
      pragma Atomic (Violation_Occurred);
      
      task type Test_N_Worker is
         entry Start (ID : Integer);
      end Test_N_Worker;
      
      task body Test_N_Worker is
         My_ID : Integer;
         Current_Count : Integer;
         Conflict : Boolean;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;
         
         for I in 1 .. 3 loop
            -- Entry protocol (Filter algorithm)
            for L in 1 .. N - 1 loop
               Level (My_ID) := L;
               Last_To_Enter (L) := My_ID;
               
               loop
                  Conflict := False;
                  for K in 0 .. N - 1 loop
                     if K /= My_ID and then Level (K) >= L then
                        Conflict := True;
                        exit;
                     end if;
                  end loop;
                  
                  exit when not (Conflict and then Last_To_Enter (L) = My_ID);
                  delay 0.0;
               end loop;
            end loop;
            
            -- Critical section
            Current_Count := Critical_Count + 1;
            Critical_Count := Current_Count;
            
            if Current_Count > 1 then
               Violation_Occurred := True;
            end if;
            
            if Current_Count > Max_Concurrent then
               Max_Concurrent := Current_Count;
            end if;
            
            delay 0.01;
            
            Critical_Count := Current_Count - 1;
            
            -- Exit protocol
            Level (My_ID) := 0;
         end loop;
      end Test_N_Worker;
      
      Tasks : array (0 .. N - 1) of Test_N_Worker;
   begin
      Start_Test ("N-Process Peterson - Mutual Exclusion");
      
      for I in Tasks'Range loop
         Tasks (I).Start (I);
      end loop;
      
      delay 3.0;
      
      if not Violation_Occurred and Max_Concurrent <= 1 then
         End_Test (PASSED, "No concurrent violations with " & Integer'Image(N) & " processes");
      else
         End_Test (FAILED, "Concurrent access detected: " & Integer'Image(Max_Concurrent));
      end if;
   end Test_Peterson_N_Mutual_Exclusion;

   --  ====================================================================
   --  Test 7: N-Process Peterson - Progress (4 processes)
   --  Assumption: All processes should make progress
   --  Test: Verify all N processes complete
   --  ====================================================================
   procedure Test_Peterson_N_Progress is
      N : constant := 4;
      
      Level : array (0 .. N - 1) of Integer := (others => 0);
      pragma Atomic_Components (Level);
      
      Last_To_Enter : array (1 .. N - 1) of Integer := (others => 0);
      pragma Atomic_Components (Last_To_Enter);
      
      Completion_Count : array (0 .. N - 1) of Integer := (others => 0);
      pragma Atomic_Components (Completion_Count);
      
      task type Test_N_Progress_Worker is
         entry Start (ID : Integer);
      end Test_N_Progress_Worker;
      
      task body Test_N_Progress_Worker is
         My_ID : Integer;
         Conflict : Boolean;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;
         
         for I in 1 .. 2 loop
            for L in 1 .. N - 1 loop
               Level (My_ID) := L;
               Last_To_Enter (L) := My_ID;
               
               loop
                  Conflict := False;
                  for K in 0 .. N - 1 loop
                     if K /= My_ID and then Level (K) >= L then
                        Conflict := True;
                        exit;
                     end if;
                  end loop;
                  
                  exit when not (Conflict and then Last_To_Enter (L) = My_ID);
                  delay 0.0;
               end loop;
            end loop;
            
            Completion_Count (My_ID) := Completion_Count (My_ID) + 1;
            
            Level (My_ID) := 0;
            delay 0.01;
         end loop;
      end Test_N_Progress_Worker;
      
      Tasks : array (0 .. N - 1) of Test_N_Progress_Worker;
      All_Completed : Boolean := True;
   begin
      Start_Test ("N-Process Peterson - Progress");
      
      for I in Tasks'Range loop
         Tasks (I).Start (I);
      end loop;
      
      delay 3.0;
      
      -- Check all processes completed at least 2 iterations
      for P in 0 .. N - 1 loop
         if Completion_Count (P) < 2 then
            All_Completed := False;
            exit;
         end if;
      end loop;
      
      if All_Completed then
         End_Test (PASSED, "All " & Integer'Image(N) & " processes completed");
      else
         End_Test (FAILED, "Some processes did not complete");
      end if;
   end Test_Peterson_N_Progress;

   --  ====================================================================
   --  Test 8: Strict Alternation - Starvation Detection
   --  Assumption: Strict alternation can cause starvation if one process stops
   --  Test: Verify that if one process stops, the other can still proceed
   --  ====================================================================
   --  ====================================================================
   --  Test 8: Strict Alternation - Starvation Detection
   --  Assumption: Strict alternation can cause starvation if one process stops
   --  Test: Verify that if one process stops, the other starves
   --  ====================================================================
   procedure Test_Strict_Alternation_Starvation is
      Turn : Integer range 0 .. 1 := 0;
      pragma Atomic (Turn);
      
      Completion_Count : array (0 .. 1) of Integer := (0, 0);
      pragma Atomic_Components (Completion_Count);
      
      Stop_Early : array (0 .. 1) of Boolean := (False, False);
      pragma Atomic_Components (Stop_Early);
      
      task type Test_Starvation_Worker is
         entry Start (ID : Integer);
      end Test_Starvation_Worker;
      
      task body Test_Starvation_Worker is
         My_ID : Integer;
         Other : Integer;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;
         Other := 1 - My_ID;
         
         -- Process 0 does only 1 iteration then stops
         if My_ID = 0 then
            while Turn /= My_ID loop
               delay 0.0;
            end loop;
            
            Completion_Count (My_ID) := Completion_Count (My_ID) + 1;
            Turn := Other;
            Stop_Early (My_ID) := True;
            -- Task ends here after 1 iteration
            
         else
            -- Process 1 tries to do 3 iterations
            -- But it can only proceed when Turn = 1
            -- After P0's first iteration, Turn = 1, so P1 can do one iteration
            -- Then P1 sets Turn = 0, but P0 is stopped, so Turn stays at 0
            -- P1 cannot proceed further (starvation)
            for I in 1 .. 3 loop
               while Turn /= My_ID loop
                  delay 0.0;
               end loop;
               
               Completion_Count (My_ID) := Completion_Count (My_ID) + 1;
               Turn := Other;
               
               -- After first iteration, P0 is stopped with Turn=0
               -- So P1 cannot continue
               if Stop_Early (Other) and Turn = Other then
                  exit;
               end if;
            end loop;
         end if;
      end Test_Starvation_Worker;
      
      Tasks : array (0 .. 1) of Test_Starvation_Worker;
   begin
      Start_Test ("Strict Alternation - Starvation Scenario");
      
      for I in Tasks'Range loop
         Tasks (I).Start (I);
      end loop;
      
      delay 2.0;
      
      -- P0 should have 1 completion, P1 should have 1 (can do one after P0 stops)
      -- Actually with strict alternation, P1 can only do 1 iteration
      if Completion_Count (0) = 1 and Completion_Count (1) = 1 then
         End_Test (PASSED, "Starvation: P0=1, P1=1 (P1 starved after 1 iteration)");
      else
         End_Test (FAILED, "Unexpected: P0=" & Integer'Image(Completion_Count(0)) & 
                  ", P1=" & Integer'Image(Completion_Count(1)));
      end if;
   end Test_Strict_Alternation_Starvation;


   --  ====================================================================
   --  Test 9: 2-Process Peterson - No Deadlock
   --  Assumption: Peterson's algorithm should never deadlock
   --  Test: Verify both processes can enter critical section repeatedly
   --  ====================================================================
   procedure Test_Peterson_2_No_Deadlock is
      Flag : array (0 .. 1) of Boolean := (False, False);
      pragma Atomic_Components (Flag);
      
      Turn : Integer range 0 .. 1 := 0;
      pragma Atomic (Turn);
      
      Entry_Count : array (0 .. 1) of Integer := (0, 0);
      pragma Atomic_Components (Entry_Count);
      
      task type Test_Deadlock_Worker is
         entry Start (ID : Integer);
      end Test_Deadlock_Worker;
      
      task body Test_Deadlock_Worker is
         My_ID : Integer;
         Other : Integer;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;
         Other := 1 - My_ID;
         
         for I in 1 .. 10 loop
            Flag (My_ID) := True;
            Turn := Other;
            
            while Flag (Other) and then Turn = Other loop
               delay 0.0;
            end loop;
            
            Entry_Count (My_ID) := Entry_Count (My_ID) + 1;
            
            Flag (My_ID) := False;
            delay 0.005;
         end loop;
      end Test_Deadlock_Worker;
      
      Tasks : array (0 .. 1) of Test_Deadlock_Worker;
   begin
      Start_Test ("2-Process Peterson - No Deadlock");
      
      for I in Tasks'Range loop
         Tasks (I).Start (I);
      end loop;
      
      delay 3.0;
      
      -- Both should have entered multiple times
      if Entry_Count (0) >= 5 and Entry_Count (1) >= 5 then
         End_Test (PASSED, "P0: " & Integer'Image(Entry_Count(0)) & 
                  ", P1: " & Integer'Image(Entry_Count(1)) & " entries");
      else
         End_Test (FAILED, "Possible deadlock: P0=" & Integer'Image(Entry_Count(0)) & 
                  ", P1=" & Integer'Image(Entry_Count(1)));
      end if;
   end Test_Peterson_2_No_Deadlock;

   --  ====================================================================
   --  Test 10: N-Process Peterson - Scalability (8 processes)
   --  Assumption: Filter algorithm works with more processes
   --  Test: Verify mutual exclusion with 8 processes
   --  ====================================================================
   procedure Test_Peterson_N_Scalability is
      N : constant := 8;
      
      Level : array (0 .. N - 1) of Integer := (others => 0);
      pragma Atomic_Components (Level);
      
      Last_To_Enter : array (1 .. N - 1) of Integer := (others => 0);
      pragma Atomic_Components (Last_To_Enter);
      
      Critical_Count : Integer := 0;
      pragma Atomic (Critical_Count);
      
      Max_Concurrent : Integer := 0;
      pragma Atomic (Max_Concurrent);
      
      task type Test_Scalability_Worker is
         entry Start (ID : Integer);
      end Test_Scalability_Worker;
      
      task body Test_Scalability_Worker is
         My_ID : Integer;
         Current_Count : Integer;
         Conflict : Boolean;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;
         
         for I in 1 .. 2 loop
            for L in 1 .. N - 1 loop
               Level (My_ID) := L;
               Last_To_Enter (L) := My_ID;
               
               loop
                  Conflict := False;
                  for K in 0 .. N - 1 loop
                     if K /= My_ID and then Level (K) >= L then
                        Conflict := True;
                        exit;
                     end if;
                  end loop;
                  
                  exit when not (Conflict and then Last_To_Enter (L) = My_ID);
                  delay 0.0005;
               end loop;
            end loop;
            
            Current_Count := Critical_Count + 1;
            Critical_Count := Current_Count;
            
            if Current_Count > Max_Concurrent then
               Max_Concurrent := Current_Count;
            end if;
            
            delay 0.005;
            
            Critical_Count := Current_Count - 1;
            
            Level (My_ID) := 0;
         end loop;
      end Test_Scalability_Worker;
      
      Tasks : array (0 .. N - 1) of Test_Scalability_Worker;
   begin
      Start_Test ("N-Process Peterson - Scalability (8 processes)");
      
      for I in Tasks'Range loop
         Tasks (I).Start (I);
      end loop;
      
      delay 5.0;
      
      if Max_Concurrent <= 1 then
         End_Test (PASSED, "Mutual exclusion maintained with " & Integer'Image(N) & " processes");
      else
         End_Test (FAILED, "Violation: " & Integer'Image(Max_Concurrent) & " concurrent");
      end if;
   end Test_Peterson_N_Scalability;

   --  ====================================================================
   --  Test 11: 2-Process Peterson - Fairness
   --  Assumption: Peterson's algorithm is fair (no starvation)
   --  Test: Verify both processes get fair access
   --  ====================================================================
   procedure Test_Peterson_2_Fairness is
      Flag : array (0 .. 1) of Boolean := (False, False);
      pragma Atomic_Components (Flag);
      
      Turn : Integer range 0 .. 1 := 0;
      pragma Atomic (Turn);
      
      Entry_Count : array (0 .. 1) of Integer := (0, 0);
      pragma Atomic_Components (Entry_Count);
      
      task type Test_Fairness_Worker is
         entry Start (ID : Integer);
      end Test_Fairness_Worker;
      
      task body Test_Fairness_Worker is
         My_ID : Integer;
         Other : Integer;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;
         Other := 1 - My_ID;
         
         for I in 1 .. 20 loop
            Flag (My_ID) := True;
            Turn := Other;
            
            while Flag (Other) and then Turn = Other loop
               delay 0.0001;
            end loop;
            
            Entry_Count (My_ID) := Entry_Count (My_ID) + 1;
            
            Flag (My_ID) := False;
         end loop;
      end Test_Fairness_Worker;
      
      Tasks : array (0 .. 1) of Test_Fairness_Worker;
      Ratio : Float;
   begin
      Start_Test ("2-Process Peterson - Fairness");
      
      for I in Tasks'Range loop
         Tasks (I).Start (I);
      end loop;
      
      delay 5.0;
      
      -- Check fairness: ratio should be between 0.5 and 2.0
      if Entry_Count (1) > 0 then
         Ratio := Float(Entry_Count (0)) / Float(Entry_Count (1));
      else
         Ratio := Float(Entry_Count (0));
      end if;
      
      if Ratio >= 0.5 and Ratio <= 2.0 then
         End_Test (PASSED, "Fair ratio: " & Float'Image(Ratio));
      else
         End_Test (FAILED, "Unfair ratio: " & Float'Image(Ratio) & 
                  " (P0=" & Integer'Image(Entry_Count(0)) & 
                  ", P1=" & Integer'Image(Entry_Count(1)) & ")");
      end if;
   end Test_Peterson_2_Fairness;

   --  ====================================================================
   --  Test 12: N-Process Peterson - Bounded Waiting
   --  Assumption: Filter algorithm ensures bounded waiting
   --  Test: Verify no process waits excessively
   --  ====================================================================
   procedure Test_Peterson_N_Bounded_Waiting is
      N : constant := 4;
      
      Level : array (0 .. N - 1) of Integer := (others => 0);
      pragma Atomic_Components (Level);
      
      Last_To_Enter : array (1 .. N - 1) of Integer := (others => 0);
      pragma Atomic_Components (Last_To_Enter);
      
      Entry_Times : array (0 .. N - 1, 1 .. 3) of Time;
      Exit_Times : array (0 .. N - 1, 1 .. 3) of Time;
      
      task type Test_N_Bounded_Worker is
         entry Start (ID : Integer);
      end Test_N_Bounded_Worker;
      
      task body Test_N_Bounded_Worker is
         My_ID : Integer;
         Conflict : Boolean;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;
         
         for I in 1 .. 3 loop
            for L in 1 .. N - 1 loop
               Level (My_ID) := L;
               Last_To_Enter (L) := My_ID;
               
               loop
                  Conflict := False;
                  for K in 0 .. N - 1 loop
                     if K /= My_ID and then Level (K) >= L then
                        Conflict := True;
                        exit;
                     end if;
                  end loop;
                  
                  exit when not (Conflict and then Last_To_Enter (L) = My_ID);
                  delay 0.0;
               end loop;
            end loop;
            
            Entry_Times (My_ID, I) := Clock;
            
            delay 0.01;
            
            Exit_Times (My_ID, I) := Clock;
            
            Level (My_ID) := 0;
         end loop;
      end Test_N_Bounded_Worker;
      
      Tasks : array (0 .. N - 1) of Test_N_Bounded_Worker;
      Max_Wait_Time : Time_Span := Milliseconds (0);
      Current_Wait : Time_Span;
   begin
      Start_Test ("N-Process Peterson - Bounded Waiting");
      
      for I in Tasks'Range loop
         Tasks (I).Start (I);
      end loop;
      
      delay 5.0;
      
      -- Check wait times
      for P in 0 .. N - 1 loop
         for I in 1 .. 3 loop
            if Exit_Times (P, I) > Entry_Times (P, I) then
               Current_Wait := Exit_Times (P, I) - Entry_Times (P, I);
               if Current_Wait > Max_Wait_Time then
                  Max_Wait_Time := Current_Wait;
               end if;
            end if;
         end loop;
      end loop;
      
      -- With N=4 and 3 iterations, wait should be reasonable
      if Max_Wait_Time < Milliseconds (1000) then
         End_Test (PASSED, "Max wait: " & Time_Span_To_String(Max_Wait_Time));
      else
         End_Test (FAILED, "Excessive wait: " & Time_Span_To_String(Max_Wait_Time));
      end if;
   end Test_Peterson_N_Bounded_Waiting;

   --  ====================================================================
   --  Test 13: Edge Case - Single Process (2-Process Peterson)
   --  Assumption: Algorithm should work even if only one process runs
   --  Test: Verify single process can enter critical section
   --  ====================================================================
   procedure Test_Peterson_Single_Process is
      Flag : array (0 .. 1) of Boolean := (False, False);
      pragma Atomic_Components (Flag);
      
      Turn : Integer range 0 .. 1 := 0;
      pragma Atomic (Turn);
      
      Entry_Count : Integer := 0;
      pragma Atomic (Entry_Count);
      
      task type Test_Single_Worker is
         entry Start (ID : Integer);
      end Test_Single_Worker;
      
      task body Test_Single_Worker is
         My_ID : Integer;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;
         
         for I in 1 .. 5 loop
            Flag (My_ID) := True;
            Turn := 1 - My_ID; -- Other process
            
            while Flag (1 - My_ID) and then Turn = (1 - My_ID) loop
               delay 0.0;
            end loop;
            
            Entry_Count := Entry_Count + 1;
            
            Flag (My_ID) := False;
            delay 0.01;
         end loop;
      end Test_Single_Worker;
      
      Worker : Test_Single_Worker;
   begin
      Start_Test ("Edge Case - Single Process");
      
      Worker.Start (0);
      
      delay 2.0;
      
      if Entry_Count = 5 then
         End_Test (PASSED, "Single process completed 5 entries");
      else
         End_Test (FAILED, "Only " & Integer'Image(Entry_Count) & " entries");
      end if;
   end Test_Peterson_Single_Process;

   --  ====================================================================
   --  Test 14: Edge Case - Immediate Exit (2-Process Peterson)
   --  Assumption: Process can enter and exit immediately
   --  Test: Verify rapid entry and exit
   --  ====================================================================
   procedure Test_Peterson_Immediate_Exit is
      Flag : array (0 .. 1) of Boolean := (False, False);
      pragma Atomic_Components (Flag);
      
      Turn : Integer range 0 .. 1 := 0;
      pragma Atomic (Turn);
      
      Entry_Count : array (0 .. 1) of Integer := (0, 0);
      pragma Atomic_Components (Entry_Count);
      
      task type Test_Immediate_Worker is
         entry Start (ID : Integer);
      end Test_Immediate_Worker;
      
      task body Test_Immediate_Worker is
         My_ID : Integer;
         Other : Integer;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;
         Other := 1 - My_ID;
         
         for I in 1 .. 10 loop
            Flag (My_ID) := True;
            Turn := Other;
            
            while Flag (Other) and then Turn = Other loop
               delay 0.0;
            end loop;
            
            Entry_Count (My_ID) := Entry_Count (My_ID) + 1;
            
            Flag (My_ID) := False;
            -- No delay in critical section
         end loop;
      end Test_Immediate_Worker;
      
      Tasks : array (0 .. 1) of Test_Immediate_Worker;
   begin
      Start_Test ("Edge Case - Immediate Exit");
      
      for I in Tasks'Range loop
         Tasks (I).Start (I);
      end loop;
      
      delay 2.0;
      
      if Entry_Count (0) >= 5 and Entry_Count (1) >= 5 then
         End_Test (PASSED, "Rapid entry/exit successful");
      else
         End_Test (FAILED, "P0=" & Integer'Image(Entry_Count(0)) & 
                  ", P1=" & Integer'Image(Entry_Count(1)));
      end if;
   end Test_Peterson_Immediate_Exit;

   --  ====================================================================
   --  Test 15: Assumption Test - Flag Not Set
   --  Assumption: If a process doesn't set its flag, others can proceed
   --  Test: Verify that unset flag allows other processes through
   --  ====================================================================
   procedure Test_Peterson_Flag_Not_Set is
      Flag : array (0 .. 1) of Boolean := (False, False);
      pragma Atomic_Components (Flag);
      
      Turn : Integer range 0 .. 1 := 0;
      pragma Atomic (Turn);
      
      Entry_Count : array (0 .. 1) of Integer := (0, 0);
      pragma Atomic_Components (Entry_Count);
      
      task type Test_Flag_Worker is
         entry Start (ID : Integer);
      end Test_Flag_Worker;
      
      task body Test_Flag_Worker is
         My_ID : Integer;
         Other : Integer;
      begin
         accept Start (ID : Integer) do
            My_ID := ID;
         end Start;
         Other := 1 - My_ID;
         
         -- Process 0 doesn't set its flag (simulating a bug or edge case)
         if My_ID = 1 then
            for I in 1 .. 5 loop
               Flag (My_ID) := True;
               Turn := Other;
               
               while Flag (Other) and then Turn = Other loop
                  delay 0.0;
               end loop;
               
               Entry_Count (My_ID) := Entry_Count (My_ID) + 1;
               
               Flag (My_ID) := False;
               delay 0.01;
            end loop;
         end if;
      end Test_Flag_Worker;
      
      Tasks : array (0 .. 1) of Test_Flag_Worker;
   begin
      Start_Test ("Assumption - Flag Not Set");
      
      for I in Tasks'Range loop
         Tasks (I).Start (I);
      end loop;
      
      delay 2.0;
      
      -- Process 1 should be able to enter since Process 0 never sets its flag
      if Entry_Count (1) >= 3 then
         End_Test (PASSED, "Process 1 entered " & Integer'Image(Entry_Count(1)) & " times");
      else
         End_Test (FAILED, "Process 1 only entered " & Integer'Image(Entry_Count(1)) & " times");
      end if;
   end Test_Peterson_Flag_Not_Set;

begin
   Put_Line ("========================================");
   Put_Line ("Peterson Algorithm Test Suite");
   Put_Line ("========================================");
   New_Line;

   -- Run all tests
   Test_Strict_Alternation_Mutual_Exclusion;
   Test_Strict_Alternation_Progress;
   Test_Peterson_2_Mutual_Exclusion;
   Test_Peterson_2_Bounded_Waiting;
   Test_Peterson_2_Progress;
   Test_Peterson_N_Mutual_Exclusion;
   Test_Peterson_N_Progress;
   Test_Strict_Alternation_Starvation;
   Test_Peterson_2_No_Deadlock;
   Test_Peterson_N_Scalability;
   Test_Peterson_2_Fairness;
   Test_Peterson_N_Bounded_Waiting;
   Test_Peterson_Single_Process;
   Test_Peterson_Immediate_Exit;
   Test_Peterson_Flag_Not_Set;

   -- Print summary
   Print_Summary;

end Peterson_Tests;
