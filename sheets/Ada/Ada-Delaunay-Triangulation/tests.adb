--  Standalone test suite for Delaunay_Triangulation (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Delaunay_Triangulation; use Delaunay_Triangulation;

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

   function Raised_Invalid (Pts : Point_Array) return Boolean is
      T : Triangulation;
   begin
      T := Triangulate (Pts);
      pragma Unreferenced (T);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid;

begin
   Ada.Text_IO.Put_Line ("Delaunay_Triangulation tests");
   Ada.Text_IO.Put_Line ("============================");

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
      B : constant Point := P (2.0, 0.0);
      C : constant Point := P (1.0, 1.73205080757);
      O : constant Point := Circumcenter (A, B, C);
   begin
      Check (Near (O.X, R (1.0), 1.0E-5), "equil circumcenter X");
      Check (In_Circumcircle (A, B, C, P (1.0, 0.5)), "equil inside");
      Check (not In_Circumcircle (A, B, C, P (1.0, 3.0)), "equil outside");
   end;

   ------------------------------------------------------------------
   Section ("3. Bounds_Of / Has_Near_Duplicate");
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
   Section ("4. Invalid_Argument guards");
   ------------------------------------------------------------------
   declare
      Too_Few : constant Point_Array := [P (0.0, 0.0), P (1.0, 0.0)];
      One : constant Point_Array := [P (0.0, 0.0)];
      Dup3 : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 0.0)];
   begin
      Check (Raised_Invalid (Too_Few), "reject 2 points");
      Check (Raised_Invalid (One), "reject 1 point");
      Check (Raised_Invalid (Dup3), "reject duplicates");
   end;

   ------------------------------------------------------------------
   Section ("5. Single triangle (3 sites)");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (4.0, 0.0), P (1.0, 3.0)];
      T : constant Triangulation := Triangulate (Pts);
   begin
      Check (Triangle_Count_Of (T) = 1, "3 pts → 1 triangle");
      Check (Is_Delaunay (Pts, T), "3 pts Is_Delaunay");
      Check (Is_Delaunay_Edge_Empty (Pts, T), "3 pts alias empty");
      declare
         Tri : constant Triangle := Get_Triangle (T, 1);
      begin
         Check (Tri.A in 1 .. 3 and then Tri.B in 1 .. 3
                  and then Tri.C in 1 .. 3,
                "triangle indices in 1..3");
         Check (Tri.A /= Tri.B and then Tri.B /= Tri.C
                  and then Tri.A /= Tri.C,
                "triangle vertices distinct");
         Check (CCW (Pts (Tri.A), Pts (Tri.B), Pts (Tri.C)),
                "result triangle CCW");
      end;
   end;

   ------------------------------------------------------------------
   Section ("6. Convex quad / square (4 sites)");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      T : constant Triangulation := Triangulate (Pts);
   begin
      Check (Triangle_Count_Of (T) = 2, "unit square → 2 triangles");
      Check (Is_Delaunay (Pts, T), "square Is_Delaunay");
   end;

   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (3.0, 0.0), P (1.0, 0.5), P (1.0, -0.5)];
      T : constant Triangulation := Triangulate (Pts);
   begin
      Check (Triangle_Count_Of (T) = 2, "kite → 2 triangles");
      Check (Is_Delaunay (Pts, T), "kite Is_Delaunay");
   end;

   ------------------------------------------------------------------
   Section ("7. Regular pentagon");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (1.0, 0.0),
         P (0.309, 0.951),
         P (-0.809, 0.588),
         P (-0.809, -0.588),
         P (0.309, -0.951)];
      T : constant Triangulation := Triangulate (Pts);
   begin
      Check (Triangle_Count_Of (T) = 3, "convex pentagon → 3 tris");
      Check (Is_Delaunay (Pts, T), "pentagon Is_Delaunay");
   end;

   ------------------------------------------------------------------
   Section ("8. Small grids 2x2 and 3x3");
   ------------------------------------------------------------------
   declare
      G2 : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0),
         P (0.0, 1.0), P (1.0, 1.0)];
      T2 : constant Triangulation := Triangulate (G2);
   begin
      Check (Triangle_Count_Of (T2) = 2, "2x2 grid → 2 tris");
      Check (Is_Delaunay (G2, T2), "2x2 Is_Delaunay");
   end;

   declare
      G3 : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0),
         P (0.0, 1.0), P (1.0, 1.0), P (2.0, 1.0),
         P (0.0, 2.0), P (1.0, 2.0), P (2.0, 2.0)];
      T3 : constant Triangulation := Triangulate (G3);
   begin
      Check (Triangle_Count_Of (T3) = 8, "3x3 grid → 8 tris");
      Check (Is_Delaunay (G3, T3), "3x3 Is_Delaunay");
   end;

   ------------------------------------------------------------------
   Section ("9. Random-ish scattered set");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.1), P (1.5, 1.8),
         P (0.2, 1.5), P (3.0, 1.0), P (2.5, 2.5),
         P (0.5, 2.8), P (1.0, 0.9)];
      T : constant Triangulation := Triangulate (Pts);
      N : constant Natural := Pts'Length;
      H_Min : constant Natural := 3;
      TC : constant Triangle_Count := Triangle_Count_Of (T);
   begin
      Check (Natural (TC) >= N - 2, "scattered lower triangle bound");
      Check (Natural (TC) <= 2 * N - 2 - H_Min,
             "scattered upper triangle bound");
      Check (Is_Delaunay (Pts, T), "scattered Is_Delaunay");
      Check (TC > 0, "scattered nonempty");
   end;

   ------------------------------------------------------------------
   Section ("10. All triangles CCW / valid indices");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (5.0, 0.0), P (5.0, 4.0),
         P (0.0, 4.0), P (2.5, 2.0)];
      T : constant Triangulation := Triangulate (Pts);
      OK_Idx : Boolean := True;
      OK_CCW : Boolean := True;
   begin
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
      Check (Is_Delaunay (Pts, T), "5-pt Is_Delaunay");
      Check (Triangle_Count_Of (T) = 4, "quad+interior → 4 tris");
   end;

   ------------------------------------------------------------------
   Section ("11. Shares_Vertex / Edge_Needs_Flip");
   ------------------------------------------------------------------
   declare
      Tri : constant Triangle := (A => 1, B => 2, C => 3);
   begin
      Check (Shares_Vertex (Tri, 1), "shares A");
      Check (Shares_Vertex (Tri, 2), "shares B");
      Check (Shares_Vertex (Tri, 3), "shares C");
      Check (not Shares_Vertex (Tri, 4), "not shares 4");
   end;

   declare
      --  Right triangle at origin; point deep inside circumcircle ⇒ flip.
      A : constant Point := P (0.0, 0.0);
      B : constant Point := P (1.0, 0.0);
      C : constant Point := P (0.0, 1.0);
      Inside  : constant Point := P (0.4, 0.4);
      Outside : constant Point := P (2.0, 2.0);
   begin
      Check (Edge_Needs_Flip (A, B, C, Inside), "flip needed inside");
      Check (not Edge_Needs_Flip (A, B, C, Outside), "no flip outside");
      Check (not Edge_Needs_Flip (A, B, C, P (1.0, 1.0)),
             "no flip on circumcircle");
   end;

   ------------------------------------------------------------------
   Section ("12. Larger educational set (16 pts circle)");
   ------------------------------------------------------------------
   declare
      Pts : Point_Array (1 .. 16);
      T : Triangulation;
   begin
      Pts :=
        [P (1.000000, 0.000000),
         P (0.923880, 0.382683),
         P (0.707107, 0.707107),
         P (0.382683, 0.923880),
         P (0.000000, 1.000000),
         P (-0.382683, 0.923880),
         P (-0.707107, 0.707107),
         P (-0.923880, 0.382683),
         P (-1.000000, 0.000000),
         P (-0.923880, -0.382683),
         P (-0.707107, -0.707107),
         P (-0.382683, -0.923880),
         P (0.000000, -1.000000),
         P (0.382683, -0.923880),
         P (0.707107, -0.707107),
         P (0.923880, -0.382683)];
      T := Triangulate (Pts);
      Check (Triangle_Count_Of (T) = 14, "16-gon → 14 tris");
      Check (Is_Delaunay (Pts, T), "16-gon Is_Delaunay");
   end;

   ------------------------------------------------------------------
   Section ("13. Constants / empty mesh");
   ------------------------------------------------------------------
   declare
      Empty : Triangulation;
   begin
      Check (Triangle_Count_Of (Empty) = 0, "empty count 0");
      declare
         function MP return Positive is (Max_Points);
         function MT return Positive is (Max_Triangles);
         function Ep return Real is (Epsilon);
      begin
         Check (MP = 64, "Max_Points educational 64");
         Check (MT = 256, "Max_Triangles 256");
         Check (Ep > 0.0, "Epsilon positive");
      end;
   end;

   ------------------------------------------------------------------
   Section ("14. Thin triangle + far point");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (10.0, 0.1), P (5.0, 8.0), P (-2.0, 3.0)];
      T : constant Triangulation := Triangulate (Pts);
   begin
      Check (Triangle_Count_Of (T) = 2, "4 pts general → 2 tris");
      Check (Is_Delaunay (Pts, T), "4 pts Is_Delaunay");
   end;

   ------------------------------------------------------------------
   Section ("15. Cocircular diamond");
   ------------------------------------------------------------------
   declare
      A : constant Point := P (-1.0, 0.0);
      B : constant Point := P (1.0, 0.0);
      C : constant Point := P (0.0, 1.0);
      D : constant Point := P (0.0, -1.0);
      Pts : constant Point_Array := [A, B, C, D];
      T : constant Triangulation := Triangulate (Pts);
   begin
      Check (Triangle_Count_Of (T) = 2, "diamond → 2 tris");
      Check (Is_Delaunay (Pts, T), "diamond cocircular Is_Delaunay");
      Check (not In_Circumcircle (A, B, C, D),
             "D on circumcircle of ABC not inside");
   end;

   ------------------------------------------------------------------
   Section ("16. Extra predicates / grids / clusters");
   ------------------------------------------------------------------
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
      Check (In_Circumcircle (A, B, C, O), "circumcenter inside circle");
      Check (In_Circumcircle (A, B, C, P (3.0, 4.0)),
             "exact center inside");
      Check (In_Circumcircle (A, B, C, P (2.9, 3.9)), "near-center inside");
      Check (not In_Circumcircle (A, B, C, P (10.0, 10.0)), "far outside");
   end;

   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.5, 0.866),
         P (0.5, 0.2)];
      T : constant Triangulation := Triangulate (Pts);
   begin
      Check (Triangle_Count_Of (T) = 3, "tri+interior → 3 tris");
      Check (Is_Delaunay (Pts, T), "tri+interior Is_Delaunay");
   end;

   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0),
         P (0.0, 1.0), P (1.0, 1.0), P (2.0, 1.0)];
      T : constant Triangulation := Triangulate (Pts);
   begin
      Check (Triangle_Count_Of (T) = 4, "2x3 grid → 4 tris");
      Check (Is_Delaunay (Pts, T), "2x3 Is_Delaunay");
   end;

   declare
      Pts : constant Point_Array :=
        [P (-2.0, 0.0), P (2.0, 0.0), P (0.0, 3.0),
         P (0.0, 1.0), P (-1.0, 0.5), P (1.0, 0.5)];
      T : constant Triangulation := Triangulate (Pts);
      TC : constant Triangle_Count := Triangle_Count_Of (T);
   begin
      Check (Natural (TC) >= 4, "cluster lower bound");
      Check (Natural (TC) <= 8, "cluster upper bound");
      Check (Is_Delaunay (Pts, T), "cluster Is_Delaunay");
   end;

   Check (Near (Dist2 (P (-1.0, 2.0), P (2.0, 6.0)), R (25.0)),
          "Dist2 (-1,2)-(2,6)");
   Check (Orient2D (P (1.0, 1.0), P (2.0, 2.0), P (3.0, 3.0)) = R (0.0)
            or else Near (Orient2D (P (1.0, 1.0), P (2.0, 2.0), P (3.0, 3.0)),
                          R (0.0)),
          "colin diagonal Orient~0");
   Check (not Has_Near_Duplicate
            ([P (0.0, 0.0), P (0.0, 1.0), P (1.0, 0.0), P (1.0, 1.0)]),
          "square corners not dups");
   Check (Has_Near_Duplicate
            ([P (0.0, 0.0), P (1.0, 1.0), P (0.0, 0.0)]),
          "exact dup detected");

   declare
      B : constant Bounding_Box :=
        Bounds_Of ([P (7.0, 7.0)]);
   begin
      Check (Near (B.Min_X, R (7.0)) and then Near (B.Max_Y, R (7.0)),
             "singleton bounds");
   end;

   ------------------------------------------------------------------
   Section ("17. Is_Delaunay empty / flip consistency");
   ------------------------------------------------------------------
   declare
      Empty_T : Triangulation;
      Pts3 : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (1.0, 1.5)];
   begin
      Check (Is_Delaunay (Pts3, Empty_T), "empty mesh Is_Delaunay true");
      Check (Is_Delaunay_Edge_Empty (Pts3, Empty_T), "empty alias true");
   end;

   declare
      --  Non-Delaunay pair: long edge of skinny quad should need flip.
      A : constant Point := P (0.0, 0.0);
      B : constant Point := P (4.0, 0.0);
      C : constant Point := P (1.0, 0.3);
      D : constant Point := P (1.0, -0.3);
   begin
      --  Circumcircle of A,B,C likely contains D for this flat kite.
      Check (Edge_Needs_Flip (A, B, C, D),
             "flat kite has illegal long edge");
   end;

   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (3.0, 0.0), P (0.0, 3.0),
         P (3.0, 3.0), P (1.5, 1.5)];
      T : constant Triangulation := Triangulate (Pts);
   begin
      Check (Triangle_Count_Of (T) = 4, "square+center → 4 tris");
      Check (Is_Delaunay (Pts, T), "square+center Is_Delaunay");
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
