-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Lz_Compression; use Lz_Compression;

procedure Tests is
   -- Helper procedure to standardize output logs
   procedure Log_Test (Test_Name : String) is
   begin
      Put_Line ("--------------------------------------------------");
      Put_Line ("TEST: " & Test_Name);
   end Log_Test;

   procedure Pass is
   begin
      Put_Line ("  PASS");
   end Pass;

   Test_String : constant String := "AABABBBABAABABBB";
begin
   Put_Line ("Starting V&V Test Suite for LZ Compression Algorithms");

   -----------------------------------------------------------------------------
   -- LZ77 TESTS
   -----------------------------------------------------------------------------
   
   Log_Test ("1. LZ77 Encode Baseline");
   Put_Line ("  1.1 Assert LZ77 Encodes valid string safely");
   declare
      Tokens : constant Lz77_Token_Array := Lz77_Encode (Test_String);
   begin
      Assert (Tokens'Length > 0, "LZ77 returned 0 tokens");
      Pass;
   end;

   Log_Test ("2. LZ77 Decode Consistency (Lossless Check)");
   Put_Line ("  2.1 Assert Encoded string fully matches Decoded string");
   declare
      Tokens  : constant Lz77_Token_Array := Lz77_Encode (Test_String);
      Decoded : constant String := Lz77_Decode (Tokens);
   begin
      Assert (Decoded = Test_String, "Data loss during LZ77 compression");
      Pass;
   end;

   Log_Test ("3. LZ77 Empty String Handling");
   Put_Line ("  3.1 Assert Empty_Input_Error is raised on encode");
   begin
      declare
         Tokens : constant Lz77_Token_Array := Lz77_Encode ("");
         pragma Unreferenced (Tokens);
      begin
         Assert (False, "Should have raised exception on Empty Input");
      end;
   exception
      when Empty_Input_Error => Pass;
   end;

   Log_Test ("4. LZ77 Redundancy Squeeze");
   Put_Line ("  4.1 Assert string 'AAAAAA' compresses significantly");
   declare
      Tokens : constant Lz77_Token_Array := Lz77_Encode ("AAAAAA");
   begin
      Assert (Tokens'Length < 6, "Failed to compress heavily redundant data");
      Assert (Lz77_Decode (Tokens) = "AAAAAA", "Lossless check failed");
      Pass;
   end;

   Log_Test ("5. LZ77 Entropy Verification");
   Put_Line ("  5.1 Assert 'ABCDEF' outputs correctly with no match offsets");
   declare
      Tokens : constant Lz77_Token_Array := Lz77_Encode ("ABCDEF");
   begin
      Assert (Tokens (1).Offset = 0, "False offset generated");
      Assert (Tokens'Length = 6, "Failed size alignment for zero-redundancy data");
      Pass;
   end;

   Log_Test ("6. LZ77 Malformed Token Validation");
   Put_Line ("  6.1 Assert Invalid_Token_Error is raised on bad Offset boundaries");
   begin
      declare
         Bad_Tokens : Lz77_Token_Array (1 .. 1);
         Decoded    : String (1 .. 100);
         pragma Unreferenced (Decoded);
      begin
         Bad_Tokens (1) := (Offset => 10, Length => 5, Next_Char => 'A', Has_Next => True);
         Decoded := Lz77_Decode (Bad_Tokens);
         Assert (False, "Should have raised Invalid_Token_Error");
      end;
   exception
      when Invalid_Token_Error => Pass;
   end;

   -----------------------------------------------------------------------------
   -- LZ78 TESTS
   -----------------------------------------------------------------------------
   
   Log_Test ("7. LZ78 Encode Baseline");
   Put_Line ("  7.1 Assert LZ78 Encodes valid string safely");
   declare
      Tokens : constant Lz78_Token_Array := Lz78_Encode (Test_String);
   begin
      Assert (Tokens'Length > 0, "LZ78 returned 0 tokens");
      Pass;
   end;

   Log_Test ("8. LZ78 Decode Consistency (Lossless Check)");
   Put_Line ("  8.1 Assert Encoded string fully matches Decoded string");
   declare
      Tokens  : constant Lz78_Token_Array := Lz78_Encode (Test_String);
      Decoded : constant String := Lz78_Decode (Tokens);
   begin
      Assert (Decoded = Test_String, "Data loss during LZ78 compression");
      Pass;
   end;

   Log_Test ("9. LZ78 Empty String Handling");
   Put_Line ("  9.1 Assert Empty_Input_Error is raised on empty string");
   begin
      declare
         Tokens : constant Lz78_Token_Array := Lz78_Encode ("");
         pragma Unreferenced (Tokens);
      begin
         Assert (False, "Should have raised exception on Empty Input");
      end;
   exception
      when Empty_Input_Error => Pass;
   end;

   Log_Test ("10. LZ78 Extreme Redundancy Check");
   Put_Line ("  10.1 Assert LZ78 handles single-character bursts properly");
   declare
      Tokens : constant Lz78_Token_Array := Lz78_Encode ("ZZZZZZZZZ");
   begin
      Assert (Tokens'Length < 9, "Failed to compress burst data");
      Assert (Lz78_Decode (Tokens) = "ZZZZZZZZZ", "Data corruption upon decode");
      Pass;
   end;

   Log_Test ("11. LZ78 Zero-Redundancy Verification");
   Put_Line ("  11.1 Assert LZ78 handles purely unique characters");
   declare
      Tokens : constant Lz78_Token_Array := Lz78_Encode ("123456");
   begin
      for I in Tokens'Range loop
         Assert (Tokens (I).Index = 0, "Invalid dict index injected");
      end loop;
      Assert (Lz78_Decode (Tokens) = "123456", "Data loss");
      Pass;
   end;

   Log_Test ("12. LZ78 Dictionary Index Validation");
   Put_Line ("  12.1 Assert Invalid_Token_Error is raised on corrupt tokens");
   begin
      declare
         Bad_Tokens : Lz78_Token_Array (1 .. 1);
         Decoded    : String (1 .. 100);
         pragma Unreferenced (Decoded);
      begin
         -- Requesting index 500 but dict is completely empty
         Bad_Tokens (1) := (Index => 500, Next_Char => 'A', Has_Next => True);
         Decoded := Lz78_Decode (Bad_Tokens);
         Assert (False, "Should have raised Invalid_Token_Error");
      end;
   exception
      when Invalid_Token_Error => Pass;
   end;

   Log_Test ("13. LZ78 Trailing Dictionary Match");
   Put_Line ("  13.1 Assert algorithm safely terminates if exact string is in dict");
   declare
      -- "ABAB" -> 1:(0,A) 2:(0,B) 3:(1,B). If string is "ABABA" we hit an edge case
      Tokens  : constant Lz78_Token_Array := Lz78_Encode ("ABABA");
      Decoded : constant String := Lz78_Decode (Tokens);
   begin
      Assert (Decoded = "ABABA", "Edge case termination logic bugged");
      Pass;
   end;

   Log_Test ("14. Mixed Algorithm Validation Check");
   Put_Line ("  14.1 Cross verify payload data integrity against large sets");
   declare
      Large_Payload : constant String := "THE_QUICK_BROWN_FOX_JUMPS_OVER_THE_LAZY_DOG_THE_QUICK_BROWN_FOX";
      T77 : constant Lz77_Token_Array := Lz77_Encode (Large_Payload);
      T78 : constant Lz78_Token_Array := Lz78_Encode (Large_Payload);
   begin
      Assert (Lz77_Decode (T77) = Large_Payload, "LZ77 payload corruption");
      Assert (Lz78_Decode (T78) = Large_Payload, "LZ78 payload corruption");
      Pass;
   end;

   Put_Line ("--------------------------------------------------");
   Put_Line ("ALL 14 ASSUMPTIONS DISPROVED. TESTS EXECUTED SUCCESSFULLY.");

end Tests;
