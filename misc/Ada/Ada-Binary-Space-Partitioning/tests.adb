--  Standalone test suite for Binary_Space_Partitioning (main program).

pragma Ada_2022;

with Ada.Text_IO; use Ada.Text_IO;
with Binary_Space_Partitioning; use Binary_Space_Partitioning;

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


   --  Vertical wall quad with first edge vertical so the BSP splitter
   --  is the wall plane. Front faces +X when X1 > X0 (thin slab).
   function Make_VWall
     (X0, Y0, X1, Y1 : Real; Tag : Natural) return Polygon
   is
      V : Vertex_Array := [others => (0.0, 0.0)];
   begin
      --  CCW: bottom-left up the left edge first (if X0 < X1, left edge
      --  goes up → leftward normal points -X; use right edge first for +X).
      --  Order: (X0,Y0) -> (X0,Y1) -> (X1,Y1) -> (X1,Y0) gives normal -X.
      --  For Front = +X, reverse the first edge: start at (X0,Y1) go down,
      --  but keep CCW overall: (X1,Y0)->(X1,Y1)->(X0,Y1)->(X0,Y0) when thin
      --  wall has X1≈X0+eps... Simpler: (X0,Y1)->(X0,Y0)->(X1,Y0)->(X1,Y1)
      --  first edge down the left side → Normal = +X.
      V (1) := (X0, Y1);
      V (2) := (X0, Y0);
      V (3) := (X1, Y0);
      V (4) := (X1, Y1);
      return Make_Polygon (V, 4, Tag);
   end Make_VWall;

   function Tag_In_Traversal
     (T : BSP_Tree; R : Traversal_Result; Tag : Natural) return Boolean
   is
   begin
      for I in 1 .. R.Count loop
         if T.Polys (R.Entries (I).Poly_Id).Tag = Tag then
            return True;
         end if;
      end loop;
      return False;
   end Tag_In_Traversal;

   function First_Tag_Index
     (T : BSP_Tree; R : Traversal_Result; Tag : Natural) return Natural
   is
   begin
      for I in 1 .. R.Count loop
         if T.Polys (R.Entries (I).Poly_Id).Tag = Tag then
            return I;
         end if;
      end loop;
      return 0;
   end First_Tag_Index;

