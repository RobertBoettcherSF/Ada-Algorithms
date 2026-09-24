-- tests.adb
-- Standalone test suite for Audio Compression algorithms.
-- Tests assume code is broken; PASSing disproves the assumption.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Audio_Compression; use Audio_Compression;

procedure Tests is
   Empty_Buffer : constant Buffer_16 (1 .. 0) := (others => 0);
   Normal_Buffer : constant Buffer_16 := (100, 200, 150, 50, -50);
   Extreme_Buffer : constant Buffer_16 := (-32768, 32767, -32768);
   
   Encoded_Buf, Decoded_Buf : Buffer_16 (1 .. 5);
begin
   Put_Line("===========================================");
   Put_Line("STARTING AUDIO COMPRESSION V&V TEST SUITE");
   Put_Line("===========================================");
   
   -- TEST 1: Mu-Law Zero
   Put_Line("TEST 1 - Mu-Law Zero Boundary");
   Put_Line("  1.1 Assert encoding absolute silence (0) yields 0");
   Assert (Encode_Mu_Law(0) = 0, "Mu-Law 0 encoding failed");
   Put_Line("  1.2 Assert decoding zero yields 0");
   Assert (Decode_Mu_Law(0) = 0, "Mu-Law 0 decoding failed");
   Put_Line("     PASS");

   -- TEST 2: Mu-Law Maximum Boundary
   Put_Line("TEST 2 - Mu-Law Maximum Positive Boundary");
   Put_Line("  2.1 Assert encoding Max PCM (32767) maps to Max 8-bit (127)");
   Assert (Encode_Mu_Law(32767) = 127, "Mu-Law max positive clipping failed");
   Put_Line("     PASS");

   -- TEST 3: Mu-Law Minimum Boundary
   Put_Line("TEST 3 - Mu-Law Minimum Negative Boundary");
   Put_Line("  3.1 Assert encoding Min PCM (-32768) maps to Min 8-bit (-128)");
   Assert (Encode_Mu_Law(-32768) = -128, "Mu-Law min negative clipping failed");
   Put_Line("     PASS");

   -- TEST 4: A-Law Zero
   Put_Line("TEST 4 - A-Law Zero Boundary");
   Put_Line("  4.1 Assert encoding absolute silence (0) yields 0");
   Assert (Encode_A_Law(0) = 0, "A-Law 0 encoding failed");
   Put_Line("  4.2 Assert decoding zero yields 0");
   Assert (Decode_A_Law(0) = 0, "A-Law 0 decoding failed");
   Put_Line("     PASS");

   -- TEST 5: A-Law Boundaries
   Put_Line("TEST 5 - A-Law Extremes");
   Put_Line("  5.1 Assert encoding Max PCM maps to 127");
   Assert (Encode_A_Law(32767) = 127, "A-law max failed");
   Put_Line("  5.2 Assert encoding Min PCM maps to -128");
   Assert (Encode_A_Law(-32768) = -128, "A-law min failed");
   Put_Line("     PASS");

   -- TEST 6: Mu-Law Round-Trip Tolerance
   Put_Line("TEST 6 - Mu-Law Lossy Round-Trip Stability");
   Put_Line("  6.1 Assert that compressing and expanding 1000 stays within acceptable loss limits");
   declare
      Original : constant PCM_16 := 1000;
      Compressed : constant PCM_8 := Encode_Mu_Law(Original);
      Expanded : constant PCM_16 := Decode_Mu_Law(Compressed);
      Diff : constant Integer := abs(Integer(Original) - Integer(Expanded));
   begin
      -- Lossy compression shouldn't distort small values massively
      Assert (Diff < 100, "Mu-Law roundtrip variance too high");
      Put_Line("     PASS");
   end;

   -- TEST 7: DPCM Empty Buffer Edge Case
   Put_Line("TEST 7 - DPCM Empty Buffer Handling");
   Put_Line("  7.1 Assert encoding an empty array does not throw exceptions");
   Assert (Encode_DPCM(Empty_Buffer)'Length = 0, "DPCM empty encode failed");
   Put_Line("  7.2 Assert decoding an empty array does not throw exceptions");
   Assert (Decode_DPCM(Empty_Buffer)'Length = 0, "DPCM empty decode failed");
   Put_Line("     PASS");

   -- TEST 8: DPCM Encoding Math
   Put_Line("TEST 8 - DPCM Linear Encoding Correctness");
   Put_Line("  8.1 Assert differences are calculated correctly");
   Encoded_Buf := Encode_DPCM(Normal_Buffer);
   Assert (Encoded_Buf(1) = 100, "DPCM Index 1 failed (100 - 0)");
   Assert (Encoded_Buf(2) = 100, "DPCM Index 2 failed (200 - 100)");
   Assert (Encoded_Buf(3) = -50, "DPCM Index 3 failed (150 - 200)");
   Put_Line("     PASS");

   -- TEST 9: DPCM Decoding Math
   Put_Line("TEST 9 - DPCM Linear Decoding Correctness");
   Put_Line("  9.1 Assert encoded buffer perfectly reconstructs normal buffer");
   Decoded_Buf := Decode_DPCM(Encoded_Buf);
   for I in Normal_Buffer'Range loop
      Assert (Decoded_Buf(I) = Normal_Buffer(I), "DPCM reconstruction failed at index " & I'Img);
   end loop;
   Put_Line("     PASS");

   -- TEST 10: DPCM Extreme Delta Clipping
   Put_Line("TEST 10 - DPCM Overflow/Clipping Handling");
   Put_Line("  10.1 Assert a delta > 32767 is clamped safely without Constraint_Error");
   declare
      Clipped : constant Buffer_16 := Encode_DPCM(Extreme_Buffer);
   begin
      -- 32767 - (-32768) = 65535 (Clamped to 32767)
      Assert (Clipped(2) = 32767, "DPCM max delta clamp failed");
      Put_Line("     PASS");
   end;

   -- TEST 11: A-Law Round-Trip Stability
   Put_Line("TEST 11 - A-Law Round-Trip Stability");
   Put_Line("  11.1 Assert compression/expansion cycle handles standard signals without catastrophic degradation");
   declare
      Orig : constant PCM_16 := 5000;
      Comp : constant PCM_8 := Encode_A_Law(Orig);
      Expd : constant PCM_16 := Decode_A_Law(Comp);
   begin
      Assert (abs(Integer(Orig) - Integer(Expd)) < 300, "A-law distortion exceeded bounds");
      Put_Line("     PASS");
   end;

   -- TEST 12: DPCM Single Element Boundary
   Put_Line("TEST 12 - DPCM Single Element Buffer");
   Put_Line("  12.1 Assert 1-length buffer encodes as just the single value");
   declare
      Single : constant Buffer_16(1..1) := (1 => 42);
      Res : constant Buffer_16 := Encode_DPCM(Single);
   begin
      Assert (Res(1) = 42, "Single element encode failed");
      Put_Line("     PASS");
   end;
   
   -- TEST 13: DPCM Negative Signal Encoding
   Put_Line("TEST 13 - DPCM Negative Space Crossing");
   Put_Line("  13.1 Assert signal crossing 0 is differenced accurately");
   declare
      Cross : constant Buffer_16(1..3) := (10, 0, -10);
      Res : constant Buffer_16 := Encode_DPCM(Cross);
   begin
      Assert (Res(2) = -10, "Cross to 0 failed");
      Assert (Res(3) = -10, "Cross to negative failed");
      Put_Line("     PASS");
   end;

   Put_Line("===========================================");
   Put_Line("ALL TESTS COMPLETED SUCCESSFULLY");
   Put_Line("===========================================");
end Tests;
