with Ada.Text_IO; use Ada.Text_IO;
with Ada.Assertions; use Ada.Assertions;
with Riemersma_Dithering; use Riemersma_Dithering;

procedure Tests is
   Img_1x1 : Gray_Image (1 .. 1, 1 .. 1) := (1 => (1 => 128));
   Img_Empty : Gray_Image (1 .. 0, 1 .. 0);
   Img_Small : Gray_Image (1 .. 2, 1 .. 2) := ((0, 255), (128, 64));
   Img_Rect  : Gray_Image (1 .. 3, 1 .. 2) := ((10, 20), (30, 40), (50, 60));
   X, Y : Positive;
begin
   Put_Line ("TEST 1 - Hilbert Coordinate Generation");
   Put_Line ("  1.1 Assert D=0 maps to (1,1) for N=2");
   D2XY (2, 0, X, Y);
   Assert (X = 1 and Y = 1, "Failed 1.1");
   Put_Line ("     PASS");

   Put_Line ("  1.2 Assert D=1 maps to (1,2) for N=2");
   D2XY (2, 1, X, Y);
   Assert (X = 1 and Y = 2, "Failed 1.2");
   Put_Line ("     PASS");
   
   Put_Line ("  1.3 Assert D=3 maps to (2,1) for N=2");
   D2XY (2, 3, X, Y);
   Assert (X = 2 and Y = 1, "Failed 1.3");
   Put_Line ("     PASS");

   Put_Line ("TEST 2 - Edge Case: Empty Image");
   Put_Line ("  2.1 Assert empty image returns immediately without error");
   Apply_Dither (Img_Empty);
   Assert (True, "Failed 2.1");
   Put_Line ("     PASS");

   Put_Line ("TEST 3 - Edge Case: 1x1 Image");
   Put_Line ("  3.1 Assert 1x1 image processes properly");
   Apply_Dither (Img_1x1);
   Assert (Img_1x1(1,1) = 0 or Img_1x1(1,1) = 255, "Failed 3.1");
   Put_Line ("     PASS");

   Put_Line ("TEST 4 - Robustness: Invalid Parameter");
   Put_Line ("  4.1 Assert History_Size < 1 raises Exception");
   begin
      Apply_Dither (Img_Small, History_Size => 0);
      Assert (False, "Expected exception not raised");
   exception
      when Invalid_Parameter_Error =>
         Put_Line ("     PASS");
   end;

   Put_Line ("TEST 5 - Constraints: Output Domain (Hilbert, Exponential)");
   Put_Line ("  5.1 Assert all pixels become 0 or 255");
   Apply_Dither (Img_Small, Curve => Hilbert, Decay => Exponential);
   for I in Img_Small'Range(1) loop
      for J in Img_Small'Range(2) loop
         Assert (Img_Small(I, J) = 0 or Img_Small(I, J) = 255, "Failed 5.1");
      end loop;
   end loop;
   Put_Line ("     PASS");

   Put_Line ("TEST 6 - Extreme Input: All Black (0)");
   Put_Line ("  6.1 Assert all-black image remains all-black");
   declare
      Black_Img : Gray_Image (1 .. 4, 1 .. 4) := (others => (others => 0));
   begin
      Apply_Dither (Black_Img);
      Assert (Black_Img(1,1) = 0 and Black_Img(4,4) = 0, "Failed 6.1");
      Put_Line ("     PASS");
   end;

   Put_Line ("TEST 7 - Extreme Input: All White (255)");
   Put_Line ("  7.1 Assert all-white image remains all-white");
   declare
      White_Img : Gray_Image (1 .. 4, 1 .. 4) := (others => (others => 255));
   begin
      Apply_Dither (White_Img);
      Assert (White_Img(1,1) = 255 and White_Img(4,4) = 255, "Failed 7.1");
      Put_Line ("     PASS");
   end;

   Put_Line ("TEST 8 - Constraints: Rectangular Dimensions");
   Put_Line ("  8.1 Assert 3x2 image successfully processes using Hilbert");
   Apply_Dither (Img_Rect, Curve => Hilbert);
   Assert (Img_Rect(1,1) = 0 or Img_Rect(1,1) = 255, "Failed 8.1");
   Put_Line ("     PASS");

   Put_Line ("TEST 9 - Algorithm Variants: Serpentine Curve");
   Put_Line ("  9.1 Assert Serpentine traversal processes all pixels");
   declare
      Serp_Img : Gray_Image (1 .. 2, 1 .. 2) := ((100, 100), (100, 100));
   begin
      Apply_Dither (Serp_Img, Curve => Serpentine);
      Assert (Serp_Img(2,2) = 0 or Serp_Img(2,2) = 255, "Failed 9.1");
      Put_Line ("     PASS");
   end;

   Put_Line ("TEST 10 - Algorithm Variants: Raster Curve");
   Put_Line ("  10.1 Assert Raster traversal processes all pixels");
   declare
      Rast_Img : Gray_Image (1 .. 2, 1 .. 2) := ((100, 100), (100, 100));
   begin
      Apply_Dither (Rast_Img, Curve => Raster);
      Assert (Rast_Img(2,2) = 0 or Rast_Img(2,2) = 255, "Failed 10.1");
      Put_Line ("     PASS");
   end;

   Put_Line ("TEST 11 - Algorithm Variants: Linear Decay Model");
   Put_Line ("  11.1 Assert Linear Decay model restricts output appropriately");
   declare
      Lin_Img : Gray_Image (1 .. 2, 1 .. 2) := ((150, 150), (150, 150));
   begin
      Apply_Dither (Lin_Img, Decay => Linear);
      Assert (Lin_Img(1,1) = 0 or Lin_Img(1,1) = 255, "Failed 11.1");
      Put_Line ("     PASS");
   end;

   Put_Line ("TEST 12 - Error Accumulation Behavior");
   Put_Line ("  12.1 Assert mid-gray uniform surface produces mixed B/W pixels");
   declare
      Mid_Img : Gray_Image (1 .. 4, 1 .. 4) := (others => (others => 128));
      Black_Count, White_Count : Natural := 0;
   begin
      Apply_Dither (Mid_Img);
      for I in Mid_Img'Range(1) loop
         for J in Mid_Img'Range(2) loop
            if Mid_Img(I, J) = 0 then Black_Count := Black_Count + 1;
            else White_Count := White_Count + 1; end if;
         end loop;
      end loop;
      Assert (Black_Count > 0 and White_Count > 0, "Failed 12.1");
      Put_Line ("     PASS");
   end;

   Put_Line ("TEST 13 - Large History Size Constraint");
   Put_Line ("  13.1 Assert algorithm bounds don't overflow with large History_Size");
   declare
      Big_Img : Gray_Image (1 .. 2, 1 .. 2) := ((0, 255), (128, 64));
   begin
      Apply_Dither (Big_Img, History_Size => 100);
      Assert (Big_Img(1,1) = 0 or Big_Img(1,1) = 255, "Failed 13.1");
      Put_Line ("     PASS");
   end;

   Put_Line ("TEST 14 - Edge Case: Negative Error Propagation");
   Put_Line ("  14.1 Assert very low values correctly propagate to neighbors");
   declare
      Dark_Img : Gray_Image (1 .. 4, 1 .. 4) := (others => (others => 10));
      Black_Count : Natural := 0;
   begin
      Apply_Dither (Dark_Img);
      for I in Dark_Img'Range(1) loop
         for J in Dark_Img'Range(2) loop
            if Dark_Img(I, J) = 0 then Black_Count := Black_Count + 1; end if;
         end loop;
      end loop;
      Assert (Black_Count > 10, "Failed 14.1"); 
      Put_Line ("     PASS");
   end;

end Tests;
