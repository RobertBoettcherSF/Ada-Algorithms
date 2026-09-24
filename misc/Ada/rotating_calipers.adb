--  Rotating_Calipers body — antipodal pairs, diameter, width, OBB sketch.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Rotating_Calipers
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

   function Next_Idx (I : Positive; N : Positive) return Positive is
     (if I = N then 1 else I + 1);

   function Prev_Idx (I : Positive; N : Positive) return Positive is
     (if I = 1 then N else I - 1);

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

   function Orient2D (A, B, C : Point) return Real is
   begin
      return Cross (B.X - A.X, B.Y - A.Y, C.X - A.X, C.Y - A.Y);
   end Orient2D;

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
      return Accumulated_Cross (Poly) / 2.0;
   end Signed_Area;

   function Is_CCW (Poly : Polygon) return Boolean is
   begin
      return Signed_Area (Poly) > Epsilon;
   end Is_CCW;

   function Is_Convex (Poly : Polygon) return Boolean is
      N               : constant Natural := Poly'Length;
      Saw_Pos         : Boolean := False;
      Saw_Neg         : Boolean := False;
      Prev, Curr, Nxt : Point;
      Cross_Val       : Real;
      I_Prev, I_Next  : Positive;
   begin
      Require_Vertex_Count (N);
      declare
         Dense : constant Polygon := Dense_Copy (Poly);
      begin
         for I in 1 .. N loop
            I_Prev := Prev_Idx (I, N);
            I_Next := Next_Idx (I, N);
            Prev := Dense (I_Prev);
            Curr := Dense (I);
            Nxt  := Dense (I_Next);
            Cross_Val := Orient2D (Prev, Curr, Nxt);
            if Cross_Val > Epsilon then
               Saw_Pos := True;
            elsif Cross_Val < -Epsilon then
               Saw_Neg := True;
            else
               --  Collinear triple: not strictly convex for classroom use.
               return False;
            end if;
            if Saw_Pos and then Saw_Neg then
               return False;
            end if;
         end loop;
      end;
      return Saw_Pos or else Saw_Neg;
   end Is_Convex;

   function Ensure_Convex_CCW (Poly : Polygon) return Polygon is
      Dense : Polygon (1 .. Poly'Length);
   begin
      Require_Vertex_Count (Poly'Length);
      if not Is_Convex (Poly) then
         raise Invalid_Argument;
      end if;
      Dense := Dense_Copy (Poly);
      if Signed_Area (Dense) < 0.0 then
         return Reverse_Copy (Dense);
      end if;
      if abs (Signed_Area (Dense)) <= Epsilon then
         raise Invalid_Argument;
      end if;
      return Dense;
   end Ensure_Convex_CCW;

   ---------------------------------------------------------------------------
   -- Antipodal list helpers
   ---------------------------------------------------------------------------

   procedure Append_Pair
     (L : in out Antipodal_List; A, B : Vertex_Index)
   is
      Lo : Vertex_Index;
      Hi : Vertex_Index;
   begin
      if A = B then
         return;
      end if;
      if A < B then
         Lo := A;
         Hi := B;
      else
         Lo := B;
         Hi := A;
      end if;
      for K in 1 .. L.Count loop
         if L.Pairs (K).I = Lo and then L.Pairs (K).J = Hi then
            return;
         end if;
      end loop;
      if L.Count = Max_Pairs then
         raise Invalid_Argument;
      end if;
      L.Count := L.Count + 1;
      L.Pairs (L.Count) := (I => Lo, J => Hi);
   end Append_Pair;

   ---------------------------------------------------------------------------
   -- Rotating calipers core
   ---------------------------------------------------------------------------
   --  Preparata–Shamos style: for each edge i → next(i), advance antipodal
   --  vertex k while the signed area (height) of triangle (i, next(i), k)
   --  still increases. That k is antipodal to the edge. Parallel edges
   --  (equal areas) also contribute the next vertex.

   function Antipodal_Pairs (Poly : Polygon) return Antipodal_List is
      C : constant Polygon := Ensure_Convex_CCW (Poly);
      N : constant Positive := C'Length;
      L : Antipodal_List;
      K : Positive := 2;
      Area_K, Area_Next : Real;
   begin
      --  Initialize k as antipodal to edge N → 1.
      while Orient2D (C (N), C (1), C (Next_Idx (K, N)))
              > Orient2D (C (N), C (1), C (K)) + Epsilon
      loop
         K := Next_Idx (K, N);
      end loop;

      for I in 1 .. N loop
         --  Advance k while moving increases height relative to edge I.
         while Orient2D (C (I), C (Next_Idx (I, N)), C (Next_Idx (K, N)))
                 > Orient2D (C (I), C (Next_Idx (I, N)), C (K)) + Epsilon
         loop
            K := Next_Idx (K, N);
         end loop;

         Append_Pair (L, Vertex_Index (I), Vertex_Index (K));
         Append_Pair (L, Vertex_Index (Next_Idx (I, N)), Vertex_Index (K));

         Area_K    := Orient2D (C (I), C (Next_Idx (I, N)), C (K));
         Area_Next := Orient2D (C (I), C (Next_Idx (I, N)),
                                C (Next_Idx (K, N)));
         if Near (Area_K, Area_Next) then
            --  Parallel supporting edges: also record next(k).
            Append_Pair (L, Vertex_Index (I),
                         Vertex_Index (Next_Idx (K, N)));
            Append_Pair
              (L,
               Vertex_Index (Next_Idx (I, N)),
               Vertex_Index (Next_Idx (K, N)));
         end if;
      end loop;

      return L;
   end Antipodal_Pairs;

   procedure Caliper_Diameter
     (C        : Polygon;
      Best_D2  : out Real;
      Best_I   : out Vertex_Index;
      Best_J   : out Vertex_Index)
   is
      N : constant Positive := C'Length;
      K : Positive := 2;
      D2 : Real;
   begin
      Best_D2 := 0.0;
      Best_I  := 1;
      Best_J  := 2;

      while Orient2D (C (N), C (1), C (Next_Idx (K, N)))
              > Orient2D (C (N), C (1), C (K)) + Epsilon
      loop
         K := Next_Idx (K, N);
      end loop;

      for I in 1 .. N loop
         while Orient2D (C (I), C (Next_Idx (I, N)), C (Next_Idx (K, N)))
                 > Orient2D (C (I), C (Next_Idx (I, N)), C (K)) + Epsilon
         loop
            K := Next_Idx (K, N);
         end loop;

         D2 := Dist2 (C (I), C (K));
         if D2 > Best_D2 then
            Best_D2 := D2;
            Best_I  := Vertex_Index (I);
            Best_J  := Vertex_Index (K);
         end if;

         D2 := Dist2 (C (Next_Idx (I, N)), C (K));
         if D2 > Best_D2 then
            Best_D2 := D2;
            Best_I  := Vertex_Index (Next_Idx (I, N));
            Best_J  := Vertex_Index (K);
         end if;

         if Near
              (Orient2D (C (I), C (Next_Idx (I, N)), C (K)),
               Orient2D (C (I), C (Next_Idx (I, N)), C (Next_Idx (K, N))))
         then
            D2 := Dist2 (C (I), C (Next_Idx (K, N)));
            if D2 > Best_D2 then
               Best_D2 := D2;
               Best_I  := Vertex_Index (I);
               Best_J  := Vertex_Index (Next_Idx (K, N));
            end if;
            D2 := Dist2 (C (Next_Idx (I, N)), C (Next_Idx (K, N)));
            if D2 > Best_D2 then
               Best_D2 := D2;
               Best_I  := Vertex_Index (Next_Idx (I, N));
               Best_J  := Vertex_Index (Next_Idx (K, N));
            end if;
         end if;
      end loop;
   end Caliper_Diameter;

   function Diameter_Squared (Poly : Polygon) return Real is
      C : constant Polygon := Ensure_Convex_CCW (Poly);
      D2 : Real;
      I, J : Vertex_Index;
   begin
      Caliper_Diameter (C, D2, I, J);
      pragma Unreferenced (I, J);
      return D2;
   end Diameter_Squared;

   function Diameter (Poly : Polygon) return Real is
      D2 : constant Real := Diameter_Squared (Poly);
   begin
      if D2 <= 0.0 then
         return 0.0;
      end if;
      return Real (Math.Sqrt (Long_Float (D2)));
   end Diameter;

   function Diameter_Endpoints (Poly : Polygon) return Antipodal_Pair is
      C : constant Polygon := Ensure_Convex_CCW (Poly);
      D2 : Real;
      I, J : Vertex_Index;
   begin
      Caliper_Diameter (C, D2, I, J);
      pragma Unreferenced (D2);
      if I < J then
         return (I => I, J => J);
      else
         return (I => J, J => I);
      end if;
   end Diameter_Endpoints;

   function Point_Line_Distance
     (P, A, B : Point) return Real
   is
      --  Distance from P to infinite line through A→B.
      Len : constant Real := Dist (A, B);
      Area2 : Real;
   begin
      if Len <= Epsilon then
         return Dist (P, A);
      end if;
      Area2 := abs (Orient2D (A, B, P));
      return Area2 / Len;
   end Point_Line_Distance;

   function Width (Poly : Polygon) return Real is
      C : constant Polygon := Ensure_Convex_CCW (Poly);
      N : constant Positive := C'Length;
      K : Positive := 2;
      W, Cand : Real;
      Edge_Len : Real;
   begin
      W := Real'Last;

      while Orient2D (C (N), C (1), C (Next_Idx (K, N)))
              > Orient2D (C (N), C (1), C (K)) + Epsilon
      loop
         K := Next_Idx (K, N);
      end loop;

      for I in 1 .. N loop
         while Orient2D (C (I), C (Next_Idx (I, N)), C (Next_Idx (K, N)))
                 > Orient2D (C (I), C (Next_Idx (I, N)), C (K)) + Epsilon
         loop
            K := Next_Idx (K, N);
         end loop;

         Edge_Len := Dist (C (I), C (Next_Idx (I, N)));
         if Edge_Len > Epsilon then
            Cand := abs (Orient2D (C (I), C (Next_Idx (I, N)), C (K)))
                    / Edge_Len;
            if Cand < W then
               W := Cand;
            end if;
         end if;
      end loop;

      if W = Real'Last then
         raise Invalid_Argument;
      end if;
      return W;
   end Width;

   function Min_Area_Rect (Poly : Polygon) return Bounding_Rect is
      C : constant Polygon := Ensure_Convex_CCW (Poly);
      N : constant Positive := C'Length;
      K : Positive := 2;
      Best : Bounding_Rect;
      First : Boolean := True;

      --  For edge I as base, project all vertices onto edge direction and
      --  its left normal; form axis-aligned box in that frame.
      procedure Consider_Edge (I : Positive) is
         A : constant Point := C (I);
         B : constant Point := C (Next_Idx (I, N));
         EX : constant Real := B.X - A.X;
         EY : constant Real := B.Y - A.Y;
         ELen : constant Real := Dist (A, B);
         UX, UY, NX, NY : Real;
         Min_U, Max_U, Min_V, Max_V : Real;
         U, V : Real;
         Wd, Ht, Ar : Real;
         Ang : Real;
         R : Bounding_Rect;
      begin
         if ELen <= Epsilon then
            return;
         end if;
         UX := EX / ELen;
         UY := EY / ELen;
         --  Left unit normal (CCW polygon ⇒ inward/outward consistent).
         NX := -UY;
         NY := UX;

         Min_U := Real'Last;
         Max_U := Real'First;
         Min_V := Real'Last;
         Max_V := Real'First;

         for J in 1 .. N loop
            U := (C (J).X - A.X) * UX + (C (J).Y - A.Y) * UY;
            V := (C (J).X - A.X) * NX + (C (J).Y - A.Y) * NY;
            if U < Min_U then
               Min_U := U;
            end if;
            if U > Max_U then
               Max_U := U;
            end if;
            if V < Min_V then
               Min_V := V;
            end if;
            if V > Max_V then
               Max_V := V;
            end if;
         end loop;

         Wd := Max_U - Min_U;
         Ht := Max_V - Min_V;
         if Wd < 0.0 then
            Wd := 0.0;
         end if;
         if Ht < 0.0 then
            Ht := 0.0;
         end if;
         Ar := Wd * Ht;
         Ang := Real (Math.Arctan (Long_Float (EY), Long_Float (EX)));

         --  Four corners in world space (CCW).
         R.Corner (1) :=
           (X => A.X + Min_U * UX + Min_V * NX,
            Y => A.Y + Min_U * UY + Min_V * NY);
         R.Corner (2) :=
           (X => A.X + Max_U * UX + Min_V * NX,
            Y => A.Y + Max_U * UY + Min_V * NY);
         R.Corner (3) :=
           (X => A.X + Max_U * UX + Max_V * NX,
            Y => A.Y + Max_U * UY + Max_V * NY);
         R.Corner (4) :=
           (X => A.X + Min_U * UX + Max_V * NX,
            Y => A.Y + Min_U * UY + Max_V * NY);
         R.Area   := Ar;
         R.Width  := Wd;
         R.Height := Ht;
         R.Angle  := Ang;

         if First or else Ar < Best.Area then
            Best := R;
            First := False;
         end if;
      end Consider_Edge;

   begin
      pragma Unreferenced (K);
      Best.Area := Real'Last;
      for I in 1 .. N loop
         Consider_Edge (I);
      end loop;
      if First then
         raise Invalid_Argument;
      end if;
      return Best;
   end Min_Area_Rect;

   function Pair_Count_Of (L : Antipodal_List) return Pair_Count is
   begin
      return L.Count;
   end Pair_Count_Of;

   function Get_Pair
     (L : Antipodal_List; Index : Pair_Index) return Antipodal_Pair
   is
   begin
      return L.Pairs (Index);
   end Get_Pair;

   ---------------------------------------------------------------------------
   -- Brute-force oracles
   ---------------------------------------------------------------------------

   function Brute_Diameter (Poly : Polygon) return Real is
      N : constant Natural := Poly'Length;
      Best : Real := 0.0;
      D2 : Real;
   begin
      if N < 2 or else N > Max_Vertices then
         raise Invalid_Argument;
      end if;
      for I in Poly'Range loop
         for J in Poly'Range loop
            if J > I then
               D2 := Dist2 (Poly (I), Poly (J));
               if D2 > Best then
                  Best := D2;
               end if;
            end if;
         end loop;
      end loop;
      if Best <= 0.0 then
         return 0.0;
      end if;
      return Real (Math.Sqrt (Long_Float (Best)));
   end Brute_Diameter;

   function Brute_Width (Poly : Polygon) return Real is
      C : constant Polygon := Ensure_Convex_CCW (Poly);
      N : constant Positive := C'Length;
      W : Real := Real'Last;
      Edge_Max, Cand, Edge_Len : Real;
   begin
      for I in 1 .. N loop
         Edge_Len := Dist (C (I), C (Next_Idx (I, N)));
         if Edge_Len > Epsilon then
            Edge_Max := 0.0;
            for J in 1 .. N loop
               Cand := Point_Line_Distance
                         (C (J), C (I), C (Next_Idx (I, N)));
               if Cand > Edge_Max then
                  Edge_Max := Cand;
               end if;
            end loop;
            if Edge_Max < W then
               W := Edge_Max;
            end if;
         end if;
      end loop;
      if W = Real'Last then
         raise Invalid_Argument;
      end if;
      return W;
   end Brute_Width;

end Rotating_Calipers;
