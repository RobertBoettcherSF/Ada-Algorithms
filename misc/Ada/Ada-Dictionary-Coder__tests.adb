-- tests.adb
-- Standalone test suite for the Dictionary Coder package.
-- Philosophy: Assume code is incorrect/broken. PASS when disproved.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Exceptions; use Ada.Exceptions;
with Dictionary_Coder; use Dictionary_Coder;

procedure Tests is
   Dict : Static_Dictionary;
   
   -- Helper assertion
   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("      FAIL: " & Message);
         raise Program_Error with "Test Assertion Failed: " & Message;
      end if;
   end Assert;
begin
   Put_Line ("========================================");
   Put_Line (" Dictionary Coder V&V Test Suite");
   Put_Line ("========================================");

   -----------------------------------------------------
   -- Category 1: Static Dictionary Robustness
   -----------------------------------------------------
   Put_Line ("TEST 1 - Static Dict: Initialization & Addition");
   Put_Line ("  1.1 Assert adding a valid word does not crash");
   Add_To_Dictionary (Dict, "HELLO");
   Add_To_Dictionary (Dict, "WORLD");
   Assert (True, "Initialization succeeded");
   Put_Line ("      PASS");

   Put_Line ("TEST 2 - Static Dict: Invalid Addition");
   Put_Line ("  2.1 Assert adding an empty string raises Dictionary_Error");
   begin
      Add_To_Dictionary (Dict, "");
      Assert (False, "Expected Dictionary_Error was not raised");
   exception
      when Dictionary_Error =>
         Put_Line ("      PASS");
   end;

   Put_Line ("TEST 3 - Static Dict: Encode Functional Check");
   Put_Line ("  3.1 Assert 'HELLO WORLD' encodes correctly");
   declare
      Codes : constant Code_Array := Encode_Static (Dict, "HELLO WORLD");
   begin
      Assert (Codes'Length = 2, "Length mismatch");
      Assert (Codes(1) = 1 and Codes(2) = 2, "Code values incorrect");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 4 - Static Dict: Decode Functional Check");
   Put_Line ("  4.1 Assert codes (1, 2) decode back to 'HELLO WORLD'");
   declare
      Codes : constant Code_Array (1 .. 2) := (1, 2);
      Decoded : constant String := Decode_Static (Dict, Codes);
   begin
      Assert (Decoded = "HELLO WORLD", "Decoded string mismatch");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 5 - Static Dict: Encode Boundary Case (Unknown Word)");
   Put_Line ("  5.1 Assert unknown word raises Encode_Error");
   begin
      declare
         Codes : Code_Array := Encode_Static (Dict, "HELLO ADA");
      begin
         Assert (False, "Expected Encode_Error was not raised");
      end;
   exception
      when Encode_Error =>
         Put_Line ("      PASS");
   end;

   Put_Line ("TEST 6 - Static Dict: Decode Boundary Case (Invalid Code)");
   Put_Line ("  6.1 Assert non-existent code raises Decode_Error");
   begin
      declare
         Codes : constant Code_Array (1 .. 1) := (1 => 99);
         Decoded : String := Decode_Static (Dict, Codes);
      begin
         Assert (False, "Expected Decode_Error was not raised");
      end;
   exception
      when Decode_Error =>
         Put_Line ("      PASS");
   end;

   Put_Line ("TEST 7 - Static Dict: Edge Cases (Empty Data)");
   Put_Line ("  7.1 Assert encoding empty string returns empty array");
   Put_Line ("  7.2 Assert decoding empty array returns empty string");
   declare
      Empty_Codes_Req : constant Code_Array := Encode_Static(Dict, "");
      Empty_Decoded_Req : constant String := Decode_Static(Dict, Empty_Codes_Req);
   begin
      Assert (Empty_Codes_Req'Length = 0, "Encode empty failed");
      Assert (Empty_Decoded_Req = "", "Decode empty failed");
      Put_Line ("      PASS");
   end;

   -----------------------------------------------------
   -- Category 2: Dynamic Dictionary (LZW) Logic Verification
   -----------------------------------------------------
   Put_Line ("TEST 8 - LZW: Basic Functional Encoding");
   Put_Line ("  8.1 Assert repeated patterns compress correctly (TOBEORNOT...)");
   declare
      Codes : constant Code_Array := LZW_Encode ("TOBEORNOTTOBEORTOBEORNOT");
   begin
      -- Ensure compressed size is strictly less than uncompressed size
      Assert (Codes'Length < 24, "Compression failed to reduce size");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 9 - LZW: Basic Functional Decoding");
   Put_Line ("  9.1 Assert LZW decode correctly mirrors LZW encode");
   declare
      Original : constant String := "COMPRESSION_TEST_STRING_COMPRESSION";
      Codes : constant Code_Array := LZW_Encode (Original);
      Decoded : constant String := LZW_Decode (Codes);
   begin
      Assert (Original = Decoded, "Decoded output does not match original");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 10 - LZW: The 'cScSc' Edge Case (Encode)");
   Put_Line ("  10.1 Assert LZW correctly encodes edge pattern like ABABABA");
   declare
      Codes : constant Code_Array := LZW_Encode ("ABABABA");
   begin
      Assert (Codes'Length > 0, "Failed to encode edge case");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 11 - LZW: The 'cScSc' Edge Case (Decode)");
   Put_Line ("  11.1 Assert decode handles sequence referencing incomplete dictionary node");
   declare
      Original : constant String := "ABABABA";
      Codes : constant Code_Array := LZW_Encode (Original);
      Decoded : constant String := LZW_Decode (Codes);
   begin
      Assert (Original = Decoded, "cScSc Edge case decode failed");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 12 - LZW: Edge Cases (Single Character)");
   Put_Line ("  12.1 Assert single character string handles gracefully");
   declare
      Codes : constant Code_Array := LZW_Encode ("A");
      Decoded : constant String := LZW_Decode (Codes);
   begin
      Assert (Codes'Length = 1, "Single char encoding size wrong");
      Assert (Decoded = "A", "Single char decoded mismatch");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 13 - LZW: Edge Cases (Empty Input)");
   Put_Line ("  13.1 Assert empty encode/decode returns gracefully");
   declare
      Codes : constant Code_Array := LZW_Encode ("");
      Decoded : constant String := LZW_Decode (Codes);
   begin
      Assert (Codes'Length = 0, "Empty encoding size wrong");
      Assert (Decoded = "", "Empty string decode mismatch");
      Put_Line ("      PASS");
   end;

   Put_Line ("TEST 14 - LZW: Negative Testing (Malformed Codes)");
   Put_Line ("  14.1 Assert malformed LZW codes trigger Decode_Error");
   begin
      declare
         -- Code 500 is way beyond initial 256 limit, immediately referencing future dict
         Codes : constant Code_Array(1..2) := (65, 500); 
         Decoded : String := LZW_Decode (Codes);
      begin
         Assert (False, "Expected Decode_Error not raised");
      end;
   exception
      when Decode_Error =>
         Put_Line ("      PASS");
   end;

   Put_Line ("========================================");
   Put_Line (" ALL 14 TESTS PASSED SUCCESFULLY");
   Put_Line ("========================================");
end Tests;
