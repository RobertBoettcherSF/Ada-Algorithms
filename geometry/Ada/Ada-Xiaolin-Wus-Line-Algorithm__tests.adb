with Ada.Text_IO; use Ada.Text_IO;
with Xiaolin_Wu;  use Xiaolin_Wu;

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

   -- Helper to clear an Intensity_Grid
   procedure Clear_Grid (Grid : in out Intensity_Grid) is
   begin
      for X in Grid'Range (1) loop
         for Y in Grid'Range (2) loop
            Grid (X, Y) := 0.0;
         end loop;
      end loop;
   end Clear_Grid;

   -- Helper to clear a Color_Grid
   procedure Clear_Color_Grid (Grid : in out Color_Grid; C : RGBA_Color) is
   begin
      for X in Grid'Range (1) loop
         for Y in Grid'Range (2) loop
            Grid (X, Y) := C;
         end loop;
      end loop;
   end Clear_Color_Grid;

   -- Global counters for callback testing
   Callback_Pixel_Count : Natural := 0;
   Callback_Weight_Sum  : Real := 0.0;

   procedure Counting_Callback
     (X        : Pixel_Coordinate;
      Y        : Pixel_Coordinate;
      Coverage : Intensity)
   is
      pragma Unreferenced (X, Y);
   begin
      Callback_Pixel_Count := Callback_Pixel_Count + 1;
      Callback_Weight_Sum  := Callback_Weight_Sum + Real (Coverage);
   end Counting_Callback;

   Buf_10x10 : Intensity_Grid (0 .. 9, 0 .. 9) := [others => [others => 0.0]];
   Col_10x10 : Color_Grid (0 .. 9, 0 .. 9) :=
     [others => [others => (Red => 0, Green => 0, Blue => 0, Alpha => 255)]];

