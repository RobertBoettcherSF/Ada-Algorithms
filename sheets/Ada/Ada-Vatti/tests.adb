--  Standalone test suite for Vatti (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Vatti; use Vatti;

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

   function Approx (A, B : Real; Tol : Real := 1.0E-3) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Approx;

   function Approx_Vec (A, B : Vec2; Tol : Real := 1.0E-3) return Boolean is
   begin
      return Approx (A.X, B.X, Tol) and then Approx (A.Y, B.Y, Tol);
   end Approx_Vec;

   function Has_Vertex
     (Poly : Polygon; P : Vec2; Tol : Real := 1.0E-2) return Boolean
   is
   begin
      for I in 1 .. Poly.Count loop
         if Near_Point (Poly.Verts (I), P, Tol) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Vertex;

   function Set_Has_Vertex
     (S : Polygon_Set; P : Vec2; Tol : Real := 1.0E-2) return Boolean
   is
   begin
      for I in 1 .. S.Count loop
         if Has_Vertex (S.Polys (I), P, Tol) then
            return True;
         end if;
      end loop;
      return False;
   end Set_Has_Vertex;

begin
   Put_Line ("Vatti test suite");
   Put_Line ("================");

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
   Section ("2. Make_Rectangle / Make_Triangle / Orient helpers");
   ---------------------------------------------------------------------
   declare
      R : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 5.0);
      T : constant Polygon :=
        Make_Triangle ((0.0, 0.0), (4.0, 0.0), (2.0, 3.0));
      C : constant Polygon := Polygon_Copy (R);
      CCW : constant Polygon :=
        Make_Rectangle (0.0, 0.0, 2.0, 2.0, Counter_Clockwise);
      Fixed : constant Polygon := Orient_Clockwise (CCW);
   begin
      Check (Vertex_Count_Of (R) = 4, "rectangle has 4 vertices");
      Check (Vertex_Count_Of (T) = 3, "triangle has 3 vertices");
      Check (Same_Polygon (R, C), "Polygon_Copy preserves vertices");
      Check (Polygon_Orientation (R) = Clockwise,
             "Make_Rectangle default is clockwise");
      Check (Polygon_Orientation (Fixed) = Clockwise,
             "Orient_Clockwise flips CCW");
      Check (Approx (Absolute_Area (R), 50.0), "10x5 rect area is 50");
   end;

   ---------------------------------------------------------------------
   Section ("3. Point_In_Polygon / Point_On_Boundary / Point_In_Set");
   ---------------------------------------------------------------------
   declare
      R : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 10.0);
      S : constant Polygon_Set := Singleton (R);
   begin
      Check (Point_In_Polygon ((5.0, 5.0), R), "center is inside");
      Check (not Point_In_Polygon ((15.0, 5.0), R), "outside to the right");
      Check (Point_On_Boundary ((0.0, 5.0), R), "left edge is boundary");
      Check (not Point_In_Polygon ((0.0, 5.0), R),
             "boundary counted outside for labeling");
      Check (Point_In_Set ((5.0, 5.0), S), "Point_In_Set center");
      Check (not Point_In_Set ((20.0, 20.0), S), "Point_In_Set outside");
   end;

   ---------------------------------------------------------------------
   Section ("4. Segment_Intersection / Find_All_Intersections");
   ---------------------------------------------------------------------
   declare
      H1 : constant Seg_Intersect_Result :=
        Segment_Intersection
          ((0.0, 0.0), (10.0, 10.0), (0.0, 10.0), (10.0, 0.0));
      H2 : constant Seg_Intersect_Result :=
        Segment_Intersection
          ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0));
      A : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 10.0);
      B : constant Polygon := Make_Rectangle (5.0, 5.0, 15.0, 15.0);
      Hits : constant Intersection_List := Find_All_Intersections (A, B);
   begin
      Check (H1.Found, "crossing diagonals intersect");
      Check (Approx_Vec (H1.Point, (5.0, 5.0)), "intersection at (5,5)");
      Check (not H2.Found, "parallel segments do not intersect");
      Check (Hits.Count = 2, "overlapping rects have 2 edge hits");
      Check (Classify_No_Intersection (A, B) = Overlapping,
             "crossing rects Overlapping");
   end;

   ---------------------------------------------------------------------
   Section ("5. Collect_Scanline_Ys / Build_Local_Minima");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon := Make_Rectangle (0.0, 0.0, 4.0, 2.0);
      B : constant Polygon := Make_Rectangle (1.0, 1.0, 5.0, 3.0);
      S : constant Polygon_Set := Singleton (A);
      C : constant Polygon_Set := Singleton (B);
      Ys : constant Scanline_List := Collect_Scanline_Ys (S, C);
      Lm : constant Scanline_List := Build_Local_Minima (S, C);
   begin
      Check (Ys.Count >= 4, "scanlines cover distinct Ys");
      Check (Ys.Ys (1) <= Ys.Ys (Ys.Count), "Ys sorted ascending");
      Check (Lm.Count = Ys.Count, "Build_Local_Minima matches Collect");
      Check (Approx (Ys.Ys (1), 0.0), "lowest scanline is 0");
      Check (Approx (Ys.Ys (Ys.Count), 3.0), "highest scanline is 3");
   end;

   ---------------------------------------------------------------------
   Section ("6. Sweep_Process_Scanbeam");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 10.0);
      B : constant Polygon := Make_Rectangle (5.0, 5.0, 15.0, 15.0);
      Beam_Mid : constant Scanbeam := (Y_Bot => 4.0, Y_Top => 6.0);
      Beam_Low : constant Scanbeam := (Y_Bot => 0.0, Y_Top => 1.0);
      Hits_Mid : constant Intersection_List :=
        Sweep_Process_Scanbeam (A, B, Beam_Mid);
      Hits_Low : constant Intersection_List :=
        Sweep_Process_Scanbeam (A, B, Beam_Low);
   begin
      Check (Hits_Mid.Count >= 1, "mid scanbeam finds intersection(s)");
      Check (Hits_Low.Count = 0, "low empty scanbeam finds none");
      Check (Hits_Mid.Items (1).Point.Y > 4.0, "hit Y above beam bottom");
   end;

   ---------------------------------------------------------------------
   Section ("7. Vatti_Intersection rect ∩ rect");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 10.0);
      B : constant Polygon := Make_Rectangle (5.0, 5.0, 15.0, 15.0);
      R : constant Polygon_Set := Vatti_Intersection (A, B);
   begin
      Check (R.Count = 1, "overlap intersection yields one poly");
      Check (R.Polys (1).Count = 4, "intersection is a quad");
      Check (Approx (Set_Absolute_Area (R), 25.0, 0.5),
             "intersection area ~25");
      Check (Set_Has_Vertex (R, (5.0, 5.0)), "contains (5,5)");
      Check (Set_Has_Vertex (R, (10.0, 10.0)), "contains (10,10)");
   end;

   ---------------------------------------------------------------------
   Section ("8. Vatti_Union overlapping rects");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 10.0);
      B : constant Polygon := Make_Rectangle (5.0, 5.0, 15.0, 15.0);
      R : constant Polygon_Set := Vatti_Union (A, B);
   begin
      Check (R.Count = 1, "overlapping union yields one poly");
      Check (R.Polys (1).Count >= 6, "union has >= 6 vertices");
      Check (Approx (Set_Absolute_Area (R), 175.0, 1.0),
             "union area ~175");
      Check (Set_Has_Vertex (R, (0.0, 0.0)), "union keeps (0,0)");
      Check (Set_Has_Vertex (R, (15.0, 15.0)), "union keeps (15,15)");
   end;

   ---------------------------------------------------------------------
   Section ("9. Vatti_Difference");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 10.0);
      B : constant Polygon := Make_Rectangle (5.0, 5.0, 15.0, 15.0);
      R : constant Polygon_Set := Vatti_Difference (A, B);
   begin
      Check (R.Count = 1, "corner difference yields one poly");
      Check (Approx (Set_Absolute_Area (R), 75.0, 1.0),
             "difference area ~75");
      Check (Set_Has_Vertex (R, (0.0, 0.0)), "keeps far corner");
      Check (Set_Has_Vertex (R, (5.0, 5.0))
             or else Set_Has_Vertex (R, (5.0, 10.0)),
             "keeps cut boundary");
   end;

   ---------------------------------------------------------------------
   Section ("10. Vatti_Xor");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 10.0);
      B : constant Polygon := Make_Rectangle (5.0, 5.0, 15.0, 15.0);
      R : constant Polygon_Set := Vatti_Xor (A, B);
   begin
      Check (R.Count >= 1, "xor yields at least one piece");
      Check (Approx (Set_Absolute_Area (R), 150.0, 2.0),
             "xor area ~150 (175-25)");
      Check (not Point_In_Set ((7.5, 7.5), R),
             "overlap center not in xor result");
   end;

   ---------------------------------------------------------------------
   Section ("11. Triangle ∩ rect");
   ---------------------------------------------------------------------
   declare
      T : constant Polygon :=
        Make_Triangle ((0.0, 0.0), (10.0, 0.0), (5.0, 10.0));
      R : constant Polygon := Make_Rectangle (2.0, 2.0, 8.0, 8.0);
      Out_S : constant Polygon_Set := Vatti_Intersection (T, R);
   begin
      Check (Out_S.Count = 1, "triangle∩rect one poly");
      Check (Out_S.Polys (1).Count >= 3, "result has >= 3 verts");
      Check (Set_Absolute_Area (Out_S) > 1.0, "non-empty area");
      Check (Point_In_Set ((5.0, 4.0), Out_S)
             or else Set_Has_Vertex (Out_S, (5.0, 4.0)),
             "interior/boundary point of overlap present");
   end;

   ---------------------------------------------------------------------
   Section ("12. Disjoint → empty intersection / subject inside clip");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon := Make_Rectangle (0.0, 0.0, 2.0, 2.0);
      B : constant Polygon := Make_Rectangle (5.0, 5.0, 8.0, 8.0);
      Big : constant Polygon := Make_Rectangle (0.0, 0.0, 20.0, 20.0);
      Small : constant Polygon := Make_Rectangle (5.0, 5.0, 10.0, 10.0);
      Empty : constant Polygon_Set := Vatti_Intersection (A, B);
      Inside : constant Polygon_Set := Vatti_Intersection (Small, Big);
      Disj_U : constant Polygon_Set := Vatti_Union (A, B);
   begin
      Check (Empty.Count = 0, "disjoint intersection empty");
      Check (Classify_No_Intersection (A, B) = Disjoint, "classify Disjoint");
      Check (Inside.Count = 1, "subject inside clip → subject");
      Check (Approx (Set_Absolute_Area (Inside), 25.0, 0.5),
             "inside intersection area 25");
      Check (Disj_U.Count = 2, "disjoint union keeps both");
   end;

   ---------------------------------------------------------------------
   Section ("13. Boolean_Operation via Vatti_Clip + set wrappers");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 10.0);
      B : constant Polygon := Make_Rectangle (5.0, 5.0, 15.0, 15.0);
      SA : constant Polygon_Set := Singleton (A);
      SB : constant Polygon_Set := Singleton (B);
      RI : constant Polygon_Set := Vatti_Clip (A, B, Intersection);
      RU : constant Polygon_Set := Vatti_Clip (SA, SB, Union);
      RD : constant Polygon_Set := Vatti_Difference (SA, SB);
      RX : constant Polygon_Set := Vatti_Xor (SA, SB);
   begin
      Check (RI.Count = 1, "Vatti_Clip Intersection");
      Check (RU.Count = 1, "set Vatti_Clip Union");
      Check (RD.Count >= 1, "set Vatti_Difference non-empty");
      Check (RX.Count >= 1, "set Vatti_Xor non-empty");
      Check (Approx (Set_Absolute_Area (RI), 25.0, 0.5), "clip∩ area");
   end;

   ---------------------------------------------------------------------
   Section ("14. Multi-polygon Make_Set inputs");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon := Make_Rectangle (0.0, 0.0, 2.0, 2.0);
      B : constant Polygon := Make_Rectangle (4.0, 0.0, 6.0, 2.0);
      C : constant Polygon := Make_Rectangle (1.0, 0.5, 5.0, 1.5);
      Subj : constant Polygon_Set := Make_Set (A, B);
      Clip : constant Polygon_Set := Singleton (C);
      R : constant Polygon_Set := Vatti_Intersection (Subj, Clip);
   begin
      Check (Subj.Count = 2, "Make_Set has two polys");
      Check (R.Count >= 1, "multi subject ∩ clip non-empty");
      Check (Set_Absolute_Area (R) > 0.5, "multi intersection has area");
   end;

   ---------------------------------------------------------------------
   Section ("15. Ensure_Orientation / Signed_Area / exceptions");
   ---------------------------------------------------------------------
   declare
      CW : constant Polygon := Make_Rectangle (0.0, 0.0, 2.0, 2.0);
      Ens : constant Polygon :=
        Ensure_Orientation (CW, Counter_Clockwise);
      Raised : Boolean := False;
   begin
      Check (Signed_Area (CW) < 0.0, "CW negative signed area");
      Check (Polygon_Orientation (Ens) = Counter_Clockwise,
             "Ensure_Orientation to CCW");
      Check (Approx (abs (Signed_Area (CW)), 4.0), "|area| of 2x2 is 4");
      begin
         raise Invalid_Argument;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument named exception");
      Raised := False;
      begin
         raise Degenerate_Geometry;
      exception
         when Degenerate_Geometry =>
            Raised := True;
      end;
      Check (Raised, "Degenerate_Geometry named exception");
      Raised := False;
      begin
         raise Capacity_Exceeded;
      exception
         when Capacity_Exceeded =>
            Raised := True;
      end;
      Check (Raised, "Capacity_Exceeded named exception");
   end;

   ---------------------------------------------------------------------
   Section ("16. CCW inputs normalized by clip");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon :=
        Make_Rectangle (0.0, 0.0, 8.0, 8.0, Counter_Clockwise);
      B : constant Polygon :=
        Make_Rectangle (4.0, 4.0, 12.0, 12.0, Counter_Clockwise);
      R : constant Polygon_Set := Vatti_Intersection (A, B);
   begin
      Check (R.Count = 1, "CCW inputs still intersect to one poly");
      Check (R.Polys (1).Count = 4, "normalized intersection is quad");
      Check (Set_Has_Vertex (R, (4.0, 4.0)), "contains (4,4)");
      Check (Set_Has_Vertex (R, (8.0, 8.0)), "contains (8,8)");
   end;

   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   pragma Assert (Fail_Count = 0);
   if Fail_Count > 0 then
      raise Program_Error;
   end if;
end Tests;
