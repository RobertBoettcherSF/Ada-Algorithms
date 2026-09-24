-- tests.adb
-- Verification and Validation Test Suite for LZX Algorithm
-- Assumes codebase is broken until disproven by strictly passing assertions.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with LZX_Algorithm; use LZX_Algorithm;

procedure Tests is
   Config : LZX_Configuration;
   Input_Buf  : Byte_Array(1 .. 1024);
   Output_Buf : Byte_Array(1 .. 2048);
   Recover_Buf: Byte_Array(1 .. 2048);
   Out_Len, Rec_Len : Natural;
   
   -- Helper procedure to load string into byte array
   procedure Load_String (S : String; B : in out Byte_Array) is
   begin
      for I in S'Range loop
         B(B'First + I - S'First) := Character'Pos(S(I));
      end loop;
   end Load_String;
   
   -- Helper to check array equality
   function Arrays_Equal (A, B : Byte_Array; Len : Natural) return Boolean is
   begin
      for I in 0 .. Len - 1 loop
         if A(A'First + I) /= B(B'First + I) then return False; end if;
      end loop;
      return True;
   end Arrays_Equal;

begin
   Put_Line("=============================================");
   Put_Line(" LZX Algorithm Verification & Validation     ");
   Put_Line("=============================================");

   -- TEST 1
   Put_Line("TEST 1 - CAB LZX Configuration Bounds");
   Put_Line("  1.1 Assert CAB window caps at 2MB");
   Config := Create_Config(CAB_LZX, 5_000_000);
   Assert(Config.Window_Size = 2_097_152, "CAB Window failed to clamp.");
   Put_Line("      PASS");

   -- TEST 2
   Put_Line("TEST 2 - Xbox LZX Fixed Window");
   Put_Line("  2.1 Assert Xbox window is exactly 32KB");
   Config := Create_Config(Xbox_LZX, 1024);
   Assert(Config.Window_Size = 32768, "Xbox window override failed.");
   Put_Line("      PASS");

   -- TEST 3
   Put_Line("TEST 3 - Empty Input Handling");
   Put_Line("  3.1 Assert empty compression yields length 0");
   Compress(Config, Input_Buf(1 .. 0), Output_Buf, Out_Len);
   Assert(Out_Len = 0, "Empty compress output length not 0");
   Put_Line("      PASS");

   -- TEST 4
   Put_Line("TEST 4 - Empty Decompression Handling");
   Put_Line("  4.1 Assert empty decompression yields length 0");
   Decompress(Config, Input_Buf(1 .. 0), Output_Buf, Out_Len);
   Assert(Out_Len = 0, "Empty decompress output length not 0");
   Put_Line("      PASS");

   -- TEST 5
   Put_Line("TEST 5 - Single Character Compression");
   Put_Line("  5.1 Assert single char creates literal token (2 bytes)");
   Load_String("X", Input_Buf);
   Compress(Config, Input_Buf(1 .. 1), Output_Buf, Out_Len);
   Assert(Out_Len = 2, "Single char output size incorrect");
   Assert(Output_Buf(1) = 0 and Output_Buf(2) = Character'Pos('X'), "Literal token malformed");
   Put_Line("      PASS");

   -- TEST 6
   Put_Line("TEST 6 - Buffer Overflow Protection (Compress)");
   Put_Line("  6.1 Assert passing too small output buffer raises Buffer_Overflow");
   begin
      Load_String("ABCDEFGHIJKLMNOPQRSTUVWXYZ", Input_Buf);
      Compress(Config, Input_Buf(1 .. 26), Output_Buf(1 .. 5), Out_Len);
      Assert(False, "Expected Buffer_Overflow not raised");
   exception
      when Buffer_Overflow => Put_Line("      PASS");
   end;

   -- TEST 7
   Put_Line("TEST 7 - Invalid Data Decompression (Robustness)");
   Put_Line("  7.1 Assert malformed tokens raise LZX_Error");
   begin
      Input_Buf(1) := 99; -- Invalid token type
      Decompress(Config, Input_Buf(1 .. 1), Output_Buf, Out_Len);
      Assert(False, "Expected LZX_Error not raised for invalid token");
   exception
      when LZX_Error => Put_Line("      PASS");
   end;

   -- TEST 8
   Put_Line("TEST 8 - Highly Compressible Data (Testing R0 Match)");
   Put_Line("  8.1 Compress sequence 'AAAAAA'");
   Load_String("AAAAAA", Input_Buf);
   Compress(Config, Input_Buf(1 .. 6), Output_Buf, Out_Len);
   Put_Line("  8.2 Assert compressed size is strictly < uncompressed");
   Assert(Out_Len < 6, "Did not compress repeating sequence");
   Put_Line("      PASS");

   -- TEST 9
   Put_Line("TEST 9 - Complete Cycle: Uncompressible Data");
   Put_Line("  9.1 Assert unique string matches after compress->decompress");
   Load_String("ABCDEF12345", Input_Buf);
   Compress(Config, Input_Buf(1 .. 11), Output_Buf, Out_Len);
   Decompress(Config, Output_Buf(1 .. Out_Len), Recover_Buf, Rec_Len);
   Assert(Rec_Len = 11, "Length mismatch on recover");
   Assert(Arrays_Equal(Input_Buf, Recover_Buf, 11), "Data corrupted");
   Put_Line("      PASS");

   -- TEST 10
   Put_Line("TEST 10 - Complete Cycle: Pattern Data");
   Put_Line("  10.1 Assert ABABAB... pattern successfully cycles");
   Load_String("ABABABABABABABAB", Input_Buf);
   Compress(Config, Input_Buf(1 .. 16), Output_Buf, Out_Len);
   Decompress(Config, Output_Buf(1 .. Out_Len), Recover_Buf, Rec_Len);
   Assert(Rec_Len = 16, "Length mismatch on pattern");
   Assert(Arrays_Equal(Input_Buf, Recover_Buf, 16), "Pattern data corrupted");
   Put_Line("      PASS");

   -- TEST 11
   Put_Line("TEST 11 - R1/R2 Repeated Offset Shifting Validation");
   Put_Line("  11.1 Assert complex offset shifting doesn't break decompress");
   -- A pattern designed to force matches at varying previous offsets
   Load_String("Hello Hello Hello World World Hello", Input_Buf);
   Compress(Config, Input_Buf(1 .. 35), Output_Buf, Out_Len);
   Decompress(Config, Output_Buf(1 .. Out_Len), Recover_Buf, Rec_Len);
   Assert(Arrays_Equal(Input_Buf, Recover_Buf, 35), "Offset queue corruption");
   Put_Line("      PASS");

   -- TEST 12
   Put_Line("TEST 12 - Corrupted Match Offset Error Handling");
   Put_Line("  12.1 Assert reference to past-buffer offset raises LZX_Error");
   begin
      Input_Buf(1) := 1; -- Match
      Input_Buf(2) := 255; -- Huge offset High
      Input_Buf(3) := 255; -- Huge offset Low
      Input_Buf(4) := 5;   -- Length
      Decompress(Config, Input_Buf(1 .. 4), Output_Buf, Out_Len);
      Assert(False, "Decompress allowed out-of-bounds backward reference");
   exception
      when LZX_Error => Put_Line("      PASS");
   end;

   -- TEST 13
   Put_Line("TEST 13 - DELTA LZX Configuration");
   Put_Line("  13.1 Assert Delta initializes safely with dynamic window");
   Config := Create_Config(DELTA_LZX, 1_048_576);
   Assert(Config.Window_Size = 1_048_576, "Delta window size mismatch");
   Put_Line("      PASS");

end Tests;
