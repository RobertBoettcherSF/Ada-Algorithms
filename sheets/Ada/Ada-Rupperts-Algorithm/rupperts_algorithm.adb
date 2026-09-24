--  Rupperts_Algorithm body — Delaunay refinement (educational Float).

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Rupperts_Algorithm
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Elementary_Functions;

   Pi : constant Real := 3.141_592_653_589_793;
   Rad_To_Deg : constant Real := 180.0 / Pi;

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

   function Dist (A, B : Point) return Real is
      D2 : constant Real := Dist2 (A, B);
   begin
      if D2 <= 0.0 then
         return 0.0;
      end if;
      return Real (Math.Sqrt (Float (D2)));
   end Dist;

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
   -- Quality / angles
   ---------------------------------------------------------------------------

   function Angle_Degrees_At (A, B, C : Point) return Real is
      --  Angle at B via atan2 / law of cosines on BA, BC.
      BAx : constant Real := A.X - B.X;
      BAy : constant Real := A.Y - B.Y;
      BCx : constant Real := C.X - B.X;
      BCy : constant Real := C.Y - B.Y;
      Len_BA : constant Real := Dist (A, B);
      Len_BC : constant Real := Dist (B, C);
      Dot, Cos_Val, Ang : Real;
   begin
      if Len_BA <= Epsilon or else Len_BC <= Epsilon then
         return 0.0;
      end if;
      Dot := BAx * BCx + BAy * BCy;
      Cos_Val := Dot / (Len_BA * Len_BC);
      if Cos_Val > 1.0 then
         Cos_Val := 1.0;
      elsif Cos_Val < -1.0 then
         Cos_Val := -1.0;
      end if;
      Ang := Real (Math.Arccos (Float (Cos_Val))) * Rad_To_Deg;
      if Ang < 0.0 then
         return 0.0;
      elsif Ang > 180.0 then
         return 180.0;
      end if;
      return Ang;
   end Angle_Degrees_At;

   function Triangle_Min_Angle_Degrees (A, B, C : Point) return Real is
      A_At_A : constant Real :=
        Angle_Degrees_At (A => B, B => A, C => C);
      A_At_B : constant Real :=
        Angle_Degrees_At (A => A, B => B, C => C);
      A_At_C : constant Real :=
        Angle_Degrees_At (A => A, B => C, C => B);
      M : Real := A_At_A;
   begin
      if A_At_B < M then
         M := A_At_B;
      end if;
      if A_At_C < M then
         M := A_At_C;
      end if;
      return M;
   end Triangle_Min_Angle_Degrees;

   function Is_Skinny
     (A, B, C : Point; Min_Angle_Degrees : Real) return Boolean
   is
   begin
      return Triangle_Min_Angle_Degrees (A, B, C) < Min_Angle_Degrees;
   end Is_Skinny;

   function Aspect_Ratio (A, B, C : Point) return Real is
      L_AB : constant Real := Dist (A, B);
      L_BC : constant Real := Dist (B, C);
      L_CA : constant Real := Dist (C, A);
      Longest, Shortest : Real;
   begin
      Longest := L_AB;
      if L_BC > Longest then
         Longest := L_BC;
      end if;
      if L_CA > Longest then
         Longest := L_CA;
      end if;
      Shortest := L_AB;
      if L_BC < Shortest then
         Shortest := L_BC;
      end if;
      if L_CA < Shortest then
         Shortest := L_CA;
      end if;
      if Shortest <= Epsilon then
         return Real'Last / 4.0;
      end if;
      return Longest / Shortest;
   end Aspect_Ratio;

   ---------------------------------------------------------------------------
   -- Encroachment
   ---------------------------------------------------------------------------

   function Encroaches_Segment
     (Seg_A, Seg_B, P : Point) return Boolean
   is
      Mid : constant Point :=
        (X => (Seg_A.X + Seg_B.X) / 2.0,
         Y => (Seg_A.Y + Seg_B.Y) / 2.0);
      R2  : constant Real := Dist2 (Seg_A, Mid);
   begin
      --  Strict open diametral disk: exclude endpoints.
      if Near_Point (P, Seg_A) or else Near_Point (P, Seg_B) then
         return False;
      end if;
      return Dist2 (P, Mid) < R2 - Epsilon;
   end Encroaches_Segment;

   function Point_Encroaches_Any_Segment
     (P        : Point;
      Points   : Point_Array;
      Segments : Segment_Array) return Boolean
   is
   begin
      for S of Segments loop
         if S.A in Points'Range and then S.B in Points'Range then
            if Encroaches_Segment (Points (S.A), Points (S.B), P) then
               return True;
            end if;
         end if;
      end loop;
      return False;
   end Point_Encroaches_Any_Segment;

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
   -- Internal Delaunay helpers
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
           with "triangle buffer exceeded during Delaunay / refine";
      end if;
      Mesh.Count := Mesh.Count + 1;
      Mesh.Tris (Mesh.Count) := Tri;
   end Append_Triangle;

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

   procedure Insert_Point
     (Work  : Point_Array;
      Mesh  : in out Triangulation;
      P_Idx : Point_Index)
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

   function Mesh_Min_Angle_Degrees
     (Points : Point_Array; T : Triangulation) return Real
   is
      N : constant Natural := Points'Length;
      Local : Point_Array (1 .. Max_Points);
      K : Point_Index := 1;
      Min_A : Real := 180.0;
   begin
      if T.Count = 0 or else N = 0 then
         return 180.0;
      end if;
      for I in Points'Range loop
         Local (K) := Points (I);
         K := K + 1;
      end loop;

      for Ti in 1 .. T.Count loop
         declare
            Tri : constant Triangle := T.Tris (Ti);
            Ang : constant Real :=
              Triangle_Min_Angle_Degrees
                (Local (Tri.A), Local (Tri.B), Local (Tri.C));
         begin
            if Ang < Min_A then
               Min_A := Ang;
            end if;
         end;
      end loop;
      return Min_A;
   end Mesh_Min_Angle_Degrees;

   function Count_Skinny
     (Points : Point_Array;
      T      : Triangulation;
      Min_Angle_Degrees : Real) return Natural
   is
      N : constant Natural := Points'Length;
      Local : Point_Array (1 .. Max_Points);
      K : Point_Index := 1;
      Cnt : Natural := 0;
   begin
      if T.Count = 0 or else N = 0 then
         return 0;
      end if;
      for I in Points'Range loop
         Local (K) := Points (I);
         K := K + 1;
      end loop;

      for Ti in 1 .. T.Count loop
         declare
            Tri : constant Triangle := T.Tris (Ti);
         begin
            if Is_Skinny
              (Local (Tri.A), Local (Tri.B), Local (Tri.C),
               Min_Angle_Degrees)
            then
               Cnt := Cnt + 1;
            end if;
         end;
      end loop;
      return Cnt;
   end Count_Skinny;

   ---------------------------------------------------------------------------
   -- Refine helpers
   ---------------------------------------------------------------------------

   procedure Validate_Angle_Bound (Min_Angle_Degrees : Real) is
   begin
      if Min_Angle_Degrees <= 0.0 or else Min_Angle_Degrees >= 60.0 then
         raise Invalid_Argument
           with "Min_Angle_Degrees must be in (0, 60)";
      end if;
   end Validate_Angle_Bound;

   function Point_Near_Existing
     (Work : Point_Array; N : Point_Count; P : Point) return Boolean
   is
   begin
      for I in 1 .. Point_Index (N) loop
         if Near_Point (Work (I), P, 1.0E-8) then
            return True;
         end if;
      end loop;
      return False;
   end Point_Near_Existing;

   function Inside_Expanded_Box
     (Box : Bounding_Box; P : Point; Margin : Real) return Boolean
   is
   begin
      return P.X >= Box.Min_X - Margin
        and then P.X <= Box.Max_X + Margin
        and then P.Y >= Box.Min_Y - Margin
        and then P.Y <= Box.Max_Y + Margin;
   end Inside_Expanded_Box;

   function Find_Skinny_Triangle
     (Work : Point_Array;
      N    : Point_Count;
      Mesh : Triangulation;
      Min_Angle_Degrees : Real;
      Found : out Boolean;
      Tri_Out : out Triangle) return Boolean
   is
      Worst_Ang : Real := Min_Angle_Degrees;
      Have : Boolean := False;
      Best : Triangle := (A => 1, B => 1, C => 1);
   begin
      Found := False;
      Tri_Out := Best;
      for Ti in 1 .. Mesh.Count loop
         declare
            Tri : constant Triangle := Mesh.Tris (Ti);
            Ang : constant Real :=
              Triangle_Min_Angle_Degrees
                (Work (Tri.A), Work (Tri.B), Work (Tri.C));
         begin
            if Ang < Worst_Ang
              and then Tri.A <= Point_Index (N)
              and then Tri.B <= Point_Index (N)
              and then Tri.C <= Point_Index (N)
            then
               Worst_Ang := Ang;
               Best := Tri;
               Have := True;
            end if;
         end;
      end loop;
      Found := Have;
      Tri_Out := Best;
      return Have;
   end Find_Skinny_Triangle;

   function Find_Encroached_Segment
     (Work     : Point_Array;
      N        : Point_Count;
      Segs     : in out Segment_Array;
      Seg_N    : Segment_Count;
      Found    : out Boolean;
      Seg_Idx  : out Segment_Index) return Boolean
   is
   begin
      Found := False;
      Seg_Idx := 1;
      for Si in 1 .. Seg_N loop
         declare
            S : constant Segment := Segs (Si);
         begin
            if S.A <= Point_Index (N) and then S.B <= Point_Index (N) then
               for Pi in 1 .. Point_Index (N) loop
                  if Pi /= S.A and then Pi /= S.B then
                     if Encroaches_Segment
                       (Work (S.A), Work (S.B), Work (Pi))
                     then
                        Found := True;
                        Seg_Idx := Si;
                        return True;
                     end if;
                  end if;
               end loop;
            end if;
         end;
      end loop;
      return False;
   end Find_Encroached_Segment;

   procedure Split_Segment_At_Midpoint
     (Work   : in out Point_Array;
      N      : in out Point_Count;
      Segs   : in out Segment_Array;
      Seg_N  : in out Segment_Count;
      Seg_Idx : Segment_Index;
      New_Idx : out Point_Index)
   is
      S : constant Segment := Segs (Seg_Idx);
      Mid : Point;
      Old_B : constant Point_Index := S.B;
   begin
      if N = Max_Points then
         raise Capacity_Exceeded with "Max_Points reached during split";
      end if;
      Mid :=
        (X => (Work (S.A).X + Work (S.B).X) / 2.0,
         Y => (Work (S.A).Y + Work (S.B).Y) / 2.0);
      N := N + 1;
      New_Idx := Point_Index (N);
      Work (New_Idx) := Mid;
      --  Replace Seg_Idx with A--Mid; append Mid--Old_B.
      Segs (Seg_Idx) := (A => S.A, B => New_Idx);
      if Seg_N = Max_Segments then
         raise Capacity_Exceeded with "Max_Segments reached during split";
      end if;
      Seg_N := Seg_N + 1;
      Segs (Seg_N) := (A => New_Idx, B => Old_B);
   end Split_Segment_At_Midpoint;

   function Slice_Points
     (Work : Point_Array; N : Point_Count) return Point_Array
   is
      Pts : Point_Array (1 .. Point_Index (N));
   begin
      for I in 1 .. Point_Index (N) loop
         Pts (I) := Work (I);
      end loop;
      return Pts;
   end Slice_Points;

   function Build_Result
     (Work : Point_Array;
      N    : Point_Count;
      Mesh : Triangulation;
      Steiner : Natural) return Refine_Result
   is
      R : Refine_Result;
      Pts : constant Point_Array := Slice_Points (Work, N);
   begin
      R.Num_Points := N;
      for I in 1 .. Point_Index (N) loop
         R.Points (I) := Work (I);
      end loop;
      R.Mesh := Mesh;
      R.Steiner_Inserted := Steiner;
      R.Min_Angle_Achieved := Mesh_Min_Angle_Degrees (Pts, Mesh);
      return R;
   end Build_Result;

   function Circumcenter_Encroaches
     (C        : Point;
      Work     : Point_Array;
      Segs     : Segment_Array;
      Seg_N    : Segment_Count;
      Enc_Idx  : out Segment_Index) return Boolean
   is
   begin
      Enc_Idx := 1;
      for Si in 1 .. Seg_N loop
         declare
            S : constant Segment := Segs (Si);
         begin
            if Encroaches_Segment (Work (S.A), Work (S.B), C) then
               Enc_Idx := Si;
               return True;
            end if;
         end;
      end loop;
      return False;
   end Circumcenter_Encroaches;

   function Refine_Core
     (Points            : Point_Array;
      Segments_In       : Segment_Array;
      Use_Segments      : Boolean;
      Min_Angle_Degrees : Real;
      Max_Steiner       : Natural) return Refine_Result
   is
      N0 : constant Natural := Points'Length;
      Work : Point_Array (1 .. Max_Points + 3);
      N : Point_Count;
      Segs : Segment_Array (1 .. Max_Segments);
      Seg_N : Segment_Count := 0;
      Mesh : Triangulation;
      Steiner : Natural := 0;
      Box : Bounding_Box;
      Margin : Real;
      Found_Skinny, Found_Enc : Boolean;
      Skinny_Tri : Triangle;
      Enc_Idx : Segment_Index;
      New_Idx : Point_Index;
      Candidate : Point;
      Progress : Boolean;
   begin
      Validate_Angle_Bound (Min_Angle_Degrees);

      if N0 < 3 then
         raise Invalid_Argument
           with "Refine requires at least 3 points";
      end if;
      if N0 > Max_Points then
         raise Invalid_Argument
           with "Refine: more than Max_Points sites";
      end if;
      if Has_Near_Duplicate (Points) then
         raise Invalid_Argument
           with "Refine: near-duplicate sites detected";
      end if;

      N := Point_Count (N0);
      for I in Points'Range loop
         Work (Point_Index (Natural (I - Points'First) + 1)) := Points (I);
      end loop;

      if Use_Segments then
         for S of Segments_In loop
            if Natural (S.A) > N0 or else Natural (S.B) > N0 then
               raise Invalid_Argument
                 with "Refine: segment index out of range";
            end if;
            if S.A = S.B then
               raise Invalid_Argument
                 with "Refine: segment endpoints must differ";
            end if;
            if Seg_N = Max_Segments then
               raise Capacity_Exceeded with "too many input segments";
            end if;
            Seg_N := Seg_N + 1;
            Segs (Seg_N) := S;
         end loop;
      end if;

      Mesh := Triangulate (Slice_Points (Work, N));
      Box := Bounds_Of (Slice_Points (Work, N));
      declare
         DX : constant Real := Box.Max_X - Box.Min_X;
         DY : constant Real := Box.Max_Y - Box.Min_Y;
         Sp : Real := DX;
      begin
         if DY > Sp then
            Sp := DY;
         end if;
         if Sp < 1.0 then
            Sp := 1.0;
         end if;
         Margin := 0.05 * Sp;
      end;

      while Steiner < Max_Steiner and then N < Max_Points loop
         Progress := False;

         --  Prefer splitting encroached constrained segments.
         if Use_Segments and then Seg_N > 0 then
            if Find_Encroached_Segment
              (Work, N, Segs, Seg_N, Found_Enc, Enc_Idx)
            then
               Split_Segment_At_Midpoint
                 (Work, N, Segs, Seg_N, Enc_Idx, New_Idx);
               Steiner := Steiner + 1;
               Mesh := Triangulate (Slice_Points (Work, N));
               Progress := True;
            end if;
         end if;

         if not Progress then
            if Find_Skinny_Triangle
              (Work, N, Mesh, Min_Angle_Degrees, Found_Skinny, Skinny_Tri)
            then
               Candidate := Circumcenter
                 (Work (Skinny_Tri.A),
                  Work (Skinny_Tri.B),
                  Work (Skinny_Tri.C));

               if Use_Segments and then Seg_N > 0
                 and then Circumcenter_Encroaches
                   (Candidate, Work, Segs, Seg_N, Enc_Idx)
               then
                  Split_Segment_At_Midpoint
                    (Work, N, Segs, Seg_N, Enc_Idx, New_Idx);
                  Steiner := Steiner + 1;
                  Mesh := Triangulate (Slice_Points (Work, N));
                  Progress := True;
               elsif Inside_Expanded_Box (Box, Candidate, Margin)
                 and then not Point_Near_Existing (Work, N, Candidate)
               then
                  N := N + 1;
                  Work (Point_Index (N)) := Candidate;
                  Steiner := Steiner + 1;
                  Mesh := Triangulate (Slice_Points (Work, N));
                  Progress := True;
               else
                  --  Cannot insert this circumcenter; stop educational loop.
                  exit;
               end if;
            else
               exit;  --  no skinny triangles
            end if;
         end if;

         if not Progress then
            exit;
         end if;
      end loop;

      return Build_Result (Work, N, Mesh, Steiner);
   end Refine_Core;

   function Refine
     (Points            : Point_Array;
      Min_Angle_Degrees : Real;
      Max_Steiner       : Natural := Max_Steiner_Default)
      return Refine_Result
   is
      Empty : Segment_Array (1 .. 0);
   begin
      return Refine_Core
        (Points, Empty, False, Min_Angle_Degrees, Max_Steiner);
   end Refine;

   function Refine_With_Segments
     (Points            : Point_Array;
      Segments          : Segment_Array;
      Min_Angle_Degrees : Real;
      Max_Steiner       : Natural := Max_Steiner_Default)
      return Refine_Result
   is
   begin
      return Refine_Core
        (Points, Segments, True, Min_Angle_Degrees, Max_Steiner);
   end Refine_With_Segments;

   function Get_Point
     (R : Refine_Result; Index : Point_Index) return Point
   is
   begin
      return R.Points (Index);
   end Get_Point;

   function Result_Point_Count (R : Refine_Result) return Point_Count is
   begin
      return R.Num_Points;
   end Result_Point_Count;

end Rupperts_Algorithm;
