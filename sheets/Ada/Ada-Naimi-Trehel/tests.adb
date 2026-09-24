-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Exceptions; use Ada.Exceptions;
with Naimi_Trehel; use Naimi_Trehel;

procedure Tests is
   Sys : Distributed_System (Num_Nodes => 5);
   Success : Boolean;

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("      FAIL: " & Message);
         raise Program_Error with Message;
      else
         Put_Line ("      PASS");
      end if;
   end Assert;

begin
   Put_Line ("Starting Test Suite for Naimi-Trehel Algorithm");
   Put_Line ("Assuming code is non-functional; proving otherwise...");

   -- TEST 1
   Put_Line ("TEST 1 - Initialization State");
   Initialize (Sys, 1);
   Put_Line ("  1.1 Assert initial token holder (1) has token");
   Assert (Has_Token (Sys, 1), "Node 1 should have token");
   Put_Line ("  1.2 Assert non-holders (2) do not have token");
   Assert (not Has_Token (Sys, 2), "Node 2 should not have token");
   Put_Line ("  1.3 Assert all nodes point to Initial Holder as Owner");
   Assert (Sys.Nodes(3).Owner = 1, "Node 3 owner should be 1");

   -- TEST 2
   Put_Line ("TEST 2 - Immediate CS Entry");
   Put_Line ("  2.1 Assert Node 1 enters CS without messages");
   Request_Critical_Section (Sys, 1);
   Assert (Is_Requesting (Sys, 1), "Node 1 should be requesting");
   Assert (Pending_Messages (Sys) = 0, "No messages should be generated");

   -- TEST 3
   Put_Line ("TEST 3 - CS Release by Token Holder");
   Put_Line ("  3.1 Assert Node 1 retains token if no queue");
   Release_Critical_Section (Sys, 1);
   Assert (not Is_Requesting (Sys, 1), "Node 1 should not be requesting");
   Assert (Has_Token (Sys, 1), "Node 1 should retain token");
   Assert (Pending_Messages (Sys) = 0, "No token messages generated");

   -- TEST 4
   Put_Line ("TEST 4 - CS Request Generates Network Traffic");
   Put_Line ("  4.1 Assert Node 2 request generates Request message");
   Request_Critical_Section (Sys, 2);
   Assert (Pending_Messages (Sys) = 1, "One request message expected");
   Put_Line ("  4.2 Assert Node 2 becomes its own owner (root of sub-tree)");
   Assert (Sys.Nodes(2).Owner = 2, "Node 2 should update owner to itself");

   -- TEST 5
   Put_Line ("TEST 5 - Root Message Processing (Not in CS)");
   Put_Line ("  5.1 Assert Root (Node 1) sends token immediately if not in CS");
   Process_Next_Message (Sys, Success);
   Assert (Success, "Message should be processed");
   Assert (not Has_Token (Sys, 1), "Node 1 gave up token");
   Put_Line ("  5.2 Assert Token message is in queue");
   Assert (Pending_Messages (Sys) = 1, "Token message expected in queue");

   -- TEST 6
   Put_Line ("TEST 6 - Token Message Delivery");
   Put_Line ("  6.1 Assert Node 2 receives token");
   Process_Next_Message (Sys, Success);
   Assert (Has_Token (Sys, 2), "Node 2 should have the token now");

   -- TEST 7
   Put_Line ("TEST 7 - Root Message Processing (While in CS)");
   Put_Line ("  7.1 Node 2 in CS, Node 3 requests token");
   Request_Critical_Section (Sys, 3);
   Process_Next_Message (Sys, Success);
   Process_Next_Message (Sys, Success);

   Put_Line ("  7.2 Assert Node 2 queues Node 3 (Next_Node updated)");
   Assert (Sys.Nodes(2).Next_Node = 3, "Node 2 should set Next_Node to 3");
   Assert (Has_Token (Sys, 2), "Node 2 still has token");

   -- TEST 8
   Put_Line ("TEST 8 - Deferred Token Passing");
   Put_Line ("  8.1 Assert Node 2 passes token to Node 3 upon release");
   Release_Critical_Section (Sys, 2);
   Assert (not Has_Token (Sys, 2), "Node 2 released token");
   Assert (Pending_Messages (Sys) = 1, "Token message generated");

   -- TEST 9
   Put_Line ("TEST 9 - Intermediate Node Forwarding");
   Put_Line ("  9.1 Node 4 requests token");
   Process_All_Messages (Sys); -- Node 3 gets the token from 2 releasing it
   Request_Critical_Section (Sys, 4);
   Put_Line ("  9.2 Assert Node 1 forwards request to Node 3 (its current owner)");
   Process_Next_Message (Sys, Success); -- Node 1 gets request from 4, forwards to 3
   Assert (Pending_Messages (Sys) = 1, "Forwarded request expected");
   Assert (Sys.Nodes(1).Owner = 4, "Node 1 owner updated to 4");

   -- TEST 10
   Put_Line ("TEST 10 - Multiple Forwarding Chain Verification");
   Put_Line ("  10.1 Assert Request arrives at Node 3");
   Process_Next_Message (Sys, Success); -- Node 3 gets request from 4 (via 1)
   Assert (Pending_Messages (Sys) = 0, "Request handled by Node 3");
   Assert (Sys.Nodes(3).Owner = 4, "Node 3 owner updated to 4");

   -- TEST 11
   Put_Line ("TEST 11 - Error Handling: Release Without Token");
   Put_Line ("  11.1 Assert Exception when releasing CS improperly");
   begin
      Release_Critical_Section (Sys, 5);
      Assert (False, "Should have raised exception");
   exception
      when Critical_Section_Violation =>
         Put_Line ("      PASS");
   end;

   -- TEST 12
   Put_Line ("TEST 12 - Error Handling: Process Empty Queue");
   Put_Line ("  12.1 Assert Success flag is False for empty queue");
   Process_All_Messages (Sys); -- Clear everything
   Process_Next_Message (Sys, Success);
   Assert (not Success, "Success should be False");

   -- TEST 13
   Put_Line ("TEST 13 - Network Saturation Edge Case");
   Put_Line ("  13.1 Assert all nodes requesting simultaneously forms linear queue");
   Initialize (Sys, 1);
   Request_Critical_Section (Sys, 1); -- 1 enters CS immediately and holds token
   Request_Critical_Section (Sys, 2);
   Request_Critical_Section (Sys, 3);
   Request_Critical_Section (Sys, 4);
   Request_Critical_Section (Sys, 5);
   Process_All_Messages (Sys);
   Put_Line ("  13.2 Assert token passes safely down the chained pointer queue");
   Assert (Has_Token(Sys, 1), "1 has it initially");
   Release_Critical_Section (Sys, 1);
   Process_All_Messages (Sys);
   Assert (Has_Token(Sys, 2), "2 gets it");
   Release_Critical_Section (Sys, 2);
   Process_All_Messages (Sys);
   Assert (Has_Token(Sys, 3), "3 gets it");
   Release_Critical_Section (Sys, 3);
   Process_All_Messages (Sys);
   Assert (Has_Token(Sys, 4), "4 gets it");

   Put_Line ("All 13+ assumptions disproved. Tests Passed.");
end Tests;
