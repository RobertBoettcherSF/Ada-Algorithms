-- tests.adb
pragma Assertion_Policy (Check);

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Lamport_Ordering; use Lamport_Ordering;

procedure Tests is
   P1, P2 : Process_State;
   Msg    : Message;
begin
   Put_Line ("Starting V&V Lamport Ordering Test Suite...");
   Put_Line ("===========================================");

   -- TEST 1 - Initialization
   Put_Line ("TEST 1 - Initialization Normal Case");
   Put_Line ("  1.1 Assert process initializes with correct ID and Time");
   Initialize (P1, ID => 1, Initial_Time => 5);
   Assert (P1.ID = 1 and P1.Clock = 5, "Initialization failed");
   Put_Line ("      PASS");

   -- TEST 2 - Local Event Increment
   Put_Line ("TEST 2 - Local Event Increment");
   Put_Line ("  2.1 Assert local event increments clock by 1");
   Initialize (P1, ID => 1, Initial_Time => 0);
   Local_Event (P1);
   Assert (P1.Clock = 1, "Local event clock mismatch");
   Put_Line ("      PASS");

   -- TEST 3 - Successive Local Events
   Put_Line ("TEST 3 - Successive Local Events");
   Put_Line ("  3.1 Assert multiple local events sum correctly");
   Local_Event (P1);
   Local_Event (P1);
   Assert (P1.Clock = 3, "Successive increments failed");
   Put_Line ("      PASS");

   -- TEST 4 - Send Event Timestamp Generation
   Put_Line ("TEST 4 - Send Event Generation");
   Put_Line ("  4.1 Assert send event increments local clock and tags message");
   Initialize (P1, ID => 2, Initial_Time => 10);
   Msg := Send_Event (P1);
   Assert (P1.Clock = 11, "Sender clock not incremented");
   Assert (Msg.Sender = 2 and Msg.Timestamp = 11, "Message payload incorrect");
   Put_Line ("      PASS");

   -- TEST 5 - Receive Event (Message Time < Local Time)
   Put_Line ("TEST 5 - Receive Event with Older Timestamp");
   Put_Line ("  5.1 Assert clock increments local time, ignoring older msg time");
   Initialize (P2, ID => 3, Initial_Time => 20);
   Msg := (Sender => 1, Timestamp => 5);
   Receive_Event (P2, Msg);
   Assert (P2.Clock = 21, "Clock synchronization failed on older msg");
   Put_Line ("      PASS");

   -- TEST 6 - Receive Event (Message Time > Local Time)
   Put_Line ("TEST 6 - Receive Event with Newer Timestamp");
   Put_Line ("  6.1 Assert clock jumps to max(local, msg) + 1");
   Initialize (P2, ID => 3, Initial_Time => 10);
   Msg := (Sender => 1, Timestamp => 25);
   Receive_Event (P2, Msg);
   Assert (P2.Clock = 26, "Clock synchronization failed on newer msg");
   Put_Line ("      PASS");

   -- TEST 7 - Receive Event (Message Time = Local Time)
   Put_Line ("TEST 7 - Receive Event with Equal Timestamp");
   Put_Line ("  7.1 Assert clock simply increments normally");
   Initialize (P2, ID => 3, Initial_Time => 15);
   Msg := (Sender => 1, Timestamp => 15);
   Receive_Event (P2, Msg);
   Assert (P2.Clock = 16, "Clock sync failed on equal timestamps");
   Put_Line ("      PASS");

   -- TEST 8 - Partial Ordering: Lower time is before
   Put_Line ("TEST 8 - Happens-Before: Standard Comparison");
   Put_Line ("  8.1 Assert smaller logical clock happens before larger");
   Assert (Happens_Before (Clock_A => 5, ID_A => 1, Clock_B => 10, ID_B => 2) = True, "Standard partial order failed");
   Put_Line ("      PASS");

   -- TEST 9 - Partial Ordering: Higher time is after
   Put_Line ("TEST 9 - Happens-Before: Standard Comparison Reversed");
   Put_Line ("  9.1 Assert larger logical clock does not happen before smaller");
   Assert (Happens_Before (Clock_A => 15, ID_A => 1, Clock_B => 10, ID_B => 2) = False, "Reversed partial order failed");
   Put_Line ("      PASS");

   -- TEST 10 - Total Ordering: Tie-Breaker (Lower ID wins)
   Put_Line ("TEST 10 - Total Ordering: Identical Clocks, A < B");
   Put_Line ("  10.1 Assert tie-breaker resolves to Process ID A < ID B");
   Assert (Happens_Before (Clock_A => 20, ID_A => 1, Clock_B => 20, ID_B => 2) = True, "Tie-breaker lower ID failed");
   Put_Line ("      PASS");

   -- TEST 11 - Total Ordering: Tie-Breaker (Higher ID loses)
   Put_Line ("TEST 11 - Total Ordering: Identical Clocks, A > B");
   Put_Line ("  11.1 Assert tie-breaker resolves correctly for ID A > ID B");
   Assert (Happens_Before (Clock_A => 20, ID_A => 5, Clock_B => 20, ID_B => 2) = False, "Tie-breaker higher ID failed");
   Put_Line ("      PASS");

   -- TEST 12 - Overflow Protection
   Put_Line ("TEST 12 - Clock Overflow Boundary Case");
   Put_Line ("  12.1 Assert raising exception when clock reaches limit");
   begin
      Initialize (P1, ID => 1, Initial_Time => Logical_Clock'Last);
      Local_Event (P1);
      Assert (False, "Overflow exception was not raised");
   exception
      when Clock_Overflow =>
         Put_Line ("      PASS");
   end;

   -- TEST 13 - Transitivity of Total Order
   Put_Line ("TEST 13 - Transitivity Property Verification");
   Put_Line ("  13.1 Assert A->B and B->C implies A->C");
   declare
      A_Before_B : Boolean := Happens_Before(10, 1, 10, 2); -- True
      B_Before_C : Boolean := Happens_Before(10, 2, 11, 1); -- True
      A_Before_C : Boolean := Happens_Before(10, 1, 11, 1); -- True
   begin
      Assert (A_Before_B and B_Before_C and A_Before_C, "Transitivity property failed");
      Put_Line ("      PASS");
   end;
   
   -- TEST 14 - Causality Verification
   Put_Line ("TEST 14 - Causality (Send happens before Receive)");
   Put_Line ("  14.1 Assert sender timestamp always precedes receiver updated timestamp");
   Initialize (P1, ID => 1, Initial_Time => 42);
   Initialize (P2, ID => 2, Initial_Time => 10);
   Msg := Send_Event (P1);      -- P1 becomes 43. Msg time = 43
   Receive_Event (P2, Msg);     -- P2 syncs to 43, increments to 44
   Assert (Happens_Before (Msg.Timestamp, P1.ID, P2.Clock, P2.ID) = True, "Causality broken");
   Put_Line ("      PASS");

   Put_Line ("===========================================");
   Put_Line ("ALL TESTS PASSED: Pessimistic assumptions disproved. Code verified.");
end Tests;
