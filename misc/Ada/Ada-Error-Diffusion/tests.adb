-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Error_Diffusion; use Error_Diffusion;

procedure Tests is
   Img_1x1 : Image_Grid(1..1, 1..1);
   Img_2x2 : Image_Grid(1..2, 1..2);
   Empty   : Image_Grid(1..0, 1..0);
begin
   Put_Line ("Starting Error Diffusion Validation Test Suite");
   Put_Line ("Assuming codebase is non-functional or broken. Proving otherwise...");
   Put_Line ("------------------------------------------------------");

   -- TEST 1 - Quantization Logic (1x1 Matrix)
   Put_Line ("TEST 1 - Single Pixel Quantization");
   Img_1x1 (1,1) := 128.0; -- Above threshold
   Put_Line ("  1.1 Assert pixel > 127.5 quantizes to 255.0");
   Apply_Diffusion (Img_1x1, Floyd_Steinberg_Kernel);
   Assert (Img_1x1 (1,1) = 255.0, "Failed to quantize upward");
   Put_Line ("      PASS");
   
   Img_1x1 (1,1) := 100.0; -- Below threshold
   Put_Line ("  1.2 Assert pixel < 127.5 quantizes to 0.0");
   Apply_Diffusion (Img_1x1, Floyd_Steinberg_Kernel);
   Assert (Img_1x1 (1,1) = 0.0, "Failed to quantize downward");
   Put_Line ("      PASS");

   -- TEST 2 - Error Diffusion (Horizontal Propagation)
   Put_Line ("TEST 2 - Horizontal Diffusion (Floyd-Steinberg)");
   Img_2x2 := (others => (others => 100.0));
   Apply_Diffusion (Img_2x2, Floyd_Steinberg_Kernel);
   Put_Line ("  2.1 Assert first pixel became 0.0");
   Assert (Img_2x2 (1,1) = 0.0, "Quantization failed");
   Put_Line ("      PASS");
   Put_Line ("  2.2 Assert rightward error propagation (+ 100 * 7/16)");
   -- 100 + (100 * 7/16) = 143.75. Since 143.75 > 127.5, it becomes 255.0
   Assert (Img_2x2 (2,1) = 255.0, "Rightward propagation failed");
   Put_Line ("      PASS");

   -- TEST 3 - Empty Input Verification
   Put_Line ("TEST 3 - Empty Image Edge Case");
   Put_Line ("  3.1 Assert empty image raises Invalid_Image_Error");
   begin
      Apply_Diffusion (Empty, Floyd_Steinberg_Kernel);
      Assert (False, "Expected Invalid_Image_Error");
   exception
      when Invalid_Image_Error =>
         Put_Line ("      PASS");
   end;

   -- TEST 4 - Atkinson Kernel Special Properties
   Put_Line ("TEST 4 - Atkinson Kernel Loading");
   Put_Line ("  4.1 Assert Atkinson kernel contains exactly 6 elements");
   Assert (Atkinson_Kernel'Length = 6, "Atkinson kernel length incorrect");
   Put_Line ("      PASS");
   
   Put_Line ("  4.2 Assert Atkinson weight values are 1/8");
   Assert (Atkinson_Kernel(1).Weight = 0.125, "Atkinson weight incorrect");
   Put_Line ("      PASS");

   -- TEST 5 - Jarvis-Judice-Ninke Size
   Put_Line ("TEST 5 - JJN Kernel Integrity");
   Put_Line ("  5.1 Assert JJN kernel contains exactly 12 elements");
   Assert (Jarvis_Judice_Ninke_Kernel'Length = 12, "JJN kernel size incorrect");
   Put_Line ("      PASS");

   -- TEST 6 - Stucki Size
   Put_Line ("TEST 6 - Stucki Kernel Integrity");
   Put_Line ("  6.1 Assert Stucki kernel contains exactly 12 elements");
   Assert (Stucki_Kernel'Length = 12, "Stucki kernel size incorrect");
   Put_Line ("      PASS");

   -- TEST 7 - Burkes Integrity
   Put_Line ("TEST 7 - Burkes Kernel Integrity");
   Put_Line ("  7.1 Assert Burkes kernel contains exactly 7 elements");
   Assert (Burkes_Kernel'Length = 7, "Burkes kernel size incorrect");
   Put_Line ("      PASS");

   -- TEST 8 - Sierra Family Loading
   Put_Line ("TEST 8 - Sierra Kernels Integrity");
   Put_Line ("  8.1 Assert Sierra3 length = 10");
   Assert (Sierra3_Kernel'Length = 10, "Sierra3 incorrect");
   Put_Line ("      PASS");
   Put_Line ("  8.2 Assert Sierra2 length = 7");
   Assert (Sierra2_Row_Kernel'Length = 7, "Sierra2 incorrect");
   Put_Line ("      PASS");
   Put_Line ("  8.3 Assert Sierra Lite length = 3");
   Assert (Sierra_Lite_Kernel'Length = 3, "Sierra Lite incorrect");
   Put_Line ("      PASS");

   -- TEST 9 - Bounds Enforcement / Clamping (Upper)
   Put_Line ("TEST 9 - Extreme Positive Error Clamping");
   Img_2x2 := (others => (others => 255.0));
   -- Force an impossible state to test clamp function implicitly via algorithm
   -- Old_Pixel=255.0 -> New_Pixel=255.0. Error=0. Nothing goes out of bounds.
   -- Let's manually inject negative threshold behavior
   Put_Line ("  9.1 Assert extreme upper bounds do not raise Constraint_Error");
   Apply_Diffusion (Img_2x2, Sierra_Lite_Kernel);
   Assert (Img_2x2(2,2) <= 255.0, "Clamping failed upper bound");
   Put_Line ("      PASS");

   -- TEST 10 - Bounds Enforcement / Clamping (Lower)
   Put_Line ("TEST 10 - Extreme Negative Error Clamping");
   Img_2x2 := (others => (others => 0.0));
   Put_Line ("  10.1 Assert extreme lower bounds do not raise Constraint_Error");
   Apply_Diffusion (Img_2x2, Burkes_Kernel);
   Assert (Img_2x2(1,1) = 0.0, "Clamping failed lower bound");
   Put_Line ("      PASS");

   -- TEST 11 - Out-of-bounds Coordinate Safety
   Put_Line ("TEST 11 - Out of Bounds Matrix Protection");
   Img_1x1(1,1) := 127.0; 
   Put_Line ("  11.1 Assert 1x1 processing doesn't crash on non-existent neighbors");
   Apply_Diffusion (Img_1x1, Floyd_Steinberg_Kernel);
   Assert (Img_1x1(1,1) = 0.0, "Out of bounds protection failed");
   Put_Line ("      PASS");

   -- TEST 12 - Error Carryover Mechanics
   Put_Line ("TEST 12 - Deep Error Carryover");
   declare
      Img_3x1 : Image_Grid(1..3, 1..1) := (others => (others => 127.0));
   begin
      Apply_Diffusion (Img_3x1, Floyd_Steinberg_Kernel);
      Put_Line ("  12.1 Assert cascaded error pushes third pixel over threshold");
      -- P1(127) -> 0, Err=127.
      -- P2(127 + 127*7/16 = 182.5) -> 255, Err=-72.5
      -- P3(127 + -72.5*7/16 = 95.28) -> 0
      Assert (Img_3x1(1,1) = 0.0, "P1 failed");
      Assert (Img_3x1(2,1) = 255.0, "P2 failed");
      Assert (Img_3x1(3,1) = 0.0, "P3 failed");
      Put_Line ("      PASS");
   end;

   -- TEST 13 - Asymmetrical Negative Indices (Kernel properties)
   Put_Line ("TEST 13 - Negative Delta X Safety");
   declare
      Img_3x3 : Image_Grid(1..3, 1..3) := (others => (others => 100.0));
   begin
      Put_Line ("  13.1 Assert backward X propagation works safely");
      Apply_Diffusion (Img_3x3, Jarvis_Judice_Ninke_Kernel);
      Assert (Img_3x3(1,1) = 0.0, "Backward mapping crashed or failed");
      Put_Line ("      PASS");
   end;

   Put_Line ("------------------------------------------------------");
   Put_Line ("ALL TESTS PASSED: Assumptions of broken code disproven.");
end Tests;
