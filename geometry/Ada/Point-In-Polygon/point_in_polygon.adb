--  Point_In_Polygon body — even–odd ray casting & Sunday winding number.

pragma Ada_2022;

package body Point_In_Polygon
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Validation
   ---------------------------------------------------------------------------

   procedure Require_Vertex_Count (N : Natural) is
   begin
      if N < 3 or else N > Max_Vertices then
         raise Invalid_Argument;
      end if;
   end Require_Vertex_Count;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Near_Point (A, B : Point; Tol : Real := Epsilon) return Boolean is
   begin
      return Near (A.X, B.X, Tol) and then Near (A.Y, B.Y, Tol);
   end Near_Point;

   function Dist2 (A, B : Point) return Real is
      DX : constant Real := A.X - B.X;
      DY : constant Real := A.Y - B.Y;
   begin
      return DX * DX + DY * DY;
   end Dist2;

   function Orient2D (A, B, C : Point) return Real is
   begin
      return (B.X - A.X) * (C.Y - A.Y) - (C.X - A.X) * (B.Y - A.Y);
   end Orient2D;

   ---------------------------------------------------------------------------
   -- Boundary / edge tests
   ---------------------------------------------------------------------------

   function Point_On_Segment
     (P, A, B : Point; Tol : Real := Epsilon) return Boolean
   is
      Len2 : constant Real := Dist2 (A, B);
      Cross, Dot : Real;
      Min_X, Max_X, Min_Y, Max_Y : Real;
   begin
      --  Degenerate segment: treat as a point.
      if Len2 <= Tol * Tol then
         return Near_Point (P, A, Tol);
      end if;

      --  Distance from P to the infinite line through A,B via cross product:
      --  | (B−A)×(P−A) | / |B−A|  ≤ Tol  ⇔  |cross|^2 ≤ Tol^2 · Len2.
      Cross := Orient2D (A, B, P);
      if Cross * Cross > Tol * Tol * Len2 then
         return False;
      end if;

      --  Project P onto AB; require the projection parameter in [0,1]
      --  (within Tol in parameter space via bounding-box + dot).
      Dot := (P.X - A.X) * (B.X - A.X) + (P.Y - A.Y) * (B.Y - A.Y);
      if Dot < -Tol * (if Len2 > 1.0 then Len2 else 1.0) then
         return False;
      end if;
      if Dot > Len2 + Tol * (if Len2 > 1.0 then Len2 else 1.0) then
         return False;
      end if;

      --  Axis-aligned guard (handles near-horizontal / near-vertical edges).
      if A.X < B.X then
         Min_X := A.X;
         Max_X := B.X;
      else
         Min_X := B.X;
         Max_X := A.X;
      end if;
      if A.Y < B.Y then
         Min_Y := A.Y;
         Max_Y := B.Y;
      else
         Min_Y := B.Y;
         Max_Y := A.Y;
      end if;

      return P.X >= Min_X - Tol and then P.X <= Max_X + Tol
        and then P.Y >= Min_Y - Tol and then P.Y <= Max_Y + Tol;
   end Point_On_Segment;

   function On_Boundary
     (P : Point; Poly : Polygon; Tol : Real := Epsilon) return Boolean
   is
      J : Vertex_Index;
   begin
      Require_Vertex_Count (Poly'Length);
      for I in Poly'Range loop
         if I = Poly'Last then
            J := Poly'First;
         else
            J := I + 1;
         end if;
         if Point_On_Segment (P, Poly (I), Poly (J), Tol) then
            return True;
         end if;
      end loop;
      return False;
   end On_Boundary;

   ---------------------------------------------------------------------------
   -- Crossing number (even–odd / ray casting)
   ---------------------------------------------------------------------------
   --  Horizontal ray from P to +∞. An edge (Vi, Vj) contributes one
   --  crossing when it straddles P.Y with the upper endpoint strictly
   --  above the ray, and the intersection x-coordinate is strictly to
   --  the right of P.X. Horizontal edges are skipped.

   function Crossing_Number (P : Point; Poly : Polygon) return Natural is
      Count : Natural := 0;
      Vi, Vj : Point;
      J      : Vertex_Index;
      T      : Real;
      X_Int  : Real;
   begin
      Require_Vertex_Count (Poly'Length);

      for I in Poly'Range loop
         if I = Poly'Last then
            J := Poly'First;
         else
            J := I + 1;
         end if;
         Vi := Poly (I);
         Vj := Poly (J);

         --  Upward or downward straddle (upper endpoint strictly above).
         if (Vi.Y <= P.Y and then Vj.Y > P.Y)
           or else (Vi.Y > P.Y and then Vj.Y <= P.Y)
         then
            --  Parametric y-fraction along the edge.
            T := (P.Y - Vi.Y) / (Vj.Y - Vi.Y);
            X_Int := Vi.X + T * (Vj.X - Vi.X);
            if P.X < X_Int then
               Count := Count + 1;
            end if;
         end if;
      end loop;

      return Count;
   end Crossing_Number;

   ---------------------------------------------------------------------------
   -- Winding number (Dan Sunday, 2001)
   ---------------------------------------------------------------------------
   --  +1 for an upward crossing with P strictly left of the directed edge;
   --  −1 for a downward crossing with P strictly right. Horizontal edges
   --  are ignored by the y-straddle tests.

   function Winding_Number (P : Point; Poly : Polygon) return Integer is
      Wn : Integer := 0;
      Vi, Vj : Point;
      J      : Vertex_Index;
      Left   : Real;
   begin
      Require_Vertex_Count (Poly'Length);

      for I in Poly'Range loop
         if I = Poly'Last then
            J := Poly'First;
         else
            J := I + 1;
         end if;
         Vi := Poly (I);
         Vj := Poly (J);
         Left := Orient2D (Vi, Vj, P);

         if Vi.Y <= P.Y then
            if Vj.Y > P.Y and then Left > 0.0 then
               Wn := Wn + 1;   -- upward crossing, P left of edge
            end if;
         else
            if Vj.Y <= P.Y and then Left < 0.0 then
               Wn := Wn - 1;   -- downward crossing, P right of edge
            end if;
         end if;
      end loop;

      return Wn;
   end Winding_Number;

   ---------------------------------------------------------------------------
   -- Public containment predicates (closed-set boundary policy)
   ---------------------------------------------------------------------------

   function Contains_Even_Odd (P : Point; Poly : Polygon) return Boolean is
   begin
      Require_Vertex_Count (Poly'Length);
      if On_Boundary (P, Poly) then
         return True;
      end if;
      return Crossing_Number (P, Poly) mod 2 = 1;
   end Contains_Even_Odd;

   function Contains_Winding (P : Point; Poly : Polygon) return Boolean is
   begin
      Require_Vertex_Count (Poly'Length);
      if On_Boundary (P, Poly) then
         return True;
      end if;
      return Winding_Number (P, Poly) /= 0;
   end Contains_Winding;

   function Contains
     (P : Point; Poly : Polygon; Use_Winding : Boolean := False)
      return Boolean
   is
   begin
      if Use_Winding then
         return Contains_Winding (P, Poly);
      else
         return Contains_Even_Odd (P, Poly);
      end if;
   end Contains;

end Point_In_Polygon;
