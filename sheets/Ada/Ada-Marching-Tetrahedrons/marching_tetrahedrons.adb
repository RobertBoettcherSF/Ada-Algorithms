--  Marching_Tetrahedrons body — cube→tet split, case table, edge
--  interpolation, cell/grid marching, normals and mesh helpers.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Marching_Tetrahedrons
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Internal helpers
   -------------------------------------------------------------------------

   function Sqrt_Safe (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      else
         return Real (Sqrt (Float (X)));
      end if;
   end Sqrt_Safe;

   --  Endpoints of the six local tetra edges among vertices 0..3.
   type Edge_Ends is array (0 .. 1) of Natural range 0 .. 3;
   type Edge_Table is array (Tetra_Edge) of Edge_Ends;

   Tetra_Edge_Verts : constant Edge_Table :=
     [0 => [0, 1],
      1 => [1, 2],
      2 => [2, 0],
      3 => [0, 3],
      4 => [1, 3],
      5 => [2, 3]];

   --  Triangle lists as local edge indices; -1 terminates a strip slot.
   type Case_Edges is array (1 .. 7) of Integer;

   function Edge_List_For (C : Case_Index) return Case_Edges is
   begin
      case C is
         when 0 | 15 =>
            return [-1, -1, -1, -1, -1, -1, -1];
         when 1 =>
            return [0, 3, 2, -1, -1, -1, -1];
         when 2 =>
            return [0, 1, 4, -1, -1, -1, -1];
         when 3 =>
            return [1, 4, 2, 2, 4, 3, -1];
         when 4 =>
            return [1, 2, 5, -1, -1, -1, -1];
         when 5 =>
            return [0, 3, 5, 0, 5, 1, -1];
         when 6 =>
            return [0, 2, 5, 0, 5, 4, -1];
         when 7 =>
            return [3, 5, 4, -1, -1, -1, -1];
         when 8 =>
            return [3, 4, 5, -1, -1, -1, -1];
         when 9 =>
            return [0, 4, 5, 0, 5, 2, -1];
         when 10 =>
            return [0, 1, 5, 0, 5, 3, -1];
         when 11 =>
            return [1, 5, 2, -1, -1, -1, -1];
         when 12 =>
            return [2, 3, 4, 2, 4, 1, -1];
         when 13 =>
            return [0, 4, 1, -1, -1, -1, -1];
         when 14 =>
            return [0, 2, 3, -1, -1, -1, -1];
      end case;
   end Edge_List_For;

   type Corner_Points is array (Cube_Corner) of Point3;
   type Corner_Scalars is array (Cube_Corner) of Real;

   -------------------------------------------------------------------------
   -- Vector helpers
   -------------------------------------------------------------------------

   function Length (V : Vec3) return Non_Negative is
      S : constant Real := V.X * V.X + V.Y * V.Y + V.Z * V.Z;
   begin
      return Non_Negative (Sqrt_Safe (S));
   end Length;

   function Normalize (V : Vec3) return Normal3 is
      L : constant Non_Negative := Length (V);
   begin
      if L = 0.0 then
         raise Degenerate_Geometry with "Normalize of zero vector";
      end if;
      return (V.X / L, V.Y / L, V.Z / L);
   end Normalize;

   function Dot (A, B : Vec3) return Real is
   begin
      return A.X * B.X + A.Y * B.Y + A.Z * B.Z;
   end Dot;

   function Cross (A, B : Vec3) return Vec3 is
   begin
      return
        (A.Y * B.Z - A.Z * B.Y,
         A.Z * B.X - A.X * B.Z,
         A.X * B.Y - A.Y * B.X);
   end Cross;

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

   function Clamp (X, Lo, Hi : Real) return Real is
   begin
      if X < Lo then
         return Lo;
      elsif X > Hi then
         return Hi;
      else
         return X;
      end if;
   end Clamp;

   function Distance_Between (A, B : Vec3) return Non_Negative is
   begin
      return Length (A - B);
   end Distance_Between;

   function Cube_Corner_Offset (C : Cube_Corner) return Vec3 is
   begin
      case C is
         when 0 => return (0.0, 0.0, 0.0);
         when 1 => return (1.0, 0.0, 0.0);
         when 2 => return (1.0, 1.0, 0.0);
         when 3 => return (0.0, 1.0, 0.0);
         when 4 => return (0.0, 0.0, 1.0);
         when 5 => return (1.0, 0.0, 1.0);
         when 6 => return (1.0, 1.0, 1.0);
         when 7 => return (0.0, 1.0, 1.0);
      end case;
   end Cube_Corner_Offset;

   -------------------------------------------------------------------------
   -- 1. Split_Cube_Into_Tetrahedra
   -------------------------------------------------------------------------

   function Split_Cube_Into_Tetrahedra return Tetrahedra_Six is
   begin
      --  Main diagonal 0–6; six irregular tetrahedra (Wikipedia / Doi–Koide).
      return
        [1 => (Corners => [0, 5, 1, 6]),
         2 => (Corners => [0, 1, 2, 6]),
         3 => (Corners => [0, 2, 3, 6]),
         4 => (Corners => [0, 3, 7, 6]),
         5 => (Corners => [0, 7, 4, 6]),
         6 => (Corners => [0, 4, 5, 6])];
   end Split_Cube_Into_Tetrahedra;

   -------------------------------------------------------------------------
   -- 2. Tetra_Case_Index
   -------------------------------------------------------------------------

   function Tetra_Case_Index
     (S0, S1, S2, S3 : Real;
      Isolevel       : Real) return Case_Index
   is
      Idx : Natural := 0;
   begin
      if S0 < Isolevel then
         Idx := Idx + 1;
      end if;
      if S1 < Isolevel then
         Idx := Idx + 2;
      end if;
      if S2 < Isolevel then
         Idx := Idx + 4;
      end if;
      if S3 < Isolevel then
         Idx := Idx + 8;
      end if;
      return Case_Index (Idx);
   end Tetra_Case_Index;

   -------------------------------------------------------------------------
   -- 3. Interpolate_Edge_Vertex
   -------------------------------------------------------------------------

   function Interpolate_Edge_Vertex
     (P0, P1 : Point3;
      V0, V1 : Real;
      Isolevel : Real) return Point3
   is
      Denom : constant Real := V1 - V0;
      T     : Real;
   begin
      if abs (Denom) < 1.0E-12 then
         raise Degenerate_Geometry
           with "Interpolate_Edge_Vertex: equal endpoint scalars";
      end if;
      T := Clamp ((Isolevel - V0) / Denom, 0.0, 1.0);
      return P0 + (T * (P1 - P0));
   end Interpolate_Edge_Vertex;

   procedure Interpolate_Edge_Vertex
     (P0, P1 : Point3;
      V0, V1 : Real;
      G0, G1 : Vec3;
      Isolevel : Real;
      Position : out Point3;
      Gradient : out Vec3)
   is
      Denom : constant Real := V1 - V0;
      T     : Real;
   begin
      if abs (Denom) < 1.0E-12 then
         raise Degenerate_Geometry
           with "Interpolate_Edge_Vertex: equal endpoint scalars";
      end if;
      T := Clamp ((Isolevel - V0) / Denom, 0.0, 1.0);
      Position := P0 + (T * (P1 - P0));
      Gradient := G0 + (T * (G1 - G0));
   end Interpolate_Edge_Vertex;

   -------------------------------------------------------------------------
   -- 7. Face_Normal / Estimate_Normal  (needed by triangulate)
   -------------------------------------------------------------------------

   function Face_Normal (T : Triangle) return Normal3 is
      N : constant Vec3 := Cross (T.B - T.A, T.C - T.A);
      L : constant Non_Negative := Length (N);
   begin
      if L < 1.0E-12 then
         raise Degenerate_Geometry with "Face_Normal of degenerate triangle";
      end if;
      return Normalize (N);
   end Face_Normal;

   function Estimate_Normal
     (P0, P1, P2, P3 : Point3;
      S0, S1, S2, S3 : Real) return Normal3
   is
      C : constant Point3 :=
        0.25 * (P0 + (P1 + (P2 + P3)));
      G : Vec3 := (0.0, 0.0, 0.0);
      D : Vec3;
      L : Non_Negative;
   begin
      D := P0 - C;
      L := Length (D);
      if L > 0.0 then
         G := G + ((S0 / L) * D);
      end if;
      D := P1 - C;
      L := Length (D);
      if L > 0.0 then
         G := G + ((S1 / L) * D);
      end if;
      D := P2 - C;
      L := Length (D);
      if L > 0.0 then
         G := G + ((S2 / L) * D);
      end if;
      D := P3 - C;
      L := Length (D);
      if L > 0.0 then
         G := G + ((S3 / L) * D);
      end if;
      if Length (G) < 1.0E-12 then
         return (0.0, 0.0, 1.0);
      end if;
      return Normalize (G);
   end Estimate_Normal;

   -------------------------------------------------------------------------
   -- Mesh helpers
   -------------------------------------------------------------------------

   function Empty_Mesh return Mesh is
      M : Mesh;
   begin
      M.Count := 0;
      return M;
   end Empty_Mesh;

   procedure Append_Triangle (M : in out Mesh; T : Triangle) is
   begin
      if M.Count = Max_Triangles then
         raise Mesh_Capacity with "Mesh triangle capacity exceeded";
      end if;
      M.Count := M.Count + 1;
      M.Tris (M.Count) := T;
   end Append_Triangle;

   function Count_Triangles (M : Mesh) return Natural is
   begin
      return Natural (M.Count);
   end Count_Triangles;

   function Compute_Mesh_Stats (M : Mesh) return Mesh_Stats is
      S     : Mesh_Stats;
      First : Boolean := True;

      procedure Acc (P : Point3) is
      begin
         if First then
            S.Min_Corner := P;
            S.Max_Corner := P;
            First := False;
         else
            if P.X < S.Min_Corner.X then
               S.Min_Corner.X := P.X;
            end if;
            if P.Y < S.Min_Corner.Y then
               S.Min_Corner.Y := P.Y;
            end if;
            if P.Z < S.Min_Corner.Z then
               S.Min_Corner.Z := P.Z;
            end if;
            if P.X > S.Max_Corner.X then
               S.Max_Corner.X := P.X;
            end if;
            if P.Y > S.Max_Corner.Y then
               S.Max_Corner.Y := P.Y;
            end if;
            if P.Z > S.Max_Corner.Z then
               S.Max_Corner.Z := P.Z;
            end if;
         end if;
      end Acc;
   begin
      S.Triangle_Count := Natural (M.Count);
      S.Vertex_Slots   := Natural (M.Count) * 3;
      for I in 1 .. M.Count loop
         Acc (M.Tris (I).A);
         Acc (M.Tris (I).B);
         Acc (M.Tris (I).C);
      end loop;
      return S;
   end Compute_Mesh_Stats;

   -------------------------------------------------------------------------
   -- 4. Triangulate_Tetrahedron
   -------------------------------------------------------------------------

   procedure Triangulate_Tetrahedron
     (P0, P1, P2, P3 : Point3;
      S0, S1, S2, S3 : Real;
      Isolevel       : Real;
      Out_Tris       : out Small_Triangle_List;
      Out_Count      : out Natural)
   is
      Case_Id : constant Case_Index :=
        Tetra_Case_Index (S0, S1, S2, S3, Isolevel);
      Edges   : constant Case_Edges := Edge_List_For (Case_Id);
      Pos     : constant array (0 .. 3) of Point3 := [P0, P1, P2, P3];
      Scl     : constant array (0 .. 3) of Real := [S0, S1, S2, S3];
      Vert    : array (Tetra_Edge) of Point3;
      Edge_Ok : array (Tetra_Edge) of Boolean := [others => False];
      I       : Positive := 1;
      E0, E1, E2 : Integer;
      Va, Vb  : Natural;
      Grad    : constant Normal3 :=
        Estimate_Normal (P0, P1, P2, P3, S0, S1, S2, S3);
      Need    : Boolean;
   begin
      Out_Count := 0;
      Out_Tris := [others => (A => (0.0, 0.0, 0.0), B => (0.0, 0.0, 0.0),
                               C => (0.0, 0.0, 0.0),
                               NA => (0.0, 0.0, 0.0), NB => (0.0, 0.0, 0.0),
                               NC => (0.0, 0.0, 0.0))];

      if Case_Id = 0 or else Case_Id = 15 then
         return;
      end if;

      for E in Tetra_Edge loop
         Need := False;
         for K in Edges'Range loop
            if Edges (K) = E then
               Need := True;
               exit;
            end if;
         end loop;
         if Need then
            Va := Tetra_Edge_Verts (E) (0);
            Vb := Tetra_Edge_Verts (E) (1);
            Vert (E) := Interpolate_Edge_Vertex
              (Pos (Va), Pos (Vb), Scl (Va), Scl (Vb), Isolevel);
            Edge_Ok (E) := True;
         end if;
      end loop;

      while I <= 6 and then Edges (I) >= 0 loop
         E0 := Edges (I);
         E1 := Edges (I + 1);
         E2 := Edges (I + 2);
         if E0 < 0 or else E1 < 0 or else E2 < 0 then
            exit;
         end if;
         if not (Edge_Ok (Tetra_Edge (E0))
                   and then Edge_Ok (Tetra_Edge (E1))
                   and then Edge_Ok (Tetra_Edge (E2)))
         then
            raise Degenerate_Geometry
              with "Triangulate_Tetrahedron: missing edge vertex";
         end if;
         Out_Count := Out_Count + 1;
         Out_Tris (Out_Count) :=
           (A  => Vert (Tetra_Edge (E0)),
            B  => Vert (Tetra_Edge (E1)),
            C  => Vert (Tetra_Edge (E2)),
            NA => Grad,
            NB => Grad,
            NC => Grad);
         I := I + 3;
      end loop;
   end Triangulate_Tetrahedron;

   -------------------------------------------------------------------------
   -- Corner gather helpers for one cell
   -------------------------------------------------------------------------

   procedure Cell_Corners
     (Corner_Pos : Position_Field;
      Corner_Val : Scalar_Field;
      I_Cell, J_Cell, K_Cell : Natural;
      Pos : out Corner_Points;
      Val : out Corner_Scalars)
   is
      I : constant Natural := I_Cell;
      J : constant Natural := J_Cell;
      K : constant Natural := K_Cell;
   begin
      Pos (0) := Corner_Pos (I,     J,     K);
      Pos (1) := Corner_Pos (I + 1, J,     K);
      Pos (2) := Corner_Pos (I + 1, J + 1, K);
      Pos (3) := Corner_Pos (I,     J + 1, K);
      Pos (4) := Corner_Pos (I,     J,     K + 1);
      Pos (5) := Corner_Pos (I + 1, J,     K + 1);
      Pos (6) := Corner_Pos (I + 1, J + 1, K + 1);
      Pos (7) := Corner_Pos (I,     J + 1, K + 1);

      Val (0) := Corner_Val (I,     J,     K);
      Val (1) := Corner_Val (I + 1, J,     K);
      Val (2) := Corner_Val (I + 1, J + 1, K);
      Val (3) := Corner_Val (I,     J + 1, K);
      Val (4) := Corner_Val (I,     J,     K + 1);
      Val (5) := Corner_Val (I + 1, J,     K + 1);
      Val (6) := Corner_Val (I + 1, J + 1, K + 1);
      Val (7) := Corner_Val (I,     J + 1, K + 1);
   end Cell_Corners;

   -------------------------------------------------------------------------
   -- 5. March_Single_Cube
   -------------------------------------------------------------------------

   procedure March_Single_Cube
     (Corner_Pos : Position_Field;
      Corner_Val : Scalar_Field;
      I_Cell, J_Cell, K_Cell : Natural;
      Isolevel   : Real;
      Acc        : in out Mesh)
   is
      Tets       : constant Tetrahedra_Six := Split_Cube_Into_Tetrahedra;
      Pos        : Corner_Points;
      Val        : Corner_Scalars;
      Local_Tris : Small_Triangle_List;
      N          : Natural;
      C0, C1, C2, C3 : Cube_Corner;
   begin
      Cell_Corners
        (Corner_Pos, Corner_Val, I_Cell, J_Cell, K_Cell, Pos, Val);

      for T in Tets'Range loop
         C0 := Tets (T).Corners (0);
         C1 := Tets (T).Corners (1);
         C2 := Tets (T).Corners (2);
         C3 := Tets (T).Corners (3);
         Triangulate_Tetrahedron
           (Pos (C0), Pos (C1), Pos (C2), Pos (C3),
            Val (C0), Val (C1), Val (C2), Val (C3),
            Isolevel, Local_Tris, N);
         for K in 1 .. N loop
            Append_Triangle (Acc, Local_Tris (K));
         end loop;
      end loop;
   end March_Single_Cube;

   -------------------------------------------------------------------------
   -- 6. March_Grid
   -------------------------------------------------------------------------

   function March_Grid
     (Values    : Scalar_Field;
      Positions : Position_Field;
      Isolevel  : Real) return Mesh
   is
      Acc : Mesh := Empty_Mesh;
   begin
      if Values'Length (1) > Max_Grid_Dim
        or else Values'Length (2) > Max_Grid_Dim
        or else Values'Length (3) > Max_Grid_Dim
      then
         raise Invalid_Argument
           with "March_Grid: grid axis exceeds Max_Grid_Dim";
      end if;

      for I in Values'First (1) .. Values'Last (1) - 1 loop
         for J in Values'First (2) .. Values'Last (2) - 1 loop
            for K in Values'First (3) .. Values'Last (3) - 1 loop
               March_Single_Cube
                 (Positions, Values, I, J, K, Isolevel, Acc);
            end loop;
         end loop;
      end loop;
      return Acc;
   end March_Grid;

   -------------------------------------------------------------------------
   -- Field fixtures
   -------------------------------------------------------------------------

   procedure Fill_Sphere_SDF
     (Values     : out Scalar_Field;
      Positions  : out Position_Field;
      Origin     : Point3;
      Spacing    : Real;
      Center     : Point3;
      Radius     : Non_Negative)
   is
      P : Point3;
   begin
      if Spacing <= 0.0 then
         raise Invalid_Argument with "Fill_Sphere_SDF: Spacing must be > 0";
      end if;
      for I in Values'Range (1) loop
         for J in Values'Range (2) loop
            for K in Values'Range (3) loop
               P :=
                 (Origin.X + Real (I - Values'First (1)) * Spacing,
                  Origin.Y + Real (J - Values'First (2)) * Spacing,
                  Origin.Z + Real (K - Values'First (3)) * Spacing);
               Positions (I, J, K) := P;
               Values (I, J, K) := Distance_Between (P, Center) - Radius;
            end loop;
         end loop;
      end loop;
   end Fill_Sphere_SDF;

   procedure Fill_Plane_Field
     (Values       : out Scalar_Field;
      Positions    : out Position_Field;
      Origin       : Point3;
      Spacing      : Real;
      Plane_Point  : Point3;
      Plane_Normal : Normal3)
   is
      N : constant Normal3 := Normalize (Plane_Normal);
      P : Point3;
   begin
      if Spacing <= 0.0 then
         raise Invalid_Argument with "Fill_Plane_Field: Spacing must be > 0";
      end if;
      for I in Values'Range (1) loop
         for J in Values'Range (2) loop
            for K in Values'Range (3) loop
               P :=
                 (Origin.X + Real (I - Values'First (1)) * Spacing,
                  Origin.Y + Real (J - Values'First (2)) * Spacing,
                  Origin.Z + Real (K - Values'First (3)) * Spacing);
               Positions (I, J, K) := P;
               Values (I, J, K) := Dot (P - Plane_Point, N);
            end loop;
         end loop;
      end loop;
   end Fill_Plane_Field;

end Marching_Tetrahedrons;
