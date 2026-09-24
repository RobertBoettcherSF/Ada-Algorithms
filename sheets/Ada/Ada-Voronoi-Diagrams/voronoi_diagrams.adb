--  Voronoi_Diagrams body — educational 2-D Voronoi via Delaunay dual.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Voronoi_Diagrams
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Elementary_Functions;

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

   function Distance (A, B : Point) return Real is
      D2 : constant Real := Dist2 (A, B);
   begin
      if D2 <= 0.0 then
         return 0.0;
      end if;
      return Real (Math.Sqrt (Float (D2)));
   end Distance;

   ---------------------------------------------------------------------------
   -- Orientation / in-circle
   ---------------------------------------------------------------------------

   function Orient2D (A, B, C : Point) return Real is
   begin
      return (B.X - A.X) * (C.Y - A.Y) - (B.Y - A.Y) * (C.X - A.X);
   end Orient2D;

   function CCW (A, B, C : Point) return Boolean is
   begin
      return Orient2D (A, B, C) > Epsilon;
   end CCW;

   function In_Circumcircle (A, B, C, P : Point) return Boolean is
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
   -- Perpendicular bisector helpers
   ---------------------------------------------------------------------------

   function Midpoint (A, B : Point) return Point is
   begin
      return (X => (A.X + B.X) / 2.0, Y => (A.Y + B.Y) / 2.0);
   end Midpoint;

   function Perpendicular_Direction (A, B : Point) return Point is
      DX : constant Real := B.X - A.X;
      DY : constant Real := B.Y - A.Y;
      --  Rotate 90°: (-DY, DX)
      PX : constant Real := -DY;
      PY : constant Real := DX;
      Len2 : constant Real := PX * PX + PY * PY;
      Len  : Real;
   begin
      if Len2 <= Epsilon * Epsilon then
         return (X => 0.0, Y => 1.0);
      end if;
      Len := Real (Math.Sqrt (Float (Len2)));
      return (X => PX / Len, Y => PY / Len);
   end Perpendicular_Direction;

   function On_Perpendicular_Bisector
     (Q, A, B : Point; Tol : Real := Epsilon) return Boolean
   is
   begin
      return abs (Distance (Q, A) - Distance (Q, B)) <= Tol;
   end On_Perpendicular_Bisector;

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
   -- Internal edge / mesh helpers (embedded Bowyer–Watson)
   ---------------------------------------------------------------------------

   type Edge is record
      U, V : Site_Index := 1;
   end record;

   type Edge_Array is array (Positive range <>) of Edge;

   function Same_Undirected (E1, E2 : Edge) return Boolean is
   begin
      return (E1.U = E2.U and then E1.V = E2.V)
        or else (E1.U = E2.V and then E1.V = E2.U);
   end Same_Undirected;

   function Shares_Vertex
     (Tri : Triangle; V : Site_Index) return Boolean
   is
   begin
      return Tri.A = V or else Tri.B = V or else Tri.C = V;
   end Shares_Vertex;

   function Make_CCW
     (Pts : Point_Array; A, B, C : Site_Index) return Triangle
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
           with "triangle buffer exceeded during Delaunay";
      end if;
      Mesh.Count := Mesh.Count + 1;
      Mesh.Tris (Mesh.Count) := Tri;
   end Append_Triangle;

   procedure Build_Super_Triangle
     (User_Pts : Point_Array;
      Work     : in out Point_Array;
      N_User   : Site_Count;
      Super_A, Super_B, Super_C : out Site_Index)
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
      Margin := 20.0 * Span + 10.0;
      Mid_X := (Box.Min_X + Box.Max_X) / 2.0;
      Mid_Y := (Box.Min_Y + Box.Max_Y) / 2.0;

      Super_A := Site_Index (N_User + 1);
      Super_B := Site_Index (N_User + 2);
      Super_C := Site_Index (N_User + 3);

      Work (Super_A) := (X => Mid_X - Margin, Y => Mid_Y - Margin);
      Work (Super_B) := (X => Mid_X + Margin, Y => Mid_Y - Margin);
      Work (Super_C) := (X => Mid_X,         Y => Mid_Y + Margin);
   end Build_Super_Triangle;

   procedure Insert_Point
     (Work   : Point_Array;
      Mesh   : in out Triangulation;
      P_Idx  : Site_Index)
   is
      Bad       : array (1 .. Max_Triangles) of Boolean := [others => False];
      Bad_Count : Natural := 0;
      Hole      : Edge_Array (1 .. Max_Hole_Edges);
      Hole_N    : Natural := 0;
      P         : constant Point := Work (P_Idx);
      New_Mesh  : Triangulation;
      Shared    : Boolean;
   begin
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
         return;
      end if;

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

      New_Mesh.Count := 0;
      for I in 1 .. Mesh.Count loop
         if not Bad (I) then
            Append_Triangle (New_Mesh, Mesh.Tris (I));
         end if;
      end loop;

      for K in 1 .. Hole_N loop
         Append_Triangle
           (New_Mesh,
            Make_CCW (Work, Hole (K).U, Hole (K).V, P_Idx));
      end loop;

      Mesh := New_Mesh;
   end Insert_Point;

   ---------------------------------------------------------------------------
   -- Public Delaunay API
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

   function Delaunay_From_Sites (Sites : Point_Array) return Triangulation is
      N : constant Natural := Sites'Length;
      Work : Point_Array (1 .. Max_Sites + 3);
      Mesh : Triangulation;
      Super_A, Super_B, Super_C : Site_Index;
      Result : Triangulation;
      Src : Site_Index;
   begin
      if N < 3 then
         raise Invalid_Argument
           with "Delaunay_From_Sites requires at least 3 sites";
      end if;
      if N > Max_Sites then
         raise Invalid_Argument
           with "Delaunay_From_Sites: more than Max_Sites sites";
      end if;
      if Has_Near_Duplicate (Sites) then
         raise Invalid_Argument
           with "Delaunay_From_Sites: near-duplicate sites detected";
      end if;

      Src := 1;
      for I in Sites'Range loop
         Work (Src) := Sites (I);
         Src := Src + 1;
      end loop;

      Build_Super_Triangle
        (User_Pts => Sites,
         Work     => Work,
         N_User   => Site_Count (N),
         Super_A  => Super_A,
         Super_B  => Super_B,
         Super_C  => Super_C);

      Mesh.Count := 0;
      Append_Triangle
        (Mesh, Make_CCW (Work, Super_A, Super_B, Super_C));

      for P_Idx in 1 .. Site_Index (N) loop
         Insert_Point (Work, Mesh, P_Idx);
      end loop;

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
   end Delaunay_From_Sites;

   function Is_Delaunay_Empty_Circle
     (Sites : Point_Array; T : Triangulation) return Boolean
   is
      N : constant Natural := Sites'Length;
      Local : Point_Array (1 .. Max_Sites);
      K : Site_Index := 1;
   begin
      if N = 0 or else T.Count = 0 then
         return True;
      end if;
      for I in Sites'Range loop
         Local (K) := Sites (I);
         K := K + 1;
      end loop;

      for Ti in 1 .. T.Count loop
         declare
            Tri : constant Triangle := T.Tris (Ti);
            A : constant Point := Local (Tri.A);
            B : constant Point := Local (Tri.B);
            C : constant Point := Local (Tri.C);
         begin
            for Pi in 1 .. Site_Index (N) loop
               if Pi /= Tri.A and then Pi /= Tri.B and then Pi /= Tri.C then
                  if In_Circumcircle (A, B, C, Local (Pi)) then
                     return False;
                  end if;
               end if;
            end loop;
         end;
      end loop;
      return True;
   end Is_Delaunay_Empty_Circle;

   ---------------------------------------------------------------------------
   -- Nearest site (brute-force cell membership)
   ---------------------------------------------------------------------------

   function Nearest_Site
     (Query : Point; Sites : Point_Array) return Site_Index
   is
      N : constant Natural := Sites'Length;
      Best_I : Site_Index;
      Best_D2 : Real;
      D2 : Real;
      Local_I : Site_Index;
   begin
      if N = 0 then
         raise Invalid_Argument with "Nearest_Site: empty site set";
      end if;
      if N > Max_Sites then
         raise Invalid_Argument with "Nearest_Site: more than Max_Sites";
      end if;

      Best_I := 1;
      Best_D2 := Dist2 (Query, Sites (Sites'First));
      Local_I := 1;
      for I in Sites'Range loop
         D2 := Dist2 (Query, Sites (I));
         if D2 < Best_D2 then
            Best_D2 := D2;
            Best_I := Local_I;
         end if;
         Local_I := Local_I + 1;
      end loop;
      return Best_I;
   end Nearest_Site;

   ---------------------------------------------------------------------------
   -- Voronoi dual construction
   ---------------------------------------------------------------------------

   function Voronoi_Vertex_Count_Of
     (V : Voronoi_Diagram) return Voronoi_Vertex_Count
   is
   begin
      return V.Vertex_N;
   end Voronoi_Vertex_Count_Of;

   function Voronoi_Edge_Count_Of
     (V : Voronoi_Diagram) return Voronoi_Edge_Count
   is
   begin
      return V.Edge_N;
   end Voronoi_Edge_Count_Of;

   function Get_Voronoi_Vertex
     (V : Voronoi_Diagram; Index : Voronoi_Vertex_Index) return Voronoi_Vertex
   is
   begin
      return V.Vertices (Index);
   end Get_Voronoi_Vertex;

   function Get_Voronoi_Edge
     (V : Voronoi_Diagram; Index : Voronoi_Edge_Index) return Voronoi_Edge
   is
   begin
      return V.Edges (Index);
   end Get_Voronoi_Edge;

   function Count_Bounded_Edges (V : Voronoi_Diagram) return Natural is
      N : Natural := 0;
   begin
      for I in 1 .. V.Edge_N loop
         if V.Edges (I).Bounded then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count_Bounded_Edges;

   function Count_Unbounded_Edges (V : Voronoi_Diagram) return Natural is
      N : Natural := 0;
   begin
      for I in 1 .. V.Edge_N loop
         if not V.Edges (I).Bounded then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Count_Unbounded_Edges;

   procedure Append_Voronoi_Edge
     (V : in out Voronoi_Diagram; E : Voronoi_Edge)
   is
   begin
      if V.Edge_N = Max_Voronoi_Edges then
         raise Capacity_Exceeded with "Voronoi edge buffer exceeded";
      end if;
      V.Edge_N := V.Edge_N + 1;
      V.Edges (V.Edge_N) := E;
   end Append_Voronoi_Edge;

   --  Find up to two triangles that contain undirected edge (U,V).
   procedure Triangles_Of_Edge
     (T : Triangulation;
      U, V : Site_Index;
      T1, T2 : out Natural;
      Count  : out Natural)
   is
      function Has_Edge (Tri : Triangle) return Boolean is
      begin
         return (Tri.A = U and then Tri.B = V)
           or else (Tri.B = U and then Tri.C = V)
           or else (Tri.C = U and then Tri.A = V)
           or else (Tri.A = V and then Tri.B = U)
           or else (Tri.B = V and then Tri.C = U)
           or else (Tri.C = V and then Tri.A = U);
      end Has_Edge;
   begin
      T1 := 0;
      T2 := 0;
      Count := 0;
      for I in 1 .. T.Count loop
         if Has_Edge (T.Tris (I)) then
            Count := Count + 1;
            if Count = 1 then
               T1 := Natural (I);
            elsif Count = 2 then
               T2 := Natural (I);
               return;
            end if;
         end if;
      end loop;
   end Triangles_Of_Edge;

   function Third_Vertex
     (Tri : Triangle; U, V : Site_Index) return Site_Index
   is
   begin
      if Tri.A /= U and then Tri.A /= V then
         return Tri.A;
      elsif Tri.B /= U and then Tri.B /= V then
         return Tri.B;
      else
         return Tri.C;
      end if;
   end Third_Vertex;

   function Build_Voronoi (Sites : Point_Array) return Voronoi_Diagram is
      N : constant Natural := Sites'Length;
      V : Voronoi_Diagram;
      DT : Triangulation;
      Local : Point_Array (1 .. Max_Sites);
      K : Site_Index := 1;
      --  Track processed undirected edges via (min,max) pairs.
      type Pair is record
         Lo, Hi : Site_Index := 1;
         Used   : Boolean := False;
      end record;
      Max_Pairs : constant Positive := Max_Triangles * 3;
      Pairs : array (1 .. Max_Pairs) of Pair := [others => <>];
      Pair_N : Natural := 0;

      procedure Note_Edge (U, Vtx : Site_Index) is
         Lo : Site_Index := U;
         Hi : Site_Index := Vtx;
         Found : Boolean := False;
      begin
         if Hi < Lo then
            Lo := Vtx;
            Hi := U;
         end if;
         for I in 1 .. Pair_N loop
            if Pairs (I).Lo = Lo and then Pairs (I).Hi = Hi then
               Found := True;
               exit;
            end if;
         end loop;
         if not Found then
            if Pair_N >= Max_Pairs then
               raise Capacity_Exceeded with "Delaunay edge pair buffer";
            end if;
            Pair_N := Pair_N + 1;
            Pairs (Pair_N) := (Lo => Lo, Hi => Hi, Used => False);
         end if;
      end Note_Edge;
   begin
      DT := Delaunay_From_Sites (Sites);

      V.Site_N := Site_Count (N);
      for I in Sites'Range loop
         Local (K) := Sites (I);
         V.Sites (K) := Sites (I);
         K := K + 1;
      end loop;
      V.Delaunay := DT;

      --  Voronoi vertices = circumcenters.
      V.Vertex_N := 0;
      for Ti in 1 .. DT.Count loop
         declare
            Tri : constant Triangle := DT.Tris (Ti);
            O : constant Point :=
              Circumcenter (Local (Tri.A), Local (Tri.B), Local (Tri.C));
         begin
            if V.Vertex_N = Max_Voronoi_Vertices then
               raise Capacity_Exceeded with "Voronoi vertex buffer";
            end if;
            V.Vertex_N := V.Vertex_N + 1;
            V.Vertices (V.Vertex_N) :=
              (Location => O, Source_Triangle => Ti);
         end;
      end loop;

      --  Collect unique Delaunay edges.
      for Ti in 1 .. DT.Count loop
         declare
            Tri : constant Triangle := DT.Tris (Ti);
         begin
            Note_Edge (Tri.A, Tri.B);
            Note_Edge (Tri.B, Tri.C);
            Note_Edge (Tri.C, Tri.A);
         end;
      end loop;

      V.Edge_N := 0;
      for Pi in 1 .. Pair_N loop
         declare
            U : constant Site_Index := Pairs (Pi).Lo;
            W : constant Site_Index := Pairs (Pi).Hi;
            T1, T2, Cnt : Natural;
            E : Voronoi_Edge;
         begin
            Triangles_Of_Edge (DT, U, W, T1, T2, Cnt);
            E.Site_A := U;
            E.Site_B := W;
            if Cnt = 2 then
               --  Bounded dual segment between two circumcenters.
               E.Bounded := True;
               E.V_From := Voronoi_Vertex_Index (T1);
               E.V_To   := Voronoi_Vertex_Index (T2);
               E.Direction := (0.0, 0.0);
               Append_Voronoi_Edge (V, E);
            elsif Cnt = 1 then
               --  Hull edge → unbounded ray.
               declare
                  Tri : constant Triangle := DT.Tris (Triangle_Index (T1));
                  Third : constant Site_Index := Third_Vertex (Tri, U, W);
                  Mid : constant Point := Midpoint (Local (U), Local (W));
                  Dir : Point := Perpendicular_Direction (Local (U), Local (W));
                  --  Orient outward: from third vertex through Mid, away
                  --  from Third. Dot (Dir, Mid - Third) should be > 0.
                  VX : constant Real := Mid.X - Local (Third).X;
                  VY : constant Real := Mid.Y - Local (Third).Y;
               begin
                  if Dir.X * VX + Dir.Y * VY < 0.0 then
                     Dir := (X => -Dir.X, Y => -Dir.Y);
                  end if;
                  E.Bounded := False;
                  E.V_From := Voronoi_Vertex_Index (T1);
                  E.V_To   := 1;  -- unused for rays
                  E.Direction := Dir;
                  Append_Voronoi_Edge (V, E);
               end;
            end if;
         end;
      end loop;

      return V;
   end Build_Voronoi;

end Voronoi_Diagrams;
