-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Parity_Bit; use Parity_Bit;

procedure Tests is
   -- Helper variables
   Data_Even_1s : constant Bit_Array := (1, 1, 0, 0); -- 2 ones
   Data_Odd_1s  : constant Bit_Array := (1, 0, 0, 0); -- 1 one
   Single_Bit   : constant Bit_Array := (1 => 1);
   Empty_Data   : constant Bit_Array (1 .. 0) := (others => 0);
begin
   Put_Line ("Starting Parity Bit Test Suite...");
   Put_Line ("---------------------------------");

   -- TEST 1: Even Parity with Even Data
   Put_Line ("TEST 1 - Even Parity (Even number of 1s)");
   Put_Line ("  1.1 Assert parity bit is 0");
   Assert (Calculate_Parity (Data_Even_1s, Even) = 0, "Failed: Should be 0");
   Put_Line ("      PASS");

   -- TEST 2: Even Parity with Odd Data
   Put_Line ("TEST 2 - Even Parity (Odd number of 1s)");
   Put_Line ("  2.1 Assert parity bit is 1");
   Assert (Calculate_Parity (Data_Odd_1s, Even) = 1, "Failed: Should be 1");
   Put_Line ("      PASS");

   -- TEST 3: Odd Parity with Even Data
   Put_Line ("TEST 3 - Odd Parity (Even number of 1s)");
   Put_Line ("  3.1 Assert parity bit is 1");
   Assert (Calculate_Parity (Data_Even_1s, Odd) = 1, "Failed: Should be 1");
   Put_Line ("      PASS");

   -- TEST 4: Odd Parity with Odd Data
   Put_Line ("TEST 4 - Odd Parity (Odd number of 1s)");
   Put_Line ("  4.1 Assert parity bit is 0");
   Assert (Calculate_Parity (Data_Odd_1s, Odd) = 0, "Failed: Should be 0");
   Put_Line ("      PASS");

   -- TEST 5: Mark Parity
   Put_Line ("TEST 5 - Mark Parity Variant");
   Put_Line ("  5.1 Assert parity is always 1");
   Assert (Calculate_Parity (Data_Even_1s, Mark) = 1, "Failed Mark parity");
   Assert (Calculate_Parity (Data_Odd_1s, Mark) = 1, "Failed Mark parity");
   Put_Line ("      PASS");

   -- TEST 6: Space Parity
   Put_Line ("TEST 6 - Space Parity Variant");
   Put_Line ("  6.1 Assert parity is always 0");
   Assert (Calculate_Parity (Data_Even_1s, Space) = 0, "Failed Space parity");
   Assert (Calculate_Parity (Data_Odd_1s, Space) = 0, "Failed Space parity");
   Put_Line ("      PASS");

   -- TEST 7: Add_Parity function
   Put_Line ("TEST 7 - Append Parity Bit to Payload");
   Put_Line ("  7.1 Assert result length is N+1");
   declare
      Res : constant Bit_Array := Add_Parity (Data_Even_1s, Even);
   begin
      Assert (Res'Length = Data_Even_1s'Length + 1, "Length mismatch");
      Put_Line ("  7.2 Assert appended bit is correct");
      Assert (Res (Res'Last) = 0, "Appended bit incorrect");
      Put_Line ("      PASS");
   end;

   -- TEST 8: Check_Parity Valid
   Put_Line ("TEST 8 - Check Valid Frame");
   Put_Line ("  8.1 Assert Check_Parity returns True for valid payload");
   Assert (Check_Parity ((1, 1, 0, 0, 0), Even) = True, "Validation failed");
   Put_Line ("      PASS");

   -- TEST 9: Check_Parity Invalid
   Put_Line ("TEST 9 - Check Invalid Frame");
   Put_Line ("  9.1 Assert Check_Parity returns False for corruption");
   Assert (Check_Parity ((1, 1, 0, 0, 1), Even) = False, "False positive");
   Put_Line ("      PASS");

   -- TEST 10: Exception Handling - Empty Calculate
   Put_Line ("TEST 10 - Empty Data handling (Calculate)");
   Put_Line ("  10.1 Assert Invalid_Data_Error is raised on empty array");
   begin
      declare
         Dummy : Bit := Calculate_Parity (Empty_Data, Even);
      begin
         Assert (False, "Exception not raised");
      end;
   exception
      when Invalid_Data_Error => Put_Line ("      PASS");
   end;

   -- TEST 11: Exception Handling - Empty Add
   Put_Line ("TEST 11 - Empty Data handling (Add_Parity)");
   Put_Line ("  11.1 Assert Invalid_Data_Error is raised");
   begin
      declare
         Dummy : Bit_Array := Add_Parity (Empty_Data, Even);
      begin
         Assert (False, "Exception not raised");
      end;
   exception
      when Invalid_Data_Error => Put_Line ("      PASS");
   end;

   -- TEST 12: Exception Handling - Check Too Short
   Put_Line ("TEST 12 - Frame too small to validate");
   Put_Line ("  12.1 Assert Invalid_Data_Error on single-bit frame check");
   begin
      declare
         Dummy : Boolean := Check_Parity (Single_Bit, Even);
      begin
         Assert (False, "Exception not raised");
      end;
   exception
      when Invalid_Data_Error => Put_Line ("      PASS");
   end;

   -- TEST 13: Boundary - Single Bit Payload
   Put_Line ("TEST 13 - Single Bit Payload Processing");
   Put_Line ("  13.1 Assert calculation works on exactly 1 bit");
   Assert (Calculate_Parity (Single_Bit, Odd) = 0, "Single bit failed");
   Put_Line ("      PASS");

   -- TEST 14: Independence of indexing
   Put_Line ("TEST 14 - Array Index Independence");
   Put_Line ("  14.1 Assert functions work regardless of starting index");
   declare
      Offset_Array : Bit_Array (100 .. 103) := (1, 0, 0, 0);
   begin
      Assert (Calculate_Parity (Offset_Array, Even) = 1, "Index independence failed");
      Put_Line ("      PASS");
   end;

   Put_Line ("---------------------------------");
   Put_Line ("ALL TESTS PASSED SUCCESSFULLY");
end Tests;
