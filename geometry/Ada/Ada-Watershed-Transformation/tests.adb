with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Watershed_Algorithm; use Watershed_Algorithm;

procedure Tests is
   procedure Pass (Msg : String) is
   begin
      Put_Line("      PASS - " & Msg);
   end Pass;

   -- Test Variables
   Img_3x3  : Image_Grid(1..3, 1..3) := ((10, 15, 10), (10, 0, 10), (10, 10, 10));
   Mkr_3x3  : Label_Grid(1..3, 1..3) := (others => (others => UNLABELED));
   Res_3x3  : Label_Grid(1..3, 1..3);
   
   Img_Bad  : Image_Grid(1..2, 1..2) := ((0,0), (0,0));
   
begin
   Put_Line("===========================================");
   Put_Line("   WATERSHED ALGORITHM V&V TEST SUITE      ");
   Put_Line("===========================================");

   -- TEST 1
   Put_Line("TEST 1 - Meyer: Basic functionality with single marker");
   Put_Line("  1.1 Assume code fails to flood from a single marker point");
   Mkr_3x3(2,2) := 1;
   Meyer_Watershed(Img_3x3, Mkr_3x3, Res_3x3);
   Assert(Res_3x3(1,1) = 1 and Res_3x3(3,3) = 1, "Flood failed");
   Pass("Flood fills entire image from single marker");

   -- TEST 2
   Put_Line("TEST 2 - Meyer: Watershed line creation");
   Put_Line("  1.2 Assume code fails to create lines between distinct markers");
   Mkr_3x3(2,2) := UNLABELED; Mkr_3x3(1,1) := 1; Mkr_3x3(3,3) := 2;
   Meyer_Watershed(Img_3x3, Mkr_3x3, Res_3x3);
   Assert(Res_3x3(2,2) = WATERSHED_LINE or Res_3x3(1,2) = WATERSHED_LINE, "Line missing");
   Pass("Watershed line (-1) accurately prevents region mixing");

   -- TEST 3
   Put_Line("TEST 3 - Robustness: Meyer Dimension Mismatch");
   Put_Line("  1.3 Assume code processes arrays with mismatched sizes without error");
   begin
      Meyer_Watershed(Img_Bad, Mkr_3x3, Res_3x3);
      Assert(False, "Should have raised Dimension_Mismatch");
   exception
      when Dimension_Mismatch => Pass("Raised Dimension_Mismatch correctly");
   end;

   -- TEST 4
   Put_Line("TEST 4 - Robustness: Immersion Dimension Mismatch");
   Put_Line("  1.4 Assume code fails to validate dimensions on Immersion variant");
   begin
      Immersion_Watershed(Img_Bad, Res_3x3);
      Assert(False, "Should have raised");
   exception
      when Dimension_Mismatch => Pass("Raised Dimension_Mismatch correctly");
   end;

   -- TEST 5
   Put_Line("TEST 5 - Immersion: Detects single minimum basin");
   Put_Line("  1.5 Assume code cannot identify a single basin in an image");
   Immersion_Watershed(Img_3x3, Res_3x3);
   Assert(Res_3x3(2,2) > UNLABELED, "Minimum not found");
   Pass("Center minimum correctly labeled");

   -- TEST 6
   Put_Line("TEST 6 - Immersion: Multiple minima isolation");
   Put_Line("  1.6 Assume code groups multiple isolated minima together");
   declare
      Img_Multi : Image_Grid(1..3, 1..5) := ((10, 10, 10, 10, 10), (0, 10, 10, 10, 0), (10, 10, 10, 10, 10));
      Res_Multi : Label_Grid(1..3, 1..5);
   begin
      Immersion_Watershed(Img_Multi, Res_Multi);
      Assert(Res_Multi(2,1) /= Res_Multi(2,5), "Minima merged incorrectly");
      Pass("Distinct minima received distinct labels");
   end;

   -- TEST 7
   Put_Line("TEST 7 - Topological: Steepest descent pathing");
   Put_Line("  1.7 Assume topological algorithm fails to trace downward paths");
   declare
      Img_Slope : Image_Grid(1..3, 1..3) := ((20, 15, 10), (25, 20, 15), (30, 25, 20));
      Res_Slope : Label_Grid(1..3, 1..3);
   begin
      Topological_Watershed(Img_Slope, Res_Slope);
      Assert(Res_Slope(3,1) = Res_Slope(1,3), "Path did not reach same minimum");
      Pass("Path successfully traced to global minimum");
   end;

   -- TEST 8
   Put_Line("TEST 8 - Topological: Ridge separation");
   Put_Line("  1.8 Assume topological descent blends across absolute ridges");
   declare
      Img_Ridge : Image_Grid(1..3, 1..3) := ((0, 20, 0), (10, 20, 10), (20, 20, 20));
      Res_Ridge : Label_Grid(1..3, 1..3);
   begin
      Topological_Watershed(Img_Ridge, Res_Ridge);
      Assert(Res_Ridge(1,1) /= Res_Ridge(1,3), "Ridge crossed improperly");
      Pass("Ridge correctly separates descended regions");
   end;

   -- TEST 9
   Put_Line("TEST 9 - Edge Case: Flat Topography (Plateau)");
   Put_Line("  1.9 Assume algorithm crashes on completely flat images");
   declare
      Img_Flat : Image_Grid(1..3, 1..3) := (others => (others => 128));
      Res_Flat : Label_Grid(1..3, 1..3);
   begin
      Topological_Watershed(Img_Flat, Res_Flat);
      Pass("Handled flat plateaus gracefully without infinite loops");
   end;

   -- TEST 10
   Put_Line("TEST 10 - Edge Case: Single Pixel Image");
   Put_Line("  1.10 Assume array out-of-bounds on 1x1 grids");
   declare
      Img_1x1 : Image_Grid(1..1, 1..1) := (1 => (1 => 10));
      Mkr_1x1 : Label_Grid(1..1, 1..1) := (1 => (1 => 5));
      Res_1x1 : Label_Grid(1..1, 1..1);
   begin
      Meyer_Watershed(Img_1x1, Mkr_1x1, Res_1x1);
      Assert(Res_1x1(1,1) = 5, "Label lost");
      Pass("1x1 grid processed without out-of-bounds");
   end;

   -- TEST 11
   Put_Line("TEST 11 - Meyer: All Pixels Pre-Marked");
   Put_Line("  1.11 Assume code overwrites fully marked initial states");
   Mkr_3x3 := (others => (others => 9));
   Meyer_Watershed(Img_3x3, Mkr_3x3, Res_3x3);
   Assert(Res_3x3(2,2) = 9, "Pre-marked state altered");
   Pass("Pre-marked state preserved entirely");

   -- TEST 12
   Put_Line("TEST 12 - Meyer: No Markers Given");
   Put_Line("  1.12 Assume Priority Queue crashes when initialized empty");
   Mkr_3x3 := (others => (others => UNLABELED));
   Meyer_Watershed(Img_3x3, Mkr_3x3, Res_3x3);
   Assert(Res_3x3(1,1) = UNLABELED, "Unexpected label generated");
   Pass("Handled 0-marker initiation smoothly");

   -- TEST 13
   Put_Line("TEST 13 - Boundary Limitations");
   Put_Line("  1.13 Assume edges wrap around to other side of array");
   declare
      Img_Bound : Image_Grid(1..3, 1..3) := ((0, 10, 10), (10, 10, 10), (10, 10, 0));
      Res_Bound : Label_Grid(1..3, 1..3);
   begin
      Immersion_Watershed(Img_Bound, Res_Bound);
      Assert(Res_Bound(1,1) /= Res_Bound(3,3), "Edges wrapped inappropriately");
      Pass("Strict boundary checking maintained");
   end;

   Put_Line("===========================================");
   Put_Line("ALL 13 TESTS PASSED SUCCESSFULLY");
   Put_Line("===========================================");

end Tests;
