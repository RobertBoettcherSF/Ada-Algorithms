with Ada.Text_IO; use Ada.Text_IO;
with Computer_Vision; use Computer_Vision;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS - " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL - " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Test Inputs
   RGB_Test : constant RGB_Image (1 .. 2, 1 .. 2) :=
     [[(R => 255, G => 0,   B => 0),   (R => 0,   G => 255, B => 0)],
      [(R => 0,   G => 0,   B => 255), (R => 255, G => 255, B => 255)]];
      
   Solid_Img : constant Image (1 .. 3, 1 .. 3) :=
     [others => [others => 100]];
     
   Edge_Img  : constant Image (1 .. 3, 1 .. 3) :=
     [[0, 255, 0],
      [0, 255, 0],
      [0, 255, 0]];

   Empty_RGB : constant RGB_Image (1 .. 0, 1 .. 0) := [others => [others => (0, 0, 0)]];
   Empty_Img : constant Image (1 .. 0, 1 .. 0) := [others => [others => 0]];

   Res_Img   : Image (1 .. 2, 1 .. 2);
   Res_Solid : Image (1 .. 3, 1 .. 3);
begin
   Put_Line ("TEST 1 - Grayscale Average");
   Res_Img := To_Grayscale_Average (RGB_Test);
   Check ("1.1 Red channel averages to 85", Res_Img (1, 1) = 85);
   Check ("1.2 Green channel averages to 85", Res_Img (1, 2) = 85);
   Check ("1.3 White channel averages to 255", Res_Img (2, 2) = 255);

   Put_Line ("TEST 2 - Grayscale Luminosity");
   Res_Img := To_Grayscale_Luminosity (RGB_Test);
   Check ("2.1 Red converts to ~54 perceptual weight", Res_Img (1, 1) = 54);
   Check ("2.2 Green converts to ~182 perceptual weight", Res_Img (1, 2) = 182);
   Check ("2.3 Blue converts to ~18 perceptual weight", Res_Img (2, 1) = 18);

   Put_Line ("TEST 3 - Convolution Identity");
   declare
      Id_Kernel : constant Kernel :=
        [[0.0, 0.0, 0.0],
         [0.0, 1.0, 0.0],
         [0.0, 0.0, 0.0]];
   begin
      Res_Solid := Convolve (Solid_Img, Id_Kernel);
      Check ("3.1 Top-Left is unchanged", Res_Solid (1, 1) = 100);
      Check ("3.2 Center is unchanged", Res_Solid (2, 2) = 100);
      Check ("3.3 Bottom-Right is unchanged", Res_Solid (3, 3) = 100);
   end;

   Put_Line ("TEST 4 - Convolution Zero-Out");
   declare
      Zero_Kernel : constant Kernel := [others => [others => 0.0]];
   begin
      Res_Solid := Convolve (Solid_Img, Zero_Kernel);
      Check ("4.1 Top-Left is zeroed", Res_Solid (1, 1) = 0);
      Check ("4.2 Center is zeroed", Res_Solid (2, 2) = 0);
      Check ("4.3 Bottom-Right is zeroed", Res_Solid (3, 3) = 0);
   end;

   Put_Line ("TEST 5 - Convolution Clamp Max");
   declare
      High_Kernel : constant Kernel :=
        [[0.0, 0.0, 0.0],
         [0.0, 5.0, 0.0], -- 5 * 100 = 500 which is > 255
         [0.0, 0.0, 0.0]];
   begin
      Res_Solid := Convolve (Solid_Img, High_Kernel);
      Check ("5.1 Top-Left clamped to 255 max limit", Res_Solid (1, 1) = 255);
      Check ("5.2 Center clamped to 255 max limit", Res_Solid (2, 2) = 255);
      Check ("5.3 Bottom-Right clamped to 255 max limit", Res_Solid (3, 3) = 255);
   end;

   Put_Line ("TEST 6 - Convolution Clamp Min");
   declare
      Neg_Kernel : constant Kernel :=
        [[0.0, 0.0, 0.0],
         [0.0, -2.0, 0.0], -- -2 * 100 = -200 which is < 0
         [0.0, 0.0, 0.0]];
   begin
      Res_Solid := Convolve (Solid_Img, Neg_Kernel);
      Check ("6.1 Top-Left clamped to 0 min limit", Res_Solid (1, 1) = 0);
      Check ("6.2 Center clamped to 0 min limit", Res_Solid (2, 2) = 0);
      Check ("6.3 Bottom-Right clamped to 0 min limit", Res_Solid (3, 3) = 0);
   end;

   Put_Line ("TEST 7 - Sobel X on Solid Flat Image");
   Res_Solid := Sobel_X (Solid_Img);
   Check ("7.1 Center gradient is 0", Res_Solid (2, 2) = 0);
   Check ("7.2 Top-Center gradient is 0", Res_Solid (1, 2) = 0);
   Check ("7.3 Bottom-Center gradient is 0", Res_Solid (3, 2) = 0);

   Put_Line ("TEST 8 - Sobel Y on Solid Flat Image");
   Res_Solid := Sobel_Y (Solid_Img);
   Check ("8.1 Center gradient is 0", Res_Solid (2, 2) = 0);
   Check ("8.2 Left-Center gradient is 0", Res_Solid (2, 1) = 0);
   Check ("8.3 Right-Center gradient is 0", Res_Solid (2, 3) = 0);

   Put_Line ("TEST 9 - Sobel X on Vertical Edge Image");
   Res_Solid := Sobel_X (Edge_Img);
   -- The vertical line is at column 2
   Check ("9.1 Left side observes high positive gradient", Res_Solid (2, 1) = 255);
   Check ("9.2 Center perfectly straddles edge, gradient 0", Res_Solid (2, 2) = 0);
   Check ("9.3 Right side observes negative gradient, clamped to 0", Res_Solid (2, 3) = 0);

   Put_Line ("TEST 10 - Sobel Magnitude on Vertical Edge Image");
   Res_Solid := Sobel_Magnitude (Edge_Img);
   -- Magnitude takes absolute intensity of both sides of edge
   Check ("10.1 Left side detects strong magnitude", Res_Solid (2, 1) = 255);
   Check ("10.2 Center remains zero magnitude", Res_Solid (2, 2) = 0);
   Check ("10.3 Right side negative gradient recovered as positive magnitude", Res_Solid (2, 3) = 255);

   Put_Line ("TEST 11 - Single Pixel Image Edge Cases");
   declare
      Single : constant Image (1 .. 1, 1 .. 1) := [others => [others => 128]];
      Res    : Image (1 .. 1, 1 .. 1);
   begin
      Res := Sobel_Magnitude (Single);
      Check ("11.1 Magnitude of 1x1 flat plane is 0", Res (1, 1) = 0);
      Res := Sobel_X (Single);
      Check ("11.2 Sobel_X of 1x1 flat plane is 0", Res (1, 1) = 0);
      Res := Sobel_Y (Single);
      Check ("11.3 Sobel_Y of 1x1 flat plane is 0", Res (1, 1) = 0);
   end;

   Put_Line ("TEST 12 - Exception Dimension_Error Grayscale");
   declare
      Failed : Boolean := False;
   begin
      begin
         declare
            -- Attempt processing on zero-length array
            Res : Image := To_Grayscale_Average (Empty_RGB);
            pragma Unreferenced (Res);
         begin
            Failed := False;
         end;
      exception
         when Dimension_Error => Failed := True;
         when others => Failed := False;
      end;
      Check ("12.1 Grayscale_Average rejects empty array", Failed);

      begin
         declare
            Res : Image := To_Grayscale_Luminosity (Empty_RGB);
            pragma Unreferenced (Res);
         begin
            Failed := False;
         end;
      exception
         when Dimension_Error => Failed := True;
         when others => Failed := False;
      end;
      Check ("12.2 Grayscale_Luminosity rejects empty array", Failed);

      begin
         declare
            Res : Image := Sobel_Y (Empty_Img);
            pragma Unreferenced (Res);
         begin
            Failed := False;
         end;
      exception
         when Dimension_Error => Failed := True;
         when others => Failed := False;
      end;
      Check ("12.3 Sobel_Y rejects empty array", Failed);
   end;

   Put_Line ("TEST 13 - Exception Dimension_Error Convolution");
   declare
      Failed : Boolean := False;
   begin
      begin
         declare
            Res : Image := Convolve (Empty_Img, Sobel_X_Kernel);
            pragma Unreferenced (Res);
         begin
            Failed := False;
         end;
      exception
         when Dimension_Error => Failed := True;
         when others => Failed := False;
      end;
      Check ("13.1 Convolve rejects empty array", Failed);

      begin
         declare
            Res : Image := Sobel_X (Empty_Img);
            pragma Unreferenced (Res);
         begin
            Failed := False;
         end;
      exception
         when Dimension_Error => Failed := True;
         when others => Failed := False;
      end;
      Check ("13.2 Sobel_X rejects empty array", Failed);

      begin
         declare
            Res : Image := Sobel_Magnitude (Empty_Img);
            pragma Unreferenced (Res);
         begin
            Failed := False;
         end;
      exception
         when Dimension_Error => Failed := True;
         when others => Failed := False;
      end;
      Check ("13.3 Sobel_Magnitude rejects empty array", Failed);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
