with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Vector_Clocks; use Vector_Clocks;

procedure Tests is
   P1, P2 : Process_Node (2);
   Msg_Payload : Vector_Clock (1 .. 2);
   Expected    : Vector_Clock (1 .. 2);
begin
   Put_Line ("Running Pessimistic Assuming Test Suite (V&V)...");
   Put_Line ("==================================================");

   -- TEST 1 - Initialization Correctness
   Put_Line ("TEST 1 - Initialization State");
   Put_Line ("  1.1 Assert Setup correctly sets ID");
   Put_Line ("  1.2 Assert Setup zeros out all clock elements");
   Expected := (0, 0);
   Setup (P1, 1);
   Assert (P1.ID = 1, "ID was not set correctly");
   Assert (P1.Clock = Expected, "Clock was not zeroed");
   Put_Line ("      PASS");

   -- TEST 2 - Setup Boundary/Exception
   Put_Line ("TEST 2 - Invalid ID Assignment");
   Put_Line ("  2.1 Assert Setup rejects ID > Num_Processes");
   begin
      Setup (P1, 3);
      Assert (False, "Should have raised Invalid_Process_ID");
   exception
      when Invalid_Process_ID =>
         Put_Line ("      PASS");
   end;

   -- TEST 3 - Internal Event Logic
   Put_Line ("TEST 3 - Internal Event");
   Put_Line ("  3.1 Assert process only increments its own index");
   Setup (P1, 1);
   Internal_Event (P1);
   Expected := (1, 0);
   Assert (P1.Clock = Expected, "Internal event incremented wrong index");
   Put_Line ("      PASS");

   -- TEST 4 - Send Message Logic
   Put_Line ("TEST 4 - Send Message");
   Put_Line ("  4.1 Assert send event increments local clock");
   Put_Line ("  4.2 Assert send returns exact copy of updated clock");
   Setup (P2, 2);
   Msg_Payload := Send_Message (P2);
   Expected := (0, 1);
   Assert (Msg_Payload = Expected, "Payload vector is incorrect");
   Assert (P2.Clock = Msg_Payload, "Local clock mismatch after send");
   Put_Line ("      PASS");

   -- TEST 5 - Receive Message Logic
   Put_Line ("TEST 5 - Receive Message");
   Put_Line ("  5.1 Assert receive takes maximum of both vectors");
   Put_Line ("  5.2 Assert receive increments receiving process's index");
   Setup (P1, 1);
   P1.Clock := (1, 0); -- Manual state inject for test
   Msg_Payload := (0, 2); -- Simulated incoming payload from P2
   Receive_Message (P1, Msg_Payload);
   -- Max of (1,0) and (0,2) is (1,2). P1 ID=1 increments -> (2,2)
   Expected := (2, 2);
   Assert (P1.Clock = Expected, "Receive merge and increment failed");
   Put_Line ("      PASS");

   -- TEST 6 - Ordering: Less Than or Equal (<=) True
   Put_Line ("TEST 6 - Causal Ordering (<=)");
   Put_Line ("  6.1 Assert <= is True when completely identical");
   Put_Line ("  6.2 Assert <= is True when strictly less");
   Assert (Vector_Clock'(1, 1) <= Vector_Clock'(1, 1), "<= failed on identical");
   Assert (Vector_Clock'(1, 1) <= Vector_Clock'(1, 2), "<= failed on strictly less");
   Put_Line ("      PASS");

   -- TEST 7 - Ordering: Less Than or Equal (<=) False
   Put_Line ("TEST 7 - Causal Ordering (<=) Negative");
   Put_Line ("  7.1 Assert <= is False when any element is greater");
   Assert (not (Vector_Clock'(2, 1) <= Vector_Clock'(1, 2)), "<= passed incorrectly");
   Put_Line ("      PASS");

   -- TEST 8 - Happens-Before (<)
   Put_Line ("TEST 8 - Happens-Before (<) Logic");
   Put_Line ("  8.1 Assert < is True when logically prior");
   Put_Line ("  8.2 Assert < is False for identical vectors");
   Assert (Vector_Clock'(1, 1) < Vector_Clock'(1, 2), "Happens-before failed");
   Assert (not (Vector_Clock'(1, 1) < Vector_Clock'(1, 1)), "Happens-before passed on identical");
   Put_Line ("      PASS");

   -- TEST 9 - Concurrency (||) True
   Put_Line ("TEST 9 - Concurrency Detection (True)");
   Put_Line ("  9.1 Assert Are_Concurrent is True when vectors have mixed greater/lesser values");
   Assert (Are_Concurrent (Vector_Clock'(2, 1), Vector_Clock'(1, 2)), "Concurrency not detected");
   Put_Line ("      PASS");

   -- TEST 10 - Concurrency (||) False
   Put_Line ("TEST 10 - Concurrency Detection (False)");
   Put_Line ("  10.1 Assert Are_Concurrent is False when causal relationship exists");
   Assert (not Are_Concurrent (Vector_Clock'(1, 1), Vector_Clock'(1, 2)), "False positive concurrency");
   Put_Line ("      PASS");

   -- TEST 11 - Exception: Receive Mismatch
   Put_Line ("TEST 11 - Dimensions Exception (Receive)");
   Put_Line ("  11.1 Assert Mismatched_Dimensions raised when receiving incompatible clock");
   begin
      Setup (P1, 1);
      Receive_Message (P1, Vector_Clock'(1, 1, 1));
      Assert (False, "Accepted mismatched payload");
   exception
      when Mismatched_Dimensions => Put_Line ("      PASS");
   end;

   -- TEST 12 - Exception: Comparison Mismatch
   Put_Line ("TEST 12 - Dimensions Exception (Compare)");
   Put_Line ("  12.1 Assert Mismatched_Dimensions raised during <=");
   begin
      if Vector_Clock'(1, 1) <= Vector_Clock'(1, 1, 1) then null; end if;
      Assert (False, "Completed mismatched comparison");
   exception
      when Mismatched_Dimensions => Put_Line ("      PASS");
   end;

   -- TEST 13 - Complete Integration Sequence
   Put_Line ("TEST 13 - Full Sequence Integration");
   Put_Line ("  13.1 Assert complex P1->P2->P1 exchange ends in correct state");
   declare
      NodeA, NodeB : Process_Node (2);
      Msg : Vector_Clock (1 .. 2);
   begin
      Setup (NodeA, 1);
      Setup (NodeB, 2);
      -- A sends to B
      Msg := Send_Message (NodeA);           -- NodeA: (1,0)
      Receive_Message (NodeB, Msg);          -- NodeB: (1,1)
      -- B sends to A
      Msg := Send_Message (NodeB);           -- NodeB: (1,2)
      Receive_Message (NodeA, Msg);          -- NodeA: (2,2)
      Assert (NodeA.Clock = Vector_Clock'(2, 2) and NodeB.Clock = Vector_Clock'(1, 2),
              "Integration states corrupted");
      Put_Line ("      PASS");
   end;

   Put_Line ("==================================================");
   Put_Line ("ALL 13+ TESTS PASSED SUCESSFULLY.");
end Tests;
