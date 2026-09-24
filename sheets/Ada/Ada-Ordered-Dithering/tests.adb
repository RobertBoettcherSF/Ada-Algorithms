with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Ordered_Dithering; use Ordered_Dithering;

procedure Tests is
   Passed_Tests : Natural := 0;
   Total_Tests  : Natural := 0;

   procedure Report_Pass (Msg : String) is
   begin
      Put_Line ("    PASS : " & Msg);
      Passed_Tests := Passed_Tests + 1;
   end Report_Pass;

   procedure Start_Test (Name : String) is
   begin
      Put_Line ("TEST " & Integer'Image(Total_Tests + 1) & " - " & Name);
      Total_Tests := Total_Tests + 1;
   end Start_Test;

begin
   Put_Line ("==================================================");
   Put_Line ("Starting V&V Test Suite for Ordered Dithering");
   Put_Line ("ASSUMPTION: Code is BROKEN. PASS = Assumption Disproved");
   Put_Line ("==================================================");

   -- TEST 1
   Start_Test ("Bayer Matrix 2x2 Generation");
   Put_Line ("  1.1 Assert Matrix values match expected Wikipedia formula");
   declare
      M : Bayer_Matrix := Generate_Bayer_Matrix (2);
   begin
      Assert (M(0,0) = -0.5, "M(0,0) incorrect");
      Assert (M(1,0) = 0.0, "M(1,0) incorrect");
      Assert (M(0,1) = 0.25, "M(0,1) incorrect");
      Assert (M(1,1) = -0.25, "M(1,1) incorrect");
      Report_Pass ("2x2 matrix values exact");
   end;

   -- TEST 2
   Start_Test ("Power of Two Dimension Validation");
   Put_Line ("  2.1 Assert dim=3 raises Invalid_Matrix_Dimension");
   begin
      declare
         M : Bayer_Matrix := Generate_Bayer_Matrix (3);
      begin
         Assert (False, "Exception not raised");
      end;
   exception
      when Invalid_Matrix_Dimension =>
         Report_Pass ("Constraint properly raised for Dim=3");
   end;

   -- TEST 3
   Start_Test ("Quantization Function Logic");
   Put_Line ("  3.1 Assert 0.0 maps to 0");
   Assert (Quantize (0.0, 2) = 0, "Quantize 0 failed");
   Put_Line ("  3.2 Assert 1.0 maps to 255");
   Assert (Quantize (1.0, 2) = 255, "Quantize 255 failed");
   Put_Line ("  3.3 Assert 0.5 maps to 255 (round half up)");
   Assert (Quantize (0.5, 2) = 255, "Quantize 0.5 failed");
   Report_Pass ("Quantize boundary mapping correct");

   -- TEST 4
   Start_Test ("Monochrome - Black stays Black");
   Put_Line ("  4.1 Assert Apply_Monochrome on 0 yields 0");
   declare
      Img : Grayscale_Image (1 .. 2, 1 .. 2) := (others => (others => 0));
   begin
      Apply_Monochrome (Img, 2, 2);
      Assert (Img(1,1) = 0, "Black changed to white");
      Report_Pass ("Black pixel preservation verified");
   end;

   -- TEST 5
   Start_Test ("Monochrome - White stays White");
   Put_Line ("  5.1 Assert Apply_Monochrome on 255 yields 255");
   declare
      Img : Grayscale_Image (1 .. 2, 1 .. 2) := (others => (others => 255));
   begin
      Apply_Monochrome (Img, 2, 2);
      Assert (Img(1,1) = 255, "White changed to black");
      Report_Pass ("White pixel preservation verified");
   end;

   -- TEST 6
   Start_Test ("Monochrome - 50% Gray checkerboard");
   Put_Line ("  6.1 Assert 127/128 maps appropriately based on Bayer Matrix");
   declare
      Img : Grayscale_Image (1 .. 2, 1 .. 2) := (others => (others => 127));
   begin
      Apply_Monochrome (Img, 2, 2);
      Assert (Img(1,1) = 0, "Top-left should be 0");
      Assert (Img(2,1) = 0, "Top-right should be 0");
      Report_Pass ("Gray properly translated via threshold map");
   end;

   -- TEST 7
   Start_Test ("Monochrome - Empty Image Exception");
   Put_Line ("  7.1 Assert empty image raises Empty_Image_Error");
   begin
      declare
         Img : Grayscale_Image (1 .. 0, 1 .. 0);
      begin
         Apply_Monochrome (Img, 2);
         Assert (False, "Exception missing");
      end;
   exception
      when Empty_Image_Error => Report_Pass ("Empty image rejected");
   end;

   -- TEST 8
   Start_Test ("Monochrome - Invalid Levels Exception");
   Put_Line ("  8.1 Assert levels=1 raises Invalid_Levels_Error");
   begin
      declare
         Img : Grayscale_Image (1 .. 2, 1 .. 2) := (others => (others => 0));
      begin
         Apply_Monochrome (Img, 2, 1);
         Assert (False, "Exception missing");
      end;
   exception
      when Invalid_Levels_Error => Report_Pass ("Invalid levels rejected");
   end;

   -- TEST 9
   Start_Test ("Color Dithering - Pure Red Preservation");
   Put_Line ("  9.1 Assert Apply_Color on pure red keeps red");
   declare
      Img : Color_Image (1 .. 2, 1 .. 2) := (others => (others => (255, 0, 0)));
   begin
      Apply_Color (Img, 2);
      Assert (Img(1,1).R = 255 and Img(1,1).G = 0, "Pure red altered");
      Report_Pass ("Primary color isolation robust");
   end;

   -- TEST 10
   Start_Test ("Color Dithering - Complex Mix");
   Put_Line ("  10.1 Assert independent channels are processed correctly");
   declare
      Img : Color_Image (1 .. 1, 1 .. 1) := (others => (others => (127, 255, 0)));
   begin
      Apply_Color (Img, 2);
      Assert (Img(1,1).G = 255, "Green channel failed");
      Assert (Img(1,1).B = 0, "Blue channel failed");
      Report_Pass ("Color channels dither independently");
   end;

   -- TEST 11
   Start_Test ("Color Dithering - Invalid Levels");
   Put_Line ("  11.1 Assert invalid levels in any channel raises exception");
   begin
      declare
         Img : Color_Image (1 .. 2, 1 .. 2) := (others => (others => (0,0,0)));
      begin
         Apply_Color (Img, 2, 2, 1, 2);
         Assert (False, "Exception missing");
      end;
   exception
      when Invalid_Levels_Error => Report_Pass ("Channel levels validated");
   end;

   -- TEST 12
   Start_Test ("1x1 Image Bounds Check");
   Put_Line ("  12.1 Assert 1x1 image completes without range errors");
   declare
      Img : Grayscale_Image (1 .. 1, 1 .. 1) := (others => (others => 100));
   begin
      Apply_Monochrome (Img, 4);
      Assert (Img(1,1) = 0 or Img(1,1) = 255, "1x1 failed to quantize");
      Report_Pass ("1x1 edge case bounds safe");
   end;

   -- TEST 13
   Start_Test ("Matrix 8x8 Boundary Size");
   Put_Line ("  13.1 Assert Apply_Color handles 8x8 Matrix across large image");
   declare
      Img : Color_Image (1 .. 10, 1 .. 10) := (others => (others => (128,128,128)));
   begin
      Apply_Color (Img, 8);
      Report_Pass ("8x8 Matrix mapped across 10x10 cleanly");
   end;

   Put_Line ("==================================================");
   Put_Line ("Test Summary: " & Integer'Image(Passed_Tests) & " / " & Integer'Image(Total_Tests) & " Passed.");
   if Passed_Tests = Total_Tests then
      Put_Line ("STATUS: ALL ASSUMPTIONS DISPROVED (Code is correct).");
   else
      Put_Line ("STATUS: FAILED.");
   end if;
end Tests;
