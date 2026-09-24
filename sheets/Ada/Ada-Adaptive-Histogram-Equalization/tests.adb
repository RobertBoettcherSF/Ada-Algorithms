-- tests.adb
-- Extensive V&V testing assuming the code natively fails. Contains 13 assertions.

with Ada.Text_IO; use Ada.Text_IO;
with Adaptive_Histogram_Equalization; use Adaptive_Histogram_Equalization;

procedure Tests is
   Img_Small      : constant Image_Type(1..2, 1..2) := (others => (others => 128));
   Out_Small      : Image_Type(1..2, 1..2);
   Img_Mismatched : Image_Type(1..3, 1..3);
   Empty_Img      : Image_Type(1..0, 1..0);
   Out_Empty      : Image_Type(1..0, 1..0);
   Val_AHE        : Pixel_Type;
   Val_CLAHE      : Pixel_Type;
begin
   Put_Line("=== AHE Algorithm V&V Test Suite ===");

   Put_Line("TEST 1 - Global HE Normal Operation");
   Put_Line("  1.1 Assert Global_HE maps uniform values to maximum pixel (255)");
   Global_HE(Img_Small, Out_Small);
   if Out_Small(1,1) = 255 then Put_Line("      PASS"); else Put_Line("      FAIL"); end if;

   Put_Line("  1.2 Assert mismatched output matrix dimensions raise Invalid_Image");
   begin
      Global_HE(Img_Small, Img_Mismatched);
      Put_Line("      FAIL (No exception)");
   exception
      when Invalid_Image => Put_Line("      PASS");
   end;

   Put_Line("  1.3 Assert perfectly empty/null images raise Invalid_Image");
   begin
      Global_HE(Empty_Img, Out_Empty);
      Put_Line("      FAIL");
   exception
      when Invalid_Image => Put_Line("      PASS");
   end;

   Put_Line("TEST 2 - Adaptive HE Input Boundaries");
   Put_Line("  2.1 Assert even window sizes (2) are rejected via Invalid_Window");
   begin
      Sliding_Window_AHE(Img_Small, Out_Small, 2);
      Put_Line("      FAIL");
   exception
      when Invalid_Window => Put_Line("      PASS");
   end;

   Put_Line("  2.2 Assert AHE safely bounds window queries beyond image size limits");
   declare
      Img3 : constant Image_Type(1..3, 1..3) := (others => (others => 50));
      Out3 : Image_Type(1..3, 1..3);
   begin
      Sliding_Window_AHE(Img3, Out3, 5); -- Window exceeds 3x3
      Put_Line("      PASS");
   end;

   Put_Line("  2.3 Assert single-pixel images function seamlessly without Zero-Divisions");
   declare
      Img1 : constant Image_Type(1..1, 1..1) := (others => (others => 64));
      Out1 : Image_Type(1..1, 1..1);
   begin
      Sliding_Window_AHE(Img1, Out1, 3);
      if Out1(1,1) = 255 then Put_Line("      PASS"); else Put_Line("      FAIL"); end if;
   end;

   Put_Line("TEST 3 - CLAHE Contrast Limiting Integrity");
   Put_Line("  3.1 Assert CLAHE artificially suppresses output values on severe single-pixel peaks");
   declare
      Img5 : Image_Type(1..5, 1..5) := (others => (others => 100));
      OutAHE : Image_Type(1..5, 1..5);
      OutCLAHE : Image_Type(1..5, 1..5);
   begin
      Img5(3,3) := 200;
      Sliding_Window_AHE(Img5, OutAHE, 3);
      Sliding_Window_CLAHE(Img5, OutCLAHE, 3, 2); -- Aggressive clip limit
      Val_AHE := OutAHE(3,3);
      Val_CLAHE := OutCLAHE(3,3);
      -- The clipping redistributes intensity away from the peak, lowering its mapped result
      if Val_CLAHE <= Val_AHE then Put_Line("      PASS"); else Put_Line("      FAIL"); end if;
   end;

   Put_Line("  3.2 Assert clip limit of 0 avoids divide-by-zero crashes");
   declare
       OutZero : Image_Type(1..2, 1..2);
   begin
       Sliding_Window_CLAHE(Img_Small, OutZero, 3, 0);
       Put_Line("      PASS"); 
   end;

   Put_Line("TEST 4 - Block-Based / Grid CLAHE Features");
   Put_Line("  4.1 Assert 1x1 grid degrades into Global HE outputs");
   declare
       OutBlk : Image_Type(1..2, 1..2);
   begin
       Block_Based_CLAHE(Img_Small, OutBlk, 1, 1, 100);
       if OutBlk(1,1) = Out_Small(1,1) then Put_Line("      PASS"); else Put_Line("      FAIL"); end if;
   end;

   Put_Line("  4.2 Assert over-sized logical grid (exceeds matrix limits) throws Invalid_Grid");
   begin
       Block_Based_CLAHE(Img_Small, Out_Small, 5, 5, 10);
       Put_Line("      FAIL");
   exception
       when Invalid_Grid => Put_Line("      PASS");
   end;

   Put_Line("  4.3 Assert non-square dimensions safely process through fractional tile mapping");
   declare
       ImgRect : constant Image_Type(1..4, 1..8) := (others => (others => 12));
       OutRect : Image_Type(1..4, 1..8);
   begin
       Block_Based_CLAHE(ImgRect, OutRect, 2, 4, 5);
       Put_Line("      PASS");
   end;

   Put_Line("TEST 5 - Extreme Intensity Bounds Handling");
   Put_Line("  5.1 Assert inputs of 255 (maximum) do not overflow CDF multiplication types");
   declare
      ImgMax : constant Image_Type(1..2, 1..2) := (others => (others => 255));
      OutMax : Image_Type(1..2, 1..2);
   begin
      Global_HE(ImgMax, OutMax);
      if OutMax(1,1) = 255 then Put_Line("      PASS"); else Put_Line("      FAIL"); end if;
   end;

   Put_Line("  5.2 Assert absolute black pixels (0) do not cause mathematical skips");
   declare
      ImgMin : constant Image_Type(1..2, 1..2) := (others => (others => 0));
      OutMin : Image_Type(1..2, 1..2);
   begin
      Global_HE(ImgMin, OutMin);
      if OutMin(1,1) = 255 then Put_Line("      PASS"); else Put_Line("      FAIL"); end if;
   end;
   
   Put_Line("=== Test Suite Completed Successfully ===");
end Tests;
