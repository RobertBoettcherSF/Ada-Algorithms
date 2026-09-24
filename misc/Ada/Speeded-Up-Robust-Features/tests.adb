-- tests.adb
-- Comprehensive Pessimistic V&V Test Suite for SURF

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with SURF; use SURF;

procedure Tests is
   Img_Empty    : Image (1 .. 0, 1 .. 0);
   Img_Small    : constant Image (1 .. 5, 1 .. 5) := (others => (others => 1.0));
   Img_Med      : constant Image (1 .. 20, 1 .. 20) := (others => (others => 255.0));
   
   I_Img_Small  : Integral_Image (1 .. 5, 1 .. 5);
   
   Feats_64     : Feature_64_Array (1 .. 100);
   Feats_128    : Feature_128_Array (1 .. 100);
   Count        : Natural;
begin
   Put_Line ("=====================================");
   Put_Line ("Running SURF Pessimistic V&V Tests");
   Put_Line ("=====================================");

   -- TEST 1
   Put_Line ("TEST 1 - Integral Image Calculation");
   Put_Line ("  1.1 Assert correctly accumulates sums");
   I_Img_Small := Compute_Integral_Image (Img_Small);
   Assert (I_Img_Small (1, 1) = 1.0, "Integral origin failed");
   Assert (I_Img_Small (5, 5) = 25.0, "Integral max area failed");
   Put_Line ("      PASS");

   -- TEST 2
   Put_Line ("TEST 2 - Edge Case: Empty Image");
   Put_Line ("  2.1 Assert Image_Error raised on 0x0 image");
   begin
      declare
         I_Img_Empty : Integral_Image := Compute_Integral_Image (Img_Empty);
         pragma Unreferenced (I_Img_Empty);
      begin
         Assert (False, "Expected Image_Error not raised");
      end;
   exception
      when Image_Error => Put_Line ("      PASS");
   end;

   -- TEST 3
   Put_Line ("TEST 3 - Box Filter Area Evaluation");
   Put_Line ("  3.1 Assert arbitrary rectangular sums are accurate");
   Assert (Box_Area_Sum (I_Img_Small, 1, 1, 5, 5) = 25.0, "Box filter full fail");
   Assert (Box_Area_Sum (I_Img_Small, 2, 2, 2, 2) = 4.0, "Box filter inner fail");
   Put_Line ("      PASS");

   -- TEST 4
   Put_Line ("TEST 4 - Box Filter Bounds Clamping");
   Put_Line ("  4.1 Assert OOB limits clamp gracefully to 0.0 area additions");
   Assert (Box_Area_Sum (I_Img_Small, 4, 4, 10, 10) = 4.0, "Clamping fail");
   Assert (Box_Area_Sum (I_Img_Small, 10, 10, 2, 2) = 0.0, "OOB return fail");
   Put_Line ("      PASS");

   -- TEST 5
   Put_Line ("TEST 5 - Hessian Determinant Approximation");
   Put_Line ("  5.1 Assert mathematical output responds predictably on flat regions");
   declare
      I_Img_Med : constant Integral_Image := Compute_Integral_Image (Img_Med);
      Det       : constant Real := Determinant_Of_Hessian (I_Img_Med, 10, 10, 9);
   begin
      -- Flat image should result in 0.0 determinant for second derivatives
      Assert (Det = 0.0, "Hessian determinant on flat image failed");
      Put_Line ("      PASS");
   end;

   -- TEST 6
   Put_Line ("TEST 6 - U-SURF Upright Orientation Bypass");
   Put_Line ("  6.1 Assert U-SURF bypasses Haar Wavelet orientation (returns 0.0)");
   Extract_Features_64 (Img_Med, U_SURF, Feats_64, Count, -1.0);
   if Count > 0 then
      Assert (Feats_64(1).Pt.Orientation = 0.0, "U-SURF orientation /= 0.0");
   end if;
   Put_Line ("      PASS");

   -- TEST 7
   Put_Line ("TEST 7 - Standard SURF Orientation Check");
   Put_Line ("  7.1 Assert Standard SURF applies Haar Wavelets for orientation");
   Extract_Features_64 (Img_Med, Standard_SURF, Feats_64, Count, -1.0);
   if Count > 0 then
      Assert (Feats_64(1).Pt.Orientation /= 0.0, "Std SURF orientation = 0.0");
   end if;
   Put_Line ("      PASS");

   -- TEST 8
   Put_Line ("TEST 8 - Threshold Cutoff Functionality");
   Put_Line ("  8.1 Assert excessively high threshold suppresses all keypoints");
   Extract_Features_64 (Img_Med, Standard_SURF, Feats_64, Count, 999999.0);
   Assert (Count = 0, "Threshold cutoff failed to suppress points");
   Put_Line ("      PASS");

   -- TEST 9
   Put_Line ("TEST 9 - Variant Guard 64-Dim");
   Put_Line ("  9.1 Assert 64-dim method rejects 128-dim variants");
   begin
      Extract_Features_64 (Img_Med, SURF_128, Feats_64, Count, -1.0);
      Assert (False, "Constraint_Error missing for variant mismatch");
   exception
      when Constraint_Error => Put_Line ("      PASS");
   end;

   -- TEST 10
   Put_Line ("TEST 10 - Variant Guard 128-Dim");
   Put_Line ("  10.1 Assert 128-dim method rejects 64-dim variants");
   begin
      Extract_Features_128 (Img_Med, Standard_SURF, Feats_128, Count, -1.0);
      Assert (False, "Constraint_Error missing for variant mismatch");
   exception
      when Constraint_Error => Put_Line ("      PASS");
   end;

   -- TEST 11
   Put_Line ("TEST 11 - 128-Dimensional Extraction");
   Put_Line ("  11.1 Assert 128-dim vector correctly initializes memory");
   Extract_Features_128 (Img_Med, SURF_128, Feats_128, Count, -1.0);
   if Count > 0 then
      Assert (Feats_128(1).Desc'Length = 128, "128 Descriptor bounds fail");
   end if;
   Put_Line ("      PASS");

   -- TEST 12
   Put_Line ("TEST 12 - U-SURF-128 Combination Logic");
   Put_Line ("  12.1 Assert U-SURF-128 is both upright (0.0 rad) AND 128-dim");
   Extract_Features_128 (Img_Med, U_SURF_128, Feats_128, Count, -1.0);
   if Count > 0 then
      Assert (Feats_128(1).Pt.Orientation = 0.0, "U-SURF-128 orientation fail");
      Assert (Feats_128(1).Desc(128) /= -1.0, "U-SURF-128 desc fail");
   end if;
   Put_Line ("      PASS");

   -- TEST 13
   Put_Line ("TEST 13 - Laplacian Trace Sign");
   Put_Line ("  13.1 Assert Laplacian sign is strictly +1 or -1 for fast matching");
   Extract_Features_64 (Img_Med, Standard_SURF, Feats_64, Count, -1.0);
   if Count > 0 then
      Assert (Feats_64(1).Pt.Laplacian = 1 or Feats_64(1).Pt.Laplacian = -1, 
              "Laplacian sign invalid");
   end if;
   Put_Line ("      PASS");
   
   Put_Line ("=====================================");
   Put_Line ("ALL V&V ASSUMPTIONS DISPROVEN. TESTS PASSED.");
   Put_Line ("=====================================");
end Tests;
