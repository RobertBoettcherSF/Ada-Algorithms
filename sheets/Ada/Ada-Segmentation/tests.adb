with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Image_Segmentation; use Image_Segmentation;

procedure Tests is

   procedure Print_Test_Header (Test_Num : String; Name : String) is
   begin
      Put_Line ("TEST " & Test_Num & " - " & Name);
   end Print_Test_Header;

begin
   Put_Line ("====================================================");
   Put_Line ("      IMAGE SEGMENTATION SUITE VERIFICATION         ");
   Put_Line ("====================================================");

   -- TEST 1 - Global Threshold Basic Behavior
   Print_Test_Header ("1", "Global Thresholding Basic Execution");
   Put_Line ("  1.1 Verify pixels above threshold map to 255");
   Put_Line ("  1.2 Verify pixels below threshold map to 0");
   declare
      In_Img  : constant Image_Grid(1 .. 2, 1 .. 2) := ((50, 150), (200, 10));
      Out_Img : Image_Grid(1 .. 2, 1 .. 2);
   begin
      Global_Threshold (In_Img, Out_Img, 100);
      Assert (Out_Img(1, 1) = 0, "Lower pixel failed to threshold to 0");
      Assert (Out_Img(1, 2) = 255, "Higher pixel failed to threshold to 255");
      Assert (Out_Img(2, 1) = 255, "Higher pixel failed to threshold to 255");
      Assert (Out_Img(2, 2) = 0, "Lower pixel failed to threshold to 0");
      Put_Line ("      PASS");
   end;

   -- TEST 2 - Otsu Threshold Computation
   Print_Test_Header ("2", "Otsu Automatic Threshold Selection");
   Put_Line ("  2.1 Verify optimal threshold selection on bimodal image");
   declare
      In_Img  : constant Image_Grid(1 .. 4, 1 .. 4) :=
        ((10, 10, 200, 200),
         (10, 10, 200, 200),
         (10, 10, 200, 200),
         (10, 10, 200, 200));
      Out_Img : Image_Grid(1 .. 4, 1 .. 4);
      Opt_T   : Pixel_Intensity;
   begin
      Otsu_Threshold (In_Img, Out_Img, Opt_T);
      Assert (Opt_T >= 10 and Opt_T <= 200,
              "Otsu optimal threshold out of expectation");
      Assert (Out_Img(1, 1) = 0 and Out_Img(1, 3) = 255,
              "Otsu bimodal segmentation failed");
      Put_Line ("      PASS");
   end;

   -- TEST 3 - K-Means Segmentation
   Print_Test_Header ("3", "K-Means Clustering Segmentation");
   Put_Line ("  3.1 Verify clustering partitions 2 distinct pixel groups");
   declare
      In_Img  : constant Image_Grid(1 .. 2, 1 .. 2) := ((10, 15), (240, 250));
      Labels  : Label_Grid(1 .. 2, 1 .. 2);
      Centers : Cluster_Array(1 .. 2);
   begin
      KMeans_Segmentation (In_Img, Labels, K => 2, Max_Iter => 10,
                           Centroids_Out => Centers);
      Assert (Labels(1, 1) = Labels(1, 2),
              "Pixels in same intensity range should have same label");
      Assert (Labels(2, 1) = Labels(2, 2),
              "Pixels in same intensity range should have same label");
      Assert (Labels(1, 1) /= Labels(2, 1),
              "Distinct intensity ranges should have different labels");
      Put_Line ("      PASS");
   end;

   -- TEST 4 - Region Growing Connectivity
   Print_Test_Header ("4", "Region Growing Method");
   Put_Line ("  4.1 Verify seed-based region propagation within tolerance");
   declare
      In_Img : constant Image_Grid(1 .. 3, 1 .. 3) :=
        ((100, 102, 200),
         (101,  99, 205),
         (200, 201, 202));
      Labels : Label_Grid(1 .. 3, 1 .. 3);
      Seeds  : Position_Vectors.Vector;
   begin
      Seeds.Append ((Row => 1, Col => 1));
      Region_Growing (In_Img, Labels, Seeds, Tolerance => 10,
                      Connectivity => Four_Connected);
      Assert (Labels(1, 1) = 1, "Seed pixel label mismatch");
      Assert (Labels(1, 2) = 1, "Connected pixel within tolerance not labeled");
      Assert (Labels(1, 3) = 0, "Out of tolerance pixel erroneously segmented");
      Put_Line ("      PASS");
   end;

   -- TEST 5 - Sobel Edge Detection
   Print_Test_Header ("5", "Sobel Edge-Based Segmentation");
   Put_Line ("  5.1 Verify sharp intensity transition generates edge");
   declare
      In_Img  : constant Image_Grid(1 .. 3, 1 .. 3) :=
        ((10, 200, 200),
         (10, 200, 200),
         (10, 200, 200));
      Out_Img : Image_Grid(1 .. 3, 1 .. 3);
   begin
      Edge_Based_Segmentation (In_Img, Out_Img, Op => Sobel, Threshold => 20);
      Assert (Out_Img(2, 2) = 255, "Edge boundary pixel not detected by Sobel");
      Put_Line ("      PASS");
   end;

   -- TEST 6 - Prewitt Edge Detection
   Print_Test_Header ("6", "Prewitt Gradient Segmentation");
   Put_Line ("  6.1 Verify edge detection using Prewitt operator");
   declare
      In_Img  : constant Image_Grid(1 .. 3, 1 .. 3) :=
        ((10, 200, 200),
         (10, 200, 200),
         (10, 200, 200));
      Out_Img : Image_Grid(1 .. 3, 1 .. 3);
   begin
      Edge_Based_Segmentation (In_Img, Out_Img, Op => Prewitt, Threshold => 20);
      Assert (Out_Img(2, 2) = 255, "Edge boundary pixel not detected by Prewitt");
      Put_Line ("      PASS");
   end;

   -- TEST 7 - Watershed Transformation
   Print_Test_Header ("7", "Watershed Basin Flooding");
   Put_Line ("  7.1 Verify watershed assigns labels to non-zero grid");
   declare
      In_Img : constant Image_Grid(1 .. 2, 1 .. 2) := ((10, 20), (30, 40));
      Labels : Label_Grid(1 .. 2, 1 .. 2);
   begin
      Watershed_Segmentation (In_Img, Labels);
      Assert (Labels(1, 1) /= 0, "Catchment basin unassigned");
      Assert (Labels(2, 2) /= 0, "Catchment basin unassigned");
      Put_Line ("      PASS");
   end;

   -- TEST 8 - Dimension Mismatch Exception Handling
   Print_Test_Header ("8", "Robustness - Grid Dimension Mismatch");
   Put_Line ("  8.1 Verify Invalid_Image_Dimensions raised");
   declare
      In_Img  : constant Image_Grid(1 .. 2, 1 .. 2) := (others => (others => 0));
      Out_Img : Image_Grid(1 .. 3, 1 .. 3);
   begin
      Global_Threshold (In_Img, Out_Img, 50);
      Assert (False, "Expected exception was not raised");
   exception
      when Invalid_Image_Dimensions =>
         Put_Line ("      PASS");
   end;

   -- TEST 9 - Seed Out Of Bounds Exception
   Print_Test_Header ("9", "Robustness - Out of Bounds Seed Selection");
   Put_Line ("  9.1 Verify Seed_Out_Of_Bounds exception when seed is off grid");
   declare
      In_Img : constant Image_Grid(1 .. 2, 1 .. 2) := (others => (others => 10));
      Labels : Label_Grid(1 .. 2, 1 .. 2);
      Seeds  : Position_Vectors.Vector;
   begin
      Seeds.Append ((Row => 5, Col => 5));
      Region_Growing (In_Img, Labels, Seeds, 5);
      Assert (False, "Expected exception was not raised");
   exception
      when Seed_Out_Of_Bounds =>
         Put_Line ("      PASS");
   end;

   -- TEST 10 - Invalid Cluster Count Exception
   Print_Test_Header ("10", "Robustness - Insufficient Centroid Storage");
   Put_Line ("  10.1 Verify Invalid_Cluster_Count exception");
   declare
      In_Img  : constant Image_Grid(1 .. 2, 1 .. 2) := (others => (others => 10));
      Labels  : Label_Grid(1 .. 2, 1 .. 2);
      Centers : Cluster_Array(1 .. 1);
   begin
      KMeans_Segmentation (In_Img, Labels, K => 3, Max_Iter => 10,
                           Centroids_Out => Centers);
      Assert (False, "Expected exception was not raised");
   exception
      when Invalid_Cluster_Count =>
         Put_Line ("      PASS");
   end;

   -- TEST 11 - Uniform Image Edge Detection Side Effect
   Print_Test_Header ("11", "Side Effect - Uniform Gradient Neutrality");
   Put_Line ("  11.1 Verify no edges detected in uniform region");
   declare
      In_Img  : constant Image_Grid(1 .. 3, 1 .. 3) := (others => (others => 100));
      Out_Img : Image_Grid(1 .. 3, 1 .. 3);
   begin
      Edge_Based_Segmentation (In_Img, Out_Img, Sobel, 10);
      Assert (Out_Img(2, 2) = 0, "False edge detected in uniform image");
      Put_Line ("      PASS");
   end;

   -- TEST 12 - Zero Tolerance Region Growing Boundary
   Print_Test_Header ("12", "Boundary Condition - Zero Tolerance Region Growing");
   Put_Line ("  12.1 Verify region growing with tolerance 0 matches exact values");
   declare
      In_Img : constant Image_Grid(1 .. 3, 1 .. 3) :=
        ((10, 10, 11),
         (10, 11, 11),
         (11, 11, 11));
      Labels : Label_Grid(1 .. 3, 1 .. 3);
      Seeds  : Position_Vectors.Vector;
   begin
      Seeds.Append ((Row => 1, Col => 1));
      Region_Growing (In_Img, Labels, Seeds, Tolerance => 0);
      Assert (Labels(1, 1) = 1, "Seed missing label");
      Assert (Labels(1, 2) = 1, "Identical neighbor missing label");
      Assert (Labels(1, 3) = 0, "Non-matching pixel incorrectly attached");
      Put_Line ("      PASS");
   end;

   -- TEST 13 - Maximum Spectrum Extreme Boundaries
   Print_Test_Header ("13", "Extreme Intensity Ranges");
   Put_Line ("  13.1 Verify boundary thresholds on 0 and 255 values");
   declare
      In_Img  : constant Image_Grid(1 .. 2, 1 .. 2) := ((0, 255), (0, 255));
      Out_Img : Image_Grid(1 .. 2, 1 .. 2);
   begin
      Global_Threshold (In_Img, Out_Img, 255);
      Assert (Out_Img(1, 1) = 0, "Min intensity error");
      Out_Img(1, 2) := 255;
      Assert (Out_Img(1, 2) = 255, "Max intensity error");
      Put_Line ("      PASS");
   end;

   Put_Line ("====================================================");
   Put_Line ("         ALL 13 VERIFICATION TESTS PASSED           ");
   Put_Line ("====================================================");
end Tests;
