-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Raymonds_Algorithm; use Raymonds_Algorithm;

procedure Tests is
   Test_Node : Node_State;
   Msgs      : Message_Buffer;
   Tmp_Id    : Node_Id;
begin
   Put_Line ("===============================================");
   Put_Line ("    RAYMOND'S ALGORITHM V&V TEST SUITE");
   Put_Line (" Philosophy: Assume code is functionally broken");
   Put_Line (" PASS = Assumption disproven by assertions");
   Put_Line ("===============================================");

   -- ---------------------------------------------------------
   Put_Line ("TEST 1 - Initialization Logic");
   Put_Line ("  1.1 [Assertion: Node fails to retain valid ID]");
   Initialize (Test_Node, 42, 99);
   Assert (Test_Node.Id = 42, "Initialization failed ID binding");
   Put_Line ("      PASS: Node correctly retains ID.");
   
   Put_Line ("  1.2 [Assertion: Node misconfigures Holder address]");
   Assert (Test_Node.Holder = 99, "Initialization failed Holder binding");
   Put_Line ("      PASS: Node correctly sets Holder.");

   Put_Line ("  1.3 [Assertion: Node defaults to unsafe CS usage]");
   Assert (Test_Node.Using_CS = False, "Node initialized in critical section");
   Put_Line ("      PASS: Node is out of CS on start.");

   -- ---------------------------------------------------------
   Put_Line ("TEST 2 - FIFO Queue Reliability");
   Put_Line ("  2.1 [Assertion: Queue fails to increment count on Enqueue]");
   Enqueue (Test_Node.Req_Q, 10);
   Assert (Test_Node.Req_Q.Count = 1, "Queue Enqueue count invalid");
   Put_Line ("      PASS: Queue count behaves predictably.");

   Put_Line ("  2.2 [Assertion: Queue scrambles FIFO Dequeue order]");
   Dequeue (Test_Node.Req_Q, Tmp_Id);
   Assert (Tmp_Id = 10 and Test_Node.Req_Q.Count = 0, "Queue Dequeue returned wrong element");
   Put_Line ("      PASS: Strict FIFO order maintained.");

   Put_Line ("  2.3 [Assertion: Dequeuing empty queue causes memory corruption]");
   begin
      Dequeue (Test_Node.Req_Q, Tmp_Id);
      Assert (False, "Should have raised exception!");
   exception
      when Queue_Underflow =>
         Put_Line ("      PASS: Caught intentional Queue_Underflow exception.");
   end;

   -- ---------------------------------------------------------
   Put_Line ("TEST 3 - Token Holder Local Request");
   Initialize (Test_Node, Id => 1, Holder => 1); -- Holds Token
   Msgs.Count := 0;
   Put_Line ("  3.1 [Assertion: Token Holder fails to assign token to itself]");
   Request_CS (Test_Node, Msgs);
   Assert (Test_Node.Using_CS = True, "Root node failed to enter CS instantly");
   Put_Line ("      PASS: Token holder skips network, grabs CS.");

   Put_Line ("  3.2 [Assertion: Token Holder spams network asking for own token]");
   Assert (Msgs.Count = 0, "Root node erroneously dispatched messages");
   Put_Line ("      PASS: No phantom messages emitted.");

   -- ---------------------------------------------------------
   Put_Line ("TEST 4 - Leaf Node Network Request");
   Initialize (Test_Node, Id => 2, Holder => 1); -- Leaf Node
   Msgs.Count := 0;
   Put_Line ("  4.1 [Assertion: Leaf forgets to enqueue its own request]");
   Request_CS (Test_Node, Msgs);
   Assert (Test_Node.Req_Q.Count = 1, "Self not added to queue");
   Put_Line ("      PASS: Leaf request properly enqueued.");

   Put_Line ("  4.2 [Assertion: Leaf drops the Request Message]");
   Assert (Msgs.Count = 1 and then Msgs.Messages(1).Kind = Request_Msg, "Message missing or invalid");
   Put_Line ("      PASS: Request message accurately structured and emitted.");

   Put_Line ("  4.3 [Assertion: Leaf forgets 'Asked' state, risking network flood]");
   Assert (Test_Node.Asked = True, "Asked flag not flipped");
   Put_Line ("      PASS: Asked state prevents duplicate requests.");

   -- ---------------------------------------------------------
   Put_Line ("TEST 5 - Standard Message Reception");
   Initialize (Test_Node, Id => 3, Holder => 1);
   Msgs.Count := 0;
   Put_Line ("  5.1 [Assertion: Node ignores incoming requests]");
   Receive_Request (Test_Node, From => 4, Out_Msgs => Msgs);
   Assert (Test_Node.Req_Q.Count = 1, "Remote request dropped");
   Put_Line ("      PASS: Request safely enqueued.");

   Put_Line ("  5.2 [Assertion: Node drops routing responsibility]");
   Assert (Msgs.Count = 1, "Failed to route request upward");
   Put_Line ("      PASS: Node routed Request upward.");

   -- ---------------------------------------------------------
   Put_Line ("TEST 6 - Greedy Variant Network Optimization");
   Initialize (Test_Node, Id => 5, Holder => 1);
   Msgs.Count := 0;
   Enqueue (Test_Node.Req_Q, 99); -- Pre-load request from Node 99
   
   Put_Line ("  6.1 [Assertion: Greedy algorithm fails to drop duplicate requests]");
   Greedy_Receive_Request (Test_Node, From => 99, Out_Msgs => Msgs);
   -- If broken, Queue Count would be 2.
   Assert (Test_Node.Req_Q.Count = 1, "Duplicate request was not suppressed!");
   Put_Line ("      PASS: Variant correctly suppressed duplicate network request.");

   Put_Line ("===============================================");
   Put_Line (" ALL V&V ASSUMPTIONS DISPROVEN - SYSTEM STABLE");
end Tests;
