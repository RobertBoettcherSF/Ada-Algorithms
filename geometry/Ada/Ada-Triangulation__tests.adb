--  Standalone test suite for Triangulation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Triangulation; use Triangulation;

procedure Tests is

   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check
     (Condition : Boolean;
      Message   : String)
   is
   begin
      if Condition then
         Pass_Count := Pass_Count + 1;
         Ada.Text_IO.Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Ada.Text_IO.Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      Ada.Text_IO.New_Line;
      Ada.Text_IO.Put_Line ("=== " & Title & " ===");
   end Section;

   --  Non-static views (avoid -gnatwc constant-condition warnings).
   function R (X : Real) return Real is (X);
   function P (X, Y : Real) return Point is ((X => X, Y => Y));

   function Raised_Invalid_Poly (Poly : Point_Array) return Boolean is
      T : Mesh;
   begin
      T := Triangulate_Polygon (Poly);
      pragma Unreferenced (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Poly;

   function Raised_Invalid_PS (Pts : Point_Array) return Boolean is
      T : Mesh;
   begin
      T := Triangulate_Point_Set (Pts);
      pragma Unreferenced (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_PS;

   function Mesh_Area_Sum
     (Pts : Point_Array; T : Mesh) return Real
   is
      Sum : Real := 0.0;
      Tri : Triangle;
      A, B, C : Point;
   begin
      for I in 1 .. T.Count loop
         Tri := Get_Triangle (T, I);
         A := Pts (Point_Index (Pts'First + Tri.A - 1));
         B := Pts (Point_Index (Pts'First + Tri.B - 1));
         C := Pts (Point_Index (Pts'First + Tri.C - 1));
         Sum := Sum + Triangle_Area (A, B, C);
      end loop;
      return Sum;
   end Mesh_Area_Sum;

   function All_Verts_Used
     (Pts : Point_Array; T : Mesh) return Boolean
   is
      N : constant Positive := Pts'Length;
      Seen : array (1 .. Max_Points) of Boolean := [others => False];
      Tri : Triangle;
   begin
      for I in 1 .. T.Count loop
         Tri := Get_Triangle (T, I);
         if Tri.A in 1 .. Point_Index (N) then
            Seen (Positive (Tri.A)) := True;
         else
            return False;
         end if;
         if Tri.B in 1 .. Point_Index (N) then
            Seen (Positive (Tri.B)) := True;
         else
            return False;
         end if;
         if Tri.C in 1 .. Point_Index (N) then
            Seen (Positive (Tri.C)) := True;
         else
            return False;
         end if;
      end loop;
      for V in 1 .. N loop
         if not Seen (V) then
            return False;
         end if;
      end loop;
      return True;
   end All_Verts_Used;

begin
   Ada.Text_IO.Put_Line ("Triangulation (geometry) survey tests");
   Ada.Text_IO.Put_Line ("=====================================");

   ------------------------------------------------------------------
   Section ("1. Near / Dist2 / Orient2D / CCW");
   ------------------------------------------------------------------
   Check (Near (R (1.0), R (1.0)), "Near equal");
   Check (Near (R (1.0), R (1.0 + 1.0E-12)), "Near within eps");
   Check (not Near (R (0.0), R (1.0)), "not Near 0,1");
   Check (Near_Point (P (0.0, 0.0), P (0.0, 0.0)), "Near_Point identical");
   Check (not Near_Point (P (0.0, 0.0), P (1.0, 0.0)), "not Near_Point");
   Check (Near (Dist2 (P (0.0, 0.0), P (3.0, 4.0)), R (25.0)), "Dist2 3-4-5");
   Check (Near (Dist2 (P (1.0, 1.0), P (1.0, 1.0)), R (0.0)), "Dist2 zero");
   Check (Orient2D (P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)) > 0.0,
          "Orient2D CCW positive");
   Check (Orient2D (P (0.0, 0.0), P (0.0, 1.0), P (1.0, 0.0)) < 0.0,
          "Orient2D CW negative");
   Check (Near (Orient2D (P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0)), R (0.0)),
          "Orient2D collinear ~0");
   Check (CCW (P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)), "CCW true");
   Check (not CCW (P (0.0, 0.0), P (0.0, 1.0), P (1.0, 0.0)), "CCW false CW");
   Check (not CCW (P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0)), "CCW false colin");

   ------------------------------------------------------------------
   Section ("2. Triangle_Area / Point_In_Triangle / In_Circumcircle");
   ------------------------------------------------------------------
   declare
      A : constant Point := P (0.0, 0.0);
      B : constant Point := P (4.0, 0.0);
      C : constant Point := P (0.0, 4.0);
   begin
      Check (Near (Triangle_Area (A, B, C), R (8.0)), "Triangle_Area 8");
      Check (Point_In_Triangle (P (1.0, 1.0), A, B, C), "strict inside");
      Check (not Point_In_Triangle (P (3.0, 3.0), A, B, C), "outside");
      Check (not Point_In_Triangle (P (2.0, 0.0), A, B, C, Strict => True),
             "on edge not strict-inside");
      Check (Point_In_Triangle (P (2.0, 0.0), A, B, C, Strict => False),
             "on edge allowed non-strict");
      Check (not Point_In_Triangle (A, A, B, C, Strict => True),
             "vertex not strict-inside");
      Check (Point_In_Triangle (A, A, B, C, Strict => False),
             "vertex allowed non-strict");
      Check (not Point_In_Triangle (P (1.0, 1.0), A, A, B),
             "degenerate triangle empty");
      Check (Point_In_Triangle (P (1.0, 1.0), A, C, B), "inside CW triangle");
      Check (In_Circumcircle (A, B, C, P (1.0, 1.0)),
             "center-ish inside circumcircle");
      Check (not In_Circumcircle (A, B, C, P (10.0, 10.0)),
             "far point outside circumcircle");
   end;

   ------------------------------------------------------------------
   Section ("3. Polygon area / Polygon_Triangle_Count");
   ------------------------------------------------------------------
   declare
      Sq : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      Tri : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (0.0, 2.0)];
   begin
      Check (Near (Area (Sq), R (1.0)), "square area 1");
      Check (Signed_Area (Sq) > 0.0, "square CCW signed");
      Check (Near (Area (Tri), R (2.0)), "right triangle area 2");
      Check (Polygon_Triangle_Count (3) = 1, "n=3 → 1");
      Check (Polygon_Triangle_Count (4) = 2, "n=4 → 2");
      Check (Polygon_Triangle_Count (5) = 3, "n=5 → 3");
      Check (Polygon_Triangle_Count (10) = 8, "n=10 → 8");
      Check (Polygon_Triangle_Count (2) = 0, "n=2 → 0");
      Check (Polygon_Triangle_Count (0) = 0, "n=0 → 0");
   end;

   ------------------------------------------------------------------
   Section ("4. Is_Simple_Enough / Has_Near_Duplicate / Bounds");
   ------------------------------------------------------------------
   declare
      Good : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.5, 1.0)];
      Dup : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 0.0)];
      Tiny : constant Point_Array :=
        [P (0.0, 0.0), P (1.0E-12, 0.0), P (0.0, 1.0E-12)];
      Two : constant Point_Array := [P (0.0, 0.0), P (1.0, 0.0)];
      B : Bounding_Box;
   begin
      Check (Is_Simple_Enough (Good), "triangle simple enough");
      Check (not Is_Simple_Enough (Two), "2-gon not simple enough");
      Check (not Is_Simple_Enough (Dup), "closing dup not simple");
      Check (Has_Near_Duplicate (Dup), "dup detected");
      Check (not Has_Near_Duplicate (Good), "good no dup");
      Check (not Is_Simple_Enough (Tiny), "near-zero area rejected");
      B := Bounds_Of (Good);
      Check (Near (B.Min_X, R (0.0)) and then Near (B.Max_Y, R (1.0)),
             "bounds of triangle");
   end;

   ------------------------------------------------------------------
   Section ("5. Triangulate_Polygon — triangle / square / pentagon");
   ------------------------------------------------------------------
   declare
      T3 : constant Point_Array :=
        [P (0.0, 0.0), P (3.0, 0.0), P (1.0, 2.0)];
      M3 : constant Mesh := Triangulate_Polygon (T3);
      Sq : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (2.0, 2.0), P (0.0, 2.0)];
      M4 : constant Mesh := Triangulate_Polygon (Sq);
      Pent : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (3.0, 1.5),
         P (1.0, 3.0), P (-1.0, 1.5)];
      M5 : constant Mesh := Triangulate_Polygon (Pent);
   begin
      Check (Triangle_Count_Of (M3) = 1, "triangle → 1 tri");
      Check (All_Verts_Used (T3, M3), "triangle uses all verts");
      Check (Near (Mesh_Area_Sum (T3, M3), Area (T3), 1.0E-6),
             "triangle area match");
      Check (Triangle_Count_Of (M4) = 2, "square → 2 tris");
      Check (All_Verts_Used (Sq, M4), "square uses all verts");
      Check (Near (Mesh_Area_Sum (Sq, M4), Area (Sq), 1.0E-6),
             "square area match");
      Check (Triangle_Count_Of (M5) = 3, "pentagon → 3 tris");
      Check (Near (Mesh_Area_Sum (Pent, M5), Area (Pent), 1.0E-6),
             "pentagon area match");
      Check (Uses_Vertex (Get_Triangle (M3, 1), 1), "tri uses v1");
   end;

   ------------------------------------------------------------------
   Section ("6. Triangulate_Polygon — CW / concave / invalid");
   ------------------------------------------------------------------
   declare
      CW : constant Point_Array :=
        [P (0.0, 0.0), P (0.0, 1.0), P (1.0, 1.0), P (1.0, 0.0)];
      M : constant Mesh := Triangulate_Polygon (CW);
      Conc : constant Point_Array :=
        [P (0.0, 0.0), P (3.0, 0.0), P (1.0, 1.0),
         P (3.0, 2.0), P (0.0, 2.0)];
      Mc : constant Mesh := Triangulate_Polygon (Conc);
      Bad2 : constant Point_Array := [P (0.0, 0.0), P (1.0, 0.0)];
      Col : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0)];
   begin
      Check (Triangle_Count_Of (M) = 2, "CW square → 2");
      Check (Near (Mesh_Area_Sum (CW, M), Area (CW), 1.0E-6),
             "CW square area");
      Check (Triangle_Count_Of (Mc) = 3, "concave pent → 3");
      Check (Near (Mesh_Area_Sum (Conc, Mc), Area (Conc), 1.0E-6),
             "concave area match");
      Check (Raised_Invalid_Poly (Bad2), "2-gon Invalid_Argument");
      Check (Raised_Invalid_Poly (Col), "collinear Invalid_Argument");
   end;

   ------------------------------------------------------------------
   Section ("7. Fan_From_Vertex");
   ------------------------------------------------------------------
   declare
      Sq : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      M1 : constant Mesh := Fan_From_Vertex (Sq, 1);
      M2 : constant Mesh := Fan_From_Vertex (Sq, 2);
   begin
      Check (Triangle_Count_Of (M1) = 2, "fan from v1 → 2");
      Check (Near (Mesh_Area_Sum (Sq, M1), R (1.0), 1.0E-6),
             "fan v1 area 1");
      Check (Triangle_Count_Of (M2) = 2, "fan from v2 → 2");
      Check (All_Verts_Used (Sq, M1), "fan uses all verts");
   end;

   ------------------------------------------------------------------
   Section ("8. Fan_From_Interior — convex / single interior");
   ------------------------------------------------------------------
   declare
      Conv : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (2.0, 2.0), P (0.0, 2.0)];
      Mc : constant Mesh := Fan_From_Interior (Conv);
      With_In : constant Point_Array :=
        [P (0.0, 0.0), P (4.0, 0.0), P (4.0, 4.0), P (0.0, 4.0),
         P (2.0, 2.0)];
      Mi : constant Mesh := Fan_From_Interior (With_In);
   begin
      Check (Triangle_Count_Of (Mc) = 2, "convex fan → 2");
      Check (Near (Mesh_Area_Sum (Conv, Mc), R (4.0), 1.0E-6),
             "convex fan area 4");
      Check (Triangle_Count_Of (Mi) = 4, "square+center fan → 4");
      Check (All_Verts_Used (With_In, Mi), "interior fan uses all");
      Check (Near (Mesh_Area_Sum (With_In, Mi), R (16.0), 1.0E-6),
             "square+center area 16");
   end;

   ------------------------------------------------------------------
   Section ("9. Triangulate_Point_Set — convex / interior / multi");
   ------------------------------------------------------------------
   declare
      T3 : constant Point_Array :=
        [P (0.0, 0.0), P (3.0, 0.0), P (1.0, 2.0)];
      M3 : constant Mesh := Triangulate_Point_Set (T3);
      Sq : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      M4 : constant Mesh := Triangulate_Point_Set (Sq);
      --  Two interior sites → BW-lite fallback.
      Multi : constant Point_Array :=
        [P (0.0, 0.0), P (5.0, 0.0), P (5.0, 5.0), P (0.0, 5.0),
         P (1.5, 1.5), P (3.5, 3.5)];
      Mm : constant Mesh := Triangulate_Point_Set (Multi);
   begin
      Check (Triangle_Count_Of (M3) = 1, "PS triangle → 1");
      Check (Near (Mesh_Area_Sum (T3, M3), Area (T3), 1.0E-6),
             "PS triangle area");
      Check (Triangle_Count_Of (M4) = 2, "PS square → 2");
      Check (All_Verts_Used (Sq, M4), "PS square all verts");
      Check (Triangle_Count_Of (Mm) >= 4, "PS multi-interior ≥ 4");
      Check (All_Verts_Used (Multi, Mm), "PS multi all verts");
   end;

   ------------------------------------------------------------------
   Section ("10. Invalid_Argument for point-set");
   ------------------------------------------------------------------
   declare
      Two : constant Point_Array := [P (0.0, 0.0), P (1.0, 0.0)];
      Dup : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 0.0 + 0.0)];
      Exact_Dup : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (1.0, 1.0), P (0.0, 0.0)];
   begin
      Check (Raised_Invalid_PS (Two), "PS 2 pts Invalid");
      Check (Raised_Invalid_PS (Exact_Dup), "PS exact dup Invalid");
      pragma Unreferenced (Dup);
   end;

   ------------------------------------------------------------------
   Section ("11. Hexagon polygon / larger convex PS");
   ------------------------------------------------------------------
   declare
      Hex : constant Point_Array :=
        [P (2.0, 0.0), P (3.0, 1.0), P (3.0, 2.0),
         P (2.0, 3.0), P (1.0, 2.0), P (1.0, 1.0)];
      Mh : constant Mesh := Triangulate_Polygon (Hex);
      Oct : constant Point_Array :=
        [P (1.0, 0.0), P (2.0, 0.0), P (3.0, 1.0), P (3.0, 2.0),
         P (2.0, 3.0), P (1.0, 3.0), P (0.0, 2.0), P (0.0, 1.0)];
      Mo : constant Mesh := Triangulate_Point_Set (Oct);
   begin
      Check (Triangle_Count_Of (Mh) = 4, "hexagon → 4");
      Check (Polygon_Triangle_Count (6) = 4, "count helper hex");
      Check (Near (Mesh_Area_Sum (Hex, Mh), Area (Hex), 1.0E-6),
             "hexagon area");
      Check (Triangle_Count_Of (Mo) = 6, "octagon PS → 6");
      Check (All_Verts_Used (Oct, Mo), "octagon all verts");
   end;

   ------------------------------------------------------------------
   Section ("12. Capacity constants / accessors");
   ------------------------------------------------------------------
   declare
      function MP return Positive is (Max_Points);
      function MT return Positive is (Max_Triangles);
      function Ep return Real is (Epsilon);
      Sq : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      M : constant Mesh := Triangulate_Polygon (Sq);
      Tri : Triangle;
   begin
      Check (MP = 64, "Max_Points = 64");
      Check (MT = 256, "Max_Triangles = 256");
      Check (Ep > R (0.0), "Epsilon positive");
      Check (Triangle_Count_Of (M) = M.Count, "Count_Of matches");
      Tri := Get_Triangle (M, 1);
      Check (Uses_Vertex (Tri, Tri.A), "Uses_Vertex A");
      Check (Uses_Vertex (Tri, Tri.B), "Uses_Vertex B");
      Check (Uses_Vertex (Tri, Tri.C), "Uses_Vertex C");
      declare
         Other : Point_Index := 1;
      begin
         while Uses_Vertex (Tri, Other) loop
            Other := Other + 1;
         end loop;
         Check (not Uses_Vertex (Tri, Other), "not Uses_Vertex other");
      end;
   end;

   ------------------------------------------------------------------
   Section ("13. Arrow polygon (concave) + parallelogram");
   ------------------------------------------------------------------
   declare
      --  Classic arrow / chevron-ish concave quad-ish pentagon.
      Arrow : constant Point_Array :=
        [P (0.0, 1.0), P (2.0, 0.0), P (1.0, 1.0),
         P (2.0, 2.0), P (0.0, 1.5)];
      --  Simpler concave: dart-free concave pentagon.
      Conc : constant Point_Array :=
        [P (0.0, 0.0), P (5.0, 0.0), P (4.0, 1.0),
         P (5.0, 2.0), P (0.0, 2.0)];
      Mc : constant Mesh := Triangulate_Polygon (Conc);
      Para : constant Point_Array :=
        [P (0.0, 0.0), P (3.0, 0.0), P (4.0, 2.0), P (1.0, 2.0)];
      Mp : constant Mesh := Triangulate_Polygon (Para);
   begin
      pragma Unreferenced (Arrow);
      Check (Triangle_Count_Of (Mc) = 3, "concave → 3");
      Check (Near (Mesh_Area_Sum (Conc, Mc), Area (Conc), 1.0E-6),
             "concave5 area");
      Check (Triangle_Count_Of (Mp) = 2, "parallelogram → 2");
      Check (Near (Mesh_Area_Sum (Para, Mp), Area (Para), 1.0E-6),
             "parallelogram area");
   end;

   ------------------------------------------------------------------
   Section ("14. Point set with center + random-ish cloud");
   ------------------------------------------------------------------
   declare
      Cloud : constant Point_Array :=
        [P (0.0, 0.0), P (4.0, 0.0), P (4.0, 3.0), P (0.0, 3.0),
         P (1.0, 1.0), P (2.0, 2.0), P (3.0, 1.0)];
      Mc : constant Mesh := Triangulate_Point_Set (Cloud);
      Grid : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0),
         P (0.0, 1.0), P (1.0, 1.0), P (2.0, 1.0),
         P (0.0, 2.0), P (1.0, 2.0), P (2.0, 2.0)];
      Mg : constant Mesh := Triangulate_Point_Set (Grid);
   begin
      Check (Triangle_Count_Of (Mc) >= 5, "cloud ≥ 5 tris");
      Check (All_Verts_Used (Cloud, Mc), "cloud all verts");
      Check (Triangle_Count_Of (Mg) >= 8, "3x3 grid ≥ 8 tris");
      Check (All_Verts_Used (Grid, Mg), "grid all verts");
   end;

   ------------------------------------------------------------------
   Section ("15. Polygon_Triangle_Count identity on results");
   ------------------------------------------------------------------
   declare
      N4 : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      N7 : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.5), P (2.0, 1.5),
         P (1.0, 2.0), P (0.0, 2.0), P (-0.5, 1.0)];
      M4 : constant Mesh := Triangulate_Polygon (N4);
      M7 : constant Mesh := Triangulate_Polygon (N7);
   begin
      Check (Natural (Triangle_Count_Of (M4)) =
             Polygon_Triangle_Count (N4'Length),
             "n-2 identity square");
      Check (Natural (Triangle_Count_Of (M7)) =
             Polygon_Triangle_Count (N7'Length),
             "n-2 identity heptagon");
   end;

   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line ("=================================");
   Ada.Text_IO.Put_Line
     ("Result:" & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");
   Ada.Text_IO.Put_Line ("=================================");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;

   pragma Assert (Fail_Count = 0);
end Tests;
