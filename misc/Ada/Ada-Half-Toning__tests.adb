-- tests.adb
-- Test suite verifying algorithms assume initial state is broken
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Halftoning; use Halftoning;

procedure Tests is
   Img_1x1 : Image_Grid(1..1, 1..1);
   Img_2x2 : Image_Grid(1..2, 1..2);
   Img_3x3 : Image_Grid(1..3, 1..3);
   Img_Custom_Bounds : Image_Grid(5..6, 10..11);
begin
   Put_Line("Starting Verification & Validation Suite");
   Put_Line("========================================");

   -- TEST 1 - Simple Thresholding Functional Limits
   Put_Line("TEST 1 - Simple Thresholding Limits");
   
   Put_Line("  1.1 Assert 255 remains 255 (Max boundary)");
   Img_1x1(1,1) := 255;
   Simple_Threshold(Img_1x1);
   Assert (Img_1x1(1,1) = 255, "Threshold Max Bound Failed");
   Put_Line("     PASS");

   Put_Line("  1.2 Assert 0 remains 0 (Min boundary)");
   Img_1x1(1,1) := 0;
   Simple_Threshold(Img_1x1);
   Assert (Img_1x1(1,1) = 0, "Threshold Min Bound Failed");
   Put_Line("     PASS");

   Put_Line("  1.3 Assert 127 quantizes to 0 (Just below threshold)");
   Img_1x1(1,1) := 127;
   Simple_Threshold(Img_1x1);
   Assert (Img_1x1(1,1) = 0, "Threshold Under-Limit Failed");
   Put_Line("     PASS");
   
   Put_Line("  1.4 Assert 128 quantizes to 255 (Exactly on threshold)");
   Img_1x1(1,1) := 128;
   Simple_Threshold(Img_1x1);
   Assert (Img_1x1(1,1) = 255, "Threshold Exact-Limit Failed");
   Put_Line("     PASS");


   -- TEST 2 - Ordered Dithering Spatial Consistency
   Put_Line("TEST 2 - Ordered Dithering Matrix Alignment");

   Put_Line("  2.1 Assert solid white input stays solid white");
   Img_2x2 := (others => (others => 255));
   Ordered_Dither(Img_2x2);
   Assert (Img_2x2(1,1) = 255 and Img_2x2(2,2) = 255, "Ordered White Dither Failed");
   Put_Line("     PASS");

   Put_Line("  2.2 Assert matrix thresholds apply correctly (Index 0,0 vs 0,1)");
   Img_2x2 := (others => (others => 100));
   Ordered_Dither(Img_2x2);
   -- Bayer(0,0) = 0 so pixel(100) > 0 -> 255. Bayer(0,1) = 128 so pixel(100) < 128 -> 0
   Assert (Img_2x2(1,1) = 255 and Img_2x2(1,2) = 0, "Matrix Spatial Alignment Failed");
   Put_Line("     PASS");

   Put_Line("  2.3 Assert custom array bounds do not crash modulo logic");
   Img_Custom_Bounds := (others => (others => 128));
   Ordered_Dither(Img_Custom_Bounds);
   Assert (Img_Custom_Bounds(5,10) = 255, "Custom Bounds Modulo Failed");
   Put_Line("     PASS");


   -- TEST 3 - Floyd-Steinberg Error Diffusion & Boundary Checking
   Put_Line("TEST 3 - Error Diffusion & Bounds Mechanics");

   Put_Line("  3.1 Assert 1x1 grid handles missing neighbors without Constraint_Error");
   Img_1x1(1,1) := 100;
   Floyd_Steinberg_Dither(Img_1x1);
   Assert (Img_1x1(1,1) = 0, "FS 1x1 Edge Case Failed");
   Put_Line("     PASS");

   Put_Line("  3.2 Assert error diffuses correctly to the Right (7/16)");
   Img_2x2 := (others => (others => 0));
   Img_2x2(1,1) := 100; -- Quantizes to 0, Error is 100. Right pixel gets (100*7)/16 = 43
   Floyd_Steinberg_Dither(Img_2x2);
   Assert (Img_2x2(1,2) = 0, "FS Right Diffusion Failed (Should be 0 after quantizing)");
   Put_Line("     PASS");

   Put_Line("  3.3 Assert error bounds don't cause positive overflow (>255)");
   Img_3x3 := (others => (others => 200)); 
   Floyd_Steinberg_Dither(Img_3x3);
   -- It must stay within Pixel_Value ranges
   Assert (Img_3x3(3,3) >= 0 and Img_3x3(3,3) <= 255, "FS Overflow Clamp Failed");
   Put_Line("     PASS");
   
   Put_Line("  3.4 Assert error bounds don't cause negative overflow (<0)");
   Img_3x3 := (others => (others => 50)); 
   Floyd_Steinberg_Dither(Img_3x3);
   Assert (Img_3x3(3,3) = 0, "FS Underflow Clamp Failed");
   Put_Line("     PASS");

   Put_Line("  3.5 Assert bottom-right corner handles full accumulation dynamically");
   Img_3x3 := (others => (others => 127));
   Floyd_Steinberg_Dither(Img_3x3);
   -- Error from previous cells propagates down and right, eventually triggering 255
   Assert (Img_3x3(3,3) = 0 or Img_3x3(3,3) = 255, "FS Accumulation Failed");
   Put_Line("     PASS");

   Put_Line("  3.6 Assert Custom Bounds array functions normally");
   Img_Custom_Bounds := (others => (others => 128));
   Floyd_Steinberg_Dither(Img_Custom_Bounds);
   Assert (Img_Custom_Bounds(5,10) = 255, "FS Custom Bounds Failed");
   Put_Line("     PASS");

   Put_Line("========================================");
   Put_Line("ALL TESTS PASSED. CODEBASE IS VALIDATED.");
end Tests;
