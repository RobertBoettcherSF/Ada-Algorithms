--  Bowyer_Watson body — incremental 2-D Delaunay (educational Float).

pragma Ada_2022;


package body Bowyer_Watson
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
   -- Orientation / in-circle
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

   function In_Circumcircle (A, B, C, P : Point) return Boolean is
      --  Determinant form (Shewchuk / Guibas–Stolfi style, Float only):
      --  | Ax-Px  Ay-Py  (Ax-Px)^2+(Ay-Py)^2 |
      --  | Bx-Px  By-Py  (Bx-Px)^2+(By-Py)^2 |  > 0  ⇒ P inside circle of
      --  | Cx-Px  Cy-Py  (Cx-Px)^2+(Cy-Py)^2 |     CCW triangle ABC.
      Adx : constant Real := A.X - P.X;
      Ady : constant Real := A.Y - P.Y;
      Bdx : constant Real := B.X - P.X;
      Bdy : constant Real := B.Y - P.Y;
      Cdx : constant Real := C.X - P.X;
      Cdy : constant Real := C.Y - P.Y;
      Ad2 : constant Real := Adx * Adx + Ady * Ady;
      Bd2 : constant Real := Bdx * Bdx + Bdy * Bdy;
      Cd2 : constant Real := Cdx * Cdx + Cdy * Cdy;
      Det : constant Real :=
        Adx * (Bdy * Cd2 - Bd2 * Cdy)
        - Ady * (Bdx * Cd2 - Bd2 * Cdx)
        + Ad2 * (Bdx * Cdy - Bdy * Cdx);
   begin
      return Det > Epsilon;
   end In_Circumcircle;

   function Circumcenter (A, B, C : Point) return Point is
      D : constant Real := 2.0 *
        (A.X * (B.Y - C.Y) + B.X * (C.Y - A.Y) + C.X * (A.Y - B.Y));
      A2 : constant Real := A.X * A.X + A.Y * A.Y;
      B2 : constant Real := B.X * B.X + B.Y * B.Y;
      C2 : constant Real := C.X * C.X + C.Y * C.Y;
      Ux, Uy : Real;
   begin
      if abs (D) <= Epsilon then
         --  Degenerate: fall back to centroid (educational safety).
         return (X => (A.X + B.X + C.X) / 3.0,
                 Y => (A.Y + B.Y + C.Y) / 3.0);
      end if;
      Ux := (A2 * (B.Y - C.Y) + B2 * (C.Y - A.Y) + C2 * (A.Y - B.Y)) / D;
      Uy := (A2 * (C.X - B.X) + B2 * (A.X - C.X) + C2 * (B.X - A.X)) / D;
      return (X => Ux, Y => Uy);
   end Circumcenter;

   function Circumradius2 (A, B, C : Point) return Real is
      O : constant Point := Circumcenter (A, B, C);
   begin
      return Dist2 (O, A);
   end Circumradius2;

   ---------------------------------------------------------------------------
   -- Bounds / duplicates
   ---------------------------------------------------------------------------

   function Bounds_Of (Points : Point_Array) return Bounding_Box is
      B : Bounding_Box;
   begin
      B.Min_X := Points (Points'First).X;
      B.Max_X := Points (Points'First).X;
      B.Min_Y := Points (Points'First).Y;
      B.Max_Y := Points (Points'First).Y;
      for I in Points'Range loop
         if Points (I).X < B.Min_X then
            B.Min_X := Points (I).X;
         end if;
         if Points (I).X > B.Max_X then
            B.Max_X := Points (I).X;
         end if;
         if Points (I).Y < B.Min_Y then
            B.Min_Y := Points (I).Y;
         end if;
         if Points (I).Y > B.Max_Y then
            B.Max_Y := Points (I).Y;
         end if;
      end loop;
      return B;
   end Bounds_Of;

   function Has_Near_Duplicate
     (Points : Point_Array; Tol : Real := Epsilon) return Boolean
   is
      Tol2 : constant Real := Tol * Tol;
   begin
      for I in Points'Range loop
         for J in Points'Range loop
            if J > I and then Dist2 (Points (I), Points (J)) <= Tol2 then
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Has_Near_Duplicate;

   ---------------------------------------------------------------------------
   -- Internal edge / mesh helpers
   ---------------------------------------------------------------------------

   type Edge is record
      U, V : Point_Index := 1;
   end record;

   type Edge_Array is array (Positive range <>) of Edge;

   function Same_Undirected (E1, E2 : Edge) return Boolean is
   begin
      return (E1.U = E2.U and then E1.V = E2.V)
        or else (E1.U = E2.V and then E1.V = E2.U);
   end Same_Undirected;

   function Shares_Vertex
     (Tri : Triangle; V : Point_Index) return Boolean
   is
   begin
      return Tri.A = V or else Tri.B = V or else Tri.C = V;
   end Shares_Vertex;

   function Make_CCW
     (Pts : Point_Array; A, B, C : Point_Index) return Triangle
   is
   begin
      if Orient2D (Pts (A), Pts (B), Pts (C)) >= 0.0 then
         return (A => A, B => B, C => C);
      else
         return (A => A, B => C, C => B);
      end if;
   end Make_CCW;

   procedure Append_Triangle
     (Mesh : in out Triangulation; Tri : Triangle)
   is
   begin
      if Mesh.Count = Max_Triangles then
         raise Capacity_Exceeded
           with "triangle buffer exceeded during Bowyer–Watson";
      end if;
      Mesh.Count := Mesh.Count + 1;
      Mesh.Tris (Mesh.Count) := Tri;
   end Append_Triangle;

   ---------------------------------------------------------------------------
   -- Super-triangle
   ---------------------------------------------------------------------------

   procedure Build_Super_Triangle
     (User_Pts : Point_Array;
      Work     : in out Point_Array;
      N_User   : Point_Count;
      Super_A, Super_B, Super_C : out Point_Index)
   is
      Box : constant Bounding_Box := Bounds_Of (User_Pts);
      DX  : constant Real := Box.Max_X - Box.Min_X;
      DY  : constant Real := Box.Max_Y - Box.Min_Y;
      Span : Real := DX;
      Mid_X, Mid_Y, Margin : Real;
   begin
      if DY > Span then
         Span := DY;
      end if;
      if Span < 1.0 then
         Span := 1.0;
      end if;
      --  Large enclosing triangle (educational; generous margin).
      Margin := 20.0 * Span + 10.0;
      Mid_X := (Box.Min_X + Box.Max_X) / 2.0;
      Mid_Y := (Box.Min_Y + Box.Max_Y) / 2.0;

      Super_A := Point_Index (N_User + 1);
      Super_B := Point_Index (N_User + 2);
      Super_C := Point_Index (N_User + 3);

      Work (Super_A) := (X => Mid_X - Margin, Y => Mid_Y - Margin);
      Work (Super_B) := (X => Mid_X + Margin, Y => Mid_Y - Margin);
      Work (Super_C) := (X => Mid_X,         Y => Mid_Y + Margin);
   end Build_Super_Triangle;

   ---------------------------------------------------------------------------
   -- Insert one site
   ---------------------------------------------------------------------------

   procedure Insert_Point
     (Work   : Point_Array;
      Mesh   : in out Triangulation;
      P_Idx  : Point_Index)
   is
      Bad      : array (1 .. Max_Triangles) of Boolean := [others => False];
      Bad_Count : Natural := 0;
      Hole      : Edge_Array (1 .. Max_Hole_Edges);
      Hole_N    : Natural := 0;
      P         : constant Point := Work (P_Idx);
      New_Mesh  : Triangulation;
      Shared    : Boolean;
   begin
      --  1. Mark bad triangles (circumcircle contains P).
      for I in 1 .. Mesh.Count loop
         declare
            Tri : constant Triangle := Mesh.Tris (I);
         begin
            if In_Circumcircle
              (Work (Tri.A), Work (Tri.B), Work (Tri.C), P)
            then
               Bad (I) := True;
               Bad_Count := Bad_Count + 1;
            end if;
         end;
      end loop;

      if Bad_Count = 0 then
         --  Should not happen if super-triangle contains all sites; skip.
         return;
      end if;

      --  2. Collect unique boundary edges of the polygonal hole.
      for I in 1 .. Mesh.Count loop
         if Bad (I) then
            declare
               Tri : constant Triangle := Mesh.Tris (I);
               E1  : constant Edge := (U => Tri.A, V => Tri.B);
               E2  : constant Edge := (U => Tri.B, V => Tri.C);
               E3  : constant Edge := (U => Tri.C, V => Tri.A);

               procedure Consider (E : Edge) is
               begin
                  Shared := False;
                  for J in 1 .. Mesh.Count loop
                     if Bad (J) and then J /= I then
                        declare
                           Tj : constant Triangle := Mesh.Tris (J);
                           F1 : constant Edge := (U => Tj.A, V => Tj.B);
                           F2 : constant Edge := (U => Tj.B, V => Tj.C);
                           F3 : constant Edge := (U => Tj.C, V => Tj.A);
                        begin
                           if Same_Undirected (E, F1)
                             or else Same_Undirected (E, F2)
                             or else Same_Undirected (E, F3)
                           then
                              Shared := True;
                              exit;
                           end if;
                        end;
                     end if;
                  end loop;
                  if not Shared then
                     if Hole_N >= Max_Hole_Edges then
                        raise Capacity_Exceeded
                          with "hole edge buffer exceeded";
                     end if;
                     Hole_N := Hole_N + 1;
                     Hole (Hole_N) := E;
                  end if;
               end Consider;
            begin
               Consider (E1);
               Consider (E2);
               Consider (E3);
            end;
         end if;
      end loop;

      --  3. Keep good triangles.
      New_Mesh.Count := 0;
      for I in 1 .. Mesh.Count loop
         if not Bad (I) then
            Append_Triangle (New_Mesh, Mesh.Tris (I));
         end if;
      end loop;

      --  4. Retriangulate hole to P.
      for K in 1 .. Hole_N loop
         Append_Triangle
           (New_Mesh,
            Make_CCW (Work, Hole (K).U, Hole (K).V, P_Idx));
      end loop;

      Mesh := New_Mesh;
   end Insert_Point;

   ---------------------------------------------------------------------------
   -- Public API
   ---------------------------------------------------------------------------

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

   function Triangulate (Points : Point_Array) return Triangulation is
      N : constant Natural := Points'Length;
      Work : Point_Array (1 .. Max_Points + 3);
      Mesh : Triangulation;
      Super_A, Super_B, Super_C : Point_Index;
      Result : Triangulation;
      Src : Point_Index;
   begin
      if N < 3 then
         raise Invalid_Argument
           with "Triangulate requires at least 3 points";
      end if;
      if N > Max_Points then
         raise Invalid_Argument
           with "Triangulate: more than Max_Points sites";
      end if;
      if Has_Near_Duplicate (Points) then
         raise Invalid_Argument
           with "Triangulate: near-duplicate sites detected";
      end if;

      --  Copy user sites into Work (1 .. N), preserving relative order.
      Src := 1;
      for I in Points'Range loop
         Work (Src) := Points (I);
         Src := Src + 1;
      end loop;

      Build_Super_Triangle
        (User_Pts => Points,
         Work     => Work,
         N_User   => Point_Count (N),
         Super_A  => Super_A,
         Super_B  => Super_B,
         Super_C  => Super_C);

      Mesh.Count := 0;
      Append_Triangle
        (Mesh, Make_CCW (Work, Super_A, Super_B, Super_C));

      for P_Idx in 1 .. Point_Index (N) loop
         Insert_Point (Work, Mesh, P_Idx);
      end loop;

      --  Strip triangles incident to any super-triangle vertex.
      Result.Count := 0;
      for I in 1 .. Mesh.Count loop
         declare
            Tri : constant Triangle := Mesh.Tris (I);
         begin
            if not Shares_Vertex (Tri, Super_A)
              and then not Shares_Vertex (Tri, Super_B)
              and then not Shares_Vertex (Tri, Super_C)
            then
               Append_Triangle (Result, Tri);
            end if;
         end;
      end loop;


      return Result;
   end Triangulate;

   function Is_Delaunay_Edge_Empty
     (Points : Point_Array; T : Triangulation) return Boolean
   is
      --  Remap: Triangulate stores indices 1 .. N matching Points order
      --  when Points'First = 1; otherwise we rebuild a local table.
      N : constant Natural := Points'Length;
      Local : Point_Array (1 .. Max_Points);
      K : Point_Index := 1;
   begin
      if N = 0 or else T.Count = 0 then
         return True;
      end if;
      for I in Points'Range loop
         Local (K) := Points (I);
         K := K + 1;
      end loop;

      for Ti in 1 .. T.Count loop
         declare
            Tri : constant Triangle := T.Tris (Ti);
            A : constant Point := Local (Tri.A);
            B : constant Point := Local (Tri.B);
            C : constant Point := Local (Tri.C);
         begin
            for Pi in 1 .. Point_Index (N) loop
               if Pi /= Tri.A and then Pi /= Tri.B and then Pi /= Tri.C then
                  if In_Circumcircle (A, B, C, Local (Pi)) then
                     return False;
                  end if;
               end if;
            end loop;
         end;
      end loop;
      return True;
   end Is_Delaunay_Edge_Empty;

end Bowyer_Watson;
