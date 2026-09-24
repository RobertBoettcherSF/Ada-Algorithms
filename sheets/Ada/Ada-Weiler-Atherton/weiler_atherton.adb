--  Weiler_Atherton body — orientation helpers, point-in-polygon, segment
--  intersections, circular linked lists, inbound/outbound collection,
--  clip / merge walks, and no-intersection classification.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Weiler_Atherton
  with SPARK_Mode => Off
is

   -----------------------------------------------------------------------
   -- Internal numeric helpers
   -----------------------------------------------------------------------

   function Sqrt_Safe (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      else
         return Real (Sqrt (Float (X)));
      end if;
   end Sqrt_Safe;

   function Clamp01 (T : Real) return Real is
   begin
      if T < 0.0 then
         return 0.0;
      elsif T > 1.0 then
         return 1.0;
      else
         return T;
      end if;
   end Clamp01;

   function Next_Index (I, Count : Positive) return Positive is
   begin
      if I = Count then
         return 1;
      else
         return I + 1;
      end if;
   end Next_Index;

   -----------------------------------------------------------------------
   -- Vector helpers
   -----------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Point (A, B : Vec2; Tol : Real := Epsilon) return Boolean is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
   end Near_Point;

   function "-" (A, B : Vec2) return Vec2 is
   begin
      return (A.X - B.X, A.Y - B.Y);
   end "-";

   function "+" (A, B : Vec2) return Vec2 is
   begin
      return (A.X + B.X, A.Y + B.Y);
   end "+";

   function "*" (S : Real; V : Vec2) return Vec2 is
   begin
      return (S * V.X, S * V.Y);
   end "*";

   function Dot (A, B : Vec2) return Real is
   begin
      return A.X * B.X + A.Y * B.Y;
   end Dot;

   function Cross_Z (A, B : Vec2) return Real is
   begin
      return A.X * B.Y - A.Y * B.X;
   end Cross_Z;

   function Distance (A, B : Vec2) return Non_Negative is
      D : constant Vec2 := A - B;
   begin
      return Non_Negative (Sqrt_Safe (D.X * D.X + D.Y * D.Y));
   end Distance;

   -----------------------------------------------------------------------
   -- Polygon helpers
   -----------------------------------------------------------------------

   function Vertex_Count_Of (P : Polygon) return Vertex_Count is
   begin
      return P.Count;
   end Vertex_Count_Of;

   function Polygon_Copy (P : Polygon) return Polygon is
      R : Polygon;
   begin
      R.Count := P.Count;
      for I in 1 .. P.Count loop
         R.Verts (I) := P.Verts (I);
      end loop;
      return R;
   end Polygon_Copy;

   procedure Reverse_Vertices (P : in out Polygon) is
      T : Vec2;
      J : Positive;
   begin
      for I in 1 .. P.Count / 2 loop
         J := P.Count - I + 1;
         T := P.Verts (I);
         P.Verts (I) := P.Verts (J);
         P.Verts (J) := T;
      end loop;
   end Reverse_Vertices;

   function Make_Rectangle
     (Min_X, Min_Y, Max_X, Max_Y : Real;
      Orient : Orientation := Clockwise) return Polygon
   is
      P : Polygon;
   begin
      P.Count := 4;
      --  Default listing is clockwise starting at lower-left.
      P.Verts (1) := (Min_X, Min_Y);
      P.Verts (2) := (Min_X, Max_Y);
      P.Verts (3) := (Max_X, Max_Y);
      P.Verts (4) := (Max_X, Min_Y);
      if Orient = Counter_Clockwise then
         Reverse_Vertices (P);
      end if;
      return P;
   end Make_Rectangle;

   function Make_Triangle
     (A, B, C : Vec2;
      Orient  : Orientation := Clockwise) return Polygon
   is
      P : Polygon;
      Area2 : Real;
   begin
      P.Count := 3;
      P.Verts (1) := A;
      P.Verts (2) := B;
      P.Verts (3) := C;
      Area2 := Cross_Z (B - A, C - A);
      --  Positive Area2 ⇒ CCW order A-B-C.
      if Orient = Clockwise and then Area2 > 0.0 then
         Reverse_Vertices (P);
      elsif Orient = Counter_Clockwise and then Area2 < 0.0 then
         Reverse_Vertices (P);
      end if;
      return P;
   end Make_Triangle;

   function Same_Polygon
     (A, B : Polygon; Tol : Real := Epsilon) return Boolean
   is
   begin
      if A.Count /= B.Count then
         return False;
      end if;
      for I in 1 .. A.Count loop
         if not Near_Point (A.Verts (I), B.Verts (I), Tol) then
            return False;
         end if;
      end loop;
      return True;
   end Same_Polygon;

   -----------------------------------------------------------------------
   -- Orientation
   -----------------------------------------------------------------------

   function Signed_Area (P : Polygon) return Real is
      Sum : Real := 0.0;
      J   : Positive;
   begin
      for I in 1 .. P.Count loop
         J := Next_Index (I, Positive (P.Count));
         Sum := Sum + (P.Verts (I).X * P.Verts (J).Y
                       - P.Verts (J).X * P.Verts (I).Y);
      end loop;
      return Sum / 2.0;
   end Signed_Area;

   function Polygon_Orientation (P : Polygon) return Orientation is
   begin
      if Signed_Area (P) >= 0.0 then
         return Counter_Clockwise;
      else
         return Clockwise;
      end if;
   end Polygon_Orientation;

   function Orient_Clockwise (P : Polygon) return Polygon is
      R : Polygon := Polygon_Copy (P);
   begin
      if Polygon_Orientation (R) = Counter_Clockwise then
         Reverse_Vertices (R);
      end if;
      return R;
   end Orient_Clockwise;

   function Ensure_Orientation
     (P : Polygon; Wanted : Orientation) return Polygon
   is
      R : Polygon := Polygon_Copy (P);
   begin
      if Polygon_Orientation (R) /= Wanted then
         Reverse_Vertices (R);
      end if;
      return R;
   end Ensure_Orientation;

   -----------------------------------------------------------------------
   -- Point in polygon / on boundary
   -----------------------------------------------------------------------

   function Point_On_Segment
     (Q, A, B : Vec2; Tol : Real) return Boolean
   is
      AB : constant Vec2 := B - A;
      AQ : constant Vec2 := Q - A;
      Len2 : constant Real := Dot (AB, AB);
      T    : Real;
   begin
      if Len2 < Tol * Tol then
         return Near_Point (Q, A, Tol);
      end if;
      if abs (Cross_Z (AB, AQ)) > Tol * Sqrt_Safe (Len2) then
         return False;
      end if;
      T := Dot (AQ, AB) / Len2;
      return T >= -Tol and then T <= 1.0 + Tol;
   end Point_On_Segment;

   function Point_On_Boundary
     (Q : Vec2; Poly : Polygon; Tol : Real := Epsilon) return Boolean
   is
      J : Positive;
   begin
      for I in 1 .. Poly.Count loop
         J := Next_Index (I, Positive (Poly.Count));
         if Point_On_Segment (Q, Poly.Verts (I), Poly.Verts (J), Tol) then
            return True;
         end if;
      end loop;
      return False;
   end Point_On_Boundary;

   function Point_In_Polygon (Q : Vec2; Poly : Polygon) return Boolean is
      Inside : Boolean := False;
      J      : Positive;
      Xi, Xj, Yi, Yj : Real;
   begin
      if Point_On_Boundary (Q, Poly, Epsilon) then
         return False;
      end if;
      for I in 1 .. Poly.Count loop
         J := Next_Index (I, Positive (Poly.Count));
         Yi := Poly.Verts (I).Y;
         Yj := Poly.Verts (J).Y;
         Xi := Poly.Verts (I).X;
         Xj := Poly.Verts (J).X;
         if ((Yi > Q.Y) /= (Yj > Q.Y)) then
            declare
               X_Int : constant Real :=
                 Xi + (Q.Y - Yi) * (Xj - Xi) / (Yj - Yi);
            begin
               if Q.X < X_Int then
                  Inside := not Inside;
               end if;
            end;
         end if;
      end loop;
      return Inside;
   end Point_In_Polygon;

   -----------------------------------------------------------------------
   -- Segment intersection
   -----------------------------------------------------------------------

   function Segment_Intersection
     (P0, P1, Q0, Q1 : Vec2) return Seg_Intersect_Result
   is
      R : constant Vec2 := P1 - P0;
      S : constant Vec2 := Q1 - Q0;
      Denom : constant Real := Cross_Z (R, S);
      QP    : constant Vec2 := Q0 - P0;
      Result : Seg_Intersect_Result;
      T, U  : Real;
   begin
      if abs (Denom) < Epsilon then
         --  Parallel / collinear: treat as no proper intersection.
         return Result;
      end if;
      T := Cross_Z (QP, S) / Denom;
      U := Cross_Z (QP, R) / Denom;
      --  Strict open interval so shared vertices are not double-counted.
      if T > Epsilon and then T < 1.0 - Epsilon
        and then U > Epsilon and then U < 1.0 - Epsilon
      then
         Result.Found := True;
         Result.T := T;
         Result.U := U;
         Result.Point := P0 + (T * R);
      end if;
      return Result;
   end Segment_Intersection;

   function Find_All_Intersections
     (Clip, Subject : Polygon) return Intersection_List
   is
      List : Intersection_List;
      IA, IB : Positive;
      Hit  : Seg_Intersect_Result;
      Dup  : Boolean;
   begin
      List.Count := 0;
      for EA in 1 .. Clip.Count loop
         IA := Next_Index (EA, Positive (Clip.Count));
         for EB in 1 .. Subject.Count loop
            IB := Next_Index (EB, Positive (Subject.Count));
            Hit := Segment_Intersection
              (Clip.Verts (EA), Clip.Verts (IA),
               Subject.Verts (EB), Subject.Verts (IB));
            if Hit.Found then
               Dup := False;
               for K in 1 .. List.Count loop
                  if Near_Point (List.Items (K).Point, Hit.Point) then
                     Dup := True;
                     exit;
                  end if;
               end loop;
               if not Dup then
                  if List.Count = Max_Intersections then
                     raise Capacity_Exceeded;
                  end if;
                  List.Count := List.Count + 1;
                  List.Items (List.Count) :=
                    (Point   => Hit.Point,
                     Kind    => Unknown,
                     Edge_A  => EA,
                     Edge_B  => EB,
                     Alpha_A => Hit.T,
                     Alpha_B => Hit.U);
               end if;
            end if;
         end loop;
      end loop;
      return List;
   end Find_All_Intersections;

   -----------------------------------------------------------------------
   -- Linked circular lists
   -----------------------------------------------------------------------

   --  Insert a node after position After in a singly-linked circular list
   --  stored densely in Nodes (1 .. Count). Returns the new node index.
   function Insert_After
     (Nodes : in out List_Node_Array;
      Count : in out List_Node_Count;
      After : Positive;
      Point : Vec2;
      Source : Node_Source) return Positive
   is
      New_Idx : Positive;
   begin
      if Count = Max_List_Nodes then
         raise Capacity_Exceeded;
      end if;
      Count := Count + 1;
      New_Idx := Positive (Count);
      Nodes (New_Idx).Point := Point;
      Nodes (New_Idx).Source := Source;
      Nodes (New_Idx).Is_Inbound := False;
      Nodes (New_Idx).Is_Outbound := False;
      Nodes (New_Idx).Visited := False;
      Nodes (New_Idx).Link := 0;
      Nodes (New_Idx).Next := Nodes (After).Next;
      Nodes (After).Next := New_Idx;
      return New_Idx;
   end Insert_After;

   procedure Init_Circular
     (Poly  : Polygon;
      Nodes : out List_Node_Array;
      Count : out List_Node_Count;
      Head  : out Natural)
   is
   begin
      Count := 0;
      Head := 0;
      if Poly.Count = 0 then
         return;
      end if;
      for I in 1 .. Poly.Count loop
         Count := Count + 1;
         Nodes (Positive (Count)).Point := Poly.Verts (I);
         Nodes (Positive (Count)).Source := Original_Vertex;
         Nodes (Positive (Count)).Is_Inbound := False;
         Nodes (Positive (Count)).Is_Outbound := False;
         Nodes (Positive (Count)).Visited := False;
         Nodes (Positive (Count)).Link := 0;
         if I < Poly.Count then
            Nodes (Positive (Count)).Next := I + 1;
         else
            Nodes (Positive (Count)).Next := 1;
         end if;
      end loop;
      Head := 1;
   end Init_Circular;

   --  Find the list node that is the start vertex of edge Edge_Start
   --  (original vertex index), then walk forward among nodes that still
   --  lie on that edge (inserted intersections sorted by alpha).
   procedure Insert_Intersection_On_Edge
     (Nodes      : in out List_Node_Array;
      Count      : in out List_Node_Count;
      Orig_Count : Positive;
      Edge_Start : Positive;
      Alpha      : Real;
      Point      : Vec2;
      New_Idx    : out Positive)
   is
      --  Walk from Edge_Start along Next, inserting in increasing alpha
      --  among already-inserted intersection nodes on this edge. Original
      --  next vertex (or later original) ends the edge.
      Cur   : Positive := Edge_Start;
      Prev  : Positive;
      Placed_Alpha : Real;
      Guard : Natural := 0;
   begin
      declare
         A0 : constant Vec2 := Nodes (Edge_Start).Point;
         A1 : constant Vec2 :=
           Nodes (Next_Index (Edge_Start, Orig_Count)).Point;
         --  Original end node index is stable.
         End_Idx : constant Positive :=
           Next_Index (Edge_Start, Orig_Count);
         Edge_Vec : constant Vec2 := A1 - A0;
         Len2 : constant Real := Dot (Edge_Vec, Edge_Vec);
         function Alpha_Of (P : Vec2) return Real is
         begin
            if Len2 < Epsilon * Epsilon then
               return 0.0;
            end if;
            return Clamp01 (Dot (P - A0, Edge_Vec) / Len2);
         end Alpha_Of;
      begin
         Prev := Edge_Start;
         Cur := Positive (Nodes (Edge_Start).Next);
         while Cur /= End_Idx and then Guard < Max_List_Nodes loop
            Guard := Guard + 1;
            if Nodes (Cur).Source = Intersection_Vertex then
               Placed_Alpha := Alpha_Of (Nodes (Cur).Point);
               if Alpha < Placed_Alpha - Epsilon then
                  exit;
               end if;
               Prev := Cur;
               Cur := Positive (Nodes (Cur).Next);
            else
               --  Unexpected original before End_Idx — stop.
               exit;
            end if;
         end loop;
         New_Idx := Insert_After
           (Nodes, Count, Prev, Point, Intersection_Vertex);
      end;
   end Insert_Intersection_On_Edge;

   procedure Label_Inbound_Outbound
     (Lists   : in out Linked_Polygon_Lists;
      Clip    : Polygon)
   is
      Idx   : Natural;
      Nxt   : Natural;
      Guard : Natural := 0;
      Mid   : Vec2;
   begin
      if Lists.Subject_Head = 0 then
         return;
      end if;
      Idx := Lists.Subject_Head;
      loop
         Guard := Guard + 1;
         if Guard > Max_List_Nodes + 1 then
            exit;
         end if;
         if Lists.Subject (Positive (Idx)).Source = Intersection_Vertex then
            Nxt := Lists.Subject (Positive (Idx)).Next;
            --  Sample a point slightly after the intersection along subject.
            Mid := Lists.Subject (Positive (Idx)).Point
              + (0.01 *
                   (Lists.Subject (Positive (Nxt)).Point
                    - Lists.Subject (Positive (Idx)).Point));
            --  If the leaving direction enters the clip interior ⇒ inbound.
            if Point_In_Polygon (Mid, Clip) then
               Lists.Subject (Positive (Idx)).Is_Inbound := True;
               Lists.Subject (Positive (Idx)).Is_Outbound := False;
            else
               Lists.Subject (Positive (Idx)).Is_Inbound := False;
               Lists.Subject (Positive (Idx)).Is_Outbound := True;
            end if;
            --  Mirror flags onto the linked clip node.
            if Lists.Subject (Positive (Idx)).Link /= 0 then
               declare
                  L : constant Positive :=
                    Positive (Lists.Subject (Positive (Idx)).Link);
               begin
                  Lists.Clip (L).Is_Inbound :=
                    Lists.Subject (Positive (Idx)).Is_Inbound;
                  Lists.Clip (L).Is_Outbound :=
                    Lists.Subject (Positive (Idx)).Is_Outbound;
               end;
            end if;
         end if;
         Idx := Lists.Subject (Positive (Idx)).Next;
         exit when Idx = Lists.Subject_Head;
      end loop;
   end Label_Inbound_Outbound;

   function Build_Linked_Polygon_Lists
     (Clip, Subject : Polygon) return Linked_Polygon_Lists
   is
      Lists : Linked_Polygon_Lists;
      Hits  : constant Intersection_List :=
        Find_All_Intersections (Clip, Subject);
      Clip_Orig : constant Positive := Positive (Clip.Count);
      Subj_Orig : constant Positive := Positive (Subject.Count);
      Clip_Idx, Subj_Idx : Positive;
   begin
      Init_Circular
        (Clip, Lists.Clip, Lists.Clip_Count, Lists.Clip_Head);
      Init_Circular
        (Subject, Lists.Subject, Lists.Subject_Count, Lists.Subject_Head);

      for K in 1 .. Hits.Count loop
         Insert_Intersection_On_Edge
           (Lists.Clip, Lists.Clip_Count, Clip_Orig,
            Positive (Hits.Items (K).Edge_A),
            Hits.Items (K).Alpha_A,
            Hits.Items (K).Point,
            Clip_Idx);
         Insert_Intersection_On_Edge
           (Lists.Subject, Lists.Subject_Count, Subj_Orig,
            Positive (Hits.Items (K).Edge_B),
            Hits.Items (K).Alpha_B,
            Hits.Items (K).Point,
            Subj_Idx);
         Lists.Clip (Clip_Idx).Link := Subj_Idx;
         Lists.Subject (Subj_Idx).Link := Clip_Idx;
      end loop;

      Label_Inbound_Outbound (Lists, Clip);
      return Lists;
   end Build_Linked_Polygon_Lists;

   function Collect_Inbound_Intersections
     (Lists : Linked_Polygon_Lists) return Intersection_List
   is
      Out_L : Intersection_List;
      Idx   : Natural;
      Guard : Natural := 0;
   begin
      Out_L.Count := 0;
      if Lists.Subject_Head = 0 then
         return Out_L;
      end if;
      Idx := Lists.Subject_Head;
      loop
         Guard := Guard + 1;
         exit when Guard > Max_List_Nodes + 1;
         if Lists.Subject (Positive (Idx)).Source = Intersection_Vertex
           and then Lists.Subject (Positive (Idx)).Is_Inbound
         then
            if Out_L.Count = Max_Intersections then
               raise Capacity_Exceeded;
            end if;
            Out_L.Count := Out_L.Count + 1;
            Out_L.Items (Out_L.Count).Point :=
              Lists.Subject (Positive (Idx)).Point;
            Out_L.Items (Out_L.Count).Kind := Inbound;
         end if;
         Idx := Lists.Subject (Positive (Idx)).Next;
         exit when Idx = Lists.Subject_Head;
      end loop;
      return Out_L;
   end Collect_Inbound_Intersections;

   function Collect_Outbound_Intersections
     (Lists : Linked_Polygon_Lists) return Intersection_List
   is
      Out_L : Intersection_List;
      Idx   : Natural;
      Guard : Natural := 0;
   begin
      Out_L.Count := 0;
      if Lists.Subject_Head = 0 then
         return Out_L;
      end if;
      Idx := Lists.Subject_Head;
      loop
         Guard := Guard + 1;
         exit when Guard > Max_List_Nodes + 1;
         if Lists.Subject (Positive (Idx)).Source = Intersection_Vertex
           and then Lists.Subject (Positive (Idx)).Is_Outbound
         then
            if Out_L.Count = Max_Intersections then
               raise Capacity_Exceeded;
            end if;
            Out_L.Count := Out_L.Count + 1;
            Out_L.Items (Out_L.Count).Point :=
              Lists.Subject (Positive (Idx)).Point;
            Out_L.Items (Out_L.Count).Kind := Outbound;
         end if;
         Idx := Lists.Subject (Positive (Idx)).Next;
         exit when Idx = Lists.Subject_Head;
      end loop;
      return Out_L;
   end Collect_Outbound_Intersections;

   -----------------------------------------------------------------------
   -- No-intersection classification
   -----------------------------------------------------------------------

   function Classify_No_Intersection
     (Clip, Subject : Polygon) return Overlap_Class
   is
      Hits : constant Intersection_List :=
        Find_All_Intersections (Clip, Subject);
      Sample_S : Vec2;
      Sample_C : Vec2;
   begin
      if Hits.Count > 0 then
         return Overlapping;
      end if;
      Sample_S := Subject.Verts (1);
      Sample_C := Clip.Verts (1);
      if Point_In_Polygon (Sample_S, Clip)
        or else Point_On_Boundary (Sample_S, Clip)
      then
         return B_In_A;
      elsif Point_In_Polygon (Sample_C, Subject)
        or else Point_On_Boundary (Sample_C, Subject)
      then
         return A_In_B;
      else
         return Disjoint;
      end if;
   end Classify_No_Intersection;

   -----------------------------------------------------------------------
   -- Trace helpers for clip / merge
   -----------------------------------------------------------------------

   procedure Append_Vertex (Poly : in out Polygon; P : Vec2) is
   begin
      --  Skip near-duplicates of the last vertex.
      if Poly.Count >= 1
        and then Near_Point (Poly.Verts (Poly.Count), P)
      then
         return;
      end if;
      if Poly.Count = Max_Vertices then
         raise Capacity_Exceeded;
      end if;
      Poly.Count := Poly.Count + 1;
      Poly.Verts (Poly.Count) := P;
   end Append_Vertex;

   procedure Append_Polygon (Result : in out Clip_Result; P : Polygon) is
      Clean : Polygon;
   begin
      if P.Count < 3 then
         return;
      end if;
      --  Drop closing duplicate if present.
      Clean := P;
      if Clean.Count >= 2
        and then Near_Point
          (Clean.Verts (1), Clean.Verts (Clean.Count))
      then
         Clean.Count := Clean.Count - 1;
      end if;
      if Clean.Count < 3 then
         return;
      end if;
      if Result.Count = Max_Polygons then
         raise Capacity_Exceeded;
      end if;
      Result.Count := Result.Count + 1;
      Result.Polys (Result.Count) := Clean;
   end Append_Polygon;

   --  Walk from a start intersection on the subject list. At each
   --  intersection, cross via Link to the other polygon. On_Subject
   --  tracks which list we currently follow. For clipping we start
   --  inbound on subject; for merging we start outbound on subject.
   procedure Trace_From
     (Lists       : in out Linked_Polygon_Lists;
      Start_Subj  : Positive;
      Result_Poly : out Polygon)
   is
      On_Subject : Boolean := True;
      Cur        : Positive := Start_Subj;
      Steps      : Natural := 0;
      Node       : List_Node;
   begin
      Result_Poly.Count := 0;
      loop
         --  Finished when we return to the start intersection.
         if Steps > 0 then
            if On_Subject and then Cur = Start_Subj then
               exit;
            end if;
            if (not On_Subject)
              and then Lists.Clip (Cur).Link = Natural (Start_Subj)
            then
               exit;
            end if;
         end if;

         if Steps > Max_List_Nodes * 4 then
            exit;
         end if;

         if On_Subject then
            Node := Lists.Subject (Cur);
            Lists.Subject (Cur).Visited := True;
            if Node.Link /= 0 then
               Lists.Clip (Positive (Node.Link)).Visited := True;
            end if;
         else
            Node := Lists.Clip (Cur);
            Lists.Clip (Cur).Visited := True;
            if Node.Link /= 0 then
               Lists.Subject (Positive (Node.Link)).Visited := True;
            end if;
         end if;

         Append_Vertex (Result_Poly, Node.Point);
         Steps := Steps + 1;

         if Node.Source = Intersection_Vertex
           and then Steps > 1
           and then Node.Link /= 0
         then
            Cur := Positive (Node.Link);
            On_Subject := not On_Subject;
            if On_Subject then
               Cur := Positive (Lists.Subject (Cur).Next);
            else
               Cur := Positive (Lists.Clip (Cur).Next);
            end if;
         else
            if On_Subject then
               Cur := Positive (Lists.Subject (Cur).Next);
            else
               Cur := Positive (Lists.Clip (Cur).Next);
            end if;
         end if;
      end loop;
   end Trace_From;

   function Find_Unvisited_Marked
     (Lists    : Linked_Polygon_Lists;
      Inbound  : Boolean) return Natural
   is
      Idx   : Natural;
      Guard : Natural := 0;
   begin
      if Lists.Subject_Head = 0 then
         return 0;
      end if;
      Idx := Lists.Subject_Head;
      loop
         Guard := Guard + 1;
         exit when Guard > Max_List_Nodes + 1;
         declare
            N : List_Node renames Lists.Subject (Positive (Idx));
         begin
            if N.Source = Intersection_Vertex
              and then not N.Visited
              and then ((Inbound and then N.Is_Inbound)
                        or else ((not Inbound) and then N.Is_Outbound))
            then
               return Idx;
            end if;
         end;
         Idx := Lists.Subject (Positive (Idx)).Next;
         exit when Idx = Lists.Subject_Head;
      end loop;
      return 0;
   end Find_Unvisited_Marked;

   function Trace_All
     (Clip, Subject : Polygon;
      Use_Inbound   : Boolean) return Clip_Result
   is
      A : constant Polygon := Orient_Clockwise (Clip);
      B : constant Polygon := Orient_Clockwise (Subject);
      Lists : Linked_Polygon_Lists := Build_Linked_Polygon_Lists (A, B);
      Result : Clip_Result;
      Start  : Natural;
      Poly   : Polygon;
      Class  : Overlap_Class;
      Hits   : constant Intersection_List := Find_All_Intersections (A, B);
   begin
      Result.Count := 0;

      if Hits.Count = 0 then
         Class := Classify_No_Intersection (A, B);
         if Use_Inbound then
            --  Clipping
            case Class is
               when B_In_A =>
                  Append_Polygon (Result, B);
               when A_In_B =>
                  Append_Polygon (Result, A);
               when Disjoint =>
                  null;
               when Overlapping =>
                  null;
            end case;
         else
            --  Merging
            case Class is
               when B_In_A =>
                  Append_Polygon (Result, A);
               when A_In_B =>
                  Append_Polygon (Result, B);
               when Disjoint =>
                  Append_Polygon (Result, A);
                  Append_Polygon (Result, B);
               when Overlapping =>
                  null;
            end case;
         end if;
         return Result;
      end if;

      loop
         Start := Find_Unvisited_Marked (Lists, Use_Inbound);
         exit when Start = 0;
         Trace_From (Lists, Positive (Start), Poly);
         Append_Polygon (Result, Poly);
      end loop;

      return Result;
   end Trace_All;

   function Weiler_Atherton_Clip
     (Clip, Subject : Polygon) return Clip_Result
   is
   begin
      if Clip.Count < 3 or else Subject.Count < 3 then
         raise Invalid_Argument;
      end if;
      return Trace_All (Clip, Subject, Use_Inbound => True);
   end Weiler_Atherton_Clip;

   function Weiler_Atherton_Merge
     (Clip, Subject : Polygon) return Clip_Result
   is
   begin
      if Clip.Count < 3 or else Subject.Count < 3 then
         raise Invalid_Argument;
      end if;
      return Trace_All (Clip, Subject, Use_Inbound => False);
   end Weiler_Atherton_Merge;

begin
   null;
end Weiler_Atherton;
