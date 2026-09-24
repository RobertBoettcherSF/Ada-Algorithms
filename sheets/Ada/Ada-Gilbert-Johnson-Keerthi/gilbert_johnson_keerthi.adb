--  Gilbert_Johnson_Keerthi body — support queries, Minkowski difference,
--  and educational 2-D GJK distance / intersection.

pragma Ada_2022;

with Ada.Numerics;
with Ada.Numerics.Long_Elementary_Functions;

package body Gilbert_Johnson_Keerthi
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Long_Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Validation helpers
   ---------------------------------------------------------------------------

   procedure Require_Vertex_Count (N : Natural) is
   begin
      if N < 3 or else N > Max_Vertices then
         raise Invalid_Argument;
      end if;
   end Require_Vertex_Count;

   procedure Require_Nonempty (N : Natural) is
   begin
      if N = 0 or else N > Max_Vertices then
         raise Invalid_Argument;
      end if;
   end Require_Nonempty;

   function Next_Idx (I : Positive; N : Positive) return Positive is
     (if I = N then 1 else I + 1);

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
      DX : constant Real := B.X - A.X;
      DY : constant Real := B.Y - A.Y;
   begin
      return DX * DX + DY * DY;
   end Dist2;

   function Dist (A, B : Point) return Real is
      D2 : constant Real := Dist2 (A, B);
   begin
      if D2 <= 0.0 then
         return 0.0;
      end if;
      return Real (Math.Sqrt (Long_Float (D2)));
   end Dist;

   function Norm2 (V : Vec2) return Real is
   begin
      return V.X * V.X + V.Y * V.Y;
   end Norm2;

   function Norm (V : Vec2) return Real is
      N2 : constant Real := Norm2 (V);
   begin
      if N2 <= 0.0 then
         return 0.0;
      end if;
      return Real (Math.Sqrt (Long_Float (N2)));
   end Norm;

   function Cross (Ax, Ay, Bx, By : Real) return Real is
   begin
      return Ax * By - Ay * Bx;
   end Cross;

   function Cross (A, B : Point) return Real is
   begin
      return A.X * B.Y - A.Y * B.X;
   end Cross;

   function Dot (A, B : Point) return Real is
   begin
      return A.X * B.X + A.Y * B.Y;
   end Dot;

   function Sub (A, B : Point) return Point is
   begin
      return (X => A.X - B.X, Y => A.Y - B.Y);
   end Sub;

   function Add (A, B : Point) return Point is
   begin
      return (X => A.X + B.X, Y => A.Y + B.Y);
   end Add;

   function Scale (V : Vec2; S : Real) return Vec2 is
   begin
      return (X => V.X * S, Y => V.Y * S);
   end Scale;

   function Negate (V : Vec2) return Vec2 is
   begin
      return (X => -V.X, Y => -V.Y);
   end Negate;

   function Orient2D (A, B, C : Point) return Real is
   begin
      return Cross (B.X - A.X, B.Y - A.Y, C.X - A.X, C.Y - A.Y);
   end Orient2D;

   function Perp (V : Vec2) return Vec2 is
   begin
      return (X => -V.Y, Y => V.X);
   end Perp;

   ---------------------------------------------------------------------------
   -- Dense copy / reverse
   ---------------------------------------------------------------------------

   function Dense_Copy (Poly : Polygon) return Polygon is
      N    : constant Positive := Poly'Length;
      Copy : Polygon (1 .. N);
      K    : Positive := 1;
   begin
      for I in Poly'Range loop
         Copy (K) := Poly (I);
         K := K + 1;
      end loop;
      return Copy;
   end Dense_Copy;

   function Reverse_Copy (Poly : Polygon) return Polygon is
      N    : constant Positive := Poly'Length;
      Copy : Polygon (1 .. N);
   begin
      for I in 1 .. N loop
         Copy (I) := Poly (Poly'First + (N - I));
      end loop;
      return Copy;
   end Reverse_Copy;

   ---------------------------------------------------------------------------
   -- Polygon measures
   ---------------------------------------------------------------------------

   function Accumulated_Cross (Poly : Polygon) return Real is
      Sum : Real := 0.0;
      J   : Vertex_Index;
   begin
      for I in Poly'Range loop
         if I = Poly'Last then
            J := Poly'First;
         else
            J := I + 1;
         end if;
         Sum := Sum + Poly (I).X * Poly (J).Y
                    - Poly (J).X * Poly (I).Y;
      end loop;
      return Sum;
   end Accumulated_Cross;

   function Signed_Area (Poly : Polygon) return Real is
   begin
      Require_Vertex_Count (Poly'Length);
      return Accumulated_Cross (Poly) * 0.5;
   end Signed_Area;

   function Is_Convex (Poly : Polygon) return Boolean is
      N          : constant Positive := Poly'Length;
      Dense      : Polygon (1 .. N);
      Cross_Val  : Real;
      Sign       : Integer := 0;
      S          : Integer;
   begin
      Require_Vertex_Count (N);
      Dense := Dense_Copy (Poly);
      for I in 1 .. N loop
         declare
            A : constant Point := Dense (I);
            B : constant Point := Dense (Next_Idx (I, N));
            C : constant Point := Dense (Next_Idx (Next_Idx (I, N), N));
         begin
            Cross_Val := Orient2D (A, B, C);
            if abs (Cross_Val) <= Epsilon then
               return False;  --  collinear / degenerate turn
            end if;
            if Cross_Val > 0.0 then
               S := 1;
            else
               S := -1;
            end if;
            if Sign = 0 then
               Sign := S;
            elsif Sign /= S then
               return False;
            end if;
         end;
      end loop;
      return Sign /= 0;
   end Is_Convex;

   function Is_CCW (Poly : Polygon) return Boolean is
   begin
      return Signed_Area (Poly) > Epsilon;
   end Is_CCW;

   function Ensure_Convex_CCW (Poly : Polygon) return Polygon is
      N : constant Natural := Poly'Length;
   begin
      Require_Vertex_Count (N);
      if not Is_Convex (Poly) then
         raise Invalid_Argument;
      end if;
      declare
         Dense : constant Polygon := Dense_Copy (Poly);
      begin
         if Accumulated_Cross (Dense) > 0.0 then
            return Dense;
         else
            return Reverse_Copy (Dense);
         end if;
      end;
   end Ensure_Convex_CCW;

   function Centroid (Poly : Polygon) return Point is
      N   : constant Natural := Poly'Length;
      Sum : Point := (X => 0.0, Y => 0.0);
      Inv : Real;
   begin
      Require_Nonempty (N);
      for P of Poly loop
         Sum.X := Sum.X + P.X;
         Sum.Y := Sum.Y + P.Y;
      end loop;
      Inv := 1.0 / Real (N);
      return (X => Sum.X * Inv, Y => Sum.Y * Inv);
   end Centroid;

   ---------------------------------------------------------------------------
   -- Support functions
   ---------------------------------------------------------------------------

   function Support (Poly : Polygon; Direction : Vec2) return Point is
      Best_Dot : Real;
      Best_Pt  : Point;
      First    : Boolean := True;
      D        : Real;
   begin
      Require_Vertex_Count (Poly'Length);
      Best_Pt := Poly (Poly'First);
      Best_Dot := 0.0;
      for P of Poly loop
         D := Dot (P, Direction);
         if First or else D > Best_Dot then
            Best_Dot := D;
            Best_Pt  := P;
            First    := False;
         end if;
      end loop;
      return Best_Pt;
   end Support;

   function Support_Minkowski
     (A, B : Polygon; Dir : Vec2) return Point
   is
      SA : constant Point := Support (A, Dir);
      SB : constant Point := Support (B, Negate (Dir));
   begin
      return Sub (SA, SB);
   end Support_Minkowski;

   ---------------------------------------------------------------------------
   -- Educational 2-D simplex (point / segment / triangle)
   ---------------------------------------------------------------------------

   subtype Simplex_Size is Natural range 0 .. 3;

   type Simplex is record
      V     : Point_Array (1 .. 3) := [others => (X => 0.0, Y => 0.0)];
      Count : Simplex_Size := 0;
   end record;

   --  Closest point on segment AB to the origin, plus whether the closest
   --  feature is an endpoint (and which) or the open edge.
   type Segment_Closest is record
      Point     : Vec2;
      On_Edge   : Boolean;  --  True ⇒ interior of AB; False ⇒ endpoint
      Keep_A    : Boolean;
      Keep_B    : Boolean;
   end record;

   function Closest_On_Segment (A, B : Point) return Segment_Closest is
      AB   : constant Vec2 := (X => B.X - A.X, Y => B.Y - A.Y);
      AB2  : constant Real := Norm2 (AB);
      T    : Real;
      Clos : Vec2;
   begin
      if AB2 <= Epsilon * Epsilon then
         --  Degenerate: treat as point A.
         return (Point => A, On_Edge => False, Keep_A => True, Keep_B => False);
      end if;
      --  Project origin onto AB: t = ((0−A)·AB) / ‖AB‖² = (−A·AB)/‖AB‖².
      T := -Dot (A, AB) / AB2;
      if T <= 0.0 then
         return (Point => A, On_Edge => False, Keep_A => True, Keep_B => False);
      elsif T >= 1.0 then
         return (Point => B, On_Edge => False, Keep_A => False, Keep_B => True);
      else
         Clos := Add (A, Scale (AB, T));
         return
           (Point => Clos, On_Edge => True, Keep_A => True, Keep_B => True);
      end if;
   end Closest_On_Segment;

   --  Process the current simplex: reduce toward the feature closest to
   --  the origin, return the new search direction (toward the origin from
   --  that feature), the squared distance of the closest point, and
   --  whether the origin is inside (intersecting).
   procedure Evolve_Simplex
     (S              : in out Simplex;
      Direction      : out Vec2;
      Closest_Sq     : out Real;
      Contains_Origin : out Boolean)
   is
   begin
      Contains_Origin := False;
      Closest_Sq := 0.0;
      Direction := (X => 0.0, Y => 0.0);

      if S.Count = 0 then
         Closest_Sq := 0.0;
         Direction := (X => 1.0, Y => 0.0);
         return;
      elsif S.Count = 1 then
         Closest_Sq := Norm2 (S.V (1));
         Direction := Negate (S.V (1));
         if Closest_Sq <= Epsilon * Epsilon then
            Contains_Origin := True;
            Direction := (X => 0.0, Y => 0.0);
         end if;
         return;
      elsif S.Count = 2 then
         declare
            C : constant Segment_Closest :=
              Closest_On_Segment (S.V (1), S.V (2));
         begin
            Closest_Sq := Norm2 (C.Point);
            if Closest_Sq <= Epsilon * Epsilon then
               Contains_Origin := True;
               Direction := (X => 0.0, Y => 0.0);
               return;
            end if;
            if not C.Keep_B then
               --  Keep only A (= V(1)).
               S.Count := 1;
               Direction := Negate (S.V (1));
            elsif not C.Keep_A then
               --  Keep only B (= V(2)).
               S.V (1) := S.V (2);
               S.Count := 1;
               Direction := Negate (S.V (1));
            else
               --  Keep segment; direction is perpendicular toward origin.
               declare
                  AB : constant Vec2 := Sub (S.V (2), S.V (1));
                  N  : Vec2 := Perp (AB);
               begin
                  --  Flip so N points toward the origin (same half-plane
                  --  as −C.Point, i.e. Dot (N, C.Point) should be ≤ 0).
                  if Dot (N, C.Point) > 0.0 then
                     N := Negate (N);
                  end if;
                  Direction := N;
               end;
            end if;
         end;
         return;
      else
         --  Triangle ABC with vertices V(1), V(2), V(3)=newest.
         declare
            A : constant Point := S.V (1);
            B : constant Point := S.V (2);
            C : constant Point := S.V (3);
            --  Signed areas / barycentric via Orient2D with origin O=(0,0):
            --  Orient2D(A,B,O) = A×B (cross of A,B as vectors from O... wait)
            --  Orient2D(P,Q,R) = (Q−P)×(R−P). For R = origin:
            --  Orient2D(A,B,O) = (B−A)×(−A) = A×B − A×A... = Cross(B−A, −A)
            AO_AB : constant Real := Orient2D (A, B, (X => 0.0, Y => 0.0));
            BO_BC : constant Real := Orient2D (B, C, (X => 0.0, Y => 0.0));
            CO_CA : constant Real := Orient2D (C, A, (X => 0.0, Y => 0.0));
            --  Triangle orientation (should be consistent with CCW or CW).
            Tri   : constant Real := Orient2D (A, B, C);
            Same_AB : Boolean;
            Same_BC : Boolean;
            Same_CA : Boolean;
         begin
            --  Origin is inside iff it is on the same side of each edge
            --  as the third vertex (or on an edge).
            if abs (Tri) <= Epsilon then
               --  Degenerate triangle → fall back to segment BC (newest).
               S.V (1) := B;
               S.V (2) := C;
               S.Count := 2;
               Evolve_Simplex (S, Direction, Closest_Sq, Contains_Origin);
               return;
            end if;

            Same_AB := (AO_AB * Tri >= -Epsilon);
            Same_BC := (BO_BC * Tri >= -Epsilon);
            Same_CA := (CO_CA * Tri >= -Epsilon);

            if Same_AB and then Same_BC and then Same_CA then
               Contains_Origin := True;
               Closest_Sq := 0.0;
               Direction := (X => 0.0, Y => 0.0);
               return;
            end if;

            --  Outside edge AB (opposite C): reduce to AB.
            if not Same_AB then
               S.V (1) := A;
               S.V (2) := B;
               S.Count := 2;
               Evolve_Simplex (S, Direction, Closest_Sq, Contains_Origin);
               return;
            end if;

            --  Outside edge BC (opposite A): reduce to BC.
            if not Same_BC then
               S.V (1) := B;
               S.V (2) := C;
               S.Count := 2;
               Evolve_Simplex (S, Direction, Closest_Sq, Contains_Origin);
               return;
            end if;

            --  Outside edge CA (opposite B): reduce to CA.
            if not Same_CA then
               S.V (1) := C;
               S.V (2) := A;
               S.Count := 2;
               Evolve_Simplex (S, Direction, Closest_Sq, Contains_Origin);
               return;
            end if;

            --  Fallback (should be covered above).
            Contains_Origin := True;
            Closest_Sq := 0.0;
            Direction := (X => 0.0, Y => 0.0);
         end;
      end if;
   end Evolve_Simplex;

   procedure Push_Vertex (S : in out Simplex; P : Point) is
   begin
      if S.Count = 3 then
         --  Should not happen after proper reduction; drop oldest.
         S.V (1) := S.V (2);
         S.V (2) := S.V (3);
         S.V (3) := P;
         S.Count := 3;
      else
         S.Count := S.Count + 1;
         S.V (S.Count) := P;
      end if;
   end Push_Vertex;

   ---------------------------------------------------------------------------
   -- Core GJK
   ---------------------------------------------------------------------------

   function Finish
     (Clos2 : Real; Contains : Boolean; Iters : Natural)
      return Distance_Result
   is
      Result : Distance_Result;
   begin
      Result.Iterations := Iters;
      if Contains or else Clos2 <= Epsilon * Epsilon then
         Result.Distance := 0.0;
         Result.Intersecting := True;
      else
         Result.Distance := Real (Math.Sqrt (Long_Float (Clos2)));
         Result.Intersecting := Near (Result.Distance, 0.0);
      end if;
      return Result;
   end Finish;

   function GJK_Query (A, B : Polygon) return Distance_Result is
      PA      : constant Polygon := Ensure_Convex_CCW (A);
      PB      : constant Polygon := Ensure_Convex_CCW (B);
      CA      : constant Point := Centroid (PA);
      CB      : constant Point := Centroid (PB);
      Dir     : Vec2;
      S       : Simplex;
      Supp    : Point;
      Closest : Vec2;
      Clos2   : Real;
      Contains : Boolean;
      Iters   : Natural := 0;
      --  Absolute progress tolerance on squared distance.
      Tol2    : constant Real := Epsilon;
   begin
      --  Initial search direction: centroid(A) − centroid(B).
      Dir := Sub (CA, CB);
      if Norm2 (Dir) <= Tol2 then
         Dir := (X => 1.0, Y => 0.0);
      end if;

      Supp := Support_Minkowski (PA, PB, Dir);
      Push_Vertex (S, Supp);
      Closest := Supp;
      Clos2 := Norm2 (Closest);

      if Clos2 <= Tol2 then
         return Finish (0.0, True, 1);
      end if;

      while Iters < Max_Iterations loop
         Iters := Iters + 1;

         --  Search toward the origin from the current closest point.
         Dir := Negate (Closest);

         Supp := Support_Minkowski (PA, PB, Dir);

         --  No further progress: support does not get strictly closer to
         --  the origin along −Closest than the current closest point.
         --  Equivalently: Supp · Closest >= ‖Closest‖² − tol.
         if Dot (Supp, Closest) >= Clos2 - Tol2 then
            return Finish (Clos2, False, Iters);
         end if;

         --  Duplicate vertex → converged.
         if S.Count >= 1 then
            declare
               Dup : Boolean := False;
            begin
               for I in 1 .. S.Count loop
                  if Near_Point (Supp, S.V (I), Epsilon) then
                     Dup := True;
                     exit;
                  end if;
               end loop;
               if Dup then
                  return Finish (Clos2, False, Iters);
               end if;
            end;
         end if;

         Push_Vertex (S, Supp);
         Evolve_Simplex (S, Dir, Clos2, Contains);

         if Contains or else Clos2 <= Tol2 then
            return Finish (0.0, True, Iters);
         end if;

         --  Recover closest point: for a 1-vertex simplex it is that
         --  vertex; for a segment it is the projection stored via Dir
         --  reconstruction from Evolve (Dir points from closest toward
         --  origin when on an edge, or −vertex when at a vertex).
         --  Recompute explicitly from the reduced simplex.
         if S.Count = 1 then
            Closest := S.V (1);
         elsif S.Count = 2 then
            Closest := Closest_On_Segment (S.V (1), S.V (2)).Point;
         else
            --  Should have been reduced; fall back.
            Closest := S.V (1);
         end if;
         Clos2 := Norm2 (Closest);

         if Clos2 <= Tol2 then
            return Finish (0.0, True, Iters);
         end if;
      end loop;
      return Finish (Clos2, False, Iters);
   end GJK_Query;

   function Distance (A, B : Polygon) return Real is
      R : constant Distance_Result := GJK_Query (A, B);
   begin
      return R.Distance;
   end Distance;

   function Distance_Info (A, B : Polygon) return Distance_Result is
   begin
      return GJK_Query (A, B);
   end Distance_Info;

   function Intersect (A, B : Polygon) return Boolean is
      R : constant Distance_Result := GJK_Query (A, B);
   begin
      return R.Intersecting;
   end Intersect;

   function Distance_Squared (A, B : Polygon) return Real is
      D : constant Real := Distance (A, B);
   begin
      return D * D;
   end Distance_Squared;

   ---------------------------------------------------------------------------
   -- Teaching helpers
   ---------------------------------------------------------------------------

   function Regular_Polygon
     (N      : Vertex_Count;
      Radius : Real;
      Center : Point := (X => 0.0, Y => 0.0);
      Phase  : Real := 0.0) return Polygon
   is
      Two_Pi : constant Real := 2.0 * Real (Ada.Numerics.Pi);
   begin
      if Natural (N) < 3 or else Radius <= 0.0 then
         raise Invalid_Argument;
      end if;
      declare
         Result : Polygon (1 .. N);
         Angle  : Real;
      begin
         for I in 1 .. N loop
            Angle := Phase + Two_Pi * Real (I - 1) / Real (N);
            Result (I) :=
              (X => Center.X
                 + Radius * Real (Math.Cos (Long_Float (Angle))),
               Y => Center.Y
                 + Radius * Real (Math.Sin (Long_Float (Angle))));
         end loop;
         return Result;
      end;
   end Regular_Polygon;

   function Axis_Aligned_Square
     (Center : Point; Half_Side : Real) return Polygon
   is
      H : Real;
   begin
      if Half_Side <= 0.0 then
         raise Invalid_Argument;
      end if;
      H := Half_Side;
      return Polygon'
        (1 => (X => Center.X - H, Y => Center.Y - H),
         2 => (X => Center.X + H, Y => Center.Y - H),
         3 => (X => Center.X + H, Y => Center.Y + H),
         4 => (X => Center.X - H, Y => Center.Y + H));
   end Axis_Aligned_Square;

end Gilbert_Johnson_Keerthi;
