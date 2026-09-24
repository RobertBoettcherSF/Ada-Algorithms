with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Bully_System; use Bully_System;

procedure Tests is
   Network : Process_Array (1 .. 3) := (
      (1, True, Idle),
      (2, True, Idle),
      (3, True, Idle)
   );
begin
   Put_Line("--- Running Bully Algorithm Test Suite ---");

   -- TEST 1: Initialization
   Put_Line("TEST 1 - Initial State Check");
   Assert (Get_Coordinator(Network) = 0, "Coordinator should be 0 initially");
   Put_Line("   PASS");

   -- TEST 2: Single Node Election
   Put_Line("TEST 2 - Single Node Election");
   declare
      Single_Net : Process_Array (1 .. 1) := (1 => Process'(1, True, Idle));
   begin
      Start_Election(Single_Net, 1);
      Assert (Get_Coordinator(Single_Net) = 1, "Process 1 should be coordinator");
      Put_Line("   PASS");
   end;

   -- TEST 3: Higher ID Preemption
   Put_Line("TEST 3 - Higher ID Preemption");
   Start_Election(Network, 2);
   Assert (Get_Coordinator(Network) = 3, "Process 3 should supersede 2");
   Put_Line("   PASS");

   -- TEST 4: Node Failure
   Put_Line("TEST 4 - Node Failure");
   Fail_Process(Network, 3);
   Assert (Get_Coordinator(Network) = 0, "Coordinator should reset after failure");
   Put_Line("   PASS");

   -- TEST 5: Recovery and Election
   Put_Line("TEST 5 - Recovery and Election");
   Recover_Process(Network, 3);
   Start_Election(Network, 1);
   Assert (Get_Coordinator(Network) = 3, "3 should regain coordinator status");
   Put_Line("   PASS");

   -- TEST 6: All Nodes Fail
   Put_Line("TEST 6 - All Nodes Fail");
   Fail_Process(Network, 1); Fail_Process(Network, 2); Fail_Process(Network, 3);
   Assert (Get_Coordinator(Network) = 0, "No nodes alive, no coordinator");
   Put_Line("   PASS");

   -- TEST 7: Idempotency (Repeat Election)
   Put_Line("TEST 7 - Idempotency");
   Recover_Process(Network, 1);
   Start_Election(Network, 1);
   Start_Election(Network, 1);
   Assert (Get_Coordinator(Network) = 1, "Idempotency failed");
   Put_Line("   PASS");

   -- TEST 8: Middle Node Election
   Put_Line("TEST 8 - Middle Node Election");
   Recover_Process(Network, 2);
   Start_Election(Network, 2);
   Assert (Get_Coordinator(Network) = 2, "2 should be coord (3 is still dead)");
   Put_Line("   PASS");

   -- TEST 9: Empty Network Edge Case
   Put_Line("TEST 9 - Empty Network Logic");
   declare
      Empty_Net : Process_Array (1 .. 0);
   begin
      Assert (Get_Coordinator(Empty_Net) = 0, "Empty net should return 0");
      Put_Line("   PASS");
   end;

   -- TEST 10: Non-Sequential IDs (Robustness)
   Put_Line("TEST 10 - Non-Sequential IDs");
   declare
      Custom_Net : Process_Array (1 .. 2) := (1 => Process'(10, True, Idle), 2 => Process'(5, True, Idle));
   begin
      Start_Election(Custom_Net, 5);
      Assert (Get_Coordinator(Custom_Net) = 10, "10 should beat 5");
      Put_Line("   PASS");
   end;

   -- TEST 11: Fail Current Coordinator
   Put_Line("TEST 11 - Fail Current Coordinator");
   Fail_Process(Network, 2);
   Start_Election(Network, 1);
   Assert (Get_Coordinator(Network) = 1, "1 should become coordinator after 2 fails");
   Put_Line("   PASS");

   -- TEST 12: Recovery Triggering Election
   Put_Line("TEST 12 - Recovery Triggering Election");
   Recover_Process(Network, 3);
   Start_Election(Network, 1);
   Assert (Get_Coordinator(Network) = 3, "New process 3 should take coordinator");
   Put_Line("   PASS");

   -- TEST 13: Integrity Check (Multiple coordinators not allowed)
   Put_Line("TEST 13 - Single Coordinator Integrity");
   declare
      Count : Integer := 0;
   begin
      for P of Network loop
         if P.Status = Coordinator then Count := Count + 1; end if;
      end loop;
      Assert (Count <= 1, "Multiple coordinators found!");
      Put_Line("   PASS");
   end;

end Tests;
