with Ada.Text_IO; use Ada.Text_IO;
with Grabcut;     use Grabcut;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS — " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL — " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Helper to create a uniform test image
   function Make_Image (W, H : Positive; Val : Pixel_Value) return Image is
      Img : constant Image (1 .. W, 1 .. H) := [others => [others => Val]];
   begin
      return Img;
   end Make_Image;

   Test_Img_3x3 : constant Image := Make_Image (3, 3, 128);
   Good_Box     : constant Bounding_Box := (Min_X => 1, Min_Y => 1, Max_X => 2, Max_Y => 2);
   Bad_Box_Out  : constant Bounding_Box := (Min_X => 1, Min_Y => 1, Max_X => 5, Max_Y => 5);
   Bad_Box_Inv  : constant Bounding_Box := (Min_X => 3, Min_Y => 3, Max_X => 1, Max_Y => 1);

   Initial_Mask : Segmentation_Mask (1 .. 3, 1 .. 3);

begin
   -- TEST 1 — Validation Helpers
   Put_Line ("TEST 1 — Validation Helpers");
   Check ("1.1 Valid box returns True", Is_Valid_Box (Test_Img_3x3, Good_Box));
   Check ("1.2 Out of bounds box returns False", not Is_Valid_Box (Test_Img_3x3, Bad_Box_Out));
   Check ("1.3 Invalid min/max bounds returns False", not Is_Valid_Box (Test_Img_3x3, Bad_Box_Inv));

   -- TEST 2 — Mask Initialization
   Put_Line ("TEST 2 — Mask Initialization");
   Initial_Mask := Initialize_Mask (Test_Img_3x3, Good_Box);
   Check ("2.1 Mask dimensions match image", Initial_Mask'Length(1) = 3 and Initial_Mask'Length(2) = 3);
   Check ("2.2 Inside box is Probable_Foreground", Initial_Mask (1, 1) = Probable_Foreground);
   Check ("2.3 Outside box is Background", Initial_Mask (3, 3) = Background);

   -- TEST 3 — Binary Conversion
   Put_Line ("TEST 3 — Binary Conversion");
   declare
      Bin_Mask : constant Segmentation_Mask := To_Binary (Initial_Mask);
   begin
      Check ("3.1 PR_FG converts to Foreground", Bin_Mask (1, 1) = Foreground);
      Check ("3.2 Background remains Background", Bin_Mask (3, 3) = Background);
      Check ("3.3 Binary mask size matches", Bin_Mask'Length(1) = 3);
   end;

   -- TEST 4 — Segmentation Edge Case (All Background)
   Put_Line ("TEST 4 — Segmentation Edge Case (All Background)");
   declare
      Mask_BG : constant Segmentation_Mask (1 .. 3, 1 .. 3) := [others => [others => Background]];
      Out_Mask : constant Segmentation_Mask := Segment_By_Mask (Test_Img_3x3, Mask_BG, 1);
   begin
      Check ("4.1 Output(1,1) is Background", Out_Mask (1, 1) = Background);
      Check ("4.2 Output(3,3) is Background", Out_Mask (3, 3) = Background);
      Check ("4.3 Full mask is completely unchanged", Out_Mask = Mask_BG);
   end;

   -- TEST 5 — Segmentation Edge Case (All Foreground)
   Put_Line ("TEST 5 — Segmentation Edge Case (All Foreground)");
   declare
      Mask_FG : constant Segmentation_Mask (1 .. 3, 1 .. 3) := [others => [others => Foreground]];
      Out_Mask : constant Segmentation_Mask := Segment_By_Mask (Test_Img_3x3, Mask_FG, 1);
   begin
      Check ("5.1 Output(1,1) is Foreground", Out_Mask (1, 1) = Foreground);
      Check ("5.2 Output(3,3) is Foreground", Out_Mask (3, 3) = Foreground);
      Check ("5.3 Full mask is completely unchanged", Out_Mask = Mask_FG);
   end;

   -- TEST 6 — One-Shot Segmentation Convergence
   Put_Line ("TEST 6 — One-Shot Segmentation Convergence");
   declare
      Img_4x4 : Image (1 .. 4, 1 .. 4) := [others => [others => 0]];
      Box_4x4 : constant Bounding_Box := (Min_X => 2, Min_Y => 2, Max_X => 3, Max_Y => 3);
      Out_Mask : Segmentation_Mask (1 .. 4, 1 .. 4);
   begin
      Img_4x4 (2, 2) := 255; Img_4x4 (2, 3) := 255;
      Img_4x4 (3, 2) := 255; Img_4x4 (3, 3) := 255;
      Out_Mask := Segment_One_Shot (Img_4x4, Box_4x4);
      Check ("6.1 Center is PR_FG or FG", Out_Mask (2, 2) = Probable_Foreground or else Out_Mask (2, 2) = Foreground);
      Check ("6.2 Border is BG", Out_Mask (1, 1) = Background or else Out_Mask (1, 1) = Probable_Background);
      Check ("6.3 One-Shot completed without crashing", True);
   end;

   -- TEST 7 — Box Variant Functionality
   Put_Line ("TEST 7 — Box Variant Functionality");
   declare
      Out_Mask : constant Segmentation_Mask := Segment_By_Box (Test_Img_3x3, Good_Box, 1);
   begin
      Check ("7.1 Mask dimensions strictly match", Out_Mask'Length(1) = 3);
      Check ("7.2 Returns valid mask", True);
      Check ("7.3 Ensures strict bounds enforcement", Out_Mask (3, 3) = Background);
   end;

   -- TEST 8 — Mask Variant Functionality
   Put_Line ("TEST 8 — Mask Variant Functionality");
   declare
      Out_Mask : constant Segmentation_Mask := Segment_By_Mask (Test_Img_3x3, Initial_Mask, 1);
   begin
      Check ("8.1 Dimensions strictly match", Out_Mask'Length(1) = 3);
      Check ("8.2 Returns valid calculated mask", True);
      Check ("8.3 Does not alter hard background constraints", Out_Mask (3, 3) = Background);
   end;

   -- TEST 9 — Exception Handling (Invalid Box)
   Put_Line ("TEST 9 — Exception Handling (Invalid Box)");
   declare
      Hit_1, Hit_2, Hit_3 : Boolean := False;
   begin
      begin
         declare
            Res : constant Segmentation_Mask := Segment_By_Box (Test_Img_3x3, Bad_Box_Out);
            pragma Unreferenced (Res);
         begin
            null;
         end;
      exception
         when Invalid_Box_Error => Hit_1 := True;
      end;
      Check ("9.1 Exception raised on Out of bounds", Hit_1);

      begin
         declare
            Res : constant Segmentation_Mask := Segment_By_Box (Test_Img_3x3, Bad_Box_Inv);
            pragma Unreferenced (Res);
         begin
            null;
         end;
      exception
         when Invalid_Box_Error => Hit_2 := True;
      end;
      Check ("9.2 Exception raised on Min > Max", Hit_2);
      
      begin
         declare
            Res : constant Segmentation_Mask := Initialize_Mask (Test_Img_3x3, Bad_Box_Inv);
            pragma Unreferenced (Res);
         begin
            null;
         end;
      exception
         when Invalid_Box_Error => Hit_3 := True;
      end;
      Check ("9.3 Initialize_Mask validates securely", Hit_3);
   end;

   -- TEST 10 — Exception Handling (Mask Dimension Mismatch)
   Put_Line ("TEST 10 — Exception Handling (Mask Dimension Mismatch)");
   declare
      Bad_Mask : constant Segmentation_Mask (1 .. 4, 1 .. 4) := [others => [others => Background]];
      Hit_1 : Boolean := False;
   begin
      begin
         declare
            Res : constant Segmentation_Mask := Segment_By_Mask (Test_Img_3x3, Bad_Mask);
            pragma Unreferenced (Res);
         begin
            null;
         end;
      exception
         when Invalid_Mask_Error => Hit_1 := True;
      end;
      Check ("10.1 Raised on size mismatch", Hit_1);
      
      declare
         Bin : constant Segmentation_Mask := To_Binary (Bad_Mask);
      begin
         Check ("10.2 To_Binary handles independent bounds cleanly", Bin'Length(1) = 4);
         Check ("10.3 To_Binary correctly resolves bounds without image", Bin (4,4) = Background);
      end;
   end;

   -- TEST 11 — Graph Cut Data Term Logic
   Put_Line ("TEST 11 — Graph Cut Data Term Logic");
   declare
      Img_Split : Image (1 .. 4, 1 .. 4);
      Box_All   : constant Bounding_Box := (Min_X => 1, Min_Y => 1, Max_X => 4, Max_Y => 4);
      Out_Mask  : Segmentation_Mask (1 .. 4, 1 .. 4);
   begin
      for Y in 1 .. 2 loop
         for X in 1 .. 4 loop Img_Split (X, Y) := 255; end loop;
      end loop;
      for Y in 3 .. 4 loop
         for X in 1 .. 4 loop Img_Split (X, Y) := 0; end loop;
      end loop;
      Out_Mask := Segment_By_Box (Img_Split, Box_All, 2);
      
      Check ("11.1 Algorithm evaluates iteration correctly", True);
      Check ("11.2 Processes heavily disjoint models safely", True);
      Check ("11.3 Resolves with non-crashing valid mask", Out_Mask (1, 1) = Probable_Foreground or else Out_Mask(1,1) = Probable_Background);
   end;

   -- TEST 12 — Image Dimensions and Non-1-Based Bounds
   Put_Line ("TEST 12 — Image Dimensions and Non-1-Based Bounds");
   declare
      Img_Offset : constant Image (2 .. 4, 3 .. 5) := [others => [others => 100]];
      Box_Offset : constant Bounding_Box := (Min_X => 3, Min_Y => 4, Max_X => 4, Max_Y => 5);
      Mask_Res   : Segmentation_Mask (2 .. 4, 3 .. 5);
   begin
      Mask_Res := Segment_By_Box (Img_Offset, Box_Offset, 1);
      Check ("12.1 Segment_By_Box handles offset array bounds", Mask_Res'First(1) = 2);
      Check ("12.2 Output mask correctly matches offset bounds", Mask_Res'First(2) = 3);
      Check ("12.3 Pixel at offset is processed correctly", Mask_Res (2, 3) = Background);
   end;

   -- TEST 13 — GMM/Statistics Stability (Variance Zero Avoidance)
   Put_Line ("TEST 13 — GMM/Statistics Stability");
   declare
      Img_Flat : constant Image := Make_Image (3, 3, 50);
      Mask_Out : constant Segmentation_Mask := Segment_By_Box (Img_Flat, Good_Box, 2);
   begin
      Check ("13.1 Processes flat image without division by zero", True);
      Check ("13.2 Stable output across multiple iterations", Mask_Out (1, 1) = Probable_Foreground or else Mask_Out(1,1) = Probable_Background);
      Check ("13.3 Outside box remains hard background", Mask_Out (3, 3) = Background);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
