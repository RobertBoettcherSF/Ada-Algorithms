--  Standalone test suite for Sutherland_Hodgman (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Sutherland_Hodgman; use Sutherland_Hodgman;

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

   function Has_Vertex
     (Poly : Polygon; P : Vec2; Tol : Real := 1.0E-3) return Boolean
   is
   begin
      for I in 1 .. Poly.Count loop
         if Near_Point (Poly.Verts (I), P, Tol) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Vertex;

   function Has_Vertex3
     (Poly : Polygon3; P : Vec3; Tol : Real := 1.0E-3) return Boolean
   is
   begin
      for I in 1 .. Poly.Count loop
         if Near_Point3 (Poly.Verts (I), P, Tol) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Vertex3;

begin
   Put_Line ("Sutherland_Hodgman test suite");
   Put_Line ("==============================");

   ---------------------------------------------------------------------
   Section ("1. Vector helpers / Near / Distance / Cross_Z");
   ---------------------------------------------------------------------
   declare
      A : constant Vec2 := (3.0, 4.0);
      B : constant Vec2 := (0.0, 0.0);
      S : constant Vec2 := A + (1.0, 1.0);
      D : constant Vec2 := A - (1.0, 1.0);
      M : constant Vec2 := 2.0 * (1.0, 2.0);
   begin
      Check (Approx (Distance (A, B), 5.0), "Distance (3,4) to origin is 5");
      Check (Near (1.0, 1.0 + 1.0E-6), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Approx (Cross_Z ((1.0, 0.0), (0.0, 1.0)), 1.0),
             "Cross_Z of basis is 1");
      Check (Approx_Vec (S, (4.0, 5.0)), "vector +");
      Check (Approx_Vec (D, (2.0, 3.0)), "vector -");
      Check (Approx_Vec (M, (2.0, 4.0)), "scalar *");
      Check (Approx (Dot ((1.0, 0.0), (0.0, 1.0)), 0.0), "Dot orthogonal");
   end;

   ---------------------------------------------------------------------
   Section ("2. Make_Rectangle / Make_Triangle / Vertex_Count / Copy");
   ---------------------------------------------------------------------
   declare
      R : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 5.0);
      T : constant Polygon :=
        Make_Triangle ((0.0, 0.0), (4.0, 0.0), (2.0, 3.0));
      C : constant Polygon := Polygon_Copy (R);
   begin
      Check (Vertex_Count_Of (R) = 4, "rectangle has 4 vertices");
      Check (Vertex_Count_Of (T) = 3, "triangle has 3 vertices");
      Check (Same_Polygon (R, C), "Polygon_Copy preserves vertices");
      Check (Polygon_Orientation (R) = Counter_Clockwise,
             "Make_Rectangle default is CCW");
      Check (Polygon_Orientation (T) = Counter_Clockwise,
             "Make_Triangle default is CCW");
      Check (Approx_Vec (R.Verts (1), (0.0, 0.0)), "rect lower-left first");
   end;

   ---------------------------------------------------------------------
   Section ("3. Signed_Area / Orient / Ensure_Orientation");
   ---------------------------------------------------------------------
   declare
      CW  : constant Polygon := Make_Rectangle (0.0, 0.0, 2.0, 2.0, Clockwise);
      CCW : constant Polygon :=
        Make_Rectangle (0.0, 0.0, 2.0, 2.0, Counter_Clockwise);
      Fixed : constant Polygon := Orient_Clockwise (CCW);
      Ens   : constant Polygon :=
        Ensure_Orientation (CW, Counter_Clockwise);
      Back  : constant Polygon := Orient_Counter_Clockwise (CW);
   begin
      Check (Signed_Area (CW) < 0.0, "CW rectangle has negative signed area");
      Check (Signed_Area (CCW) > 0.0, "CCW rectangle has positive signed area");
      Check (Approx (abs (Signed_Area (CW)), 4.0), "|area| of 2x2 is 4");
      Check (Polygon_Orientation (Fixed) = Clockwise,
             "Orient_Clockwise flips CCW to CW");
      Check (Polygon_Orientation (Ens) = Counter_Clockwise,
             "Ensure_Orientation to CCW");
      Check (Polygon_Orientation (Back) = Counter_Clockwise,
             "Orient_Counter_Clockwise flips CW to CCW");
      Check (Approx (Absolute_Area (CW), 4.0), "Absolute_Area of 2x2 is 4");
   end;

   ---------------------------------------------------------------------
   Section ("4. Is_Convex_Polygon");
   ---------------------------------------------------------------------
   declare
      Rect : constant Polygon := Make_Rectangle (0.0, 0.0, 4.0, 3.0);
      Tri  : constant Polygon :=
        Make_Triangle ((0.0, 0.0), (5.0, 0.0), (1.0, 4.0));
      Conc : Polygon;
   begin
      --  C-shaped concave quad-ish pentagon
      Conc.Count := 6;
      Conc.Verts (1) := (0.0, 0.0);
      Conc.Verts (2) := (5.0, 0.0);
      Conc.Verts (3) := (5.0, 4.0);
      Conc.Verts (4) := (3.0, 4.0);
      Conc.Verts (5) := (3.0, 1.0);
      Conc.Verts (6) := (0.0, 4.0);
      Check (Is_Convex_Polygon (Rect), "rectangle is convex");
      Check (Is_Convex_Polygon (Tri), "triangle is convex");
      Check (not Is_Convex_Polygon (Conc), "C-shape is not convex");
      Check (Is_Convex_Polygon
               (Make_Rectangle (0.0, 0.0, 1.0, 1.0, Clockwise)),
             "CW rectangle still convex");
   end;

   ---------------------------------------------------------------------
   Section ("5. Inside_HalfPlane");
   ---------------------------------------------------------------------
   declare
      --  Bottom edge of unit square, left-to-right (CCW): (0,0)→(1,0)
      E : constant Edge := ((0.0, 0.0), (1.0, 0.0));
   begin
      Check (Inside_HalfPlane ((0.5, 0.5), E, True),
             "point above bottom edge is left/inside for CCW");
      Check (not Inside_HalfPlane ((0.5, -0.5), E, True),
             "point below bottom edge is outside for CCW");
      Check (Inside_HalfPlane ((0.5, 0.0), E, True),
             "point on the line counts as inside");
      Check (Inside_HalfPlane ((0.5, -0.5), E, False),
             "below is inside when Inside_Left=False (CW)");
      Check (not Inside_HalfPlane ((0.5, 0.5), E, False),
             "above is outside when Inside_Left=False");
   end;

   ---------------------------------------------------------------------
   Section ("6. Compute_Intersection");
   ---------------------------------------------------------------------
   declare
      E : constant Edge := ((0.0, 0.0), (0.0, 10.0));  -- vertical x=0
      I : constant Vec2 :=
        Compute_Intersection ((-2.0, 3.0), (2.0, 3.0), E);
      H : constant Edge := ((0.0, 5.0), (10.0, 5.0));  -- horizontal y=5
      J : constant Vec2 :=
        Compute_Intersection ((4.0, 0.0), (4.0, 10.0), H);
      Raised : Boolean := False;
   begin
      Check (Approx_Vec (I, (0.0, 3.0)), "horizontal subject hits x=0 at (0,3)");
      Check (Approx_Vec (J, (4.0, 5.0)), "vertical subject hits y=5 at (4,5)");
      begin
         declare
            Ignore : constant Vec2 :=
              Compute_Intersection
                ((0.0, 0.0), (1.0, 0.0),
                 ((0.0, 1.0), (2.0, 1.0)));  -- parallel horizontals
            pragma Unreferenced (Ignore);
         begin
            null;
         end;
      exception
         when Degenerate_Geometry =>
            Raised := True;
      end;
      Check (Raised, "parallel lines raise Degenerate_Geometry");
   end;

   ---------------------------------------------------------------------
   Section ("7. Clip_Against_Edge (single pass)");
   ---------------------------------------------------------------------
   declare
      --  Subject: square [0,2]x[0,2]; clip against right half-plane x>=1
      --  Edge (1,0)→(1,10) with Inside_Left: left of upward edge is x<=1...
      --  For CCW window left edge (0,0)→(0,H) keeps x>=0 (left of upward? wait)
      --  Use edge (1,10)→(1,0) downward so left = x>=1.
      Subj : Polygon;
      E    : constant Edge := ((1.0, 10.0), (1.0, 0.0));
      Outp : Polygon;
   begin
      Subj := Make_Rectangle (0.0, 0.0, 2.0, 2.0, Counter_Clockwise);
      Outp := Clip_Against_Edge (Subj, E, True);
      Check (Outp.Count >= 4, "clip against x=1 yields a polygon");
      Check (Has_Vertex (Outp, (1.0, 0.0)) or else Has_Vertex (Outp, (1.0, 2.0)),
             "intersection vertices on the clip line appear");
      Check (not Has_Vertex (Outp, (0.0, 0.0)),
             "fully outside corner (0,0) is removed");
      --  All remaining vertices should have X >= 1 - eps
      declare
         All_Right : Boolean := True;
      begin
         for K in 1 .. Outp.Count loop
            if Outp.Verts (K).X < 1.0 - 1.0E-3 then
               All_Right := False;
            end if;
         end loop;
         Check (All_Right, "all output vertices have X >= 1");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("8. Sutherland_Hodgman_Clip — rect ∩ rect");
   ---------------------------------------------------------------------
   declare
      Subject : constant Polygon :=
        Make_Rectangle (0.0, 0.0, 4.0, 4.0);
      Clip    : constant Polygon :=
        Make_Rectangle (1.0, 1.0, 3.0, 3.0);
      Result  : constant Polygon :=
        Sutherland_Hodgman_Clip (Subject, Clip);
   begin
      Check (Result.Count = 4, "overlapping squares yield a quad");
      Check (Approx (Absolute_Area (Result), 4.0),
             "intersection area of [0,4]² ∩ [1,3]² is 4");
      Check (Has_Vertex (Result, (1.0, 1.0)), "has (1,1)");
      Check (Has_Vertex (Result, (3.0, 3.0)), "has (3,3)");
   end;

   ---------------------------------------------------------------------
   Section ("9. Sutherland_Hodgman_Clip — triangle ∩ rect");
   ---------------------------------------------------------------------
   declare
      Tri : constant Polygon :=
        Make_Triangle ((-1.0, 1.0), (5.0, 1.0), (2.0, 5.0));
      Win : constant Polygon := Make_Rectangle (0.0, 0.0, 4.0, 4.0);
      R   : constant Polygon := Sutherland_Hodgman_Clip (Tri, Win);
   begin
      Check (R.Count >= 3, "clipped triangle has at least 3 verts");
      Check (Absolute_Area (R) > 0.0, "clipped triangle has positive area");
      Check (Absolute_Area (R) < Absolute_Area (Tri) + 1.0E-3,
             "clipped area <= original triangle area");
      --  Vertices should lie inside or on the window
      declare
         Inside_Ok : Boolean := True;
      begin
         for I in 1 .. R.Count loop
            if R.Verts (I).X < -1.0E-3
              or else R.Verts (I).X > 4.0 + 1.0E-3
              or else R.Verts (I).Y < -1.0E-3
              or else R.Verts (I).Y > 4.0 + 1.0E-3
            then
               Inside_Ok := False;
            end if;
         end loop;
         Check (Inside_Ok, "all clipped vertices inside window");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Clip_Against_Rect convenience");
   ---------------------------------------------------------------------
   declare
      Subject : constant Polygon :=
        Make_Rectangle (-2.0, -2.0, 6.0, 6.0);
      R : constant Polygon :=
        Clip_Against_Rect (Subject, 0.0, 0.0, 4.0, 4.0);
   begin
      Check (R.Count = 4, "rect clip of large square → quad");
      Check (Approx (Absolute_Area (R), 16.0), "clipped area is 16");
      Check (Has_Vertex (R, (0.0, 0.0)), "has (0,0)");
      Check (Has_Vertex (R, (4.0, 4.0)), "has (4,4)");
   end;

   ---------------------------------------------------------------------
   Section ("11. Clip_Against_Frustum_2D (alias)");
   ---------------------------------------------------------------------
   declare
      Subject : constant Polygon :=
        Make_Triangle ((0.0, 0.0), (10.0, 0.0), (5.0, 8.0));
      Window  : constant Polygon :=
        Make_Rectangle (2.0, 1.0, 8.0, 6.0);
      A : constant Polygon := Clip_Against_Frustum_2D (Subject, Window);
      B : constant Polygon := Sutherland_Hodgman_Clip (Subject, Window);
   begin
      Check (A.Count = B.Count, "frustum alias matches SH vertex count");
      Check (Approx (Absolute_Area (A), Absolute_Area (B)),
             "frustum alias matches SH area");
      Check (A.Count >= 3, "frustum clip produces a polygon");
      Check (Absolute_Area (A) > 0.0, "frustum clip has positive area");
   end;

   ---------------------------------------------------------------------
   Section ("12. Subject fully inside / fully outside / CW clip");
   ---------------------------------------------------------------------
   declare
      Clip : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 10.0);
      Inside_Subj : constant Polygon :=
        Make_Rectangle (2.0, 2.0, 4.0, 4.0);
      Outside_Subj : constant Polygon :=
        Make_Rectangle (20.0, 20.0, 25.0, 25.0);
      Rin  : constant Polygon :=
        Sutherland_Hodgman_Clip (Inside_Subj, Clip);
      Rout : constant Polygon :=
        Sutherland_Hodgman_Clip (Outside_Subj, Clip);
      CW_Clip : constant Polygon :=
        Make_Rectangle (0.0, 0.0, 5.0, 5.0, Clockwise);
      Subj2 : constant Polygon :=
        Make_Rectangle (-1.0, -1.0, 3.0, 3.0);
      Rcw : constant Polygon :=
        Sutherland_Hodgman_Clip (Subj2, CW_Clip);
   begin
      Check (Rin.Count = 4, "fully inside subject preserved as quad");
      Check (Approx (Absolute_Area (Rin), 4.0),
             "fully inside area unchanged");
      Check (Rout.Count < 3, "fully outside subject yields empty/degenerate");
      Check (Rcw.Count >= 3 and then Absolute_Area (Rcw) > 0.0,
             "CW clip polygon still works via orientation detect");
   end;

   ---------------------------------------------------------------------
   Section ("13. Clip_Polygon_Against_Plane_3D_Lite");
   ---------------------------------------------------------------------
   declare
      --  Unit square in XY plane at z=0; clip with plane z >= 0 is no-op.
      --  Clip with plane x >= 0.5: keep right half.
      Quad : constant Polygon3 :=
        Make_Polygon3
          ((0.0, 0.0, 0.0), (2.0, 0.0, 0.0),
           (2.0, 2.0, 0.0), (0.0, 2.0, 0.0));
      Plane_X : constant Plane3 :=
        (Normal => (1.0, 0.0, 0.0), D => -0.5);  -- x - 0.5 >= 0 ⇒ x >= 0.5
      R : constant Polygon3 :=
        Clip_Polygon_Against_Plane_3D_Lite (Quad, Plane_X);
      Tri : constant Polygon3 :=
        Make_Polygon3
          ((0.0, 0.0, -1.0), (2.0, 0.0, -1.0), (1.0, 2.0, 1.0));
      Plane_Z : constant Plane3 :=
        (Normal => (0.0, 0.0, 1.0), D => 0.0);  -- z >= 0
      Rz : constant Polygon3 :=
        Clip_Polygon_Against_Plane_3D_Lite (Tri, Plane_Z);
   begin
      Check (R.Count >= 3, "3D plane clip yields a polygon");
      Check (Has_Vertex3 (R, (0.5, 0.0, 0.0))
               or else Has_Vertex3 (R, (0.5, 2.0, 0.0)),
             "3D clip inserts intersection on plane x=0.5");
      declare
         All_Pos : Boolean := True;
      begin
         for I in 1 .. R.Count loop
            if R.Verts (I).X < 0.5 - 1.0E-3 then
               All_Pos := False;
            end if;
         end loop;
         Check (All_Pos, "all 3D clipped verts have X >= 0.5");
      end;
      Check (Rz.Count >= 3, "z>=0 clip of straddling triangle has verts");
      Check (Approx (Plane_Signed_Distance ((1.0, 0.0, 2.0), Plane_Z), 2.0),
             "Plane_Signed_Distance for z-plane");
      Check (Near_Point3 ((1.0, 2.0, 3.0), (1.0, 2.0, 3.0)),
             "Near_Point3 identity");
   end;

   ---------------------------------------------------------------------
   Section ("14. Non_Convex_Clip exception / empty edge pass");
   ---------------------------------------------------------------------
   declare
      Conc : Polygon;
      Subj : constant Polygon := Make_Rectangle (0.0, 0.0, 2.0, 2.0);
      Raised : Boolean := False;
      Empty  : Polygon;
      Edge_Pass : Polygon;
   begin
      Conc.Count := 5;
      Conc.Verts (1) := (0.0, 0.0);
      Conc.Verts (2) := (4.0, 0.0);
      Conc.Verts (3) := (4.0, 3.0);
      Conc.Verts (4) := (2.0, 1.0);  -- dent
      Conc.Verts (5) := (0.0, 3.0);
      begin
         declare
            Ignore : constant Polygon :=
              Sutherland_Hodgman_Clip (Subj, Conc);
            pragma Unreferenced (Ignore);
         begin
            null;
         end;
      exception
         when Non_Convex_Clip =>
            Raised := True;
      end;
      Check (Raised, "concave clip raises Non_Convex_Clip");
      Check (not Is_Convex_Polygon (Conc), "dent polygon is concave");
      Empty.Count := 0;
      Edge_Pass := Clip_Against_Edge
        (Empty, ((0.0, 0.0), (1.0, 0.0)), True);
      Check (Edge_Pass.Count = 0, "clip empty subject stays empty");
   end;

   ---------------------------------------------------------------------
   Section ("15. Vec3 helpers / Make_Polygon3");
   ---------------------------------------------------------------------
   declare
      A : constant Vec3 := (1.0, 2.0, 3.0);
      B : constant Vec3 := (0.0, 1.0, 1.0);
      S : constant Vec3 := A + B;
      D : constant Vec3 := A - B;
      M : constant Vec3 := 2.0 * B;
      P3 : constant Polygon3 :=
        Make_Polygon3 ((0.0, 0.0, 0.0), (1.0, 0.0, 0.0), (0.0, 1.0, 0.0));
   begin
      Check (Approx_Vec3 (S, (1.0, 3.0, 4.0)), "Vec3 +");
      Check (Approx_Vec3 (D, (1.0, 1.0, 2.0)), "Vec3 -");
      Check (Approx_Vec3 (M, (0.0, 2.0, 2.0)), "Vec3 scalar *");
      Check (Approx (Dot3 (A, B), 5.0), "Dot3 (1,2,3)·(0,1,1)=5");
      Check (P3.Count = 3, "Make_Polygon3 triangle has 3 verts");
   end;

   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   pragma Assert (Fail_Count = 0);
   Put_Line ("All tests passed.");
end Tests;