begin
   ----------------------------------------------------------------------------
   -- TEST 1 — Helper Functions: Round, Floor, and Fractional Parts
   ----------------------------------------------------------------------------
   Put_Line ("TEST 1 — Helper Functions");
   Check ("1.1 Round_Coord positive and negative",
          Round_Coord (2.6) = 3 and then Round_Coord (-2.6) = -3 and then Round_Coord (2.4) = 2);
   Check ("1.2 Floor_Coord positive and negative",
          Floor_Coord (2.9) = 2 and then Floor_Coord (-2.1) = -3);
   Check ("1.3 Fractional_Part and Reverse_Fractional_Part",
          abs (Fractional_Part (3.25) - 0.25) < 0.0001
          and then abs (Reverse_Fractional_Part (3.25) - 0.75) < 0.0001);

   ----------------------------------------------------------------------------
   -- TEST 2 — Color Compositing and Luminance
   ----------------------------------------------------------------------------
   Put_Line ("TEST 2 — Color Compositing");
   declare
      Black : constant RGBA_Color := (Red => 0, Green => 0, Blue => 0, Alpha => 255);
      White : constant RGBA_Color := (Red => 255, Green => 255, Blue => 255, Alpha => 255);
      Blended_Half : constant RGBA_Color := Blend_Over (White, Black, 0.5);
      Blended_Zero : constant RGBA_Color := Blend_Over (White, Black, 0.0);
   begin
      Check ("2.1 50% white over black yields ~128 gray",
             Blended_Half.Red >= 126 and then Blended_Half.Red <= 130);
      Check ("2.2 0% coverage leaves background untouched",
             Blended_Zero.Red = 0 and then Blended_Zero.Green = 0 and then Blended_Zero.Blue = 0);
      Check ("2.3 Color_To_Grayscale correctly weights RGB",
             Color_To_Grayscale ((Red => 100, Green => 100, Blue => 100, Alpha => 255)) = 100);
   end;

   ----------------------------------------------------------------------------
   -- TEST 3 — Degenerate Line (Single Point)
   ----------------------------------------------------------------------------
   Put_Line ("TEST 3 — Degenerate Point Line");
   Clear_Grid (Buf_10x10);
   Draw_Line (Buf_10x10, (X => 3.0, Y => 4.0), (X => 3.0, Y => 4.0));
   Check ("3.1 Single point rasterized at exact coord",
          Buf_10x10 (3, 4) = 1.0);
   Check ("3.2 Neighbor pixel remains untouched",
          Buf_10x10 (3, 5) = 0.0);
   Check ("3.3 Far pixel remains untouched",
          Buf_10x10 (0, 0) = 0.0);

   ----------------------------------------------------------------------------
   -- TEST 4 — Horizontal Line Drawing (Zero Slope)
   ----------------------------------------------------------------------------
   Put_Line ("TEST 4 — Horizontal Line");
   Clear_Grid (Buf_10x10);
   Draw_Line (Buf_10x10, (X => 1.0, Y => 2.0), (X => 5.0, Y => 2.0));
   Check ("4.1 Start and end of horizontal line get half coverage (Wu endpoints)",
          Buf_10x10 (1, 2) = 0.5 and then Buf_10x10 (5, 2) = 0.5);
   Check ("4.2 Intermediate points on horizontal line fully covered",
          Buf_10x10 (2, 2) = 1.0 and then Buf_10x10 (3, 2) = 1.0 and then Buf_10x10 (4, 2) = 1.0);
   Check ("4.3 Adjacent row has zero intensity for integer horizontal line",
          Buf_10x10 (2, 1) = 0.0 and then Buf_10x10 (2, 3) = 0.0);

   ----------------------------------------------------------------------------
   -- TEST 5 — Vertical Line Drawing (Infinite Slope / Steep)
   ----------------------------------------------------------------------------
   Put_Line ("TEST 5 — Vertical Line");
   Clear_Grid (Buf_10x10);
   Draw_Line (Buf_10x10, (X => 4.0, Y => 2.0), (X => 4.0, Y => 7.0));
   Check ("5.1 Vertical line endpoints get half coverage",
          Buf_10x10 (4, 2) = 0.5 and then Buf_10x10 (4, 7) = 0.5);
   Check ("5.2 Vertical line intermediates drawn",
          Buf_10x10 (4, 3) = 1.0 and then Buf_10x10 (4, 5) = 1.0);
   Check ("5.3 Adjacent columns remain zero",
          Buf_10x10 (3, 4) = 0.0 and then Buf_10x10 (5, 4) = 0.0);

   ----------------------------------------------------------------------------
   -- TEST 6 — Diagonal 45-Degree Line
   ----------------------------------------------------------------------------
   Put_Line ("TEST 6 — Diagonal Line");
   Clear_Grid (Buf_10x10);
   Draw_Line (Buf_10x10, (X => 1.0, Y => 1.0), (X => 6.0, Y => 6.0));
   Check ("6.1 Diagonal start point gets half coverage",
          Buf_10x10 (1, 1) = 0.5);
   Check ("6.2 Diagonal midpoint covered",
          Buf_10x10 (3, 3) = 1.0 and then Buf_10x10 (4, 4) = 1.0);
   Check ("6.3 Diagonal end point gets half coverage",
          Buf_10x10 (6, 6) = 0.5);

   ----------------------------------------------------------------------------
   -- TEST 7 — Antialiasing Energy Conservation Invariant
   ----------------------------------------------------------------------------
   Put_Line ("TEST 7 — Antialiasing Invariant");
   Clear_Grid (Buf_10x10);
   -- Fractional line with slope = 0.5
   Draw_Line (Buf_10x10, (X => 1.0, Y => 1.25), (X => 6.0, Y => 3.75));
   declare
      Col_X : constant Pixel_Coordinate := 3;
      Sum_Intensity : constant Real := Real (Buf_10x10 (Col_X, 2)) + Real (Buf_10x10 (Col_X, 3));
   begin
      Check ("7.1 Lower adjacent pixel received antialiased weight",
             Buf_10x10 (Col_X, 2) > 0.0);
      Check ("7.2 Upper adjacent pixel received antialiased weight",
             Buf_10x10 (Col_X, 3) > 0.0);
      Check ("7.3 Pair sum approximates 1.0 (coverage partition)",
             abs (Sum_Intensity - 1.0) < 0.05);
   end;

   ----------------------------------------------------------------------------
   -- TEST 8 — Direction Invariance (P0->P1 vs P1->P0)
   ----------------------------------------------------------------------------
   Put_Line ("TEST 8 — Direction Invariance");
   declare
      Buf_Forward  : Intensity_Grid (0 .. 9, 0 .. 9) := [others => [others => 0.0]];
      Buf_Backward : Intensity_Grid (0 .. 9, 0 .. 9) := [others => [others => 0.0]];
      Identical : Boolean := True;
      P_A : constant Point_2D := (X => 1.2, Y => 2.7);
      P_B : constant Point_2D := (X => 7.8, Y => 5.3);
   begin
      Draw_Line (Buf_Forward, P_A, P_B);
      Draw_Line (Buf_Backward, P_B, P_A);

      for X in Buf_Forward'Range (1) loop
         for Y in Buf_Forward'Range (2) loop
            if abs (Buf_Forward (X, Y) - Buf_Backward (X, Y)) > 0.0001 then
               Identical := False;
            end if;
         end loop;
      end loop;

      Check ("8.1 Rasterization is symmetrical", Identical);
      Check ("8.2 Forward drew active pixels", Buf_Forward (2, 3) > 0.0);
      Check ("8.3 Backward drew active pixels matching forward", Buf_Backward (2, 3) > 0.0);
   end;

   ----------------------------------------------------------------------------
   -- TEST 9 — Callback Variant Streaming
   ----------------------------------------------------------------------------
   Put_Line ("TEST 9 — Callback Variant");
   Callback_Pixel_Count := 0;
   Callback_Weight_Sum  := 0.0;
   Draw_Line_Callback
     (P0       => (X => 1.0, Y => 1.0),
      P1       => (X => 8.0, Y => 3.0),
      Max_X    => 9,
      Max_Y    => 9,
      Callback => Counting_Callback'Access);
   Check ("9.1 Callback emitted pixels", Callback_Pixel_Count > 0);
   Check ("9.2 Callback accumulated non-zero intensity", Callback_Weight_Sum > 0.0);
   Check ("9.3 Pixel count scales proportionally to line length",
          Callback_Pixel_Count >= 10 and then Callback_Pixel_Count <= 25);

   ----------------------------------------------------------------------------
   -- TEST 10 — RGBA Direct Color Rendering
   ----------------------------------------------------------------------------
   Put_Line ("TEST 10 — RGBA Direct Rendering");
   declare
      Bg_Color : constant RGBA_Color := (Red => 10, Green => 10, Blue => 10, Alpha => 255);
      Line_Col : constant RGBA_Color := (Red => 250, Green => 50, Blue => 50, Alpha => 255);
   begin
      Clear_Color_Grid (Col_10x10, Bg_Color);
      Draw_Line_RGBA (Col_10x10, (X => 1.0, Y => 1.0), (X => 8.0, Y => 1.0), Line_Col);

      Check ("10.1 Horizontal RGBA line changed red channel",
             Col_10x10 (4, 1).Red > 200);
      Check ("10.2 Untouched RGBA line background intact",
             Col_10x10 (4, 5).Red = 10 and then Col_10x10 (4, 5).Green = 10);
      Check ("10.3 Endpoint blended with half weight (approx 130)",
             Col_10x10 (1, 1).Red > 120 and then Col_10x10 (1, 1).Red < 140
             and then Col_10x10 (8, 1).Red > 120 and then Col_10x10 (8, 1).Red < 140);
   end;

   ----------------------------------------------------------------------------
   -- TEST 11 — Clipped Viewport Rendering
   ----------------------------------------------------------------------------
   Put_Line ("TEST 11 — Clipped Viewport");
   Clear_Grid (Buf_10x10);
   -- Draw line spanning (0, 4) to (9, 4), but clipped to bounding box [3 .. 6] x [0 .. 9]
   Draw_Line_Clipped
     (Buffer => Buf_10x10,
      P0     => (X => 0.0, Y => 4.0),
      P1     => (X => 9.0, Y => 4.0),
      Min_X  => 3,
      Min_Y  => 0,
      Max_X  => 6,
      Max_Y  => 9);
   Check ("11.1 Pixel before Min_X was clipped away",
          Buf_10x10 (2, 4) = 0.0);
   Check ("11.2 Pixels within clipping box rendered",
          Buf_10x10 (3, 4) = 1.0 and then Buf_10x10 (5, 4) = 1.0 and then Buf_10x10 (6, 4) = 1.0);
   Check ("11.3 Pixel after Max_X was clipped away",
          Buf_10x10 (7, 4) = 0.0);

   ----------------------------------------------------------------------------
   -- TEST 12 — Out of Frame Sub-pixel Coordinates (Safety & No Crash)
   ----------------------------------------------------------------------------
   Put_Line ("TEST 12 — Out-of-Bounds Line Handling");
   Clear_Grid (Buf_10x10);
   -- Line starts negative and ends past 10x10 buffer boundary
   Draw_Line (Buf_10x10, (X => -5.0, Y => 2.0), (X => 15.0, Y => 2.0));
   Check ("12.1 Visible portion inside buffer drawn",
          Buf_10x10 (0, 2) = 1.0 and then Buf_10x10 (9, 2) = 1.0);
   Check ("12.2 Midpoint inside buffer drawn",
          Buf_10x10 (5, 2) = 1.0);
   Check ("12.3 Off-line buffer areas remain pristine",
          Buf_10x10 (5, 4) = 0.0);

   ----------------------------------------------------------------------------
   -- TEST 13 — Zero-Length and Micro-Step Sub-Pixel Segment
   ----------------------------------------------------------------------------
   Put_Line ("TEST 13 — Micro Sub-Pixel Step");
   Clear_Grid (Buf_10x10);
   Draw_Line (Buf_10x10, (X => 4.1, Y => 4.1), (X => 4.2, Y => 4.2));
   Check ("13.1 Micro-step plotted onto nearest rounded pixel",
          Buf_10x10 (4, 4) > 0.0);
   Check ("13.2 Surrounding points maintain zero",
          Buf_10x10 (2, 2) = 0.0 and then Buf_10x10 (6, 6) = 0.0);
   Check ("13.3 Value is within valid intensity bounds",
          Buf_10x10 (4, 4) <= 1.0);

   ----------------------------------------------------------------------------
   -- Summary
   ----------------------------------------------------------------------------
   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
