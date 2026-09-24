--  Standalone test suite for Clipping (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Clipping; use Clipping;

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

begin
   Put_Line ("Clipping test suite");
   Put_Line ("===================");

   ---------------------------------------------------------------------
   Section ("1. Vector helpers / Near / Dot / Cross_Z");
   ---------------------------------------------------------------------
   declare
      A : constant Vec2 := (3.0, 4.0);
      B : constant Vec2 := (0.0, 0.0);
      S : constant Vec2 := A + (1.0, 1.0);
      D : constant Vec2 := A - (1.0, 1.0);
      M : constant Vec2 := 2.0 * (1.0, 2.0);
      C : constant Vec3 := (1.0, 2.0, 3.0);
   begin
      Check (Near (1.0, 1.0 + 1.0E-6), "Near accepts tiny delta");
      Check (not Near (1.0, 2.0), "Near rejects large delta");
      Check (Approx_Vec (S, (4.0, 5.0)), "vector +");
      Check (Approx_Vec (D, (2.0, 3.0)), "vector -");
      Check (Approx_Vec (M, (2.0, 4.0)), "scalar *");
      Check (Approx (Dot ((1.0, 0.0), (0.0, 1.0)), 0.0), "Dot orthogonal");
      Check (Approx (Cross_Z ((1.0, 0.0), (0.0, 1.0)), 1.0), "Cross_Z unit");
      Check (Near_Point (A, A), "Near_Point identical");
      Check (not Near_Point (A, B), "Near_Point distinct");
      Check (Near_Point3 (C, C), "Near_Point3 identical");
      Check (Approx_Vec3 (C + (1.0, 0.0, 0.0), (2.0, 2.0, 3.0)), "Vec3 +");
      Check (Approx (Dot3 ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0)), 0.0),
             "Dot3 orthogonal");
   end;

   ---------------------------------------------------------------------
   Section ("2. Make_Rect / Is_Valid_Rect / Point_In_Rect");
   ---------------------------------------------------------------------
   declare
      R     : constant Clip_Rect := Make_Rect (0.0, 0.0, 10.0, 5.0);
      Bad   : Clip_Rect;
      Raised : Boolean := False;
   begin
      Check (Is_Valid_Rect (R), "Make_Rect yields valid rect");
      Check (Approx (R.X_Max - R.X_Min, 10.0), "rect width 10");
      Check (Approx (R.Y_Max - R.Y_Min, 5.0), "rect height 5");
      Bad := (0.0, 0.0, 0.0, 1.0);
      Check (not Is_Valid_Rect (Bad), "zero-width rect invalid");
      Check (Point_In_Rect ((5.0, 2.5), R), "center inside");
      Check (Point_In_Rect ((0.0, 0.0), R), "corner counts inside");
      Check (not Point_In_Rect ((-1.0, 2.0), R), "outside left");
      begin
         declare
            Unused : Clip_Rect;
         begin
            Unused := Make_Rect (1.0, 0.0, 0.0, 1.0);
            pragma Unreferenced (Unused);
         end;
      exception
         when Invalid_Argument =>
            Raised := True;
         when Constraint_Error =>
            Raised := True;
      end;
      Check (Raised, "Make_Rect inverted X raises");
   end;

   ---------------------------------------------------------------------
   Section ("3. Make_Segment / Make_Polygon / Length");
   ---------------------------------------------------------------------
   declare
      S  : constant Segment := Make_Segment ((0.0, 0.0), (3.0, 4.0));
      S3 : constant Segment3 :=
        Make_Segment3 ((0.0, 0.0, 0.0), (0.0, 0.0, 5.0));
      VA : Vertex_Array := [others => (0.0, 0.0)];
      P  : Polygon;
      A  : constant Segment := Make_Segment ((0.0, 0.0), (10.0, 10.0));
      B  : constant Segment := Make_Segment ((10.0, 10.0), (0.0, 0.0));
   begin
      VA (1) := (0.0, 0.0);
      VA (2) := (2.0, 0.0);
      VA (3) := (1.0, 2.0);
      P := Make_Polygon (VA, 3);
      Check (Approx_Vec (S.P0, (0.0, 0.0)), "Make_Segment P0");
      Check (Approx_Vec (S.P1, (3.0, 4.0)), "Make_Segment P1");
      Check (Approx (Length (S), 5.0), "Length 3-4-5");
      Check (Approx (Length3 (S3), 5.0), "Length3 along Z");
      Check (P.Count = 3, "Make_Polygon count 3");
      Check (Approx_Vec (P.Verts (3), (1.0, 2.0)), "Make_Polygon vert 3");
      Check (Same_Clipped_Segment (A, B), "Same_Clipped undirected");
      Check (not Same_Clipped_Segment
               (A, Make_Segment ((0.0, 0.0), (5.0, 5.0))),
             "Same_Clipped rejects different");
   end;

   ---------------------------------------------------------------------
   Section ("4. Clip_Point accept / reject");
   ---------------------------------------------------------------------
   declare
      R : constant Clip_Rect := Make_Rect (0.0, 0.0, 10.0, 10.0);
   begin
      Check (Clip_Point ((5.0, 5.0), R) = Clip_Accept, "center accept");
      Check (Clip_Point ((0.0, 0.0), R) = Clip_Accept, "corner accept");
      Check (Clip_Point ((-1.0, 5.0), R) = Clip_Reject, "left reject");
      Check (Clip_Point ((5.0, 11.0), R) = Clip_Reject, "above reject");
      Check (Clip_Point ((10.0, 10.0), R) = Clip_Accept, "far corner accept");
   end;

   ---------------------------------------------------------------------
   Section ("5. Clip_Line_Liang_Barsky");
   ---------------------------------------------------------------------
   declare
      R  : constant Clip_Rect := Make_Rect (0.0, 0.0, 10.0, 10.0);
      Inside_Seg : constant Clip_Result :=
        Clip_Line_Liang_Barsky
          (Make_Segment ((1.0, 1.0), (9.0, 9.0)), R);
      Outside_Seg : constant Clip_Result :=
        Clip_Line_Liang_Barsky
          (Make_Segment ((-5.0, -5.0), (-1.0, -1.0)), R);
      Cross : constant Clip_Result :=
        Clip_Line_Liang_Barsky
          (Make_Segment ((-5.0, 5.0), (15.0, 5.0)), R);
      Diag : constant Clip_Result :=
        Clip_Line_Liang_Barsky
          (Make_Segment ((-2.0, -2.0), (12.0, 12.0)), R);
   begin
      Check (Inside_Seg.Status = Clip_Accept, "fully inside accepted");
      Check (Same_Clipped_Segment
               (Inside_Seg.Clipped, Make_Segment ((1.0, 1.0), (9.0, 9.0))),
             "inside segment unchanged");
      Check (Outside_Seg.Status = Clip_Reject, "fully outside rejected");
      Check (Cross.Status = Clip_Accept, "horizontal cross accepted");
      Check (Approx_Vec (Cross.Clipped.P0, (0.0, 5.0)), "cross left edge");
      Check (Approx_Vec (Cross.Clipped.P1, (10.0, 5.0)), "cross right edge");
      Check (Diag.Status = Clip_Accept, "diagonal cross accepted");
      Check (Approx_Vec (Diag.Clipped.P0, (0.0, 0.0), 1.0E-2),
             "diag enters corner");
      Check (Approx_Vec (Diag.Clipped.P1, (10.0, 10.0), 1.0E-2),
             "diag leaves corner");
   end;

   ---------------------------------------------------------------------
   Section ("6. Clip_Polygon_Sutherland_Hodgman / Clip_Polygon_To_Rect");
   ---------------------------------------------------------------------
   declare
      R : constant Clip_Rect := Make_Rect (0.0, 0.0, 10.0, 10.0);
      VA : Vertex_Array := [others => (0.0, 0.0)];
      Subj : Polygon;
      Res  : Polygon_Result;
      Tri  : Polygon_Result;
   begin
      --  Square subject fully inside.
      VA (1) := (2.0, 2.0);
      VA (2) := (8.0, 2.0);
      VA (3) := (8.0, 8.0);
      VA (4) := (2.0, 8.0);
      Subj := Make_Polygon (VA, 4);
      Res := Clip_Polygon_To_Rect (Subj, R);
      Check (Res.Status = Clip_Accept, "inside polygon accepted");
      Check (Res.Clipped.Count >= 3, "inside polygon has verts");

      --  Triangle straddling the left edge.
      VA (1) := (-5.0, 5.0);
      VA (2) := (5.0, 0.0);
      VA (3) := (5.0, 10.0);
      Subj := Make_Polygon (VA, 3);
      Tri := Clip_Polygon_To_Rect (Subj, R);
      Check (Tri.Status = Clip_Accept, "straddling triangle accepted");
      Check (Tri.Clipped.Count >= 3, "clipped triangle has >= 3 verts");

      --  Triangle fully outside.
      VA (1) := (-8.0, -8.0);
      VA (2) := (-2.0, -8.0);
      VA (3) := (-5.0, -2.0);
      Subj := Make_Polygon (VA, 3);
      Res := Clip_Polygon_Sutherland_Hodgman (Subj, Rect_To_Polygon (R));
      Check (Res.Status = Clip_Reject, "outside triangle rejected");

      --  Rect_To_Polygon has 4 verts.
      Check (Rect_To_Polygon (R).Count = 4, "Rect_To_Polygon count 4");
   end;

   ---------------------------------------------------------------------
   Section ("7. Intersect_Clip_Regions (user ∩ device)");
   ---------------------------------------------------------------------
   declare
      User   : constant Clip_Rect := Make_Rect (0.0, 0.0, 10.0, 10.0);
      Device : constant Clip_Rect := Make_Rect (5.0, 5.0, 20.0, 20.0);
      Over   : constant Intersect_Result :=
        Intersect_Clip_Regions (User, Device);
      Miss   : constant Intersect_Result :=
        Intersect_Clip_Regions
          (Make_Rect (0.0, 0.0, 2.0, 2.0),
           Make_Rect (5.0, 5.0, 8.0, 8.0));
      Same   : constant Intersect_Result :=
        Intersect_Clip_Regions (User, User);
   begin
      Check (Over.Overlaps, "overlapping regions overlap");
      Check (Is_Valid_Rect (Over.Region), "intersection is valid rect");
      Check (Approx (Over.Region.X_Min, 5.0), "intersect X_Min 5");
      Check (Approx (Over.Region.Y_Min, 5.0), "intersect Y_Min 5");
      Check (Approx (Over.Region.X_Max, 10.0), "intersect X_Max 10");
      Check (Approx (Over.Region.Y_Max, 10.0), "intersect Y_Max 10");
      Check (not Miss.Overlaps, "disjoint regions no overlap");
      Check (Same.Overlaps, "self intersection overlaps");
      Check (Approx (Same.Region.X_Max - Same.Region.X_Min, 10.0),
             "self intersection preserves width");
   end;

   ---------------------------------------------------------------------
   Section ("8. View_Frustum_2D / Point_In_Frustum");
   ---------------------------------------------------------------------
   declare
      --  Trapezoid frustum: near (small) at y=2, far (wide) at y=10.
      F : constant View_Frustum_2D :=
        Make_Frustum_2D
          ([(4.0, 2.0), (6.0, 2.0), (10.0, 10.0), (0.0, 10.0)]);
      Bad : constant View_Frustum_2D :=
        Make_Frustum_2D
          ([(0.0, 0.0), (1.0, 0.0), (0.5, 0.0), (0.5, 1.0)]);
   begin
      Check (Is_Valid_Frustum (F), "trapezoid frustum valid");
      Check (not Is_Valid_Frustum (Bad), "degenerate frustum invalid");
      Check (Point_In_Frustum ((5.0, 5.0), F), "center in frustum");
      Check (Point_In_Frustum ((5.0, 2.0), F), "near-edge midpoint inside");
      Check (not Point_In_Frustum ((5.0, 0.0), F), "below near plane out");
      Check (not Point_In_Frustum ((-1.0, 5.0), F), "left of frustum out");
      Check (Clip_Against_Frustum ((5.0, 6.0), F) = Clip_Accept,
             "point frustum accept");
      Check (Clip_Against_Frustum ((20.0, 6.0), F) = Clip_Reject,
             "point frustum reject");
   end;

   ---------------------------------------------------------------------
   Section ("9. Clip_Against_Frustum (line)");
   ---------------------------------------------------------------------
   declare
      F : constant View_Frustum_2D :=
        Make_Frustum_2D
          ([(4.0, 2.0), (6.0, 2.0), (10.0, 10.0), (0.0, 10.0)]);
      Mid : constant Clip_Result :=
        Clip_Against_Frustum (Make_Segment ((5.0, 3.0), (5.0, 9.0)), F);
      Outside_F : constant Clip_Result :=
        Clip_Against_Frustum
          (Make_Segment ((-10.0, 0.0), (-8.0, 1.0)), F);
      Cross : constant Clip_Result :=
        Clip_Against_Frustum
          (Make_Segment ((5.0, 0.0), (5.0, 12.0)), F);
   begin
      Check (Mid.Status = Clip_Accept, "interior vertical accepted");
      Check (Outside_F.Status = Clip_Reject, "far-left rejected");
      Check (Cross.Status = Clip_Accept, "through-frustum accepted");
      Check (Approx (Cross.Clipped.P0.Y, 2.0, 1.0E-2)
               or else Approx (Cross.Clipped.P1.Y, 2.0, 1.0E-2),
             "cross hits near y≈2");
      Check (Point_In_Frustum (Cross.Clipped.P0, F)
               and then Point_In_Frustum (Cross.Clipped.P1, F),
             "clipped endpoints inside frustum");
   end;

   ---------------------------------------------------------------------
   Section ("10. Near_Far_Clip_3D_Lite");
   ---------------------------------------------------------------------
   declare
      Inside : constant Clip_Result3 :=
        Near_Far_Clip_3D_Lite
          (Make_Segment3 ((0.0, 0.0, 2.0), (1.0, 0.0, 8.0)), 1.0, 10.0);
      Before : constant Clip_Result3 :=
        Near_Far_Clip_3D_Lite
          (Make_Segment3 ((0.0, 0.0, -5.0), (0.0, 0.0, 0.0)), 1.0, 10.0);
      After : constant Clip_Result3 :=
        Near_Far_Clip_3D_Lite
          (Make_Segment3 ((0.0, 0.0, 11.0), (0.0, 0.0, 20.0)), 1.0, 10.0);
      Span : constant Clip_Result3 :=
        Near_Far_Clip_3D_Lite
          (Make_Segment3 ((0.0, 0.0, -5.0), (0.0, 0.0, 15.0)), 1.0, 10.0);
      Flat : constant Clip_Result3 :=
        Near_Far_Clip_3D_Lite
          (Make_Segment3 ((1.0, 2.0, 5.0), (3.0, 4.0, 5.0)), 1.0, 10.0);
   begin
      Check (Inside.Status = Clip_Accept, "Z-inside accepted");
      Check (Approx_Vec3 (Inside.Clipped.P0, (0.0, 0.0, 2.0)),
             "Z-inside P0 unchanged");
      Check (Before.Status = Clip_Reject, "before near rejected");
      Check (After.Status = Clip_Reject, "beyond far rejected");
      Check (Span.Status = Clip_Accept, "spanning near/far accepted");
      Check (Approx (Span.Clipped.P0.Z, 1.0, 1.0E-3), "span clipped to near");
      Check (Approx (Span.Clipped.P1.Z, 10.0, 1.0E-3), "span clipped to far");
      Check (Flat.Status = Clip_Accept, "constant-Z inside accepted");
      Check (Approx_Vec3 (Flat.Clipped.P1, (3.0, 4.0, 5.0)),
             "flat P1 unchanged");
   end;

   ---------------------------------------------------------------------
   Section ("11. Classify_Visibility");
   ---------------------------------------------------------------------
   declare
      R : constant Clip_Rect := Make_Rect (0.0, 0.0, 10.0, 10.0);
   begin
      Check (Classify_Visibility
               (Make_Segment ((1.0, 1.0), (2.0, 2.0)), R) = Fully_Visible,
             "interior Fully_Visible");
      Check (Classify_Visibility
               (Make_Segment ((-5.0, -5.0), (-1.0, -1.0)), R) = Invisible,
             "outside Invisible");
      Check (Classify_Visibility
               (Make_Segment ((-5.0, 5.0), (15.0, 5.0)), R)
             = Partially_Visible,
             "crossing Partially_Visible");
      Check (Classify_Visibility
               (Make_Segment ((5.0, 5.0), (15.0, 5.0)), R)
             = Partially_Visible,
             "one-in Partially_Visible");
      Check (Classify_Visibility
               (Make_Segment ((0.0, 0.0), (10.0, 10.0)), R) = Fully_Visible,
             "boundary diagonal Fully_Visible");
   end;

   ---------------------------------------------------------------------
   Section ("12. Composite clip: user ∩ device then line clip");
   ---------------------------------------------------------------------
   declare
      User   : constant Clip_Rect := Make_Rect (0.0, 0.0, 100.0, 100.0);
      Device : constant Clip_Rect := Make_Rect (10.0, 10.0, 50.0, 50.0);
      Comp   : constant Intersect_Result :=
        Intersect_Clip_Regions (User, Device);
      CR     : Clip_Result;
   begin
      Check (Comp.Overlaps, "composite region exists");
      CR := Clip_Line_Liang_Barsky
        (Make_Segment ((0.0, 30.0), (100.0, 30.0)), Comp.Region);
      Check (CR.Status = Clip_Accept, "line vs composite accepted");
      Check (Approx_Vec (CR.Clipped.P0, (10.0, 30.0)), "composite left");
      Check (Approx_Vec (CR.Clipped.P1, (50.0, 30.0)), "composite right");
      Check (Classify_Visibility
               (Make_Segment ((0.0, 30.0), (100.0, 30.0)), Comp.Region)
             = Partially_Visible,
             "composite visibility partial");
   end;

   ---------------------------------------------------------------------
   Section ("13. Degenerate / edge cases");
   ---------------------------------------------------------------------
   declare
      R : constant Clip_Rect := Make_Rect (0.0, 0.0, 10.0, 10.0);
      Pt : constant Clip_Result :=
        Clip_Line_Liang_Barsky
          (Make_Segment ((5.0, 5.0), (5.0, 5.0)), R);
      Pt_Out : constant Clip_Result :=
        Clip_Line_Liang_Barsky
          (Make_Segment ((-1.0, -1.0), (-1.0, -1.0)), R);
      Edge : constant Clip_Result :=
        Clip_Line_Liang_Barsky
          (Make_Segment ((0.0, 0.0), (0.0, 10.0)), R);
      Z_Flat_Out : constant Clip_Result3 :=
        Near_Far_Clip_3D_Lite
          (Make_Segment3 ((0.0, 0.0, 0.0), (1.0, 0.0, 0.0)), 1.0, 10.0);
   begin
      Check (Pt.Status = Clip_Accept, "degenerate point inside accept");
      Check (Pt_Out.Status = Clip_Reject, "degenerate point outside reject");
      Check (Edge.Status = Clip_Accept, "rect edge segment accept");
      Check (Approx (Length (Edge.Clipped), 10.0), "edge length 10");
      Check (Z_Flat_Out.Status = Clip_Reject, "flat Z outside near reject");
      Check (Approx (Length (Make_Segment ((1.0, 1.0), (1.0, 1.0))), 0.0),
             "zero Length");
   end;

   ---------------------------------------------------------------------
   Section ("14. Polygon clip vs SH on convex clip poly");
   ---------------------------------------------------------------------
   declare
      --  Convex pentagon-ish clip: unit square as clip via Make_Polygon.
      Clip_VA : Vertex_Array := [others => (0.0, 0.0)];
      Subj_VA : Vertex_Array := [others => (0.0, 0.0)];
      Clip_P, Subj_P : Polygon;
      Res : Polygon_Result;
   begin
      Clip_VA (1) := (0.0, 0.0);
      Clip_VA (2) := (8.0, 0.0);
      Clip_VA (3) := (8.0, 8.0);
      Clip_VA (4) := (0.0, 8.0);
      Clip_P := Make_Polygon (Clip_VA, 4);

      Subj_VA (1) := (-2.0, 2.0);
      Subj_VA (2) := (10.0, 2.0);
      Subj_VA (3) := (4.0, 12.0);
      Subj_P := Make_Polygon (Subj_VA, 3);

      Res := Clip_Polygon_Sutherland_Hodgman (Subj_P, Clip_P);
      Check (Res.Status = Clip_Accept, "SH triangle vs square accept");
      Check (Res.Clipped.Count >= 3, "SH result has polygon");
      Check (Res.Clipped.Count > 0, "SH result non-empty");

      --  Tiny subject inside.
      Subj_VA (1) := (3.0, 3.0);
      Subj_VA (2) := (5.0, 3.0);
      Subj_VA (3) := (4.0, 5.0);
      Subj_P := Make_Polygon (Subj_VA, 3);
      Res := Clip_Polygon_Sutherland_Hodgman (Subj_P, Clip_P);
      Check (Res.Status = Clip_Accept, "SH tiny inside accept");
      Check (Res.Clipped.Count = 3, "SH tiny keeps triangle");
   end;

   New_Line;
   Put_Line ("Results: " & Pass_Count'Image & " passed, "
             & Fail_Count'Image & " failed");
   pragma Assert (Fail_Count = 0);
end Tests;
