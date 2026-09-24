--  Clipping body — rect helpers, Liang–Barsky, Sutherland–Hodgman,
--  region intersection, 2-D frustum clip, near/far Z lite, visibility.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Clipping
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

   function Accepted (A, B : Vec2) return Clip_Result is
   begin
      return (Status => Clip_Accept, Clipped => (A, B));
   end Accepted;

   function Rejected return Clip_Result is
   begin
      return (Status => Clip_Reject, Clipped => ((0.0, 0.0), (0.0, 0.0)));
   end Rejected;

   function Accepted3 (A, B : Vec3) return Clip_Result3 is
   begin
      return (Status => Clip_Accept, Clipped => (A, B));
   end Accepted3;

   function Rejected3 return Clip_Result3 is
   begin
      return
        (Status  => Clip_Reject,
         Clipped => ((0.0, 0.0, 0.0), (0.0, 0.0, 0.0)));
   end Rejected3;

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
   -- Segment / polygon helpers
   -----------------------------------------------------------------------

   function Make_Segment (P0, P1 : Vec2) return Segment is
   begin
      return (P0, P1);
   end Make_Segment;

   function Make_Segment3 (P0, P1 : Vec3) return Segment3 is
   begin
      return (P0, P1);
   end Make_Segment3;

   function Length (S : Segment) return Non_Negative is
      D : constant Vec2 := S.P1 - S.P0;
   begin
      return Sqrt_Safe (D.X * D.X + D.Y * D.Y);
   end Length;

   function Length3 (S : Segment3) return Non_Negative is
      D : constant Vec3 := S.P1 - S.P0;
   begin
      return Sqrt_Safe (D.X * D.X + D.Y * D.Y + D.Z * D.Z);
   end Length3;

   function Make_Polygon (Verts : Vertex_Array; Count : Vertex_Count)
     return Polygon
   is
      P : Polygon;
   begin
      P.Count := Count;
      for I in 1 .. Count loop
         P.Verts (I) := Verts (I);
      end loop;
      return P;
   end Make_Polygon;

   function Same_Clipped_Segment
     (A, B : Segment; Tol : Real := Epsilon) return Boolean
   is
   begin
      return
        (Near_Point (A.P0, B.P0, Tol) and then Near_Point (A.P1, B.P1, Tol))
        or else
        (Near_Point (A.P0, B.P1, Tol) and then Near_Point (A.P1, B.P0, Tol));
   end Same_Clipped_Segment;

   -----------------------------------------------------------------------
   -- Clip_Rect construction
   -----------------------------------------------------------------------

   function Is_Valid_Rect (R : Clip_Rect) return Boolean is
   begin
      return R.X_Max > R.X_Min and then R.Y_Max > R.Y_Min;
   end Is_Valid_Rect;

   function Make_Rect
     (X_Min, Y_Min, X_Max, Y_Max : Real) return Clip_Rect
   is
   begin
      if not (X_Max > X_Min and then Y_Max > Y_Min) then
         raise Invalid_Argument with "Make_Rect requires positive extents";
      end if;
      return (X_Min, Y_Min, X_Max, Y_Max);
   end Make_Rect;

   function Point_In_Rect (P : Vec2; R : Clip_Rect) return Boolean is
   begin
      return P.X >= R.X_Min - Epsilon
        and then P.X <= R.X_Max + Epsilon
        and then P.Y >= R.Y_Min - Epsilon
        and then P.Y <= R.Y_Max + Epsilon;
   end Point_In_Rect;

   function Rect_To_Polygon (R : Clip_Rect) return Polygon is
      P : Polygon;
   begin
      P.Count := 4;
      P.Verts (1) := (R.X_Min, R.Y_Min);
      P.Verts (2) := (R.X_Max, R.Y_Min);
      P.Verts (3) := (R.X_Max, R.Y_Max);
      P.Verts (4) := (R.X_Min, R.Y_Max);
      return P;
   end Rect_To_Polygon;

   -----------------------------------------------------------------------
   -- Clip_Point
   -----------------------------------------------------------------------

   function Clip_Point (P : Vec2; R : Clip_Rect) return Clip_Status is
   begin
      if Point_In_Rect (P, R) then
         return Clip_Accept;
      else
         return Clip_Reject;
      end if;
   end Clip_Point;

   -----------------------------------------------------------------------
   -- Clip_Line_Liang_Barsky
   -----------------------------------------------------------------------

   function Clip_Line_Liang_Barsky
     (S : Segment; R : Clip_Rect) return Clip_Result
   is
      DX : constant Real := S.P1.X - S.P0.X;
      DY : constant Real := S.P1.Y - S.P0.Y;
      T0 : Real := 0.0;
      T1 : Real := 1.0;

      function Clip_T (P, Q : Real; T_Enter, T_Leave : in out Real)
        return Boolean
      is
         R_Param : Real;
      begin
         if Near (P, 0.0) then
            --  Parallel to this boundary.
            return Q >= 0.0;
         end if;
         R_Param := Q / P;
         if P < 0.0 then
            --  Entering.
            if R_Param > T_Leave then
               return False;
            elsif R_Param > T_Enter then
               T_Enter := R_Param;
            end if;
         else
            --  Leaving.
            if R_Param < T_Enter then
               return False;
            elsif R_Param < T_Leave then
               T_Leave := R_Param;
            end if;
         end if;
         return True;
      end Clip_T;

      Ok : Boolean;
   begin
      Ok := Clip_T (-DX, S.P0.X - R.X_Min, T0, T1);  -- left
      if not Ok then
         return Rejected;
      end if;
      Ok := Clip_T (DX, R.X_Max - S.P0.X, T0, T1);   -- right
      if not Ok then
         return Rejected;
      end if;
      Ok := Clip_T (-DY, S.P0.Y - R.Y_Min, T0, T1);  -- bottom
      if not Ok then
         return Rejected;
      end if;
      Ok := Clip_T (DY, R.Y_Max - S.P0.Y, T0, T1);   -- top
      if not Ok then
         return Rejected;
      end if;
      if T0 > T1 then
         return Rejected;
      end if;
      return Accepted
        ((S.P0.X + T0 * DX, S.P0.Y + T0 * DY),
         (S.P0.X + T1 * DX, S.P0.Y + T1 * DY));
   end Clip_Line_Liang_Barsky;

   -----------------------------------------------------------------------
   -- Sutherland–Hodgman (compact)
   -----------------------------------------------------------------------

   function Inside_Halfplane
     (P, Edge_A, Edge_B : Vec2) return Boolean
   is
      --  Inside = left of directed edge A→B (CCW clip polygon).
      E : constant Vec2 := Edge_B - Edge_A;
      D : constant Vec2 := P - Edge_A;
   begin
      return Cross_Z (E, D) >= -Epsilon;
   end Inside_Halfplane;

   function Edge_Intersection
     (S0, S1, Edge_A, Edge_B : Vec2) return Vec2
   is
      DS : constant Vec2 := S1 - S0;
      DE : constant Vec2 := Edge_B - Edge_A;
      Den : constant Real := Cross_Z (DS, DE);
      T   : Real;
   begin
      if Near (Den, 0.0) then
         return S0;  -- parallel; return start (degenerate)
      end if;
      T := Cross_Z (Edge_A - S0, DE) / Den;
      return S0 + T * DS;
   end Edge_Intersection;

   procedure Append_Vertex (Poly : in out Polygon; V : Vec2) is
   begin
      if Poly.Count = Max_Vertices then
         raise Capacity_Exceeded with "SH output exceeds Max_Vertices";
      end if;
      --  Skip near-duplicate consecutive vertices.
      if Poly.Count > 0
        and then Near_Point (Poly.Verts (Poly.Count), V)
      then
         return;
      end if;
      Poly.Count := Poly.Count + 1;
      Poly.Verts (Poly.Count) := V;
   end Append_Vertex;

   function Clip_Against_Edge
     (Subject : Polygon; Edge_A, Edge_B : Vec2) return Polygon
   is
      Output : Polygon;
      S, E   : Vec2;
      S_In, E_In : Boolean;
   begin
      Output.Count := 0;
      if Subject.Count = 0 then
         return Output;
      end if;

      S := Subject.Verts (Subject.Count);
      for I in 1 .. Subject.Count loop
         E := Subject.Verts (I);
         S_In := Inside_Halfplane (S, Edge_A, Edge_B);
         E_In := Inside_Halfplane (E, Edge_A, Edge_B);
         if E_In then
            if not S_In then
               Append_Vertex
                 (Output, Edge_Intersection (S, E, Edge_A, Edge_B));
            end if;
            Append_Vertex (Output, E);
         elsif S_In then
            Append_Vertex
              (Output, Edge_Intersection (S, E, Edge_A, Edge_B));
         end if;
         S := E;
      end loop;
      return Output;
   end Clip_Against_Edge;

   function Clip_Polygon_Sutherland_Hodgman
     (Subject : Polygon; Clip : Polygon) return Polygon_Result
   is
      Current : Polygon := Subject;
      A, B    : Vec2;
      Result  : Polygon_Result;
   begin
      if Subject.Count < 3 or else Clip.Count < 3 then
         raise Invalid_Argument
           with "SH requires subject and clip with >= 3 vertices";
      end if;

      for I in 1 .. Clip.Count loop
         A := Clip.Verts (I);
         if I = Clip.Count then
            B := Clip.Verts (1);
         else
            B := Clip.Verts (I + 1);
         end if;
         Current := Clip_Against_Edge (Current, A, B);
         exit when Current.Count = 0;
      end loop;

      if Current.Count >= 3 then
         Result.Status  := Clip_Accept;
         Result.Clipped := Current;
      else
         Result.Status  := Clip_Reject;
         Result.Clipped := (Verts => [others => (0.0, 0.0)], Count => 0);
      end if;
      return Result;
   end Clip_Polygon_Sutherland_Hodgman;

   function Clip_Polygon_To_Rect
     (Subject : Polygon; R : Clip_Rect) return Polygon_Result
   is
   begin
      return Clip_Polygon_Sutherland_Hodgman (Subject, Rect_To_Polygon (R));
   end Clip_Polygon_To_Rect;

   -----------------------------------------------------------------------
   -- Intersect_Clip_Regions
   -----------------------------------------------------------------------

   function Intersect_Clip_Regions
     (User, Device : Clip_Rect) return Intersect_Result
   is
      X0 : constant Real := Real'Max (User.X_Min, Device.X_Min);
      Y0 : constant Real := Real'Max (User.Y_Min, Device.Y_Min);
      X1 : constant Real := Real'Min (User.X_Max, Device.X_Max);
      Y1 : constant Real := Real'Min (User.Y_Max, Device.Y_Max);
      Res : Intersect_Result;
   begin
      if X1 > X0 and then Y1 > Y0 then
         Res.Overlaps := True;
         Res.Region   := (X0, Y0, X1, Y1);
      else
         Res.Overlaps := False;
         Res.Region   := (0.0, 0.0, 0.0, 0.0);
      end if;
      return Res;
   end Intersect_Clip_Regions;

   -----------------------------------------------------------------------
   -- View_Frustum_2D
   -----------------------------------------------------------------------

   function Make_Frustum_2D (Verts : Frustum_Verts) return View_Frustum_2D is
   begin
      return (Verts => Verts);
   end Make_Frustum_2D;

   function Signed_Area_Quad (F : View_Frustum_2D) return Real is
      Acc : Real := 0.0;
      J   : Frustum_Vertex_Index;
   begin
      for I in Frustum_Vertex_Index loop
         if I = Frustum_Vertex_Index'Last then
            J := Frustum_Vertex_Index'First;
         else
            J := Frustum_Vertex_Index'Succ (I);
         end if;
         Acc := Acc
           + F.Verts (I).X * F.Verts (J).Y
           - F.Verts (J).X * F.Verts (I).Y;
      end loop;
      return 0.5 * Acc;
   end Signed_Area_Quad;

   function Is_Valid_Frustum (F : View_Frustum_2D) return Boolean is
      Area : constant Real := Signed_Area_Quad (F);
      A, B, C : Vec2;
      Cross   : Real;
      Prev_Sign : Integer := 0;
      Sign      : Integer;
      J, K      : Frustum_Vertex_Index;
   begin
      if abs (Area) <= Epsilon then
         return False;
      end if;
      --  Consistent turn direction at every vertex (strict convexity).
      for I in Frustum_Vertex_Index loop
         if I = Frustum_Vertex_Index'Last then
            J := Frustum_Vertex_Index'First;
         else
            J := Frustum_Vertex_Index'Succ (I);
         end if;
         if J = Frustum_Vertex_Index'Last then
            K := Frustum_Vertex_Index'First;
         else
            K := Frustum_Vertex_Index'Succ (J);
         end if;
         A := F.Verts (I);
         B := F.Verts (J);
         C := F.Verts (K);
         Cross := Cross_Z (B - A, C - B);
         if Cross > Epsilon then
            Sign := 1;
         elsif Cross < -Epsilon then
            Sign := -1;
         else
            return False;  -- collinear / zero turn
         end if;
         if Prev_Sign = 0 then
            Prev_Sign := Sign;
         elsif Sign /= Prev_Sign then
            return False;
         end if;
      end loop;
      return True;
   end Is_Valid_Frustum;

   function Point_In_Frustum
     (P : Vec2; F : View_Frustum_2D) return Boolean
   is
      Area : constant Real := Signed_Area_Quad (F);
      CCW  : constant Boolean := Area > 0.0;
      A, B : Vec2;
      Cross : Real;
      J    : Frustum_Vertex_Index;
   begin
      for I in Frustum_Vertex_Index loop
         if I = Frustum_Vertex_Index'Last then
            J := Frustum_Vertex_Index'First;
         else
            J := Frustum_Vertex_Index'Succ (I);
         end if;
         A := F.Verts (I);
         B := F.Verts (J);
         Cross := Cross_Z (B - A, P - A);
         if CCW then
            if Cross < -Epsilon then
               return False;
            end if;
         else
            if Cross > Epsilon then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Point_In_Frustum;

   function Clip_Against_Frustum
     (P : Vec2; F : View_Frustum_2D) return Clip_Status
   is
   begin
      if Point_In_Frustum (P, F) then
         return Clip_Accept;
      else
         return Clip_Reject;
      end if;
   end Clip_Against_Frustum;

   function Clip_Against_Frustum
     (S : Segment; F : View_Frustum_2D) return Clip_Result
   is
      --  Parametric Cyrus–Beck style against convex quad half-planes.
      T_Enter : Real := 0.0;
      T_Leave : Real := 1.0;
      D       : constant Vec2 := S.P1 - S.P0;
      Area    : constant Real := Signed_Area_Quad (F);
      CCW     : constant Boolean := Area > 0.0;
      A, B, Edge, N : Vec2;
      Numer, Denom  : Real;
      T             : Real;
      J             : Frustum_Vertex_Index;
   begin
      for I in Frustum_Vertex_Index loop
         if I = Frustum_Vertex_Index'Last then
            J := Frustum_Vertex_Index'First;
         else
            J := Frustum_Vertex_Index'Succ (I);
         end if;
         A := F.Verts (I);
         B := F.Verts (J);
         Edge := B - A;
         --  Inward normal: left of edge if CCW, right if CW.
         if CCW then
            N := (-Edge.Y, Edge.X);
         else
            N := (Edge.Y, -Edge.X);
         end if;
         Numer := Dot (N, A - S.P0);
         Denom := Dot (N, D);
         if Near (Denom, 0.0) then
            --  Parallel to this edge.
            if Numer < -Epsilon then
               return Rejected;  -- outside
            end if;
         else
            T := Numer / Denom;
            if Denom < 0.0 then
               --  Leaving.
               if T < T_Enter then
                  return Rejected;
               elsif T < T_Leave then
                  T_Leave := T;
               end if;
            else
               --  Entering.
               if T > T_Leave then
                  return Rejected;
               elsif T > T_Enter then
                  T_Enter := T;
               end if;
            end if;
         end if;
      end loop;

      if T_Enter > T_Leave then
         return Rejected;
      end if;
      return Accepted (S.P0 + T_Enter * D, S.P0 + T_Leave * D);
   end Clip_Against_Frustum;

   -----------------------------------------------------------------------
   -- Near_Far_Clip_3D_Lite
   -----------------------------------------------------------------------

   function Near_Far_Clip_3D_Lite
     (S : Segment3; Near_Z, Far_Z : Real) return Clip_Result3
   is
      Z0 : constant Real := S.P0.Z;
      DZ : constant Real := S.P1.Z - S.P0.Z;
      T0 : Real := 0.0;
      T1 : Real := 1.0;

      function Clip_T (P, Q : Real; T_Enter, T_Leave : in out Real)
        return Boolean
      is
         R_Param : Real;
      begin
         if Near (P, 0.0) then
            return Q >= -Epsilon;
         end if;
         R_Param := Q / P;
         if P < 0.0 then
            if R_Param > T_Leave then
               return False;
            elsif R_Param > T_Enter then
               T_Enter := R_Param;
            end if;
         else
            if R_Param < T_Enter then
               return False;
            elsif R_Param < T_Leave then
               T_Leave := R_Param;
            end if;
         end if;
         return True;
      end Clip_T;

      Ok : Boolean;
   begin
      if not (Far_Z > Near_Z) then
         raise Invalid_Argument with "Near_Far requires Far_Z > Near_Z";
      end if;

      --  Liang–Barsky-style against Z >= Near_Z and Z <= Far_Z.
      Ok := Clip_T (-DZ, Z0 - Near_Z, T0, T1);
      if not Ok then
         return Rejected3;
      end if;
      Ok := Clip_T (DZ, Far_Z - Z0, T0, T1);
      if not Ok then
         return Rejected3;
      end if;
      if T0 > T1 then
         return Rejected3;
      end if;
      return Accepted3
        (S.P0 + T0 * (S.P1 - S.P0),
         S.P0 + T1 * (S.P1 - S.P0));
   end Near_Far_Clip_3D_Lite;

   -----------------------------------------------------------------------
   -- Classify_Visibility
   -----------------------------------------------------------------------

   function Classify_Visibility
     (S : Segment; R : Clip_Rect) return Visibility
   is
      In0 : constant Boolean := Point_In_Rect (S.P0, R);
      In1 : constant Boolean := Point_In_Rect (S.P1, R);
      CR  : Clip_Result;
   begin
      if In0 and then In1 then
         return Fully_Visible;
      end if;
      CR := Clip_Line_Liang_Barsky (S, R);
      if CR.Status = Clip_Reject then
         return Invisible;
      end if;
      return Partially_Visible;
   end Classify_Visibility;

end Clipping;
