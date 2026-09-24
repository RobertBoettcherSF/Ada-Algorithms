-- tests.adb
-- Verification & Validation Suite for Canny Edge Detector
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Canny_Edge_Detector; use Canny_Edge_Detector;

procedure Tests is
   Img_Small     : Image(1..3, 1..3) := (others => (others => 0.0));
   Img_Small_Out : Image(1..3, 1..3);
   Img_Valid     : Image(1..10, 1..10) := (others => (others => 0.0));
   Img_Out       : Image(1..10, 1..10);
   Img_Mag       : Image(1..10, 1..10);
   Img_Dir       : Image(1..10, 1..10);

begin
   Put_Line ("Starting V&V Test Suite for Canny Edge Detector...");
   Put_Line ("ASSUMPTION: The codebase is broken. Tests prove otherwise.");
   Put_Line ("------------------------------------------------------");

   -- TEST 1: Validation of Image Size Bounds
   Put_Line ("TEST 1 - Image Size Boundaries");
   Put_Line ("  1.1 Assert processing a too-small image (<5x5) raises Invalid_Image_Size");
   begin
      Apply_Canny(Img_Small, Img_Small_Out, 10.0, 50.0);
      Assert(False, "Failed to raise Invalid_Image_Size");
   exception
      when Invalid_Image_Size => Put_Line ("      PASS");
   end;

   -- TEST 2: Threshold Validation
   Put_Line ("TEST 2 - Threshold Validation Constraints");
   Put_Line ("  2.1 Assert Low_Threshold >= High_Threshold raises Invalid_Thresholds");
   begin
      Apply_Canny(Img_Valid, Img_Out, 100.0, 50.0);
      Assert(False, "Failed to raise Invalid_Thresholds");
   exception
      when Invalid_Thresholds => Put_Line ("      PASS");
   end;

   -- TEST 3: Uniform Image
   Put_Line ("TEST 3 - Uniform Intensity (No Edges)");
   Put_Line ("  3.1 Assert fully black image produces zero edges");
   Img_Valid := (others => (others => 0.0));
   Apply_Canny(Img_Valid, Img_Out, 10.0, 50.0);
   Assert(Img_Out(5,5) = 0.0, "Edges found in black image");
   Put_Line ("      PASS");

   Put_Line ("  3.2 Assert fully white image produces zero edges");
   Img_Valid := (others => (others => 255.0));
   Apply_Canny(Img_Valid, Img_Out, 10.0, 50.0);
   Assert(Img_Out(5,5) = 0.0, "Edges found in white image");
   Put_Line ("      PASS");

   -- TEST 4: Gradient Computations (Exact Method)
   Put_Line ("TEST 4 - Gradient Computation (Exact Method)");
   Img_Valid := (others => (others => 0.0));
   for I in 1..10 loop Img_Valid(I, 5) := 255.0; end loop; -- Vertical line
   Compute_Gradients(Img_Valid, Img_Mag, Img_Dir, Exact);
   Put_Line ("  4.1 Assert horizontal gradient magnitude is > 0 adjacent to vertical line");
   Assert(Img_Mag(5, 4) > 0.0, "No gradient magnitude found");
   Put_Line ("      PASS");
   Put_Line ("  4.2 Assert direction for vertical line computes to 0 degrees (Horizontal gradient)");
   Assert(Img_Dir(5, 4) = 0.0, "Incorrect gradient direction");
   Put_Line ("      PASS");

   -- TEST 5: Gradient Computations (Approximated Method)
   Put_Line ("TEST 5 - Gradient Computation (Approximated/Manhattan)");
   Compute_Gradients(Img_Valid, Img_Mag, Img_Dir, Approximated);
   Put_Line ("  5.1 Assert approx magnitude detects edges properly");
   Assert(Img_Mag(5, 4) > 0.0, "Approximated method failed to detect edge");
   Put_Line ("      PASS");

   -- TEST 6: Gradient Direction (Horizontal Line)
   Put_Line ("TEST 6 - Gradient Direction Analysis");
   Img_Valid := (others => (others => 0.0));
   for J in 1..10 loop Img_Valid(5, J) := 255.0; end loop; -- Horizontal line
   Compute_Gradients(Img_Valid, Img_Mag, Img_Dir, Exact);
   Put_Line ("  6.1 Assert direction for horizontal line computes to 90 degrees");
   Assert(Img_Dir(4, 5) = 90.0, "Failed to map to 90 degrees");
   Put_Line ("      PASS");

   -- TEST 7: Gradient Direction (Diagonal Line)
   Put_Line ("TEST 7 - Gradient Direction (Diagonal)");
   Img_Valid := (others => (others => 0.0));
   for I in 1..10 loop Img_Valid(I, I) := 255.0; end loop;
   Compute_Gradients(Img_Valid, Img_Mag, Img_Dir, Exact);
   Put_Line ("  7.1 Assert diagonal line detects 45 or 135 deg gradients");
   Assert(Img_Dir(4, 5) = 135.0 or Img_Dir(4, 5) = 45.0, "Failed diagonal angle mapping");
   Put_Line ("      PASS");

   -- TEST 8: Non-Maximum Suppression (Edge Thinning)
   Put_Line ("TEST 8 - Non-Maximum Suppression");
   Put_Line ("  8.1 Assert thick gradient is thinned correctly");
   Img_Mag := (others => (others => 100.0));
   Img_Mag(5,5) := 200.0; -- Maximum point
   Img_Dir := (others => (others => 90.0));
   Non_Maximum_Suppression(Img_Mag, Img_Dir, Img_Out);
   Assert(Img_Out(5,5) = 200.0 and Img_Out(4,5) = 0.0, "NMS failed to thin edge");
   Put_Line ("      PASS");

   -- TEST 9: Double Thresholding
   Put_Line ("TEST 9 - Double Threshold Classification");
   Put_Line ("  9.1 Assert pixels below low_thresh become 0");
   Img_Valid := (others => (others => 20.0));
   Double_Threshold_And_Hysteresis(Img_Valid, Img_Out, 30.0, 80.0);
   Assert(Img_Out(5,5) = 0.0, "Sub-threshold pixel not suppressed");
   Put_Line ("      PASS");

   -- TEST 10: Double Thresholding (Strong Edges)
   Put_Line ("TEST 10 - Double Threshold Classification (Strong)");
   Put_Line ("  10.1 Assert pixels above high_thresh become 255.0");
   Img_Valid := (others => (others => 100.0));
   Double_Threshold_And_Hysteresis(Img_Valid, Img_Out, 30.0, 80.0);
   Assert(Img_Out(5,5) = 255.0, "Strong edge not maximized");
   Put_Line ("      PASS");

   -- TEST 11: Hysteresis Tracking (Propagation)
   Put_Line ("TEST 11 - Hysteresis Edge Tracking (Positive)");
   Put_Line ("  11.1 Assert weak edge connected to strong edge becomes strong");
   Img_Valid := (others => (others => 0.0));
   Img_Valid(5,5) := 100.0; -- Strong
   Img_Valid(5,6) := 50.0;  -- Weak, connected
   Double_Threshold_And_Hysteresis(Img_Valid, Img_Out, 30.0, 80.0);
   Assert(Img_Out(5,6) = 255.0, "Hysteresis failed to propagate");
   Put_Line ("      PASS");

   -- TEST 12: Hysteresis Tracking (Elimination)
   Put_Line ("TEST 12 - Hysteresis Edge Tracking (Negative)");
   Put_Line ("  12.1 Assert isolated weak edge is eliminated to 0");
   Img_Valid := (others => (others => 0.0));
   Img_Valid(2,2) := 50.0; -- Weak, isolated
   Double_Threshold_And_Hysteresis(Img_Valid, Img_Out, 30.0, 80.0);
   Assert(Img_Out(2,2) = 0.0, "Isolated weak edge was not suppressed");
   Put_Line ("      PASS");

   -- TEST 13: Full Integration with Approximated Variant
   Put_Line ("TEST 13 - Full Pipeline Integration (Approximated Variant)");
   Put_Line ("  13.1 Assert Apply_Canny functions end-to-end without crashing");
   Img_Valid := (others => (others => 0.0));
   for I in 1..10 loop Img_Valid(I, 5) := 255.0; end loop; 
   Apply_Canny(Img_Valid, Img_Out, 10.0, 50.0, Approximated);
   -- It shouldn't be fully black since there is an edge
   declare
      Sum : Float := 0.0;
   begin
      for I in 3..8 loop Sum := Sum + Float(Img_Out(I, 4)); end loop;
      Assert(Sum > 0.0, "End-to-end integration failed to produce edges");
      Put_Line ("      PASS");
   end;

   Put_Line ("------------------------------------------------------");
   Put_Line ("All assumptions of broken code DISPROVEN. Test Suite PASSED.");
end Tests;
