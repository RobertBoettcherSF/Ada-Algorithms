--  Vatti body — vector helpers, scanline/sweep scaffolding, segment
--  intersections, linked-list boolean walks for simple polygons, and
--  Intersection / Union / Difference / Exclusive_Or convenience wrappers.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Vatti
  with SPARK_Mode => Off
is

   Max_List_Nodes : constant Positive := 128;
   subtype List_Node_Count is Natural range 0 .. Max_List_Nodes;
   subtype List_Node_Index is Positive range 1 .. Max_List_Nodes;

   type Node_Source is (Original_Vertex, Intersection_Vertex);

   type List_Node is record
      Point       : Vec2 := (0.0, 0.0);
      Source      : Node_Source := Original_Vertex;
      Is_Entry    : Boolean := False;  -- entering the other polygon
      Visited     : Boolean := False;
      Link        : Natural := 0;
      Next        : Natural := 0;
      Prev        : Natural := 0;
   end record;

   type List_Node_Array is array (List_Node_Index) of List_Node;

   type Linked_Lists is record
      A, B           : List_Node_Array;
      A_Count, B_Count : List_Node_Count := 0;
      A_Head, B_Head : Natural := 0;
   end record;

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

   function Absolute_Area (P : Polygon) return Non_Negative is
   begin
      return Non_Negative (abs (Signed_Area (P)));
   end Absolute_Area;

   function Set_Absolute_Area (S : Polygon_Set) return Non_Negative is
      Acc : Real := 0.0;
   begin
      for I in 1 .. S.Count loop
         if S.Polys (I).Count >= 3 then
            Acc := Acc + abs (Signed_Area (S.Polys (I)));
         end if;
      end loop;
      return Non_Negative (Acc);
   end Set_Absolute_Area;

   function Singleton (P : Polygon) return Polygon_Set is
      S : Polygon_Set;
   begin
      S.Count := 1;
      S.Polys (1) := P;
      return S;
   end Singleton;

   function Make_Set (A, B : Polygon) return Polygon_Set is
      S : Polygon_Set;
   begin
      S.Count := 2;
      S.Polys (1) := A;
      S.Polys (2) := B;
      return S;
   end Make_Set;

   -----------------------------------------------------------------------
   -- Point in polygon / boundary
   -----------------------------------------------------------------------

   function Point_On_Segment
     (Q, A, B : Vec2; Tol : Real) return Boolean
   is
      AB : constant Vec2 := B - A;
      AQ : constant Vec2 := Q - A;
      Len2 : constant Real := Dot (AB, AB);
      T : Real;
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
      J : Positive;
      Yi, Yj, Xi, Xj : Real;
      Xint : Real;
   begin
      if Point_On_Boundary (Q, Poly) then
         return False;
      end if;
      for I in 1 .. Poly.Count loop
         J := Next_Index (I, Positive (Poly.Count));
         Yi := Poly.Verts (I).Y;
         Yj := Poly.Verts (J).Y;
         Xi := Poly.Verts (I).X;
         Xj := Poly.Verts (J).X;
         if ((Yi > Q.Y) /= (Yj > Q.Y)) then
            Xint := (Xj - Xi) * (Q.Y - Yi) / (Yj - Yi + 0.0) + Xi;
            if Q.X < Xint then
               Inside := not Inside;
            end if;
         end if;
      end loop;
      return Inside;
   end Point_In_Polygon;

   function Point_In_Set (Q : Vec2; S : Polygon_Set) return Boolean is
   begin
      for I in 1 .. S.Count loop
         if S.Polys (I).Count >= 3
           and then (Point_In_Polygon (Q, S.Polys (I))
                     or else Point_On_Boundary (Q, S.Polys (I)))
         then
            return True;
         end if;
      end loop;
      return False;
   end Point_In_Set;

   -----------------------------------------------------------------------
   -- Segment intersection
   -----------------------------------------------------------------------

   function Segment_Intersection
     (P0, P1, Q0, Q1 : Vec2) return Seg_Intersect_Result
   is
      R : constant Vec2 := P1 - P0;
      S : constant Vec2 := Q1 - Q0;
      Den : constant Real := Cross_Z (R, S);
      QP : constant Vec2 := Q0 - P0;
      T, U : Real;
      Res : Seg_Intersect_Result;
   begin
      Res.Found := False;
      if abs (Den) < Epsilon * Epsilon then
         return Res;
      end if;
      T := Cross_Z (QP, S) / Den;
      U := Cross_Z (QP, R) / Den;
      if T > Epsilon and then T < 1.0 - Epsilon
        and then U > Epsilon and then U < 1.0 - Epsilon
      then
         Res.Found := True;
         Res.T := T;
         Res.U := U;
         Res.Point := P0 + (T * R);
      end if;
      return Res;
   end Segment_Intersection;

   function Find_All_Intersections
     (A, B : Polygon) return Intersection_List
   is
      Out_L : Intersection_List;
      Hit : Seg_Intersect_Result;
      IA, JA, IB, JB : Positive;
   begin
      Out_L.Count := 0;
      for EA in 1 .. A.Count loop
         IA := EA;
         JA := Next_Index (EA, Positive (A.Count));
         for EB in 1 .. B.Count loop
            IB := EB;
            JB := Next_Index (EB, Positive (B.Count));
            Hit := Segment_Intersection
              (A.Verts (IA), A.Verts (JA), B.Verts (IB), B.Verts (JB));
            if Hit.Found then
               if Out_L.Count = Max_Intersections then
                  raise Capacity_Exceeded;
               end if;
               Out_L.Count := Out_L.Count + 1;
               Out_L.Items (Out_L.Count) :=
                 (Point   => Hit.Point,
                  Edge_A  => EA,
                  Edge_B  => EB,
                  Alpha_A => Hit.T,
                  Alpha_B => Hit.U);
            end if;
         end loop;
      end loop;
      return Out_L;
   end Find_All_Intersections;

   function Classify_No_Intersection
     (A, B : Polygon) return Overlap_Class
   is
      Hits : constant Intersection_List := Find_All_Intersections (A, B);
      SA : constant Vec2 := A.Verts (1);
      SB : constant Vec2 := B.Verts (1);
   begin
      if Hits.Count > 0 then
         return Overlapping;
      end if;
      if Point_In_Polygon (SB, A) or else Point_On_Boundary (SB, A) then
         return B_In_A;
      elsif Point_In_Polygon (SA, B) or else Point_On_Boundary (SA, B) then
         return A_In_B;
      else
         return Disjoint;
      end if;
   end Classify_No_Intersection;

   -----------------------------------------------------------------------
   -- Scanline / local minima / scanbeam
   -----------------------------------------------------------------------

   procedure Insert_Y_Sorted (L : in out Scanline_List; Y : Real) is
      I : Scanline_Count;
   begin
      for K in 1 .. L.Count loop
         if Near (L.Ys (K), Y) then
            return;
         end if;
      end loop;
      if L.Count = Max_Scanlines then
         raise Capacity_Exceeded;
      end if;
      I := L.Count;
      while I >= 1 and then L.Ys (I) > Y loop
         L.Ys (I + 1) := L.Ys (I);
         I := I - 1;
      end loop;
      L.Ys (I + 1) := Y;
      L.Count := L.Count + 1;
   end Insert_Y_Sorted;

   procedure Collect_Polygon_Ys (P : Polygon; L : in out Scanline_List) is
   begin
      for I in 1 .. P.Count loop
         Insert_Y_Sorted (L, P.Verts (I).Y);
      end loop;
   end Collect_Polygon_Ys;

   function Collect_Scanline_Ys
     (Subject, Clip : Polygon_Set) return Scanline_List
   is
      L : Scanline_List;
   begin
      L.Count := 0;
      for I in 1 .. Subject.Count loop
         Collect_Polygon_Ys (Subject.Polys (I), L);
      end loop;
      for I in 1 .. Clip.Count loop
         Collect_Polygon_Ys (Clip.Polys (I), L);
      end loop;
      return L;
   end Collect_Scanline_Ys;

   function Build_Local_Minima
     (Subject, Clip : Polygon_Set) return Scanline_List
   is
   begin
      return Collect_Scanline_Ys (Subject, Clip);
   end Build_Local_Minima;

   function Y_In_Beam (Y : Real; Beam : Scanbeam) return Boolean is
   begin
      return Y > Beam.Y_Bot + Epsilon and then Y <= Beam.Y_Top + Epsilon;
   end Y_In_Beam;

   function Sweep_Process_Scanbeam
     (Subject, Clip : Polygon;
      Beam          : Scanbeam) return Intersection_List
   is
      All_Hits : constant Intersection_List :=
        Find_All_Intersections (Subject, Clip);
      Out_L : Intersection_List;
   begin
      Out_L.Count := 0;
      for K in 1 .. All_Hits.Count loop
         if Y_In_Beam (All_Hits.Items (K).Point.Y, Beam) then
            if Out_L.Count = Max_Intersections then
               raise Capacity_Exceeded;
            end if;
            Out_L.Count := Out_L.Count + 1;
            Out_L.Items (Out_L.Count) := All_Hits.Items (K);
         end if;
      end loop;
      return Out_L;
   end Sweep_Process_Scanbeam;

   -----------------------------------------------------------------------
   -- Linked lists for boolean walks
   -----------------------------------------------------------------------

   function Insert_After
     (Nodes : in out List_Node_Array;
      Count : in out List_Node_Count;
      Prev  : Positive;
      Point : Vec2;
      Src   : Node_Source) return Positive
   is
      New_I : Positive;
      Nxt   : Natural;
   begin
      if Count = Max_List_Nodes then
         raise Capacity_Exceeded;
      end if;
      Count := Count + 1;
      New_I := Positive (Count);
      Nxt := Nodes (Prev).Next;
      Nodes (New_I).Point := Point;
      Nodes (New_I).Source := Src;
      Nodes (New_I).Is_Entry := False;
      Nodes (New_I).Visited := False;
      Nodes (New_I).Link := 0;
      Nodes (New_I).Prev := Prev;
      Nodes (New_I).Next := Nxt;
      Nodes (Prev).Next := New_I;
      if Nxt /= 0 then
         Nodes (Positive (Nxt)).Prev := New_I;
      end if;
      return New_I;
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
         Nodes (Positive (Count)).Is_Entry := False;
         Nodes (Positive (Count)).Visited := False;
         Nodes (Positive (Count)).Link := 0;
         if I < Poly.Count then
            Nodes (Positive (Count)).Next := I + 1;
         else
            Nodes (Positive (Count)).Next := 1;
         end if;
         if I = 1 then
            Nodes (Positive (Count)).Prev := Positive (Poly.Count);
         else
            Nodes (Positive (Count)).Prev := I - 1;
         end if;
      end loop;
      Head := 1;
   end Init_Circular;

   procedure Insert_Intersection_On_Edge
     (Nodes      : in out List_Node_Array;
      Count      : in out List_Node_Count;
      Orig_Count : Positive;
      Edge_Start : Positive;
      Alpha      : Real;
      Point      : Vec2;
      New_Idx    : out Positive)
   is
      Cur   : Positive;
      Prev  : Positive;
      Placed_Alpha : Real;
      Guard : Natural := 0;
      A0 : constant Vec2 := Nodes (Edge_Start).Point;
      A1 : constant Vec2 :=
        Nodes (Next_Index (Edge_Start, Orig_Count)).Point;
      End_Idx : constant Positive := Next_Index (Edge_Start, Orig_Count);
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
            exit;
         end if;
      end loop;
      New_Idx := Insert_After
        (Nodes, Count, Prev, Point, Intersection_Vertex);
   end Insert_Intersection_On_Edge;

   procedure Label_Entries
     (Lists : in out Linked_Lists;
      Other : Polygon;
      Which : Character)
   is
      Idx   : Natural;
      Nxt   : Natural;
      Guard : Natural := 0;
      Mid   : Vec2;
      Inside : Boolean;
   begin
      if Which = 'A' then
         if Lists.A_Head = 0 then
            return;
         end if;
         Idx := Lists.A_Head;
         loop
            Guard := Guard + 1;
            exit when Guard > Max_List_Nodes + 1;
            if Lists.A (Positive (Idx)).Source = Intersection_Vertex then
               Nxt := Lists.A (Positive (Idx)).Next;
               Mid := Lists.A (Positive (Idx)).Point
                 + (0.01 *
                      (Lists.A (Positive (Nxt)).Point
                       - Lists.A (Positive (Idx)).Point));
               Inside := Point_In_Polygon (Mid, Other);
               Lists.A (Positive (Idx)).Is_Entry := Inside;
            end if;
            Idx := Lists.A (Positive (Idx)).Next;
            exit when Idx = Lists.A_Head;
         end loop;
      else
         if Lists.B_Head = 0 then
            return;
         end if;
         Idx := Lists.B_Head;
         loop
            Guard := Guard + 1;
            exit when Guard > Max_List_Nodes + 1;
            if Lists.B (Positive (Idx)).Source = Intersection_Vertex then
               Nxt := Lists.B (Positive (Idx)).Next;
               Mid := Lists.B (Positive (Idx)).Point
                 + (0.01 *
                      (Lists.B (Positive (Nxt)).Point
                       - Lists.B (Positive (Idx)).Point));
               Inside := Point_In_Polygon (Mid, Other);
               Lists.B (Positive (Idx)).Is_Entry := Inside;
            end if;
            Idx := Lists.B (Positive (Idx)).Next;
            exit when Idx = Lists.B_Head;
         end loop;
      end if;
   end Label_Entries;

   function Build_Lists (A, B : Polygon) return Linked_Lists is
      Lists : Linked_Lists;
      Hits  : constant Intersection_List := Find_All_Intersections (A, B);
      A_Orig : constant Positive := Positive (A.Count);
      B_Orig : constant Positive := Positive (B.Count);
      A_Idx, B_Idx : Positive;
   begin
      Init_Circular (A, Lists.A, Lists.A_Count, Lists.A_Head);
      Init_Circular (B, Lists.B, Lists.B_Count, Lists.B_Head);
      for K in 1 .. Hits.Count loop
         Insert_Intersection_On_Edge
           (Lists.A, Lists.A_Count, A_Orig,
            Positive (Hits.Items (K).Edge_A),
            Hits.Items (K).Alpha_A,
            Hits.Items (K).Point,
            A_Idx);
         Insert_Intersection_On_Edge
           (Lists.B, Lists.B_Count, B_Orig,
            Positive (Hits.Items (K).Edge_B),
            Hits.Items (K).Alpha_B,
            Hits.Items (K).Point,
            B_Idx);
         Lists.A (A_Idx).Link := B_Idx;
         Lists.B (B_Idx).Link := A_Idx;
      end loop;
      Label_Entries (Lists, B, 'A');
      Label_Entries (Lists, A, 'B');
      return Lists;
   end Build_Lists;

   procedure Append_Vertex (Poly : in out Polygon; P : Vec2) is
   begin
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

   procedure Append_Polygon (Result : in out Polygon_Set; P : Polygon) is
      Clean : Polygon;
   begin
      if P.Count < 3 then
         return;
      end if;
      Clean := P;
      if Clean.Count >= 2
        and then Near_Point (Clean.Verts (1), Clean.Verts (Clean.Count))
      then
         Clean.Count := Clean.Count - 1;
      end if;
      if Clean.Count < 3 then
         return;
      end if;
      if Absolute_Area (Clean) < Epsilon then
         return;
      end if;
      if Result.Count = Max_Polygons then
         raise Capacity_Exceeded;
      end if;
      Result.Count := Result.Count + 1;
      Result.Polys (Result.Count) := Orient_Clockwise (Clean);
   end Append_Polygon;

   --  Trace one result contour.
   --  Forward on both for Intersection / Union / Exclusive_Or.
   --  For Difference: forward on subject (A), backward on clip (B).
   procedure Trace_Contour
     (Lists       : in out Linked_Lists;
      Start_A     : Positive;
      Op          : Boolean_Operation;
      Result_Poly : out Polygon)
   is
      On_A  : Boolean := True;
      Cur   : Positive := Start_A;
      Steps : Natural := 0;
      Node  : List_Node;
      Forward : Boolean := True;
   begin
      Result_Poly.Count := 0;
      loop
         if Steps > 0 then
            if On_A and then Cur = Start_A then
               exit;
            end if;
            if (not On_A)
              and then Lists.B (Cur).Link = Natural (Start_A)
            then
               exit;
            end if;
         end if;
         if Steps > Max_List_Nodes * 4 then
            exit;
         end if;

         if On_A then
            Node := Lists.A (Cur);
            Lists.A (Cur).Visited := True;
            if Node.Link /= 0 then
               Lists.B (Positive (Node.Link)).Visited := True;
            end if;
         else
            Node := Lists.B (Cur);
            Lists.B (Cur).Visited := True;
            if Node.Link /= 0 then
               Lists.A (Positive (Node.Link)).Visited := True;
            end if;
         end if;

         Append_Vertex (Result_Poly, Node.Point);
         Steps := Steps + 1;

         if Node.Source = Intersection_Vertex and then Node.Link /= 0
           and then Steps > 1
         then
            --  Switch polygons at intersections.
            if On_A then
               Cur := Positive (Node.Link);
               On_A := False;
               Forward := Op /= Difference;
            else
               Cur := Positive (Node.Link);
               On_A := True;
               Forward := True;
            end if;
            --  After switch, advance one step along the new polygon.
            if On_A then
               if Forward then
                  Cur := Positive (Lists.A (Cur).Next);
               else
                  Cur := Positive (Lists.A (Cur).Prev);
               end if;
            else
               if Forward then
                  Cur := Positive (Lists.B (Cur).Next);
               else
                  Cur := Positive (Lists.B (Cur).Prev);
               end if;
            end if;
         else
            if On_A then
               Cur := Positive (Lists.A (Cur).Next);
            else
               if Op = Difference then
                  Cur := Positive (Lists.B (Cur).Prev);
               else
                  Cur := Positive (Lists.B (Cur).Next);
               end if;
            end if;
         end if;
      end loop;
   end Trace_Contour;

   function No_Hit_Result
     (A, B : Polygon; Op : Boolean_Operation) return Polygon_Set
   is
      Class : constant Overlap_Class := Classify_No_Intersection (A, B);
      R : Polygon_Set;
   begin
      R.Count := 0;
      case Op is
         when Intersection =>
            case Class is
               when B_In_A =>
                  Append_Polygon (R, B);
               when A_In_B =>
                  Append_Polygon (R, A);
               when Disjoint | Overlapping =>
                  null;
            end case;
         when Union =>
            case Class is
               when B_In_A =>
                  Append_Polygon (R, A);
               when A_In_B =>
                  Append_Polygon (R, B);
               when Disjoint =>
                  Append_Polygon (R, A);
                  Append_Polygon (R, B);
               when Overlapping =>
                  null;
            end case;
         when Difference =>
            case Class is
               when B_In_A =>
                  --  Subject contains clip: hole not supported → keep subject.
                  --  Documented limitation; return subject unchanged.
                  Append_Polygon (R, A);
               when A_In_B =>
                  null;  -- subject entirely removed
               when Disjoint =>
                  Append_Polygon (R, A);
               when Overlapping =>
                  null;
            end case;
         when Exclusive_Or =>
            case Class is
               when B_In_A | A_In_B =>
                  --  Nested without hole support: return outer only.
                  if Class = B_In_A then
                     Append_Polygon (R, A);
                  else
                     Append_Polygon (R, B);
                  end if;
               when Disjoint =>
                  Append_Polygon (R, A);
                  Append_Polygon (R, B);
               when Overlapping =>
                  null;
            end case;
      end case;
      return R;
   end No_Hit_Result;

   function Clip_Two
     (Subject, Clip : Polygon;
      Op            : Boolean_Operation) return Polygon_Set
   is
      A : constant Polygon := Orient_Clockwise (Subject);
      B : constant Polygon := Orient_Clockwise (Clip);
      Hits : constant Intersection_List := Find_All_Intersections (A, B);
      Lists : Linked_Lists;
      R : Polygon_Set;
      Poly : Polygon;
      Idx : Natural;
      Guard : Natural;
      Want_Entry : Boolean;
   begin
      R.Count := 0;
      if Hits.Count = 0 then
         return No_Hit_Result (A, B, Op);
      end if;

      Lists := Build_Lists (A, B);

      case Op is
         when Intersection =>
            Want_Entry := True;
         when Union =>
            Want_Entry := False;
         when Difference =>
            --  Start where subject leaves the clip (exit = not entry).
            Want_Entry := False;
         when Exclusive_Or =>
            Want_Entry := True;  -- any unused intersection; use entry first
      end case;

      Guard := 0;
      Idx := Lists.A_Head;
      if Idx = 0 then
         return R;
      end if;
      loop
         Guard := Guard + 1;
         exit when Guard > Max_List_Nodes + 1;
         if Lists.A (Positive (Idx)).Source = Intersection_Vertex
           and then not Lists.A (Positive (Idx)).Visited
         then
            if Op = Exclusive_Or
              or else Lists.A (Positive (Idx)).Is_Entry = Want_Entry
            then
               Trace_Contour (Lists, Positive (Idx), Op, Poly);
               Append_Polygon (R, Poly);
            end if;
         end if;
         Idx := Lists.A (Positive (Idx)).Next;
         exit when Idx = Lists.A_Head;
      end loop;

      --  For Union of partially overlapping shapes, also start unused
      --  intersections that are exits if none collected (safety).
      if Op = Union and then R.Count = 0 then
         Guard := 0;
         Idx := Lists.A_Head;
         loop
            Guard := Guard + 1;
            exit when Guard > Max_List_Nodes + 1;
            if Lists.A (Positive (Idx)).Source = Intersection_Vertex
              and then not Lists.A (Positive (Idx)).Visited
            then
               Trace_Contour (Lists, Positive (Idx), Op, Poly);
               Append_Polygon (R, Poly);
            end if;
            Idx := Lists.A (Positive (Idx)).Next;
            exit when Idx = Lists.A_Head;
         end loop;
      end if;

      return R;
   end Clip_Two;

   function Merge_Sets (X, Y : Polygon_Set) return Polygon_Set is
      R : Polygon_Set;
   begin
      R.Count := 0;
      for I in 1 .. X.Count loop
         Append_Polygon (R, X.Polys (I));
      end loop;
      for I in 1 .. Y.Count loop
         Append_Polygon (R, Y.Polys (I));
      end loop;
      return R;
   end Merge_Sets;

   function Vatti_Clip
     (Subject, Clip : Polygon;
      Op            : Boolean_Operation) return Polygon_Set
   is
   begin
      if Op = Exclusive_Or then
         --  Exclusive_Or = (S\C) ∪ (C\S) — robust for simple polygons.
         return Merge_Sets
           (Clip_Two (Subject, Clip, Difference),
            Clip_Two (Clip, Subject, Difference));
      else
         return Clip_Two (Subject, Clip, Op);
      end if;
   end Vatti_Clip;

   function Vatti_Clip
     (Subject, Clip : Polygon_Set;
      Op            : Boolean_Operation) return Polygon_Set
   is
      --  Educational multi-poly: reduce each set by successive union,
      --  then boolean the collapsed components pairwise / reduce.
      S : Polygon_Set := Subject;
      C : Polygon_Set := Clip;
      Acc : Polygon_Set;
      Part : Polygon_Set;
      Tmp : Polygon_Set;
   begin
      if S.Count = 0 or else C.Count = 0 then
         Acc.Count := 0;
         if Op = Union then
            return Merge_Sets (S, C);
         elsif Op = Difference then
            return S;
         else
            return Acc;
         end if;
      end if;

      --  Normalize orientations.
      for I in 1 .. S.Count loop
         if S.Polys (I).Count >= 3 then
            S.Polys (I) := Orient_Clockwise (S.Polys (I));
         end if;
      end loop;
      for I in 1 .. C.Count loop
         if C.Polys (I).Count >= 3 then
            C.Polys (I) := Orient_Clockwise (C.Polys (I));
         end if;
      end loop;

      case Op is
         when Intersection =>
            Acc.Count := 0;
            for I in 1 .. S.Count loop
               for J in 1 .. C.Count loop
                  Part := Clip_Two (S.Polys (I), C.Polys (J), Intersection);
                  for K in 1 .. Part.Count loop
                     Append_Polygon (Acc, Part.Polys (K));
                  end loop;
               end loop;
            end loop;
            return Acc;

         when Union =>
            --  Fold clip polygons into the accumulator via Clip_Two Union.
            Acc := S;
            for J in 1 .. C.Count loop
               Tmp.Count := 0;
               declare
                  Merged_C : Boolean := False;
                  U : Polygon_Set;
               begin
                  for I in 1 .. Acc.Count loop
                     U := Clip_Two (Acc.Polys (I), C.Polys (J), Union);
                     if U.Count = 0 then
                        Append_Polygon (Tmp, Acc.Polys (I));
                     else
                        Merged_C := True;
                        for K in 1 .. U.Count loop
                           Append_Polygon (Tmp, U.Polys (K));
                        end loop;
                     end if;
                  end loop;
                  if not Merged_C then
                     Append_Polygon (Tmp, C.Polys (J));
                  end if;
                  Acc := Tmp;
               end;
            end loop;
            return Acc;

         when Difference =>
            Acc := S;
            for J in 1 .. C.Count loop
               Tmp.Count := 0;
               for I in 1 .. Acc.Count loop
                  Part := Clip_Two (Acc.Polys (I), C.Polys (J), Difference);
                  for K in 1 .. Part.Count loop
                     Append_Polygon (Tmp, Part.Polys (K));
                  end loop;
               end loop;
               Acc := Tmp;
            end loop;
            return Acc;

         when Exclusive_Or =>
            return Merge_Sets
              (Vatti_Clip (S, C, Difference),
               Vatti_Clip (C, S, Difference));
      end case;
   end Vatti_Clip;

   function Vatti_Intersection
     (Subject, Clip : Polygon) return Polygon_Set is
   begin
      return Vatti_Clip (Subject, Clip, Intersection);
   end Vatti_Intersection;

   function Vatti_Union
     (Subject, Clip : Polygon) return Polygon_Set is
   begin
      return Vatti_Clip (Subject, Clip, Union);
   end Vatti_Union;

   function Vatti_Difference
     (Subject, Clip : Polygon) return Polygon_Set is
   begin
      return Vatti_Clip (Subject, Clip, Difference);
   end Vatti_Difference;

   function Vatti_Xor
     (Subject, Clip : Polygon) return Polygon_Set is
   begin
      return Vatti_Clip (Subject, Clip, Exclusive_Or);
   end Vatti_Xor;

   function Vatti_Intersection
     (Subject, Clip : Polygon_Set) return Polygon_Set is
   begin
      return Vatti_Clip (Subject, Clip, Intersection);
   end Vatti_Intersection;

   function Vatti_Union
     (Subject, Clip : Polygon_Set) return Polygon_Set is
   begin
      return Vatti_Clip (Subject, Clip, Union);
   end Vatti_Union;

   function Vatti_Difference
     (Subject, Clip : Polygon_Set) return Polygon_Set is
   begin
      return Vatti_Clip (Subject, Clip, Difference);
   end Vatti_Difference;

   function Vatti_Xor
     (Subject, Clip : Polygon_Set) return Polygon_Set is
   begin
      return Vatti_Clip (Subject, Clip, Exclusive_Or);
   end Vatti_Xor;

end Vatti;
