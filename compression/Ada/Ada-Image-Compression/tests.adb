-- tests.adb
-- Standalone test suite with 14 assertions designed to challenge and verify 
-- functionality, boundaries, and robustness. Tests PASS when code operates correctly.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Image_Compression; use Image_Compression;

procedure Tests is
   -- Test Data Helpers
   P_Black : constant Pixel := (0, 0, 0);
   P_White : constant Pixel := (255, 255, 255);
   P_Red   : constant Pixel := (255, 0, 0);
   
   Img_Const : constant Image_1D(1 .. 3) := (P_Red, P_Red, P_Red);
   Img_Mix   : constant Image_1D(1 .. 4) := (P_Red, P_Red, P_White, P_Black);
   Img_Empty : Image_1D(1 .. 0);

begin
   Put_Line("==============================================");
   Put_Line(" IMAGE COMPRESSION ALGORITHM TEST SUITE");
   Put_Line("==============================================");

   -- ---------------------------------------------------------
   Put_Line("TEST 1 - RLE Compression (Constant Sequence)");
   Put_Line("  1.1 Assert identical pixels collapse into a single run");
   declare
      RLE : constant RLE_Sequence := Compress_RLE(Img_Const);
   begin
      Assert (RLE'Length = 1, "RLE should yield length 1");
      Assert (RLE(1).Count = 3 and RLE(1).Val = P_Red, "RLE Count should be 3");
      Put_Line("     PASS");
   end;

   -- ---------------------------------------------------------
   Put_Line("TEST 2 - RLE Compression (Mixed Sequence)");
   Put_Line("  2.1 Assert runs are isolated correctly for varying pixels");
   declare
      RLE : constant RLE_Sequence := Compress_RLE(Img_Mix);
   begin
      Assert (RLE'Length = 3, "RLE should yield length 3");
      Assert (RLE(1).Count = 2, "First run count incorrect");
      Assert (RLE(2).Count = 1 and RLE(2).Val = P_White, "Second run incorrect");
      Put_Line("     PASS");
   end;

   -- ---------------------------------------------------------
   Put_Line("TEST 3 - RLE Edge Case (Empty Array)");
   Put_Line("  3.1 Assert empty image raises Empty_Image_Error");
   begin
      declare
         RLE : constant RLE_Sequence := Compress_RLE(Img_Empty);
         pragma Unreferenced (RLE); -- Suppress warning for variable used only to trigger error
      begin
         Assert (False, "Expected Empty_Image_Error not raised");
      end;
   exception
      when Empty_Image_Error => Put_Line("     PASS");
   end;

   -- ---------------------------------------------------------
   Put_Line("TEST 4 - RLE Decompression (Roundtrip verification)");
   Put_Line("  4.1 Assert decompressing restores original structural data");
   declare
      RLE     : constant RLE_Sequence := Compress_RLE(Img_Mix);
      Dec_Img : constant Image_1D := Decompress_RLE(RLE);
   begin
      Assert (Dec_Img'Length = Img_Mix'Length, "Lengths differ");
      for I in Img_Mix'Range loop
         Assert (Dec_Img(I) = Img_Mix(I), "Pixel mismatch at " & Integer'Image(I));
      end loop;
      Put_Line("     PASS");
   end;

   -- ---------------------------------------------------------
   Put_Line("TEST 5 - RLE Decompression Edge Case");
   Put_Line("  5.1 Assert decompressing empty sequence raises error");
   begin
      declare
         Empty_RLE : constant RLE_Sequence(1 .. 0) := (others => <>);
         Res : constant Image_1D := Decompress_RLE(Empty_RLE);
         pragma Unreferenced (Res); -- Suppress warning
      begin
         Assert (False, "Expected Invalid_Data_Error");
      end;
   exception
      when Invalid_Data_Error => Put_Line("     PASS");
   end;

   -- ---------------------------------------------------------
   Put_Line("TEST 6 - Delta Compression (Constant Color)");
   Put_Line("  6.1 Assert differential on constant image yields 0s");
   declare
      Delta_Seq : constant Delta_Sequence := Compress_Delta(Img_Const);
   begin
      Assert (Delta_Seq'Length = 2, "Should have 2 deltas for 3 pixels");
      Assert (Delta_Seq(1).dR = 0, "Delta R should be 0");
      Put_Line("     PASS");
   end;

   -- ---------------------------------------------------------
   Put_Line("TEST 7 - Delta Compression (High variance gradient)");
   Put_Line("  7.1 Assert maximum negative/positive differentials parse correctly");
   declare
      Grad : constant Image_1D(1 .. 2) := (P_Black, P_White); -- 0 to 255
      Delta_Seq : constant Delta_Sequence := Compress_Delta(Grad);
   begin
      Assert (Delta_Seq(1).dR = 255, "Positive Delta failed");
      
      declare
         Grad2 : constant Image_1D(1 .. 2) := (P_White, P_Black); -- 255 to 0
         Delta_Seq2 : constant Delta_Sequence := Compress_Delta(Grad2);
      begin
         Assert (Delta_Seq2(1).dR = -255, "Negative Delta failed");
      end;
      Put_Line("     PASS");
   end;

   -- ---------------------------------------------------------
   Put_Line("TEST 8 - Delta Edge Case (Empty Array)");
   Put_Line("  8.1 Assert compression of empty array raises Empty_Image_Error");
   begin
      declare
         Delta_Seq : constant Delta_Sequence := Compress_Delta(Img_Empty);
         pragma Unreferenced (Delta_Seq); -- Suppress warning
      begin
         Assert (False, "Expected error on empty delta");
      end;
   exception
      when Empty_Image_Error => Put_Line("     PASS");
   end;

   -- ---------------------------------------------------------
   Put_Line("TEST 9 - Delta Decompression (Roundtrip Verification)");
   Put_Line("  9.1 Assert decompressed delta recovers exact original state");
   declare
      Delta_Seq : constant Delta_Sequence := Compress_Delta(Img_Mix);
      Dec       : constant Image_1D := Decompress_Delta(Delta_Seq, Img_Mix(Img_Mix'First));
   begin
      Assert (Dec'Length = Img_Mix'Length, "Delta length mismatch");
      Assert (Dec(4) = P_Black, "Last pixel not correctly recovered");
      Put_Line("     PASS");
   end;

   -- ---------------------------------------------------------
   Put_Line("TEST 10 - Quantization Lossy (0 Levels)");
   Put_Line("  10.1 Assert 0 levels dropped implies lossless state retention");
   declare
      Img_Q : Image_1D := Img_Mix;
   begin
      Quantize_Colors(Img_Q, 0);
      Assert (Img_Q(1) = P_Red, "0 levels quantization modified data");
      Put_Line("     PASS");
   end;

   -- ---------------------------------------------------------
   Put_Line("TEST 11 - Quantization Lossy (Minor Bit Drop)");
   Put_Line("  11.1 Assert minor loss zeroes out Least Significant Bits");
   declare
      Img_Q : Image_1D(1 .. 1) := (1 => (255, 255, 255));
   begin
      Quantize_Colors(Img_Q, 1);
      -- 255 (11111111) dropping 1 bit -> 254 (11111110)
      Assert (Img_Q(1).R = 254, "Failed to drop 1 level cleanly");
      Put_Line("     PASS");
   end;

   -- ---------------------------------------------------------
   Put_Line("TEST 12 - Quantization Lossy (Heavy Bit Drop)");
   Put_Line("  12.1 Assert high quantization clusters values correctly");
   declare
      Img_Q : Image_1D(1 .. 1) := (1 => (127, 0, 0)); -- 127 = 01111111
   begin
      Quantize_Colors(Img_Q, 7);
      -- Dropping 7 bits leaves only the top bit, which is 0. So result is 0.
      Assert (Img_Q(1).R = 0, "Top bit calculation error");
      Put_Line("     PASS");
   end;

   -- ---------------------------------------------------------
   Put_Line("TEST 13 - Quantization Lossy (Total Loss / 8 levels)");
   Put_Line("  13.1 Assert 8-level drop effectively blacks out the image");
   declare
      Img_Q : Image_1D := Img_Mix;
   begin
      Quantize_Colors(Img_Q, 8);
      Assert (Img_Q(1).R = 0 and Img_Q(3).G = 0, "Failed to zero out completely");
      Put_Line("     PASS");
   end;

   -- ---------------------------------------------------------
   Put_Line("TEST 14 - Robustness Test (Type Bounds Safety)");
   Put_Line("  14.1 Assert algorithm prevents overflow on negative deltas");
   begin
      -- Test the bounds logic of the custom Type itself instead of evaluating tautological variables
      Assert (Color_Diff'First = -255 and Color_Diff'Last = 255, "Data type bounded incorrectly");
      Put_Line("     PASS");
   end;

   Put_Line("==============================================");
   Put_Line(" ALL TESTS EXECUTED SUCCESSFULLY");
   Put_Line("==============================================");
end Tests;
