-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with LRC; use LRC;

procedure Tests is
   Data_1 : constant Byte_Array := (16#01#, 16#02#, 16#03#); -- XOR=0, Modbus=FA, Odd=FF
   Data_2 : constant Byte_Array := (16#FF#, 16#FF#);         -- XOR=0, Modbus=02, Odd=FF
   Data_3 : constant Byte_Array := (16#00#, 16#00#, 16#00#); -- XOR=0, Modbus=00, Odd=FF
   Data_4 : constant Byte_Array := (16#FF#, 16#01#);         -- XOR=FE, Modbus=00, Odd=01
   Empty  : constant Byte_Array(1 .. 0) := (others => 0);    -- Empty array
begin
   Put_Line("=============================================");
   Put_Line("Running LRC Verification & Validation Tests");
   Put_Line("=============================================");
   
   -- TEST 1
   Put_Line("TEST 1 - Standard XOR LRC Basic Functionality");
   Put_Line("  1.1 Assert XOR LRC of [01, 02, 03] is 00");
   Assert (Calculate_XOR_LRC (Data_1) = 16#00#, "XOR Calculation failed");
   Put_Line("      PASS");

   -- TEST 2
   Put_Line("TEST 2 - Standard XOR LRC Canceling Pair");
   Put_Line("  2.1 Assert XOR LRC of [FF, FF] is 00");
   Assert (Calculate_XOR_LRC (Data_2) = 16#00#, "XOR Pair cancellation failed");
   Put_Line("      PASS");

   -- TEST 3
   Put_Line("TEST 3 - Standard XOR LRC All Zeros");
   Put_Line("  3.1 Assert XOR LRC of [00, 00, 00] is 00");
   Assert (Calculate_XOR_LRC (Data_3) = 16#00#, "XOR Zero evaluation failed");
   Put_Line("      PASS");

   -- TEST 4
   Put_Line("TEST 4 - Standard XOR LRC Verification (Positive)");
   Put_Line("  4.1 Assert Verify_XOR_LRC returns True for valid expected LRC");
   Assert (Verify_XOR_LRC (Data_1, 16#00#) = True, "XOR Verification (Positive) failed");
   Put_Line("      PASS");

   -- TEST 5
   Put_Line("TEST 5 - Standard XOR LRC Verification (Negative)");
   Put_Line("  5.1 Assert Verify_XOR_LRC returns False for invalid expected LRC");
   Assert (Verify_XOR_LRC (Data_1, 16#FF#) = False, "XOR Verification (Negative) failed");
   Put_Line("      PASS");

   -- TEST 6
   Put_Line("TEST 6 - Modbus LRC Basic Functionality");
   Put_Line("  6.1 Assert Modbus LRC of [01, 02, 03] is FA (2's comp of 06)");
   Assert (Calculate_Modbus_LRC (Data_1) = 16#FA#, "Modbus Calculation failed");
   Put_Line("      PASS");

   -- TEST 7
   Put_Line("TEST 7 - Modbus LRC Wraparound");
   Put_Line("  7.1 Assert Modbus LRC of [FF, 01] is 00 (Sum=0 mod 256, 2's comp=0)");
   Assert (Calculate_Modbus_LRC (Data_4) = 16#00#, "Modbus Wraparound failed");
   Put_Line("      PASS");

   -- TEST 8
   Put_Line("TEST 8 - Modbus LRC All Zeros");
   Put_Line("  8.1 Assert Modbus LRC of [00, 00, 00] is 00");
   Assert (Calculate_Modbus_LRC (Data_3) = 16#00#, "Modbus Zero evaluation failed");
   Put_Line("      PASS");

   -- TEST 9
   Put_Line("TEST 9 - Modbus LRC Verification (Positive)");
   Put_Line("  9.1 Assert Verify_Modbus_LRC returns True for valid Modbus LRC");
   Assert (Verify_Modbus_LRC (Data_1, 16#FA#) = True, "Modbus Verification (Positive) failed");
   Put_Line("      PASS");

   -- TEST 10
   Put_Line("TEST 10 - Odd Parity LRC Basic Functionality");
   Put_Line("  10.1 Assert Odd Parity LRC of [01, 02, 03] is FF (NOT 00)");
   Assert (Calculate_Odd_Parity_LRC (Data_1) = 16#FF#, "Odd Parity Calculation failed");
   Put_Line("      PASS");

   -- TEST 11
   Put_Line("TEST 11 - Odd Parity LRC All Zeros");
   Put_Line("  11.1 Assert Odd Parity LRC of [00, 00, 00] is FF");
   Assert (Calculate_Odd_Parity_LRC (Data_3) = 16#FF#, "Odd Parity Zero evaluation failed");
   Put_Line("      PASS");

   -- TEST 12
   Put_Line("TEST 12 - Boundary Exception Handling (XOR LRC)");
   Put_Line("  12.1 Assert Empty array raises Empty_Data_Error in XOR LRC");
   begin
      declare
         Result : Byte := Calculate_XOR_LRC (Empty);
      begin
         Assert(False, "XOR expected Empty_Data_Error, none raised");
      end;
   exception
      when Empty_Data_Error =>
         Put_Line("      PASS");
   end;

   -- TEST 13
   Put_Line("TEST 13 - Boundary Exception Handling (Modbus LRC)");
   Put_Line("  13.1 Assert Empty array raises Empty_Data_Error in Modbus LRC");
   begin
      declare
         Result : Byte := Calculate_Modbus_LRC (Empty);
      begin
         Assert(False, "Modbus expected Empty_Data_Error, none raised");
      end;
   exception
      when Empty_Data_Error =>
         Put_Line("      PASS");
   end;

   -- TEST 14
   Put_Line("TEST 14 - Boundary Exception Handling (Odd Parity LRC)");
   Put_Line("  14.1 Assert Empty array raises Empty_Data_Error in Odd Parity LRC");
   begin
      declare
         Result : Byte := Calculate_Odd_Parity_LRC (Empty);
      begin
         Assert(False, "Odd Parity expected Empty_Data_Error, none raised");
      end;
   exception
      when Empty_Data_Error =>
         Put_Line("      PASS");
   end;
   
   Put_Line("=============================================");
   Put_Line("ALL TESTS PASSED SUCCESSFULLY.");
end Tests;
