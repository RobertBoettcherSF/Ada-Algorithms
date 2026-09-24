--  Standalone test suite for Voronoi_Diagrams (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Voronoi_Diagrams; use Voronoi_Diagrams;

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

   function Raised_Invalid_Delaunay (Pts : Point_Array) return Boolean is
      T : Triangulation;
   begin
      T := Delaunay_From_Sites (Pts);
      pragma Unreferenced (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Delaunay;

   function Raised_Invalid_Voronoi (Pts : Point_Array) return Boolean is
      V : Voronoi_Diagram;
   begin
      V := Build_Voronoi (Pts);
      pragma Unreferenced (V);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Voronoi;

   function Raised_Invalid_Nearest
     (Q : Point; Pts : Point_Array) return Boolean
   is
      I : Site_Index;
   begin
      I := Nearest_Site (Q, Pts);
      pragma Unreferenced (I);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Nearest;

begin
   Ada.Text_IO.Put_Line ("Voronoi_Diagrams tests");
   Ada.Text_IO.Put_Line ("======================");

   ------------------------------------------------------------------
   Section ("1. Near / Dist2 / Distance / Orient2D / CCW");
   ------------------------------------------------------------------
   Check (Near (R (1.0), R (1.0)), "Near equal");
   Check (Near (R (1.0), R (1.0 + 1.0E-12)), "Near within eps");
   Check (not Near (R (0.0), R (1.0)), "not Near 0,1");
   Check (Near_Point (P (0.0, 0.0), P (0.0, 0.0)), "Near_Point identical");
   Check (not Near_Point (P (0.0, 0.0), P (1.0, 0.0)), "not Near_Point");
   Check (Near (Dist2 (P (0.0, 0.0), P (3.0, 4.0)), R (25.0)), "Dist2 3-4-5");
   Check (Near (Dist2 (P (1.0, 1.0), P (1.0, 1.0)), R (0.0)), "Dist2 zero");
   Check (Near (Distance (P (0.0, 0.0), P (3.0, 4.0)), R (5.0), 1.0E-6),
          "Distance 3-4-5");
   Check (Near (Distance (P (1.0, 1.0), P (1.0, 1.0)), R (0.0)),
          "Distance zero");
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
   Section ("2. In_Circumcircle / Circumcenter");
   ------------------------------------------------------------------
   declare
      A : constant Point := P (0.0, 0.0);
      B : constant Point := P (1.0, 0.0);
      C : constant Point := P (0.0, 1.0);
      Inside  : constant Point := P (0.4, 0.4);
      Outside : constant Point := P (2.0, 2.0);
      On_Circ : constant Point := P (1.0, 1.0);
      O : Point;
   begin
      Check (In_Circumcircle (A, B, C, Inside), "inside circumcircle");
      Check (not In_Circumcircle (A, B, C, Outside), "outside circumcircle");
      Check (not In_Circumcircle (A, B, C, On_Circ),
             "on circumcircle not strict-inside");
      Check (not In_Circumcircle (A, B, C, A), "vertex not inside");
      O := Circumcenter (A, B, C);
      Check (Near (O.X, R (0.5), 1.0E-6) and then Near (O.Y, R (0.5), 1.0E-6),
             "circumcenter right triangle");
      Check (Near (Circumradius2 (A, B, C), R (0.5), 1.0E-6),
             "circumradius2 = 0.5");
   end;

   declare
      A : constant Point := P (0.0, 0.0);
      B : constant Point := P (6.0, 0.0);
      C : constant Point := P (0.0, 8.0);
      O : constant Point := Circumcenter (A, B, C);
   begin
      Check (Near (O.X, R (3.0), 1.0E-6), "3-4-5 circumcenter X");
      Check (Near (O.Y, R (4.0), 1.0E-6), "3-4-5 circumcenter Y");
      Check (Near (Circumradius2 (A, B, C), R (25.0), 1.0E-5),
             "3-4-5 circumradius2=25");
   end;

   ------------------------------------------------------------------
   Section ("3. Perpendicular bisector helpers");
   ------------------------------------------------------------------
   declare
      A : constant Point := P (0.0, 0.0);
      B : constant Point := P (4.0, 0.0);
      M : constant Point := Midpoint (A, B);
      D : constant Point := Perpendicular_Direction (A, B);
   begin
      Check (Near (M.X, R (2.0)) and then Near (M.Y, R (0.0)), "midpoint AB");
      Check (Near (D.X, R (0.0), 1.0E-6), "perp dir X ~0 for horizontal");
      Check (Near (abs (D.Y), R (1.0), 1.0E-6), "perp dir |Y|~1");
      Check (On_Perpendicular_Bisector (P (2.0, 5.0), A, B),
             "point on bisector equidistant");
      Check (On_Perpendicular_Bisector (M, A, B), "midpoint on bisector");
      Check (not On_Perpendicular_Bisector (P (0.0, 1.0), A, B, 0.1),
             "off-bisector rejected");
   end;

   declare
      A : constant Point := P (0.0, 0.0);
      B : constant Point := P (0.0, 4.0);
      D : constant Point := Perpendicular_Direction (A, B);
   begin
      Check (Near (abs (D.X), R (1.0), 1.0E-6), "vertical edge perp |X|~1");
      Check (Near (D.Y, R (0.0), 1.0E-6), "vertical edge perp Y~0");
   end;

   ------------------------------------------------------------------
   Section ("4. Bounds_Of / Has_Near_Duplicate");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (1.0, 2.0), P (-3.0, 4.0), P (5.0, -1.0)];
      B : constant Bounding_Box := Bounds_Of (Pts);
      Dup : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0E-12)];
      Clean : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)];
   begin
      Check (Near (B.Min_X, R (-3.0)), "bounds Min_X");
      Check (Near (B.Max_X, R (5.0)), "bounds Max_X");
      Check (Near (B.Min_Y, R (-1.0)), "bounds Min_Y");
      Check (Near (B.Max_Y, R (4.0)), "bounds Max_Y");
      Check (Has_Near_Duplicate (Dup), "detects near-duplicate");
      Check (not Has_Near_Duplicate (Clean), "clean set no dup");
   end;

   ------------------------------------------------------------------
   Section ("5. Invalid_Argument guards");
   ------------------------------------------------------------------
   declare
      Too_Few : constant Point_Array := [P (0.0, 0.0), P (1.0, 0.0)];
      One : constant Point_Array := [P (0.0, 0.0)];
      Dup3 : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 0.0)];
   begin
      Check (Raised_Invalid_Delaunay (Too_Few), "Delaunay reject 2 pts");
      Check (Raised_Invalid_Delaunay (One), "Delaunay reject 1 pt");
      Check (Raised_Invalid_Delaunay (Dup3), "Delaunay reject duplicates");
      Check (Raised_Invalid_Voronoi (Too_Few), "Voronoi reject 2 pts");
      Check (Raised_Invalid_Voronoi (Dup3), "Voronoi reject duplicates");
      Check (Raised_Invalid_Nearest (P (0.0, 0.0),
             Point_Array'(1 .. 0 => <>)), "Nearest reject empty");
   end;

   ------------------------------------------------------------------
   Section ("6. Nearest_Site brute-force membership");
   ------------------------------------------------------------------
   declare
      Sites : constant Point_Array :=
        [P (0.0, 0.0), P (4.0, 0.0), P (0.0, 4.0)];
   begin
      Check (Nearest_Site (P (0.1, 0.1), Sites) = 1, "nearest site 1");
      Check (Nearest_Site (P (3.9, 0.1), Sites) = 2, "nearest site 2");
      Check (Nearest_Site (P (0.1, 3.9), Sites) = 3, "nearest site 3");
      --  Tie at midpoint of 1 and 2 → smallest index wins.
      Check (Nearest_Site (P (2.0, 0.0), Sites) = 1, "tie → smallest index");
      Check (Nearest_Site (P (0.0, 0.0), Sites) = 1, "query at site 1");
   end;

   ------------------------------------------------------------------
   Section ("7. Single triangle Delaunay + Voronoi");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (4.0, 0.0), P (1.0, 3.0)];
      T : constant Triangulation := Delaunay_From_Sites (Pts);
      V : constant Voronoi_Diagram := Build_Voronoi (Pts);
   begin
      Check (Triangle_Count_Of (T) = 1, "3 pts → 1 triangle");
      Check (Is_Delaunay_Empty_Circle (Pts, T), "3 pts Delaunay empty");
      Check (Voronoi_Vertex_Count_Of (V) = 1, "3 pts → 1 Voronoi vertex");
      --  All 3 edges are hull → 3 unbounded rays, 0 bounded.
      Check (Count_Bounded_Edges (V) = 0, "triangle: 0 bounded edges");
      Check (Count_Unbounded_Edges (V) = 3, "triangle: 3 unbounded rays");
      Check (Voronoi_Edge_Count_Of (V) = 3, "triangle: 3 Voronoi edges");
      declare
         Tri : constant Triangle := Get_Triangle (T, 1);
         VV  : constant Voronoi_Vertex := Get_Voronoi_Vertex (V, 1);
         O   : constant Point :=
           Circumcenter (Pts (Tri.A), Pts (Tri.B), Pts (Tri.C));
      begin
         Check (CCW (Pts (Tri.A), Pts (Tri.B), Pts (Tri.C)),
                "result triangle CCW");
         Check (Near_Point (VV.Location, O, 1.0E-6),
                "Voronoi vertex = circumcenter");
      end;
   end;

   ------------------------------------------------------------------
   Section ("8. Unit square: 2 tris, dual Voronoi");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      T : constant Triangulation := Delaunay_From_Sites (Pts);
      V : constant Voronoi_Diagram := Build_Voronoi (Pts);
   begin
      Check (Triangle_Count_Of (T) = 2, "unit square → 2 triangles");
      Check (Is_Delaunay_Empty_Circle (Pts, T), "square Delaunay empty");
      Check (Voronoi_Vertex_Count_Of (V) = 2, "square → 2 Voronoi verts");
      --  Shared diagonal → 1 bounded; 4 hull edges → 4 unbounded.
      Check (Count_Bounded_Edges (V) = 1, "square: 1 bounded dual");
      Check (Count_Unbounded_Edges (V) = 4, "square: 4 unbounded rays");
      Check (Voronoi_Edge_Count_Of (V) = 5, "square: 5 Voronoi edges");
      --  Circumcenters of both tris of unit square lie at (0.5, 0.5).
      declare
         V1 : constant Voronoi_Vertex := Get_Voronoi_Vertex (V, 1);
         V2 : constant Voronoi_Vertex := Get_Voronoi_Vertex (V, 2);
      begin
         Check (Near (V1.Location.X, R (0.5), 1.0E-5)
                  and then Near (V1.Location.Y, R (0.5), 1.0E-5),
                "square Voronoi vert1 ~ center");
         Check (Near (V2.Location.X, R (0.5), 1.0E-5)
                  and then Near (V2.Location.Y, R (0.5), 1.0E-5),
                "square Voronoi vert2 ~ center");
      end;
      --  Cell membership samples.
      Check (Nearest_Site (P (0.1, 0.1), Pts) = 1, "square cell SW");
      Check (Nearest_Site (P (0.9, 0.1), Pts) = 2, "square cell SE");
      Check (Nearest_Site (P (0.9, 0.9), Pts) = 3, "square cell NE");
      Check (Nearest_Site (P (0.1, 0.9), Pts) = 4, "square cell NW");
   end;

   ------------------------------------------------------------------
   Section ("9. Bounded edge lies on perpendicular bisector");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (4.0, 0.0), P (1.0, 3.0), P (2.0, -2.0)];
      V : constant Voronoi_Diagram := Build_Voronoi (Pts);
      OK_Bis : Boolean := True;
      Found_Bounded : Boolean := False;
   begin
      Check (Voronoi_Vertex_Count_Of (V) = 2, "4 pts → 2 Voronoi verts");
      Check (Count_Bounded_Edges (V) = 1, "4 pts: 1 bounded edge");
      for I in 1 .. V.Edge_N loop
         declare
            E : constant Voronoi_Edge := Get_Voronoi_Edge (V, I);
         begin
            if E.Bounded then
               Found_Bounded := True;
               declare
                  A : constant Point := Pts (E.Site_A);
                  B : constant Point := Pts (E.Site_B);
                  C1 : constant Point :=
                    Get_Voronoi_Vertex (V, E.V_From).Location;
                  C2 : constant Point :=
                    Get_Voronoi_Vertex (V, E.V_To).Location;
               begin
                  if not On_Perpendicular_Bisector (C1, A, B, 1.0E-4)
                    or else not On_Perpendicular_Bisector (C2, A, B, 1.0E-4)
                  then
                     OK_Bis := False;
                  end if;
               end;
            end if;
         end;
      end loop;
      Check (Found_Bounded, "found bounded dual edge");
      Check (OK_Bis, "bounded endpoints on site bisector");
   end;

   ------------------------------------------------------------------
   Section ("10. Unbounded ray direction nonzero / bisector");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (4.0, 0.0), P (1.0, 3.0)];
      V : constant Voronoi_Diagram := Build_Voronoi (Pts);
      OK_Dir : Boolean := True;
      OK_Bis : Boolean := True;
   begin
      for I in 1 .. V.Edge_N loop
         declare
            E : constant Voronoi_Edge := Get_Voronoi_Edge (V, I);
         begin
            if not E.Bounded then
               if Near (E.Direction.X, R (0.0))
                 and then Near (E.Direction.Y, R (0.0))
               then
                  OK_Dir := False;
               end if;
               declare
                  C : constant Point :=
                    Get_Voronoi_Vertex (V, E.V_From).Location;
                  --  A point along the ray should stay equidistant.
                  Q : constant Point :=
                    (X => C.X + E.Direction.X,
                     Y => C.Y + E.Direction.Y);
               begin
                  if not On_Perpendicular_Bisector
                    (Q, Pts (E.Site_A), Pts (E.Site_B), 1.0E-4)
                  then
                     OK_Bis := False;
                  end if;
               end;
            end if;
         end;
      end loop;
      Check (OK_Dir, "unbounded ray directions nonzero");
      Check (OK_Bis, "ray samples stay on bisector");
   end;

   ------------------------------------------------------------------
   Section ("11. Convex pentagon + scattered");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (1.0, 0.0),
         P (0.309, 0.951),
         P (-0.809, 0.588),
         P (-0.809, -0.588),
         P (0.309, -0.951)];
      T : constant Triangulation := Delaunay_From_Sites (Pts);
      V : constant Voronoi_Diagram := Build_Voronoi (Pts);
   begin
      Check (Triangle_Count_Of (T) = 3, "convex pentagon → 3 tris");
      Check (Is_Delaunay_Empty_Circle (Pts, T), "pentagon Delaunay empty");
      Check (Voronoi_Vertex_Count_Of (V) = 3, "pentagon → 3 Voronoi verts");
      Check (Count_Unbounded_Edges (V) = 5, "pentagon: 5 hull rays");
      Check (Count_Bounded_Edges (V) = 2, "pentagon: 2 internal duals");
   end;

   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.1), P (1.5, 1.8),
         P (0.2, 1.5), P (3.0, 1.0), P (2.5, 2.5),
         P (0.5, 2.8), P (1.0, 0.9)];
      T : constant Triangulation := Delaunay_From_Sites (Pts);
      V : constant Voronoi_Diagram := Build_Voronoi (Pts);
      N : constant Natural := Pts'Length;
      TC : constant Triangle_Count := Triangle_Count_Of (T);
   begin
      Check (Natural (TC) >= N - 2, "scattered lower triangle bound");
      Check (Is_Delaunay_Empty_Circle (Pts, T), "scattered Delaunay empty");
      Check (Voronoi_Vertex_Count_Of (V) = TC,
             "Voronoi verts = Delaunay tris");
      Check (Count_Unbounded_Edges (V) >= 3, "scattered ≥3 rays");
      Check (Voronoi_Edge_Count_Of (V) > 0, "scattered nonempty edges");
   end;

   ------------------------------------------------------------------
   Section ("12. Grid 2x2 / 3x3 / Voronoi dual counts");
   ------------------------------------------------------------------
   declare
      G2 : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0),
         P (0.0, 1.0), P (1.0, 1.0)];
      T2 : constant Triangulation := Delaunay_From_Sites (G2);
      V2 : constant Voronoi_Diagram := Build_Voronoi (G2);
   begin
      Check (Triangle_Count_Of (T2) = 2, "2x2 grid → 2 tris");
      Check (Voronoi_Vertex_Count_Of (V2) = 2, "2x2 → 2 Voronoi verts");
      Check (Is_Delaunay_Empty_Circle (G2, T2), "2x2 Delaunay");
   end;

   declare
      G3 : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0),
         P (0.0, 1.0), P (1.0, 1.0), P (2.0, 1.0),
         P (0.0, 2.0), P (1.0, 2.0), P (2.0, 2.0)];
      T3 : constant Triangulation := Delaunay_From_Sites (G3);
      V3 : constant Voronoi_Diagram := Build_Voronoi (G3);
   begin
      Check (Triangle_Count_Of (T3) = 8, "3x3 grid → 8 tris");
      Check (Is_Delaunay_Empty_Circle (G3, T3), "3x3 Delaunay");
      Check (Voronoi_Vertex_Count_Of (V3) = 8, "3x3 → 8 Voronoi verts");
      Check (Nearest_Site (P (1.0, 1.0), G3) = 5, "3x3 center site index");
      Check (Nearest_Site (P (0.1, 0.1), G3) = 1, "3x3 corner nearest");
   end;

   ------------------------------------------------------------------
   Section ("13. Quad + interior / Shares_Vertex / constants");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (5.0, 0.0), P (5.0, 4.0),
         P (0.0, 4.0), P (2.5, 2.0)];
      T : constant Triangulation := Delaunay_From_Sites (Pts);
      V : constant Voronoi_Diagram := Build_Voronoi (Pts);
      OK_Idx : Boolean := True;
      OK_CCW : Boolean := True;
   begin
      Check (Triangle_Count_Of (T) = 4, "quad+interior → 4 tris");
      Check (Voronoi_Vertex_Count_Of (V) = 4, "quad+int → 4 Voronoi verts");
      Check (Is_Delaunay_Empty_Circle (Pts, T), "5-pt Delaunay");
      for I in 1 .. T.Count loop
         declare
            Tri : constant Triangle := Get_Triangle (T, I);
         begin
            if Natural (Tri.A) > Pts'Length
              or else Natural (Tri.B) > Pts'Length
              or else Natural (Tri.C) > Pts'Length
              or else Tri.A = Tri.B
              or else Tri.B = Tri.C
              or else Tri.A = Tri.C
            then
               OK_Idx := False;
            end if;
            if not CCW (Pts (Tri.A), Pts (Tri.B), Pts (Tri.C)) then
               OK_CCW := False;
            end if;
         end;
      end loop;
      Check (OK_Idx, "all vertex indices in range");
      Check (OK_CCW, "all result triangles CCW");
      Check (Nearest_Site (P (2.5, 2.0), Pts) = 5, "interior site nearest");
   end;

   declare
      Tri : constant Triangle := (A => 1, B => 2, C => 3);
   begin
      Check (Shares_Vertex (Tri, 1), "shares A");
      Check (Shares_Vertex (Tri, 2), "shares B");
      Check (Shares_Vertex (Tri, 3), "shares C");
      Check (not Shares_Vertex (Tri, 4), "not shares 4");
   end;

   declare
      function MS return Positive is (Max_Sites);
      function MT return Positive is (Max_Triangles);
      function Ep return Real is (Epsilon);
      Empty : Triangulation;
      Empty_V : Voronoi_Diagram;
   begin
      Check (MS = 64, "Max_Sites educational 64");
      Check (MT = 256, "Max_Triangles 256");
      Check (Ep > 0.0, "Epsilon positive");
      Check (Triangle_Count_Of (Empty) = 0, "empty triangulation count 0");
      Check (Voronoi_Vertex_Count_Of (Empty_V) = 0, "empty Voronoi verts 0");
      Check (Voronoi_Edge_Count_Of (Empty_V) = 0, "empty Voronoi edges 0");
   end;

   ------------------------------------------------------------------
   Section ("14. Equilateral-ish / diamond / extra membership");
   ------------------------------------------------------------------
   declare
      A : constant Point := P (-1.0, 0.0);
      B : constant Point := P (1.0, 0.0);
      C : constant Point := P (0.0, 1.0);
      D : constant Point := P (0.0, -1.0);
      Pts : constant Point_Array := [A, B, C, D];
      T : constant Triangulation := Delaunay_From_Sites (Pts);
      V : constant Voronoi_Diagram := Build_Voronoi (Pts);
   begin
      Check (Triangle_Count_Of (T) = 2, "diamond → 2 tris");
      Check (Is_Delaunay_Empty_Circle (Pts, T),
             "diamond cocircular strict-empty ok");
      Check (not In_Circumcircle (A, B, C, D),
             "D on circumcircle of ABC not inside");
      Check (Voronoi_Vertex_Count_Of (V) = 2, "diamond → 2 Voronoi verts");
      Check (Count_Bounded_Edges (V) = 1, "diamond: 1 bounded");
      Check (Count_Unbounded_Edges (V) = 4, "diamond: 4 rays");
   end;

   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.5, 0.866),
         P (0.5, 0.2)];
      T : constant Triangulation := Delaunay_From_Sites (Pts);
      V : constant Voronoi_Diagram := Build_Voronoi (Pts);
   begin
      Check (Triangle_Count_Of (T) = 3, "tri+interior → 3 tris");
      Check (Is_Delaunay_Empty_Circle (Pts, T), "tri+interior Delaunay");
      Check (Voronoi_Vertex_Count_Of (V) = 3, "tri+int → 3 Voronoi verts");
      Check (Count_Unbounded_Edges (V) = 3, "tri+int: 3 hull rays");
      Check (Count_Bounded_Edges (V) = 3, "tri+int: 3 internal duals");
   end;

   ------------------------------------------------------------------
   Section ("15. Build_Voronoi sites stored / edge site indices");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (3.0, 0.0), P (0.0, 3.0), P (3.0, 3.0)];
      V : constant Voronoi_Diagram := Build_Voronoi (Pts);
      OK_Sites : Boolean := True;
      OK_Edge_Sites : Boolean := True;
   begin
      Check (V.Site_N = 4, "diagram stores Site_N=4");
      for I in 1 .. V.Site_N loop
         if not Near_Point (V.Sites (I), Pts (I)) then
            OK_Sites := False;
         end if;
      end loop;
      Check (OK_Sites, "diagram Sites match input");
      for I in 1 .. V.Edge_N loop
         declare
            E : constant Voronoi_Edge := Get_Voronoi_Edge (V, I);
         begin
            if Natural (E.Site_A) > Pts'Length
              or else Natural (E.Site_B) > Pts'Length
              or else E.Site_A = E.Site_B
            then
               OK_Edge_Sites := False;
            end if;
         end;
      end loop;
      Check (OK_Edge_Sites, "edge site indices valid distinct");
      Check (Nearest_Site (P (0.2, 0.2), Pts) = 1, "corner nearest 1");
      Check (Nearest_Site (P (2.8, 2.8), Pts) = 4, "corner nearest 4");
   end;

   ------------------------------------------------------------------
   Ada.Text_IO.New_Line;
   Ada.Text_IO.Put_Line
     ("Result:" & Natural'Image (Pass_Count) & " PASS,"
      & Natural'Image (Fail_Count) & " FAIL");

   if Fail_Count > 0 then
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   else
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   end if;

   pragma Assert (Fail_Count = 0);
end Tests;
