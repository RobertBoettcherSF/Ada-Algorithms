--  Standalone test suite for Weiler_Atherton (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Weiler_Atherton; use Weiler_Atherton;

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

   --  True when Poly contains a vertex near P (order-independent).
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

   function Total_Vertices (R : Clip_Result) return Natural is
      N : Natural := 0;
   begin
      for I in 1 .. R.Count loop
         N := N + Natural (R.Polys (I).Count);
      end loop;
      return N;
   end Total_Vertices;

begin
   Put_Line ("Weiler_Atherton test suite");
   Put_Line ("==========================");

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
      Check (Polygon_Orientation (R) = Clockwise,
             "Make_Rectangle default is clockwise");
      Check (Polygon_Orientation (T) = Clockwise,
             "Make_Triangle default is clockwise");
      Check (Approx_Vec (R.Verts (1), (0.0, 0.0)), "rect lower-left first");
   end;

   ---------------------------------------------------------------------
   Section ("3. Signed_Area / Orient_Clockwise / Ensure_Orientation");
   ---------------------------------------------------------------------
   declare
      CW  : constant Polygon := Make_Rectangle (0.0, 0.0, 2.0, 2.0, Clockwise);
      CCW : constant Polygon :=
        Make_Rectangle (0.0, 0.0, 2.0, 2.0, Counter_Clockwise);
      Fixed : constant Polygon := Orient_Clockwise (CCW);
      Ens   : constant Polygon :=
        Ensure_Orientation (CW, Counter_Clockwise);
   begin
      Check (Signed_Area (CW) < 0.0, "CW rectangle has negative signed area");
      Check (Signed_Area (CCW) > 0.0, "CCW rectangle has positive signed area");
      Check (Approx (abs (Signed_Area (CW)), 4.0), "|area| of 2x2 is 4");
      Check (Polygon_Orientation (Fixed) = Clockwise,
             "Orient_Clockwise flips CCW to CW");
      Check (Polygon_Orientation (Ens) = Counter_Clockwise,
             "Ensure_Orientation to CCW");
      Check (Fixed.Count = 4, "orientation helpers preserve count");
   end;

   ---------------------------------------------------------------------
   Section ("4. Point_In_Polygon / Point_On_Boundary");
   ---------------------------------------------------------------------
   declare
      R : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 10.0);
   begin
      Check (Point_In_Polygon ((5.0, 5.0), R), "center is inside");
      Check (not Point_In_Polygon ((15.0, 5.0), R), "outside to the right");
      Check (not Point_In_Polygon ((-1.0, -1.0), R), "outside corner");
      Check (Point_On_Boundary ((0.0, 5.0), R), "left edge is boundary");
      Check (not Point_In_Polygon ((0.0, 5.0), R),
             "boundary counted outside for labeling");
      Check (not Point_On_Boundary ((5.0, 5.0), R), "center not on boundary");
   end;

   ---------------------------------------------------------------------
   Section ("5. Segment_Intersection");
   ---------------------------------------------------------------------
   declare
      H1 : constant Seg_Intersect_Result :=
        Segment_Intersection
          ((0.0, 0.0), (10.0, 0.0), (5.0, -1.0), (5.0, 1.0));
      H2 : constant Seg_Intersect_Result :=
        Segment_Intersection
          ((0.0, 0.0), (1.0, 0.0), (0.0, 1.0), (1.0, 1.0));
      H3 : constant Seg_Intersect_Result :=
        Segment_Intersection
          ((0.0, 0.0), (2.0, 2.0), (0.0, 2.0), (2.0, 0.0));
   begin
      Check (H1.Found, "crossing segments intersect");
      Check (Approx_Vec (H1.Point, (5.0, 0.0)), "intersection at (5,0)");
      Check (not H2.Found, "parallel segments do not intersect");
      Check (H3.Found, "diagonal X intersects");
      Check (Approx_Vec (H3.Point, (1.0, 1.0)), "X center at (1,1)");
   end;

   ---------------------------------------------------------------------
   Section ("6. Find_All_Intersections rect vs rect");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 10.0);
      B : constant Polygon := Make_Rectangle (5.0, 5.0, 15.0, 15.0);
      H : constant Intersection_List := Find_All_Intersections (A, B);
   begin
      Check (H.Count = 2, "overlapping rects yield 2 intersections");
      Check (Has_Vertex
               ((Verts => [H.Items (1).Point, H.Items (2).Point,
                           others => (0.0, 0.0)],
                 Count => 2),
                (10.0, 5.0))
             or else Near_Point (H.Items (1).Point, (10.0, 5.0))
             or else Near_Point (H.Items (2).Point, (10.0, 5.0)),
             "one intersection near (10,5)");
      Check
        (Near_Point (H.Items (1).Point, (5.0, 10.0))
         or else Near_Point (H.Items (2).Point, (5.0, 10.0))
         or else Near_Point (H.Items (1).Point, (10.0, 5.0)),
         "intersections at overlap corners");
      Check (H.Items (1).Kind = Unknown, "raw hits leave Kind Unknown");
   end;

   ---------------------------------------------------------------------
   Section ("7. Build_Linked_Polygon_Lists + inbound/outbound");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 10.0);
      B : constant Polygon := Make_Rectangle (5.0, 5.0, 15.0, 15.0);
      L : constant Linked_Polygon_Lists :=
        Build_Linked_Polygon_Lists (A, B);
      Inb : constant Intersection_List := Collect_Inbound_Intersections (L);
      Outb : constant Intersection_List := Collect_Outbound_Intersections (L);
   begin
      Check (L.Clip_Count > 4, "clip list grew with intersections");
      Check (L.Subject_Count > 4, "subject list grew with intersections");
      Check (L.Clip_Head = 1 and then L.Subject_Head = 1, "heads at 1");
      Check (Inb.Count = 1, "exactly one inbound intersection");
      Check (Outb.Count = 1, "exactly one outbound intersection");
      Check (Inb.Items (1).Kind = Inbound, "inbound kind tagged");
      Check (Outb.Items (1).Kind = Outbound, "outbound kind tagged");
   end;

   ---------------------------------------------------------------------
   Section ("8. Weiler_Atherton_Clip rect ∩ rect");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 10.0);
      B : constant Polygon := Make_Rectangle (5.0, 5.0, 15.0, 15.0);
      R : constant Clip_Result := Weiler_Atherton_Clip (A, B);
   begin
      Check (R.Count = 1, "convex clip yields one polygon");
      Check (R.Polys (1).Count = 4, "intersection is a quadrilateral");
      Check (Has_Vertex (R.Polys (1), (5.0, 5.0)), "contains (5,5)");
      Check (Has_Vertex (R.Polys (1), (10.0, 5.0)), "contains (10,5)");
      Check (Has_Vertex (R.Polys (1), (5.0, 10.0)), "contains (5,10)");
      Check (Has_Vertex (R.Polys (1), (10.0, 10.0)), "contains (10,10)");
      Check (abs (Signed_Area (R.Polys (1))) > 1.0,
             "result has positive area magnitude");
   end;

   ---------------------------------------------------------------------
   Section ("9. Triangle ∩ rectangle");
   ---------------------------------------------------------------------
   declare
      Clip : constant Polygon := Make_Rectangle (0.0, 0.0, 4.0, 4.0);
      --  Triangle straddling the top of the square.
      Subj : constant Polygon :=
        Make_Triangle ((1.0, 2.0), (1.0, 6.0), (3.0, 2.0));
      R : constant Clip_Result := Weiler_Atherton_Clip (Clip, Subj);
   begin
      Check (R.Count >= 1, "triangle∩rect produces at least one piece");
      Check (R.Polys (1).Count >= 3, "result has >= 3 vertices");
      Check (Total_Vertices (R) >= 3, "total vertices recorded");
      --  Peak (1,6) is outside clip; clipped poly should stay y <= 4.
      declare
         Max_Y : Real := Real'First;
      begin
         for I in 1 .. R.Polys (1).Count loop
            if R.Polys (1).Verts (I).Y > Max_Y then
               Max_Y := R.Polys (1).Verts (I).Y;
            end if;
         end loop;
         Check (Max_Y <= 4.0 + 1.0E-3, "clipped vertices y <= clip top");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("10. Subject inside clip (B_In_A)");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 10.0);
      B : constant Polygon := Make_Rectangle (2.0, 2.0, 4.0, 4.0);
      Class : constant Overlap_Class := Classify_No_Intersection (A, B);
      R : constant Clip_Result := Weiler_Atherton_Clip (A, B);
      M : constant Clip_Result := Weiler_Atherton_Merge (A, B);
   begin
      Check (Class = B_In_A, "small inside large classified B_In_A");
      Check (Find_All_Intersections (A, B).Count = 0, "no edge hits");
      Check (R.Count = 1, "clip returns the subject");
      Check (Same_Polygon (Orient_Clockwise (R.Polys (1)),
                           Orient_Clockwise (B)),
             "clip result equals subject");
      Check (M.Count = 1, "merge returns the clip");
      Check (Same_Polygon (Orient_Clockwise (M.Polys (1)),
                           Orient_Clockwise (A)),
             "merge result equals clip");
   end;

   ---------------------------------------------------------------------
   Section ("11. Clip inside subject (A_In_B)");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon := Make_Rectangle (2.0, 2.0, 4.0, 4.0);
      B : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 10.0);
      Class : constant Overlap_Class := Classify_No_Intersection (A, B);
      R : constant Clip_Result := Weiler_Atherton_Clip (A, B);
      M : constant Clip_Result := Weiler_Atherton_Merge (A, B);
   begin
      Check (Class = A_In_B, "clip inside subject classified A_In_B");
      Check (R.Count = 1, "clip returns the clip polygon");
      Check (Same_Polygon (Orient_Clockwise (R.Polys (1)),
                           Orient_Clockwise (A)),
             "clip result equals clip A");
      Check (M.Count = 1, "merge returns the subject");
      Check (Same_Polygon (Orient_Clockwise (M.Polys (1)),
                           Orient_Clockwise (B)),
             "merge result equals subject B");
   end;

   ---------------------------------------------------------------------
   Section ("12. Disjoint polygons");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon := Make_Rectangle (0.0, 0.0, 1.0, 1.0);
      B : constant Polygon := Make_Rectangle (3.0, 3.0, 4.0, 4.0);
      Class : constant Overlap_Class := Classify_No_Intersection (A, B);
      R : constant Clip_Result := Weiler_Atherton_Clip (A, B);
      M : constant Clip_Result := Weiler_Atherton_Merge (A, B);
   begin
      Check (Class = Disjoint, "far rectangles are Disjoint");
      Check (R.Count = 0, "clip of disjoint is empty");
      Check (M.Count = 2, "merge of disjoint returns both");
      Check (Vertex_Count_Of (M.Polys (1)) = 4, "first merge poly is quad");
      Check (Vertex_Count_Of (M.Polys (2)) = 4, "second merge poly is quad");
   end;

   ---------------------------------------------------------------------
   Section ("13. Weiler_Atherton_Merge overlapping rects");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 10.0);
      B : constant Polygon := Make_Rectangle (5.0, 5.0, 15.0, 15.0);
      M : constant Clip_Result := Weiler_Atherton_Merge (A, B);
   begin
      Check (M.Count = 1, "merge of overlapping convex yields one poly");
      Check (M.Polys (1).Count >= 6, "union outline has >= 6 vertices");
      Check (Has_Vertex (M.Polys (1), (0.0, 0.0))
             or else Has_Vertex (M.Polys (1), (0.0, 10.0)),
             "union keeps a clip corner");
      Check (Has_Vertex (M.Polys (1), (15.0, 15.0))
             or else Has_Vertex (M.Polys (1), (15.0, 5.0)),
             "union keeps a subject corner");
      Check (abs (Signed_Area (M.Polys (1))) >
             abs (Signed_Area (A)),
             "union area magnitude exceeds clip alone");
   end;

   ---------------------------------------------------------------------
   Section ("14. Concave clip may yield multiple pieces");
   ---------------------------------------------------------------------
   declare
      --  C-shaped clip (concave), clockwise:
      --  outer notch opening to the right.
      C : Polygon;
      S : constant Polygon := Make_Rectangle (2.0, 1.0, 5.0, 5.0);
      R : Clip_Result;
   begin
      C.Count := 8;
      C.Verts (1) := (0.0, 0.0);
      C.Verts (2) := (0.0, 6.0);
      C.Verts (3) := (3.0, 6.0);
      C.Verts (4) := (3.0, 4.0);
      C.Verts (5) := (1.0, 4.0);
      C.Verts (6) := (1.0, 2.0);
      C.Verts (7) := (3.0, 2.0);
      C.Verts (8) := (3.0, 0.0);
      C := Orient_Clockwise (C);
      R := Weiler_Atherton_Clip (C, S);
      Check (R.Count >= 2, "concave clip produces multiple pieces");
      Check (Total_Vertices (R) >= 3, "pieces have vertices");
      --  Prefer multiple pieces when the C-notch splits the subject.
      Check (R.Count = 2, "C-notch splits subject into two quads");
      declare
         All_Insideish : Boolean := True;
      begin
         for P in 1 .. R.Count loop
            for V in 1 .. R.Polys (P).Count loop
               declare
                  Q : constant Vec2 := R.Polys (P).Verts (V);
               begin
                  if not (Point_In_Polygon (Q, C)
                          or else Point_On_Boundary (Q, C)
                          or else Point_In_Polygon (Q, S)
                          or else Point_On_Boundary (Q, S))
                  then
                     All_Insideish := False;
                  end if;
               end;
            end loop;
         end loop;
         Check (All_Insideish,
                "result vertices lie on/in clip or subject");
      end;
   end;

   ---------------------------------------------------------------------
   Section ("15. Classify Overlapping + exception smoke");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon := Make_Rectangle (0.0, 0.0, 10.0, 10.0);
      B : constant Polygon := Make_Rectangle (5.0, 5.0, 15.0, 15.0);
      Raised : Boolean := False;
   begin
      Check (Classify_No_Intersection (A, B) = Overlapping,
             "crossing rects classified Overlapping");
      begin
         raise Invalid_Argument;
      exception
         when Invalid_Argument =>
            Raised := True;
      end;
      Check (Raised, "Invalid_Argument is a named exception");
      Raised := False;
      begin
         raise Degenerate_Geometry;
      exception
         when Degenerate_Geometry =>
            Raised := True;
      end;
      Check (Raised, "Degenerate_Geometry is a named exception");
      Raised := False;
      begin
         raise Capacity_Exceeded;
      exception
         when Capacity_Exceeded =>
            Raised := True;
      end;
      Check (Raised, "Capacity_Exceeded is a named exception");
   end;

   ---------------------------------------------------------------------
   Section ("16. CCW input normalized by clip");
   ---------------------------------------------------------------------
   declare
      A : constant Polygon :=
        Make_Rectangle (0.0, 0.0, 8.0, 8.0, Counter_Clockwise);
      B : constant Polygon :=
        Make_Rectangle (4.0, 4.0, 12.0, 12.0, Counter_Clockwise);
      R : constant Clip_Result := Weiler_Atherton_Clip (A, B);
   begin
      Check (R.Count = 1, "CCW inputs still clip to one poly");
      Check (R.Polys (1).Count = 4, "normalized intersection is quad");
      Check (Has_Vertex (R.Polys (1), (4.0, 4.0)), "contains (4,4)");
      Check (Has_Vertex (R.Polys (1), (8.0, 8.0)), "contains (8,8)");
   end;

   New_Line;
   Put_Line ("----------------------------------------");
   Put_Line ("Passed:" & Pass_Count'Image & "  Failed:" & Fail_Count'Image);
   pragma Assert (Fail_Count = 0);
end Tests;
