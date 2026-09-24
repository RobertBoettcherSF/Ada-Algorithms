--  Collision_Detection body — discrete 2-D educational survey.

pragma Ada_2022;


package body Collision_Detection is


   -------------------------------------------------------------------------
   -- Numeric helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Dot (A, B : Point) return Real is
   begin
      return A.X * B.X + A.Y * B.Y;
   end Dot;

   function Cross (A, B : Point) return Real is
   begin
      return A.X * B.Y - A.Y * B.X;
   end Cross;

   function Sub (A, B : Point) return Point is
   begin
      return (X => A.X - B.X, Y => A.Y - B.Y);
   end Sub;

   function Dist2 (A, B : Point) return Real is
      D : constant Point := Sub (A, B);
   begin
      return Dot (D, D);
   end Dist2;

   function Orient2D (A, B, C : Point) return Real is
      BA : constant Point := Sub (A => B, B => A);
      CA : constant Point := Sub (A => C, B => A);
   begin
      return Cross (A => BA, B => CA);
   end Orient2D;

   -------------------------------------------------------------------------
   -- Validation / constructors
   -------------------------------------------------------------------------

   function Is_Valid_AABB (Box : AABB) return Boolean is
   begin
      return Box.Min.X <= Box.Max.X and then Box.Min.Y <= Box.Max.Y;
   end Is_Valid_AABB;

   function Is_Valid_Circle (C : Circle) return Boolean is
   begin
      return C.Radius >= 0.0;
   end Is_Valid_Circle;

   function Make_AABB (Min_X, Min_Y, Max_X, Max_Y : Real) return AABB is
   begin
      if Max_X < Min_X or else Max_Y < Min_Y then
         raise Invalid_Argument;
      end if;
      return (Min => (X => Min_X, Y => Min_Y),
              Max => (X => Max_X, Y => Max_Y));
   end Make_AABB;

   function Make_Circle (Cx, Cy, Radius : Real) return Circle is
   begin
      if Radius < 0.0 then
         raise Invalid_Argument;
      end if;
      return (Center => (X => Cx, Y => Cy), Radius => Radius);
   end Make_Circle;

   function Empty_Pair_List return Pair_List is
   begin
      return (Items => [others => (1, 1)], Count => 0);
   end Empty_Pair_List;

   procedure Clear (P : in out Pair_List) is
   begin
      P.Count := 0;
   end Clear;

   function Make_Pair (A, B : Object_Id) return Pair is
   begin
      if A < B then
         return (A => A, B => B);
      else
         return (A => B, B => A);
      end if;
   end Make_Pair;

   function Contains_Pair (P : Pair_List; A, B : Object_Id) return Boolean is
      Canon : constant Pair := Make_Pair (A, B);
   begin
      for I in 1 .. P.Count loop
         if P.Items (I).A = Canon.A and then P.Items (I).B = Canon.B then
            return True;
         end if;
      end loop;
      return False;
   end Contains_Pair;

   procedure Append_Pair (P : in out Pair_List; A, B : Object_Id) is
      Canon : constant Pair := Make_Pair (A, B);
   begin
      if Contains_Pair (P, A, B) then
         return;
      end if;
      if P.Count = Max_Pairs then
         raise Invalid_Argument;
      end if;
      P.Count := P.Count + 1;
      P.Items (P.Count) := Canon;
   end Append_Pair;

   procedure Normalize_Pairs (P : in out Pair_List) is
      --  Insertion sort by (A, B), then unique.
      Tmp   : Pair;
      Write : Pair_Count;
   begin
      for I in 2 .. P.Count loop
         Tmp := P.Items (I);
         declare
            J : Natural := I - 1;
         begin
            while J >= 1
              and then (P.Items (J).A > Tmp.A
                        or else (P.Items (J).A = Tmp.A
                                 and then P.Items (J).B > Tmp.B))
            loop
               P.Items (J + 1) := P.Items (J);
               J := J - 1;
            end loop;
            P.Items (J + 1) := Tmp;
         end;
      end loop;

      if P.Count = 0 then
         return;
      end if;

      Write := 1;
      for I in 2 .. P.Count loop
         if P.Items (I).A /= P.Items (Write).A
           or else P.Items (I).B /= P.Items (Write).B
         then
            Write := Write + 1;
            P.Items (Write) := P.Items (I);
         end if;
      end loop;
      P.Count := Write;
   end Normalize_Pairs;

   function Same_Pair_Set (Left, Right : Pair_List) return Boolean is
      L : Pair_List := Left;
      R : Pair_List := Right;
   begin
      Normalize_Pairs (L);
      Normalize_Pairs (R);
      if L.Count /= R.Count then
         return False;
      end if;
      for I in 1 .. L.Count loop
         if L.Items (I).A /= R.Items (I).A
           or else L.Items (I).B /= R.Items (I).B
         then
            return False;
         end if;
      end loop;
      return True;
   end Same_Pair_Set;

   -------------------------------------------------------------------------
   -- Narrow phase
   -------------------------------------------------------------------------

   function AABB_Overlap (A, B : AABB) return Boolean is
   begin
      if not Is_Valid_AABB (A) or else not Is_Valid_AABB (B) then
         raise Invalid_Argument;
      end if;
      return A.Max.X >= B.Min.X and then B.Max.X >= A.Min.X
        and then A.Max.Y >= B.Min.Y and then B.Max.Y >= A.Min.Y;
   end AABB_Overlap;

   function Circle_Overlap
     (C1 : Point; R1 : Real; C2 : Point; R2 : Real) return Boolean
   is
      Sum : Real;
   begin
      if R1 < 0.0 or else R2 < 0.0 then
         raise Invalid_Argument;
      end if;
      Sum := R1 + R2;
      return Dist2 (C1, C2) <= Sum * Sum;
   end Circle_Overlap;

   function Circle_Overlap (A, B : Circle) return Boolean is
   begin
      return Circle_Overlap (A.Center, A.Radius, B.Center, B.Radius);
   end Circle_Overlap;

   --  Project polygon onto axis (Nx, Ny); return [Min, Max] scalar range.
   procedure Project_Polygon
     (Poly     : Polygon;
      Nx, Ny   : Real;
      Min, Max : out Real)
   is
      Val : Real;
   begin
      Min := Poly (Poly'First).X * Nx + Poly (Poly'First).Y * Ny;
      Max := Min;
      for I in Poly'First + 1 .. Poly'Last loop
         Val := Poly (I).X * Nx + Poly (I).Y * Ny;
         if Val < Min then
            Min := Val;
         elsif Val > Max then
            Max := Val;
         end if;
      end loop;
   end Project_Polygon;

   function Axis_Separated
     (A, B : Polygon; Edge_From, Edge_To : Point) return Boolean
   is
      --  Outward-ish normal of edge (left perp of edge for CCW polygon).
      Ex : constant Real := Edge_To.X - Edge_From.X;
      Ey : constant Real := Edge_To.Y - Edge_From.Y;
      Nx : constant Real := -Ey;
      Ny : constant Real := Ex;
      A_Min, A_Max, B_Min, B_Max : Real;
   begin
      --  Degenerate edge → skip (treat as not separating).
      if Near (Ex, 0.0) and then Near (Ey, 0.0) then
         return False;
      end if;
      Project_Polygon (A, Nx, Ny, A_Min, A_Max);
      Project_Polygon (B, Nx, Ny, B_Min, B_Max);
      --  Closed: separated only if a gap strictly between projections.
      return A_Max < B_Min or else B_Max < A_Min;
   end Axis_Separated;

   function Convex_Polygons_Overlap (A, B : Polygon) return Boolean is
      N_A : constant Natural := A'Length;
      N_B : constant Natural := B'Length;
   begin
      if N_A < 3 or else N_B < 3
        or else N_A > Max_Vertices or else N_B > Max_Vertices
      then
         raise Invalid_Argument;
      end if;

      --  Axes from edges of A.
      for I in A'Range loop
         declare
            J : constant Vertex_Index :=
              (if I = A'Last then A'First else I + 1);
         begin
            if Axis_Separated (A, B, A (I), A (J)) then
               return False;
            end if;
         end;
      end loop;

      --  Axes from edges of B.
      for I in B'Range loop
         declare
            J : constant Vertex_Index :=
              (if I = B'Last then B'First else I + 1);
         begin
            if Axis_Separated (A, B, B (I), B (J)) then
               return False;
            end if;
         end;
      end loop;

      return True;
   end Convex_Polygons_Overlap;

   function On_Segment (P, A, B : Point) return Boolean is
      --  P on closed segment AB assuming collinearity.
   begin
      return P.X >= Real'Min (A.X, B.X) - Epsilon
        and then P.X <= Real'Max (A.X, B.X) + Epsilon
        and then P.Y >= Real'Min (A.Y, B.Y) - Epsilon
        and then P.Y <= Real'Max (A.Y, B.Y) + Epsilon;
   end On_Segment;

   function Segments_Intersect
     (P1, Q1, P2, Q2 : Point) return Boolean
   is
      O1, O2, O3, O4 : Real;
   begin
      if Dist2 (P1, Q1) <= Epsilon * Epsilon
        or else Dist2 (P2, Q2) <= Epsilon * Epsilon
      then
         raise Invalid_Argument;
      end if;

      O1 := Orient2D (P1, Q1, P2);
      O2 := Orient2D (P1, Q1, Q2);
      O3 := Orient2D (P2, Q2, P1);
      O4 := Orient2D (P2, Q2, Q1);

      --  Proper intersection: general case.
      if ((O1 > Epsilon and then O2 < -Epsilon)
          or else (O1 < -Epsilon and then O2 > Epsilon))
        and then
        ((O3 > Epsilon and then O4 < -Epsilon)
         or else (O3 < -Epsilon and then O4 > Epsilon))
      then
         return True;
      end if;

      --  Improper / collinear endpoint-on-segment cases.
      if abs (O1) <= Epsilon and then On_Segment (P2, P1, Q1) then
         return True;
      end if;
      if abs (O2) <= Epsilon and then On_Segment (Q2, P1, Q1) then
         return True;
      end if;
      if abs (O3) <= Epsilon and then On_Segment (P1, P2, Q2) then
         return True;
      end if;
      if abs (O4) <= Epsilon and then On_Segment (Q1, P2, Q2) then
         return True;
      end if;

      return False;
   end Segments_Intersect;

   -------------------------------------------------------------------------
   -- Broad phase
   -------------------------------------------------------------------------

   procedure Require_AABB_Array (Boxes : AABB_Array) is
   begin
      if Boxes'Length = 0 or else Boxes'Length > Max_Objects then
         raise Invalid_Argument;
      end if;
      for I in Boxes'Range loop
         if not Is_Valid_AABB (Boxes (I)) then
            raise Invalid_Argument;
         end if;
      end loop;
   end Require_AABB_Array;

   procedure Require_Circle_Array (Circles : Circle_Array) is
   begin
      if Circles'Length = 0 or else Circles'Length > Max_Objects then
         raise Invalid_Argument;
      end if;
      for I in Circles'Range loop
         if not Is_Valid_Circle (Circles (I)) then
            raise Invalid_Argument;
         end if;
      end loop;
   end Require_Circle_Array;

   function Brute_Force_Pairs (Boxes : AABB_Array) return Pair_List is
      Result : Pair_List := Empty_Pair_List;
      Id_A, Id_B : Object_Id;
      Offset : constant Integer := Integer (Boxes'First) - 1;
   begin
      Require_AABB_Array (Boxes);
      for I in Boxes'Range loop
         for J in I + 1 .. Boxes'Last loop
            if AABB_Overlap (Boxes (I), Boxes (J)) then
               Id_A := Object_Id (Integer (I) - Offset);
               Id_B := Object_Id (Integer (J) - Offset);
               Append_Pair (Result, Id_A, Id_B);
            end if;
         end loop;
      end loop;
      Normalize_Pairs (Result);
      return Result;
   end Brute_Force_Pairs;

   function Brute_Force_Pairs (Circles : Circle_Array) return Pair_List is
      Result : Pair_List := Empty_Pair_List;
      Id_A, Id_B : Object_Id;
      Offset : constant Integer := Integer (Circles'First) - 1;
   begin
      Require_Circle_Array (Circles);
      for I in Circles'Range loop
         for J in I + 1 .. Circles'Last loop
            if Circle_Overlap (Circles (I), Circles (J)) then
               Id_A := Object_Id (Integer (I) - Offset);
               Id_B := Object_Id (Integer (J) - Offset);
               Append_Pair (Result, Id_A, Id_B);
            end if;
         end loop;
      end loop;
      Normalize_Pairs (Result);
      return Result;
   end Brute_Force_Pairs;

   function Sweep_And_Prune_Pairs (Boxes : AABB_Array) return Pair_List is
      Result : Pair_List := Empty_Pair_List;
      Offset : constant Integer := Integer (Boxes'First) - 1;

      --  Endpoint list: Value, Is_Start, Obj index into Boxes.
      type Ep_Kind is (Start_Ep, End_Ep);
      type Ep is record
         Value : Real := 0.0;
         Kind  : Ep_Kind := Start_Ep;
         Idx   : Object_Id := 1;
      end record;
      type Ep_Arr is array (1 .. Max_Objects * 2) of Ep;
      Eps   : Ep_Arr;
      Count : Natural := 0;

      --  Active set of object indices currently under the sweep line.
      Active : array (1 .. Max_Objects) of Object_Id := [others => 1];
      Active_N : Natural := 0;

      procedure Sort_Endpoints is
         Tmp : Ep;
      begin
         --  Insertion sort: Value ascending; on tie, Start before End
         --  so closed touching intervals still overlap.
         for I in 2 .. Count loop
            Tmp := Eps (I);
            declare
               J : Natural := I - 1;
               function Before (L, R : Ep) return Boolean is
               begin
                  if L.Value < R.Value then
                     return True;
                  elsif L.Value > R.Value then
                     return False;
                  else
                     --  Start (0) before End (1) on equal value.
                     return L.Kind = Start_Ep and then R.Kind = End_Ep;
                  end if;
               end Before;
            begin
               while J >= 1 and then Before (Tmp, Eps (J)) loop
                  Eps (J + 1) := Eps (J);
                  J := J - 1;
               end loop;
               Eps (J + 1) := Tmp;
            end;
         end loop;
      end Sort_Endpoints;

      procedure Add_Active (Idx : Object_Id) is
      begin
         Active_N := Active_N + 1;
         Active (Active_N) := Idx;
      end Add_Active;

      procedure Remove_Active (Idx : Object_Id) is
      begin
         for K in 1 .. Active_N loop
            if Active (K) = Idx then
               Active (K) := Active (Active_N);
               Active_N := Active_N - 1;
               return;
            end if;
         end loop;
      end Remove_Active;

   begin
      Require_AABB_Array (Boxes);
      for I in Boxes'Range loop
         Count := Count + 1;
         Eps (Count) :=
           (Value => Boxes (I).Min.X,
            Kind  => Start_Ep,
            Idx   => I);
         Count := Count + 1;
         Eps (Count) :=
           (Value => Boxes (I).Max.X,
            Kind  => End_Ep,
            Idx   => I);
      end loop;

      Sort_Endpoints;

      for E in 1 .. Count loop
         if Eps (E).Kind = Start_Ep then
            --  Pair new box with every currently active box (Y check).
            for K in 1 .. Active_N loop
               declare
                  I : constant Object_Id := Eps (E).Idx;
                  J : constant Object_Id := Active (K);
                  Id_A, Id_B : Object_Id;
               begin
                  if AABB_Overlap (Boxes (I), Boxes (J)) then
                     Id_A := Object_Id (Integer (I) - Offset);
                     Id_B := Object_Id (Integer (J) - Offset);
                     Append_Pair (Result, Id_A, Id_B);
                  end if;
               end;
            end loop;
            Add_Active (Eps (E).Idx);
         else
            Remove_Active (Eps (E).Idx);
         end if;
      end loop;

      Normalize_Pairs (Result);
      return Result;
   end Sweep_And_Prune_Pairs;

   function Find_Colliding_AABBs (Boxes : AABB_Array) return Pair_List is
   begin
      return Brute_Force_Pairs (Boxes);
   end Find_Colliding_AABBs;

   function Find_Colliding_Circles
     (Circles : Circle_Array) return Pair_List
   is
   begin
      return Brute_Force_Pairs (Circles);
   end Find_Colliding_Circles;

begin
   null;
end Collision_Detection;
