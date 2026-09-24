--  tests.adb
--  V&V Test Suite for the Dithering algorithms.
--  Tests functionality, robustness, and boundary conditions.

with Ada.Text_IO;    use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Dithering;      use Dithering;

procedure Tests is
   Img_1x1   : Image (1 .. 1, 1 .. 1);
   Img_2x2   : Image (1 .. 2, 1 .. 2);
   Img_Empty : Image (1 .. 0, 1 .. 0); --  Legal empty array
begin
   Put_Line ("=============================================");
   Put_Line ("       DITHERING ALGORITHM TEST SUITE        ");
   Put_Line ("=============================================");

   --  TEST 1 - Helper Function Bounds Checking
   Put_Line ("TEST 1 - Helper Functions (Clamp/Round)");
   Put_Line ("  1.1 Assert Clamp bounds below 0.0");
   Assert (Clamp (-0.5) = 0.0, "Failed to clamp negative value");
   Put_Line ("      PASS");
   Put_Line ("  1.2 Assert Clamp bounds above 1.0");
   Assert (Clamp (1.5) = 1.0, "Failed to clamp overflow value");
   Put_Line ("      PASS");
   Put_Line ("  1.3 Assert Round_To_Palette normal boundaries");
   Assert
     (Round_To_Palette (0.4) = 0.0 and Round_To_Palette (0.6) = 1.0,
      "Rounding logic failed");
   Put_Line ("      PASS");

   --  TEST 2 - Threshold Dither
   Put_Line ("TEST 2 - Threshold Dithering Correctness");
   Img_1x1 (1, 1) := 0.49;
   Threshold_Dither (Img_1x1);
   Put_Line ("  2.1 Assert 0.49 thresholds to 0.0");
   Assert (Img_1x1 (1, 1) = 0.0, "Threshold failed on low value");
   Put_Line ("      PASS");

   Img_1x1 (1, 1) := 0.51;
   Threshold_Dither (Img_1x1);
   Put_Line ("  2.2 Assert 0.51 thresholds to 1.0");
   Assert (Img_1x1 (1, 1) = 1.0, "Threshold failed on high value");
   Put_Line ("      PASS");

   --  TEST 3 - Random Dither Edge Cases
   Put_Line ("TEST 3 - Random Dithering Execution");
   Put_Line ("  3.1 Assert Random_Dither executes without crashing on 1x1");
   Img_1x1 (1, 1) := 0.5;
   Random_Dither (Img_1x1);
   Assert
     (Img_1x1 (1, 1) = 0.0 or Img_1x1 (1, 1) = 1.0,
      "Random dither did not output a palette color");
   Put_Line ("      PASS");

   --  TEST 4 - Ordered Dithering Pattern Correctness
   Put_Line ("TEST 4 - Ordered Dithering (Bayer)");
   Put_Line ("  4.1 Assert pure black remains pure black");
   Img_2x2 := (others => (others => 0.0));
   Ordered_Dither_2x2 (Img_2x2);
   Assert
     (Img_2x2 (1, 1) = 0.0 and Img_2x2 (2, 2) = 0.0,
      "Black altered by ordered dither");
   Put_Line ("      PASS");

   Put_Line ("  4.2 Assert pure white remains pure white");
   Img_2x2 := (others => (others => 1.0));
   Ordered_Dither_2x2 (Img_2x2);
   Assert
     (Img_2x2 (1, 1) = 1.0 and Img_2x2 (2, 2) = 1.0,
      "White altered by ordered dither");
   Put_Line ("      PASS");

   --  TEST 5 - Error Diffusion: Floyd-Steinberg
   Put_Line ("TEST 5 - Floyd-Steinberg Error Diffusion");
   Put_Line ("  5.1 Assert handles empty images smoothly");
   Floyd_Steinberg_Dither (Img_Empty);
   Put_Line ("      PASS");

   Put_Line ("  5.2 Assert error propagation to adjacent pixel");
   Img_2x2 (1, 1) := 0.5;
   Img_2x2 (1, 2) := 0.0;
   Img_2x2 (2, 1) := 0.0;
   Img_2x2 (2, 2) := 0.0;
   Floyd_Steinberg_Dither (Img_2x2);
   Assert
     (Img_2x2 (1, 1) = 1.0,
      "Initial pixel did not quantize correctly");
   Assert
     (Img_2x2 (1, 2) = 0.0,
      "Propagated error broke pixel constraints");
   Put_Line ("      PASS");

   --  TEST 6 - Error Diffusion: Atkinson
   Put_Line ("TEST 6 - Atkinson Dithering Boundaries");
   Put_Line ("  6.1 Assert 1x1 image finishes without Out_Of_Bounds");
   Img_1x1 (1, 1) := 0.6;
   Atkinson_Dither (Img_1x1);
   Assert
     (Img_1x1 (1, 1) = 1.0,
      "Atkinson failed safe 1x1 boundary conditions");
   Put_Line ("      PASS");

   --  TEST 7 - Error Diffusion: Jarvis-Judice-Ninke
   Put_Line ("TEST 7 - Jarvis-Judice-Ninke Boundaries");
   Put_Line ("  7.1 Assert nested neighbor checks prevent Constraint_Error");
   Img_2x2 := (others => (others => 0.5));
   Jarvis_Judice_Ninke_Dither (Img_2x2);
   Assert
     (Img_2x2 (2, 2) = 0.0 or Img_2x2 (2, 2) = 1.0,
      "JJN did not reach final pixel safely");
   Put_Line ("      PASS");

   --  TEST 8 - Error Diffusion: Stucki
   Put_Line ("TEST 8 - Stucki Boundaries");
   Put_Line ("  8.1 Assert safe termination on tiny arrays");
   Img_1x1 (1, 1) := 0.2;
   Stucki_Dither (Img_1x1);
   Assert (Img_1x1 (1, 1) = 0.0, "Stucki quantization failed");
   Put_Line ("      PASS");

   Put_Line ("=============================================");
   Put_Line ("  ALL TESTS COMPLETED SUCCESSFULLY (PASS)    ");
   Put_Line ("=============================================");
end Tests;
