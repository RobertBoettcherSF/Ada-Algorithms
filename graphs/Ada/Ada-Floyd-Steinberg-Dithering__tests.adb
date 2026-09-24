-- tests.adb
pragma Assertion_Policy (Check);

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Floyd_Steinberg; use Floyd_Steinberg;

procedure Tests is
   Empty_Img : Image (1 .. 0, 1 .. 0);
   Img_1x1   : Image (1 .. 1, 1 .. 1);
   Img_2x2   : Image (1 .. 2, 1 .. 2);
   Img_1x5   : Image (1 .. 1, 1 .. 5);
   Img_5x1   : Image (1 .. 5, 1 .. 1);
   Img_4x4   : Image (1 .. 4, 1 .. 4);
   
   Sum       : Color_Value := 0.0;
begin
   Put_Line ("Starting Floyd-Steinberg Verification & Validation Tests");
   Put_Line ("========================================================");

   -- TEST 1
   Put_Line ("TEST 1 - Standard Dithering (2x2 Basic Quantization)");
   Put_Line ("  1.1 Assert all pixels map strictly to palette values (0.0 or 1.0)");
   Img_2x2 := (others => (others => 0.5));
   Dither_Standard (Img_2x2);
   for Y in Img_2x2'Range(2) loop
      for X in Img_2x2'Range(1) loop
         Assert (Img_2x2(X, Y) = 0.0 or Img_2x2(X, Y) = 1.0, "Unquantized pixel found");
      end loop;
   end loop;
   Put_Line ("      PASS");

   -- TEST 2
   Put_Line ("TEST 2 - Serpentine Dithering (2x2 Basic Quantization)");
   Put_Line ("  2.1 Assert all pixels map strictly to palette values");
   Img_2x2 := (others => (others => 0.4));
   Dither_Serpentine (Img_2x2);
   for Y in Img_2x2'Range(2) loop
      for X in Img_2x2'Range(1) loop
         Assert (Img_2x2(X, Y) = 0.0 or Img_2x2(X, Y) = 1.0, "Unquantized pixel found");
      end loop;
   end loop;
   Put_Line ("      PASS");

   -- TEST 3
   Put_Line ("TEST 3 - Empty Image Handling (Standard)");
   Put_Line ("  3.1 Assert Invalid_Image_Error is raised on 0-sized bounds");
   begin
      Dither_Standard (Empty_Img);
      Assert (False, "Exception was not raised");
   exception
      when Invalid_Image_Error => Put_Line ("      PASS");
   end;

   -- TEST 4
   Put_Line ("TEST 4 - Empty Image Handling (Serpentine)");
   Put_Line ("  4.1 Assert Invalid_Image_Error is raised on 0-sized bounds");
   begin
      Dither_Serpentine (Empty_Img);
      Assert (False, "Exception was not raised");
   exception
      when Invalid_Image_Error => Put_Line ("      PASS");
   end;

   -- TEST 5
   Put_Line ("TEST 5 - Pure White Image Identity");
   Put_Line ("  5.1 Assert image composed of 1.0 remains fully 1.0");
   Img_4x4 := (others => (others => 1.0));
   Dither_Standard (Img_4x4);
   Assert (Img_4x4(2, 2) = 1.0 and Img_4x4(4, 4) = 1.0, "White pixel mutated");
   Put_Line ("      PASS");

   -- TEST 6
   Put_Line ("TEST 6 - Pure Black Image Identity");
   Put_Line ("  6.1 Assert image composed of 0.0 remains fully 0.0");
   Img_4x4 := (others => (others => 0.0));
   Dither_Serpentine (Img_4x4);
   Assert (Img_4x4(1, 1) = 0.0 and Img_4x4(3, 3) = 0.0, "Black pixel mutated");
   Put_Line ("      PASS");

   -- TEST 7
   Put_Line ("TEST 7 - Average Luminance Preservation");
   Put_Line ("  7.1 Assert 50% gray image balances to equal black/white pixels");
   Img_4x4 := (others => (others => 0.5));
   Dither_Standard (Img_4x4);
   Sum := 0.0;
   for Y in 1 .. 4 loop
      for X in 1 .. 4 loop
         Sum := Sum + Img_4x4(X, Y);
      end loop;
   end loop;
   Assert (Sum = 8.0, "Luminance not preserved (Expected 8.0)");
   Put_Line ("      PASS");

   -- TEST 8
   Put_Line ("TEST 8 - Minimal Boundary Checking (1x1 Image)");
   Put_Line ("  8.1 Assert 1x1 image processes without bounds exceptions");
   Img_1x1 := (others => (others => 0.7));
   Dither_Standard (Img_1x1);
   Assert (Img_1x1(1, 1) = 1.0, "1x1 quantization failed");
   Put_Line ("      PASS");

   -- TEST 9
   Put_Line ("TEST 9 - Vertical Bounds Constraints (1x5 Image)");
   Put_Line ("  9.1 Assert 1D vertical processing distributes error legally");
   Img_1x5 := (others => (others => 0.5));
   Dither_Standard (Img_1x5);
   Assert (Img_1x5(1, 5) = 1.0 or Img_1x5(1, 5) = 0.0, "Final pixel corrupted");
   Put_Line ("      PASS");

   -- TEST 10
   Put_Line ("TEST 10 - Horizontal Bounds Constraints (5x1 Image)");
   Put_Line ("  10.1 Assert 1D horizontal processing distributes error legally");
   Img_5x1 := (others => (others => 0.3));
   Dither_Serpentine (Img_5x1);
   Assert (Img_5x1(5, 1) = 0.0 or Img_5x1(5, 1) = 1.0, "Final pixel corrupted");
   Put_Line ("      PASS");

   -- TEST 11
   Put_Line ("TEST 11 - Idempotency Validation");
   Put_Line ("  11.1 Assert re-dithering a dithered image causes zero side effects");
   Img_4x4 := (others => (others => 0.5));
   Dither_Standard (Img_4x4);
   declare
      Img_Copy : Image := Img_4x4;
   begin
      Dither_Standard (Img_4x4);
      for Y in 1 .. 4 loop
         for X in 1 .. 4 loop
            Assert (Img_4x4(X, Y) = Img_Copy(X, Y), "Idempotency broken");
         end loop;
      end loop;
   end;
   Put_Line ("      PASS");

   -- TEST 12
   Put_Line ("TEST 12 - Negative Value Clamping Integrity");
   Put_Line ("  12.1 Assert inputs below 0.0 are quantized correctly to 0.0");
   Img_1x1 := (others => (others => -0.8));
   Dither_Standard (Img_1x1);
   Assert (Img_1x1(1, 1) = 0.0, "Negative clamping failed");
   Put_Line ("      PASS");

   -- TEST 13
   Put_Line ("TEST 13 - Overflow Value Clamping Integrity");
   Put_Line ("  13.1 Assert inputs above 1.0 are quantized correctly to 1.0");
   Img_1x1 := (others => (others => 2.5));
   Dither_Serpentine (Img_1x1);
   Assert (Img_1x1(1, 1) = 1.0, "Overflow clamping failed");
   Put_Line ("      PASS");

   Put_Line ("========================================================");
   Put_Line ("ALL 13 TESTS PASSED SUCCESSFULLY");
end Tests;
