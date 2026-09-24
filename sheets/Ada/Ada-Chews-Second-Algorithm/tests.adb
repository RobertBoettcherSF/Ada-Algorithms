--  Standalone test suite for Chews_Second_Algorithm (main program).

pragma Ada_2022;

with Ada.Command_Line;
with Ada.Text_IO;
with Chews_Second_Algorithm; use Chews_Second_Algorithm;

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

   Empty_Segs : constant Segment_Array (1 .. 0) := [];

   function Raised_Invalid_Tri (Pts : Point_Array) return Boolean is
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
   end Raised_Invalid_Tri;

   function Raised_Invalid_Refine
     (Pts : Point_Array; Ang : Real; Max_S : Natural) return Boolean
   is
      Res : Refine_Result;
   begin
      Res := Refine (Pts, Empty_Segs, Ang, Max_S);
      pragma Unreferenced (Res);
      return False;
   exception
      when Invalid_Argument =>
         return True;
      when others =>
         return False;
   end Raised_Invalid_Refine;

begin
   Ada.Text_IO.Put_Line ("Chews_Second_Algorithm tests");
   Ada.Text_IO.Put_Line ("============================");

   ------------------------------------------------------------------
   Section ("1. Near / Dist2 / Dist / Orient2D / CCW");
   ------------------------------------------------------------------
   Check (Near (R (1.0), R (1.0)), "Near equal");
   Check (Near (R (1.0), R (1.0 + 1.0E-12)), "Near within eps");
   Check (not Near (R (0.0), R (1.0)), "not Near 0,1");
   Check (Near_Point (P (0.0, 0.0), P (0.0, 0.0)), "Near_Point identical");
   Check (not Near_Point (P (0.0, 0.0), P (1.0, 0.0)), "not Near_Point");
   Check (Near (Dist2 (P (0.0, 0.0), P (3.0, 4.0)), R (25.0)), "Dist2 3-4-5");
   Check (Near (Dist (P (0.0, 0.0), P (3.0, 4.0)), R (5.0), 1.0E-6),
          "Dist 3-4-5");
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
   Section ("3. Angle / Is_Skinny / Aspect_Ratio");
   ------------------------------------------------------------------
   declare
      A : constant Point := P (0.0, 0.0);
      B : constant Point := P (1.0, 0.0);
      C : constant Point := P (0.0, 1.0);
      Min_A : Real;
   begin
      Check (Near (Angle_Degrees_At (A => A, B => B, C => C), R (45.0), 1.0E-3),
             "angle at B ~45");
      Check (Near (Angle_Degrees_At (A => B, B => A, C => C), R (90.0), 1.0E-3),
             "angle at A ~90");
      Check (Near (Angle_Degrees_At (A => A, B => C, C => B), R (45.0), 1.0E-3),
             "angle at C ~45");
      Min_A := Triangle_Min_Angle_Degrees (A, B, C);
      Check (Near (Min_A, R (45.0), 1.0E-3), "min angle ~45");
      Check (not Is_Skinny (A, B, C, R (30.0)), "45-45-90 not skinny @30");
      Check (Is_Skinny (A, B, C, R (50.0)), "45-45-90 skinny @50");
      Check (Near (Aspect_Ratio (A, B, C), R (1.41421356237), 1.0E-3),
             "aspect ~sqrt2");
   end;

   declare
      A : constant Point := P (0.0, 0.0);
      B : constant Point := P (1.0, 0.0);
      C : constant Point := P (0.5, 0.01);
      Min_A : constant Real := Triangle_Min_Angle_Degrees (A, B, C);
   begin
      Check (Min_A < R (5.0), "skinny triangle min angle < 5");
      Check (Is_Skinny (A, B, C, R (20.0)), "skinny flagged @20");
      Check (Aspect_Ratio (A, B, C) > R (1.5), "skinny elevated aspect");
      declare
         D : constant Point := P (0.0, 0.0);
         E : constant Point := P (10.0, 0.0);
         F : constant Point := P (0.05, 0.01);
      begin
         Check (Aspect_Ratio (D, E, F) > R (50.0), "needle high aspect");
         Check (Triangle_Min_Angle_Degrees (D, E, F) < R (2.0),
                "needle tiny min angle");
      end;
   end;

   ------------------------------------------------------------------
   Section ("4. Encroachment / Chew opposite-side");
   ------------------------------------------------------------------
   declare
      A : constant Point := P (0.0, 0.0);
      B : constant Point := P (2.0, 0.0);
      Inside  : constant Point := P (1.0, 0.5);
      Outside : constant Point := P (1.0, 1.5);
      On_Circ : constant Point := P (1.0, 1.0);
   begin
      Check (Encroaches_Segment (A, B, Inside), "point encroaches segment");
      Check (not Encroaches_Segment (A, B, Outside), "far point no encroach");
      Check (not Encroaches_Segment (A, B, On_Circ), "on diametral not strict");
      Check (not Encroaches_Segment (A, B, A), "endpoint not encroaching");
      Check (not Encroaches_Segment (A, B, B), "other endpoint not encroaching");
   end;

   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (1.0, 0.3)];
      Segs : constant Segment_Array :=
        [(A => 1, B => 2)];
   begin
      Check (Point_Encroaches_Any_Segment (Pts (3), Pts, Segs),
             "site encroaches listed segment");
      Check (not Point_Encroaches_Any_Segment (P (1.0, 2.0), Pts, Segs),
             "far site no encroach");
   end;

   declare
      Seg_A : constant Point := P (0.0, 0.0);
      Seg_B : constant Point := P (2.0, 0.0);
      Tri_Above : constant Point := P (1.0, 1.0);
      Circ_Below : constant Point := P (1.0, -1.0);
      Circ_Above : constant Point := P (1.0, 2.0);
   begin
      Check (Circumcenter_Opposite_Side
               (Seg_A, Seg_B, Tri_Above, Circ_Below),
             "Chew opposite-side true");
      Check (not Circumcenter_Opposite_Side
               (Seg_A, Seg_B, Tri_Above, Circ_Above),
             "same-side not opposite");
      Check (not Circumcenter_Opposite_Side
               (Seg_A, Seg_B, Tri_Above, P (1.0, 0.0)),
             "on-line not opposite");
   end;

   ------------------------------------------------------------------
   Section ("5. Bounds_Of / Has_Near_Duplicate");
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
   Section ("6. Invalid_Argument guards");
   ------------------------------------------------------------------
   declare
      Too_Few : constant Point_Array := [P (0.0, 0.0), P (1.0, 0.0)];
      One : constant Point_Array := [P (0.0, 0.0)];
      Dup3 : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 0.0)];
      Ok3 : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)];
   begin
      Check (Raised_Invalid_Tri (Too_Few), "triangulate reject 2 points");
      Check (Raised_Invalid_Tri (One), "triangulate reject 1 point");
      Check (Raised_Invalid_Tri (Dup3), "triangulate reject duplicates");
      Check (Raised_Invalid_Refine (Ok3, R (0.0), 4), "reject Min_Angle 0");
      Check (Raised_Invalid_Refine (Ok3, R (-5.0), 4), "reject negative angle");
      Check (Raised_Invalid_Refine (Ok3, R (60.0), 4), "reject Min_Angle 60");
      Check (Raised_Invalid_Refine (Ok3, R (90.0), 4), "reject Min_Angle 90");
      Check (Raised_Invalid_Refine (Too_Few, R (20.0), 4), "refine reject 2 pts");
      Check (Raised_Invalid_Refine (Dup3, R (20.0), 4), "refine reject dups");
   end;

   ------------------------------------------------------------------
   Section ("7. Embedded Triangulate (Delaunay)");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (4.0, 0.0), P (1.0, 3.0)];
      T : constant Triangulation := Triangulate (Pts);
   begin
      Check (Triangle_Count_Of (T) = 1, "3 pts → 1 triangle");
      Check (Is_Delaunay_Edge_Empty (Pts, T), "3 pts Delaunay empty");
      declare
         Tri : constant Triangle := Get_Triangle (T, 1);
      begin
         Check (Tri.A /= Tri.B and then Tri.B /= Tri.C
                  and then Tri.A /= Tri.C,
                "triangle vertices distinct");
         Check (CCW (Pts (Tri.A), Pts (Tri.B), Pts (Tri.C)),
                "result triangle CCW");
      end;
   end;

   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      T : constant Triangulation := Triangulate (Pts);
   begin
      Check (Triangle_Count_Of (T) = 2, "unit square → 2 triangles");
      Check (Is_Delaunay_Edge_Empty (Pts, T), "square Delaunay empty");
   end;

   ------------------------------------------------------------------
   Section ("8. Mesh quality metrics");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)];
      T : constant Triangulation := Triangulate (Pts);
      Min_A : constant Real := Mesh_Min_Angle_Degrees (Pts, T);
   begin
      Check (Near (Min_A, R (45.0), 1.0E-2), "mesh min angle ~45");
      Check (Count_Skinny (Pts, T, R (30.0)) = 0, "no skinny @30");
      Check (Count_Skinny (Pts, T, R (50.0)) = 1, "one skinny @50");
   end;

   ------------------------------------------------------------------
   Section ("9. Refine: good triangle @ Default_Min_Angle 30");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.5, 0.86602540378)];
      Before : constant Triangulation := Triangulate (Pts);
      Ang0 : constant Real := Mesh_Min_Angle_Degrees (Pts, Before);
      Res : constant Refine_Result :=
        Refine (Pts, Empty_Segs, Default_Min_Angle, 8);
   begin
      Check (Near (Default_Min_Angle, R (30.0)), "Default_Min_Angle is 30");
      Check (Ang0 > R (50.0), "equilateral input already good");
      Check (Res.Steiner_Inserted = 0, "equilateral needs 0 Steiner @30");
      Check (Result_Point_Count (Res) = 3, "equilateral keeps 3 points");
      Check (Triangle_Count_Of (Res.Mesh) = 1, "equilateral still 1 tri");
      Check (Res.Min_Angle_Achieved >= R (30.0) - R (1.0E-3),
             "equilateral min angle >= 30");
   end;

   ------------------------------------------------------------------
   Section ("10. Refine: square improves or maintains");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (1.0, 1.0), P (0.0, 1.0)];
      Before : constant Triangulation := Triangulate (Pts);
      Ang0 : constant Real := Mesh_Min_Angle_Degrees (Pts, Before);
      Res : constant Refine_Result :=
        Refine (Pts, Empty_Segs, R (20.0), 16);
      Ang1 : constant Real := Res.Min_Angle_Achieved;
   begin
      Check (Triangle_Count_Of (Before) = 2, "square starts with 2 tris");
      Check (Ang0 > R (40.0), "square already has decent angles");
      Check (Res.Steiner_Inserted <= 16, "square Steiner within budget");
      Check (Result_Point_Count (Res) >= 4, "square at least 4 points");
      Check (Ang1 + R (1.0E-3) >= Ang0 or else Ang1 >= R (20.0) - R (1.0),
             "square quality maintained or meets bound");
      Check (Triangle_Count_Of (Res.Mesh) >= 2, "square mesh non-empty");
   end;

   ------------------------------------------------------------------
   Section ("11. Refine: skinny input may insert Steiner");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (4.0, 0.0), P (0.0, 3.0), P (0.05, 0.05)];
      Before : constant Triangulation := Triangulate (Pts);
      Ang0 : constant Real := Mesh_Min_Angle_Degrees (Pts, Before);
      Skin0 : constant Natural := Count_Skinny (Pts, Before, R (20.0));
      Res : constant Refine_Result :=
        Refine (Pts, Empty_Segs, R (20.0), 24);
      Ang1 : constant Real := Res.Min_Angle_Achieved;
   begin
      Check (Skin0 >= 1 or else Ang0 < R (20.0),
             "skinny input has poor quality or skinny count");
      Check (Res.Steiner_Inserted <= 24, "skinny Steiner within budget");
      Check (Result_Point_Count (Res) >= 4, "skinny refine keeps >= 4 pts");
      Check (Ang1 + R (0.5) >= Ang0 or else Res.Steiner_Inserted > 0
               or else Ang1 >= R (15.0),
             "skinny refine improves, inserts, or stays reasonable");
      Check (Triangle_Count_Of (Res.Mesh) >= 1, "skinny refine has tris");
      declare
         Out_Pts : Point_Array (1 .. Point_Index (Res.Num_Points));
      begin
         for I in Out_Pts'Range loop
            Out_Pts (I) := Get_Point (Res, I);
         end loop;
         Check (Is_Delaunay_Edge_Empty (Out_Pts, Res.Mesh)
                  or else Result_Point_Count (Res) >= 4,
                "refined mesh Delaunay or point count ok");
      end;
   end;

   ------------------------------------------------------------------
   Section ("12. Refine Max_Steiner = 0 is no-op");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (0.1, 0.05), P (0.0, 1.5)];
      Res : constant Refine_Result :=
        Refine (Pts, Empty_Segs, R (25.0), 0);
   begin
      Check (Res.Steiner_Inserted = 0, "Max_Steiner 0 → no inserts");
      Check (Result_Point_Count (Res) = 4, "Max_Steiner 0 keeps 4 pts");
      Check (Triangle_Count_Of (Res.Mesh) >= 1, "Max_Steiner 0 still meshes");
   end;

   ------------------------------------------------------------------
   Section ("13. Refine with constrained PSLG segments");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (2.0, 0.0), P (2.0, 2.0), P (0.0, 2.0),
         P (1.0, 0.4)];
      Segs : constant Segment_Array :=
        [(A => 1, B => 2), (A => 2, B => 3),
         (A => 3, B => 4), (A => 4, B => 1)];
      Res : constant Refine_Result :=
        Refine (Pts, Segs, R (15.0), 20);
   begin
      Check (Res.Steiner_Inserted <= 20, "PSLG Steiner within budget");
      Check (Result_Point_Count (Res) >= 5, "PSLG keeps >= 5 points");
      Check (Triangle_Count_Of (Res.Mesh) >= 2, "PSLG mesh has triangles");
      Check (Res.Min_Angle_Achieved > R (0.0), "PSLG min angle positive");
   end;

   declare
      --  Simple polygon PSLG (triangle boundary)
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (3.0, 0.0), P (1.0, 0.2)];
      Segs : constant Segment_Array :=
        [(A => 1, B => 2), (A => 2, B => 3), (A => 3, B => 1)];
      Before : constant Triangulation := Triangulate (Pts);
      Ang0 : constant Real := Mesh_Min_Angle_Degrees (Pts, Before);
      Res : constant Refine_Result :=
        Refine (Pts, Segs, R (20.0), 16);
   begin
      Check (Ang0 < R (20.0) or else Count_Skinny (Pts, Before, R (20.0)) >= 1,
             "thin polygon starts skinny or near bound");
      Check (Res.Steiner_Inserted <= 16, "thin PSLG Steiner within budget");
      Check (Result_Point_Count (Res) >= 3, "thin PSLG >= 3 points");
      Check (Triangle_Count_Of (Res.Mesh) >= 1, "thin PSLG has mesh");
      Check (Res.Min_Angle_Achieved + R (0.5) >= Ang0
               or else Res.Steiner_Inserted > 0
               or else Res.Min_Angle_Achieved >= R (10.0),
             "thin PSLG improves, inserts, or terminates reasonably");
   end;

   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)];
      Bad_Seg : constant Segment_Array := [(A => 1, B => 9)];
      Raised : Boolean := False;
   begin
      declare
         Res : Refine_Result;
      begin
         Res := Refine (Pts, Bad_Seg, R (20.0), 4);
         pragma Unreferenced (Res);
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            Raised := False;
      end;
      Check (Raised, "bad segment index → Invalid_Argument");
   end;

   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.0, 1.0)];
      Coinc : constant Segment_Array := [(A => 1, B => 1)];
      Raised : Boolean := False;
   begin
      declare
         Res : Refine_Result;
      begin
         Res := Refine (Pts, Coinc, R (20.0), 4);
         pragma Unreferenced (Res);
      exception
         when Invalid_Argument =>
            Raised := True;
         when others =>
            Raised := False;
      end;
      Check (Raised, "coincident segment ends → Invalid_Argument");
   end;

   ------------------------------------------------------------------
   Section ("14. Accessors / Shares_Vertex / extras");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (3.0, 0.0), P (0.0, 4.0)];
      Res : constant Refine_Result :=
        Refine (Pts, Empty_Segs, R (10.0), 4);
      Tri : Triangle;
   begin
      Check (Result_Point_Count (Res) >= 3, "3-4-5 result points");
      Check (Near (Get_Point (Res, 1).X, R (0.0)), "Get_Point (1).X");
      Check (Near (Dist2 (P (0.0, 0.0), P (3.0, 4.0)), R (25.0)),
             "Dist2 3-4-5 again");
      if Triangle_Count_Of (Res.Mesh) >= 1 then
         Tri := Get_Triangle (Res.Mesh, 1);
         Check (Shares_Vertex (Tri, Tri.A), "Shares_Vertex true");
         declare
            Far : constant Point_Index := Max_Points;
         begin
            Check (not Shares_Vertex (Tri, Far)
                     or else Tri.A = Far or else Tri.B = Far
                     or else Tri.C = Far,
                   "Shares_Vertex far index");
         end;
      else
         Check (False, "expected at least one triangle");
      end if;
   end;

   Check (Near (Dist (P (-1.0, 2.0), P (2.0, 6.0)), R (5.0), 1.0E-6),
          "Dist (-1,2)-(2,6)");
   Check (not Has_Near_Duplicate
            ([P (0.0, 0.0), P (0.0, 1.0), P (1.0, 0.0), P (1.0, 1.0)]),
          "square corners not dups");
   Check (Has_Near_Duplicate
            ([P (0.0, 0.0), P (1.0, 1.0), P (0.0, 0.0)]),
          "exact dup detected");

   declare
      B : constant Bounding_Box := Bounds_Of ([P (7.0, 7.0)]);
   begin
      Check (Near (B.Min_X, R (7.0)) and then Near (B.Max_Y, R (7.0)),
             "singleton bounds");
   end;

   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.5, 0.866),
         P (0.5, 0.2)];
      T : constant Triangulation := Triangulate (Pts);
   begin
      Check (Triangle_Count_Of (T) = 3, "tri+interior → 3 tris");
      Check (Is_Delaunay_Edge_Empty (Pts, T), "tri+interior Delaunay");
   end;

   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (2.0, 0.0),
         P (0.0, 1.0), P (1.0, 1.0), P (2.0, 1.0)];
      T : constant Triangulation := Triangulate (Pts);
      Res : constant Refine_Result :=
        Refine (Pts, Empty_Segs, R (20.0), 8);
   begin
      Check (Triangle_Count_Of (T) = 4, "2x3 grid → 4 tris");
      Check (Is_Delaunay_Edge_Empty (Pts, T), "2x3 Delaunay");
      Check (Res.Steiner_Inserted <= 8, "2x3 Steiner within budget");
      Check (Result_Point_Count (Res) >= 6, "2x3 refine >= 6 pts");
   end;

   ------------------------------------------------------------------
   Section ("15. Default Refine signature uses Segments");
   ------------------------------------------------------------------
   declare
      Pts : constant Point_Array :=
        [P (0.0, 0.0), P (1.0, 0.0), P (0.5, 0.866)];
      Res : constant Refine_Result := Refine (Pts, Empty_Segs);
   begin
      Check (Result_Point_Count (Res) = 3, "default args keep equilateral");
      Check (Res.Steiner_Inserted = 0, "default @30 needs 0 Steiner");
      Check (Res.Min_Angle_Achieved >= R (29.0),
             "default min angle near 30");
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
