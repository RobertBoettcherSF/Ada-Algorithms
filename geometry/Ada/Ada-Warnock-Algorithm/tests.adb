with Ada.Text_IO; use Ada.Text_IO;
with Warnock_Algorithm; use Warnock_Algorithm;

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

   --  Shared polygon factories
   function Make_Triangle
     (P1, P2, P3 : Point_2D;
      Z_Val      : Real;
      C          : RGBA_Color) return Polygon_Record
   is
      Poly : Polygon_Record (3);
   begin
      Poly.Vertices := [1 => P1, 2 => P2, 3 => P3];
      --  Equation z = Z_Val => 0x + 0y + 1z - Z_Val = 0
      Poly.Plane    := (A => 0.0, B => 0.0, C => 1.0, D => -Z_Val);
      Poly.Color    := C;
      return Poly;
   end Make_Triangle;

   function Make_Quad
     (P1, P2, P3, P4 : Point_2D;
      Z_Val          : Real;
      C              : RGBA_Color) return Polygon_Record
   is
      Poly : Polygon_Record (4);
   begin
      Poly.Vertices := [1 => P1, 2 => P2, 3 => P3, 4 => P4];
      Poly.Plane    := (A => 0.0, B => 0.0, C => 1.0, D => -Z_Val);
      Poly.Color    := C;
      return Poly;
   end Make_Quad;

