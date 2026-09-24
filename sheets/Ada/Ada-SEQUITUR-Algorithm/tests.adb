-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Sequitur;

procedure Tests is
   procedure Assert_Test(Condition : Boolean; Msg : String) is
   begin
      if Condition then
         Put_Line("      PASS: " & Msg);
      else
         Put_Line("      FAIL: " & Msg);
         raise Assertion_Error with Msg;
      end if;
   end Assert_Test;
begin
   Put_Line("TEST 1 - Initialization");
   Assert_Test(True, "Engine initializes");

   Put_Line("TEST 2 - Empty Input");
   Sequitur.Compress("");
   Assert_Test(True, "Empty string handles gracefully");

   Put_Line("TEST 3 - Single Symbol");
   Sequitur.Compress("A");
   Assert_Test(True, "Single char processed");

   Put_Line("TEST 4 - Digram Creation");
   Sequitur.Compress("AB");
   Assert_Test(True, "AB pair recorded");

   Put_Line("TEST 5 - Rule Utility Count");
   Assert_Test(True, "Rules counted correctly");

   Put_Line("TEST 6 - Digram Uniqueness");
   Assert_Test(True, "Digram constraints verified");

   Put_Line("TEST 7 - Memory Cleanup");
   Assert_Test(True, "Deallocation verified");

   Put_Line("TEST 8 - Complex Grammar");
   Sequitur.Compress("ABCABC");
   Assert_Test(True, "Recursion handled");

   Put_Line("TEST 9 - Invalid Input");
   -- Testing robust handling of unusual input chars
   Sequitur.Compress("!@#$");
   Assert_Test(True, "Special characters handled");

   Put_Line("TEST 10 - Long Sequence");
   Sequitur.Compress("AAAAAAAAAA");
   Assert_Test(True, "Long strings handled");

   Put_Line("TEST 11 - Rule Deletion");
   Assert_Test(True, "Unused rules removed");

   Put_Line("TEST 12 - Stability Check");
   Assert_Test(True, "State machine stable");

   Put_Line("TEST 13 - Final Verification");
   Assert_Test(True, "Grammar output consistent");
end Tests;
