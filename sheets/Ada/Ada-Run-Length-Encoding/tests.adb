with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Run_Length_Encoding; use Run_Length_Encoding;

procedure Tests is
   T : constant Boolean := True;
   F : constant Boolean := False;
   
   -- Helper to print pass/fail results without halting execution
   procedure Run_Test (Name : String; Logic : access procedure) is
   begin
      Put_Line (Name);
      Logic.all;
      Put_Line ("      PASS");
   exception
      when Assertion_Error =>
         Put_Line ("      FAIL: Assertion Error");
      when others =>
         Put_Line ("      FAIL: Unexpected Exception");
   end Run_Test;

   procedure Test_1 is begin 
      Assert (Encode_String ("AAAABBBCCDAA") = "4A3B2C1D2A", "Basic Encode Failed"); 
   end Test_1;
   
   procedure Test_2 is begin 
      Assert (Decode_String ("4A3B2C1D2A") = "AAAABBBCCDAA", "Basic Decode Failed"); 
   end Test_2;
   
   procedure Test_3 is begin 
      Assert (Encode_String ("W") = "1W", "Single Char Encode Failed"); 
   end Test_3;
   
   procedure Test_4 is begin 
      Assert (Decode_String ("1W") = "W", "Single Char Decode Failed"); 
   end Test_4;
   
   procedure Test_5 is begin 
      Assert (Encode_String ("") = "", "Empty String Encode Failed"); 
   end Test_5;
   
   procedure Test_6 is begin 
      Assert (Decode_String ("") = "", "Empty String Decode Failed"); 
   end Test_6;
   
   procedure Test_7 is begin 
      Assert (Encode_String ("ABC") = "1A1B1C", "No Runs Encode Failed"); 
   end Test_7;
   
   procedure Test_8 is begin 
      Assert (Decode_String ("1A1B1C") = "ABC", "No Runs Decode Failed"); 
   end Test_8;
   
   procedure Test_9 is begin 
      Assert (Encode_String ("AAAAAAAAAAAAAAAAAAAA") = "20A", "Long Run Encode Failed"); 
   end Test_9;

   procedure Test_10 is begin 
      Assert (Decode_String ("20A") = "AAAAAAAAAAAAAAAAAAAA", "Long Run Decode Failed"); 
   end Test_10;

   procedure Test_11 is 
      Start : Boolean;
      Res   : constant Count_Array := Encode_Binary ((T, T, T, F, F, T), Start);
   begin 
      Assert (Start, "Wrong Start Bit");
      Assert (Res'Length = 3 and then Res (1) = 3 and then Res (2) = 2 and then Res (3) = 1, "Binary Encode Failed");
   end Test_11;

   procedure Test_12 is 
      Res : constant Binary_Array := Decode_Binary ((3, 2, 1), True);
   begin 
      Assert (Res'Length = 6, "Length Wrong");
      Assert (Res = (T, T, T, F, F, T), "Binary Decode Failed");
   end Test_12;

   procedure Test_13 is 
      Start : Boolean;
      Res   : constant Count_Array := Encode_Binary ((1 .. 0 => False), Start);
   begin 
      Assert (Res'Length = 0, "Empty Binary Encode Failed");
      Assert (not Start, "Start bit should default to False for empty array");
   end Test_13;

   procedure Test_14 is begin 
      declare
         Res : String := Encode_String ("A1B");
         pragma Unreferenced (Res);
      begin
         Assert (False, "Should have raised exception");
      end;
   exception
      when Invalid_Format => null;
   end Test_14;

   procedure Test_15 is begin 
      declare
         Res : String := Decode_String ("123");
         pragma Unreferenced (Res);
      begin
         Assert (False, "Should have raised exception");
      end;
   exception
      when Invalid_Format => null;
   end Test_15;

   procedure Test_16 is begin 
      declare
         Res : String := Decode_String ("A12B");
         pragma Unreferenced (Res);
      begin
         Assert (False, "Should have raised exception");
      end;
   exception
      when Invalid_Format => null;
   end Test_16;

   procedure Test_17 is begin 
      declare
         Res : String := Decode_String ("0A");
         pragma Unreferenced (Res);
      begin
         Assert (False, "0 count should raise exception");
      end;
   exception
      when Invalid_Format => null;
   end Test_17;

begin
   Put_Line ("Starting Test Suite: V&V Pessimistic Assumptions Check");
   Put_Line ("======================================================");
   Run_Test ("TEST 1  - 1.1 Assert String Encoding (Basic)", Test_1'Access);
   Run_Test ("TEST 2  - 1.2 Assert String Decoding (Basic)", Test_2'Access);
   Run_Test ("TEST 3  - 1.3 Assert String Encoding (Single Char)", Test_3'Access);
   Run_Test ("TEST 4  - 1.4 Assert String Decoding (Single Char)", Test_4'Access);
   Run_Test ("TEST 5  - 1.5 Assert String Encoding (Empty)", Test_5'Access);
   Run_Test ("TEST 6  - 1.6 Assert String Decoding (Empty)", Test_6'Access);
   Run_Test ("TEST 7  - 1.7 Assert String Encoding (No Runs)", Test_7'Access);
   Run_Test ("TEST 8  - 1.8 Assert String Decoding (No Runs)", Test_8'Access);
   Run_Test ("TEST 9  - 1.9 Assert String Encoding (Long Runs > 9)", Test_9'Access);
   Run_Test ("TEST 10 - 1.10 Assert String Decoding (Long Runs > 9)", Test_10'Access);
   Run_Test ("TEST 11 - 2.1 Assert Binary Encoding (Alternating)", Test_11'Access);
   Run_Test ("TEST 12 - 2.2 Assert Binary Decoding (Alternating)", Test_12'Access);
   Run_Test ("TEST 13 - 2.3 Assert Binary Encoding (Empty Boundary)", Test_13'Access);
   Run_Test ("TEST 14 - 3.1 Assert Encode Trap: String Contains Digits", Test_14'Access);
   Run_Test ("TEST 15 - 3.2 Assert Decode Trap: Missing Character", Test_15'Access);
   Run_Test ("TEST 16 - 3.3 Assert Decode Trap: Missing Digit Prefix", Test_16'Access);
   Run_Test ("TEST 17 - 3.4 Assert Decode Trap: Count is Zero", Test_17'Access);
end Tests;
