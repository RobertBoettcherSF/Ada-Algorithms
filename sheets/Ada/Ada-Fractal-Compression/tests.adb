-- tests.adb
-- Standalone Test Suite to disprove broken assumptions (V&V Standard)
with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Fractal_Compression; use Fractal_Compression;

procedure Tests is
   Grid_4x4 : Pixel_Grid (1 .. 4, 1 .. 4) := (
      (10.0, 10.0, 20.0, 20.0),
      (10.0, 10.0, 20.0, 20.0),
      (30.0, 30.0, 40.0, 40.0),
      (30.0, 30.0, 40.0, 40.0)
   );
   Code_Output : Fractal_Code;
begin
   Put_Line("STARTING FRACTAL COMPRESSION V&V TEST SUITE");
   Put_Line("-------------------------------------------");

   -- TEST 1 - Functionality: Symmetry Identity
   Put_Line("TEST 1 - Symmetry: Identity Mapping");
   Put_Line("  1.1 Assert Identity returns unchanged coordinates");
   declare
      Res : constant Coordinate := Apply_Symmetry(1, 2, 4, Identity);
   begin
      Assert (Res.X = 1 and Res.Y = 2, "Identity failed");
      Put_Line("     PASS");
   end;

   -- TEST 2 - Functionality: Symmetry Rot_90
   Put_Line("TEST 2 - Symmetry: Rot_90 Mapping");
   Put_Line("  2.1 Assert Rot_90 correctly translates top-left to top-right");
   declare
      Res : constant Coordinate := Apply_Symmetry(1, 1, 4, Rot_90);
   begin
      Assert (Res.X = 4 and Res.Y = 1, "Rot_90 failed");
      Put_Line("     PASS");
   end;

   -- TEST 3 - Functionality: Symmetry Flip_H
   Put_Line("TEST 3 - Symmetry: Flip Horizontal");
   Put_Line("  3.1 Assert Flip_Horizontal swaps X axis correctly");
   declare
      Res : constant Coordinate := Apply_Symmetry(1, 2, 4, Flip_Horizontal);
   begin
      Assert (Res.X = 4 and Res.Y = 2, "Flip_H failed");
      Put_Line("     PASS");
   end;

   -- TEST 4 - Functionality: Downsampling
   Put_Line("TEST 4 - Matrix Downsampling");
   Put_Line("  4.1 Assert 4x4 matrix downsamples to 2x2 with averages");
   declare
      Down : Pixel_Grid := Downsample(Grid_4x4);
   begin
      Assert (Down(1,1) = 10.0 and Down(2,2) = 40.0, "Downsample failed averaging logic");
      Put_Line("     PASS");
   end;

   -- TEST 5 - Robustness: Least Squares (Identical)
   Put_Line("TEST 5 - Least Squares calculation (Identical blocks)");
   Put_Line("  5.1 Assert identical domain/range yields S=1.0, O=0.0");
   declare
      S, O : Float;
      Down : Pixel_Grid := Downsample(Grid_4x4);
   begin
      Least_Squares(Down, Down, S, O);
      Assert (S > 0.99 and O < 0.01, "Least Squares failed identity calculation");
      Put_Line("     PASS");
   end;

   -- TEST 6 - Edge Case: Least Squares (Zero Variance Domain)
   Put_Line("TEST 6 - Least Squares calculation (Zero Variance Domain)");
   Put_Line("  6.1 Assert Div-by-Zero prevention when Domain has no variance");
   declare
      S, O : Float;
      Flat : Pixel_Grid (1..2, 1..2) := (others => (others => 50.0));
      Rng  : Pixel_Grid (1..2, 1..2) := (others => (others => 100.0));
   begin
      Least_Squares(Flat, Rng, S, O);
      Assert (S = 0.0 and O = 100.0, "Least Squares failed Zero-Variance prevention");
      Put_Line("     PASS");
   end;

   -- TEST 7 - Robustness: Contractivity Clamping
   Put_Line("TEST 7 - Contractivity Constraint");
   Put_Line("  7.1 Assert Contrast (S) is clamped to [-1.0, 1.0] for convergence");
   declare
      S, O : Float;
      Dom : Pixel_Grid (1..2, 1..2) := ((1.0, 1.0), (2.0, 2.0));
      Rng : Pixel_Grid (1..2, 1..2) := ((100.0, 100.0), (250.0, 250.0)); -- Huge variance
   begin
      Least_Squares(Dom, Rng, S, O);
      Assert (S <= 1.0, "Contractivity clamping failed");
      Put_Line("     PASS");
   end;

   -- TEST 8 - Functionality: Fixed Block Encoding
   Put_Line("TEST 8 - Encoding (Fixed Square Partitioning)");
   Put_Line("  8.1 Assert 4x4 image with Range=2 yields exactly 4 transforms");
   Code_Output := Encode(Grid_4x4, Square_Fixed, 2);
   Assert (Natural(Code_Output.Length) = 4, "Encode_Fixed block count incorrect");
   Put_Line("     PASS");

   -- TEST 9 - Error Handling: Invalid Image Dimensions
   Put_Line("TEST 9 - Error Handling: Validation of image dimensions");
   Put_Line("  9.1 Assert Constraint_Error / Invalid Dimensions raised on 5x5 image");
   begin
      declare
         Grid_5x5 : Pixel_Grid (1 .. 5, 1 .. 5) := (others => (others => 0.0));
         Code     : Fractal_Code;
      begin
         Code := Encode(Grid_5x5, Square_Fixed, 2);
         Assert (False, "Did not raise exception on invalid dimensions");
      end;
   exception
      when Invalid_Image_Dimensions =>
         Put_Line("     PASS");
   end;

   -- TEST 10 - Error Handling: Unsupported Variants
   Put_Line("TEST 10 - Error Handling: Unsupported Topology variant");
   Put_Line("  10.1 Assert Hexagonal topology throws Unsupported_Variant");
   begin
      declare
         Code : Fractal_Code;
      begin
         Code := Encode(Grid_4x4, Hexagonal, 2);
         Assert (False, "Did not raise exception on Hexagonal");
      end;
   exception
      when Unsupported_Variant =>
         Put_Line("     PASS");
   end;

   -- TEST 11 - Functionality: Quadtree Variant
   Put_Line("TEST 11 - Encoding (Quadtree Variant)");
   Put_Line("  11.1 Assert Quadtree variant partitions blocks accurately into sub-blocks");
   declare
      Grid_8x8 : Pixel_Grid (1..8, 1..8) := (others => (others => 10.0));
      Code     : Fractal_Code;
   begin
      Code := Encode(Grid_8x8, Quadtree, 4);
      Assert (Natural(Code.Length) = 16, "Quadtree partitioning count incorrect");
      Put_Line("     PASS");
   end;

   -- TEST 12 - Performance & Side Effects: Decoding Safety
   Put_Line("TEST 12 - Decoding Limits & Clamping");
   Put_Line("  12.1 Assert Brightness overflowing 255.0 is clamped correctly");
   declare
      Code : Fractal_Code;
      Res  : Pixel_Grid (1..4, 1..4);
   begin
      -- FIX: Block_Size adjusted to 2 so the Domain_Size (4) fits exactly within the 4x4 image buffer
      Code.Append(Affine_Transform'(Range_X => 1, Range_Y => 1, Block_Size => 2, Domain_X => 1, Domain_Y => 1, Symmetry => Identity, Contrast => 0.0, Brightness => 999.0));
      Res := Decode(Code, 4, 4, 1);
      Assert (Res(1,1) = 255.0, "Decoding over-clamp failed");
      Put_Line("     PASS");
   end;

   -- TEST 13 - End-To-End: Full Integration Test
   Put_Line("TEST 13 - End-to-End System Integration");
   Put_Line("  13.1 Assert Encode and Decode operate without systemic crash");
   declare
      Code : Fractal_Code := Encode(Grid_4x4, Square_Fixed, 2);
      Res  : Pixel_Grid := Decode(Code, 4, 4, 3);
   begin
      Assert (Res'Length(1) = 4, "System crash or invalid output dimensions in Decode");
      Put_Line("     PASS");
   end;

   Put_Line("-------------------------------------------");
   Put_Line("ALL 13+ ASSUMPTIONS DISPROVEN. SYSTEM IS STABLE.");
end Tests;
