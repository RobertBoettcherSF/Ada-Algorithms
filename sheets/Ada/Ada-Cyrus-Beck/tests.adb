--  Standalone test suite for Cyrus_Beck (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Cyrus_Beck; use Cyrus_Beck;

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
         Put_Line ("  PASS: " & Message);
      else
         Fail_Count := Fail_Count + 1;
         Put_Line ("  FAIL: " & Message);
      end if;
   end Check;

   procedure Section (Title : String) is
   begin
      New_Line;
      Put_Line ("=== " & Title & " ===");
   end Section;

   function Approx (A, B : Real; Tol : Real := 1.0E-4) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Approx_Vec (A, B : Vec2; Tol : Real := 1.0E-3) return Boolean is
   begin
      return Approx (A.X, B.X, Tol) and then Approx (A.Y, B.Y, Tol);
   end Approx_Vec;

   function Approx_Vec3 (A, B : Vec3; Tol : Real := 1.0E-3) return Boolean is
   begin
      return Approx (A.X, B.X, Tol)
        and then Approx (A.Y, B.Y, Tol)
        and then Approx (A.Z, B.Z, Tol);
   end Approx_Vec3;

   function Status_Agree (A, B : Clip_Result) return Boolean is
   begin
      if A.Status /= B.Status then
         return False;
      end if;
      if A.Status = Clip_Reject then
         return True;
      end if;
      return Same_Clipped_Segment (A.Clipped, B.Clipped, 1.0E-3);
   end Status_Agree;

begin
   Put_Line ("Cyrus_Beck test suite");
   Put_Line ("=====================");

   ---------------------------------------------------------------------
   Section ("1. Vector helpers / Near / Dot / Cross_Z");
   ---------------------------------------------------------------------
   declare
      A : constant Vec2 := (3.0, 4.0);
      B : constant Vec2 := (0.0, 0.0);
      S : constant Vec2 := A + (1.0, 1.0);
      D : constant Vec2 := A - (1.0, 1.0);
      M : constant Vec2 := 2.0 * (1.0, 2.0);
   begin
      Check (Near (1.0, 1.0 + 1.0E-6), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Approx_Vec (S, (4.0, 5.0)), "vector +");
      Check (Approx_Vec (D, (2.0, 3.0)), "vector -");
      Check (Approx_Vec (M, (2.0, 4.0)), "scalar *");
      Check (Approx (Dot ((1.0, 0.0), (0.0, 1.0)), 0.0), "Dot orthogonal");
      Check (Approx (Cross_Z ((1.0, 0.0), (0.0, 1.0)), 1.0), "Cross_Z CCW");
      Check (Near_Point (A, A), "Near_Point identical");
      Check (not Near_Point (A, B), "Near_Point distinct");
   end;

   ---------------------------------------------------------------------
   Section ("2. Make_Segment / Length / Point_Inside_Convex");
   ---------------------------------------------------------------------
   declare
      Poly : constant Convex_Clip_Polygon :=
        Make_Convex_Rect (0.0, 0.0, 10.0, 10.0);
      S : constant Segment := Make_Segment ((0.0, 0.0), (3.0, 4.0));
   begin
      Check (Approx_Vec (S.P0, (0.0, 0.0)), "Make_Segment P0");
      Check (Approx_Vec (S.P1, (3.0, 4.0)), "Make_Segment P1");
      Check (Approx (Length (S), 5.0), "Length 3-4-5");
      Check (Point_Inside_Convex ((5.0, 5.0), Poly), "center inside");
      Check (Point_Inside_Convex ((0.0, 0.0), Poly), "corner counts inside");
      Check (not Point_Inside_Convex ((-1.0, 5.0), Poly), "outside left");
   end;

   ---------------------------------------------------------------------
   Section ("3. Make_Convex_Rect / Is_Convex_Polygon / Edge_Normal");
   ---------------------------------------------------------------------
   declare
      R : constant Convex_Clip_Polygon :=
        Make_Convex_Rect (0.0, 0.0, 4.0, 2.0);
      N1 : constant Vec2 := Edge_Normal (R, 1);  -- bottom edge → outward down
      N2 : constant Vec2 := Edge_Normal (R, 2);  -- right edge → outward right
      Bad : Convex_Clip_Polygon;
      Raised : Boolean := False;
   begin
      Check (R.Count = 4, "rect has 4 vertices");
      Check (Is_Convex_Polygon (R), "rect is CCW convex");
      Check (Approx_Vec (R.V (1), (0.0, 0.0)), "BL vertex");
      Check (Approx (N1.Y, -1.0) and then Approx (N1.X, 0.0),
             "bottom outward normal (0,-1)");
      Check (Approx (N2.X, 1.0) and then Approx (N2.Y, 0.0),
             "right outward normal (1,0)");
      Bad.Count := 3;
      Bad.V (1) := (0.0, 0.0);
      Bad.V (2) := (1.0, 0.0);
      Bad.V (3) := (0.5, -1.0);  -- CW triangle
      Check (not Is_Convex_Polygon (Bad), "CW triangle rejected");
      begin
         declare
            Unused : Convex_Clip_Polygon;
            Verts  : Vertex_Array := [others => (0.0, 0.0)];
         begin
            Verts (1) := (0.0, 0.0);
            Verts (2) := (1.0, 0.0);
            Verts (3) := (0.5, -1.0);
            Unused := Make_Convex_Polygon (Verts, 3);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
      end;
      Check (Raised, "Make_Convex_Polygon CW raises");
   end;

   ---------------------------------------------------------------------
   Section ("4. Plane_Dot_Classification");
   ---------------------------------------------------------------------
   declare
      Poly : constant Convex_Clip_Polygon :=
        Make_Convex_Rect (0.0, 0.0, 10.0, 10.0);
      --  Edge 1 = bottom (outward down): inside is above
   begin
      Check (Plane_Dot_Classification ((5.0, 5.0), Poly, 1) = Dot_Inside,
             "center vs bottom = Inside");
      Check (Plane_Dot_Classification ((5.0, 0.0), Poly, 1) = Dot_On_Plane,
             "on bottom edge = On_Plane");
      Check (Plane_Dot_Classification ((5.0, -1.0), Poly, 1) = Dot_Outside,
             "below bottom = Outside");
      Check (Plane_Dot_Classification ((15.0, 5.0), Poly, 2) = Dot_Outside,
             "right of right edge = Outside");
   end;

   ---------------------------------------------------------------------
   Section ("5. Point_At_Parameter");
   ---------------------------------------------------------------------
   declare
      S : constant Segment := Make_Segment ((0.0, 0.0), (10.0, 20.0));
      M : constant Vec2 := Point_At_Parameter (S, 0.5);
      A : constant Vec2 := Point_At_Parameter (S, 0.0);
      B : constant Vec2 := Point_At_Parameter (S, 1.0);
   begin
      Check (Approx_Vec (A, (0.0, 0.0)), "t=0 is P0");
      Check (Approx_Vec (B, (10.0, 20.0)), "t=1 is P1");
      Check (Approx_Vec (M, (5.0, 10.0)), "t=0.5 midpoint");
   end;

   ---------------------------------------------------------------------
   Section ("6. Cyrus_Beck_Clip fully inside");
   ---------------------------------------------------------------------
   declare
      Poly : constant Convex_Clip_Polygon :=
        Make_Convex_Rect (0.0, 0.0, 10.0, 10.0);
      S : constant Segment := Make_Segment ((1.0, 2.0), (3.0, 4.0));
      R : constant Clip_Result := Cyrus_Beck_Clip (S, Poly);
   begin
      Check (R.Status = Clip_Accept, "fully inside Accept");
      Check (Approx_Vec (R.Clipped.P0, S.P0), "inside P0 unchanged");
      Check (Approx_Vec (R.Clipped.P1, S.P1), "inside P1 unchanged");
      Check (Point_Inside_Convex (R.Clipped.P0, Poly), "clipped P0 inside");
      Check (Point_Inside_Convex (R.Clipped.P1, Poly), "clipped P1 inside");
   end;

   ---------------------------------------------------------------------
   Section ("7. Cyrus_Beck_Clip fully outside / edge crossings");
   ---------------------------------------------------------------------
   declare
      Poly : constant Convex_Clip_Polygon :=
        Make_Convex_Rect (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
   begin
      R := Cyrus_Beck_Clip (Make_Segment ((-5.0, 5.0), (-1.0, 5.0)), Poly);
      Check (R.Status = Clip_Reject, "fully left Reject");

      R := Cyrus_Beck_Clip (Make_Segment ((-5.0, 5.0), (15.0, 5.0)), Poly);
      Check (R.Status = Clip_Accept, "horizontal through Accept");
      Check (Approx_Vec (R.Clipped.P0, (0.0, 5.0), 1.0E-2),
             "enter at left x=0");
      Check (Approx_Vec (R.Clipped.P1, (10.0, 5.0), 1.0E-2),
             "leave at right x=10");

      R := Cyrus_Beck_Clip (Make_Segment ((5.0, -5.0), (5.0, 15.0)), Poly);
      Check (R.Status = Clip_Accept, "vertical through Accept");
      Check (Approx_Vec (R.Clipped.P0, (5.0, 0.0), 1.0E-2),
             "enter at bottom y=0");
      Check (Approx_Vec (R.Clipped.P1, (5.0, 10.0), 1.0E-2),
             "leave at top y=10");

      R := Cyrus_Beck_Clip (Make_Segment ((-2.0, -2.0), (12.0, 12.0)), Poly);
      Check (R.Status = Clip_Accept, "diagonal through Accept");
      Check (Point_Inside_Convex (R.Clipped.P0, Poly), "diag P0 inside");
      Check (Point_Inside_Convex (R.Clipped.P1, Poly), "diag P1 inside");
   end;

   ---------------------------------------------------------------------
   Section ("8. Cyrus_Beck_Clip_Params retained t0/t1");
   ---------------------------------------------------------------------
   declare
      Poly : constant Convex_Clip_Polygon :=
        Make_Convex_Rect (0.0, 0.0, 10.0, 10.0);
      S : constant Segment := Make_Segment ((-5.0, 5.0), (15.0, 5.0));
      --  Δx=20; enter at x=0 ⇒ t=5/20=0.25; leave at x=10 ⇒ t=15/20=0.75
      P : constant Clip_Params_Result := Cyrus_Beck_Clip_Params (S, Poly);
   begin
      Check (P.Status = Clip_Accept, "params Accept");
      Check (Approx (P.T0, 0.25), "t_enter = 0.25");
      Check (Approx (P.T1, 0.75), "t_leave = 0.75");
      Check (Approx_Vec (P.Clipped.P0, (0.0, 5.0), 1.0E-2), "params P0");
      Check (Approx_Vec (P.Clipped.P1, (10.0, 5.0), 1.0E-2), "params P1");
   end;

   ---------------------------------------------------------------------
   Section ("9. Triangle clip window");
   ---------------------------------------------------------------------
   declare
      Verts : Vertex_Array := [others => (0.0, 0.0)];
      Tri   : Convex_Clip_Polygon;
      R     : Clip_Result;
   begin
      --  CCW triangle: (0,0), (10,0), (5,8)
      Verts (1) := (0.0, 0.0);
      Verts (2) := (10.0, 0.0);
      Verts (3) := (5.0, 8.0);
      Tri := Make_Convex_Polygon (Verts, 3);
      Check (Is_Convex_Polygon (Tri), "triangle is convex");
      Check (Point_Inside_Convex ((5.0, 2.0), Tri), "centroid-ish inside");
      Check (not Point_Inside_Convex ((5.0, 9.0), Tri), "above apex outside");

      R := Cyrus_Beck_Clip (Make_Segment ((5.0, 1.0), (5.0, 3.0)), Tri);
      Check (R.Status = Clip_Accept, "segment inside triangle Accept");
      Check (Approx_Vec (R.Clipped.P0, (5.0, 1.0)), "tri inside P0");
      Check (Approx_Vec (R.Clipped.P1, (5.0, 3.0)), "tri inside P1");

      R := Cyrus_Beck_Clip (Make_Segment ((5.0, -2.0), (5.0, 10.0)), Tri);
      Check (R.Status = Clip_Accept, "vertical through triangle Accept");
      Check (Point_Inside_Convex (R.Clipped.P0, Tri), "tri clip P0 inside");
      Check (Point_Inside_Convex (R.Clipped.P1, Tri), "tri clip P1 inside");

      R := Cyrus_Beck_Clip (Make_Segment ((-5.0, 5.0), (-1.0, 5.0)), Tri);
      Check (R.Status = Clip_Reject, "left of triangle Reject");
   end;

   ---------------------------------------------------------------------
   Section ("10. Cyrus_Beck_Clip_Rect agrees with Liang_Barsky_Clip_Lite");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      type Seg_List is array (Positive range <>) of Segment;
      Segs : constant Seg_List :=
        [Make_Segment ((1.0, 1.0), (2.0, 2.0)),
         Make_Segment ((-5.0, 5.0), (-1.0, 5.0)),
         Make_Segment ((-2.0, 5.0), (12.0, 5.0)),
         Make_Segment ((5.0, -3.0), (5.0, 13.0)),
         Make_Segment ((-2.0, -2.0), (12.0, 12.0)),
         Make_Segment ((0.0, 0.0), (10.0, 10.0)),
         Make_Segment ((11.0, 0.0), (11.0, 10.0)),
         Make_Segment ((-1.0, 11.0), (11.0, 11.0))];
      CB, LB : Clip_Result;
      All_Ok : Boolean := True;
   begin
      for I in Segs'Range loop
         CB := Cyrus_Beck_Clip_Rect (Segs (I), W);
         LB := Liang_Barsky_Clip_Lite (Segs (I), W);
         if not Status_Agree (CB, LB) then
            All_Ok := False;
            Put_Line ("  mismatch at segment index" & I'Image);
         end if;
      end loop;
      Check (All_Ok, "CB_Rect agrees with LB_Lite on lattice");
      Check (Is_Valid_Window (W), "window valid");
      declare
         One : constant Clip_Result :=
           Cyrus_Beck_Clip_Rect (Make_Segment ((-1.0, 5.0), (11.0, 5.0)), W);
      begin
         Check (One.Status = Clip_Accept, "CB_Rect through Accept");
         Check (Approx_Vec (One.Clipped.P0, (0.0, 5.0), 1.0E-2),
                "CB_Rect enter");
         Check (Approx_Vec (One.Clipped.P1, (10.0, 5.0), 1.0E-2),
                "CB_Rect leave");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("11. Liang_Barsky_Clip_Lite reference cases");
   ---------------------------------------------------------------------
   declare
      W : constant Clip_Window := Make_Window (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
   begin
      R := Liang_Barsky_Clip_Lite (Make_Segment ((2.0, 2.0), (8.0, 8.0)), W);
      Check (R.Status = Clip_Accept, "LB inside Accept");
      Check (Approx_Vec (R.Clipped.P0, (2.0, 2.0)), "LB inside P0");
      Check (Approx_Vec (R.Clipped.P1, (8.0, 8.0)), "LB inside P1");
      R := Liang_Barsky_Clip_Lite (Make_Segment ((-3.0, -3.0), (-1.0, -1.0)), W);
      Check (R.Status = Clip_Reject, "LB outside Reject");
      R := Liang_Barsky_Clip_Lite (Make_Segment ((-5.0, 5.0), (15.0, 5.0)), W);
      Check (R.Status = Clip_Accept, "LB cross Accept");
      Check (Approx_Vec (R.Clipped.P0, (0.0, 5.0), 1.0E-2), "LB cross P0");
      Check (Approx_Vec (R.Clipped.P1, (10.0, 5.0), 1.0E-2), "LB cross P1");
   end;

   ---------------------------------------------------------------------
   Section ("12. Cyrus_Beck_Clip_3D_Lite axis-aligned box");
   ---------------------------------------------------------------------
   declare
      Planes : constant Polyhedron_Planes :=
        Make_Axis_Aligned_Box_Planes (0.0, 0.0, 0.0, 10.0, 10.0, 10.0);
      R : Clip_Result3;
      S : Segment3;
   begin
      Check (Planes.Count = 6, "box has 6 planes");
      Check (Plane_Dot_Classification3
               ((5.0, 5.0, 5.0), Planes.P (1)) = Dot_Inside,
             "box center vs −X = Inside");
      Check (Plane_Dot_Classification3
               ((-1.0, 5.0, 5.0), Planes.P (1)) = Dot_Outside,
             "left of −X = Outside");

      S := Make_Segment3 ((1.0, 2.0, 3.0), (4.0, 5.0, 6.0));
      R := Cyrus_Beck_Clip_3D_Lite (S, Planes);
      Check (R.Status = Clip_Accept, "3D inside Accept");
      Check (Approx_Vec3 (R.Clipped.P0, S.P0), "3D inside P0");
      Check (Approx_Vec3 (R.Clipped.P1, S.P1), "3D inside P1");

      S := Make_Segment3 ((-5.0, 5.0, 5.0), (15.0, 5.0, 5.0));
      R := Cyrus_Beck_Clip_3D_Lite (S, Planes);
      Check (R.Status = Clip_Accept, "3D through Accept");
      Check (Approx_Vec3 (R.Clipped.P0, (0.0, 5.0, 5.0), 1.0E-2),
             "3D enter x=0");
      Check (Approx_Vec3 (R.Clipped.P1, (10.0, 5.0, 5.0), 1.0E-2),
             "3D leave x=10");

      S := Make_Segment3 ((-5.0, 5.0, 5.0), (-1.0, 5.0, 5.0));
      R := Cyrus_Beck_Clip_3D_Lite (S, Planes);
      Check (R.Status = Clip_Reject, "3D outside Reject");

      Check (Approx (Length3 (Make_Segment3 ((0.0, 0.0, 0.0), (0.0, 3.0, 4.0))),
                     5.0),
             "Length3 3-4-5");
   end;

   ---------------------------------------------------------------------
   Section ("13. Degenerate / parallel / point segments");
   ---------------------------------------------------------------------
   declare
      Poly : constant Convex_Clip_Polygon :=
        Make_Convex_Rect (0.0, 0.0, 10.0, 10.0);
      R : Clip_Result;
      P : Clip_Params_Result;
   begin
      --  Point segment inside
      R := Cyrus_Beck_Clip (Make_Segment ((5.0, 5.0), (5.0, 5.0)), Poly);
      Check (R.Status = Clip_Accept, "point inside Accept");
      Check (Approx_Vec (R.Clipped.P0, (5.0, 5.0)), "point inside P0");
      Check (Approx_Vec (R.Clipped.P1, (5.0, 5.0)), "point inside P1");

      --  Point segment outside
      R := Cyrus_Beck_Clip (Make_Segment ((-1.0, 5.0), (-1.0, 5.0)), Poly);
      Check (R.Status = Clip_Reject, "point outside Reject");

      --  Parallel outside (horizontal above window, using triangle? rect top)
      R := Cyrus_Beck_Clip (Make_Segment ((-2.0, 12.0), (12.0, 12.0)), Poly);
      Check (R.Status = Clip_Reject, "parallel above Reject");

      P := Cyrus_Beck_Clip_Params (Make_Segment ((5.0, 5.0), (5.0, 5.0)), Poly);
      Check (P.Status = Clip_Accept, "params point inside");
      Check (Approx (P.T0, 0.0) and then Approx (P.T1, 1.0),
             "params point t in [0,1]");
   end;

   ---------------------------------------------------------------------
   Section ("14. Vec3 helpers / Near_Point3");
   ---------------------------------------------------------------------
   declare
      A : constant Vec3 := (1.0, 2.0, 3.0);
      B : constant Vec3 := A + (1.0, 1.0, 1.0);
      C : constant Vec3 := 2.0 * (1.0, 0.0, -1.0);
   begin
      Check (Near_Point3 (A, A), "Near_Point3 identical");
      Check (not Near_Point3 (A, (0.0, 0.0, 0.0)), "Near_Point3 distinct");
      Check (Approx_Vec3 (B, (2.0, 3.0, 4.0)), "Vec3 +");
      Check (Approx_Vec3 (A - (1.0, 1.0, 1.0), (0.0, 1.0, 2.0)), "Vec3 -");
      Check (Approx_Vec3 (C, (2.0, 0.0, -2.0)), "Vec3 scalar *");
      Check (Approx (Dot3 ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0)), 0.0),
             "Dot3 orthogonal");
   end;

   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("Passed:" & Pass_Count'Image);
   Put_Line ("Failed:" & Fail_Count'Image);
   Put_Line ("----------------------------------------");

   pragma Assert (Fail_Count = 0, "Cyrus_Beck tests failed");
   Put_Line ("ALL TESTS PASSED");
end Tests;
