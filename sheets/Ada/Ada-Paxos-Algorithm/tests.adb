-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Paxos; use Paxos;

procedure Tests is
   State1 : Acceptor_State;
   Response1 : Promise_Response;
   Accepted_Flag : Boolean;
   Multi_Log : Multi_Acceptor_Array(1 .. 10);
begin
   Put_Line("Running Paxos Verification & Validation Suite");
   Put_Line("---------------------------------------------");

   -- TEST 1
   Put_Line("TEST 1 - Proposal ID Comparison (Number Dominance)");
   Put_Line("  1.1 Assert Proposal(2,0) > Proposal(1,99)");
   Assert (Proposal_ID'(2, 0) > Proposal_ID'(1, 99), "Comparison failed on Number");
   Put_Line("     PASS");

   -- TEST 2
   Put_Line("TEST 2 - Proposal ID Comparison (Node Tiebreaker)");
   Put_Line("  2.1 Assert Proposal(1,5) > Proposal(1,4)");
   Assert (Proposal_ID'(1, 5) > Proposal_ID'(1, 4), "Comparison failed on Node ID");
   Put_Line("     PASS");

   -- TEST 3
   Put_Line("TEST 3 - Basic Paxos Prepare (Clean State)");
   Put_Line("  3.1 Assert Acceptor promises to initial Prepare");
   State1 := (Min_Proposal => (0,0), Accepted_Proposal => (0,0), Accepted_Value => Null_Value);
   Basic_Paxos_Prepare(State1, (1, 1), Response1);
   Assert (Response1.Ack = True, "Acceptor rejected valid initial proposal");
   Assert (State1.Min_Proposal = (1, 1), "State Min_Proposal did not update");
   Put_Line("     PASS");

   -- TEST 4
   Put_Line("TEST 4 - Basic Paxos Prepare (Outdated ID Rejection)");
   Put_Line("  4.1 Assert Acceptor rejects old Proposal ID");
   Basic_Paxos_Prepare(State1, (0, 1), Response1);
   Assert (Response1.Ack = False, "Acceptor accepted outdated proposal ID");
   Put_Line("     PASS");

   -- TEST 5
   Put_Line("TEST 5 - Basic Paxos Prepare (Higher ID Progression)");
   Put_Line("  5.1 Assert Acceptor promises higher ID after previous promise");
   Basic_Paxos_Prepare(State1, (2, 1), Response1);
   Assert (Response1.Ack = True, "Acceptor rejected higher valid proposal");
   Assert (State1.Min_Proposal = (2, 1), "State Min_Proposal did not progress");
   Put_Line("     PASS");

   -- TEST 6
   Put_Line("TEST 6 - Basic Paxos Accept (Valid Path)");
   Put_Line("  6.1 Assert Acceptor accepts matching Proposal ID");
   Basic_Paxos_Accept(State1, (2, 1), 42, Accepted_Flag);
   Assert (Accepted_Flag = True, "Accept failed for valid Proposal");
   Assert (State1.Accepted_Value = 42, "Value was not stored");
   Put_Line("     PASS");

   -- TEST 7
   Put_Line("TEST 7 - Basic Paxos Accept (Old ID Rejection)");
   Put_Line("  7.1 Assert Acceptor rejects accept request for older ID");
   Basic_Paxos_Accept(State1, (1, 1), 99, Accepted_Flag);
   Assert (Accepted_Flag = False, "Accept allowed older proposal to overwrite");
   Assert (State1.Accepted_Value = 42, "Value was improperly overwritten");
   Put_Line("     PASS");

   -- TEST 8
   Put_Line("TEST 8 - Basic Paxos Prepare (Return Prior Value)");
   Put_Line("  8.1 Assert Prepare returns previously accepted values");
   Basic_Paxos_Prepare(State1, (3, 1), Response1);
   Assert (Response1.Ack = True, "Failed to Ack new highest ID");
   Assert (Response1.Previous_Value = 42, "Failed to return previously accepted value");
   Put_Line("     PASS");

   -- TEST 9
   Put_Line("TEST 9 - Multi-Paxos Accept (Valid Instance)");
   Put_Line("  9.1 Assert Instance 5 can accept independently");
   Multi_Paxos_Accept(Multi_Log, 5, (1, 1), 100, Accepted_Flag);
   Assert (Accepted_Flag = True, "Multi-Paxos failed to accept valid instance");
   Assert (Multi_Log(5).Accepted_Value = 100, "Multi-Paxos stored wrong value");
   Put_Line("     PASS");

   -- TEST 10
   Put_Line("TEST 10 - Multi-Paxos Boundary Exception");
   Put_Line("  10.1 Assert accessing out-of-bounds Instance raises Exception");
   begin
      Multi_Paxos_Accept(Multi_Log, 999, (1, 1), 100, Accepted_Flag);
      Assert (False, "Constraint_Error / Invalid_Instance not raised");
   exception
      when Constraint_Error | Invalid_Instance =>
         Put_Line("     PASS");
   end;

   -- TEST 11
   Put_Line("TEST 11 - Fast Paxos (Direct Client Bypass)");
   Put_Line("  11.1 Assert Acceptor handles Fast_Proposal without Phase 1");
   State1 := (Min_Proposal => (0,0), Accepted_Proposal => (0,0), Accepted_Value => Null_Value);
   Fast_Paxos_Any_Accept(State1, 77, Accepted_Flag);
   Assert (Accepted_Flag = True, "Fast Paxos reject Direct Accept");
   Assert (State1.Accepted_Value = 77, "Fast Paxos value not recorded");
   Put_Line("     PASS");

   -- TEST 12
   Put_Line("TEST 12 - Fast Paxos (Conflict Prevention)");
   Put_Line("  12.1 Assert Fast Accept is rejected if already promised higher");
   State1.Min_Proposal := (99, 99); -- Simulating Proposer intervention
   Fast_Paxos_Any_Accept(State1, 88, Accepted_Flag);
   Assert (Accepted_Flag = False, "Fast Paxos incorrectly overrode a higher promised ID");
   Put_Line("     PASS");

   -- TEST 13
   Put_Line("TEST 13 - Cheap Paxos (Main Node Normal Operation)");
   Put_Line("  13.1 Assert Main node accepts when system is healthy");
   State1 := (Min_Proposal => (0,0), Accepted_Proposal => (0,0), Accepted_Value => Null_Value);
   Cheap_Paxos_Accept(State1, Main, True, (1, 1), 55, Accepted_Flag);
   Assert (Accepted_Flag = True, "Main node failed to accept");
   Put_Line("     PASS");

   -- TEST 14
   Put_Line("TEST 14 - Cheap Paxos (Auxiliary Node Standby)");
   Put_Line("  14.1 Assert Aux node rejects operations while Main is Up");
   Cheap_Paxos_Accept(State1, Auxiliary, True, (1, 1), 55, Accepted_Flag);
   Assert (Accepted_Flag = False, "Auxiliary node improperly participated while Main was healthy");
   Put_Line("     PASS");

   -- TEST 15
   Put_Line("TEST 15 - Cheap Paxos (Auxiliary Node Takeover)");
   Put_Line("  15.1 Assert Aux node accepts when Main is Down");
   Cheap_Paxos_Accept(State1, Auxiliary, False, (1, 1), 55, Accepted_Flag);
   Assert (Accepted_Flag = True, "Auxiliary node failed to take over when Main was down");
   Put_Line("     PASS");

   Put_Line("---------------------------------------------");
   Put_Line("All 15 assertions passed. Zero runtime errors.");
end Tests;
