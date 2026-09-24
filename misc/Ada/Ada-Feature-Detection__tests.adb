-- tests.adb
-- Verification and Validation Test Suite for Feature Detection
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Feature_Detection; use Feature_Detection;

procedure Tests is
   -- Test data buffers
   Small_Img : Image(1..2, 1..2) := (others => (others => 0));
   Flat_Img  : Image(1..5, 1..5) := (others => (others => 128));
   Line_Img  : Image(1..5, 1..5) := (others => (others => 0));
   Dot_Img   : Image(1..5, 1..5) := (others => (others => 0));
   
   Feats     : Feature_Array(1..100);
   Count     : Natural;

begin
   Put_Line("=============================================");
   Put_Line("STARTING FEATURE DETECTION V&V TEST SUITE");
   Put_Line("Philosophy: Assume codebase is broken/unsafe.");
   Put_Line("Tests PASS when assumption is proven false.");
   Put_Line("=============================================");

   -- Setup synthetic image data
   for Y in 1..5 loop Line_Img(3, Y) := 255; end loop; -- Vertical line
   Dot_Img(3,3) := 255; -- Single point

   -- TEST 1: Edge Cases & Bounds Protection
   Put_Line("TEST 1 - Invalid Image Dimensions (Bounds Safety)");
   begin
      Put("  1.1 Assert Detect_Edges rejects 2x2 image... ");
      Detect_Edges(Small_Img, 1.0, Feats, Count);
      Assert (False, "Expected Invalid_Image_Error not raised");
   exception
      when Invalid_Image_Error => Put_Line("PASS");
   end;

   begin
      Put("  1.2 Assert Detect_Corners rejects 2x2 image... ");
      Detect_Corners(Small_Img, 1.0, Feats, Count);
      Assert (False, "Expected Invalid_Image_Error not raised");
   exception
      when Invalid_Image_Error => Put_Line("PASS");
   end;
   
   begin
      Put("  1.3 Assert Detect_Blobs rejects 2x2 image... ");
      Detect_Blobs(Small_Img, 1.0, Feats, Count);
      Assert (False, "Expected Invalid_Image_Error not raised");
   exception
      when Invalid_Image_Error => Put_Line("PASS");
   end;

   -- TEST 2: False Positive Resistance (Solid Images)
   Put_Line("TEST 2 - False Positive Mitigation (Flat Field)");
   Put("  2.1 Assert Edges on flat image = 0... ");
   Detect_Edges(Flat_Img, 0.1, Feats, Count);
   Assert(Count = 0, "Failed: Detected false edges");
   Put_Line("PASS");

   Put("  2.2 Assert Corners on flat image = 0... ");
   Detect_Corners(Flat_Img, 0.1, Feats, Count);
   Assert(Count = 0, "Failed: Detected false corners");
   Put_Line("PASS");

   Put("  2.3 Assert Blobs on flat image = 0... ");
   Detect_Blobs(Flat_Img, 0.1, Feats, Count);
   Assert(Count = 0, "Failed: Detected false blobs");
   Put_Line("PASS");

   Put("  2.4 Assert Ridges on flat image = 0... ");
   Detect_Ridges(Flat_Img, 0.1, Feats, Count);
   Assert(Count = 0, "Failed: Detected false ridges");
   Put_Line("PASS");

   -- TEST 3: Functional Feature Detection
   Put_Line("TEST 3 - Algorithmic Correctness & True Positives");
   Put("  3.1 Assert Vertical Line detects Edges... ");
   Detect_Edges(Line_Img, 100.0, Feats, Count);
   Assert(Count > 0, "Failed: Missed visible edge");
   Put_Line("PASS");

   Put("  3.2 Assert Dot Image detects Corner... ");
   Detect_Corners(Dot_Img, 10.0, Feats, Count);
   Assert(Count > 0, "Failed: Missed visible corner");
   Put_Line("PASS");

   Put("  3.3 Assert Dot Image detects Blob... ");
   Detect_Blobs(Dot_Img, 50.0, Feats, Count);
   Assert(Count > 0, "Failed: Missed visible blob");
   Put_Line("PASS");

   Put("  3.4 Assert Vertical Line detects Ridge... ");
   Detect_Ridges(Line_Img, 50.0, Feats, Count);
   Assert(Count > 0, "Failed: Missed visible ridge");
   Put_Line("PASS");

   -- TEST 4: Boundary & Constraint Checks
   Put_Line("TEST 4 - Logic Constraints & Overflow Protection");
   Put("  4.1 Assert High Threshold yields 0 features... ");
   Detect_Edges(Line_Img, 9999.0, Feats, Count);
   Assert(Count = 0, "Failed: Threshold filtering bypassed");
   Put_Line("PASS");

   declare
      Tiny_Buffer : Feature_Array(1..1);
   begin
      Put("  4.2 Assert Array bounds prevent buffer overflow... ");
      -- Sending an image that creates many edges, but only a buffer of 1
      Detect_Edges(Line_Img, 10.0, Tiny_Buffer, Count);
      Assert(Count = 1, "Failed: Overflowed buffer or didn't truncate");
      Put_Line("PASS");
   end;

   Put_Line("=============================================");
   Put_Line("ALL 13 TESTS EXECUTED AND PASSED.");
   Put_Line("CODE VERIFIED AND VALIDATED AGAINST ASSUMPTIONS.");
   Put_Line("=============================================");
end Tests;
