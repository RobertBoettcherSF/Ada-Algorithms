--  Standalone test suite for Polygon_Triangulation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Polygon_Triangulation; use Polygon_Triangulation;

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

   function Raised_Invalid (Poly : Point_Array) return Boolean is
      T : Triangulation;
   begin
      T := Triangulate_Ear_Clip (Poly);
      pragma Unreferenced (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid;

   --  Sum of absolute triangle areas should match polygon area.
   function Tri_Area_Sum
     (Poly : Point_Array; T : Triangulation) return Real
   is
      Sum : Real := 0.0;
      Tri : Triangle;
      A, B, C : Point;
   begin
      for I in 1 .. T.Count loop
         Tri := Get_Triangle (T, I);
         A := Poly (Vertex_Index (Poly'First + Tri.A - 1));
         B := Poly (Vertex_Index (Poly'First + Tri.B - 1));
         C := Poly (Vertex_Index (Poly'First + Tri.C - 1));
         Sum := Sum + abs (Orient2D (A, B, C)) / 2.0;
      end loop;
      return Sum;
   end Tri_Area_Sum;

   function All_Verts_Used
     (Poly : Point_Array; T : Triangulation) return Boolean
   is
      N : constant Positive := Poly'Length;
      Seen : array (1 .. Max_Vertices) of Boolean := [others => False];
      Tri : Triangle;
   begin
      for I in 1 .. T.Count loop
         Tri := Get_Triangle (T, I);
         if Tri.A in 1 .. N then
            Seen (Tri.A) := True;
         else
            return False;
         end if;
         if Tri.B in 1 .. N then
            Seen (Tri.B) := True;
         else
            return False;
         end if;
         if Tri.C in 1 .. N then
            Seen (Tri.C) := True;
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
   Ada.Text_IO.Put_Line ("Polygon_Triangulation tests");
   Ada.Text_IO.Put_Line ("===========================");

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
   Section ("2. Point_In_Triangle");
   ------------------------------------------------------------------
   declare
      A : constant Point := P (0.0, 0.0);
      B : constant Point := P (4.0, 0.0);
      C : constant Point := P (0.0, 4.0);
   begin
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
      --  CW triangle still works
      Check (Point_In_Triangle (P (1.0, 1.0), A, C, B), "inside CW triangle");
      Check (not Point_In_Triangle (P (5.0, 5.0), A, C, B), "outside CW");
   end;

   ------------------------------------------------------------------
   Section ("3. Signed_Area / Area / Is_CCW");
   ------------------------------------------------------------------
   declare
      Unit_Sq_CCW : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      Unit_Sq_CW : constant Point_Array :=
        [P (0.0, 0.0), P (0.0, 1.0), P (1.0, 1.0), P (1.0, 0.0)];
      Tri : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (0.0, 2.0)];
   begin
      Check (Near (Area (Unit_Sq_CCW), R (1.0), 1.0E-9), "unit square area");
      Check (Signed_Area (Unit_Sq_CCW) > 0.0, "CCW square signed > 0");
      Check (Signed_Area (Unit_Sq_CW) < 0.0, "CW square signed < 0");
      Check (Is_CCW (Unit_Sq_CCW), "Is_CCW square");
      Check (not Is_CCW (Unit_Sq_CW), "not Is_CCW CW square");
      Check (Near (Area (Unit_Sq_CW), R (1.0), 1.0E-9), "CW square abs area");
      Check (Near (Area (Tri), R (2.0), 1.0E-9), "right triangle area 2");
      Check (Near (Signed_Area (Tri), R (4.0), 1.0E-9),
             "triangle twice-area 4");
   end;

   ------------------------------------------------------------------
   Section ("4. Is_Convex_Vertex / Is_Ear");
   ------------------------------------------------------------------
   declare
      --  Convex square CCW: every vertex convex and an ear.
      Sq : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (2.0, 2.0), P (0.0, 2.0)];
      --  Concave arrow / chevron (dart): tip at (1,0.5) pushed in.
      --  Vertices CCW: (0,0), (3,0), (3,2), (1.5,0.5), (0,2)
      Arrow : constant Point_Array :=
        [P (0.0, 0.0), P (3.0, 0.0), P (3.0, 2.0),
         P (1.5, 0.5), P (0.0, 2.0)];
   begin
      Check (Is_Convex_Vertex (Sq, 1), "square v1 convex");
      Check (Is_Convex_Vertex (Sq, 2), "square v2 convex");
      Check (Is_Convex_Vertex (Sq, 3), "square v3 convex");
      Check (Is_Convex_Vertex (Sq, 4), "square v4 convex");
      Check (Is_Ear (Sq, 1), "square v1 ear");
      Check (Is_Ear (Sq, 2), "square v2 ear");
      Check (Is_Ear (Sq, 3), "square v3 ear");
      Check (Is_Ear (Sq, 4), "square v4 ear");

      Check (Is_Convex_Vertex (Arrow, 1), "arrow v1 convex");
      Check (Is_Convex_Vertex (Arrow, 2), "arrow v2 convex");
      Check (Is_Convex_Vertex (Arrow, 3), "arrow v3 convex");
      Check (not Is_Convex_Vertex (Arrow, 4), "arrow reflex tip not convex");
      Check (Is_Convex_Vertex (Arrow, 5), "arrow v5 convex");
      Check (not Is_Ear (Arrow, 4), "reflex tip is not an ear");
      Check (Is_Ear (Arrow, 1) or else Is_Ear (Arrow, 2)
             or else Is_Ear (Arrow, 3) or else Is_Ear (Arrow, 5),
             "arrow has at least one ear");
   end;

   ------------------------------------------------------------------
   Section ("5. Is_Simple_Enough / Invalid_Argument");
   ------------------------------------------------------------------
   declare
      Ok : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)];
      Too_Few : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0)];
      Dup_Edge : constant Point_Array :=
        [P (0.0, 0.0), P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)];
      Flat : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0)];
      Near_Dup : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0E-12), P (0.0, 1.0)];
   begin
      Check (Is_Simple_Enough (Ok), "triangle simple enough");
      Check (not Is_Simple_Enough (Too_Few), "2-gon not enough");
      Check (not Is_Simple_Enough (Dup_Edge), "dup consecutive rejected");
      Check (not Is_Simple_Enough (Flat), "collinear zero-area rejected");
      Check (not Is_Simple_Enough (Near_Dup), "near-dup consecutive");
      Check (Raised_Invalid (Too_Few), "triangulate rejects 2-gon");
      Check (Raised_Invalid (Flat), "triangulate rejects flat");
      Check (Raised_Invalid (Dup_Edge), "triangulate rejects dup edge");
   end;

   ------------------------------------------------------------------
   Section ("6. Triangle (n=3 → 1 triangle)");
   ------------------------------------------------------------------
   declare
      Poly : constant Point_Array :=
        [P (0.0, 0.0), P (3.0, 0.0), P (0.0, 4.0)];
      T : constant Triangulation := Triangulate_Ear_Clip (Poly);
      Tri : Triangle;
   begin
      Check (Triangle_Count_Of (T) = 1, "triangle → 1 face");
      Check (T.Count = 1, "Count field = 1");
      Tri := Get_Triangle (T, 1);
      Check (Uses_Vertex (Tri, 1) and then Uses_Vertex (Tri, 2)
             and then Uses_Vertex (Tri, 3),
             "uses all three vertices");
      Check (Near (Tri_Area_Sum (Poly, T), Area (Poly), 1.0E-6),
             "triangle area preserved");
      Check (All_Verts_Used (Poly, T), "all verts appear");
   end;

   ------------------------------------------------------------------
   Section ("7. Square (n=4 → 2 triangles)");
   ------------------------------------------------------------------
   declare
      Poly : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (2.0, 2.0), P (0.0, 2.0)];
      T : constant Triangulation := Triangulate_Ear_Clip (Poly);
   begin
      Check (Triangle_Count_Of (T) = 2, "square → 2 faces");
      Check (Near (Tri_Area_Sum (Poly, T), Area (Poly), 1.0E-6),
             "square area preserved");
      Check (All_Verts_Used (Poly, T), "square all verts used");
      Check (Near (Area (Poly), R (4.0), 1.0E-9), "square area = 4");
   end;

   --  CW square should also work (normalize internally)
   declare
      Poly : constant Point_Array :=
        [P (0.0, 0.0), P (0.0, 2.0), P (2.0, 2.0), P (2.0, 0.0)];
      T : constant Triangulation := Triangulate_Ear_Clip (Poly);
   begin
      Check (not Is_CCW (Poly), "CW square input");
      Check (Triangle_Count_Of (T) = 2, "CW square → 2 faces");
      Check (Near (Tri_Area_Sum (Poly, T), Area (Poly), 1.0E-6),
             "CW square area preserved");
      Check (All_Verts_Used (Poly, T), "CW square all verts");
   end;

   ------------------------------------------------------------------
   Section ("8. Convex pentagon (n=5 → 3 triangles)");
   ------------------------------------------------------------------
   declare
      --  Regular-ish convex pentagon, CCW.
      Poly : constant Point_Array :=
        [P (1.0, 0.0),
         P (0.309, 0.951),
         P (-0.809, 0.588),
         P (-0.809, -0.588),
         P (0.309, -0.951)];
      T : constant Triangulation := Triangulate_Ear_Clip (Poly);
   begin
      Check (Is_CCW (Poly), "pentagon CCW");
      Check (Triangle_Count_Of (T) = 3, "pentagon → 3 faces");
      Check (Near (Tri_Area_Sum (Poly, T), Area (Poly), 1.0E-5),
             "pentagon area preserved");
      Check (All_Verts_Used (Poly, T), "pentagon all verts");
      Check (Is_Convex_Vertex (Poly, 1), "pentagon v1 convex");
      Check (Is_Convex_Vertex (Poly, 3), "pentagon v3 convex");
      Check (Is_Ear (Poly, 1), "pentagon v1 ear");
      Check (Is_Ear (Poly, 2), "pentagon v2 ear");
   end;

   ------------------------------------------------------------------
   Section ("9. Concave arrow / chevron (n=5 → 3 triangles)");
   ------------------------------------------------------------------
   declare
      --  Arrowhead / dart: concave at vertex 4.
      Poly : constant Point_Array :=
        [P (0.0, 0.0), P (4.0, 0.0), P (4.0, 3.0),
         P (2.0, 1.0), P (0.0, 3.0)];
      T : constant Triangulation := Triangulate_Ear_Clip (Poly);
   begin
      Check (Is_Simple_Enough (Poly), "arrow simple enough");
      Check (not Is_Convex_Vertex (Poly, 4), "arrow tip reflex");
      Check (Triangle_Count_Of (T) = 3, "arrow → 3 faces");
      Check (Near (Tri_Area_Sum (Poly, T), Area (Poly), 1.0E-5),
             "arrow area preserved");
      Check (All_Verts_Used (Poly, T), "arrow all verts");
      --  Reflex vertex must still appear in some triangle.
      declare
         Found : Boolean := False;
         Tri : Triangle;
      begin
         for I in 1 .. T.Count loop
            Tri := Get_Triangle (T, I);
            if Uses_Vertex (Tri, 4) then
               Found := True;
            end if;
         end loop;
         Check (Found, "reflex vertex appears in a triangle");
      end;
   end;

   --  Classic chevron / V-notch concave quad-like pentagon variant
   declare
      Poly : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 1.0), P (4.0, 0.0),
         P (3.0, 2.0), P (1.0, 2.0)];
      T : constant Triangulation := Triangulate_Ear_Clip (Poly);
   begin
      Check (Triangle_Count_Of (T) = 3, "chevron → 3 faces");
      Check (Near (Tri_Area_Sum (Poly, T), Area (Poly), 1.0E-5),
             "chevron area preserved");
      Check (All_Verts_Used (Poly, T), "chevron all verts");
   end;

   ------------------------------------------------------------------
   Section ("10. Convex hexagon / larger n");
   ------------------------------------------------------------------
   declare
      Poly : constant Point_Array :=
        [P (2.0, 0.0), P (1.0, 1.732), P (-1.0, 1.732),
         P (-2.0, 0.0), P (-1.0, -1.732), P (1.0, -1.732)];
      T : constant Triangulation := Triangulate_Ear_Clip (Poly);
   begin
      Check (Triangle_Count_Of (T) = 4, "hexagon → 4 faces (n-2)");
      Check (Near (Tri_Area_Sum (Poly, T), Area (Poly), 1.0E-4),
             "hexagon area preserved");
      Check (All_Verts_Used (Poly, T), "hexagon all verts");
   end;

   ------------------------------------------------------------------
   Section ("11. Accessors / Uses_Vertex");
   ------------------------------------------------------------------
   declare
      Poly : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      T : constant Triangulation := Triangulate_Ear_Clip (Poly);
      Tri : constant Triangle := Get_Triangle (T, 1);
   begin
      Check (Triangle_Count_Of (T) = T.Count, "Count_Of matches field");
      Check (Uses_Vertex (Tri, Tri.A), "Uses_Vertex A");
      Check (Uses_Vertex (Tri, Tri.B), "Uses_Vertex B");
      Check (Uses_Vertex (Tri, Tri.C), "Uses_Vertex C");
      Check (not Uses_Vertex ((A => 1, B => 2, C => 3), 4),
             "Uses_Vertex miss");
   end;

   ------------------------------------------------------------------
   Section ("12. Fan-like convex / thin shapes");
   ------------------------------------------------------------------
   declare
      --  Convex "house": square + roof
      House : constant Point_Array :=
        [P (0.0, 0.0), P (4.0, 0.0), P (4.0, 3.0),
         P (2.0, 5.0), P (0.0, 3.0)];
      T : constant Triangulation := Triangulate_Ear_Clip (House);
   begin
      Check (Triangle_Count_Of (T) = 3, "house → 3 faces");
      Check (Near (Tri_Area_Sum (House, T), Area (House), 1.0E-5),
             "house area preserved");
   end;

   declare
      --  Thin parallelogram
      Para : constant Point_Array :=
        [P (0.0, 0.0), P (3.0, 0.0), P (4.0, 1.0), P (1.0, 1.0)];
      T : constant Triangulation := Triangulate_Ear_Clip (Para);
   begin
      Check (Triangle_Count_Of (T) = 2, "parallelogram → 2");
      Check (Near (Tri_Area_Sum (Para, T), Area (Para), 1.0E-6),
             "parallelogram area");
   end;

   ------------------------------------------------------------------
   Section ("13. Max capacity / educational bounds");
   ------------------------------------------------------------------
   declare
      --  Non-static views of constants (avoid -gnatwc).
      function MV return Positive is (Max_Vertices);
      function MT return Positive is (Max_Triangles);
      function Ep return Real is (Epsilon);
   begin
      Check (MV = 64, "Max_Vertices = 64");
      Check (MT = 62, "Max_Triangles = n-2 max");
      Check (Ep > R (0.0), "Epsilon positive");
   end;

   ------------------------------------------------------------------
   Section ("14. Indexed polygon slice (non-1 First)");
   ------------------------------------------------------------------
   --  Point_Array is Vertex_Index range <> so First is always >= 1.
   --  Still verify triangulation with a local array starting at 1.
   declare
      Poly : constant Point_Array (1 .. 4) :=
        [1 => P (0.0, 0.0), 2 => P (1.0, 0.0),
         3 => P (1.0, 1.0), 4 => P (0.0, 1.0)];
      T : constant Triangulation := Triangulate_Ear_Clip (Poly);
   begin
      Check (Triangle_Count_Of (T) = 2, "explicit 1..4 square");
      Check (Near (Tri_Area_Sum (Poly, T), R (1.0), 1.0E-6),
             "explicit square area 1");
   end;

   ------------------------------------------------------------------
   Section ("15. Extra ear / convexity on CW polygon");
   ------------------------------------------------------------------
   declare
      CW : constant Point_Array :=
        [P (0.0, 0.0), P (0.0, 1.0), P (1.0, 1.0), P (1.0, 0.0)];
   begin
      Check (not Is_CCW (CW), "CW detect");
      Check (Is_Convex_Vertex (CW, 1), "CW square still convex v1");
      Check (Is_Convex_Vertex (CW, 2), "CW square still convex v2");
      Check (Is_Ear (CW, 1), "CW square ear v1");
      Check (Is_Ear (CW, 3), "CW square ear v3");
   end;

   ------------------------------------------------------------------
   -- Summary
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
end Tests;
