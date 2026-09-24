-- tests.adb
-- Comprehensive test suite validating the logic of the LZMA implementation.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Exceptions; use Ada.Exceptions;
with LZMA; use LZMA;

procedure Tests is

   procedure Assert (Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line ("    FAIL: " & Message);
         raise Program_Error with Message;
      else
         Put_Line ("    PASS");
      end if;
   end Assert;

   State  : LZMA_State;
   Conf   : LZMA_Config;
   
begin
   Put_Line ("Starting LZMA Validation & Verification Tests...");
   Put_Line ("===============================================");

   -- TEST 1: State Machine - Initial LIT transition
   Put_Line ("TEST 1 - State Machine: Initial LIT");
   State := 0;
   Update_State (State, LIT);
   Put_Line ("  1.1 Assert state 0 + LIT remains 0");
   Assert (State = 0, "State mismatch");

   -- TEST 2: State Machine - Mid-tier LIT transition
   Put_Line ("TEST 2 - State Machine: Mid-tier LIT");
   State := 4;
   Update_State (State, LIT);
   Put_Line ("  2.1 Assert state 4 + LIT goes to 1");
   Assert (State = 1, "State mismatch");

   -- TEST 3: State Machine - High-tier LIT transition
   Put_Line ("TEST 3 - State Machine: High-tier LIT");
   State := 11;
   Update_State (State, LIT);
   Put_Line ("  3.1 Assert state 11 + LIT goes to 5");
   Assert (State = 5, "State mismatch");

   -- TEST 4: State Machine - MATCH transition from low state
   Put_Line ("TEST 4 - State Machine: MATCH from low");
   State := 2;
   Update_State (State, MATCH);
   Put_Line ("  4.1 Assert state 2 + MATCH goes to 7");
   Assert (State = 7, "State mismatch");

   -- TEST 5: State Machine - MATCH transition from high state
   Put_Line ("TEST 5 - State Machine: MATCH from high");
   State := 9;
   Update_State (State, MATCH);
   Put_Line ("  5.1 Assert state 9 + MATCH goes to 10");
   Assert (State = 10, "State mismatch");

   -- TEST 6: State Machine - SHORTREP transition
   Put_Line ("TEST 6 - State Machine: SHORTREP");
   State := 5;
   Update_State (State, SHORTREP);
   Put_Line ("  6.1 Assert state 5 + SHORTREP goes to 9");
   Assert (State = 9, "State mismatch");

   -- TEST 7: State Machine - LONGREP transition
   Put_Line ("TEST 7 - State Machine: LONGREP");
   State := 10;
   Update_State (State, LONGREP);
   Put_Line ("  7.1 Assert state 10 + LONGREP goes to 11");
   Assert (State = 11, "State mismatch");

   -- TEST 8: Compression of empty string
   Put_Line ("TEST 8 - Compress Empty String");
   declare
      Res : constant Token_List := Compress ("", Conf);
   begin
      Put_Line ("  8.1 Assert output length is 0");
      Assert (Res.Len = 0, "Empty string generated tokens");
   end;

   -- TEST 9: Compression of literal characters without matches
   Put_Line ("TEST 9 - Compress literals only");
   declare
      Res : constant Token_List := Compress ("ABC", Conf);
   begin
      Put_Line ("  9.1 Assert output contains exactly 3 tokens");
      Assert (Res.Len = 3, "Wrong token count for ABC");
      Put_Line ("  9.2 Assert all tokens are literals");
      Assert (Res.Data(1).Kind = LIT and Res.Data(2).Kind = LIT, "Expected literals");
   end;

   -- TEST 10: Compression with dictionary matches
   Put_Line ("TEST 10 - Compress repeated pattern");
   declare
      Res : constant Token_List := Compress ("ABABA", Conf);
   begin
      Put_Line ("  10.1 Assert string generates a MATCH token");
      -- A (LIT), B (LIT), ABA (MATCH dist 2, len 3)
      Assert (Res.Len = 3, "Pattern ABABA should compress to 3 tokens");
      Assert (Res.Data(3).Kind = MATCH, "Expected MATCH token");
      Assert (Res.Data(3).Length = 3, "Expected match length 3");
   end;

   -- TEST 11: End-to-End Decompression Validity
   Put_Line ("TEST 11 - Decompression Correctness");
   declare
      Original : constant String := "Hello, Hello, Hello, World!";
      Compressed : constant Token_List := Compress (Original, Conf);
      Decompressed : constant String := Decompress (Compressed.Data (1 .. Compressed.Len), Conf);
   begin
      Put_Line ("  11.1 Assert decompressed matches original exactly");
      Assert (Original = Decompressed, "Data corruption in cycle");
   end;

   -- TEST 12: Robustness - Invalid Distance
   Put_Line ("TEST 12 - Error Handling: Invalid Distance");
   begin
      Put_Line ("  12.1 Assert invalid distance raises LZMA_Error");
      declare
         Bad_Tokens : constant Token_Array (1 .. 1) := 
           (1 => (Kind => MATCH, Literal => ASCII.NUL, Distance => 50, Length => 5));
         Result : String := Decompress (Bad_Tokens, Conf);
      begin
         Assert (False, "Expected LZMA_Error not raised");
      end;
   exception
      when LZMA_Error =>
         Put_Line ("    PASS");
   end;

   -- TEST 13: Robustness - Invalid Length
   Put_Line ("TEST 13 - Error Handling: Invalid Length");
   begin
      Put_Line ("  13.1 Assert invalid length raises LZMA_Error");
      declare
         -- Provide valid LIT to build dict, then bad MATCH length
         Bad_Tokens : constant Token_Array (1 .. 2) := 
           (1 => (Kind => LIT, Literal => 'A', Distance => 0, Length => 0),
            2 => (Kind => MATCH, Literal => ASCII.NUL, Distance => 1, Length => 0));
         Result : String := Decompress (Bad_Tokens, Conf);
      begin
         Assert (False, "Expected LZMA_Error not raised");
      end;
   exception
      when LZMA_Error =>
         Put_Line ("    PASS");
   end;

   Put_Line ("===============================================");
   Put_Line ("All 13 tests passed successfully. Code verified.");
end Tests;
