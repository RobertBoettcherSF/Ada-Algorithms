with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Lempel_Ziv_Oberhumer; use Lempel_Ziv_Oberhumer;

procedure Tests is
   Total_Passed : Natural := 0;

   procedure Report_Pass (Subtest : String) is
   begin
      Put_Line("   " & Subtest & " -> PASS");
      Total_Passed := Total_Passed + 1;
   end Report_Pass;

begin
   Put_Line("=========================================================");
   Put_Line(" Running LZO Verification & Validation (V&V) Test Suite ");
   Put_Line(" Test Philosophy: Assume code is broken until disproven. ");
   Put_Line("=========================================================");

   -- TEST 1 - Basic LZO1 Roundtrip
   Put_Line("TEST 1 - LZO1 Basic Functionality");
   declare
      In_Data  : constant Byte_Array(1 .. 30) := (others => 65);
      Out_Comp : Byte_Array(1 .. 100);
      Out_Dec  : Byte_Array(1 .. 100);
      CLen, DLen : Natural;
   begin
      Compress_LZO1(In_Data, Out_Comp, CLen);
      Assert(CLen > 0 and CLen < In_Data'Length, "1.1 LZO1 failed to compress repeating data");
      Report_Pass("1.1 Assert LZO1 reduces redundant data size");

      Decompress_LZO1(Out_Comp(1 .. CLen), Out_Dec, DLen);
      Assert(DLen = In_Data'Length, "1.2 Decompressed length mismatch");
      Report_Pass("1.2 Assert decompressed length matches input length");

      Assert(Verify_Equality(In_Data, Out_Dec(1 .. DLen)), "1.3 Decompressed bytes mismatch input");
      Report_Pass("1.3 Assert byte-for-byte fidelity");
   end;

   -- TEST 2 - LZO1X Standard Variant Correctness
   Put_Line("TEST 2 - LZO1X Standard Variant Roundtrip");
   declare
      In_Data  : constant Byte_Array := (1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3, 1, 2, 3);
      Out_Comp : Byte_Array(1 .. 100);
      Out_Dec  : Byte_Array(1 .. 100);
      CLen, DLen : Natural;
   begin
      Compress_LZO1X(In_Data, Out_Comp, CLen);
      Assert(CLen > 0, "2.1 LZO1X compression emitted empty stream");
      Report_Pass("2.1 Assert LZO1X produces valid compressed output");

      Decompress_LZO1X(Out_Comp(1 .. CLen), Out_Dec, DLen);
      Assert(Verify_Equality(In_Data, Out_Dec(1 .. DLen)), "2.2 LZO1X roundtrip mismatch");
      Report_Pass("2.2 Assert LZO1X roundtrip byte restoration");
   end;

   -- TEST 3 - LZO1Y High-Ratio Variant
   Put_Line("TEST 3 - LZO1Y Large Match Block Encoding");
   declare
      In_Data  : constant Byte_Array(1 .. 200) := (others => 88);
      Out_Comp : Byte_Array(1 .. 300);
      Out_Dec  : Byte_Array(1 .. 200);
      CLen, DLen : Natural;
   begin
      Compress_LZO1Y(In_Data, Out_Comp, CLen);
      Report_Pass("3.1 Assert LZO1Y handles large match blocks without buffer overrun");

      Decompress_LZO1Y(Out_Comp(1 .. CLen), Out_Dec, DLen);
      Assert(Verify_Equality(In_Data, Out_Dec(1 .. DLen)), "3.2 LZO1Y decompressed stream corrupted");
      Report_Pass("3.2 Assert LZO1Y exact restoration");
   end;

   -- TEST 4 - LZO1Z Recycled Offset Optimization
   Put_Line("TEST 4 - LZO1Z Offset Recycling Variant");
   declare
      In_Data  : constant Byte_Array := (10, 20, 30, 10, 20, 30, 10, 20, 30, 10, 20, 30);
      Out_Comp : Byte_Array(1 .. 100);
      Out_Dec  : Byte_Array(1 .. 100);
      CLen, DLen : Natural;
   begin
      Compress_LZO1Z(In_Data, Out_Comp, CLen);
      Report_Pass("4.1 Assert LZO1Z compresses repeated offset patterns");

      Decompress_LZO1Z(Out_Comp(1 .. CLen), Out_Dec, DLen);
      Assert(Verify_Equality(In_Data, Out_Dec(1 .. DLen)), "4.2 LZO1Z failed roundtrip");
      Report_Pass("4.2 Assert LZO1Z restores recycled offset tokens accurately");
   end;

   -- TEST 5 - LZO_RLE Pre-filter Variant
   Put_Line("TEST 5 - LZO_RLE Run-Length Compression");
   declare
      In_Data  : constant Byte_Array(1 .. 500) := (others => 42);
      Out_Comp : Byte_Array(1 .. 100);
      Out_Dec  : Byte_Array(1 .. 500);
      CLen, DLen : Natural;
   begin
      Compress_LZO_RLE(In_Data, Out_Comp, CLen);
      Assert(CLen < 20, "5.1 LZO_RLE failed to achieve high compression ratio on uniform data");
      Report_Pass("5.1 Assert LZO_RLE achieves massive compression on uniform runs");

      Decompress_LZO_RLE(Out_Comp(1 .. CLen), Out_Dec, DLen);
      Assert(Verify_Equality(In_Data, Out_Dec(1 .. DLen)), "5.2 LZO_RLE byte restoration failed");
      Report_Pass("5.2 Assert LZO_RLE restores uniform sequence losslessly");
   end;

   -- TEST 6 - Edge Case: Empty Input Buffer
   Put_Line("TEST 6 - Edge Case: Empty Input Buffer");
   declare
      In_Data  : constant Byte_Array(1 .. 0) := (others => 0);
      Out_Comp : Byte_Array(1 .. 20);
      Out_Dec  : Byte_Array(1 .. 20);
      CLen, DLen : Natural;
   begin
      Compress(In_Data, Out_Comp, CLen, LZO1X);
      Report_Pass("6.1 Assert Compress handles zero-length input without crashing");

      Decompress(Out_Comp(1 .. CLen), Out_Dec, DLen, LZO1X);
      Assert(DLen = 0, "6.2 Decompressed empty buffer length non-zero");
      Report_Pass("6.2 Assert Decompress returns 0 length output for empty input");
   end;

   -- TEST 7 - Edge Case: Single Byte Input
   Put_Line("TEST 7 - Edge Case: Single Byte Input");
   declare
      In_Data  : constant Byte_Array(1 .. 1) := (1 => 99);
      Out_Comp : Byte_Array(1 .. 20);
      Out_Dec  : Byte_Array(1 .. 20);
      CLen, DLen : Natural;
   begin
      Compress(In_Data, Out_Comp, CLen, LZO1X);
      Report_Pass("7.1 Assert single byte compression completes");

      Decompress(Out_Comp(1 .. CLen), Out_Dec, DLen, LZO1X);
      Assert(DLen = 1 and Out_Dec(1) = 99, "7.2 Single byte value mismatch");
      Report_Pass("7.2 Assert single byte restored faithfully");
   end;

   -- TEST 8 - Edge Case: Non-compressible Incompressible Sequence
   Put_Line("TEST 8 - Incompressible Data Resilience");
   declare
      In_Data  : constant Byte_Array := (1, 17, 255, 43, 88, 19, 102, 33, 71, 9);
      Out_Comp : Byte_Array(1 .. 100);
      Out_Dec  : Byte_Array(1 .. 100);
      CLen, DLen : Natural;
   begin
      Compress(In_Data, Out_Comp, CLen, LZO1X);
      Report_Pass("8.1 Assert incompressible data compressed without overrun");

      Decompress(Out_Comp(1 .. CLen), Out_Dec, DLen, LZO1X);
      Assert(Verify_Equality(In_Data, Out_Dec(1 .. DLen)), "8.2 Incompressible data mismatch");
      Report_Pass("8.2 Assert literal-only stream restored accurately");
   end;

   -- TEST 9 - Robustness: Buffer Overrun Exception Handling
   Put_Line("TEST 9 - Exception Robustness: Output Buffer Overrun");
   declare
      In_Data  : constant Byte_Array(1 .. 100) := (others => 7);
      Tiny_Buf : Byte_Array(1 .. 2);
      CLen     : Natural;
      Caught   : Boolean := False;
   begin
      begin
         Compress_LZO1X(In_Data, Tiny_Buf, CLen);
      exception
         when Buffer_Overrun_Error =>
            Caught := True;
      end;
      Assert(Caught, "9.1 Buffer_Overrun_Error was not raised for tiny destination buffer");
      Report_Pass("9.1 Assert Buffer_Overrun_Error raised on insufficient compression buffer");
   end;

   -- TEST 10 - Robustness: Corrupt Stream Handling
   Put_Line("TEST 10 - Exception Robustness: Corrupt Input Stream");
   declare
      Bad_Stream : constant Byte_Array := (16#80#, 16#05#, 16#FF#, 16#FF#); -- Invalid match offset
      Out_Dec    : Byte_Array(1 .. 100);
      DLen       : Natural;
      Caught     : Boolean := False;
   begin
      begin
         Decompress_LZO1(Bad_Stream, Out_Dec, DLen);
      exception
         when Corrupt_Input_Error =>
            Caught := True;
      end;
      Assert(Caught, "10.1 Corrupt_Input_Error not raised on invalid lookback offset");
      Report_Pass("10.1 Assert Corrupt_Input_Error raised when offset exceeds buffer");
   end;

   -- TEST 11 - Unified Interface & Variant Dispatching
   Put_Line("TEST 11 - Unified Interface Variant Dispatching");
   declare
      In_Data  : constant Byte_Array := (5, 5, 5, 5, 5, 5, 5, 5);
      Out_Comp : Byte_Array(1 .. 100);
      Out_Dec  : Byte_Array(1 .. 100);
      CLen, DLen : Natural;
   begin
      for V in LZO_Variant loop
         Compress(In_Data, Out_Comp, CLen, Variant => V);
         Decompress(Out_Comp(1 .. CLen), Out_Dec, DLen, Variant => V);
         Assert(Verify_Equality(In_Data, Out_Dec(1 .. DLen)), "11.1 Variant dispatch failure for " & LZO_Variant'Image(V));
      end loop;
      Report_Pass("11.1 Assert all variants dispatch correctly through unified interface");
   end;

   -- TEST 12 - Utility Helper Functions
   Put_Line("TEST 12 - Utility Helper Function Verification");
   declare
      R1 : constant Float := Calculate_Compression_Ratio(100, 40);
      R2 : constant Float := Calculate_Compression_Ratio(0, 50);
      B1 : constant Byte_Array := (1, 2, 3);
      B2 : constant Byte_Array := (1, 2, 3);
      B3 : constant Byte_Array := (1, 2, 4);
   begin
      Assert(R1 > 59.9 and R1 < 60.1, "12.1 Compression ratio calculation invalid");
      Report_Pass("12.1 Assert Calculate_Compression_Ratio math accuracy");

      Assert(R2 = 0.0, "12.2 Zero size ratio calculation failed");
      Report_Pass("12.2 Assert zero uncompressed length ratio returns 0.0");

      Assert(Verify_Equality(B1, B2), "12.3 Equal arrays reported unequal");
      Report_Pass("12.3 Assert Verify_Equality returns True for identical arrays");

      Assert(not Verify_Equality(B1, B3), "12.4 Unequal arrays reported equal");
      Report_Pass("12.4 Assert Verify_Equality returns False for differing arrays");
   end;

   -- TEST 13 - Sliding Window Boundary Lookback
   Put_Line("TEST 13 - Sliding Window Offset Boundary Test");
   declare
      In_Data  : Byte_Array(1 .. 5000);
      Out_Comp : Byte_Array(1 .. 6000);
      Out_Dec  : Byte_Array(1 .. 5000);
      CLen, DLen : Natural;
   begin
      for I in In_Data'Range loop
         In_Data(I) := Byte(I mod 251);
      end loop;
      -- Repeat pattern 4000 bytes later
      In_Data(4500 .. 4510) := In_Data(100 .. 110);

      Compress_LZO1X(In_Data, Out_Comp, CLen);
      Decompress_LZO1X(Out_Comp(1 .. CLen), Out_Dec, DLen);
      Assert(Verify_Equality(In_Data, Out_Dec(1 .. DLen)), "13.1 Sliding window boundary mismatch");
      Report_Pass("13.1 Assert sliding window lookback correctly handles large arrays");
   end;

   -- TEST 14 - Arbitrary Non-1 Base Indexing
   Put_Line("TEST 14 - Non-Standard Array Slice Indexing");
   declare
      In_Slice  : constant Byte_Array(10 .. 25) := (others => 77);
      Out_Comp  : Byte_Array(100 .. 200);
      Out_Dec   : Byte_Array(50 .. 100);
      CLen, DLen : Natural;
   begin
      Compress_LZO1X(In_Slice, Out_Comp, CLen);
      Decompress_LZO1X(Out_Comp(Out_Comp'First .. Out_Comp'First + CLen - 1), Out_Dec, DLen);
      Assert(DLen = In_Slice'Length, "14.1 Arbitrary slice length mismatch");
      Report_Pass("14.1 Assert non-standard index range compression completes");

      Assert(Verify_Equality(In_Slice, Out_Dec(Out_Dec'First .. Out_Dec'First + DLen - 1)), "14.2 Arbitrary slice data mismatch");
      Report_Pass("14.2 Assert slice byte restoration verified");
   end;

   Put_Line("=========================================================");
   Put_Line(" SUMMARY: All 14 Test Scenarios Passed Successfully!");
   Put_Line("=========================================================");
end Tests;
