with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Three_Dc; use Three_Dc;

procedure Tests is
   Blk_In_1D, Blk_Out_1D : Block_1D := (others => 0);
   Comp_1D : Compressed_Block_1D;
   
   Blk_In_2D, Blk_Out_2D : Block_2D;
   Comp_2D : Compressed_Block_2D;
   
   Z_Out : Block_Z;
   
   -- Helper to assert array equality
   function Check_1D_Match (A, B : Block_1D; Tolerance : Integer) return Boolean is
   begin
      for I in A'Range loop
         if abs (Integer(A(I)) - Integer(B(I))) > Tolerance then
            return False;
         end if;
      end loop;
      return True;
   end Check_1D_Match;

begin
   Put_Line ("Starting 3Dc Algorithm Test Suite...");
   
   -- TEST 1 - 3Dc+ Flat Block Handling
   Put_Line ("TEST 1 - 3Dc+ Compress/Decompress Flat Block");
   Blk_In_1D := (others => 128);
   Compress_3Dc_Plus (Blk_In_1D, Comp_1D);
   Decompress_3Dc_Plus (Comp_1D, Blk_Out_1D);
   Assert (Check_1D_Match(Blk_In_1D, Blk_Out_1D, 0), "Flat block decompression failed");
   Put_Line ("      PASS");

   -- TEST 2 - 3Dc+ Min/Max Extraction
   Put_Line ("TEST 2 - 3Dc+ Exact Endpoints");
   Blk_In_1D(0) := 10; Blk_In_1D(15) := 240;
   Compress_3Dc_Plus (Blk_In_1D, Comp_1D);
   Assert (Comp_1D(0) = 240 and Comp_1D(1) = 10, "Endpoints not extracted correctly");
   Put_Line ("      PASS");

   -- TEST 3 - 3Dc+ Gradient Approximation
   Put_Line ("TEST 3 - 3Dc+ Gradient Tolerance");
   for I in Blk_In_1D'Range loop Blk_In_1D(I) := Byte(I * 16); end loop;
   Compress_3Dc_Plus (Blk_In_1D, Comp_1D);
   Decompress_3Dc_Plus (Comp_1D, Blk_Out_1D);
   Assert (Check_1D_Match(Blk_In_1D, Blk_Out_1D, 18), "Gradient decompressed out of tolerance");
   Put_Line ("      PASS");

   -- TEST 4 - 3Dc 2D Channel Independence
   Put_Line ("TEST 4 - 3Dc Dual Channel Independence");
   Blk_In_2D.X := (others => 0);
   Blk_In_2D.Y := (others => 255);
   Compress_3Dc (Blk_In_2D, Comp_2D);
   Assert (Comp_2D.X(0) /= Comp_2D.Y(0), "Channels X and Y affected each other");
   Put_Line ("      PASS");

   -- TEST 5 - 3Dc 2D Reconstruction Integrity
   Put_Line ("TEST 5 - 3Dc Dual Channel Integrity");
   Decompress_3Dc (Comp_2D, Blk_Out_2D);
   Assert (Blk_Out_2D.X(0) = 0 and Blk_Out_2D.Y(0) = 255, "Dual channel corrupted on decode");
   Put_Line ("      PASS");

   -- TEST 6 - Z Reconstruction: Flat normal
   Put_Line ("TEST 6 - Z Reconstruction (Flat Normal)");
   Blk_In_1D := (others => 127); -- Approx 0 in float space
   Reconstruct_Z (Blk_In_1D, Blk_In_1D, Z_Out);
   Assert (Z_Out(0) > 0.99, "Flat normal Z is not ~1.0");
   Put_Line ("      PASS");

   -- TEST 7 - Z Reconstruction: Extreme angle
   Put_Line ("TEST 7 - Z Reconstruction (Extreme X)");
   Blk_In_2D.X := (others => 255);
   Blk_In_2D.Y := (others => 127);
   Reconstruct_Z (Blk_In_2D.X, Blk_In_2D.Y, Z_Out);
   Assert (Z_Out(0) < 0.1, "Extreme angle Z is not ~0.0");
   Put_Line ("      PASS");

   -- TEST 8 - Z Reconstruction: Clamping/Negative Root
   Put_Line ("TEST 8 - Z Reconstruction Clamping (X^2+Y^2 > 1)");
   Blk_In_2D.X := (others => 255);
   Blk_In_2D.Y := (others => 255);
   Reconstruct_Z (Blk_In_2D.X, Blk_In_2D.Y, Z_Out);
   Assert (Z_Out(0) = 0.0, "Z did not clamp to 0 on invalid length");
   Put_Line ("      PASS");

   -- TEST 9 - Boundary: All Zeros
   Put_Line ("TEST 9 - All Zeros Encoding");
   Blk_In_1D := (others => 0);
   Compress_3Dc_Plus (Blk_In_1D, Comp_1D);
   Decompress_3Dc_Plus (Comp_1D, Blk_Out_1D);
   Assert (Blk_Out_1D(5) = 0, "Zero block decode failed");
   Put_Line ("      PASS");

   -- TEST 10 - Boundary: All 255s
   Put_Line ("TEST 10 - All 255s Encoding");
   Blk_In_1D := (others => 255);
   Compress_3Dc_Plus (Blk_In_1D, Comp_1D);
   Decompress_3Dc_Plus (Comp_1D, Blk_Out_1D);
   Assert (Blk_Out_1D(5) = 255, "255 block decode failed");
   Put_Line ("      PASS");

   -- TEST 11 - 3Dc+ Edge Case Palette Reordering
   Put_Line ("TEST 11 - Palette Order Robustness");
   Blk_In_1D(0) := 255; Blk_In_1D(1) := 255; Blk_In_1D(2) := 254;
   Compress_3Dc_Plus(Blk_In_1D, Comp_1D);
   Assert (Comp_1D(0) = 255 and Comp_1D(1) = 254, "Min/max extraction failed on close values");
   Put_Line ("      PASS");

   -- TEST 12 - Reconstruct Z with Y axis dominance
   Put_Line ("TEST 12 - Z Reconstruction (Dominant Y)");
   Blk_In_2D.X := (others => 127);
   Blk_In_2D.Y := (others => 0);
   Reconstruct_Z (Blk_In_2D.X, Blk_In_2D.Y, Z_Out);
   Assert (Z_Out(0) < 0.1, "Dominant Y Z calculation failed");
   Put_Line ("      PASS");
   
   -- TEST 13 - Mixed Noise Tolerance
   Put_Line ("TEST 13 - Mixed Noise Stability");
   Blk_In_1D := (10, 20, 250, 15, 128, 64, 32, 200, 210, 50, 60, 70, 80, 90, 100, 110);
   Compress_3Dc_Plus(Blk_In_1D, Comp_1D);
   Decompress_3Dc_Plus(Comp_1D, Blk_Out_1D);
   Assert (Blk_Out_1D(2) > 200, "High noise spike not preserved in endpoints");
   Put_Line ("      PASS");
   
   Put_Line ("All 13 Tests Passed successfully.");
end Tests;
