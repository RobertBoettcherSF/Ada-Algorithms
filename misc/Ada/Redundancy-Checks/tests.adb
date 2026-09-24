with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Interfaces; use Interfaces;
with Redundancy_Checks; use Redundancy_Checks;

procedure Tests is
   Empty_Arr : Byte_Array (1 .. 0);
   Arr_1     : Byte_Array := (16#55#, 16#AA#);
   Arr_2     : Byte_Array := (16#01#, 16#02#, 16#03#);
   Arr_3     : Byte_Array := (16#FF#, 16#02#);
   -- Array representing ASCII string "123456789" (Standard CRC/Adler test vector)
   Arr_4     : Byte_Array := (16#31#, 16#32#, 16#33#, 16#34#, 16#35#, 16#36#, 16#37#, 16#38#, 16#39#);
begin
   Put_Line ("Starting V&V Test Suite: Redundancy Checks");
   Put_Line ("==========================================");

   -- TEST 1
   Put_Line ("TEST 1 - Even Parity Edge Cases");
   Put_Line ("  1.1 Assert Even Parity of 0x00 is 0");
   Assert (Calculate_Even_Parity (0) = 0, "Failed 1.1: 0x00 should have even parity 0");
   Put_Line ("     PASS");

   -- TEST 2
   Put_Line ("TEST 2 - Even Parity Single Bit");
   Put_Line ("  2.1 Assert Even Parity of 0x01 is 1");
   Assert (Calculate_Even_Parity (1) = 1, "Failed 2.1: 0x01 should have even parity 1");
   Put_Line ("     PASS");

   -- TEST 3
   Put_Line ("TEST 3 - Even Parity Multiple Bits");
   Put_Line ("  3.1 Assert Even Parity of 0x03 is 0");
   Assert (Calculate_Even_Parity (3) = 0, "Failed 3.1: 0x03 should have even parity 0");
   Put_Line ("     PASS");

   -- TEST 4
   Put_Line ("TEST 4 - Odd Parity Edge Cases");
   Put_Line ("  4.1 Assert Odd Parity of 0x00 is 1");
   Assert (Calculate_Odd_Parity (0) = 1, "Failed 4.1: 0x00 should have odd parity 1");
   Put_Line ("     PASS");

   -- TEST 5
   Put_Line ("TEST 5 - Odd Parity Single Bit");
   Put_Line ("  5.1 Assert Odd Parity of 0x01 is 0");
   Assert (Calculate_Odd_Parity (1) = 0, "Failed 5.1: 0x01 should have odd parity 0");
   Put_Line ("     PASS");

   -- TEST 6
   Put_Line ("TEST 6 - LRC Empty Array Protection");
   Put_Line ("  6.1 Assert LRC empty array raises Empty_Data_Error");
   begin
      declare
         Result : Byte := Calculate_LRC (Empty_Arr);
      begin
         Assert (False, "Expected Empty_Data_Error not raised");
      end;
   exception
      when Empty_Data_Error =>
         Put_Line ("     PASS");
   end;

   -- TEST 7
   Put_Line ("TEST 7 - LRC Standard Calculation");
   Put_Line ("  7.1 Assert LRC of [0x55, 0xAA] is 0xFF");
   Assert (Calculate_LRC (Arr_1) = 16#FF#, "Failed 7.1: XOR sum mismatch");
   Put_Line ("     PASS");

   -- TEST 8
   Put_Line ("TEST 8 - Checksum-8 Standard Calculation");
   Put_Line ("  8.1 Assert Checksum-8 of [0x01, 0x02, 0x03] is 0x06");
   Assert (Calculate_Checksum_8 (Arr_2) = 16#06#, "Failed 8.1: Basic sum mismatch");
   Put_Line ("     PASS");

   -- TEST 9
   Put_Line ("TEST 9 - Checksum-8 Modular Rollover");
   Put_Line ("  9.1 Assert Checksum-8 of [0xFF, 0x02] is 0x01");
   Assert (Calculate_Checksum_8 (Arr_3) = 16#01#, "Failed 9.1: Modulo arithmetic failed");
   Put_Line ("     PASS");

   -- TEST 10
   Put_Line ("TEST 10 - Checksum-8 Empty Array Protection");
   Put_Line ("  10.1 Assert Checksum-8 empty array raises Empty_Data_Error");
   begin
      declare
         Result : Byte := Calculate_Checksum_8 (Empty_Arr);
      begin
         Assert (False, "Expected Empty_Data_Error not raised");
      end;
   exception
      when Empty_Data_Error =>
         Put_Line ("     PASS");
   end;

   -- TEST 11
   Put_Line ("TEST 11 - CRC-32 Empty Vector Initialization");
   Put_Line ("  11.1 Assert CRC-32 of empty array defaults correctly (0x00000000)");
   Assert (Calculate_CRC32 (Empty_Arr) = 0, "Failed 11.1: Empty CRC32 should be 0");
   Put_Line ("     PASS");

   -- TEST 12
   Put_Line ("TEST 12 - CRC-32 Industry Standard Match");
   Put_Line ("  12.1 Assert CRC-32 of '123456789' is 0xCBF43926");
   Assert (Calculate_CRC32 (Arr_4) = 16#CBF4_3926#, "Failed 12.1: CRC32 implementation violates standard");
   Put_Line ("     PASS");

   -- TEST 13
   Put_Line ("TEST 13 - Adler-32 Empty Vector Initialization");
   Put_Line ("  13.1 Assert Adler-32 of empty array defaults correctly (1)");
   Assert (Calculate_Adler32 (Empty_Arr) = 1, "Failed 13.1: Empty Adler32 should be 1");
   Put_Line ("     PASS");

   -- TEST 14
   Put_Line ("TEST 14 - Adler-32 Industry Standard Match");
   Put_Line ("  14.1 Assert Adler-32 of '123456789' is 0x091E01DE");
   Assert (Calculate_Adler32 (Arr_4) = 16#091E_01DE#, "Failed 14.1: Adler32 implementation violates standard");
   Put_Line ("     PASS");

   Put_Line ("==========================================");
   Put_Line ("ALL 14 ASSUMPTIONS DISPROVEN - CODE WORKS.");
end Tests;
