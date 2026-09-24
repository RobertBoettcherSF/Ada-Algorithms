--  Standalone verification test suite for Scanline Rendering

with Ada.Text_IO;        use Ada.Text_IO;
with Scanline_Rendering; use Scanline_Rendering;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS -- " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL -- " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   -- Allocate massive arrays dynamically to avoid STORAGE_ERROR (stack overflow)
   type FB_Access is access Frame_Buffer;
   type ZB_Access is access Depth_Buffer;
   FB_Ptr : constant FB_Access := new Frame_Buffer;
   ZB_Ptr : constant ZB_Access := new Depth_Buffer;

   FB : Frame_Buffer renames FB_Ptr.all;
   ZB : Depth_Buffer renames ZB_Ptr.all;

begin
   ---------------------------------------------------------------------------
   -- TEST 1 -- Clear Frame Buffer
   ---------------------------------------------------------------------------
   Put_Line ("TEST 1 -- Clear Frame Buffer");
   Clear_Frame_Buffer (FB, Black);
   Check ("1.1 Origin is black", FB (0, 0) = Black);
   Check ("1.2 Center is black", FB (100, 100) = Black);
   Clear_Frame_Buffer (FB, White);
   Check ("1.3 Center is white after clear", FB (100, 100) = White);

   ---------------------------------------------------------------------------
   -- TEST 2 -- Clear Depth Buffer
   ---------------------------------------------------------------------------
   Put_Line ("TEST 2 -- Clear Depth Buffer");
   Clear_Depth_Buffer (ZB, 1000.0);
   Check ("2.1 Origin depth initialized", ZB (0, 0) = 1000.0);
   Check ("2.2 Max boundary depth initialized", ZB (Screen_Coordinate_X'Last, Screen_Coordinate_Y'Last) = 1000.0);
   Clear_Depth_Buffer (ZB, 0.0);
   Check ("2.3 Depth buffer reset to zero", ZB (50, 50) = 0.0);

   ---------------------------------------------------------------------------
   -- TEST 3 -- 2D Convex Polygon Rasterization (Triangle)
   ---------------------------------------------------------------------------
   Put_Line ("TEST 3 -- 2D Triangle Rasterization");
   Clear_Frame_Buffer (FB, Black);
   declare
      Tri : constant Point_2D_Array (1 .. 3) :=
        [(X => 10, Y => 10), (X => 50, Y => 10), (X => 30, Y => 50)];
      Count : Natural;
   begin
      Render_Polygon_2D (FB, Tri, Red);
      Count := Count_Colored_Pixels (FB, Red);
      Check ("3.1 Centroid is filled", FB (30, 20) = Red);
      Check ("3.2 Outside pixel is untouched", FB (5, 5) = Black);
      Check ("3.3 Triangle area has non-zero filled pixels", Count > 500);
   end;

   ---------------------------------------------------------------------------
   -- TEST 4 -- 2D Concave Polygon Fill (L-shape)
   ---------------------------------------------------------------------------
   Put_Line ("TEST 4 -- 2D Concave Polygon Fill");
   Clear_Frame_Buffer (FB, Black);
   declare
      --  L-shaped concave polygon
      L_Shape : constant Point_2D_Array (1 .. 6) :=
        [(X => 10, Y => 10),
         (X => 30, Y => 10),
         (X => 30, Y => 30),
         (X => 20, Y => 30),
         (X => 20, Y => 50),
         (X => 10, Y => 50)];
   begin
      Render_Polygon_2D (FB, L_Shape, Green);
      Check ("4.1 Interior of top limb is colored", FB (25, 20) = Green);
      Check ("4.2 Interior of vertical limb is colored", FB (15, 40) = Green);
      Check ("4.3 Concave exterior pocket remains black", FB (25, 40) = Black);
   end;

   ---------------------------------------------------------------------------
   -- TEST 5 -- 2D Degenerate Polygon Handling
   ---------------------------------------------------------------------------
   Put_Line ("TEST 5 -- 2D Degenerate Polygon Handling");
   declare
      Degenerate_Tri : constant Point_2D_Array (1 .. 3) :=
        [(X => 10, Y => 10), (X => 20, Y => 10), (X => 30, Y => 10)];
      Count : Natural;
   begin
      Clear_Frame_Buffer (FB, Black);
      Render_Polygon_2D (FB, Degenerate_Tri, Blue);
      Count := Count_Colored_Pixels (FB, Blue);
      Check ("5.1 Degenerate collinear points don't crash", True);
      Check ("5.2 Zero area polygon draws minimal or no pixels", Count <= 21);
      Check ("5.3 Far-off pixel remains background", FB (100, 100) = Black);
   end;

   ---------------------------------------------------------------------------
   -- TEST 6 -- Point In Convex Hull Geometric Utility
   ---------------------------------------------------------------------------
   Put_Line ("TEST 6 -- Point In Convex Hull");
   declare
      Square : constant Point_2D_Array (1 .. 4) :=
        [(X => 20, Y => 20), (X => 60, Y => 20), (X => 60, Y => 60), (X => 20, Y => 60)];
   begin
      Check ("6.1 Center point is inside hull",
             Is_Point_Inside_Convex_Hull ((X => 40, Y => 40), Square));
      Check ("6.2 Exterior point is outside hull",
             not Is_Point_Inside_Convex_Hull ((X => 10, Y => 10), Square));
      Check ("6.3 Right exterior point is outside hull",
             not Is_Point_Inside_Convex_Hull ((X => 70, Y => 40), Square));
   end;

   ---------------------------------------------------------------------------
   -- TEST 7 -- 3D Z-Buffer Occlusion (Closer Overwrites Farther)
   ---------------------------------------------------------------------------
   Put_Line ("TEST 7 -- 3D Z-Buffer Occlusion");
   Clear_Frame_Buffer (FB, Black);
   Clear_Depth_Buffer (ZB, 1000.0);
   declare
      --  Far triangle (Red, Z = 50)
      Far_Tri : constant Polygon_3D :=
        (Vertices => [(X => 10, Y => 10, Z => 50.0),
                      (X => 50, Y => 10, Z => 50.0),
                      (X => 30, Y => 50, Z => 50.0)],
         Color    => Red);

      --  Near triangle (Green, Z = 10), overlapping Far_Tri
      Near_Tri : constant Polygon_3D :=
        (Vertices => [(X => 20, Y => 10, Z => 10.0),
                      (X => 60, Y => 10, Z => 10.0),
                      (X => 40, Y => 50, Z => 10.0)],
         Color    => Green);

      Scene : constant Polygon_3D_Array (1 .. 2) := [Far_Tri, Near_Tri];
   begin
      Render_Scene_3D_ZBuffer (FB, ZB, Scene);
      --  In overlapping region (e.g. X=35, Y=25), Green should be visible because Z=10 < Z=50
      Check ("7.1 Overlapping pixel resolves to nearer green triangle", FB (35, 25) = Green);
      Check ("7.2 Non-overlapping far section remains red", FB (15, 15) = Red);
      Check ("7.3 Depth buffer correctly stores nearest Z", ZB (35, 25) < 20.0);
   end;

   ---------------------------------------------------------------------------
   -- TEST 8 -- 3D Z-Buffer Reverse Submission Order Invariance
   ---------------------------------------------------------------------------
   Put_Line ("TEST 8 -- 3D Z-Buffer Submission Invariance");
   Clear_Frame_Buffer (FB, Black);
   Clear_Depth_Buffer (ZB, 1000.0);
   declare
      Far_Tri : constant Polygon_3D :=
        (Vertices => [(X => 10, Y => 10, Z => 50.0),
                      (X => 50, Y => 10, Z => 50.0),
                      (X => 30, Y => 50, Z => 50.0)],
         Color    => Red);

      Near_Tri : constant Polygon_3D :=
        (Vertices => [(X => 20, Y => 10, Z => 10.0),
                      (X => 60, Y => 10, Z => 10.0),
                      (X => 40, Y => 50, Z => 10.0)],
         Color    => Green);

      --  Submit Near first, Far second
      Scene_Reversed : constant Polygon_3D_Array (1 .. 2) := [Near_Tri, Far_Tri];
   begin
      Render_Scene_3D_ZBuffer (FB, ZB, Scene_Reversed);
      Check ("8.1 Overlapping pixel resolves to nearer green triangle despite reverse order", FB (35, 25) = Green);
      Check ("8.2 Far triangle does not overwrite nearer depth", ZB (35, 25) <= 15.0);
      Check ("8.3 Outside region remains untouched black", FB (5, 5) = Black);
   end;

   ---------------------------------------------------------------------------
   -- TEST 9 -- Scanline Span Hidden-Surface Removal
   ---------------------------------------------------------------------------
   Put_Line ("TEST 9 -- Scanline Span Processing");
   Clear_Frame_Buffer (FB, Black);
   declare
      Tri1 : constant Polygon_3D :=
        (Vertices => [(X => 10, Y => 20, Z => 100.0),
                      (X => 50, Y => 20, Z => 100.0),
                      (X => 30, Y => 60, Z => 100.0)],
         Color    => Blue);
      Tri2 : constant Polygon_3D :=
        (Vertices => [(X => 20, Y => 20, Z => 20.0),
                      (X => 40, Y => 20, Z => 20.0),
                      (X => 30, Y => 40, Z => 20.0)],
         Color    => White);
      Scene : constant Polygon_3D_Array (1 .. 2) := [Tri1, Tri2];
   begin
      Render_Scanline_Spans (FB, 25, Scene);
      Check ("9.1 Near span pixel at Y=25 is white", FB (30, 25) = White);
      Check ("9.2 Far span non-overlapped pixel is blue", FB (15, 25) = Blue);
      Check ("9.3 Unrendered scanline Y=10 remains black", FB (30, 10) = Black);
   end;

   ---------------------------------------------------------------------------
   -- TEST 10 -- Slanted Depth Interpolation Across Scanline
   ---------------------------------------------------------------------------
   Put_Line ("TEST 10 -- Slanted Depth Interpolation");
   Clear_Frame_Buffer (FB, Black);
   Clear_Depth_Buffer (ZB, 1000.0);
   declare
      --  Triangle with varying Z (slanted along X axis)
      Slanted_Tri : constant Polygon_3D :=
        (Vertices => [(X => 10, Y => 10, Z => 10.0),
                      (X => 50, Y => 10, Z => 90.0),
                      (X => 30, Y => 50, Z => 50.0)],
         Color    => Green);
      Scene : constant Polygon_3D_Array (1 .. 1) := [1 => Slanted_Tri];
   begin
      Render_Scene_3D_ZBuffer (FB, ZB, Scene);
      Check ("10.1 Left pixel rendered", FB (20, 20) = Green);
      Check ("10.2 Right pixel rendered", FB (40, 20) = Green);
      Check ("10.3 Depth strictly increases along X for slanted plane",
             ZB (20, 20) < ZB (40, 20));
   end;

   ---------------------------------------------------------------------------
   -- TEST 11 -- Empty Scene Handling
   ---------------------------------------------------------------------------
   Put_Line ("TEST 11 -- Empty Scene Handling");
   Clear_Frame_Buffer (FB, Black);
   Clear_Depth_Buffer (ZB, 500.0);
   declare
      Empty_Scene : constant Polygon_3D_Array (1 .. 0) := [];
   begin
      Render_Scene_3D_ZBuffer (FB, ZB, Empty_Scene);
      Render_Scanline_Spans (FB, 100, Empty_Scene);
      Check ("11.1 Zero polygons rendered without error", True);
      Check ("11.2 Frame buffer untouched", Count_Colored_Pixels (FB, Black) = 1920 * 1080);
      Check ("11.3 Depth buffer remains at initial clear value", ZB (0, 0) = 500.0);
   end;

   ---------------------------------------------------------------------------
   -- TEST 12 -- Extreme Screen Boundaries
   ---------------------------------------------------------------------------
   Put_Line ("TEST 12 -- Extreme Screen Boundaries");
   Clear_Frame_Buffer (FB, Black);
   declare
      Edge_Tri : constant Point_2D_Array (1 .. 3) :=
        [(X => Screen_Coordinate_X'Last - 10, Y => Screen_Coordinate_Y'Last - 10),
         (X => Screen_Coordinate_X'Last,      Y => Screen_Coordinate_Y'Last - 10),
         (X => Screen_Coordinate_X'Last - 5,  Y => Screen_Coordinate_Y'Last)];
   begin
      Render_Polygon_2D (FB, Edge_Tri, White);
      Check ("12.1 Max coordinate rendering executes without range fault", True);
      Check ("12.2 Max edge pixel colored", FB (Screen_Coordinate_X'Last - 5, Screen_Coordinate_Y'Last - 5) = White);
      Check ("12.3 Origin unaffected", FB (0, 0) = Black);
   end;

   ---------------------------------------------------------------------------
   -- TEST 13 -- Multiple Non-Overlapping Polygons
   ---------------------------------------------------------------------------
   Put_Line ("TEST 13 -- Multiple Non-Overlapping Polygons");
   Clear_Frame_Buffer (FB, Black);
   Clear_Depth_Buffer (ZB, 1000.0);
   declare
      T1 : constant Polygon_3D :=
        (Vertices => [(X => 10, Y => 10, Z => 10.0),
                      (X => 30, Y => 10, Z => 10.0),
                      (X => 20, Y => 30, Z => 10.0)],
         Color    => Red);
      T2 : constant Polygon_3D :=
        (Vertices => [(X => 70, Y => 10, Z => 10.0),
                      (X => 90, Y => 10, Z => 10.0),
                      (X => 80, Y => 30, Z => 10.0)],
         Color    => Blue);
      Scene : constant Polygon_3D_Array (1 .. 2) := [T1, T2];
   begin
      Render_Scene_3D_ZBuffer (FB, ZB, Scene);
      Check ("13.1 First separate triangle rendered", FB (20, 15) = Red);
      Check ("13.2 Second separate triangle rendered", FB (80, 15) = Blue);
      Check ("13.3 Space between triangles remains black", FB (50, 15) = Black);
   end;

   ---------------------------------------------------------------------------
   -- TEST 14 -- Parity Self-Intersection Fill
   ---------------------------------------------------------------------------
   Put_Line ("TEST 14 -- Parity Self-Intersection Fill");
   Clear_Frame_Buffer (FB, Black);
   declare
      --  Bowtie / figure-eight self-intersecting polygon
      Bowtie : constant Point_2D_Array (1 .. 4) :=
        [(X => 10, Y => 10),
         (X => 50, Y => 50),
         (X => 50, Y => 10),
         (X => 10, Y => 50)];
   begin
      Render_Polygon_2D (FB, Bowtie, White);
      Check ("14.1 Left lobe rendered", FB (15, 20) = White or FB (20, 20) = White);
      Check ("14.2 Right lobe rendered", FB (45, 20) = White or FB (40, 20) = White);
      Check ("14.3 Outside perimeter untouched", FB (2, 2) = Black);
   end;

   ---------------------------------------------------------------------------
   -- Summary
   ---------------------------------------------------------------------------
   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
