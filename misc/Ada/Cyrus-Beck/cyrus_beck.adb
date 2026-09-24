--  Cyrus_Beck body — convex polygon helpers, edge normals, Cyrus–Beck clip,
--  rectangular convenience, Liang–Barsky lite reference, and 3-D plane clip.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Cyrus_Beck
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

   function Clamp (V, Lo, Hi : Real) return Real is
   begin
      if V < Lo then
         return Lo;
      elsif V > Hi then
         return Hi;
      else
         return V;
      end if;
   end Clamp;

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

   function Next_Vertex
     (I : Vertex_Index; Count : Vertex_Count) return Vertex_Index
   is
   begin
      if I = Count then
         return 1;
      else
         return I + 1;
      end if;
   end Next_Vertex;

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
   -- Segment / point helpers
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
   -- Window helpers
   -----------------------------------------------------------------------

   function Is_Valid_Window (W : Clip_Window) return Boolean is
   begin
      return W.X_Max > W.X_Min and then W.Y_Max > W.Y_Min;
   end Is_Valid_Window;

   function Make_Window
     (X_Min, Y_Min, X_Max, Y_Max : Real) return Clip_Window
   is
   begin
      if not (X_Max > X_Min and then Y_Max > Y_Min) then
         raise Invalid_Argument with "Make_Window requires positive extents";
      end if;
      return (X_Min, Y_Min, X_Max, Y_Max);
   end Make_Window;

   -----------------------------------------------------------------------
   -- Is_Convex_Polygon / Make_Convex_Polygon / Make_Convex_Rect
   -----------------------------------------------------------------------

   function Is_Convex_Polygon (Poly : Convex_Clip_Polygon) return Boolean is
      N : constant Vertex_Count := Poly.Count;
      E0, E1 : Vec2;
      C, First_C : Real;
      Seen : Boolean := False;
   begin
      if N < 3 then
         return False;
      end if;

      for I in 1 .. N loop
         declare
            I0 : constant Vertex_Index := I;
            I1 : constant Vertex_Index := Next_Vertex (I0, N);
            I2 : constant Vertex_Index := Next_Vertex (I1, N);
         begin
            E0 := Poly.V (I1) - Poly.V (I0);
            E1 := Poly.V (I2) - Poly.V (I1);
            if Near (E0.X, 0.0) and then Near (E0.Y, 0.0) then
               return False;
            end if;
            C := Cross_Z (E0, E1);
            if Near (C, 0.0) then
               --  Collinear consecutive edges: treat as non-strictly-convex.
               return False;
            end if;
            if not Seen then
               First_C := C;
               Seen := True;
            elsif (First_C > 0.0) /= (C > 0.0) then
               return False;
            end if;
         end;
      end loop;

      --  Require CCW (positive cross) so Edge_Normal is outward.
      return Seen and then First_C > 0.0;
   end Is_Convex_Polygon;

   function Make_Convex_Polygon
     (Verts : Vertex_Array; Count : Vertex_Count) return Convex_Clip_Polygon
   is
      P : Convex_Clip_Polygon;
   begin
      if Count < 3 then
         raise Invalid_Argument with "polygon needs at least 3 vertices";
      end if;
      P.Count := Count;
      for I in 1 .. Count loop
         P.V (I) := Verts (I);
      end loop;
      if not Is_Convex_Polygon (P) then
         raise Invalid_Argument
           with "Make_Convex_Polygon requires a CCW convex polygon";
      end if;
      return P;
   end Make_Convex_Polygon;

   function Make_Convex_Rect
     (X_Min, Y_Min, X_Max, Y_Max : Real) return Convex_Clip_Polygon
   is
      P : Convex_Clip_Polygon;
   begin
      if not (X_Max > X_Min and then Y_Max > Y_Min) then
         raise Invalid_Argument with "Make_Convex_Rect requires positive extents";
      end if;
      P.Count := 4;
      P.V (1) := (X_Min, Y_Min);  -- BL
      P.V (2) := (X_Max, Y_Min);  -- BR
      P.V (3) := (X_Max, Y_Max);  -- TR
      P.V (4) := (X_Min, Y_Max);  -- TL
      return P;
   end Make_Convex_Rect;

   function Edge_Normal
     (Poly : Convex_Clip_Polygon; Edge : Vertex_Index) return Vec2
   is
      I0 : constant Vertex_Index := Edge;
      I1 : constant Vertex_Index := Next_Vertex (Edge, Poly.Count);
      D  : constant Vec2 := Poly.V (I1) - Poly.V (I0);
      --  CCW: outward = right of edge = (Dy, −Dx)
      N  : constant Vec2 := (D.Y, -D.X);
      L  : constant Real := Sqrt_Safe (N.X * N.X + N.Y * N.Y);
   begin
      if L <= Epsilon then
         raise Degenerate_Geometry with "Edge_Normal: zero-length edge";
      end if;
      return (N.X / L, N.Y / L);
   end Edge_Normal;

   -----------------------------------------------------------------------
   -- Plane_Dot_Classification / Point_Inside_Convex
   -----------------------------------------------------------------------

   function Plane_Dot_Classification
     (P    : Vec2;
      Poly : Convex_Clip_Polygon;
      Edge : Vertex_Index) return Dot_Class
   is
      N  : constant Vec2 := Edge_Normal (Poly, Edge);
      PE : constant Vec2 := Poly.V (Edge);
      Val : constant Real := Dot (N, P - PE);
   begin
      if Near (Val, 0.0) then
         return Dot_On_Plane;
      elsif Val < 0.0 then
         return Dot_Inside;
      else
         return Dot_Outside;
      end if;
   end Plane_Dot_Classification;

   function Plane_Dot_Classification3
     (P : Vec3; Pl : Plane3) return Dot_Class
   is
      Val : constant Real := Dot3 (Pl.N, P - Pl.PE);
   begin
      if Near (Val, 0.0) then
         return Dot_On_Plane;
      elsif Val < 0.0 then
         return Dot_Inside;
      else
         return Dot_Outside;
      end if;
   end Plane_Dot_Classification3;

   function Point_Inside_Convex
     (P : Vec2; Poly : Convex_Clip_Polygon) return Boolean
   is
      C : Dot_Class;
   begin
      for E in 1 .. Poly.Count loop
         C := Plane_Dot_Classification (P, Poly, E);
         if C = Dot_Outside then
            return False;
         end if;
      end loop;
      return True;
   end Point_Inside_Convex;

   -----------------------------------------------------------------------
   -- Point_At_Parameter
   -----------------------------------------------------------------------

   function Point_At_Parameter
     (S : Segment; T : Parameter) return Vec2
   is
      D : constant Vec2 := S.P1 - S.P0;
   begin
      return S.P0 + (T * D);
   end Point_At_Parameter;

   function Point_At_Parameter3
     (S : Segment3; T : Parameter) return Vec3
   is
      D : constant Vec3 := S.P1 - S.P0;
   begin
      return S.P0 + (T * D);
   end Point_At_Parameter3;

   -----------------------------------------------------------------------
   -- Cyrus_Beck_Clip_Params / Cyrus_Beck_Clip
   -----------------------------------------------------------------------

   function Cyrus_Beck_Clip_Params
     (S : Segment; Poly : Convex_Clip_Polygon) return Clip_Params_Result
   is
      D       : constant Vec2 := S.P1 - S.P0;
      T_Enter : Real := 0.0;
      T_Leave : Real := 1.0;
      N       : Vec2;
      PE      : Vec2;
      Numer   : Real;
      Denom   : Real;
      T       : Real;
      R       : Clip_Params_Result;
      A, B    : Vec2;
   begin
      for E in 1 .. Poly.Count loop
         N  := Edge_Normal (Poly, E);
         PE := Poly.V (E);
         Numer := Dot (N, S.P0 - PE);  -- >0 ⇒ P0 outside
         Denom := Dot (N, D);

         if Near (Denom, 0.0) then
            --  Parallel to this edge: outside ⇒ reject.
            if Numer > Epsilon then
               R.Status  := Clip_Reject;
               R.Clipped := ((0.0, 0.0), (0.0, 0.0));
               R.T0      := 0.0;
               R.T1      := 0.0;
               return R;
            end if;
         else
            --  n·(P0 + t D − PE) = 0  ⇒  t = −Numer / Denom
            T := -Numer / Denom;
            if Denom < 0.0 then
               --  Entering (pointing toward interior)
               if T > T_Enter then
                  T_Enter := T;
               end if;
            else
               --  Leaving (pointing away from interior)
               if T < T_Leave then
                  T_Leave := T;
               end if;
            end if;
         end if;
      end loop;

      if T_Enter > T_Leave then
         R.Status  := Clip_Reject;
         R.Clipped := ((0.0, 0.0), (0.0, 0.0));
         R.T0      := 0.0;
         R.T1      := 0.0;
         return R;
      end if;

      R.T0 := Parameter (Clamp (T_Enter, 0.0, 1.0));
      R.T1 := Parameter (Clamp (T_Leave, 0.0, 1.0));
      if R.T0 > R.T1 then
         R.Status  := Clip_Reject;
         R.Clipped := ((0.0, 0.0), (0.0, 0.0));
         R.T0      := 0.0;
         R.T1      := 0.0;
         return R;
      end if;

      A := Point_At_Parameter (S, R.T0);
      B := Point_At_Parameter (S, R.T1);
      R.Status  := Clip_Accept;
      R.Clipped := (A, B);
      return R;
   end Cyrus_Beck_Clip_Params;

   function Cyrus_Beck_Clip
     (S : Segment; Poly : Convex_Clip_Polygon) return Clip_Result
   is
      P : constant Clip_Params_Result := Cyrus_Beck_Clip_Params (S, Poly);
   begin
      return (Status => P.Status, Clipped => P.Clipped);
   end Cyrus_Beck_Clip;

   function Cyrus_Beck_Clip_Rect
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      Poly : constant Convex_Clip_Polygon :=
        Make_Convex_Rect (W.X_Min, W.Y_Min, W.X_Max, W.Y_Max);
   begin
      return Cyrus_Beck_Clip (S, Poly);
   end Cyrus_Beck_Clip_Rect;

   -----------------------------------------------------------------------
   -- Liang_Barsky_Clip_Lite
   -----------------------------------------------------------------------

   function Liang_Barsky_Clip_Lite
     (S : Segment; W : Clip_Window) return Clip_Result
   is
      DX : constant Real := S.P1.X - S.P0.X;
      DY : constant Real := S.P1.Y - S.P0.Y;
      T_Enter : Real := 0.0;
      T_Leave : Real := 1.0;

      procedure Update (P, Q : Real; Ok : in out Boolean) is
         U : Real;
      begin
         if not Ok then
            return;
         end if;
         if Near (P, 0.0) then
            if Q < 0.0 then
               Ok := False;
            end if;
         else
            U := Q / P;
            if P < 0.0 then
               if U > T_Enter then
                  T_Enter := U;
               end if;
            else
               if U < T_Leave then
                  T_Leave := U;
               end if;
            end if;
         end if;
      end Update;

      Ok : Boolean := True;
      A, B : Vec2;
   begin
      --  left, right, bottom, top
      Update (-DX, S.P0.X - W.X_Min, Ok);
      Update (DX,  W.X_Max - S.P0.X, Ok);
      Update (-DY, S.P0.Y - W.Y_Min, Ok);
      Update (DY,  W.Y_Max - S.P0.Y, Ok);

      if not Ok or else T_Enter > T_Leave then
         return Rejected;
      end if;

      A := Point_At_Parameter
        (S, Parameter (Clamp (T_Enter, 0.0, 1.0)));
      B := Point_At_Parameter
        (S, Parameter (Clamp (T_Leave, 0.0, 1.0)));
      A.X := Clamp (A.X, W.X_Min, W.X_Max);
      A.Y := Clamp (A.Y, W.Y_Min, W.Y_Max);
      B.X := Clamp (B.X, W.X_Min, W.X_Max);
      B.Y := Clamp (B.Y, W.Y_Min, W.Y_Max);
      return Accepted (A, B);
   end Liang_Barsky_Clip_Lite;

   -----------------------------------------------------------------------
   -- 3-D lite
   -----------------------------------------------------------------------

   function Make_Axis_Aligned_Box_Planes
     (X_Min, Y_Min, Z_Min, X_Max, Y_Max, Z_Max : Real)
      return Polyhedron_Planes
   is
      Pl : Polyhedron_Planes;
   begin
      if not (X_Max > X_Min
              and then Y_Max > Y_Min
              and then Z_Max > Z_Min)
      then
         raise Invalid_Argument
           with "Make_Axis_Aligned_Box_Planes requires positive extents";
      end if;
      Pl.Count := 6;
      --  −X, +X, −Y, +Y, −Z, +Z (outward normals)
      Pl.P (1) := (N => (-1.0, 0.0, 0.0), PE => (X_Min, Y_Min, Z_Min));
      Pl.P (2) := (N => (1.0, 0.0, 0.0),  PE => (X_Max, Y_Max, Z_Max));
      Pl.P (3) := (N => (0.0, -1.0, 0.0), PE => (X_Min, Y_Min, Z_Min));
      Pl.P (4) := (N => (0.0, 1.0, 0.0),  PE => (X_Max, Y_Max, Z_Max));
      Pl.P (5) := (N => (0.0, 0.0, -1.0), PE => (X_Min, Y_Min, Z_Min));
      Pl.P (6) := (N => (0.0, 0.0, 1.0),  PE => (X_Max, Y_Max, Z_Max));
      return Pl;
   end Make_Axis_Aligned_Box_Planes;

   function Cyrus_Beck_Clip_3D_Lite
     (S : Segment3; Planes : Polyhedron_Planes) return Clip_Result3
   is
      D       : constant Vec3 := S.P1 - S.P0;
      T_Enter : Real := 0.0;
      T_Leave : Real := 1.0;
      Numer   : Real;
      Denom   : Real;
      T       : Real;
      A, B    : Vec3;
   begin
      for I in 1 .. Planes.Count loop
         Numer := Dot3 (Planes.P (I).N, S.P0 - Planes.P (I).PE);
         Denom := Dot3 (Planes.P (I).N, D);

         if Near (Denom, 0.0) then
            if Numer > Epsilon then
               return Rejected3;
            end if;
         else
            T := -Numer / Denom;
            if Denom < 0.0 then
               if T > T_Enter then
                  T_Enter := T;
               end if;
            else
               if T < T_Leave then
                  T_Leave := T;
               end if;
            end if;
         end if;
      end loop;

      if T_Enter > T_Leave then
         return Rejected3;
      end if;

      A := Point_At_Parameter3
        (S, Parameter (Clamp (T_Enter, 0.0, 1.0)));
      B := Point_At_Parameter3
        (S, Parameter (Clamp (T_Leave, 0.0, 1.0)));
      return Accepted3 (A, B);
   end Cyrus_Beck_Clip_3D_Lite;

end Cyrus_Beck;
