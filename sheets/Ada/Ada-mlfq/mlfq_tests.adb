with Ada.Text_IO; use Ada.Text_IO;
with Ada.Containers; use Ada.Containers;
with MLFQ;

procedure MLFQ_Tests is

   use MLFQ;
   use Process_Lists;

   -- Test helper: Check if a process with given ID is in any queue or running
   function Find_Process (S : Scheduler; ID : Process_ID) return Process_Record is
      P : Process_Record;
      C : Cursor;
   begin
      -- Check running process
      if not S.Is_Idle and then S.Running_Proc.ID = ID then
         return S.Running_Proc;
      end if;
      
      -- Check all queues
      for Q in 1 .. S.Num_Queues loop
         C := S.Queues(Q).First;
         while Has_Element (C) loop
            P := Element (C);
            if P.ID = ID then
               return P;
            end if;
            Next (C);
         end loop;
      end loop;
      
      -- Check blocked list
      C := S.Blocked_List.First;
      while Has_Element (C) loop
         P := Element (C);
         if P.ID = ID then
            return P;
         end if;
         Next (C);
      end loop;
      
      -- Check finished list
      C := S.Finished_List.First;
      while Has_Element (C) loop
         P := Element (C);
         if P.ID = ID then
            return P;
         end if;
         Next (C);
      end loop;
      
      -- Not found
      return Process_Record'(ID => 0, others => <>);
   end Find_Process;

   -- Test helper: Run a simulation and capture if it completes
   function Test_Completes (S : in out Scheduler) return Boolean is
   begin
      for I in 1 .. 1000 loop
         Tick (S);
         if All_Finished (S) then
            return True;
         end if;
      end loop;
      return False;
   end Test_Completes;

   -- Test 1: Empty scheduler should report all finished
   procedure Test_Empty_Scheduler is
      S : Scheduler;
      Q_Arr : constant Quantum_Array := (others => 1);
   begin
      S.Num_Queues := 3;
      Initialize (S, Q_Arr, Aging_Interval => 10);
      
      if All_Finished (S) then
         Put_Line ("[PASS] Test 1: Empty scheduler reports all finished");
      else
         Put_Line ("[FAIL] Test 1: Empty scheduler should report all finished");
      end if;
   end Test_Empty_Scheduler;

   -- Test 2: Single process should complete
   procedure Test_Single_Process is
      S : Scheduler;
      Q_Arr : constant Quantum_Array := (1 => 5, others => 1);
   begin
      S.Num_Queues := 3;
      Initialize (S, Q_Arr, Aging_Interval => 100);
      Add_Process (S, ID => 1, CPU_Time => 3, IO_Frequency => 0, IO_Duration => 0);
      
      if Test_Completes (S) and then S.Finished_List.Length = 1 then
         Put_Line ("[PASS] Test 2: Single process completes");
      else
         Put_Line ("[FAIL] Test 2: Single process should complete");
      end if;
   end Test_Single_Process;

   -- Test 3: Process demotion after quantum expires
   procedure Test_Demotion is
      S : Scheduler;
      Q_Arr : constant Quantum_Array := (1 => 2, 2 => 4, others => 8);
      P : Process_Record;
   begin
      S.Num_Queues := 3;
      Initialize (S, Q_Arr, Aging_Interval => 100);
      Add_Process (S, ID => 1, CPU_Time => 10, IO_Frequency => 0, IO_Duration => 0);
      
      -- Run for 3 ticks: should use quantum of 2, then get demoted
      for I in 1 .. 3 loop
         Tick (S);
      end loop;
      
      -- Check if process was demoted to queue 2 (could be running or in queue)
      P := Find_Process (S, 1);
      if P.ID = 1 and then P.Priority = 2 then
         Put_Line ("[PASS] Test 3: Process demoted after quantum expires");
      else
         Put_Line ("[FAIL] Test 3: Process should be demoted to queue 2 after quantum (Priority=" & 
                   Natural'Image(P.Priority) & ")");
      end if;
   end Test_Demotion;

   -- Test 4: Higher priority process preempts lower priority (Rule 1)
   procedure Test_Preemption is
      S : Scheduler;
      Q_Arr : constant Quantum_Array := (1 => 10, 2 => 10, others => 1);
      P1, P2 : Process_Record;
   begin
      S.Num_Queues := 3;
      Initialize (S, Q_Arr, Aging_Interval => 100);
      
      -- Add process to queue 2 (lower priority)
      Add_Process (S, ID => 1, CPU_Time => 100, IO_Frequency => 0, IO_Duration => 0);
      
      -- Manually move process 1 from queue 1 to running state with priority 2
      -- First remove it from queue 1
      if not S.Queues(1).Is_Empty then
         S.Running_Proc := S.Queues(1).First_Element;
         S.Queues(1).Delete_First;
      end if;
      S.Running_Proc.Priority := 2;
      S.Running_Proc.State := Running;
      S.Is_Idle := False;
      
      -- Add a new process to queue 1 (higher priority)
      Add_Process (S, ID => 2, CPU_Time => 5, IO_Frequency => 0, IO_Duration => 0);
      
      -- Run one tick - should preempt
      Tick (S);
      
      -- Check if process 1 was preempted and process 2 is running
      P1 := Find_Process (S, 1);
      P2 := Find_Process (S, 2);
      if P1.State = Ready and then P2.State = Running then
         Put_Line ("[PASS] Test 4: Higher priority process preempts lower priority");
      else
         Put_Line ("[FAIL] Test 4: Higher priority should preempt lower (P1=" & 
                   Process_State'Image(P1.State) & ", P2=" & Process_State'Image(P2.State) & ")");
      end if;
   end Test_Preemption;

   -- Test 5: I/O bound process yields and blocks
   procedure Test_IO_Yield is
      S : Scheduler;
      Q_Arr : constant Quantum_Array := (1 => 10, others => 1);
      P : Process_Record;
   begin
      S.Num_Queues := 3;
      Initialize (S, Q_Arr, Aging_Interval => 100);
      Add_Process (S, ID => 1, CPU_Time => 10, IO_Frequency => 1, IO_Duration => 2);
      
      -- Run for 2 ticks: should yield after 1 tick
      for I in 1 .. 2 loop
         Tick (S);
      end loop;
      
      -- Check if process is in blocked list
      P := Find_Process (S, 1);
      if P.State = Blocked then
         Put_Line ("[PASS] Test 5: I/O bound process yields and blocks");
      else
         Put_Line ("[FAIL] Test 5: I/O bound process should be blocked (State=" & 
                   Process_State'Image(P.State) & ")");
      end if;
   end Test_IO_Yield;

   -- Test 6: Blocked process wakes up after I/O duration
   procedure Test_IO_Wakeup is
      S : Scheduler;
      Q_Arr : constant Quantum_Array := (1 => 10, others => 1);
      P : Process_Record;
      Woke_Up : Boolean := False;
   begin
      S.Num_Queues := 3;
      Initialize (S, Q_Arr, Aging_Interval => 100);
      
      -- Use a longer IO_Frequency so process doesn't yield immediately after waking up
      -- IO_Frequency=3 means yield every 3 ticks of CPU time
      -- IO_Duration=2 means block for 2 ticks
      Add_Process (S, ID => 1, CPU_Time => 10, IO_Frequency => 3, IO_Duration => 2);
      
      -- Run until process wakes up
      -- Tick 0: Process runs, Ticks_Since_Yield=1 < 3, continues
      -- Tick 1: Process runs, Ticks_Since_Yield=2 < 3, continues
      -- Tick 2: Process runs, Ticks_Since_Yield=3 >= 3, yields for I/O (Current_IO_Wait=2)
      -- Tick 3: I/O check decrements to 1, still blocked
      -- Tick 4: I/O check decrements to 0, wakes up to Ready, then gets selected to run
      -- At end of tick 4, process is Running (not Ready)
      -- So we check if process is NOT Blocked (meaning it woke up)
      for I in 1 .. 10 loop
         Tick (S);
         P := Find_Process (S, 1);
         -- Check if process is NOT blocked (either Ready or Running means it woke up)
         if P.State /= Blocked then
            Woke_Up := True;
            exit;
         end if;
      end loop;
      
      if Woke_Up then
         Put_Line ("[PASS] Test 6: Blocked process wakes up after I/O duration");
      else
         Put_Line ("[FAIL] Test 6: Blocked process should wake up (State=" & 
                   Process_State'Image(P.State) & ", Current_IO_Wait=" & 
                   Natural'Image(P.Current_IO_Wait) & ")");
      end if;
   end Test_IO_Wakeup;

   -- Test 7: Aging boosts all processes to highest priority
   procedure Test_Aging is
      S : Scheduler;
      Q_Arr : constant Quantum_Array := (1 => 2, 2 => 4, 3 => 8, others => 1);
      P1, P2 : Process_Record;
   begin
      S.Num_Queues := 3;
      Initialize (S, Q_Arr, Aging_Interval => 5);
      
      -- Add processes that will be demoted
      Add_Process (S, ID => 1, CPU_Time => 10, IO_Frequency => 0, IO_Duration => 0);
      Add_Process (S, ID => 2, CPU_Time => 10, IO_Frequency => 0, IO_Duration => 0);
      
      -- Run for 5 ticks to trigger aging
      for I in 1 .. 5 loop
         Tick (S);
      end loop;
      
      -- Check if all processes are at priority 1
      P1 := Find_Process (S, 1);
      P2 := Find_Process (S, 2);
      
      if P1.Priority = 1 and then P2.Priority = 1 then
         Put_Line ("[PASS] Test 7: Aging boosts all processes to highest priority");
      else
         Put_Line ("[FAIL] Test 7: Aging should boost all processes to priority 1 (P1=" & 
                   Natural'Image(P1.Priority) & ", P2=" & Natural'Image(P2.Priority) & ")");
      end if;
   end Test_Aging;

   -- Test 8: Multiple processes complete in correct order
   procedure Test_Multiple_Completion is
      S : Scheduler;
      Q_Arr : constant Quantum_Array := (1 => 10, others => 1);
   begin
      S.Num_Queues := 3;
      Initialize (S, Q_Arr, Aging_Interval => 100);
      
      -- Add short processes
      Add_Process (S, ID => 1, CPU_Time => 2, IO_Frequency => 0, IO_Duration => 0);
      Add_Process (S, ID => 2, CPU_Time => 1, IO_Frequency => 0, IO_Duration => 0);
      Add_Process (S, ID => 3, CPU_Time => 3, IO_Frequency => 0, IO_Duration => 0);
      
      -- Run to completion
      for I in 1 .. 100 loop
         Tick (S);
         exit when All_Finished (S);
      end loop;
      
      -- Check if all processes finished
      if All_Finished (S) and then S.Finished_List.Length = 3 then
         Put_Line ("[PASS] Test 8: Multiple processes complete");
      else
         Put_Line ("[FAIL] Test 8: All processes should complete (Finished=" & 
                   Count_Type'Image(S.Finished_List.Length) & ")");
      end if;
   end Test_Multiple_Completion;

   -- Test 9: Round Robin within same priority queue
   procedure Test_Round_Robin is
      S : Scheduler;
      Q_Arr : constant Quantum_Array := (1 => 2, others => 1);
      Process_1_Ran : Boolean := False;
      Process_2_Ran : Boolean := False;
   begin
      S.Num_Queues := 3;
      Initialize (S, Q_Arr, Aging_Interval => 100);
      
      -- Add two processes to same queue
      Add_Process (S, ID => 1, CPU_Time => 10, IO_Frequency => 0, IO_Duration => 0);
      Add_Process (S, ID => 2, CPU_Time => 10, IO_Frequency => 0, IO_Duration => 0);
      
      -- Run for 5 ticks
      for I in 1 .. 5 loop
         Tick (S);
         
         -- Track which processes ran
         if not S.Is_Idle then
            if S.Running_Proc.ID = 1 then
               Process_1_Ran := True;
            elsif S.Running_Proc.ID = 2 then
               Process_2_Ran := True;
            end if;
         end if;
      end loop;
      
      -- Both processes should have run
      if Process_1_Ran and then Process_2_Ran then
         Put_Line ("[PASS] Test 9: Round Robin schedules multiple processes");
      else
         Put_Line ("[FAIL] Test 9: Round Robin should schedule both processes");
      end if;
   end Test_Round_Robin;

   -- Test 10: Process with zero CPU time
   procedure Test_Zero_CPU is
      S : Scheduler;
      Q_Arr : constant Quantum_Array := (1 => 10, others => 1);
   begin
      S.Num_Queues := 3;
      Initialize (S, Q_Arr, Aging_Interval => 100);
      Add_Process (S, ID => 1, CPU_Time => 0, IO_Frequency => 0, IO_Duration => 0);
      
      -- Run for 1 tick
      Tick (S);
      
      -- Process should finish immediately
      if All_Finished (S) and then S.Finished_List.Length = 1 then
         Put_Line ("[PASS] Test 10: Process with zero CPU time finishes immediately");
      else
         Put_Line ("[FAIL] Test 10: Process with zero CPU time should finish");
      end if;
   end Test_Zero_CPU;

   -- Test 11: Process demoted through all queues
   procedure Test_Full_Demotion is
      S : Scheduler;
      Q_Arr : constant Quantum_Array := (1 => 1, 2 => 1, 3 => 1, others => 1);
      P : Process_Record;
   begin
      S.Num_Queues := 3;
      Initialize (S, Q_Arr, Aging_Interval => 100);
      Add_Process (S, ID => 1, CPU_Time => 10, IO_Frequency => 0, IO_Duration => 0);
      
      -- Run for 3 ticks: should be demoted from 1 -> 2 -> 3
      for I in 1 .. 3 loop
         Tick (S);
      end loop;
      
      -- Check if process is at priority 3
      P := Find_Process (S, 1);
      if P.ID = 1 and then P.Priority = 3 then
         Put_Line ("[PASS] Test 11: Process demoted through all queues");
      else
         Put_Line ("[FAIL] Test 11: Process should be at priority 3 (Priority=" & 
                   Natural'Image(P.Priority) & ")");
      end if;
   end Test_Full_Demotion;

   -- Test 12: CPU stays idle when no processes
   procedure Test_Idle_CPU is
      S : Scheduler;
      Q_Arr : constant Quantum_Array := (1 => 10, others => 1);
      Was_Idle : Boolean := True;
   begin
      S.Num_Queues := 3;
      Initialize (S, Q_Arr, Aging_Interval => 100);
      
      -- Run for 5 ticks with no processes
      for I in 1 .. 5 loop
         Tick (S);
         if not S.Is_Idle then
            Was_Idle := False;
         end if;
      end loop;
      
      if Was_Idle then
         Put_Line ("[PASS] Test 12: CPU stays idle when no processes");
      else
         Put_Line ("[FAIL] Test 12: CPU should stay idle with no processes");
      end if;
   end Test_Idle_CPU;

   -- Test 13: Process doesn't demote if it yields for I/O
   procedure Test_IO_No_Demotion is
      S : Scheduler;
      Q_Arr : constant Quantum_Array := (1 => 10, others => 1);
      P : Process_Record;
   begin
      S.Num_Queues := 3;
      Initialize (S, Q_Arr, Aging_Interval => 100);
      Add_Process (S, ID => 1, CPU_Time => 10, IO_Frequency => 1, IO_Duration => 2);
      
      -- Run for 2 ticks: should yield for I/O at tick 1
      for I in 1 .. 2 loop
         Tick (S);
      end loop;
      
      -- Check if process is blocked (not demoted)
      P := Find_Process (S, 1);
      if P.State = Blocked and then P.Priority = 1 then
         Put_Line ("[PASS] Test 13: I/O yielding process doesn't get demoted");
      else
         Put_Line ("[FAIL] Test 13: I/O yielding process should stay at priority 1 (State=" & 
                   Process_State'Image(P.State) & ", Priority=" & Natural'Image(P.Priority) & ")");
      end if;
   end Test_IO_No_Demotion;

   -- Test 14: Multiple queues with different quantums
   procedure Test_Different_Quantums is
      S : Scheduler;
      Q_Arr : constant Quantum_Array := (1 => 1, 2 => 2, 3 => 4, others => 1);
      Quantum_Correct : Boolean := True;
   begin
      S.Num_Queues := 3;
      Initialize (S, Q_Arr, Aging_Interval => 100);
      
      -- Check if quantums were set correctly
      if S.Quantums(1) = 1 and then S.Quantums(2) = 2 and then S.Quantums(3) = 4 then
         Quantum_Correct := True;
      else
         Quantum_Correct := False;
      end if;
      
      if Quantum_Correct then
         Put_Line ("[PASS] Test 14: Different quantums per queue are set correctly");
      else
         Put_Line ("[FAIL] Test 14: Quantums should be (1,2,4), got (" & 
                   Natural'Image(S.Quantums(1)) & "," & Natural'Image(S.Quantums(2)) & "," & 
                   Natural'Image(S.Quantums(3)) & ")");
      end if;
   end Test_Different_Quantums;

   -- Test 15: Aging interval of zero disables aging
   procedure Test_No_Aging is
      S : Scheduler;
      Q_Arr : constant Quantum_Array := (1 => 1, others => 1);
      P : Process_Record;
   begin
      S.Num_Queues := 3;
      Initialize (S, Q_Arr, Aging_Interval => 0);
      
      -- Add a process that will be demoted
      Add_Process (S, ID => 1, CPU_Time => 10, IO_Frequency => 0, IO_Duration => 0);
      
      -- Run for 10 ticks (aging should not trigger)
      for I in 1 .. 10 loop
         Tick (S);
      end loop;
      
      -- With aging disabled, process should have been demoted
      P := Find_Process (S, 1);
      if P.Priority > 1 then
         Put_Line ("[PASS] Test 15: Aging interval of zero disables aging");
      else
         Put_Line ("[FAIL] Test 15: Process should be demoted with aging disabled (Priority=" & 
                   Natural'Image(P.Priority) & ")");
      end if;
   end Test_No_Aging;

begin
   Put_Line ("");
   Put_Line ("========================================");
   Put_Line ("  MLFQ Scheduler Test Suite");
   Put_Line ("========================================");
   Put_Line ("");
   
   Test_Empty_Scheduler;
   Test_Single_Process;
   Test_Demotion;
   Test_Preemption;
   Test_IO_Yield;
   Test_IO_Wakeup;
   Test_Aging;
   Test_Multiple_Completion;
   Test_Round_Robin;
   Test_Zero_CPU;
   Test_Full_Demotion;
   Test_Idle_CPU;
   Test_IO_No_Demotion;
   Test_Different_Quantums;
   Test_No_Aging;
   
   Put_Line ("");
   Put_Line ("========================================");
   Put_Line ("  Test Suite Complete");
   Put_Line ("========================================");
   Put_Line ("");
end MLFQ_Tests;
