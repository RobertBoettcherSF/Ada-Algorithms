--  Binary_Space_Partitioning body — educational 2-D BSP implementation.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Binary_Space_Partitioning
  with SPARK_Mode => Off
is

   package EF renames Ada.Numerics.Elementary_Functions;

   -------------------------------------------------------------------------
   -- Numeric / vector helpers
   -------------------------------------------------------------------------

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

   function Norm (V : Vec2) return Non_Negative is
      N2 : constant Float := Float (V.X * V.X + V.Y * V.Y);
      N  : constant Float := EF.Sqrt (N2);
   begin
      return Non_Negative (Real (N));
   end Norm;

   function Normalize (V : Vec2) return Vec2 is
      N : constant Non_Negative := Norm (V);
   begin
      if N <= Epsilon then
         raise Degenerate_Geometry with "Normalize of near-zero vector";
      end if;
      return (V.X / Real (N), V.Y / Real (N));
   end Normalize;

   -------------------------------------------------------------------------
   -- Constructors
   -------------------------------------------------------------------------

   function Make_Segment (P0, P1 : Vec2) return Segment is
   begin
      return (P0, P1);
   end Make_Segment;

   function Length (S : Segment) return Non_Negative is
   begin
      return Norm (S.P1 - S.P0);
   end Length;

   function Make_Polygon
     (Verts : Vertex_Array;
      Count : Vertex_Count;
      Tag   : Natural := 0) return Polygon
   is
      P : Polygon;
   begin
      P.Count := Count;
      P.Tag   := Tag;
      for I in 1 .. Count loop
         P.Verts (I) := Verts (I);
      end loop;
      return P;
   end Make_Polygon;

   function Make_Rect_Polygon
     (X0, Y0, X1, Y1 : Real; Tag : Natural := 0) return Polygon
   is
      V : Vertex_Array := [others => (0.0, 0.0)];
   begin
      V (1) := (X0, Y0);
      V (2) := (X1, Y0);
      V (3) := (X1, Y1);
      V (4) := (X0, Y1);
      return Make_Polygon (V, 4, Tag);
   end Make_Rect_Polygon;

   function Make_Plane_From_Points (A, B : Vec2) return Plane2 is
      D : constant Vec2 := B - A;
      N : Vec2;
   begin
      if Near_Point (A, B) then
         raise Degenerate_Geometry with "Make_Plane_From_Points: A ≈ B";
      end if;
      --  Leftward unit normal (CCW): (-Dy, Dx)
      N := Normalize ((-D.Y, D.X));
      return (Normal => N, Offset => -Dot (N, A));
   end Make_Plane_From_Points;

   function Make_Plane_From_Polygon (P : Polygon) return Plane2 is
   begin
      if P.Count < 2 then
         raise Degenerate_Geometry with "Make_Plane_From_Polygon: need ≥2 verts";
      end if;
      return Make_Plane_From_Points (P.Verts (1), P.Verts (2));
   end Make_Plane_From_Polygon;

   function Make_Axis_Aligned_Plane
     (Vertical : Boolean; Coord : Real) return Plane2
   is
   begin
      if Vertical then
         return (Normal => (1.0, 0.0), Offset => -Coord);
      else
         return (Normal => (0.0, 1.0), Offset => -Coord);
      end if;
   end Make_Axis_Aligned_Plane;

   function Signed_Distance (P : Vec2; Plane : Plane2) return Real is
   begin
      return Dot (Plane.Normal, P) + Plane.Offset;
   end Signed_Distance;

   function Is_Empty_Tree (T : BSP_Tree) return Boolean is
   begin
      return T.Root = 0 or else T.Node_Count = 0;
   end Is_Empty_Tree;

   function Node_Count (T : BSP_Tree) return Natural is
   begin
      return Natural (T.Node_Count);
   end Node_Count;

   function Polygon_Count (T : BSP_Tree) return Natural is
   begin
      return Natural (T.Poly_Count);
   end Polygon_Count;

   -------------------------------------------------------------------------
   -- Classification
   -------------------------------------------------------------------------

   function Classify_Point (P : Vec2; Plane : Plane2) return Side is
      D : constant Real := Signed_Distance (P, Plane);
   begin
      if D > Epsilon then
         return Front;
      elsif D < -Epsilon then
         return Back;
      else
         return On_Plane;
      end if;
   end Classify_Point;

   function Relate_Polygon
     (Poly : Polygon; Plane : Plane2) return Polygon_Relation
   is
      Saw_Front : Boolean := False;
      Saw_Back  : Boolean := False;
   begin
      for I in 1 .. Poly.Count loop
         case Classify_Point (Poly.Verts (I), Plane) is
            when Front =>
               Saw_Front := True;
            when Back =>
               Saw_Back := True;
            when On_Plane =>
               null;
         end case;
         exit when Saw_Front and Saw_Back;
      end loop;
      if Saw_Front and Saw_Back then
         return Straddling;
      elsif Saw_Front then
         return Wholly_Front;
      elsif Saw_Back then
         return Wholly_Back;
      else
         return Coplanar;
      end if;
   end Relate_Polygon;

   function Classify_Polygon (Poly : Polygon; Plane : Plane2) return Side is
   begin
      case Relate_Polygon (Poly, Plane) is
         when Wholly_Front =>
            return Front;
         when Wholly_Back =>
            return Back;
         when Coplanar | Straddling =>
            return On_Plane;
      end case;
   end Classify_Polygon;

   -------------------------------------------------------------------------
   -- Segment split
   -------------------------------------------------------------------------

   function Split_Segment
     (S : Segment; Plane : Plane2) return Split_Segment_Result
   is
      R     : Split_Segment_Result;
      S0    : constant Side := Classify_Point (S.P0, Plane);
      S1    : constant Side := Classify_Point (S.P1, Plane);
      D0, D1, T : Real;
      Hit   : Vec2;
   begin
      if S0 = On_Plane and S1 = On_Plane then
         R.On_Count := 1;
         R.On_Seg   := S;
         return R;
      elsif S0 /= Back and S1 /= Back then
         --  wholly front or front+on
         R.Front_Count := 1;
         R.Front_Seg   := S;
         return R;
      elsif S0 /= Front and S1 /= Front then
         --  wholly back or back+on
         R.Back_Count := 1;
         R.Back_Seg   := S;
         return R;
      end if;

      --  Straddling: compute intersection
      D0 := Signed_Distance (S.P0, Plane);
      D1 := Signed_Distance (S.P1, Plane);
      if Near (D0, D1) then
         --  numerically flat; treat as on
         R.On_Count := 1;
         R.On_Seg   := S;
         return R;
      end if;
      T   := D0 / (D0 - D1);
      Hit := S.P0 + (T * (S.P1 - S.P0));

      if S0 = Front or else (S0 = On_Plane and S1 = Back) then
         R.Front_Count := 1;
         R.Front_Seg   := (S.P0, Hit);
         R.Back_Count  := 1;
         R.Back_Seg    := (Hit, S.P1);
      else
         R.Back_Count  := 1;
         R.Back_Seg    := (S.P0, Hit);
         R.Front_Count := 1;
         R.Front_Seg   := (Hit, S.P1);
      end if;
      return R;
   end Split_Segment;

   -------------------------------------------------------------------------
   -- Polygon split (Sutherland–Hodgman style against one plane)
   -------------------------------------------------------------------------

   procedure Append_Vertex (P : in out Polygon; V : Vec2) is
   begin
      if P.Count = Max_Vertices then
         raise Capacity_Exceeded with "Append_Vertex: polygon capacity";
      end if;
      --  Skip near-duplicate consecutive vertices
      if P.Count >= 1 and then Near_Point (P.Verts (P.Count), V) then
         return;
      end if;
      P.Count := P.Count + 1;
      P.Verts (P.Count) := V;
   end Append_Vertex;

   function Split_Polygon
     (Poly : Polygon; Plane : Plane2) return Split_Polygon_Result
   is
      R : Split_Polygon_Result;
      Rel : constant Polygon_Relation := Relate_Polygon (Poly, Plane);
   begin
      R.Front.Tag := Poly.Tag;
      R.Back.Tag  := Poly.Tag;
      R.On.Tag    := Poly.Tag;

      case Rel is
         when Wholly_Front =>
            R.Front := Poly;
            return R;
         when Wholly_Back =>
            R.Back := Poly;
            return R;
         when Coplanar =>
            R.On := Poly;
            return R;
         when Straddling =>
            null;
      end case;

      declare
         Prev : Vec2;
         Curr : Vec2;
         Sp   : Side;
         Sc   : Side;
         D0, D1, T : Real;
         Hit  : Vec2;
      begin
         Prev := Poly.Verts (Poly.Count);
         Sp   := Classify_Point (Prev, Plane);

         for I in 1 .. Poly.Count loop
            Curr := Poly.Verts (I);
            Sc   := Classify_Point (Curr, Plane);

            if Sc = On_Plane then
               Append_Vertex (R.Front, Curr);
               Append_Vertex (R.Back, Curr);
               Append_Vertex (R.On, Curr);
            elsif Sc = Front then
               if Sp = Back then
                  D0  := Signed_Distance (Prev, Plane);
                  D1  := Signed_Distance (Curr, Plane);
                  T   := D0 / (D0 - D1);
                  Hit := Prev + (T * (Curr - Prev));
                  Append_Vertex (R.Front, Hit);
                  Append_Vertex (R.Back, Hit);
               end if;
               Append_Vertex (R.Front, Curr);
            else
               --  Sc = Back
               if Sp = Front then
                  D0  := Signed_Distance (Prev, Plane);
                  D1  := Signed_Distance (Curr, Plane);
                  T   := D0 / (D0 - D1);
                  Hit := Prev + (T * (Curr - Prev));
                  Append_Vertex (R.Front, Hit);
                  Append_Vertex (R.Back, Hit);
               end if;
               Append_Vertex (R.Back, Curr);
            end if;

            Prev := Curr;
            Sp   := Sc;
         end loop;
      end;

      --  Drop degenerate remnants (< 3 verts)
      if R.Front.Count < 3 then
         R.Front.Count := 0;
      end if;
      if R.Back.Count < 3 then
         R.Back.Count := 0;
      end if;
      if R.On.Count < 2 then
         R.On.Count := 0;
      end if;
      return R;
   end Split_Polygon;

   -------------------------------------------------------------------------
   -- Tree pool helpers
   -------------------------------------------------------------------------

   function Alloc_Node (T : in out BSP_Tree) return Node_Index is
   begin
      if T.Node_Count = Max_Nodes then
         raise Capacity_Exceeded with "Alloc_Node: Max_Nodes exceeded";
      end if;
      T.Node_Count := T.Node_Count + 1;
      T.Nodes (T.Node_Count) :=
        (Plane      => (Normal => (1.0, 0.0), Offset => 0.0),
         Has_Plane  => False,
         Front      => 0,
         Back       => 0,
         Polys      => [others => 1],
         Poly_Count => 0,
         Is_Solid   => False);
      return T.Node_Count;
   end Alloc_Node;

   function Alloc_Poly (T : in out BSP_Tree; P : Polygon) return Poly_Pool_Index
   is
   begin
      if T.Poly_Count = Max_Polygons then
         raise Capacity_Exceeded with "Alloc_Poly: Max_Polygons exceeded";
      end if;
      T.Poly_Count := T.Poly_Count + 1;
      T.Polys (T.Poly_Count) := P;
      return T.Poly_Count;
   end Alloc_Poly;

   procedure Add_Poly_To_Node
     (T : in out BSP_Tree; N : Node_Index; P : Polygon)
   is
      Id : Poly_Pool_Index;
   begin
      if T.Nodes (N).Poly_Count >= Max_Polys_Per_Node then
         raise Capacity_Exceeded with "Add_Poly_To_Node: per-node capacity";
      end if;
      Id := Alloc_Poly (T, P);
      T.Nodes (N).Poly_Count := T.Nodes (N).Poly_Count + 1;
      T.Nodes (N).Polys (T.Nodes (N).Poly_Count) := Id;
   end Add_Poly_To_Node;

   -------------------------------------------------------------------------
   -- Splitter selection
   -------------------------------------------------------------------------

   function Count_Splits
     (Polys : Polygon_List; Count : Natural; Plane : Plane2) return Natural
   is
      N : Natural := 0;
   begin
      for I in 1 .. Count loop
         if Relate_Polygon (Polys (I), Plane) = Straddling then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count_Splits;

   function Choose_Splitter
     (Polys     : Polygon_List;
      Count     : Natural;
      Heuristic : Splitter_Heuristic) return Positive
   is
      Best_Idx   : Positive := 1;
      Best_Score : Natural := Natural'Last;
      Plane      : Plane2;
      Score      : Natural;
   begin
      if Count < 1 then
         raise Invalid_Argument with "Choose_Splitter: empty list";
      end if;
      if Heuristic = First_Polygon then
         return 1;
      end if;
      for I in 1 .. Count loop
         if Polys (I).Count >= 2 then
            begin
               Plane := Make_Plane_From_Polygon (Polys (I));
               Score := Count_Splits (Polys, Count, Plane);
               if Score < Best_Score then
                  Best_Score := Score;
                  Best_Idx   := I;
               end if;
            exception
               when Degenerate_Geometry =>
                  null;
            end;
         end if;
      end loop;
      return Best_Idx;
   end Choose_Splitter;

   -------------------------------------------------------------------------
   -- Recursive build
   -------------------------------------------------------------------------

   --  Working list stored as Polygon_List + count for recursion.
   procedure Build_Node
     (T         : in out BSP_Tree;
      Polys     : Polygon_List;
      Count     : Natural;
      Heuristic : Splitter_Heuristic;
      Parent    : out Node_Index;
      Depth     : Natural;
      KD_Mode   : Boolean;
      KD_Vert   : Boolean)
   is
      Idx     : Positive;
      Plane   : Plane2;
      Node    : Node_Index;
      Front_L : Polygon_List;
      Back_L  : Polygon_List;
      Front_N : Natural := 0;
      Back_N  : Natural := 0;
      Split   : Split_Polygon_Result;
      Rel     : Polygon_Relation;
      Mid_X, Mid_Y : Real;
      Use_Vert : Boolean;
   begin
      Parent := 0;
      if Count = 0 then
         return;
      end if;

      Node := Alloc_Node (T);
      Parent := Node;

      if KD_Mode then
         --  Axis-aligned splitter through centroid of first polygon bbox
         declare
            P : constant Polygon := Polys (1);
            X_Min : Real := P.Verts (1).X;
            X_Max : Real := P.Verts (1).X;
            Y_Min : Real := P.Verts (1).Y;
            Y_Max : Real := P.Verts (1).Y;
         begin
            for I in 1 .. P.Count loop
               if P.Verts (I).X < X_Min then
                  X_Min := P.Verts (I).X;
               end if;
               if P.Verts (I).X > X_Max then
                  X_Max := P.Verts (I).X;
               end if;
               if P.Verts (I).Y < Y_Min then
                  Y_Min := P.Verts (I).Y;
               end if;
               if P.Verts (I).Y > Y_Max then
                  Y_Max := P.Verts (I).Y;
               end if;
            end loop;
            Mid_X := 0.5 * (X_Min + X_Max);
            Mid_Y := 0.5 * (Y_Min + Y_Max);
            Use_Vert := KD_Vert;
            Plane := Make_Axis_Aligned_Plane (Use_Vert,
              (if Use_Vert then Mid_X else Mid_Y));
            --  Store first polygon at node as representative
            Add_Poly_To_Node (T, Node, Polys (1));
            T.Nodes (Node).Plane     := Plane;
            T.Nodes (Node).Has_Plane := True;
         end;

         for I in 1 .. Count loop
            if I = 1 then
               null;  -- already stored
            else
               Rel := Relate_Polygon (Polys (I), Plane);
               case Rel is
                  when Wholly_Front =>
                     Front_N := Front_N + 1;
                     Front_L (Front_N) := Polys (I);
                  when Wholly_Back =>
                     Back_N := Back_N + 1;
                     Back_L (Back_N) := Polys (I);
                  when Coplanar =>
                     Add_Poly_To_Node (T, Node, Polys (I));
                  when Straddling =>
                     Split := Split_Polygon (Polys (I), Plane);
                     if Split.Front.Count >= 3 then
                        Front_N := Front_N + 1;
                        Front_L (Front_N) := Split.Front;
                     end if;
                     if Split.Back.Count >= 3 then
                        Back_N := Back_N + 1;
                        Back_L (Back_N) := Split.Back;
                     end if;
                     if Split.On.Count >= 3 then
                        Add_Poly_To_Node (T, Node, Split.On);
                     end if;
               end case;
            end if;
         end loop;
      else
         --  Fuchs-style: choose splitter polygon
         Idx := Choose_Splitter (Polys, Count, Heuristic);
         begin
            Plane := Make_Plane_From_Polygon (Polys (Idx));
         exception
            when Degenerate_Geometry =>
               --  Degenerate splitter: stash all as coplanar leaf
               for I in 1 .. Count loop
                  Add_Poly_To_Node (T, Node, Polys (I));
               end loop;
               return;
         end;

         T.Nodes (Node).Plane     := Plane;
         T.Nodes (Node).Has_Plane := True;
         Add_Poly_To_Node (T, Node, Polys (Idx));

         for I in 1 .. Count loop
            if I = Idx then
               null;
            else
               Rel := Relate_Polygon (Polys (I), Plane);
               case Rel is
                  when Wholly_Front =>
                     Front_N := Front_N + 1;
                     if Front_N > Max_Input_Polygons then
                        raise Capacity_Exceeded
                          with "Build_Node: front list overflow";
                     end if;
                     Front_L (Front_N) := Polys (I);
                  when Wholly_Back =>
                     Back_N := Back_N + 1;
                     if Back_N > Max_Input_Polygons then
                        raise Capacity_Exceeded
                          with "Build_Node: back list overflow";
                     end if;
                     Back_L (Back_N) := Polys (I);
                  when Coplanar =>
                     Add_Poly_To_Node (T, Node, Polys (I));
                  when Straddling =>
                     Split := Split_Polygon (Polys (I), Plane);
                     if Split.Front.Count >= 3 then
                        Front_N := Front_N + 1;
                        if Front_N > Max_Input_Polygons then
                           raise Capacity_Exceeded
                             with "Build_Node: front list overflow";
                        end if;
                        Front_L (Front_N) := Split.Front;
                     end if;
                     if Split.Back.Count >= 3 then
                        Back_N := Back_N + 1;
                        if Back_N > Max_Input_Polygons then
                           raise Capacity_Exceeded
                             with "Build_Node: back list overflow";
                        end if;
                        Back_L (Back_N) := Split.Back;
                     end if;
                     if Split.On.Count >= 3 then
                        Add_Poly_To_Node (T, Node, Split.On);
                     end if;
               end case;
            end if;
         end loop;
      end if;

      --  Recurse (depth guard for KD / safety)
      if Front_N > 0 and then Depth < 32 then
         declare
            Child : Node_Index;
         begin
            Build_Node
              (T, Front_L, Front_N, Heuristic, Child, Depth + 1,
               KD_Mode, not KD_Vert);
            T.Nodes (Node).Front := Child;
         end;
      elsif Front_N = 0 and then not KD_Mode then
         --  Educational solid: empty front leaf can be marked open (not solid)
         null;
      end if;

      if Back_N > 0 and then Depth < 32 then
         declare
            Child : Node_Index;
         begin
            Build_Node
              (T, Back_L, Back_N, Heuristic, Child, Depth + 1,
               KD_Mode, not KD_Vert);
            T.Nodes (Node).Back := Child;
         end;
      end if;

      --  Mark empty back leaf as solid for educational Point_In_Solid when
      --  the node has a plane (space behind a wall tends to be "inside" for
      --  outward-facing CCW polygons). Only when no back child.
      if T.Nodes (Node).Back = 0 and then T.Nodes (Node).Has_Plane then
         declare
            Solid_Leaf : Node_Index;
         begin
            Solid_Leaf := Alloc_Node (T);
            T.Nodes (Solid_Leaf).Is_Solid := True;
            T.Nodes (Node).Back := Solid_Leaf;
         end;
      end if;
   end Build_Node;

   function Build_BSP
     (Polys      : Polygon_List;
      Count      : Input_Count;
      Heuristic  : Splitter_Heuristic := Least_Split) return BSP_Tree
   is
      T      : BSP_Tree;
      Root   : Node_Index;
      Filtered : Polygon_List;
      FCount : Natural := 0;
   begin
      if Count = 0 then
         return T;
      end if;
      for I in 1 .. Count loop
         if Polys (I).Count >= 3 then
            FCount := FCount + 1;
            Filtered (FCount) := Polys (I);
         end if;
      end loop;
      if FCount = 0 then
         return T;
      end if;
      Build_Node
        (T, Filtered, FCount, Heuristic, Root, 0,
         KD_Mode => False, KD_Vert => True);
      T.Root := Root;
      return T;
   end Build_BSP;

   function Build_KD_Style
     (Polys : Polygon_List;
      Count : Input_Count) return BSP_Tree
   is
      T      : BSP_Tree;
      Root   : Node_Index;
      Filtered : Polygon_List;
      FCount : Natural := 0;
   begin
      if Count = 0 then
         return T;
      end if;
      for I in 1 .. Count loop
         if Polys (I).Count >= 3 then
            FCount := FCount + 1;
            Filtered (FCount) := Polys (I);
         end if;
      end loop;
      if FCount = 0 then
         return T;
      end if;
      Build_Node
        (T, Filtered, FCount, First_Polygon, Root, 0,
         KD_Mode => True, KD_Vert => True);
      T.Root := Root;
      return T;
   end Build_KD_Style;

   -------------------------------------------------------------------------
   -- Traversal
   -------------------------------------------------------------------------

   procedure Emit_Node
     (T   : BSP_Tree;
      N   : Node_Index;
      Out_R : in out Traversal_Result)
   is
   begin
      for I in 1 .. T.Nodes (N).Poly_Count loop
         if Out_R.Count >= Max_Traversal_Output then
            raise Capacity_Exceeded with "Emit_Node: traversal capacity";
         end if;
         Out_R.Count := Out_R.Count + 1;
         Out_R.Entries (Out_R.Count) :=
           (Poly_Id => T.Nodes (N).Polys (I), Node_Id => N);
      end loop;
   end Emit_Node;

   procedure Walk
     (T     : BSP_Tree;
      N     : Node_Index;
      Eye   : Vec2;
      Order : Traversal_Order;
      Out_R : in out Traversal_Result)
   is
      S : Side;
   begin
      if N = 0 then
         return;
      end if;

      if not T.Nodes (N).Has_Plane then
         Emit_Node (T, N, Out_R);
         return;
      end if;

      S := Classify_Point (Eye, T.Nodes (N).Plane);

      case Order is
         when Back_To_Front =>
            --  Painter's: far side first, then node, then near side
            case S is
               when Front =>
                  Walk (T, T.Nodes (N).Back, Eye, Order, Out_R);
                  Emit_Node (T, N, Out_R);
                  Walk (T, T.Nodes (N).Front, Eye, Order, Out_R);
               when Back =>
                  Walk (T, T.Nodes (N).Front, Eye, Order, Out_R);
                  Emit_Node (T, N, Out_R);
                  Walk (T, T.Nodes (N).Back, Eye, Order, Out_R);
               when On_Plane =>
                  Walk (T, T.Nodes (N).Front, Eye, Order, Out_R);
                  Walk (T, T.Nodes (N).Back, Eye, Order, Out_R);
            end case;
         when Front_To_Back =>
            case S is
               when Front =>
                  Walk (T, T.Nodes (N).Front, Eye, Order, Out_R);
                  Emit_Node (T, N, Out_R);
                  Walk (T, T.Nodes (N).Back, Eye, Order, Out_R);
               when Back =>
                  Walk (T, T.Nodes (N).Back, Eye, Order, Out_R);
                  Emit_Node (T, N, Out_R);
                  Walk (T, T.Nodes (N).Front, Eye, Order, Out_R);
               when On_Plane =>
                  Walk (T, T.Nodes (N).Front, Eye, Order, Out_R);
                  Walk (T, T.Nodes (N).Back, Eye, Order, Out_R);
            end case;
      end case;
   end Walk;

   function Traverse
     (T     : BSP_Tree;
      Eye   : Vec2;
      Order : Traversal_Order) return Traversal_Result
   is
      R : Traversal_Result;
   begin
      if not Is_Empty_Tree (T) then
         Walk (T, T.Root, Eye, Order, R);
      end if;
      return R;
   end Traverse;

   function Traverse_Back_To_Front
     (T : BSP_Tree; Eye : Vec2) return Traversal_Result
   is
   begin
      return Traverse (T, Eye, Back_To_Front);
   end Traverse_Back_To_Front;

   function Traverse_Front_To_Back
     (T : BSP_Tree; Eye : Vec2) return Traversal_Result
   is
   begin
      return Traverse (T, Eye, Front_To_Back);
   end Traverse_Front_To_Back;

   -------------------------------------------------------------------------
   -- Point queries
   -------------------------------------------------------------------------

   function Point_In_Solid (T : BSP_Tree; P : Vec2) return Boolean is
      N : Node_Index := T.Root;
      S : Side;
   begin
      if Is_Empty_Tree (T) then
         return False;
      end if;
      while N /= 0 loop
         if not T.Nodes (N).Has_Plane then
            return T.Nodes (N).Is_Solid;
         end if;
         S := Classify_Point (P, T.Nodes (N).Plane);
         case S is
            when Front =>
               if T.Nodes (N).Front = 0 then
                  return False;
               end if;
               N := T.Nodes (N).Front;
            when Back =>
               if T.Nodes (N).Back = 0 then
                  return T.Nodes (N).Is_Solid;
               end if;
               N := T.Nodes (N).Back;
            when On_Plane =>
               --  Prefer front for on-plane
               if T.Nodes (N).Front /= 0 then
                  N := T.Nodes (N).Front;
               elsif T.Nodes (N).Back /= 0 then
                  N := T.Nodes (N).Back;
               else
                  return T.Nodes (N).Is_Solid;
               end if;
         end case;
      end loop;
      return False;
   end Point_In_Solid;

   function Classify_Point_In_Tree (T : BSP_Tree; P : Vec2) return Side is
      N    : Node_Index := T.Root;
      Last : Side := On_Plane;
      S    : Side;
   begin
      if Is_Empty_Tree (T) then
         return On_Plane;
      end if;
      while N /= 0 and then T.Nodes (N).Has_Plane loop
         S := Classify_Point (P, T.Nodes (N).Plane);
         Last := S;
         case S is
            when Front =>
               N := T.Nodes (N).Front;
            when Back =>
               N := T.Nodes (N).Back;
            when On_Plane =>
               if T.Nodes (N).Front /= 0 then
                  N := T.Nodes (N).Front;
               else
                  N := T.Nodes (N).Back;
               end if;
         end case;
      end loop;
      return Last;
   end Classify_Point_In_Tree;

   -------------------------------------------------------------------------
   -- Ray / segment collision lite
   -------------------------------------------------------------------------

   function Segment_Segment_Hit
     (A, B : Segment; Point : out Vec2; T_Out : out Real) return Boolean
   is
      --  Parametric intersection of A (P0 + t*(P1-P0)) with B.
      R, S, Q_P : Vec2;
      Rxs : Real;
      T, U      : Real;
   begin
      T_Out := 0.0;
      Point := (0.0, 0.0);
      R   := A.P1 - A.P0;
      S   := B.P1 - B.P0;
      Q_P := B.P0 - A.P0;
      Rxs := Cross_Z (R, S);
      if abs (Rxs) <= Epsilon then
         return False;  -- parallel / collinear — skip for educational lite
      end if;
      T := Cross_Z (Q_P, S) / Rxs;
      U := Cross_Z (Q_P, R) / Rxs;
      if T >= 0.0 and then T <= 1.0 and then U >= 0.0 and then U <= 1.0 then
         T_Out := T;
         Point := A.P0 + (T * R);
         return True;
      end if;
      return False;
   end Segment_Segment_Hit;

   function Poly_Edges_Hit
     (Poly : Polygon; Ray : Segment; Point : out Vec2; T_Out : out Real)
      return Boolean
   is
      Best_T : Real := Real'Last;
      Best_P : Vec2 := (0.0, 0.0);
      Found  : Boolean := False;
      Edge   : Segment;
      Hit_P  : Vec2;
      Hit_T  : Real;
      Prev   : Vec2;
   begin
      T_Out := 0.0;
      Point := (0.0, 0.0);
      if Poly.Count < 2 then
         return False;
      end if;
      Prev := Poly.Verts (Poly.Count);
      for I in 1 .. Poly.Count loop
         Edge := (Prev, Poly.Verts (I));
         if Segment_Segment_Hit (Ray, Edge, Hit_P, Hit_T) then
            if Hit_T < Best_T and then Hit_T >= 0.0 then
               Best_T := Hit_T;
               Best_P := Hit_P;
               Found  := True;
            end if;
         end if;
         Prev := Poly.Verts (I);
      end loop;
      if Found then
         T_Out := Best_T;
         Point := Best_P;
         return True;
      end if;
      return False;
   end Poly_Edges_Hit;

   procedure Ray_Walk
     (T       : BSP_Tree;
      N       : Node_Index;
      Ray     : Segment;
      Best    : in out Ray_Hit)
   is
      S0, S1 : Side;
      Mid    : Vec2;
      D0, D1, Tv : Real;
      Near_Child, Far_Child : Node_Index;
      Hit_P : Vec2;
      Hit_T : Real;
      Dist  : Non_Negative;
   begin
      if N = 0 then
         return;
      end if;

      --  Test polygons stored at this node
      for I in 1 .. T.Nodes (N).Poly_Count loop
         declare
            Pid : constant Poly_Pool_Index := T.Nodes (N).Polys (I);
         begin
            if Poly_Edges_Hit (T.Polys (Pid), Ray, Hit_P, Hit_T) then
               Dist := Non_Negative (Hit_T) * Length (Ray);
               if (not Best.Hit) or else Hit_T < Best.T then
                  Best :=
                    (Hit      => True,
                     Point    => Hit_P,
                     T        => Hit_T,
                     Poly_Id  => Pid,
                     Distance => Dist);
               end if;
            end if;
         end;
      end loop;

      if not T.Nodes (N).Has_Plane then
         return;
      end if;

      S0 := Classify_Point (Ray.P0, T.Nodes (N).Plane);
      S1 := Classify_Point (Ray.P1, T.Nodes (N).Plane);

      if S0 = Front and S1 = Front then
         Ray_Walk (T, T.Nodes (N).Front, Ray, Best);
      elsif S0 = Back and S1 = Back then
         Ray_Walk (T, T.Nodes (N).Back, Ray, Best);
      elsif S0 = On_Plane and S1 = On_Plane then
         Ray_Walk (T, T.Nodes (N).Front, Ray, Best);
         Ray_Walk (T, T.Nodes (N).Back, Ray, Best);
      else
         --  straddling or on+side: visit near then far
         D0 := Signed_Distance (Ray.P0, T.Nodes (N).Plane);
         D1 := Signed_Distance (Ray.P1, T.Nodes (N).Plane);
         if abs (D0 - D1) > Epsilon then
            Tv  := D0 / (D0 - D1);
            Mid := Ray.P0 + (Tv * (Ray.P1 - Ray.P0));
         else
            Mid := Ray.P0;
            Tv  := 0.0;
         end if;
         pragma Unreferenced (Mid, Tv);

         if S0 = Front or else (S0 = On_Plane and S1 = Back) then
            Near_Child := T.Nodes (N).Front;
            Far_Child  := T.Nodes (N).Back;
         else
            Near_Child := T.Nodes (N).Back;
            Far_Child  := T.Nodes (N).Front;
         end if;
         Ray_Walk (T, Near_Child, Ray, Best);
         --  Continue to far side always for correctness (lite may over-test)
         Ray_Walk (T, Far_Child, Ray, Best);
      end if;
   end Ray_Walk;

   function Ray_Cast_2D (T : BSP_Tree; Ray : Segment) return Ray_Hit is
      Best : Ray_Hit;
   begin
      if Is_Empty_Tree (T) then
         return Best;
      end if;
      if Length (Ray) <= Epsilon then
         return Best;
      end if;
      Ray_Walk (T, T.Root, Ray, Best);
      return Best;
   end Ray_Cast_2D;

   function Segment_Hits_Tree
     (T : BSP_Tree; S : Segment) return Boolean
   is
      H : constant Ray_Hit := Ray_Cast_2D (T, S);
   begin
      return H.Hit;
   end Segment_Hits_Tree;

end Binary_Space_Partitioning;
