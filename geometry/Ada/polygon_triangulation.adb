--  Polygon_Triangulation body — ear clipping of a simple polygon
--  (educational Float predicates; O(n²)).

pragma Ada_2022;

package body Polygon_Triangulation
  with SPARK_Mode => Off
is

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

   ---------------------------------------------------------------------------
   -- Orientation / point-in-triangle
   ---------------------------------------------------------------------------

   function Orient2D (A, B, C : Point) return Real is
   begin
      --  (Bx - Ax)*(Cy - Ay) - (By - Ay)*(Cx - Ax)
      return (B.X - A.X) * (C.Y - A.Y) - (B.Y - A.Y) * (C.X - A.X);
   end Orient2D;

   function CCW (A, B, C : Point) return Boolean is
   begin
      return Orient2D (A, B, C) > Epsilon;
   end CCW;

   function Point_In_Triangle
     (P, A, B, C : Point; Strict : Boolean := True) return Boolean
   is
      O  : constant Real := Orient2D (A, B, C);
      O1 : constant Real := Orient2D (A, B, P);
      O2 : constant Real := Orient2D (B, C, P);
      O3 : constant Real := Orient2D (C, A, P);
      Tol : constant Real := Epsilon;
   begin
      if abs (O) <= Tol then
         --  Degenerate triangle: treat as empty interior.
         return False;
      end if;

      if O > 0.0 then
         --  CCW triangle: P inside iff all three turns are left (or
         --  non-right when not Strict).
         if Strict then
            return O1 > Tol and then O2 > Tol and then O3 > Tol;
         else
            return O1 >= -Tol and then O2 >= -Tol and then O3 >= -Tol;
         end if;
      else
         --  CW triangle: P inside iff all three turns are right.
         if Strict then
            return O1 < -Tol and then O2 < -Tol and then O3 < -Tol;
         else
            return O1 <= Tol and then O2 <= Tol and then O3 <= Tol;
         end if;
      end if;
   end Point_In_Triangle;

   ---------------------------------------------------------------------------
   -- Polygon measures
   ---------------------------------------------------------------------------

   function Signed_Area (Polygon : Point_Array) return Real is
      Sum : Real := 0.0;
      N   : constant Natural := Polygon'Length;
      J   : Vertex_Index;
   begin
      if N < 3 then
         return 0.0;
      end if;
      for I in Polygon'Range loop
         if I = Polygon'Last then
            J := Polygon'First;
         else
            J := I + 1;
         end if;
         Sum := Sum + Polygon (I).X * Polygon (J).Y
                    - Polygon (J).X * Polygon (I).Y;
      end loop;
      return Sum;  --  twice signed area (shoelace without /2)
   end Signed_Area;

   function Area (Polygon : Point_Array) return Real is
   begin
      return abs (Signed_Area (Polygon)) / 2.0;
   end Area;

   function Is_CCW (Polygon : Point_Array) return Boolean is
   begin
      return Signed_Area (Polygon) > Epsilon;
   end Is_CCW;

   ---------------------------------------------------------------------------
   -- Local helpers for cyclic neighbours on a dense 1 .. N ring
   ---------------------------------------------------------------------------

   function Prev_Of (I : Positive; N : Positive) return Positive is
     (if I = 1 then N else I - 1);

   function Next_Of (I : Positive; N : Positive) return Positive is
     (if I = N then 1 else I + 1);

   --  Map an absolute index in Polygon'Range to dense 1 .. N.
   function Dense (Polygon : Point_Array; Abs_Index : Vertex_Index)
     return Positive
   is
   begin
      return Positive (Abs_Index - Polygon'First + 1);
   end Dense;

   --  Map dense 1 .. N back to absolute Polygon index.
   function Abs_Of (Polygon : Point_Array; Dense_Index : Positive)
     return Vertex_Index
   is
   begin
      return Vertex_Index (Polygon'First + Dense_Index - 1);
   end Abs_Of;

   ---------------------------------------------------------------------------
   -- Convex / ear on the input polygon (with CW → conceptual reverse)
   ---------------------------------------------------------------------------

   function Is_Convex_Vertex
     (Polygon : Point_Array; Index : Vertex_Index) return Boolean
   is
      N    : constant Positive := Polygon'Length;
      D    : constant Positive := Dense (Polygon, Index);
      Pv   : constant Positive := Prev_Of (D, N);
      Nx   : constant Positive := Next_Of (D, N);
      A    : constant Point := Polygon (Abs_Of (Polygon, Pv));
      B    : constant Point := Polygon (Index);
      C    : constant Point := Polygon (Abs_Of (Polygon, Nx));
      O    : constant Real := Orient2D (A, B, C);
      CCW_P : constant Boolean := Is_CCW (Polygon);
   begin
      --  For a CCW polygon a convex vertex is a left turn; for CW, a right
      --  turn (equivalently: reverse the ring, then require left turns).
      if CCW_P then
         return O > Epsilon;
      else
         return O < -Epsilon;
      end if;
   end Is_Convex_Vertex;

   function Is_Ear
     (Polygon : Point_Array; Index : Vertex_Index) return Boolean
   is
      N  : constant Positive := Polygon'Length;
      D  : constant Positive := Dense (Polygon, Index);
      Pv : constant Positive := Prev_Of (D, N);
      Nx : constant Positive := Next_Of (D, N);
      A  : constant Point := Polygon (Abs_Of (Polygon, Pv));
      B  : constant Point := Polygon (Index);
      C  : constant Point := Polygon (Abs_Of (Polygon, Nx));
      K  : Positive;
      Q  : Point;
   begin
      if N < 3 then
         return False;
      end if;
      if N = 3 then
         --  The single remaining triangle is trivially an "ear".
         return Is_Convex_Vertex (Polygon, Index)
           or else abs (Orient2D (A, B, C)) > Epsilon;
      end if;

      if not Is_Convex_Vertex (Polygon, Index) then
         return False;
      end if;

      --  No other vertex strictly inside triangle ABC.
      for I in 1 .. N loop
         if I /= Pv and then I /= D and then I /= Nx then
            K := I;
            Q := Polygon (Abs_Of (Polygon, K));
            if Point_In_Triangle (Q, A, B, C, Strict => True) then
               return False;
            end if;
         end if;
      end loop;
      return True;
   end Is_Ear;

   function Is_Simple_Enough (Polygon : Point_Array) return Boolean is
      N : constant Natural := Polygon'Length;
   begin
      if N < 3 or else N > Max_Vertices then
         return False;
      end if;

      --  No consecutive near-duplicates (including closing edge).
      for I in Polygon'Range loop
         declare
            J : Vertex_Index;
         begin
            if I = Polygon'Last then
               J := Polygon'First;
            else
               J := I + 1;
            end if;
            if Near_Point (Polygon (I), Polygon (J)) then
               return False;
            end if;
         end;
      end loop;

      if abs (Signed_Area (Polygon)) <= Epsilon then
         return False;
      end if;

      return True;
   end Is_Simple_Enough;

   ---------------------------------------------------------------------------
   -- Ear-clipping triangulation
   ---------------------------------------------------------------------------

   function Triangulate_Ear_Clip (Polygon : Point_Array) return Triangulation
   is
      N_In : constant Natural := Polygon'Length;
      Result : Triangulation;
   begin
      if N_In < 3 or else N_In > Max_Vertices then
         raise Invalid_Argument;
      end if;
      if not Is_Simple_Enough (Polygon) then
         raise Invalid_Argument;
      end if;

      declare
         N : Positive := N_In;
         --  Working ring of dense original indices (1 .. N_In).
         --  When the input is CW we reverse the ring so ear tests use
         --  positive (CCW) turns; emitted triangle indices still refer to
         --  the original dense numbering of Polygon.
         Ring : array (1 .. Max_Vertices) of Positive;
         Verts : array (1 .. Max_Vertices) of Point;
         --  Verts (K) = Polygon point with dense index Ring (K) after
         --  optional reverse for CCW processing.

         function R_Prev (I : Positive) return Positive is
           (if I = 1 then N else I - 1);
         function R_Next (I : Positive) return Positive is
           (if I = N then 1 else I + 1);

         procedure Remove_At (Pos : Positive) is
         begin
            for J in Pos .. N - 1 loop
               Ring (J) := Ring (J + 1);
               Verts (J) := Verts (J + 1);
            end loop;
            N := N - 1;
         end Remove_At;

         function Ring_Is_Ear (Pos : Positive) return Boolean is
            Pv : constant Positive := R_Prev (Pos);
            Nx : constant Positive := R_Next (Pos);
            A  : constant Point := Verts (Pv);
            B  : constant Point := Verts (Pos);
            C  : constant Point := Verts (Nx);
            O  : constant Real := Orient2D (A, B, C);
         begin
            --  Working ring is always CCW-normalized ⇒ convex = left turn.
            if O <= Epsilon then
               return False;
            end if;
            if N = 3 then
               return True;
            end if;
            for I in 1 .. N loop
               if I /= Pv and then I /= Pos and then I /= Nx then
                  if Point_In_Triangle
                    (Verts (I), A, B, C, Strict => True)
                  then
                     return False;
                  end if;
               end if;
            end loop;
            return True;
         end Ring_Is_Ear;

         Found : Boolean;
         Tip   : Positive;
         Tri_N : Natural := 0;
      begin
         --  Initialise ring in input order, then reverse if CW.
         for I in 1 .. N_In loop
            Ring (I) := I;
            Verts (I) := Polygon (Abs_Of (Polygon, I));
         end loop;

         if Signed_Area (Polygon) < -Epsilon then
            --  Reverse to CCW (keep original dense indices in Ring).
            declare
               L, R : Positive;
               Tmp_I : Positive;
               Tmp_P : Point;
            begin
               L := 1;
               R := N_In;
               while L < R loop
                  Tmp_I := Ring (L);
                  Ring (L) := Ring (R);
                  Ring (R) := Tmp_I;
                  Tmp_P := Verts (L);
                  Verts (L) := Verts (R);
                  Verts (R) := Tmp_P;
                  L := L + 1;
                  R := R - 1;
               end loop;
            end;
         end if;

         --  Clip ears until one triangle remains.
         while N > 3 loop
            Found := False;
            Tip := 1;
            for Pos in 1 .. N loop
               if Ring_Is_Ear (Pos) then
                  Tip := Pos;
                  Found := True;
                  exit;
               end if;
            end loop;

            if not Found then
               --  Non-simple / numerical failure: cannot progress.
               raise Invalid_Argument;
            end if;

            if Tri_N >= Max_Triangles then
               raise Capacity_Exceeded;
            end if;
            Tri_N := Tri_N + 1;

            Result.Tris (Triangle_Index (Tri_N)) :=
              (A => Vertex_Index (Ring (R_Prev (Tip))),
               B => Vertex_Index (Ring (Tip)),
               C => Vertex_Index (Ring (R_Next (Tip))));

            Remove_At (Tip);
         end loop;

         --  Final triangle.
         if Tri_N >= Max_Triangles then
            raise Capacity_Exceeded;
         end if;
         Tri_N := Tri_N + 1;
         Result.Tris (Triangle_Index (Tri_N)) :=
           (A => Vertex_Index (Ring (1)),
            B => Vertex_Index (Ring (2)),
            C => Vertex_Index (Ring (3)));
         Result.Count := Triangle_Count (Tri_N);
      end;

      --  Expect exactly n−2 triangles for a simple n-gon.
      if Result.Count /= Triangle_Count (N_In - 2) then
         raise Invalid_Argument;
      end if;

      return Result;
   end Triangulate_Ear_Clip;

   function Triangle_Count_Of (T : Triangulation) return Triangle_Count is
   begin
      return T.Count;
   end Triangle_Count_Of;

   function Get_Triangle
     (T : Triangulation; Index : Triangle_Index) return Triangle
   is
   begin
      return T.Tris (Index);
   end Get_Triangle;

   function Uses_Vertex
     (Tri : Triangle; V : Vertex_Index) return Boolean
   is
   begin
      return Tri.A = V or else Tri.B = V or else Tri.C = V;
   end Uses_Vertex;

end Polygon_Triangulation;
