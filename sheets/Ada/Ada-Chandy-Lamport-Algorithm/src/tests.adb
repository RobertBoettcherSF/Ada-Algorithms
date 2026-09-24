with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Chandy_Lamport; use Chandy_Lamport;

procedure Tests is
   N1, N2 : Node;
   Out_Q, Out_Q2 : Message_Queue;
   App_Msg : Message;
begin
   Put_Line("=================================================");
   Put_Line("ASSUMPTION: Codebase is broken and non-functional.");
   Put_Line("GOAL: Execute rigorous tests to DISPROVE assumption.");
   Put_Line("=================================================");

   -- TEST 1
   Put_Line("TEST 1 - Initialization Integrity");
   Init_Node(N1, 1, 150);
   Put_Line("  1.1 Assert Node ID accurately assigned");
   Assert (N1.ID = 1, "ID mismatch");
   Put_Line("  1.2 Assert Initial State matches input");
   Assert (N1.Current_Value = 150, "Initial value mismatch");
   Put_Line("  1.3 Assert Snapshots default to inactive");
   Assert (not N1.Snapshots(1).Is_Active, "Snapshot active at init");
   Put_Line("      PASS");

   -- TEST 2
   Put_Line("TEST 2 - Local State Mutability");
   Update_Local_State(N1, 50);
   Put_Line("  2.1 Assert positive delta updates state");
   Assert (N1.Current_Value = 200, "Failed addition");
   Update_Local_State(N1, -25);
   Put_Line("  2.2 Assert negative delta updates state");
   Assert (N1.Current_Value = 175, "Failed subtraction");
   Put_Line("      PASS");

   -- TEST 3
   Put_Line("TEST 3 - Snapshot Initiation (Single Initiator Variant)");
   Initiate_Snapshot(N1, 1, Out_Q);
   Put_Line("  3.1 Assert Has_Recorded flag triggers");
   Assert (N1.Snapshots(1).Has_Recorded, "Failed to set record flag");
   Put_Line("  3.2 Assert Recorded_Value freezes correctly");
   Assert (N1.Snapshots(1).Recorded_Value = 175, "Recorded wrong value");
   Put_Line("  3.3 Assert out-markers are correctly formatted and bound to Max_Nodes");
   Assert (Integer(Out_Q.Length) = Max_Nodes - 1, "Wrong number of markers");
   Put_Line("      PASS");

   -- TEST 4
   Put_Line("TEST 4 - Marker Reception (First Instance)");
   Init_Node(N2, 2, 500);
   -- Simulate N2 receiving marker from N1
   Receive_Message(N2, Out_Q.First_Element, Out_Q2);
   Put_Line("  4.1 Assert target node records own state");
   Assert (N2.Snapshots(1).Has_Recorded, "N2 failed to record state");
   Put_Line("  4.2 Assert sender's channel immediately closes");
   Assert (N2.Snapshots(1).Channels(1).Is_Closed, "Sender channel not closed");
   Put_Line("  4.3 Assert non-sender channels begin recording");
   Assert (N2.Snapshots(1).Channels(3).Is_Recording, "Other channel not recording");
   Put_Line("      PASS");

   -- TEST 5
   Put_Line("TEST 5 - In-Transit Message Capture");
   App_Msg := Message'(Kind => App_Message, Sender => 3, Receiver => 2, Payload => 10);
   Receive_Message(N2, App_Msg, Out_Q2);
   Put_Line("  5.1 Assert in-transit message alters current state");
   Assert (N2.Current_Value = 510, "State not updated");
   Put_Line("  5.2 Assert in-transit message is queued for the snapshot");
   Assert (Integer(N2.Snapshots(1).Channels(3).Messages.Length) = 1, "Msg not queued");
   Put_Line("  5.3 Assert recorded snapshot state remains immutable");
   Assert (N2.Snapshots(1).Recorded_Value = 500, "Recorded value corrupted");
   Put_Line("      PASS");

   -- TEST 6
   Put_Line("TEST 6 - Marker Reception (Subsequent Instance)");
   declare
      Marker_From_3 : Message := Message'(Kind => Marker_Message, Sender => 3, Receiver => 2, Snap_ID => 1);
   begin
      Receive_Message(N2, Marker_From_3, Out_Q2);
      Put_Line("  6.1 Assert subsequent marker closes target channel");
      Assert (N2.Snapshots(1).Channels(3).Is_Closed, "Channel not closed");
      Put_Line("  6.2 Assert recording halts for target channel");
      Assert (not N2.Snapshots(1).Channels(3).Is_Recording, "Still recording");
      Put_Line("      PASS");
   end;

   -- TEST 7
   Put_Line("TEST 7 - Snapshot Completion Verification");
   Put_Line("  7.1 Assert snapshot complete when all channels closed");
   Assert (Is_Snapshot_Complete(N2, 1), "Snapshot should be complete");
   Put_Line("  7.2 Assert snapshot incomplete on active recording");
   Assert (not Is_Snapshot_Complete(N1, 1), "N1 shouldn't be complete yet");
   Put_Line("      PASS");

   -- TEST 8
   Put_Line("TEST 8 - Invalid Post-Snapshot Message Rejection");
   App_Msg := Message'(Kind => App_Message, Sender => 3, Receiver => 2, Payload => 20);
   Receive_Message(N2, App_Msg, Out_Q2);
   Put_Line("  8.1 Assert post-snapshot message updates local state");
   Assert (N2.Current_Value = 530, "Current state didn't update");
   Put_Line("  8.2 Assert post-snapshot message NOT appended to closed queue");
   Assert (Integer(N2.Snapshots(1).Channels(3).Messages.Length) = 1, "Queue appended illegally");
   Put_Line("      PASS");

   -- TEST 9
   Put_Line("TEST 9 - Concurrent Multi-Initiator Segregation (Variant 2)");
   Initiate_Snapshot(N1, 2, Out_Q); -- Second snapshot overlapping
   Put_Line("  9.1 Assert secondary snapshot tracks distinct state");
   Assert (N1.Snapshots(2).Has_Recorded, "Failed to init 2nd snap");
   Assert (N1.Snapshots(1).Recorded_Value = 175, "Original snap overwritten");
   Assert (N1.Snapshots(2).Recorded_Value = 175, "2nd snap wrong state");
   Put_Line("      PASS");

   -- TEST 10
   Put_Line("TEST 10 - Boundary Constraints Error Handling");
   Put_Line("  10.1 Assert invalid Node_ID bounds raises exception");
   begin
      declare
         N_Err : Node;
      begin
         Init_Node(N_Err, 0, 10);
         Assert (False, "Constraint_Error missing");
      end;
   exception
      when Constraint_Error => Put_Line("  10.1 Passed");
   end;
   
   Put_Line("  10.2 Assert invalid Snapshot_ID bounds raises exception");
   begin
      declare
         Valid_Msg : Message := Message'(Kind => Marker_Message, Sender => 1, Receiver => 2, Snap_ID => 99);
      begin
         Assert (False, "Constraint_Error missing");
      end;
   exception
      when Constraint_Error => Put_Line("  10.2 Passed");
   end;
   Put_Line("      PASS");

   Put_Line("=================================================");
   Put_Line("ALL TESTS PASSED. Assumption disproved.");
   Put_Line("The codebase behaves correctly according to requirements.");
   Put_Line("=================================================");
end Tests;
