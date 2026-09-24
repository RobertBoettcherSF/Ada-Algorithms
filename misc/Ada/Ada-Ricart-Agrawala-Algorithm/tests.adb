-- Ricart-Agrawala Algorithm Verification & Validation Test Suite
-- 
-- This test suite validates the correctness of the Ricart-Agrawala mutual exclusion
-- algorithm implementation through 19 assertions across 13 test categories.
-- 
-- Test Philosophy:
--   - Assumes the implementation is broken (pessimistic approach)
--   - Each test only PASSes when the assumption is provably disproved
--   - Uses Ada's pragma Assert for runtime verification
--
-- Test Categories:
--   1. Initialization State - Verify safe default state
--   2. Request Execution Boundary - Verify state transitions
--   3. Outgoing Broadcast Consistency - Verify request messaging
--   4. Receiving Requests (Idle/Released) - Verify reply behavior when released
--   5. Receiving Requests (Held/Executing) - Verify deferral when in CS
--   6. Safe Lock Release - Verify release and deferred reply handling
--   7. Time-based Tie Resolution - Verify Lamport clock priority
--   8. Spatial Tie Resolution - Verify Node ID tie-breaking
--   9-11. Roucairol-Carvalho Variant - Verify permission caching optimization
--   12. Mutual Exclusion Guarantee - Verify CS entry preconditions
--   13. Critical Section Entry - Verify state locking on entry

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ricart_Agrawala; use Ricart_Agrawala;

procedure Tests is
   N1, N2   : RA_Node;
   Requests : Node_Set;
   Replies  : Node_Set;
   Send_Rep : Boolean;
