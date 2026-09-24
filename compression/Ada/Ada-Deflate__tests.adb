-- tests.adb
-- Validation and Verification suite for Deflate Algorithm.
-- Assumes code is broken. PASS indicates the code successfully handled the condition.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Streams; use Ada.Streams;
with Deflate; use Deflate;

procedure Tests is
   Total_Tests : constant := 20;
   Passed_Tests : Natural := 0;

   procedure Assert(Condition : Boolean; Message : String) is
   begin
      if not Condition then
         Put_Line("    [FAIL] " & Message);
      else
         Put_Line("    [PASS] " & Message);
         Passed_Tests := Passed_Tests + 1;
      end if;
   end Assert;

   Empty_In : Stream_Element_Array(1 .. 0);
   Out_Buf  : Stream_Element_Array(1 .. 1024);
   Small_Out : Stream_Element_Array(1 .. 2);
   Last_Idx : Stream_Element_Offset;

   -- Helpers for test data
   function To_SEA(S : String) return Stream_Element_Array is
      Res : Stream_Element_Array(1 .. S'Length);
   begin
      for I in S'Range loop
         Res(Stream_Element_Offset(I)) := Character'Pos(S(I));
      end loop;
      return Res;
   end To_SEA;

   Test_Str : constant Stream_Element_Array := To_SEA("AAABBBCAAABBB");
   Toks     : Token_Array(1 .. 50);
   Tok_Cnt  : Natural;

begin
   Put_Line("Starting V&V Test Suite for Deflate...");

   Put_Line("TEST 1 - Empty Input Handling");
   Deflate.Compress(Empty_In, Out_Buf, Last_Idx, Deflate.Stored);
   Assert(Last_Idx < Out_Buf'First, "1.1 Compress empty array updates Last correctly");
   
   Put_Line("TEST 2 - Decompress Empty Input");
   Deflate.Decompress(Empty_In, Out_Buf, Last_Idx);
   Assert(Last_Idx < Out_Buf'First, "2.1 Decompress empty array updates Last correctly");

   Put_Line("TEST 3 - Stored Block Headers (Validation)");
   Deflate.Compress(To_SEA("A"), Out_Buf, Last_Idx, Deflate.Stored);
   Assert(Out_Buf(1) = 16#01#, "3.1 Block header BTYPE=00, BFINAL=1");
   Assert(Out_Buf(2) = 1, "3.2 LEN LSB correct");
   Assert(Out_Buf(3) = 0, "3.3 LEN MSB correct");

   Put_Line("TEST 4 - Stored Block Edge Case (Buffer Overflow)");
   begin
      Deflate.Compress(To_SEA("ABCDE"), Small_Out, Last_Idx, Deflate.Stored);
      Assert(False, "4.1 Failed to raise Buffer_Overflow on small output");
   exception
      when Deflate.Buffer_Overflow => Assert(True, "4.1 Raises Buffer_Overflow correctly");
   end;

   Put_Line("TEST 5 - LZ77 Literal Encoding");
   Deflate.LZ77_Encode(To_SEA("ABC"), Toks, Tok_Cnt);
   Assert(Tok_Cnt = 3, "5.1 Three tokens generated for distinct characters");
   Assert(Toks(1).Kind = Literal, "5.2 Token 1 is Literal");
   
   Put_Line("TEST 6 - LZ77 Match Logic");
   -- Data: "AAABBBCAAABBB" -> Match should occur on second "AAABBB"
   Deflate.LZ77_Encode(Test_Str, Toks, Tok_Cnt);
   Assert(Toks(8).Kind = Match, "6.1 Second sequence correctly identified as Match");
   Assert(Toks(8).Length = 6, "6.2 Match length is 6");
   Assert(Toks(8).Distance = 7, "6.3 Match distance is 7");

   Put_Line("TEST 7 - LZ77 No Match Minimum Bounds");
   -- Deflate requires min match of 3 characters. "AAB" vs "AAC" should not match lengths < 3.
   Deflate.LZ77_Encode(To_SEA("ABABAB"), Toks, Tok_Cnt);
   Assert(Toks(3).Kind = Match, "7.1 Match triggers for length >= 3");

   Put_Line("TEST 8 - Static Huffman Encoding Router");
   Deflate.Compress(To_SEA("XYZ"), Out_Buf, Last_Idx, Deflate.Static_Huffman);
   Assert(Out_Buf(1) = 16#03#, "8.1 Static Huffman BTYPE header correctly set (01)");

   Put_Line("TEST 9 - Dynamic Huffman Encoding Router");
   Deflate.Compress(To_SEA("XYZ"), Out_Buf, Last_Idx, Deflate.Dynamic_Huffman);
   Assert(Out_Buf(1) = 16#05#, "9.1 Dynamic Huffman BTYPE header correctly set (10)");

   Put_Line("TEST 10 - Stored Block NLEN Check");
   Deflate.Compress(To_SEA("A"), Out_Buf, Last_Idx, Deflate.Stored);
   -- NLEN is bitwise NOT of LEN (LEN = 00000001, NOT = 11111110 = 254)
   Assert(Out_Buf(4) = 254, "10.1 NLEN LSB is one's complement of LEN LSB");

   Put_Line("TEST 11 - Decompression of Stored Block");
   Deflate.Decompress(Out_Buf(1 .. Last_Idx), Out_Buf, Last_Idx);
   Assert(Last_Idx = Out_Buf'First, "11.1 Decompressed length is 1");
   Assert(Out_Buf(1) = Character'Pos('A'), "11.2 Decompressed payload matches original");

   Put_Line("TEST 12 - Maximum Match Length Ceiling (LZ77)");
   declare
      Long_In : constant Stream_Element_Array(1 .. 300) := (others => 65); -- 300 'A's
   begin
      Deflate.LZ77_Encode(Long_In, Toks, Tok_Cnt);
      -- First is literal, second is match of max 258, third is remainder
      Assert(Toks(2).Length = 258, "12.1 Match length caps at max 258 bytes per specification");
   end;

   Put_Line("TEST 13 - Over-size Stored Block Exception");
   declare
      Huge_Buf : constant Stream_Element_Array(1 .. 65536) := (others => 0);
      Dummy : Stream_Element_Offset;
   begin
      Deflate.Process_Stored_Block(Huge_Buf, Out_Buf, Dummy);
      Assert(False, "13.1 Stored block over 65535 did not fail");
   exception
      when Deflate.Deflate_Error => Assert(True, "13.1 Raises Deflate_Error for size > 65535");
   end;

   Put_Line("TEST 14 - Invalid Decompression format gracefully fails");
   declare
      Bad_In : constant Stream_Element_Array(1 .. 5) := (others => 16#FF#);
   begin
      Deflate.Decompress(Bad_In, Out_Buf, Last_Idx);
      Assert(False, "14.1 Invalid block header decompressed without error");
   exception
      when Deflate.Deflate_Error => Assert(True, "14.1 Deflate_Error raised for unknown block");
   end;

   Put_Line("");
   Put_Line("Total Passed: " & Natural'Image(Passed_Tests) & " / " & Natural'Image(Total_Tests));
   if Passed_Tests = Total_Tests then
      Put_Line("STATUS: SUCCESS. All pessimistic assumptions disproved.");
   else
      Put_Line("STATUS: FAILED.");
   end if;
end Tests;