begin
   Put_Line ("Binary_Space_Partitioning test suite");
   Put_Line ("====================================");

   ---------------------------------------------------------------------
   Section ("1. Vector helpers / Near / Dot / Cross_Z / Normalize");
   ---------------------------------------------------------------------
   declare
      A : constant Vec2 := (3.0, 4.0);
      B : constant Vec2 := (0.0, 0.0);
      S : constant Vec2 := A + (1.0, 1.0);
      D : constant Vec2 := A - (1.0, 1.0);
      M : constant Vec2 := 2.0 * (1.0, 2.0);
      U : Vec2;
      Raised : Boolean := False;
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
      Check (Approx (Norm (A), 5.0), "Norm 3-4-5");
      U := Normalize ((0.0, 4.0));
      Check (Approx_Vec (U, (0.0, 1.0)), "Normalize vertical");
      begin
         U := Normalize ((0.0, 0.0));
      exception
         when Degenerate_Geometry =>
            Raised := True;
      end;
      Check (Raised, "Normalize zero raises Degenerate_Geometry");
   end;

   ---------------------------------------------------------------------
   Section ("2. Make_Segment / Make_Polygon / Make_Rect_Polygon");
   ---------------------------------------------------------------------
   declare
      Seg : constant Segment := Make_Segment ((0.0, 0.0), (3.0, 4.0));
      V   : Vertex_Array := [others => (0.0, 0.0)];
      P   : Polygon;
      R   : Polygon;
   begin
      V (1) := (0.0, 0.0);
      V (2) := (1.0, 0.0);
      V (3) := (0.0, 1.0);
      P := Make_Polygon (V, 3, Tag => 7);
      R := Make_Rect_Polygon (0.0, 0.0, 2.0, 3.0, Tag => 9);
      Check (Approx (Length (Seg), 5.0), "segment length 5");
      Check (P.Count = 3, "triangle vertex count");
      Check (P.Tag = 7, "polygon tag retained");
      Check (R.Count = 4, "rect polygon has 4 verts");
      Check (R.Tag = 9, "rect tag retained");
      Check (Approx_Vec (R.Verts (1), (0.0, 0.0)), "rect SW corner");
      Check (Approx_Vec (R.Verts (3), (2.0, 3.0)), "rect NE corner");
      Check (Near_Point (Seg.P0, (0.0, 0.0)), "segment P0");
   end;

   ---------------------------------------------------------------------
   Section ("3. Plane construction / Classify_Point");
   ---------------------------------------------------------------------
   declare
      Pl : Plane2;
      Raised : Boolean := False;
   begin
      Pl := Make_Plane_From_Points ((0.0, 0.0), (1.0, 0.0));
      --  Leftward normal of +X edge is +Y → Front is above
      Check (Classify_Point ((0.5, 1.0), Pl) = Front, "point above X-axis Front");
      Check (Classify_Point ((0.5, -1.0), Pl) = Back, "point below X-axis Back");
      Check (Classify_Point ((0.5, 0.0), Pl) = On_Plane, "point on X-axis On");
      Check (Approx (Signed_Distance ((0.0, 2.0), Pl), 2.0), "signed dist +2");
      Pl := Make_Axis_Aligned_Plane (Vertical => True, Coord => 5.0);
      Check (Classify_Point ((6.0, 0.0), Pl) = Front, "right of X=5 Front");
      Check (Classify_Point ((4.0, 0.0), Pl) = Back, "left of X=5 Back");
      Check (Classify_Point ((5.0, 3.0), Pl) = On_Plane, "on X=5 On");
      Pl := Make_Axis_Aligned_Plane (Vertical => False, Coord => -1.0);
      Check (Classify_Point ((0.0, 0.0), Pl) = Front, "above Y=-1 Front");
      begin
         Pl := Make_Plane_From_Points ((1.0, 1.0), (1.0, 1.0));
      exception
         when Degenerate_Geometry =>
            Raised := True;
      end;
      Check (Raised, "degenerate plane points raise");
   end;

   ---------------------------------------------------------------------
   Section ("4. Relate_Polygon / Classify_Polygon");
   ---------------------------------------------------------------------
   declare
      Pl  : constant Plane2 := Make_Axis_Aligned_Plane (True, 0.0);
      PF  : constant Polygon := Make_Rect_Polygon (1.0, 0.0, 2.0, 1.0);
      PB  : constant Polygon := Make_Rect_Polygon (-2.0, 0.0, -1.0, 1.0);
      PS  : constant Polygon := Make_Rect_Polygon (-1.0, 0.0, 1.0, 1.0);
      V   : Vertex_Array := [others => (0.0, 0.0)];
      Pon : Polygon;
   begin
      V (1) := (0.0, 0.0);
      V (2) := (0.0, 1.0);
      V (3) := (0.0, 2.0);
      Pon := Make_Polygon (V, 3);
      Check (Relate_Polygon (PF, Pl) = Wholly_Front, "rect right Wholly_Front");
      Check (Relate_Polygon (PB, Pl) = Wholly_Back, "rect left Wholly_Back");
      Check (Relate_Polygon (PS, Pl) = Straddling, "rect across Straddling");
      Check (Relate_Polygon (Pon, Pl) = Coplanar, "vertical edge Coplanar");
      Check (Classify_Polygon (PF, Pl) = Front, "Classify_Polygon Front");
      Check (Classify_Polygon (PB, Pl) = Back, "Classify_Polygon Back");
      Check (Classify_Polygon (Pon, Pl) = On_Plane, "Classify_Polygon On");
   end;

   ---------------------------------------------------------------------
   Section ("5. Split_Segment against a plane");
   ---------------------------------------------------------------------
   declare
      Pl : constant Plane2 := Make_Axis_Aligned_Plane (True, 0.0);
      R  : Split_Segment_Result;
   begin
      R := Split_Segment (Make_Segment ((-1.0, 0.0), (1.0, 0.0)), Pl);
      Check (R.Front_Count = 1 and R.Back_Count = 1, "straddle yields both sides");
      Check (Approx_Vec (R.Front_Seg.P0, (0.0, 0.0))
             or else Approx_Vec (R.Front_Seg.P1, (0.0, 0.0)),
             "split point near origin");
      R := Split_Segment (Make_Segment ((1.0, 0.0), (2.0, 0.0)), Pl);
      Check (R.Front_Count = 1 and R.Back_Count = 0, "wholly front segment");
      R := Split_Segment (Make_Segment ((-2.0, 1.0), (-1.0, 1.0)), Pl);
      Check (R.Back_Count = 1 and R.Front_Count = 0, "wholly back segment");
      R := Split_Segment (Make_Segment ((0.0, 0.0), (0.0, 2.0)), Pl);
      Check (R.On_Count = 1, "coplanar segment On");
      Check (Approx (Length (R.On_Seg), 2.0), "on-seg length preserved");
   end;

   ---------------------------------------------------------------------
   Section ("6. Split_Polygon (Fuchs-style cut)");
   ---------------------------------------------------------------------
   declare
      Pl : constant Plane2 := Make_Axis_Aligned_Plane (True, 0.0);
      P  : constant Polygon := Make_Rect_Polygon (-1.0, -1.0, 1.0, 1.0, 1);
      R  : Split_Polygon_Result;
      Q  : constant Polygon := Make_Rect_Polygon (1.0, 0.0, 2.0, 1.0, 2);
      R2 : Split_Polygon_Result;
   begin
      R := Split_Polygon (P, Pl);
      Check (R.Front.Count >= 3, "straddle front remnant ≥3");
      Check (R.Back.Count >= 3, "straddle back remnant ≥3");
      Check (Relate_Polygon (R.Front, Pl) /= Wholly_Back, "front not back");
      Check (Relate_Polygon (R.Back, Pl) /= Wholly_Front, "back not front");
      Check (R.Front.Tag = 1 and R.Back.Tag = 1, "tag preserved through split");
      R2 := Split_Polygon (Q, Pl);
      Check (R2.Front.Count = 4 and R2.Back.Count = 0, "wholly front unsplit");
      Check (R2.On.Count = 0, "no coplanar remnant for front rect");
   end;

   ---------------------------------------------------------------------
   Section ("7. Build_BSP empty / single / simple scene");
   ---------------------------------------------------------------------
   declare
      Empty : constant BSP_Tree := Build_BSP ([others => <>], 0);
      List  : Polygon_List;
      T1, T2 : BSP_Tree;
   begin
      Check (Is_Empty_Tree (Empty), "empty input → empty tree");
      Check (Node_Count (Empty) = 0, "empty node count 0");
      Check (Polygon_Count (Empty) = 0, "empty poly count 0");
      List (1) := Make_Rect_Polygon (0.0, 0.0, 1.0, 1.0, Tag => 1);
      T1 := Build_BSP (List, 1, First_Polygon);
      Check (not Is_Empty_Tree (T1), "single polygon builds non-empty");
      Check (Node_Count (T1) >= 1, "single poly ≥1 node");
      Check (Polygon_Count (T1) >= 1, "single poly ≥1 stored poly");
      List (2) := Make_Rect_Polygon (2.0, 0.0, 3.0, 1.0, Tag => 2);
      T2 := Build_BSP (List, 2, Least_Split);
      Check (not Is_Empty_Tree (T2), "two-poly tree non-empty");
      Check (Node_Count (T2) >= 2, "two-poly ≥2 nodes");
      Check (Polygon_Count (T2) >= 2, "two-poly stores both");
   end;

   ---------------------------------------------------------------------
   Section ("8. Build_BSP overlapping / straddling scene");
   ---------------------------------------------------------------------
   declare
      List : Polygon_List;
      T    : BSP_Tree;
   begin
      --  Two overlapping AABBs that force a split
      List (1) := Make_Rect_Polygon (0.0, 0.0, 2.0, 1.0, Tag => 10);
      List (2) := Make_Rect_Polygon (1.0, -1.0, 3.0, 2.0, Tag => 11);
      T := Build_BSP (List, 2, Least_Split);
      Check (not Is_Empty_Tree (T), "overlapping scene builds");
      Check (Polygon_Count (T) >= 2, "overlapping stores ≥2 (maybe more after split)");
      Check (Node_Count (T) >= 1, "overlapping has nodes");
      --  Axis-aligned "rooms": left wall and right wall
      List (1) := Make_Rect_Polygon (0.0, 0.0, 0.1, 2.0, Tag => 20);
      List (2) := Make_Rect_Polygon (3.0, 0.0, 3.1, 2.0, Tag => 21);
      List (3) := Make_Rect_Polygon (0.0, 0.0, 3.1, 0.1, Tag => 22);
      T := Build_BSP (List, 3, Least_Split);
      Check (Node_Count (T) >= 3, "room walls ≥3 nodes");
      Check (Polygon_Count (T) >= 3, "room walls ≥3 polys");
      Check (not Is_Empty_Tree (T), "room tree non-empty");
   end;

   ---------------------------------------------------------------------
   Section ("9. Back-to-front painter's traversal order");
   ---------------------------------------------------------------------
   declare
      List : Polygon_List;
      T    : BSP_Tree;
      R    : Traversal_Result;
      Eye  : constant Vec2 := (5.0, 0.5);
      I1, I2 : Natural;
   begin
      --  Two vertical walls; eye to the right → left poly farther
      List (1) := Make_VWall (0.0, 0.0, 0.2, 1.0, Tag => 1);
      List (2) := Make_VWall (2.0, 0.0, 2.2, 1.0, Tag => 2);
      T := Build_BSP (List, 2, First_Polygon);
      R := Traverse_Back_To_Front (T, Eye);
      Check (R.Count >= 2, "B2F emits ≥2 entries");
      Check (Tag_In_Traversal (T, R, 1), "B2F contains tag 1");
      Check (Tag_In_Traversal (T, R, 2), "B2F contains tag 2");
      I1 := First_Tag_Index (T, R, 1);
      I2 := First_Tag_Index (T, R, 2);
      Check (I1 > 0 and I2 > 0, "both tags located in B2F");
      --  From eye at x=5, farther wall (tag1 at x≈0) should appear before nearer (tag2)
      Check (I1 < I2, "B2F: far wall (1) before near wall (2)");
      R := Traverse (T, Eye, Back_To_Front);
      Check (R.Count >= 2, "Traverse Order=B2F also emits");
   end;

   ---------------------------------------------------------------------
   Section ("10. Front-to-back traversal order");
   ---------------------------------------------------------------------
   declare
      List : Polygon_List;
      T    : BSP_Tree;
      R_F, R_B : Traversal_Result;
      Eye  : constant Vec2 := (5.0, 0.5);
      I1, I2 : Natural;
   begin
      List (1) := Make_VWall (0.0, 0.0, 0.2, 1.0, Tag => 1);
      List (2) := Make_VWall (2.0, 0.0, 2.2, 1.0, Tag => 2);
      T := Build_BSP (List, 2, First_Polygon);
      R_F := Traverse_Front_To_Back (T, Eye);
      R_B := Traverse_Back_To_Front (T, Eye);
      Check (R_F.Count >= 2, "F2B emits ≥2");
      Check (R_F.Count = R_B.Count, "F2B and B2F same count");
      I1 := First_Tag_Index (T, R_F, 1);
      I2 := First_Tag_Index (T, R_F, 2);
      Check (I1 > 0 and I2 > 0, "F2B finds both tags");
      Check (I2 < I1, "F2B: near wall (2) before far wall (1)");
      Check (Tag_In_Traversal (T, R_F, 1)
             and Tag_In_Traversal (T, R_F, 2), "F2B contains both");
   end;

   ---------------------------------------------------------------------
   Section ("11. Point_In_Solid / Classify_Point_In_Tree");
   ---------------------------------------------------------------------
   declare
      List : Polygon_List;
      T    : BSP_Tree;
      S    : Side;
   begin
      --  Vertical wall at X=0 facing +X (Front = positive X)
      List (1) := Make_VWall (0.0, 0.0, 0.2, 1.0, Tag => 1);
      T := Build_BSP (List, 1, First_Polygon);
      Check (not Point_In_Solid (Build_BSP ([others => <>], 0), (0.0, 0.0)),
             "empty tree Point_In_Solid False");
      S := Classify_Point_In_Tree (T, (10.0, 0.5));
      Check (S = Front or S = Back or S = On_Plane,
             "Classify_Point_In_Tree returns a Side");
      declare
         Behind : Boolean;
         Ahead  : Boolean;
      begin
         --  Back = X < 0 (behind outward +X normal); Front = X > 0
         Behind := Point_In_Solid (T, (-1.0, 0.5));
         Ahead  := Point_In_Solid (T, (5.0, 0.5));
         Check (Behind, "point behind wall reports solid leaf");
         Check (not Ahead, "point in front of wall not solid");
         Check (Classify_Point_In_Tree (Build_BSP ([others => <>], 0), (0.0, 0.0))
                = On_Plane, "empty Classify → On_Plane");
      end;
      Check (not Is_Empty_Tree (T), "solid-query tree non-empty");
   end;

   ---------------------------------------------------------------------
   Section ("12. Ray_Cast_2D / Segment_Hits_Tree collision lite");
   ---------------------------------------------------------------------
   declare
      List : Polygon_List;
      T    : BSP_Tree;
      Hit  : Ray_Hit;
      Miss : Ray_Hit;
   begin
      List (1) := Make_VWall (1.0, -0.5, 1.2, 0.5, Tag => 5);
      T := Build_BSP (List, 1, First_Polygon);
      Hit := Ray_Cast_2D (T, Make_Segment ((0.0, 0.0), (3.0, 0.0)));
      Check (Hit.Hit, "ray toward wall hits");
      Check (Hit.T >= 0.0 and Hit.T <= 1.0, "hit T in [0,1]");
      Check (Approx (Hit.Point.X, 1.0, 0.15), "hit near wall X≈1");
      Check (Segment_Hits_Tree (T, Make_Segment ((0.0, 0.0), (3.0, 0.0))),
             "Segment_Hits_Tree true");
      Miss := Ray_Cast_2D (T, Make_Segment ((0.0, 5.0), (3.0, 5.0)));
      Check (not Miss.Hit, "ray far above misses");
      Check (not Segment_Hits_Tree (T, Make_Segment ((0.0, 5.0), (1.0, 5.0))),
             "Segment_Hits_Tree false for miss");
      Check (not Ray_Cast_2D (Build_BSP ([others => <>], 0),
              Make_Segment ((0.0, 0.0), (1.0, 0.0))).Hit,
             "empty tree ray miss");
   end;

   ---------------------------------------------------------------------
   Section ("13. Build_KD_Style axis-aligned special case");
   ---------------------------------------------------------------------
   declare
      List : Polygon_List;
      T    : BSP_Tree;
      R    : Traversal_Result;
   begin
      List (1) := Make_Rect_Polygon (0.0, 0.0, 1.0, 1.0, Tag => 1);
      List (2) := Make_Rect_Polygon (3.0, 0.0, 4.0, 1.0, Tag => 2);
      List (3) := Make_Rect_Polygon (0.0, 3.0, 1.0, 4.0, Tag => 3);
      T := Build_KD_Style (List, 3);
      Check (not Is_Empty_Tree (T), "KD-style builds non-empty");
      Check (Node_Count (T) >= 1, "KD-style has nodes");
      Check (Polygon_Count (T) >= 3, "KD-style stores ≥3 polys");
      R := Traverse_Back_To_Front (T, (10.0, 10.0));
      Check (R.Count >= 3, "KD-style B2F emits ≥3");
      Check (Tag_In_Traversal (T, R, 1), "KD tag 1 present");
      Check (Tag_In_Traversal (T, R, 2), "KD tag 2 present");
      Check (Is_Empty_Tree (Build_KD_Style ([others => <>], 0)),
             "KD empty input empty tree");
   end;

   ---------------------------------------------------------------------
   Section ("14. Degenerates / coplanar / capacity helpers");
   ---------------------------------------------------------------------
   declare
      List : Polygon_List;
      T    : BSP_Tree;
      V    : Vertex_Array := [others => (0.0, 0.0)];
      P    : Polygon;
      Pl   : Plane2;
      Rel  : Polygon_Relation;
   begin
      --  Coplanar polygons sharing the same supporting line
      List (1) := Make_Rect_Polygon (0.0, 0.0, 1.0, 0.1, Tag => 1);
      List (2) := Make_Rect_Polygon (2.0, 0.0, 3.0, 0.1, Tag => 2);
      T := Build_BSP (List, 2, Least_Split);
      Check (not Is_Empty_Tree (T), "near-coplanar horizontal builds");
      Check (Polygon_Count (T) >= 1, "coplanar scene stores polys");
      --  Degenerate polygon (<3) filtered out
      V (1) := (0.0, 0.0);
      V (2) := (1.0, 0.0);
      P := Make_Polygon (V, 2, Tag => 99);
      List (1) := P;
      List (2) := Make_Rect_Polygon (0.0, 0.0, 1.0, 1.0, Tag => 3);
      T := Build_BSP (List, 2, First_Polygon);
      Check (not Is_Empty_Tree (T), "filters degenerate, keeps valid");
      Check (Polygon_Count (T) >= 1, "at least the valid poly stored");
      Pl := Make_Plane_From_Polygon (Make_Rect_Polygon (0.0, 0.0, 1.0, 1.0));
      Rel := Relate_Polygon (Make_Rect_Polygon (0.0, 0.0, 1.0, 1.0), Pl);
      Check (Rel = Coplanar or Rel = Wholly_Front or Rel = Wholly_Back
             or Rel = Straddling, "self-plane relation is defined");
      Check (Node_Count (T) >= 1, "helpers Node_Count positive");
      Check (Length (Make_Segment ((0.0, 0.0), (0.0, 0.0))) = 0.0,
             "zero-length segment");
   end;

   ---------------------------------------------------------------------
   Section ("15. Heuristic First_Polygon vs Least_Split + traversal reverse");
   ---------------------------------------------------------------------
   declare
      List : Polygon_List;
      Ta, Tb : BSP_Tree;
      Ra, Rb, Rf : Traversal_Result;
      Eye : constant Vec2 := (-5.0, 0.5);
   begin
      List (1) := Make_VWall (0.0, 0.0, 0.5, 1.0, Tag => 1);
      List (2) := Make_VWall (1.0, 0.0, 1.5, 1.0, Tag => 2);
      List (3) := Make_VWall (2.0, 0.0, 2.5, 1.0, Tag => 3);
      Ta := Build_BSP (List, 3, First_Polygon);
      Tb := Build_BSP (List, 3, Least_Split);
      Check (not Is_Empty_Tree (Ta), "First_Polygon heuristic builds");
      Check (not Is_Empty_Tree (Tb), "Least_Split heuristic builds");
      Check (Polygon_Count (Ta) >= 3, "First_Polygon stores ≥3");
      Check (Polygon_Count (Tb) >= 3, "Least_Split stores ≥3");
      Ra := Traverse_Back_To_Front (Ta, Eye);
      Rf := Traverse_Front_To_Back (Ta, Eye);
      Check (Ra.Count = Rf.Count, "same emission count B2F vs F2B");
      Check (Ra.Count >= 3, "3-wall B2F ≥3");
      --  Eye on the left: tag1 nearer than tag3 for F2B
      declare
         I1 : constant Natural := First_Tag_Index (Ta, Rf, 1);
         I3 : constant Natural := First_Tag_Index (Ta, Rf, 3);
      begin
         Check (I1 > 0 and I3 > 0, "F2B from left finds ends");
         Check (I1 < I3, "F2B from left: near(1) before far(3)");
      end;
      Rb := Traverse_Back_To_Front (Tb, Eye);
      Check (Rb.Count >= 3, "Least_Split B2F ≥3");
   end;

   New_Line;
   Put_Line ("------------------------------------");
   Put_Line ("Passed :" & Pass_Count'Image);
   Put_Line ("Failed :" & Fail_Count'Image);
   Put_Line ("------------------------------------");
   pragma Assert (Fail_Count = 0);
end Tests;
