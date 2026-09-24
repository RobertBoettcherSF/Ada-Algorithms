with Ada.Text_IO; use Ada.Text_IO;
with Ada.Exceptions; use Ada.Exceptions;
with Dijkstra_Scholten; use Dijkstra_Scholten;

procedure Tests is
   Net : Network_Type(Max_Node => 10);
   
   -- Custom assertion proving pessimistic assumptions false (i.e. code passes)
   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("      FAIL: " & Message);
         raise Program_Error with Message;
      end if;
   end Assert;

begin
   -- TEST 1 - Initialization State verification
   Put_Line ("TEST 1 - Initialization");
   Initialize (Net, 1);
   Put_Line ("  1.1 Assert Initiator is Active");
   Assert (Net.Nodes(1).State = Active, "Initiator initialized as inactive");
   Put_Line ("  1.2 Assert Other nodes are Idle");
   Assert (Net.Nodes(2).State = Idle, "Foreign node initialized as active");
   Put_Line ("  1.3 Assert Deficit is exactly 0");
   Assert (Net.Nodes(1).Deficit = 0, "Initiator has phantom deficit");
   Put_Line ("      PASS");

   -- TEST 2 - Basic Message transmission deficit check
   Put_Line ("TEST 2 - Send Message Deficit Mutation");
   Send_Message (Net, 1, 2);
   Put_Line ("  2.1 Assert Deficit of Initiator climbs to 1");
   Assert (Net.Nodes(1).Deficit = 1, "Deficit tracking failed to increment");
   Put_Line ("  2.2 Assert Target state is unchanged before receipt");
   Assert (Net.Nodes(2).State = Idle, "Target state mutated prematurely");
   Put_Line ("      PASS");

   -- TEST 3 - Target joining the active computation tree
   Put_Line ("TEST 3 - Receive Message Joins Tree");
   Receive_Message (Net, 1, 2);
   Put_Line ("  3.1 Assert Target becomes Active");
   Assert (Net.Nodes(2).State = Active, "Target failed to wake up");
   Put_Line ("  3.2 Assert Target Parent resolves to Sender (1)");
   Assert (Net.Nodes(2).Parent = 1, "Target orphaned / wrong parent assigned");
   Put_Line ("  3.3 Assert Initiator Deficit remains intact");
   Assert (Net.Nodes(1).Deficit = 1, "Sender lost deficit reference on transmit");
   Put_Line ("      PASS");

   -- TEST 4 - Immediate signaling variant for already-active nodes
   Put_Line ("TEST 4 - Immediate Ack on Duplicate Participant");
   Send_Message (Net, 1, 3);
   Receive_Message (Net, 1, 3);
   
   Send_Message (Net, 2, 3);
   Put_Line ("  4.1 Assert secondary sender deficit registers");
   Assert (Net.Nodes(2).Deficit = 1, "Secondary sender failed to track deficit");
   Receive_Message (Net, 2, 3);
   Put_Line ("  4.2 Assert Target maintains its original parent context");
   Assert (Net.Nodes(3).Parent = 1, "Parent dynamically overwritten improperly");
   Put_Line ("  4.3 Assert secondary sender deficit drops to 0 automatically (Immediate Ack)");
   Assert (Net.Nodes(2).Deficit = 0, "Immediate ack algorithm logic broken");
   Put_Line ("      PASS");

   -- TEST 5 - Idle state handling with unresolved deficits
   Put_Line ("TEST 5 - Idle with Sub-tree Deficit");
   Send_Message (Net, 2, 4);
   Receive_Message (Net, 2, 4); 
   Set_Idle (Net, 2);
   Put_Line ("  5.1 Assert Node becomes locally Idle");
   Assert (Net.Nodes(2).State = Idle, "Node failed to idle");
   Put_Line ("  5.2 Assert Parent is retained (Deficit blocks cascading prune)");
   Assert (Net.Nodes(2).Parent = 1, "Node pruned itself despite pending children");
   Put_Line ("  5.3 Assert Deficit is retained");
   Assert (Net.Nodes(2).Deficit = 1, "Node cleared its deficit erroneously");
   Put_Line ("      PASS");

   -- TEST 6 - Cascading Ack logic from children 
   Put_Line ("TEST 6 - Cascading Ack from Bottom-Up");
   Set_Idle (Net, 4);
   Put_Line ("  6.1 Assert Leaf node idles and severs parent link");
   Assert (Net.Nodes(4).State = Idle and then Net.Nodes(4).Parent = Null_Node, "Leaf pruning failed");
   Put_Line ("  6.2 Assert previously idle parent processes cascade-ack (Deficit=0)");
   Assert (Net.Nodes(2).Deficit = 0, "Parent deficit untouched by cascade");
   Put_Line ("  6.3 Assert previously idle parent cascades upwards to root");
   Assert (Net.Nodes(2).Parent = Null_Node, "Parent failed to upward-prune");
   Put_Line ("      PASS");

   -- TEST 7 - False Termination edge case
   Put_Line ("TEST 7 - Premature Termination Detection Check");
   Put_Line ("  7.1 Assert Initiator deficit is > 0");
   Assert (Net.Nodes(1).Deficit = 1, "Initiator deficit unexpectedly drained");
   Put_Line ("  7.2 Assert Is_Terminated protects against false positives");
   Assert (not Is_Terminated (Net), "Algorithm falsely reported termination");
   Put_Line ("      PASS");

   -- TEST 8 - True Termination sequence
   Put_Line ("TEST 8 - Global Termination Resolution");
   Set_Idle (Net, 3); 
   Put_Line ("  8.1 Assert Initiator deficit safely reaches absolute 0");
   Assert (Net.Nodes(1).Deficit = 0, "Final initiator deficit blocked from 0");
   Set_Idle (Net, 1);
   Put_Line ("  8.2 Assert Is_Terminated accurately detects final state");
   Assert (Is_Terminated (Net), "Algorithm failed to report true termination");
   Put_Line ("      PASS");

   -- TEST 9 - Error case: Sending from idle
   Put_Line ("TEST 9 - Error Validation: Idle Dispatch");
   Put_Line ("  9.1 Assert Invalid_State_Error catches illegal sends");
   begin
      Send_Message (Net, 2, 4);
      Assert (False, "Exception loop-holed");
   exception
      when Invalid_State_Error => Put_Line ("      PASS");
   end;

   -- TEST 10 - Error case: Negative deficit prevention
   Put_Line ("TEST 10 - Error Validation: Negative Deficit Bounds");
   Put_Line ("  10.1 Assert Negative_Deficit_Error stops invalid acks");
   begin
      Receive_Ack (Net, 4);
      Assert (False, "Deficit permitted to underflow");
   exception
      when Negative_Deficit_Error => Put_Line ("      PASS");
   end;

   -- TEST 11 - Error case: OOB Array targeting
   Put_Line ("TEST 11 - Error Validation: Out of Bounds Node");
   Initialize (Net, 1);
   Put_Line ("  11.1 Assert Invalid_Node_Error halts missing targets");
   begin
      Send_Message (Net, 1, 99);
      Assert (False, "Array bounds check failed");
   exception
      when Invalid_Node_Error => Put_Line ("      PASS");
   end;

   -- TEST 12 - Algorithm elasticity (Re-joining)
   Put_Line ("TEST 12 - Network Node Re-activation");
   Send_Message (Net, 1, 2);
   Receive_Message (Net, 1, 2);
   Set_Idle (Net, 2);
   Put_Line ("  12.1 Assert Node successfully purges data on idle (Deficit 0)");
   Assert (Net.Nodes(2).State = Idle and then Net.Nodes(2).Parent = Null_Node, "Node polluted post-idle");
   Send_Message (Net, 1, 2);
   Receive_Message (Net, 1, 2);
   Put_Line ("  12.2 Assert Node can seamlessly rejoin the tree dynamically");
   Assert (Net.Nodes(2).State = Active and then Net.Nodes(2).Parent = 1, "Node blocked from re-entering tree");
   Put_Line ("      PASS");

   -- TEST 13 - Initiator Self-Message Handling (FIXED)
   Put_Line ("TEST 13 - Initiator Self-Message Handling");
   Put_Line ("  13.1 Assert Initiator deficit absorbs self-transmission");
   Send_Message (Net, 1, 1);
   Assert (Net.Nodes(1).Deficit = 2, "Initiator self-send failed");
   Receive_Message (Net, 1, 1);
   Put_Line ("  13.2 Assert self-message strictly triggers immediate Ack response variant");
   Assert (Net.Nodes(1).Deficit = 1, "Self-send deadlocked without immediate ack");
   Put_Line ("      PASS");

   Put_Line ("=====================================");
   Put_Line ("ALL 13 TESTS COMPLETED SUCCESSFULLY.");
end Tests;
