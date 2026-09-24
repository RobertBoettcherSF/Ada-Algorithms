with Ada.Text_IO; use Ada.Text_IO;
with Ada.Exceptions; use Ada.Exceptions;
with Huangs_Algorithm; use Huangs_Algorithm;

procedure Tests is
   Total_Tests  : Integer := 0;
   Passed_Tests : Integer := 0;

   procedure Assert (Condition : Boolean; Msg : String) is
   begin
      Total_Tests := Total_Tests + 1;
      if Condition then
         Put_Line ("      PASS");
         Passed_Tests := Passed_Tests + 1;
      else
         Put_Line ("      FAIL: " & Msg);
      end if;
   end Assert;

   Sys : System_State (Num_Nodes => 3);
   W   : Weight_Type;
begin
   Put_Line ("Initializing V&V Suite...");
   Put_Line ("Assuming code is broken - Executing tests to disprove assumption.");
   Put_Line ("-------------------------------------------------------------");

   -- TEST 1 - Initialization State
   Put_Line ("TEST 1 - Initialization State");
   Put_Line ("  1.1 Assert Initiator is Active and Weight is 1.0");
   Initialize (Sys, 1);
   Assert (Sys.Nodes(1).State = Active and Is_Virtually_Equal(Sys.Nodes(1).Weight, 1.0), "Initiator init failed");
   Put_Line ("  1.2 Assert Non-Initiator is Idle and Weight is 0.0");
   Assert (Sys.Nodes(2).State = Idle and Sys.Nodes(2).Weight = 0.0, "Node 2 init failed");
   Put_Line ("  1.3 Assert System is NOT Terminated immediately");
   Assert (not Is_Terminated (Sys), "Premature termination");

   -- TEST 2 - Static Weight Splitting
   Put_Line ("TEST 2 - Static Weight Splitting");
   Put_Line ("  2.1 Assert Send_Message_Static splits weight exactly in half");
   Send_Message_Static (Sys, 1, W);
   Assert (Is_Virtually_Equal(Sys.Nodes(1).Weight, 0.5) and Is_Virtually_Equal(W, 0.5), "Weight not split in half");
   Put_Line ("  2.2 Assert Sender remains Active after sending");
   Assert (Sys.Nodes(1).State = Active, "Sender became idle");

   -- TEST 3 - Dynamic Weight Splitting
   Put_Line ("TEST 3 - Dynamic Weight Splitting");
   Put_Line ("  3.1 Assert Send_Message_Dynamic splits weight by specified fraction (0.2)");
   Send_Message_Dynamic (Sys, 1, 0.2, W);
   Assert (Is_Virtually_Equal(Sys.Nodes(1).Weight, 0.4) and Is_Virtually_Equal(W, 0.1), "Dynamic split incorrect");

   -- TEST 4 - Receiving Messages
   Put_Line ("TEST 4 - Receiving Messages");
   Put_Line ("  4.1 Assert Receive_Message increases node weight");
   Receive_Message (Sys, 2, 0.5);
   Assert (Is_Virtually_Equal(Sys.Nodes(2).Weight, 0.5), "Node 2 didn't receive weight");
   Put_Line ("  4.2 Assert Receive_Message activates idle node");
   Assert (Sys.Nodes(2).State = Active, "Node 2 didn't activate");

   -- TEST 5 - Finishing Tasks (Worker Node)
   Put_Line ("TEST 5 - Finishing Tasks (Worker Node)");
   Put_Line ("  5.1 Assert Finish_Task sets state to Idle");
   Finish_Task (Sys, 2, W);
   Assert (Sys.Nodes(2).State = Idle, "Node 2 not idle after finishing");
   Put_Line ("  5.2 Assert Finish_Task sets weight to 0.0 and outputs total weight");
   Assert (Sys.Nodes(2).Weight = 0.0 and Is_Virtually_Equal(W, 0.5), "Node 2 weight not emptied");

   -- TEST 6 - Weight Return Accumulation
   Put_Line ("TEST 6 - Weight Return Accumulation");
   Put_Line ("  6.1 Assert Receive_Returned_Weight adds to Initiator's weight");
   Receive_Returned_Weight (Sys, W);
   Assert (Is_Virtually_Equal(Sys.Nodes(1).Weight, 0.9), "Initiator weight not accumulated correctly");

   -- TEST 7 - Finishing Tasks (Initiator)
   Put_Line ("TEST 7 - Finishing Tasks (Initiator)");
   Put_Line ("  7.1 Assert Initiator can finish its own task");
   Finish_Task (Sys, 1, W);
   Assert (Sys.Nodes(1).State = Idle, "Initiator not idle");
   Put_Line ("  7.2 Assert partial weight return does not trigger termination");
   Receive_Returned_Weight (Sys, W);
   Assert (not Is_Terminated (Sys), "Premature termination after initiator finish");

   -- TEST 8 - Full Termination Cycle
   Put_Line ("TEST 8 - Full Termination Cycle");
   Put_Line ("  8.1 Assert system terminates when ALL weight is returned");
   Receive_Message (Sys, 3, 0.1);
   Finish_Task (Sys, 3, W);
   Receive_Returned_Weight (Sys, W);
   Assert (Is_Terminated (Sys), "Termination not detected");

   -- TEST 9 - Robustness: Idle Node Send Error
   Put_Line ("TEST 9 - Robustness: Idle Node Send Error");
   Put_Line ("  9.1 Assert Invalid_Operation raised when Idle node sends message");
   declare
   begin
      Send_Message_Static (Sys, 2, W);
      Assert (False, "No exception for idle send");
   exception
      when Invalid_Operation => 
         Assert (True, "");
      when others =>
         Assert (False, "Wrong exception raised");
   end;

   -- TEST 10 - Robustness: Idle Node Finish Error
   Put_Line ("TEST 10 - Robustness: Idle Node Finish Error");
   Put_Line ("  10.1 Assert Invalid_Operation raised when Idle node finishes task");
   declare
   begin
      Finish_Task (Sys, 2, W);
      Assert (False, "No exception for idle finish");
   exception
      when Invalid_Operation => 
         Assert (True, "");
      when others =>
         Assert (False, "Wrong exception raised");
   end;

   -- TEST 11 - Robustness: Negative Weight Receive Error
   Put_Line ("TEST 11 - Robustness: Negative Weight Receive Error");
   Put_Line ("  11.1 Assert Invalid_Operation raised for receiving negative weight");
   declare
   begin
      Receive_Message (Sys, 2, -0.5);
      Assert (False, "No exception for negative weight receive");
   exception
      when Invalid_Operation => 
         Assert (True, "");
      when others =>
         Assert (False, "Wrong exception raised");
   end;

   -- TEST 12 - Robustness: Dynamic Split Fraction Boundaries
   Put_Line ("TEST 12 - Robustness: Dynamic Split Boundaries");
   Put_Line ("  12.1 Assert Invalid_Operation for fraction >= 1.0");
   Initialize (Sys, 1);
   declare
   begin
      Send_Message_Dynamic (Sys, 1, 1.5, W);
      Assert (False, "No exception for large fraction");
   exception
      when Invalid_Operation => 
         Assert (True, "");
      when others =>
         Assert (False, "Wrong exception raised");
   end;

   -- TEST 13 - Precision and Underflow Protection
   Put_Line ("TEST 13 - Precision and Underflow Protection");
   Put_Line ("  13.1 Assert underflow exception when sending microscopic fraction");
   declare
   begin
      Send_Message_Dynamic (Sys, 1, 1.0e-12, W);
      Assert (False, "No exception for precision underflow");
   exception
      when Invalid_Operation => 
         Assert (True, "");
      when others =>
         Assert (False, "Wrong exception raised");
   end;

   Put_Line ("-------------------------------------------------------------");
   Put_Line ("Test Summary: " & Integer'Image(Passed_Tests) & " / " & Integer'Image(Total_Tests) & " Assertions Passed.");
end Tests;