begin
   Put_Line ("=====================================================");
   Put_Line ("Ricart-Agrawala V&V Test Execution");
   Put_Line ("=====================================================");

   -- TEST 1
   Put_Line ("TEST 1 - Initialization State");
   Put_Line ("  1.1 Assert state is strictly Released");
   Initialize (N1, 1, Ricart_Agrawala.Standard);
   Assert (Get_State (N1) = Released, "Node should be released");
   Put_Line ("      PASS");
   Put_Line ("  1.2 Assert internal sequence clocks default to 0");
   Assert (Get_Seq_Num (N1) = 0, "Sequence number should be 0");
   Put_Line ("      PASS");

   -- TEST 2
   Put_Line ("TEST 2 - Request Execution Boundary");
   Put_Line ("  2.1 Assert state escalates to Wanted");
   Request_Critical_Section (N1, Requests);
   Assert (Get_State (N1) = Wanted, "State not Wanted after request");
   Put_Line ("      PASS");
   Put_Line ("  2.2 Assert Lamport clock sequence increments");
   Assert (Get_Seq_Num (N1) = 1, "Sequence number did not increment");
   Put_Line ("      PASS");

   -- TEST 3
   Put_Line ("TEST 3 - Outgoing Broadcast Consistency");
   Put_Line ("  3.1 Assert broadcast masks N-1 network connections");
   Assert (Requests (2) = True and Requests (Node_ID(Max_Nodes)) = True, "Requests missed nodes");
   Put_Line ("      PASS");
   Put_Line ("  3.2 Assert reflexive isolation (no self-requests)");
   Assert (Requests (1) = False, "Sent request to self");
   Put_Line ("      PASS");

   -- TEST 4
   Put_Line ("TEST 4 - Receiving Requests (Idle/Released)");
   Put_Line ("  4.1 Assert immediate reply constraint when Released");
   Initialize (N2, 2, Ricart_Agrawala.Standard);
   Receive_Request (N2, 1, 1, Send_Rep);
   Assert (Send_Rep = True, "Did not reply while Released");
   Put_Line ("      PASS");

   -- TEST 5
   Put_Line ("TEST 5 - Receiving Requests (Held/Executing)");
   Put_Line ("  5.1 Assert forced deferral when lock is currently Held");
   Request_Critical_Section (N2, Requests);
   for I in Node_ID loop
      if I /= 2 then Receive_Reply (N2, I); end if;
   end loop;
   Enter_CS (N2);
   Receive_Request (N2, 1, 5, Send_Rep);
   Assert (Send_Rep = False, "Failed to defer lock-breaking request");
   Put_Line ("      PASS");

   -- TEST 6
   Put_Line ("TEST 6 - Safe Lock Release");
   Put_Line ("  6.1 Assert deferred backlog generates outgoing replies");
   Release_Critical_Section (N2, Replies);
   Assert (Replies (1) = True, "Deferred node abandoned");
   Put_Line ("      PASS");
   Put_Line ("  6.2 Assert exact reversion to Released state");
   Assert (Get_State (N2) = Released, "State corrupted after release");
   Put_Line ("      PASS");

   -- TEST 7
   Put_Line ("TEST 7 - Time-based Tie Resolution");
   Put_Line ("  7.1 Assert older request (lower seq) defeats newer request");
   Initialize (N1, 1, Ricart_Agrawala.Standard); Initialize (N2, 2, Ricart_Agrawala.Standard);
   Request_Critical_Section (N1, Requests); -- Seq 1
   Receive_Request (N2, 1, 1, Send_Rep); 
   Request_Critical_Section (N2, Requests); -- Seq 2
   Receive_Request (N1, 2, 2, Send_Rep);    -- N1 evaluates N2's req
   Assert (Send_Rep = False, "Failed to prioritize older sequence");
   Put_Line ("      PASS");

   -- TEST 8
   Put_Line ("TEST 8 - Spatial Tie Resolution (Same Sequence)");
   Put_Line ("  8.1 Assert lower Node ID breaks tie and forces reply from higher ID");
   Initialize (N1, 1, Ricart_Agrawala.Standard); Initialize (N2, 2, Ricart_Agrawala.Standard);
   Request_Critical_Section (N1, Requests); Request_Critical_Section (N2, Requests);
   Receive_Request (N2, 1, 1, Send_Rep); 
   Assert (Send_Rep = True, "Higher ID failed to yield to lower ID");
   Put_Line ("      PASS");
   Put_Line ("  8.2 Assert lower Node ID protects lock and defers higher ID");
   Receive_Request (N1, 2, 1, Send_Rep);
   Assert (Send_Rep = False, "Lower ID failed to claim tie victory");
   Put_Line ("      PASS");

   -- TEST 9
   Put_Line ("TEST 9 - Roucairol-Carvalho First Run Isolation");
   Put_Line ("  9.1 Assert initial run requires standard N-1 requests");
   Initialize (N1, 1, Ricart_Agrawala.Roucairol_Carvalho);
   Request_Critical_Section (N1, Requests);
   Assert (Requests (2) = True, "Variant failed to request initially");
   Put_Line ("      PASS");

   -- TEST 10
   Put_Line ("TEST 10 - Roucairol-Carvalho Implicit Permissions");
   Put_Line ("  10.1 Assert cached permissions prevent redundant network calls");
   Receive_Reply (N1, 2);
   Release_Critical_Section (N1, Replies);
   Request_Critical_Section (N1, Requests);
   Assert (Requests (2) = False, "Variant made redundant request");
   Put_Line ("      PASS");

   -- TEST 11
   Put_Line ("TEST 11 - Roucairol-Carvalho Permission Yielding");
   Put_Line ("  11.1 Assert explicit replies strip implicit permission caches");
   Receive_Request (N1, 2, 5, Send_Rep);
   Request_Critical_Section (N1, Requests);
   Assert (Requests (2) = True, "Variant unlawfully kept permission after yielding");
   Put_Line ("      PASS");

   -- TEST 12
   Put_Line ("TEST 12 - Mutual Exclusion Guarantee Pre-conditions");
   Put_Line ("  12.1 Assert denial of CS if N-1 replies are incomplete");
   Initialize (N1, 1, Ricart_Agrawala.Standard);
   Request_Critical_Section (N1, Requests);
   Receive_Reply (N1, 2); 
   Assert (Can_Enter_CS (N1) = False, "CS barrier bypassed");
   Put_Line ("      PASS");
   Put_Line ("  12.2 Assert clearance to CS exactly when replies matched");
   for I in 3 .. Node_ID(Max_Nodes) loop Receive_Reply (N1, I); end loop;
   Assert (Can_Enter_CS (N1) = True, "CS barrier failed to lift");
   Put_Line ("      PASS");

   -- TEST 13
   Put_Line ("TEST 13 - Critical Section Entry Execution");
   Put_Line ("  13.1 Assert node locks state variables safely on Entry");
   Enter_CS (N1);
   Assert (Get_State (N1) = Held, "Lock state enforcement failed");
   Put_Line ("      PASS");

   Put_Line ("=====================================================");
   Put_Line ("All 19 assertions across 13 tests passed. V&V Complete.");
end Tests;
