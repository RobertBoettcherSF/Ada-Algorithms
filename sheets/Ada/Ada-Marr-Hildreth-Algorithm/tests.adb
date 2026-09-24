-- tests.adb
-- Standalone Verification & Validation test suite disproving defect assumptions.

with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Marr_Hildreth; use Marr_Hildreth;

procedure Tests is

   -- Helper to print test result
   procedure Print_Pass (Test_Num : String; Desc : String) is
   begin
      Put_Line ("  " & Test_Num & " " & Desc);
      Put_Line ("     PASS");
   end Print_Pass;

begin
   Put_Line ("=== Running Marr-Hildreth Verification & Validation Suite ===");
   New_Line;

   -----------------------------------------------------------------------------
   -- TEST 1 - Parameter Validation
   -----------------------------------------------------------------------------
   Put_Line ("TEST 1 - Parameter Validation Handling");
   declare
      P_Valid   : Parameters := (Sigma => 1.0, Sigma_Ratio => 1.6, Kernel_Dim => 5, Threshold => 0.01);
      P_Invalid : Parameters := (Sigma => -0.5, Sigma_Ratio => 1.6, Kernel_Dim => 5, Threshold => 0.01);
      P_Even    : Parameters := (Sigma => 1.0, Sigma_Ratio => 1.6, Kernel_Dim => 4, Threshold => 0.01);
   begin
      -- 1.1 Valid parameters return True
      Assert (Validate_Parameters (P_Valid), "Valid parameters rejected");
      Print_Pass ("1.1", "Assert valid parameters return True");

      -- 1.2 Negative sigma returns False
      Assert (not Validate_Parameters (P_Invalid), "Invalid sigma accepted");
      Print_Pass ("1.2", "Assert negative sigma returns False");

      -- 1.3 Even kernel size returns False
      Assert (not Validate_Parameters (P_Even), "Even kernel dimension accepted");
      Print_Pass ("1.3", "Assert even kernel dimension returns False");
   end;

   -----------------------------------------------------------------------------
   -- TEST 2 - LoG Kernel Generation Symmetry
   -----------------------------------------------------------------------------
   Put_Line ("TEST 2 - LoG Kernel Symmetry Verification");
   declare
      P : Parameters := (Sigma => 1.0, Sigma_Ratio => 1.6, Kernel_Dim => 5, Threshold => 0.01);
      K : Image_Grid := Create_LoG_Kernel (P);
   begin
      -- 2.1 Center element checked
      Assert (K (3, 3) /= 0.0, "Kernel center value is zero");
      Print_Pass ("2.1", "Assert LoG center element non-zero");

      -- 2.2 Horizontal symmetry
      Assert (K (3, 1) = K (3, 5), "Kernel horizontal asymmetry detected");
      Print_Pass ("2.2", "Assert LoG horizontal symmetry");

      -- 2.3 Vertical symmetry
      Assert (K (1, 3) = K (5, 3), "Kernel vertical asymmetry detected");
      Print_Pass ("2.3", "Assert LoG vertical symmetry");
   end;

   -----------------------------------------------------------------------------
   -- TEST 3 - DoG Kernel Generation Validity
   -----------------------------------------------------------------------------
   Put_Line ("TEST 3 - DoG Kernel Approximation Generation");
   declare
      P : Parameters := (Sigma => 1.0, Sigma_Ratio => 1.6, Kernel_Dim => 5, Threshold => 0.01);
      K : Image_Grid := Create_DoG_Kernel (P);
   begin
      -- 3.1 Non-empty matrix produced
      Assert (K'Length (1) = 5 and K'Length (2) = 5, "Invalid DoG dimensions");
      Print_Pass ("3.1", "Assert DoG kernel dimension matches request");

      -- 3.2 Diagonal symmetry
      Assert (K (1, 5) = K (5, 1), "DoG diagonal asymmetry");
      Print_Pass ("3.2", "Assert DoG diagonal symmetry");

      -- 3.3 Center peak calculation
      Assert (K (3, 3) /= 0.0, "DoG center zero");
      Print_Pass ("3.3", "Assert DoG center value non-zero");
   end;

   -----------------------------------------------------------------------------
   -- TEST 4 - Zero-Crossing Uniform Field Handling
   -----------------------------------------------------------------------------
   Put_Line ("TEST 4 - Zero Crossing on Flat/Uniform Image");
   declare
      Flat  : Image_Grid (1 .. 10, 1 .. 10) := (others => (others => 50.0));
      Edges : Edge_Grid (1 .. 10, 1 .. 10);
      P     : Parameters := (Sigma => 1.0, Sigma_Ratio => 1.6, Kernel_Dim => 5, Threshold => 0.01);
   begin
      Detect_Edges_LoG (Flat, Edges, P);

      -- 4.1 Flat image produces no edge at center
      Assert (Edges (5, 5) = Background, "False edge detected in flat image");
      Print_Pass ("4.1", "Assert no edge in uniform background");

      -- 4.2 Edge count total is 0
      declare
         Count : Natural := 0;
      begin
         for I in Edges'Range (1) loop
            for J in Edges'Range (2) loop
               if Edges (I, J) = Edge then Count := Count + 1; end if;
            end loop;
         end loop;
         Assert (Count = 0, "Non-zero edges found on flat image");
         Print_Pass ("4.2", "Assert total edge count is zero");
      end;

      -- 4.3 Border remains background
      Assert (Edges (1, 1) = Background, "Border improperly assigned edge");
      Print_Pass ("4.3", "Assert border pixels remain Background");
   end;

   -----------------------------------------------------------------------------
   -- TEST 5 - Vertical Step Edge Detection (LoG)
   -----------------------------------------------------------------------------
   Put_Line ("TEST 5 - Vertical Step Edge Detection (LoG)");
   declare
      Img   : Image_Grid (1 .. 10, 1 .. 10) := (others => (others => 0.0));
      Edges : Edge_Grid (1 .. 10, 1 .. 10);
      P     : Parameters := (Sigma => 1.0, Sigma_Ratio => 1.6, Kernel_Dim => 5, Threshold => 0.01);
   begin
      -- Set right half to bright intensity
      for I in 1 .. 10 loop
         for J in 6 .. 10 loop
            Img (I, J) := 100.0;
         end loop;
      end loop;

      Detect_Edges_LoG (Img, Edges, P);

      -- 5.1 Step edge detected along boundary column 5
      Assert (Edges (5, 5) = Edge, "Vertical edge missed");
      Print_Pass ("5.1", "Assert step edge boundary pixel marked as Edge");

      -- 5.2 Interior pixels are background
      Assert (Edges (5, 2) = Background, "Interior pixel falsely marked as edge");
      Print_Pass ("5.2", "Assert homogeneous region marked Background");

      -- 5.3 Far right region is background
      Assert (Edges (5, 9) = Background, "Bright plateau falsely marked as edge");
      Print_Pass ("5.3", "Assert plateau area marked Background");
   end;

   -----------------------------------------------------------------------------
   -- TEST 6 - Horizontal Step Edge Detection (DoG)
   -----------------------------------------------------------------------------
   Put_Line ("TEST 6 - Horizontal Step Edge Detection (DoG)");
   declare
      Img   : Image_Grid (1 .. 10, 1 .. 10) := (others => (others => 0.0));
      Edges : Edge_Grid (1 .. 10, 1 .. 10);
      P     : Parameters := (Sigma => 1.0, Sigma_Ratio => 1.6, Kernel_Dim => 5, Threshold => 0.01);
   begin
      for I in 6 .. 10 loop
         for J in 1 .. 10 loop
            Img (I, J) := 100.0;
         end loop;
      end loop;

      Detect_Edges_DoG (Img, Edges, P);

      -- 6.1 Horizontal boundary detected
      Assert (Edges (5, 5) = Edge, "Horizontal edge missed in DoG");
      Print_Pass ("6.1", "Assert DoG detects horizontal step edge");

      -- 6.2 Off-edge background check
      Assert (Edges (2, 5) = Background, "False positive edge in top region");
      Print_Pass ("6.2", "Assert non-edge region correctly marked Background");

      -- 6.3 Lower region check
      Assert (Edges (8, 5) = Background, "False positive edge in bottom region");
      Print_Pass ("6.3", "Assert lower region marked Background");
   end;

   -----------------------------------------------------------------------------
   -- TEST 7 - Exception Handling for Dimension Mismatch
   -----------------------------------------------------------------------------
   Put_Line ("TEST 7 - Image Bounds Mismatch Exception Handling");
   declare
      Img   : Image_Grid (1 .. 5, 1 .. 5) := (others => (others => 0.0));
      Edges : Edge_Grid (1 .. 10, 1 .. 10);
      P     : Parameters;
   begin
      Detect_Edges_LoG (Img, Edges, P);
      Assert (False, "Failed to raise Invalid_Image_Bounds");
   exception
      when Invalid_Image_Bounds =>
         Print_Pass ("7.1", "Assert Invalid_Image_Bounds raised on dimension mismatch");
   end;

   -----------------------------------------------------------------------------
   -- TEST 8 - Exception Handling for Invalid Parameters
   -----------------------------------------------------------------------------
   Put_Line ("TEST 8 - Invalid Parameter Execution Exception");
   declare
      Img   : Image_Grid (1 .. 5, 1 .. 5) := (others => (others => 0.0));
      Edges : Edge_Grid (1 .. 5, 1 .. 5);
      P     : Parameters := (Sigma => -1.0, Sigma_Ratio => 1.6, Kernel_Dim => 5, Threshold => 0.01);
   begin
      Detect_Edges_LoG (Img, Edges, P);
      Assert (False, "Failed to raise Invalid_Parameters");
   exception
      when Invalid_Parameters =>
         Print_Pass ("8.1", "Assert Invalid_Parameters raised on execution with bad parameters");
   end;

   -----------------------------------------------------------------------------
   -- TEST 9 - Threshold Filter Suppression
   -----------------------------------------------------------------------------
   Put_Line ("TEST 9 - High Threshold Suppression Verification");
   declare
      Img   : Image_Grid (1 .. 10, 1 .. 10) := (others => (others => 0.0));
      Edges : Edge_Grid (1 .. 10, 1 .. 10);
      P     : Parameters := (Sigma => 1.0, Sigma_Ratio => 1.6, Kernel_Dim => 5, Threshold => 500.0);
   begin
      -- Weak step edge
      for I in 1 .. 10 loop
         for J in 6 .. 10 loop
            Img (I, J) := 5.0;
         end loop;
      end loop;

      Detect_Edges_LoG (Img, Edges, P);

      -- 9.1 High threshold suppresses weak edge
      Assert (Edges (5, 5) = Background, "Weak edge was not suppressed by high threshold");
      Print_Pass ("9.1", "Assert high threshold suppresses weak zero-crossings");
   end;

   -----------------------------------------------------------------------------
   -- TEST 10 - Diagonal Edge Detection
   -----------------------------------------------------------------------------
   Put_Line ("TEST 10 - Diagonal Edge Detection Analysis");
   declare
      Img   : Image_Grid (1 .. 10, 1 .. 10) := (others => (others => 0.0));
      Edges : Edge_Grid (1 .. 10, 1 .. 10);
      P     : Parameters := (Sigma => 1.0, Sigma_Ratio => 1.6, Kernel_Dim => 5, Threshold => 0.01);
   begin
      for I in 1 .. 10 loop
         for J in 1 .. 10 loop
            if I >= J then Img (I, J) := 100.0; end if;
         end loop;
      end loop;

      Detect_Edges_LoG (Img, Edges, P);

      -- 10.1 Point on diagonal boundary detected
      Assert (Edges (5, 5) = Edge, "Diagonal edge not detected");
      Print_Pass ("10.1", "Assert diagonal edge is detected");
   end;

   -----------------------------------------------------------------------------
   -- TEST 11 - Minimum Grid Bounds Boundary Case
   -----------------------------------------------------------------------------
   Put_Line ("TEST 11 - Minimum Grid Size Execution");
   declare
      Img   : Image_Grid (1 .. 3, 1 .. 3) := (others => (others => 10.0));
      Edges : Edge_Grid (1 .. 3, 1 .. 3);
      P     : Parameters := (Sigma => 1.0, Sigma_Ratio => 1.6, Kernel_Dim => 3, Threshold => 0.01);
   begin
      Detect_Edges_LoG (Img, Edges, P);
      Assert (Edges (2, 2) = Background, "Unexpected edge on 3x3 uniform image");
      Print_Pass ("11.1", "Assert 3x3 minimal input processed successfully");
   end;

   -----------------------------------------------------------------------------
   -- TEST 12 - Large Kernel Execution
   -----------------------------------------------------------------------------
   Put_Line ("TEST 12 - Large Kernel Parameters Test");
   declare
      P : Parameters := (Sigma => 2.0, Sigma_Ratio => 1.6, Kernel_Dim => 9, Threshold => 0.01);
      K : Image_Grid := Create_LoG_Kernel (P);
   begin
      Assert (K'Length (1) = 9 and K'Length (2) = 9, "9x9 LoG kernel dimension incorrect");
      Print_Pass ("12.1", "Assert 9x9 LoG kernel created with valid bounds");
   end;

   -----------------------------------------------------------------------------
   -- TEST 13 - Single Impulse/Point Detection
   -----------------------------------------------------------------------------
   Put_Line ("TEST 13 - Single Point Impulse Edge Detection");
   declare
      Img   : Image_Grid (1 .. 9, 1 .. 9) := (others => (others => 0.0));
      Edges : Edge_Grid (1 .. 9, 1 .. 9);
      P     : Parameters := (Sigma => 1.0, Sigma_Ratio => 1.6, Kernel_Dim => 5, Threshold => 0.001);
   begin
      Img (5, 5) := 255.0; -- Impulse in center
      Detect_Edges_LoG (Img, Edges, P);

      -- Impulse will produce zero crossings around point
      Assert (Edges (5, 4) = Edge or Edges (5, 6) = Edge or Edges (4, 5) = Edge or Edges (6, 5) = Edge,
              "Impulse point failed to trigger zero-crossing");
      Print_Pass ("13.1", "Assert point impulse triggers surrounding zero-crossing edges");
   end;

   New_Line;
   Put_Line ("=== ALL 13+ VERIFICATION TESTS PASSED SUCCESSFULLY ===");
end Tests;