begin
   --  TEST 1 — Viewport_Area Validity and Helpers
   Put_Line ("TEST 1 — Area Metrics and Validation");
   declare
      A : constant Viewport_Area := (Min_X => 0.0, Min_Y => 0.0, Max_X => 10.0, Max_Y => 20.0);
      C : constant Point_2D := Area_Center (A);
   begin
      Check ("1.1 Area validity check", Is_Valid_Area (A));
      Check ("1.2 Area width calculation", Area_Width (A) = 10.0);
      Check ("1.3 Area height and center calculation", Area_Height (A) = 20.0 and C.X = 5.0 and C.Y = 10.0);
   end;

   --  TEST 2 — Quad Split Subdivisions
   Put_Line ("TEST 2 — Quadtree Area Splitting");
   declare
      A : constant Viewport_Area := (Min_X => 0.0, Min_Y => 0.0, Max_X => 4.0, Max_Y => 4.0);
      Splits : constant Quad_Split := Split_Area (A);
   begin
      Check ("2.1 Subquadrant 1 bounds", Splits (1).Min_X = 0.0 and Splits (1).Max_X = 2.0 and Splits (1).Max_Y = 2.0);
      Check ("2.2 Subquadrant 4 bounds", Splits (4).Min_X = 2.0 and Splits (4).Max_X = 4.0 and Splits (4).Min_Y = 2.0);
      Check ("2.3 Area preservation across splits", Area_Width (Splits (1)) = 2.0 and Area_Height (Splits (4)) = 2.0);
   end;

   --  TEST 3 — Plane Equation Z Evaluation
   Put_Line ("TEST 3 — Plane Z Evaluation");
   declare
      --  2x + 3y + z - 10 = 0 => z = 10 - 2x - 3y
      P_Equ : constant Plane_Equation := (A => 2.0, B => 3.0, C => 1.0, D => -10.0);
      Pt1   : constant Point_2D := (X => 0.0, Y => 0.0);
      Pt2   : constant Point_2D := (X => 1.0, Y => 2.0);
   begin
      Check ("3.1 Evaluate at origin", Evaluate_Z (P_Equ, Pt1) = 10.0);
      Check ("3.2 Evaluate at (1,2)", Evaluate_Z (P_Equ, Pt2) = 2.0);
      Check ("3.3 Sloped plane z gradient", Evaluate_Z (P_Equ, (X => 5.0, Y => 0.0)) = 0.0);
   end;

   --  TEST 4 — Relationship Classification: Disjoint
   Put_Line ("TEST 4 — Classification: Disjoint Polygon");
   declare
      A : constant Viewport_Area := (Min_X => 0.0, Min_Y => 0.0, Max_X => 1.0, Max_Y => 1.0);
      P : constant Polygon_Record := Make_Triangle
        ((2.0, 2.0), (3.0, 2.0), (2.5, 3.0), 1.0, Red);
      Rel : constant Relationship_Type := Classify_Relationship (P, A);
   begin
      Check ("4.1 Far polygon is disjoint", Rel = Disjoint_Polygon);
      Check ("4.2 Disjoint maintains no edge intersect", not (Rel = Intersecting_Polygon));
      Check ("4.3 Not surrounding", not (Rel = Surrounding_Polygon));
   end;

   --  TEST 5 — Relationship Classification: Contained
   Put_Line ("TEST 5 — Classification: Contained Polygon");
   declare
      A : constant Viewport_Area := (Min_X => 0.0, Min_Y => 0.0, Max_X => 10.0, Max_Y => 10.0);
      P : constant Polygon_Record := Make_Triangle
        ((1.0, 1.0), (3.0, 1.0), (2.0, 3.0), 1.0, Green);
      Rel : constant Relationship_Type := Classify_Relationship (P, A);
   begin
      Check ("5.1 Interior triangle is contained", Rel = Contained_Polygon);
      Check ("5.2 Contained is not disjoint", Rel /= Disjoint_Polygon);
      Check ("5.3 Contained is not intersecting boundary", Rel /= Intersecting_Polygon);
   end;

   --  TEST 6 — Relationship Classification: Surrounding
   Put_Line ("TEST 6 — Classification: Surrounding Polygon");
   declare
      A : constant Viewport_Area := (Min_X => 2.0, Min_Y => 2.0, Max_X => 3.0, Max_Y => 3.0);
      P : constant Polygon_Record := Make_Quad
        ((0.0, 0.0), (10.0, 0.0), (10.0, 10.0), (0.0, 10.0), 5.0, Blue);
      Rel : constant Relationship_Type := Classify_Relationship (P, A);
   begin
      Check ("6.1 Enclosing polygon classifies as Surrounding", Rel = Surrounding_Polygon);
      Check ("6.2 Corners test yields surrounding", Rel /= Contained_Polygon);
      Check ("6.3 Surrounding polygon found as frontmost", Find_Frontmost_Surrounding ([1 => P], A) = 1);
   end;

   --  TEST 7 — Relationship Classification: Intersecting
   Put_Line ("TEST 7 — Classification: Intersecting Polygon");
   declare
      A : constant Viewport_Area := (Min_X => 0.0, Min_Y => 0.0, Max_X => 2.0, Max_Y => 2.0);
      P : constant Polygon_Record := Make_Triangle
        ((-1.0, 1.0), (3.0, 1.0), (1.0, 3.0), 1.0, Red);
      Rel : constant Relationship_Type := Classify_Relationship (P, A);
   begin
      Check ("7.1 Polygon crossing borders is intersecting", Rel = Intersecting_Polygon);
      Check ("7.2 Intersecting is not contained", Rel /= Contained_Polygon);
      Check ("7.3 Intersecting is not surrounding", Rel /= Surrounding_Polygon);
   end;

   --  TEST 8 — Standard Render: Empty Polygon List (Background Fallback)
   Put_Line ("TEST 8 — Standard Render: Empty Polygons");
   declare
      Empty_Polys : constant Polygon_Array (1 .. 0) := [others => <>];
      Area        : constant Viewport_Area := (0.0, 0.0, 4.0, 4.0);
      Color_Out   : RGBA_Color;
   begin
      Render_Standard (Empty_Polys, Area, Black, 0.5, Color_Out);
      Check ("8.1 Output is background red component", Color_Out.Red = Black.Red);
      Check ("8.2 Output is background green component", Color_Out.Green = Black.Green);
      Check ("8.3 Output is background blue component", Color_Out.Blue = Black.Blue);
   end;

   --  TEST 9 — Standard Render: Depth Occlusion (Z-Buffer logic)
   Put_Line ("TEST 9 — Standard Render: Depth Occlusion");
   declare
      Area : constant Viewport_Area := (0.0, 0.0, 2.0, 2.0);
      P_Back : constant Polygon_Record := Make_Quad
        ((-1.0, -1.0), (3.0, -1.0), (3.0, 3.0), (-1.0, 3.0), 1.0, Red);
      P_Front : constant Polygon_Record := Make_Quad
        ((-1.0, -1.0), (3.0, -1.0), (3.0, 3.0), (-1.0, 3.0), 5.0, Blue);
      Polys : constant Polygon_Array (1 .. 2) := [1 => P_Back, 2 => P_Front];
      Out_Col : RGBA_Color;
   begin
      Render_Standard (Polys, Area, White, 0.1, Out_Col);
      Check ("9.1 Front polygon obscures back (Blue component)", Out_Col.Blue = Blue.Blue);
      Check ("9.2 Front polygon obscures back (Red component is 0)", Out_Col.Red = 0);
      Check ("9.3 Alpha preserved", Out_Col.Alpha = 255);
   end;

   --  TEST 10 — Framebuffer Render Variant
   Put_Line ("TEST 10 — Framebuffer Grid Rasterization");
   declare
      Area   : constant Viewport_Area := (0.0, 0.0, 4.0, 4.0);
      Buffer : Framebuffer (0 .. 3, 0 .. 3) := [others => [others => White]];
      P      : constant Polygon_Record := Make_Quad
        ((-1.0, -1.0), (5.0, -1.0), (5.0, 5.0), (-1.0, 5.0), 2.0, Green);
      Polys  : constant Polygon_Array (1 .. 1) := [1 => P];
   begin
      Render_Framebuffer (Polys, Area, Black, Buffer, Max_Depth => 2);
      Check ("10.1 Pixel (0,0) rendered to green", Buffer (0, 0).Green = Green.Green);
      Check ("10.2 Pixel (3,3) rendered to green", Buffer (3, 3).Green = Green.Green);
      Check ("10.3 Pixel (1,1) red component is 0", Buffer (1, 1).Red = 0);
   end;

   --  TEST 11 — Adaptive Supersampling Anti-Aliasing
   Put_Line ("TEST 11 — Adaptive Supersampling");
   declare
      Area    : constant Viewport_Area := (0.0, 0.0, 2.0, 2.0);
      P       : constant Polygon_Record := Make_Quad
        ((0.0, 0.0), (1.0, 0.0), (1.0, 2.0), (0.0, 2.0), 1.0, Red);
      Polys   : constant Polygon_Array (1 .. 1) := [1 => P];
      Out_Col : RGBA_Color;
   begin
      --  Half area covered by Red, half by Black
      Render_Adaptive_Supersampled (Polygons => Polys,
                                    Area     => Area,
                                    Background_Color => Black,
                                    Resolution_Limit => 0.5,
                                    Output_Color     => Out_Col);
      Check ("11.1 Mixed boundary creates intermediate Red", Out_Col.Red > 0 and Out_Col.Red < 255);
      Check ("11.2 Green remains 0 in blend", Out_Col.Green = 0);
      Check ("11.3 Blue remains 0 in blend", Out_Col.Blue = 0);
   end;

   --  TEST 12 — Diagnostic Stats Counting Nodes
   Put_Line ("TEST 12 — Diagnostic Quadtree Statistics");
   declare
      Area        : constant Viewport_Area := (0.0, 0.0, 8.0, 8.0);
      P           : constant Polygon_Record := Make_Triangle ((1.0, 1.0), (2.0, 1.0), (1.5, 2.0), 1.0, Red);
      Polys       : constant Polygon_Array (1 .. 1) := [1 => P];
      Total_Nodes : Natural;
      Max_Depth   : Natural;
   begin
      Render_Diagnostic_Stats (Polygons         => Polys,
                               Area             => Area,
                               Background_Color => White,
                               Resolution_Limit => 1.0,
                               Total_Nodes      => Total_Nodes,
                               Max_Depth_Hit    => Max_Depth);
      Check ("12.1 Visited more than root node", Total_Nodes > 1);
      Check ("12.2 Tree subdivided to multiple levels", Max_Depth >= 2);
      Check ("12.3 Diagnostic finished non-zero", Total_Nodes >= 5);
   end;

   --  TEST 13 — Edge Case: Degenerate Viewport Validation
   Put_Line ("TEST 13 — Degenerate Viewport Validation");
   declare
      Bad_Area_1 : constant Viewport_Area := (Min_X => 2.0, Min_Y => 0.0, Max_X => 1.0, Max_Y => 5.0);
      Bad_Area_2 : constant Viewport_Area := (Min_X => 0.0, Min_Y => 5.0, Max_X => 5.0, Max_Y => 5.0);
      Valid_Area : constant Viewport_Area := (Min_X => 0.0, Min_Y => 0.0, Max_X => 0.1, Max_Y => 0.1);
   begin
      Check ("13.1 Inverted X axis rejected", not Is_Valid_Area (Bad_Area_1));
      Check ("13.2 Flat Y height rejected", not Is_Valid_Area (Bad_Area_2));
      Check ("13.3 Small positive area accepted", Is_Valid_Area (Valid_Area));
   end;

   --  TEST 14 — Edge Case: Planar Z Occlusion with Tilted Geometry
   Put_Line ("TEST 14 — Tilted Geometry Plane Sorting");
   declare
      --  Plane sloping steeply along X: z = 10 - x
      Sloped_Plane : constant Plane_Equation := (A => 1.0, B => 0.0, C => 1.0, D => -10.0);
      --  Flat Plane: z = 5
      Flat_Plane   : constant Plane_Equation := (A => 0.0, B => 0.0, C => 1.0, D => -5.0);
      P_Low  : constant Point_2D := (X => 8.0, Y => 0.0);
      P_High : constant Point_2D := (X => 1.0, Y => 0.0);
   begin
      Check ("14.1 Sloped plane higher at x=1 (z=9 vs z=5)",
             Evaluate_Z (Sloped_Plane, P_High) > Evaluate_Z (Flat_Plane, P_High));
      Check ("14.2 Sloped plane lower at x=8 (z=2 vs z=5)",
             Evaluate_Z (Sloped_Plane, P_Low) < Evaluate_Z (Flat_Plane, P_Low));
      Check ("14.3 Exact intersection at x=5 (z=5)",
             Evaluate_Z (Sloped_Plane, (X => 5.0, Y => 0.0)) = Evaluate_Z (Flat_Plane, (X => 5.0, Y => 0.0)));
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed, "
             & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
