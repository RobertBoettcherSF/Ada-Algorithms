--  Sutherland_Hodgman body — half-plane tests, edge clip pass,
--  intersection, full SH iteration, rect / frustum helpers, and
--  educational single-plane 3-D polygon clip.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Sutherland_Hodgman
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

   function Next_Index (I, Count : Positive) return Positive is
   begin
      if I = Count then
         return 1;
      else
         return I + 1;
      end if;
   end Next_Index;

   procedure Append_Vertex (P : in out Polygon; V : Vec2) is
   begin
      if P.Count = Max_Vertices then
         raise Capacity_Exceeded
           with "Polygon exceeded Max_Vertices";
      end if;
      P.Count := P.Count + 1;
      P.Verts (P.Count) := V;
   end Append_Vertex;

   procedure Append_Vertex3 (P : in out Polygon3; V : Vec3) is
   begin
      if P.Count = Max_Vertices then
         raise Capacity_Exceeded
           with "Polygon3 exceeded Max_Vertices";
      end if;
      P.Count := P.Count + 1;
      P.Verts (P.Count) := V;
   end Append_Vertex3;

   -----------------------------------------------------------------------
   -- Vector helpers (2-D)
   -----------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Point (A, B : Vec2; Tol : Real := Epsilon) return Boolean is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
   end Near_Point;

   function Near_Point3 (A, B : Vec3; Tol : Real := Epsilon) return Boolean is
   begin
      return Near (A.X, B.X, Tol)
        and then Near (A.Y, B.Y, Tol)
        and then Near (A.Z, B.Z, Tol);
   end Near_Point3;

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
   -- Vector helpers (3-D)
   -----------------------------------------------------------------------

   function "-" (A, B : Vec3) return Vec3 is
   begin
      return (A.X - B.X, A.Y - B.Y, A.Z - B.Z);
   end "-";

   function "+" (A, B : Vec3) return Vec3 is
   begin
      return (A.X + B.X, A.Y + B.Y, A.Z + B.Z);
   end "+";

   function "*" (S : Real; V : Vec3) return Vec3 is
   begin
      return (S * V.X, S * V.Y, S * V.Z);
   end "*";

   function Dot3 (A, B : Vec3) return Real is
   begin
      return A.X * B.X + A.Y * B.Y + A.Z * B.Z;
   end Dot3;

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
      Orient : Orientation := Counter_Clockwise) return Polygon
   is
      P : Polygon;
   begin
      P.Count := 4;
      --  Default listing is counter-clockwise starting at lower-left
      --  (matches Wikipedia SH: left of each edge is inside).
      P.Verts (1) := (Min_X, Min_Y);
      P.Verts (2) := (Max_X, Min_Y);
      P.Verts (3) := (Max_X, Max_Y);
      P.Verts (4) := (Min_X, Max_Y);
      if Orient = Clockwise then
         Reverse_Vertices (P);
      end if;
      return P;
   end Make_Rectangle;

   function Make_Triangle
     (A, B, C : Vec2;
      Orient  : Orientation := Counter_Clockwise) return Polygon
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
      if Orient = Counter_Clockwise and then Area2 < 0.0 then
         Reverse_Vertices (P);
      elsif Orient = Clockwise and then Area2 > 0.0 then
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

   function Orient_Counter_Clockwise (P : Polygon) return Polygon is
      R : Polygon := Polygon_Copy (P);
   begin
      if Polygon_Orientation (R) = Clockwise then
         Reverse_Vertices (R);
      end if;
      return R;
   end Orient_Counter_Clockwise;

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

   -----------------------------------------------------------------------
   -- Is_Convex_Polygon
   -----------------------------------------------------------------------

   function Is_Convex_Polygon (P : Polygon) return Boolean is
      Prev_Cross : Real := 0.0;
      Cross      : Real;
      I1, I2, I3 : Positive;
      Found_Sign : Boolean := False;
   begin
      if P.Count < 3 then
         return False;
      end if;
      for I in 1 .. P.Count loop
         I1 := I;
         I2 := Next_Index (I1, Positive (P.Count));
         I3 := Next_Index (I2, Positive (P.Count));
         Cross := Cross_Z
           (P.Verts (I2) - P.Verts (I1),
            P.Verts (I3) - P.Verts (I2));
         if abs (Cross) > Epsilon then
            if not Found_Sign then
               Prev_Cross := Cross;
               Found_Sign := True;
            elsif Cross * Prev_Cross < 0.0 then
               return False;
            end if;
         end if;
      end loop;
      return Found_Sign;
   end Is_Convex_Polygon;

   -----------------------------------------------------------------------
   -- Inside_HalfPlane / Compute_Intersection / Clip_Against_Edge
   -----------------------------------------------------------------------

   function Inside_HalfPlane
     (P           : Vec2;
      Clip_Edge   : Edge;
      Inside_Left : Boolean := True) return Boolean
   is
      Cross : constant Real :=
        Cross_Z (Clip_Edge.B - Clip_Edge.A, P - Clip_Edge.A);
   begin
      if Inside_Left then
         return Cross >= -Epsilon;
      else
         return Cross <= Epsilon;
      end if;
   end Inside_HalfPlane;

   function Compute_Intersection
     (P0, P1    : Vec2;
      Clip_Edge : Edge) return Vec2
   is
      --  Line P0 + T*(P1-P0) intersects Clip_Edge.A + U*(B-A).
      D1 : constant Vec2 := P1 - P0;
      D2 : constant Vec2 := Clip_Edge.B - Clip_Edge.A;
      Den : constant Real := Cross_Z (D1, D2);
      Diff : constant Vec2 := Clip_Edge.A - P0;
      T    : Real;
   begin
      if abs (Den) < Epsilon then
         raise Degenerate_Geometry
           with "Compute_Intersection: parallel / coincident lines";
      end if;
      T := Cross_Z (Diff, D2) / Den;
      return P0 + T * D1;
   end Compute_Intersection;

   function Clip_Against_Edge
     (Subject     : Polygon;
      Clip_Edge   : Edge;
      Inside_Left : Boolean := True) return Polygon
   is
      Output  : Polygon;
      Curr    : Vec2;
      Prev    : Vec2;
      Curr_In : Boolean;
      Prev_In : Boolean;
   begin
      if Subject.Count = 0 then
         return Output;
      end if;

      Prev := Subject.Verts (Subject.Count);
      Prev_In := Inside_HalfPlane (Prev, Clip_Edge, Inside_Left);

      for I in 1 .. Subject.Count loop
         Curr := Subject.Verts (I);
         Curr_In := Inside_HalfPlane (Curr, Clip_Edge, Inside_Left);

         if Curr_In then
            if not Prev_In then
               Append_Vertex
                 (Output, Compute_Intersection (Prev, Curr, Clip_Edge));
            end if;
            Append_Vertex (Output, Curr);
         elsif Prev_In then
            Append_Vertex
              (Output, Compute_Intersection (Prev, Curr, Clip_Edge));
         end if;

         Prev := Curr;
         Prev_In := Curr_In;
      end loop;

      return Output;
   end Clip_Against_Edge;

   -----------------------------------------------------------------------
   -- Sutherland_Hodgman_Clip / Clip_Against_Rect / Frustum_2D
   -----------------------------------------------------------------------

   function Sutherland_Hodgman_Clip
     (Subject, Clip : Polygon) return Polygon
   is
      Output      : Polygon := Polygon_Copy (Subject);
      Inside_Left : Boolean;
      E           : Edge;
      J           : Positive;
   begin
      if not Is_Convex_Polygon (Clip) then
         raise Non_Convex_Clip
           with "Sutherland_Hodgman_Clip requires a convex clip polygon";
      end if;

      --  Wikipedia: CCW clip ⇒ left is inside; CW ⇒ right is inside.
      Inside_Left := Polygon_Orientation (Clip) = Counter_Clockwise;

      for I in 1 .. Clip.Count loop
         exit when Output.Count = 0;
         J := Next_Index (I, Positive (Clip.Count));
         E.A := Clip.Verts (I);
         E.B := Clip.Verts (J);
         Output := Clip_Against_Edge (Output, E, Inside_Left);
      end loop;

      return Output;
   end Sutherland_Hodgman_Clip;

   function Clip_Against_Rect
     (Subject                    : Polygon;
      Min_X, Min_Y, Max_X, Max_Y : Real) return Polygon
   is
      Clip : constant Polygon :=
        Make_Rectangle (Min_X, Min_Y, Max_X, Max_Y, Counter_Clockwise);
   begin
      return Sutherland_Hodgman_Clip (Subject, Clip);
   end Clip_Against_Rect;

   function Clip_Against_Frustum_2D
     (Subject, Window : Polygon) return Polygon
   is
   begin
      return Sutherland_Hodgman_Clip (Subject, Window);
   end Clip_Against_Frustum_2D;

   -----------------------------------------------------------------------
   -- 3-D plane clip (educational)
   -----------------------------------------------------------------------

   function Plane_Signed_Distance (P : Vec3; Plane : Plane3) return Real is
   begin
      return Dot3 (Plane.Normal, P) + Plane.D;
   end Plane_Signed_Distance;

   function Intersect_Edge_Plane
     (P0, P1  : Vec3;
      Plane   : Plane3) return Vec3
   is
      D0  : constant Real := Plane_Signed_Distance (P0, Plane);
      D1  : constant Real := Plane_Signed_Distance (P1, Plane);
      Den : constant Real := D0 - D1;
      T   : Real;
   begin
      if abs (Den) < Epsilon then
         raise Degenerate_Geometry
           with "edge parallel to plane";
      end if;
      T := D0 / Den;
      return P0 + T * (P1 - P0);
   end Intersect_Edge_Plane;

   function Clip_Polygon_Against_Plane_3D_Lite
     (Subject : Polygon3;
      Plane   : Plane3) return Polygon3
   is
      Output  : Polygon3;
      Curr    : Vec3;
      Prev    : Vec3;
      Curr_In : Boolean;
      Prev_In : Boolean;
      D_Curr  : Real;
      D_Prev  : Real;
   begin
      if Subject.Count = 0 then
         return Output;
      end if;

      Prev := Subject.Verts (Subject.Count);
      D_Prev := Plane_Signed_Distance (Prev, Plane);
      Prev_In := D_Prev >= -Epsilon;

      for I in 1 .. Subject.Count loop
         Curr := Subject.Verts (I);
         D_Curr := Plane_Signed_Distance (Curr, Plane);
         Curr_In := D_Curr >= -Epsilon;

         if Curr_In then
            if not Prev_In then
               Append_Vertex3
                 (Output, Intersect_Edge_Plane (Prev, Curr, Plane));
            end if;
            Append_Vertex3 (Output, Curr);
         elsif Prev_In then
            Append_Vertex3
              (Output, Intersect_Edge_Plane (Prev, Curr, Plane));
         end if;

         Prev := Curr;
         Prev_In := Curr_In;
      end loop;

      return Output;
   end Clip_Polygon_Against_Plane_3D_Lite;

   function Make_Polygon3 (A, B, C : Vec3) return Polygon3 is
      P : Polygon3;
   begin
      P.Count := 3;
      P.Verts (1) := A;
      P.Verts (2) := B;
      P.Verts (3) := C;
      return P;
   end Make_Polygon3;

   function Make_Polygon3 (A, B, C, D : Vec3) return Polygon3 is
      P : Polygon3;
   begin
      P.Count := 4;
      P.Verts (1) := A;
      P.Verts (2) := B;
      P.Verts (3) := C;
      P.Verts (4) := D;
      return P;
   end Make_Polygon3;

end Sutherland_Hodgman;
