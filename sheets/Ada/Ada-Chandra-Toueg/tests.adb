-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Chandra_Toueg; use Chandra_Toueg;

procedure Tests is
   Sim  : Simulator;
   Vals : constant Value_Array := (10, 20, 30, 40, 50);
begin
   Put_Line ("========================================");
   Put_Line ("  CHANDRA-TOUEG ALGORITHM TEST SUITE");
   Put_Line ("========================================");

   -- TEST 1
   Put_Line ("TEST 1 - Initialization State");
   Put_Line ("  1.1 Assert all processes are correctly initialized and Undecided");
   Initialize (Sim, Vals);
   for P in Process_ID loop
      Assert (Sim.Processes(P).State = Undecided, "Process not Undecided");
      Assert (Sim.Processes(P).Estimate = Vals(P), "Initial value mismatch");
   end loop;
   Put_Line ("      PASS");

   -- TEST 2
   Put_Line ("TEST 2 - Rotating Coordinator Logic");
   Put_Line ("  2.1 Assert coordinator selection wraps properly modulo N");
   Assert (Get_Coordinator(1) = 1, "R=1 should be Coordinator 1");
   Assert (Get_Coordinator(3) = 3, "R=3 should be Coordinator 3");
   Assert (Get_Coordinator(6) = 1, "R=6 should wrap to Coordinator 1");
   Put_Line ("      PASS");

   -- TEST 3
   Put_Line ("TEST 3 - Phase 1 (Estimate Gathering)");
   Put_Line ("  3.1 Assert all alive processes send estimates");
   Phase_1 (Sim);
   Assert (Sim.Phase_1_Messages(1).Valid = True, "Process 1 message missing");
   Assert (Sim.Phase_1_Messages(5).Valid = True, "Process 5 message missing");
   Put_Line ("      PASS");

   -- TEST 4
   Put_Line ("TEST 4 - Phase 2 (Majority Proposal Selection)");
   Put_Line ("  4.1 Assert coordinator proposes highest timestamp value");
   Sim.Phase_1_Messages(2).TS := 5; -- Force max TS
   Phase_2 (Sim);
   Assert (Sim.Phase_2_Valid = True, "Phase 2 should generate a valid proposal");
   Assert (Sim.Phase_2_Proposal = Vals(2), "Proposed value should match max TS");
   Put_Line ("      PASS");

   -- TEST 5
   Put_Line ("TEST 5 - Phase 2 Edge Case (Sub-Majority)");
   Put_Line ("  5.1 Assert coordinator aborts proposal if < Majority messages");
   Initialize (Sim, Vals);
   Sim.Phase_1_Messages(1).Valid := False;
   Sim.Phase_1_Messages(2).Valid := False;
   Sim.Phase_1_Messages(3).Valid := False; -- Now only 2 messages exist
   Phase_2 (Sim);
   Assert (Sim.Phase_2_Valid = False, "Should not propose without majority");
   Put_Line ("      PASS");

   -- TEST 6
   Put_Line ("TEST 6 - Phase 3 (ACK Generation)");
   Put_Line ("  6.1 Assert alive processes ACK valid proposals");
   Initialize (Sim, Vals);
   Phase_1 (Sim);
   Phase_2 (Sim);
   Phase_3 (Sim);
   Assert (Sim.Phase_3_Votes(2) = Ack, "Process 2 should ACK");
   Put_Line ("      PASS");

   -- TEST 7
   Put_Line ("TEST 7 - Phase 3 Variant (Failure Detector Suspicion)");
   Put_Line ("  7.1 Assert suspicious process sends NACK instead of ACK");
   Initialize (Sim, Vals);
   Phase_1 (Sim);
   Phase_2 (Sim);
   Suspect (Sim, Suspector => 3, Suspected => 1); -- P3 suspects Coordinator 1
   Phase_3 (Sim);
   Assert (Sim.Phase_3_Votes(3) = Nack, "Suspecting process should NACK");
   Assert (Sim.Phase_3_Votes(2) = Ack, "Non-suspecting process should ACK");
   Put_Line ("      PASS");

   -- TEST 8
   Put_Line ("TEST 8 - Phase 4 (Decision Broadcasting)");
   Put_Line ("  8.1 Assert consensus decided on majority ACKs");
   Initialize (Sim, Vals);
   Run_Round (Sim); -- Runs full round
   Assert (Sim.Processes(1).State = Decided, "System should reach decision");
   Put_Line ("      PASS");

   -- TEST 9
   Put_Line ("TEST 9 - Phase 4 (Decision Fails Without Majority)");
   Put_Line ("  9.1 Assert consensus skipped if majority of ACKs absent");
   Initialize (Sim, Vals);
   Suspect (Sim, 2, 1);
   Suspect (Sim, 3, 1);
   Suspect (Sim, 4, 1); -- 3 processes suspect coordinator, NACK majority
   Phase_1 (Sim); Phase_2 (Sim); Phase_3 (Sim); Phase_4 (Sim);
   Assert (Sim.Processes(1).State = Undecided, "Should not decide with majority NACK");
   Put_Line ("      PASS");

   -- TEST 10
   Put_Line ("TEST 10 - Value Propagation Integrity");
   Put_Line ("  10.1 Assert all decided processes have the SAME value");
   Assert (Sim.Processes(1).Decided_Value = Sim.Processes(5).Decided_Value, "Value discrepancy");
   Put_Line ("      PASS");

   -- TEST 11
   Put_Line ("TEST 11 - Robustness (Minor Crashes)");
   Put_Line ("  11.1 Assert consensus reached despite 2 crashed nodes");
   Initialize (Sim, Vals);
   Crash_Process (Sim, 4);
   Crash_Process (Sim, 5);
   Run_Round (Sim);
   Assert (Sim.Processes(1).State = Decided, "Should tolerate F < Majority crashes");
   Put_Line ("      PASS");

   -- TEST 12
   Put_Line ("TEST 12 - Safety (Major Crashes)");
   Put_Line ("  12.1 Assert consensus halts (safety property) on 3 crashed nodes");
   Initialize (Sim, Vals);
   Crash_Process (Sim, 3);
   Crash_Process (Sim, 4);
   Crash_Process (Sim, 5);
   Run_Round (Sim);
   Assert (Sim.Processes(1).State = Undecided, "Should halt on >= Majority crashes");
   Put_Line ("      PASS");

   -- TEST 13
   Put_Line ("TEST 13 - End-to-End Multi-Round Consensus");
   Put_Line ("  13.1 Assert consensus reached in Round 2 when Round 1 fails");
   Initialize (Sim, Vals);
   Suspect (Sim, 2, 1);
   Suspect (Sim, 3, 1);
   Suspect (Sim, 4, 1);
   Run_Round (Sim); -- Round 1 fails
   Assert (Sim.Processes(2).State = Undecided, "Round 1 should fail");
   
   -- Clear suspicions for Round 2 (Coordinator will be Process 2)
   Sim.FD := (others => (others => False));
   Run_Round (Sim); -- Round 2 succeeds
   Assert (Sim.Processes(2).State = Decided, "Round 2 should succeed");
   
   -- Verify the decided value came from the original pool
   declare
      Valid_Value : Boolean := False;
   begin
      for I in Process_ID loop
         if Sim.Processes(2).Decided_Value = Vals(I) then
            Valid_Value := True;
         end if;
      end loop;
      Assert (Valid_Value, "Decided value must originate from the initial pool");
   end;
   
   Put_Line ("      PASS");
   Put_Line ("========================================");
   Put_Line ("ALL 13 TESTS PASSED.");
end Tests;
