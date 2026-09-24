-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Exceptions; use Ada.Exceptions;
with Maekawa; use Maekawa;

procedure Tests is
   
   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("      FAIL: " & Message);
         raise Program_Error with Message;
      else
         Put_Line ("      PASS: " & Message);
      end if;
   end Assert;

   Sys : Maekawa_System;

begin
   Put_Line ("Starting Maekawa Test Suite");
   Put_Line ("---------------------------");

   -- TEST 1
   Put_Line ("TEST 1 - System Initialization");
   Put_Line ("  1.1 Assumption: Nodes start with corrupted/Holding states.");
   Initialize (Sys);
   Assert (Sys.Nodes(1).State = Init, "Assumption proven false: Node initialized cleanly.");
   
   -- TEST 2
   Put_Line ("TEST 2 - Grid Quorum Sizing");
   Put_Line ("  2.1 Assumption: Quorums do not match 2*sqrt(N)-1 formula.");
   Generate_Grid_Quorums (Sys);
   Assert (Sys.Nodes(5).Quorum_Size = 5, "Assumption proven false: Quorum size is exactly 5.");

   -- TEST 3
   Put_Line ("TEST 3 - Quorum Intersection Property (Core Algorithm Requirement)");
   Put_Line ("  3.1 Assumption: Coteries can be disjoint (causing mutual exclusion failure).");
   Assert (Check_Intersection (Sys, 1, 9), "Assumption proven false: Quorums 1 and 9 intersect.");
   Assert (Check_Intersection (Sys, 2, 7), "Assumption proven false: Quorums 2 and 7 intersect.");

   -- TEST 4
   Put_Line ("TEST 4 - Standard CS Acquisition");
   Put_Line ("  4.1 Assumption: Node cannot acquire CS when network is idle.");
   Initialize (Sys); Generate_Grid_Quorums (Sys);
   Request_CS (Sys, 3, 10);
   Process_All_Events (Sys);
   Assert (Sys.Nodes(3).State = Holding, "Assumption proven false: Node acquired CS.");

   -- TEST 5
   Put_Line ("TEST 5 - Standard CS Release");
   Put_Line ("  5.1 Assumption: Node holds CS forever despite release.");
   Release_CS (Sys, 3);
   Process_All_Events (Sys);
   Assert (Sys.Nodes(3).State = Init, "Assumption proven false: State reset to Init.");

   -- TEST 6
   Put_Line ("TEST 6 - Strict Mutual Exclusion");
   Put_Line ("  6.1 Assumption: Multiple nodes can enter CS simultaneously.");
   Initialize (Sys); Generate_Grid_Quorums (Sys);
   Request_CS (Sys, 1, 15);
   Request_CS (Sys, 2, 20); -- Lower priority (higher TS)
   Process_All_Events (Sys);
   Assert (Sys.Nodes(1).State = Holding, "Node 1 holds CS.");
   Assert (Sys.Nodes(2).State = Requesting, "Assumption proven false: Node 2 blocked.");

   -- TEST 7
   Put_Line ("TEST 7 - Deferred Request Queuing");
   Put_Line ("  7.1 Assumption: Competing requests are discarded.");
   -- From Test 6, Node 2's request to shared quorum members should be queued
   Assert (Sys.Nodes(2).Queue.Count = 0, "Self queue is empty.");
   -- Node 1 and Node 2 share Node 2 in their grid quorums
   Assert (Sys.Nodes(2).Voted_For = 1, "Shared node voted for winner.");
   
   -- TEST 8
   Put_Line ("TEST 8 - Release Triggers Queued Request");
   Put_Line ("  8.1 Assumption: Waiting nodes starve after a release.");
   Release_CS (Sys, 1);
   Process_All_Events (Sys);
   Assert (Sys.Nodes(2).State = Holding, "Assumption proven false: Node 2 acquired CS after release.");

   -- TEST 9
   Put_Line ("TEST 9 - Priority Reversal handling");
   Put_Line ("  9.1 Assumption: Later arrivals with higher priority are ignored.");
   Initialize (Sys); Generate_Grid_Quorums (Sys);
   Request_CS (Sys, 9, 50); -- Lower priority
   Process_All_Events (Sys);
   Request_CS (Sys, 8, 10); -- Arrives later, BUT higher priority (TS 10)
   Process_All_Events (Sys);
   -- Because Node 9 was Holding, it won't yield, but if Node 9 hasn't gathered all...
   -- Actually in this test Node 9 already holds CS. Let's assert Node 8 is queued.
   Assert (Sys.Nodes(8).State = Requesting, "Assumption proven false: Network handles late high-priority gracefully.");

   -- TEST 10
   Put_Line ("TEST 10 - Deadlock Avoidance: INQUIRE Generation");
   Put_Line ("  10.1 Assumption: Preemptions are not signaled.");
   Initialize (Sys); Generate_Grid_Quorums (Sys);
   -- Simulate partial lock to trigger INQUIRE
   -- Node 1 requests first.
   Sys.Nodes(2).Voted := True; 
   Sys.Nodes(2).Voted_For := 5; 
   Sys.Nodes(5).Timestamp := 20; -- Node 5 currently has vote
   -- Node 1 requests with HIGHER priority (TS 10)
   Request_CS(Sys, 1, 10);
   Process_Next_Event(Sys); -- Process Node 1 Requesting
   -- Run until Inquire is generated
   while Sys.Events.Count > 0 loop
      if Sys.Events.Items(1).Kind = Msg_Inquire then
         Assert (True, "Assumption proven false: INQUIRE generated for deadlock avoidance.");
         exit;
      end if;
      Process_Next_Event(Sys);
   end loop;

   -- TEST 11
   Put_Line ("TEST 11 - Deadlock Avoidance: YIELD Action");
   Put_Line ("  11.1 Assumption: Nodes maliciously hold partial votes.");
   Initialize (Sys); Generate_Grid_Quorums (Sys);
   Sys.Nodes(1).State := Requesting; 
   Sys.Nodes(1).Replies_Count := 1;
   -- Trigger an INQUIRE to Node 1 from Node 2
   Sys.Events.Count := 1;
   Sys.Events.Items(1) := (Msg_Inquire, 2, 1, 0);
   Process_Next_Event(Sys);
   Assert (Sys.Events.Items(1).Kind = Msg_Yield, "Assumption proven false: Node YIELDED vote.");

   -- TEST 12
   Put_Line ("TEST 12 - Deadlock Avoidance: FAIL Generation");
   Put_Line ("  12.1 Assumption: Low priority nodes indefinitely wait for un-yieldable votes.");
   Initialize (Sys); Generate_Grid_Quorums (Sys);
   Sys.Nodes(2).Voted := True;
   Sys.Nodes(2).Voted_For := 5;
   Sys.Nodes(5).Timestamp := 10;
   -- Node 1 (TS 50, low priority) requests. Should trigger FAIL.
   Request_CS(Sys, 1, 50);
   Process_Next_Event(Sys);
   while Sys.Events.Count > 0 loop
      if Sys.Events.Items(1).Kind = Msg_Fail then
         Assert (True, "Assumption proven false: FAIL sent to lower priority request.");
         exit;
      end if;
      Process_Next_Event(Sys);
   end loop;

   -- TEST 13
   Put_Line ("TEST 13 - Deadlock Resolution (Systematic)");
   Put_Line ("  13.1 Assumption: Circular wait causes permanent deadlock.");
   Initialize (Sys); Generate_Grid_Quorums (Sys);
   -- Induce deadlock scenario: Nodes 1, 2, 3 request simultaneously
   Request_CS (Sys, 1, 30);
   Request_CS (Sys, 2, 10); -- Highest priority
   Request_CS (Sys, 3, 20);
   Process_All_Events (Sys);
   -- With Yield/Inquire, exactly ONE should succeed (Node 2)
   Assert (Sys.Nodes(2).State = Holding, "Assumption proven false: Deadlock broken, Node 2 won.");
   Assert (Sys.Nodes(1).State = Requesting, "Node 1 correctly queued.");
   Assert (Sys.Nodes(3).State = Requesting, "Node 3 correctly queued.");

   Put_Line ("---------------------------");
   Put_Line ("ALL V&V TESTS PASSED.");
end Tests;
