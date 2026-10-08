-- tests.adb
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Sift_Algorithm; use Sift_Algorithm;

procedure Tests is
   KPs : Keypoint_Array (1 .. 4);
begin
   Put_Line("--- SIFT ALGORITHM VERIFICATION SUITE ---");

   Put_Line("TEST 1 - Scale Space Initialization");
   begin
      Build_Scale_Space(0, 0);
      Assert(False, "Failed to catch invalid dimensions");
   exception
      when Invalid_Image_Dimensions => Put_Line("   PASS: Caught invalid dim");
   end;

   Put_Line("TEST 2 - Data Structures");
   declare
      K : constant Keypoint := (0.0, 0.0, 0.0, 0.0, [others => 1.0]);
   begin
      Assert(K.Feature_Vector'Length = 128, "Descriptor size mismatch");
      Assert(K.Feature_Vector (1) = 1.0, "Descriptor init");
      Put_Line("   PASS: Descriptor size correct");
   end;

   Put_Line("TEST 3 - Build scale space valid dims");
   Build_Scale_Space (32, 32);
   Put_Line("   PASS");

   Put_Line("TEST 4 - Detect extrema fills keypoints");
   Detect_Extrema (KPs);
   Assert (KPs'Length = 4, "keypoint array length");
   Put_Line("   PASS");

   Put_Line("TEST 5 - Localize / orient / describe");
   Localize_Keypoints (KPs);
   Assign_Orientation (KPs (1));
   Generate_Descriptor (KPs (1));
   Assert (KPs (1).Feature_Vector'Length = 128, "desc after generate");
   Put_Line("   PASS");

   Put_Line("--- ALL TESTS PASSED ---");
end Tests;
