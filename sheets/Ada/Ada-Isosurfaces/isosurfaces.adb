--  Isosurfaces body — field sampling, classification, gradients, Surface
--  Nets / Dual Contouring lite extractors, marching-tetrahedra cell
--  wrapper, mesh helpers, fixtures, and level-set band collection.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Isosurfaces
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

   function Sin_F (X : Real) return Real is
   begin
      return Real (Sin (Float (X)));
   end Sin_F;

   function Cos_F (X : Real) return Real is
   begin
      return Real (Cos (Float (X)));
   end Cos_F;

   --  Cube edges 0..11 (classic MC / Bourke numbering).
   subtype Cube_Edge is Natural range 0 .. 11;
   type Edge_Ends is array (0 .. 1) of Cube_Corner;
   type Edge_Table is array (Cube_Edge) of Edge_Ends;

   Cube_Edge_Verts : constant Edge_Table :=
     [0 => [0, 1], 1 => [1, 2], 2 => [2, 3], 3 => [3, 0],
      4 => [4, 5], 5 => [5, 6], 6 => [6, 7], 7 => [7, 4],
      8 => [0, 4], 9 => [1, 5], 10 => [2, 6], 11 => [3, 7]];

   type Corner_Points is array (Cube_Corner) of Point3;
   type Corner_Scalars is array (Cube_Corner) of Real;

   function Edge_Crosses
     (V0, V1 : Real; Isolevel : Real) return Boolean
   is
   begin
      return (V0 < Isolevel) /= (V1 < Isolevel);
   end Edge_Crosses;

   function Interpolate_Edge
     (P0, P1 : Point3;
      V0, V1 : Real;
      Isolevel : Real) return Point3
   is
      Denom : constant Real := V1 - V0;
      T     : Real;
   begin
      if abs (Denom) < 1.0E-12 then
         return 0.5 * (P0 + P1);
      end if;
      T := Clamp ((Isolevel - V0) / Denom, 0.0, 1.0);
      return P0 + (T * (P1 - P0));
   end Interpolate_Edge;

   procedure Gather_Cell
     (Values    : Scalar_Grid3;
      Positions : Position_Grid3;
      I_Cell, J_Cell, K_Cell : Natural;
      Pos : out Corner_Points;
      Scl : out Corner_Scalars)
   is
      I : constant Natural := I_Cell;
      J : constant Natural := J_Cell;
      K : constant Natural := K_Cell;
   begin
      Pos (0) := Positions (I,     J,     K);
      Pos (1) := Positions (I + 1, J,     K);
      Pos (2) := Positions (I + 1, J + 1, K);
      Pos (3) := Positions (I,     J + 1, K);
      Pos (4) := Positions (I,     J,     K + 1);
      Pos (5) := Positions (I + 1, J,     K + 1);
      Pos (6) := Positions (I + 1, J + 1, K + 1);
      Pos (7) := Positions (I,     J + 1, K + 1);
      Scl (0) := Values (I,     J,     K);
      Scl (1) := Values (I + 1, J,     K);
      Scl (2) := Values (I + 1, J + 1, K);
      Scl (3) := Values (I,     J + 1, K);
      Scl (4) := Values (I,     J,     K + 1);
      Scl (5) := Values (I + 1, J,     K + 1);
      Scl (6) := Values (I + 1, J + 1, K + 1);
      Scl (7) := Values (I,     J + 1, K + 1);
   end Gather_Cell;

   function Cell_Is_Active
     (Scl : Corner_Scalars; Isolevel : Real) return Boolean
   is
      Below, Above : Boolean := False;
   begin
      for C in Cube_Corner loop
         if Scl (C) < Isolevel then
            Below := True;
         else
            Above := True;
         end if;
      end loop;
      return Below and then Above;
   end Cell_Is_Active;

   function Cell_Center (Pos : Corner_Points) return Point3 is
      Acc : Point3 := (0.0, 0.0, 0.0);
   begin
      for C in Cube_Corner loop
         Acc := Acc + Pos (C);
      end loop;
      return 0.125 * Acc;
   end Cell_Center;

   procedure Clamp_To_Cell
     (P : in out Point3; Pos : Corner_Points)
   is
      Lo, Hi : Point3;
   begin
      Lo := Pos (0);
      Hi := Pos (0);
      for C in Cube_Corner loop
         if Pos (C).X < Lo.X then Lo.X := Pos (C).X; end if;
         if Pos (C).Y < Lo.Y then Lo.Y := Pos (C).Y; end if;
         if Pos (C).Z < Lo.Z then Lo.Z := Pos (C).Z; end if;
         if Pos (C).X > Hi.X then Hi.X := Pos (C).X; end if;
         if Pos (C).Y > Hi.Y then Hi.Y := Pos (C).Y; end if;
         if Pos (C).Z > Hi.Z then Hi.Z := Pos (C).Z; end if;
      end loop;
      P.X := Clamp (P.X, Lo.X, Hi.X);
      P.Y := Clamp (P.Y, Lo.Y, Hi.Y);
      P.Z := Clamp (P.Z, Lo.Z, Hi.Z);
   end Clamp_To_Cell;

   --  Approximate gradient at a corner by central differences on the grid.
   function Corner_Gradient
     (Values    : Scalar_Grid3;
      Positions : Position_Grid3;
      I, J, K   : Natural) return Vec3
   is
   begin
      return Estimate_Gradient (Values, Positions, I, J, K);
   end Corner_Gradient;

   procedure Dual_Vertex_Surface_Nets
     (Pos      : Corner_Points;
      Scl      : Corner_Scalars;
      Isolevel : Real;
      Vertex   : out Point3;
      Normal   : out Normal3)
   is
      Acc   : Point3 := (0.0, 0.0, 0.0);
      Count : Natural := 0;
      A, B  : Cube_Corner;
      Hit   : Point3;
   begin
      for E in Cube_Edge loop
         A := Cube_Edge_Verts (E) (0);
         B := Cube_Edge_Verts (E) (1);
         if Edge_Crosses (Scl (A), Scl (B), Isolevel) then
            Hit := Interpolate_Edge
              (Pos (A), Pos (B), Scl (A), Scl (B), Isolevel);
            Acc := Acc + Hit;
            Count := Count + 1;
         end if;
      end loop;
      if Count = 0 then
         Vertex := Cell_Center (Pos);
         Normal := (0.0, 0.0, 1.0);
      else
         Vertex := (1.0 / Real (Count)) * Acc;
         Normal := (0.0, 0.0, 1.0);
      end if;
      Clamp_To_Cell (Vertex, Pos);
   end Dual_Vertex_Surface_Nets;

   procedure Dual_Vertex_DC_Lite
     (Values    : Scalar_Grid3;
      Positions : Position_Grid3;
      I_Cell, J_Cell, K_Cell : Natural;
      Pos       : Corner_Points;
      Scl       : Corner_Scalars;
      Isolevel  : Real;
      Vertex    : out Point3;
      Normal    : out Normal3)
   is
      Acc_P : Point3 := (0.0, 0.0, 0.0);
      Acc_N : Vec3 := (0.0, 0.0, 0.0);
      Count : Natural := 0;
      A, B  : Cube_Corner;
      Hit   : Point3;
      G0, G1, G : Vec3;
      Center : constant Point3 := Cell_Center (Pos);
      --  Corner grid indices relative to cell origin.
      CI : constant array (Cube_Corner) of Natural :=
        [I_Cell, I_Cell + 1, I_Cell + 1, I_Cell,
         I_Cell, I_Cell + 1, I_Cell + 1, I_Cell];
      CJ : constant array (Cube_Corner) of Natural :=
        [J_Cell, J_Cell, J_Cell + 1, J_Cell + 1,
         J_Cell, J_Cell, J_Cell + 1, J_Cell + 1];
      CK : constant array (Cube_Corner) of Natural :=
        [K_Cell, K_Cell, K_Cell, K_Cell,
         K_Cell + 1, K_Cell + 1, K_Cell + 1, K_Cell + 1];
      T : Real;
      L : Non_Negative;
   begin
      for E in Cube_Edge loop
         A := Cube_Edge_Verts (E) (0);
         B := Cube_Edge_Verts (E) (1);
         if Edge_Crosses (Scl (A), Scl (B), Isolevel) then
            Hit := Interpolate_Edge
              (Pos (A), Pos (B), Scl (A), Scl (B), Isolevel);
            G0 := Corner_Gradient (Values, Positions, CI (A), CJ (A), CK (A));
            G1 := Corner_Gradient (Values, Positions, CI (B), CJ (B), CK (B));
            if abs (Scl (B) - Scl (A)) < 1.0E-12 then
               T := 0.5;
            else
               T := Clamp
                 ((Isolevel - Scl (A)) / (Scl (B) - Scl (A)), 0.0, 1.0);
            end if;
            G := G0 + (T * (G1 - G0));
            Acc_P := Acc_P + Hit;
            Acc_N := Acc_N + G;
            Count := Count + 1;
         end if;
      end loop;
      if Count = 0 then
         Vertex := Center;
         Normal := (0.0, 0.0, 1.0);
         return;
      end if;
      Acc_P := (1.0 / Real (Count)) * Acc_P;
      Acc_N := (1.0 / Real (Count)) * Acc_N;
      L := Length (Acc_N);
      if L < 1.0E-12 then
         Normal := (0.0, 0.0, 1.0);
         Vertex := Acc_P;
      else
         Normal := Normalize (Acc_N);
         --  Project averaged intersection onto the line Center + t·N.
         Vertex := Center + (Dot (Acc_P - Center, Normal) * Normal);
      end if;
      Clamp_To_Cell (Vertex, Pos);
   end Dual_Vertex_DC_Lite;

   procedure Emit_Quad
     (M : in out Mesh;
      P0, P1, P2, P3 : Point3;
      N0, N1, N2, N3 : Normal3)
   is
   begin
      Append_Triangle
        (M, (A => P0, B => P1, C => P2,
             NA => N0, NB => N1, NC => N2));
      Append_Triangle
        (M, (A => P0, B => P2, C => P3,
             NA => N0, NB => N2, NC => N3));
   end Emit_Quad;

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
   -- 1. Evaluate_Field / Sample_Trilinear
   -------------------------------------------------------------------------

   function Evaluate_Field
     (Values : Scalar_Grid3;
      I, J, K : Natural) return Real
   is
   begin
      return Values (I, J, K);
   end Evaluate_Field;

   function Sample_Trilinear
     (Values    : Scalar_Grid3;
      Positions : Position_Grid3;
      P         : Point3) return Real
   is
      X0 : constant Real := Positions (Values'First (1),
                                       Values'First (2),
                                       Values'First (3)).X;
      Y0 : constant Real := Positions (Values'First (1),
                                       Values'First (2),
                                       Values'First (3)).Y;
      Z0 : constant Real := Positions (Values'First (1),
                                       Values'First (2),
                                       Values'First (3)).Z;
      X1 : constant Real := Positions (Values'Last (1),
                                       Values'First (2),
                                       Values'First (3)).X;
      Y1 : constant Real := Positions (Values'First (1),
                                       Values'Last (2),
                                       Values'First (3)).Y;
      Z1 : constant Real := Positions (Values'First (1),
                                       Values'First (2),
                                       Values'Last (3)).Z;
      NX : constant Natural := Values'Length (1);
      NY : constant Natural := Values'Length (2);
      NZ : constant Natural := Values'Length (3);
      DX : Real;
      DY : Real;
      DZ : Real;
      FX, FY, FZ : Real;
      I0, J0, K0 : Natural;
      I1, J1, K1 : Natural;
      TX, TY, TZ : Real;
      C000, C100, C010, C110, C001, C101, C011, C111 : Real;
      C00, C10, C01, C11, C0, C1 : Real;
   begin
      if P.X < X0 or else P.X > X1
        or else P.Y < Y0 or else P.Y > Y1
        or else P.Z < Z0 or else P.Z > Z1
      then
         raise Invalid_Argument
           with "Sample_Trilinear: point outside grid AABB";
      end if;
      if NX < 2 or else NY < 2 or else NZ < 2 then
         raise Invalid_Argument with "Sample_Trilinear: grid too small";
      end if;
      DX := (X1 - X0) / Real (NX - 1);
      DY := (Y1 - Y0) / Real (NY - 1);
      DZ := (Z1 - Z0) / Real (NZ - 1);
      if DX <= 0.0 or else DY <= 0.0 or else DZ <= 0.0 then
         raise Invalid_Argument with "Sample_Trilinear: non-positive spacing";
      end if;
      FX := (P.X - X0) / DX;
      FY := (P.Y - Y0) / DY;
      FZ := (P.Z - Z0) / DZ;
      I0 := Values'First (1) + Natural (Float'Floor (Float (FX)));
      J0 := Values'First (2) + Natural (Float'Floor (Float (FY)));
      K0 := Values'First (3) + Natural (Float'Floor (Float (FZ)));
      if I0 >= Values'Last (1) then
         I0 := Values'Last (1) - 1;
      end if;
      if J0 >= Values'Last (2) then
         J0 := Values'Last (2) - 1;
      end if;
      if K0 >= Values'Last (3) then
         K0 := Values'Last (3) - 1;
      end if;
      I1 := I0 + 1;
      J1 := J0 + 1;
      K1 := K0 + 1;
      TX := Clamp (FX - Real (I0 - Values'First (1)), 0.0, 1.0);
      TY := Clamp (FY - Real (J0 - Values'First (2)), 0.0, 1.0);
      TZ := Clamp (FZ - Real (K0 - Values'First (3)), 0.0, 1.0);
      C000 := Values (I0, J0, K0);
      C100 := Values (I1, J0, K0);
      C010 := Values (I0, J1, K0);
      C110 := Values (I1, J1, K0);
      C001 := Values (I0, J0, K1);
      C101 := Values (I1, J0, K1);
      C011 := Values (I0, J1, K1);
      C111 := Values (I1, J1, K1);
      C00 := C000 * (1.0 - TX) + C100 * TX;
      C10 := C010 * (1.0 - TX) + C110 * TX;
      C01 := C001 * (1.0 - TX) + C101 * TX;
      C11 := C011 * (1.0 - TX) + C111 * TX;
      C0 := C00 * (1.0 - TY) + C10 * TY;
      C1 := C01 * (1.0 - TY) + C11 * TY;
      return C0 * (1.0 - TZ) + C1 * TZ;
   end Sample_Trilinear;

   -------------------------------------------------------------------------
   -- 2. Is_Inside / Classify_Vertex
   -------------------------------------------------------------------------

   function Is_Inside
     (Value    : Real;
      Isolevel : Iso_Level) return Boolean
   is
   begin
      return Value < Real (Isolevel);
   end Is_Inside;

   function Classify_Vertex
     (Value     : Real;
      Isolevel  : Iso_Level;
      Tolerance : Non_Negative := 1.0E-5) return Vertex_Class
   is
   begin
      if abs (Value - Real (Isolevel)) <= Tolerance then
         return On_Surface;
      elsif Value < Real (Isolevel) then
         return Inside;
      else
         return Outside;
      end if;
   end Classify_Vertex;

   -------------------------------------------------------------------------
   -- 3. Estimate_Gradient / Estimate_Normal
   -------------------------------------------------------------------------

   function Estimate_Gradient
     (Values    : Scalar_Grid3;
      Positions : Position_Grid3;
      I, J, K   : Natural) return Vec3
   is
      G : Vec3 := (0.0, 0.0, 0.0);
      D : Real;
   begin
      if I > Values'First (1) and then I < Values'Last (1) then
         D := Positions (I + 1, J, K).X - Positions (I - 1, J, K).X;
         if abs (D) > 1.0E-12 then
            G.X := (Values (I + 1, J, K) - Values (I - 1, J, K)) / D;
         end if;
      elsif I < Values'Last (1) then
         D := Positions (I + 1, J, K).X - Positions (I, J, K).X;
         if abs (D) > 1.0E-12 then
            G.X := (Values (I + 1, J, K) - Values (I, J, K)) / D;
         end if;
      elsif I > Values'First (1) then
         D := Positions (I, J, K).X - Positions (I - 1, J, K).X;
         if abs (D) > 1.0E-12 then
            G.X := (Values (I, J, K) - Values (I - 1, J, K)) / D;
         end if;
      end if;

      if J > Values'First (2) and then J < Values'Last (2) then
         D := Positions (I, J + 1, K).Y - Positions (I, J - 1, K).Y;
         if abs (D) > 1.0E-12 then
            G.Y := (Values (I, J + 1, K) - Values (I, J - 1, K)) / D;
         end if;
      elsif J < Values'Last (2) then
         D := Positions (I, J + 1, K).Y - Positions (I, J, K).Y;
         if abs (D) > 1.0E-12 then
            G.Y := (Values (I, J + 1, K) - Values (I, J, K)) / D;
         end if;
      elsif J > Values'First (2) then
         D := Positions (I, J, K).Y - Positions (I, J - 1, K).Y;
         if abs (D) > 1.0E-12 then
            G.Y := (Values (I, J, K) - Values (I, J - 1, K)) / D;
         end if;
      end if;

      if K > Values'First (3) and then K < Values'Last (3) then
         D := Positions (I, J, K + 1).Z - Positions (I, J, K - 1).Z;
         if abs (D) > 1.0E-12 then
            G.Z := (Values (I, J, K + 1) - Values (I, J, K - 1)) / D;
         end if;
      elsif K < Values'Last (3) then
         D := Positions (I, J, K + 1).Z - Positions (I, J, K).Z;
         if abs (D) > 1.0E-12 then
            G.Z := (Values (I, J, K + 1) - Values (I, J, K)) / D;
         end if;
      elsif K > Values'First (3) then
         D := Positions (I, J, K).Z - Positions (I, J, K - 1).Z;
         if abs (D) > 1.0E-12 then
            G.Z := (Values (I, J, K) - Values (I, J, K - 1)) / D;
         end if;
      end if;
      return G;
   end Estimate_Gradient;

   function Estimate_Normal
     (Values    : Scalar_Grid3;
      Positions : Position_Grid3;
      I, J, K   : Natural) return Normal3
   is
      G : constant Vec3 := Estimate_Gradient (Values, Positions, I, J, K);
   begin
      if Length (G) < 1.0E-12 then
         return (0.0, 0.0, 1.0);
      end if;
      return Normalize (G);
   end Estimate_Normal;

   -------------------------------------------------------------------------
   -- Mesh helpers (early — used by extractors)
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

   function Face_Normal (T : Triangle) return Normal3 is
      N : constant Vec3 := Cross (T.B - T.A, T.C - T.A);
      L : constant Non_Negative := Length (N);
   begin
      if L < 1.0E-12 then
         raise Degenerate_Geometry with "Face_Normal of degenerate triangle";
      end if;
      return Normalize (N);
   end Face_Normal;

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
            if P.X < S.Min_Corner.X then S.Min_Corner.X := P.X; end if;
            if P.Y < S.Min_Corner.Y then S.Min_Corner.Y := P.Y; end if;
            if P.Z < S.Min_Corner.Z then S.Min_Corner.Z := P.Z; end if;
            if P.X > S.Max_Corner.X then S.Max_Corner.X := P.X; end if;
            if P.Y > S.Max_Corner.Y then S.Max_Corner.Y := P.Y; end if;
            if P.Z > S.Max_Corner.Z then S.Max_Corner.Z := P.Z; end if;
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

   procedure Append_Mesh (Dest : in out Mesh; Src : Mesh) is
   begin
      for I in 1 .. Src.Count loop
         Append_Triangle (Dest, Src.Tris (I));
      end loop;
   end Append_Mesh;

   function Merge_Meshes (A, B : Mesh) return Mesh is
      M : Mesh := Empty_Mesh;
   begin
      if Natural (A.Count) + Natural (B.Count) > Max_Triangles then
         raise Mesh_Capacity with "Merge_Meshes: capacity exceeded";
      end if;
      Append_Mesh (M, A);
      Append_Mesh (M, B);
      return M;
   end Merge_Meshes;

   -------------------------------------------------------------------------
   -- Shared dual-grid extraction (Surface Nets / DC lite)
   -------------------------------------------------------------------------

   type Dual_Mode is (Surface_Nets, Dual_Contouring);

   function Extract_Dual
     (Values    : Scalar_Grid3;
      Positions : Position_Grid3;
      Isolevel  : Iso_Level;
      Mode      : Dual_Mode) return Mesh
   is
      Iso : constant Real := Real (Isolevel);
      NI  : constant Natural := Values'Length (1) - 1;
      NJ  : constant Natural := Values'Length (2) - 1;
      NK  : constant Natural := Values'Length (3) - 1;
      --  Dual vertex per cell; indexed 0 .. NI-1 etc. relative to First.
      type Active_Arr is array (Natural range <>, Natural range <>,
                                Natural range <>) of Boolean;
      type Vert_Arr is array (Natural range <>, Natural range <>,
                              Natural range <>) of Point3;
      type Norm_Arr is array (Natural range <>, Natural range <>,
                              Natural range <>) of Normal3;
      Active : Active_Arr (0 .. NI - 1, 0 .. NJ - 1, 0 .. NK - 1) :=
        [others => [others => [others => False]]];
      Verts  : Vert_Arr (0 .. NI - 1, 0 .. NJ - 1, 0 .. NK - 1) :=
        [others => [others => [others => (0.0, 0.0, 0.0)]]];
      Norms  : Norm_Arr (0 .. NI - 1, 0 .. NJ - 1, 0 .. NK - 1) :=
        [others => [others => [others => (0.0, 0.0, 1.0)]]];
      M : Mesh := Empty_Mesh;
      Pos_A : Corner_Points;
      Scl_A : Corner_Scalars;
      I0 : constant Natural := Values'First (1);
      J0 : constant Natural := Values'First (2);
      K0 : constant Natural := Values'First (3);
      IC, JC, KC : Natural;
      V  : Point3;
      NN : Normal3;
   begin
      if Values'Length (1) > Max_Grid_Dim
        or else Values'Length (2) > Max_Grid_Dim
        or else Values'Length (3) > Max_Grid_Dim
      then
         raise Invalid_Argument with "Extract_Dual: grid exceeds Max_Grid_Dim";
      end if;

      for II in 0 .. NI - 1 loop
         for JJ in 0 .. NJ - 1 loop
            for KK in 0 .. NK - 1 loop
               IC := I0 + II;
               JC := J0 + JJ;
               KC := K0 + KK;
               Gather_Cell (Values, Positions, IC, JC, KC, Pos_A, Scl_A);
               if Cell_Is_Active (Scl_A, Iso) then
                  Active (II, JJ, KK) := True;
                  case Mode is
                     when Surface_Nets =>
                        Dual_Vertex_Surface_Nets
                          (Pos_A, Scl_A, Iso, V, NN);
                     when Dual_Contouring =>
                        Dual_Vertex_DC_Lite
                          (Values, Positions, IC, JC, KC,
                           Pos_A, Scl_A, Iso, V, NN);
                  end case;
                  Verts (II, JJ, KK) := V;
                  Norms (II, JJ, KK) := NN;
               end if;
            end loop;
         end loop;
      end loop;

      --  Edge-centric: for each primal grid edge that crosses the isolevel,
      --  the up-to-four dual cells around it form a quad.
      declare
         procedure Try_Edge_Quad
           (C0I, C0J, C0K : Natural;
            C1I, C1J, C1K : Natural;
            D0I, D0J, D0K : Integer;
            D1I, D1J, D1K : Integer;
            D2I, D2J, D2K : Integer;
            D3I, D3J, D3K : Integer)
         is
            function In_Dual (DI, DJ, DK : Integer) return Boolean is
            begin
               return DI >= 0 and then DJ >= 0 and then DK >= 0
                 and then DI <= Integer (NI - 1)
                 and then DJ <= Integer (NJ - 1)
                 and then DK <= Integer (NK - 1);
            end In_Dual;

            function Ok (DI, DJ, DK : Integer) return Boolean is
            begin
               return In_Dual (DI, DJ, DK)
                 and then Active (Natural (DI), Natural (DJ), Natural (DK));
            end Ok;

            V0, V1 : Real;
            P0, P1, P2, P3 : Point3;
            N0, N1, N2, N3 : Normal3;
         begin
            V0 := Values (C0I, C0J, C0K);
            V1 := Values (C1I, C1J, C1K);
            if not Edge_Crosses (V0, V1, Iso) then
               return;
            end if;
            if not (Ok (D0I, D0J, D0K) and then Ok (D1I, D1J, D1K)
                      and then Ok (D2I, D2J, D2K)
                      and then Ok (D3I, D3J, D3K))
            then
               return;
            end if;
            P0 := Verts (Natural (D0I), Natural (D0J), Natural (D0K));
            P1 := Verts (Natural (D1I), Natural (D1J), Natural (D1K));
            P2 := Verts (Natural (D2I), Natural (D2J), Natural (D2K));
            P3 := Verts (Natural (D3I), Natural (D3J), Natural (D3K));
            N0 := Norms (Natural (D0I), Natural (D0J), Natural (D0K));
            N1 := Norms (Natural (D1I), Natural (D1J), Natural (D1K));
            N2 := Norms (Natural (D2I), Natural (D2J), Natural (D2K));
            N3 := Norms (Natural (D3I), Natural (D3J), Natural (D3K));
            --  Orient so face normal roughly aligns with gradient at edge.
            declare
               G   : constant Vec3 :=
                 Estimate_Gradient
                   (Values, Positions,
                    C0I, C0J, C0K);
               FN  : constant Vec3 := Cross (P1 - P0, P2 - P0);
            begin
               if Dot (FN, G) >= 0.0 then
                  Emit_Quad
                    (M, P0, P1, P2, P3,
                     N0, N1, N2, N3);
               else
                  Emit_Quad
                    (M,
                     P0 => P0, P1 => P3, P2 => P2, P3 => P1,
                     N0 => N0, N1 => N3, N2 => N2, N3 => N1);
               end if;
            end;
         end Try_Edge_Quad;
      begin
         --  X-aligned primal edges (vary I; fixed J,K). Four dual cells:
         --  (i-1,j-1,k-1), (i,j-1,k-1), (i,j,k-1), (i-1,j,k-1) for edge
         --  at grid point chain — actually for edge between (i,j,k)-(i+1,j,k)
         --  the four cells are those that contain the edge:
         --  (i, j-1, k-1), (i, j, k-1), (i, j, k), (i, j-1, k).
         for I in I0 .. Values'Last (1) - 1 loop
            for J in J0 .. Values'Last (2) loop
               for K in K0 .. Values'Last (3) loop
                  Try_Edge_Quad
                    (I, J, K, I + 1, J, K,
                     Integer (I - I0), Integer (J - J0) - 1,
                     Integer (K - K0) - 1,
                     Integer (I - I0), Integer (J - J0),
                     Integer (K - K0) - 1,
                     Integer (I - I0), Integer (J - J0),
                     Integer (K - K0),
                     Integer (I - I0), Integer (J - J0) - 1,
                     Integer (K - K0));
               end loop;
            end loop;
         end loop;
         --  Y-aligned edges
         for I in I0 .. Values'Last (1) loop
            for J in J0 .. Values'Last (2) - 1 loop
               for K in K0 .. Values'Last (3) loop
                  Try_Edge_Quad
                    (I, J, K, I, J + 1, K,
                     Integer (I - I0) - 1, Integer (J - J0),
                     Integer (K - K0) - 1,
                     Integer (I - I0), Integer (J - J0),
                     Integer (K - K0) - 1,
                     Integer (I - I0), Integer (J - J0),
                     Integer (K - K0),
                     Integer (I - I0) - 1, Integer (J - J0),
                     Integer (K - K0));
               end loop;
            end loop;
         end loop;
         --  Z-aligned edges
         for I in I0 .. Values'Last (1) loop
            for J in J0 .. Values'Last (2) loop
               for K in K0 .. Values'Last (3) - 1 loop
                  Try_Edge_Quad
                    (I, J, K, I, J, K + 1,
                     Integer (I - I0) - 1, Integer (J - J0) - 1,
                     Integer (K - K0),
                     Integer (I - I0), Integer (J - J0) - 1,
                     Integer (K - K0),
                     Integer (I - I0), Integer (J - J0),
                     Integer (K - K0),
                     Integer (I - I0) - 1, Integer (J - J0),
                     Integer (K - K0));
               end loop;
            end loop;
         end loop;
      end;

      return M;
   end Extract_Dual;

   function Extract_Via_Surface_Nets_Lite
     (Values    : Scalar_Grid3;
      Positions : Position_Grid3;
      Isolevel  : Iso_Level) return Mesh
   is
   begin
      return Extract_Dual (Values, Positions, Isolevel, Surface_Nets);
   end Extract_Via_Surface_Nets_Lite;

   function Extract_Via_Dual_Contouring_Lite
     (Values    : Scalar_Grid3;
      Positions : Position_Grid3;
      Isolevel  : Iso_Level) return Mesh
   is
   begin
      return Extract_Dual (Values, Positions, Isolevel, Dual_Contouring);
   end Extract_Via_Dual_Contouring_Lite;

   -------------------------------------------------------------------------
   -- 6. Marching_Tetrahedra_Cell (local 6-tet + 16-case table)
   -------------------------------------------------------------------------

   subtype Tetra_Edge is Natural range 0 .. 5;
   subtype Tet_Case is Natural range 0 .. 15;
   type Tetra_Corners is array (0 .. 3) of Cube_Corner;
   type Tetrahedron is record
      Corners : Tetra_Corners;
   end record;
   type Tetrahedra_Six is array (1 .. 6) of Tetrahedron;

   Tetra_Edge_Verts : constant array (Tetra_Edge) of Edge_Ends :=
     [0 => [0, 1], 1 => [1, 2], 2 => [2, 0],
      3 => [0, 3], 4 => [1, 3], 5 => [2, 3]];
   --  Note: Edge_Ends uses Cube_Corner range; here we store local 0..3
   --  indices cast through Natural — values stay in 0..3.

   type Case_Edges is array (1 .. 7) of Integer;

   function Tet_Edge_List (C : Tet_Case) return Case_Edges is
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
   end Tet_Edge_List;

   function Split_Six return Tetrahedra_Six is
   begin
      return
        [1 => (Corners => [0, 5, 1, 6]),
         2 => (Corners => [0, 1, 2, 6]),
         3 => (Corners => [0, 2, 3, 6]),
         4 => (Corners => [0, 3, 7, 6]),
         5 => (Corners => [0, 7, 4, 6]),
         6 => (Corners => [0, 4, 5, 6])];
   end Split_Six;

   procedure Triangulate_Tet
     (P0, P1, P2, P3 : Point3;
      S0, S1, S2, S3 : Real;
      Isolevel       : Real;
      Out_Tris       : in out Small_Triangle_List;
      Out_Count      : in out Natural)
   is
      Idx : Natural := 0;
      Case_Id : Tet_Case;
      Edges : Case_Edges;
      Pos : constant array (0 .. 3) of Point3 := [P0, P1, P2, P3];
      Scl : constant array (0 .. 3) of Real := [S0, S1, S2, S3];
      Vert : array (Tetra_Edge) of Point3;
      I : Positive := 1;
      E0, E1, E2 : Integer;
      Va, Vb : Natural;
      Grad : Normal3;
      Acc : Vec3 := (0.0, 0.0, 0.0);
      Ctr : constant Point3 := 0.25 * (P0 + (P1 + (P2 + P3)));
      D : Vec3;
      L : Non_Negative;
      Need : Boolean;
   begin
      if S0 < Isolevel then Idx := Idx + 1; end if;
      if S1 < Isolevel then Idx := Idx + 2; end if;
      if S2 < Isolevel then Idx := Idx + 4; end if;
      if S3 < Isolevel then Idx := Idx + 8; end if;
      Case_Id := Tet_Case (Idx);
      if Case_Id = 0 or else Case_Id = 15 then
         return;
      end if;

      D := P0 - Ctr; L := Length (D);
      if L > 0.0 then Acc := Acc + ((S0 / L) * D); end if;
      D := P1 - Ctr; L := Length (D);
      if L > 0.0 then Acc := Acc + ((S1 / L) * D); end if;
      D := P2 - Ctr; L := Length (D);
      if L > 0.0 then Acc := Acc + ((S2 / L) * D); end if;
      D := P3 - Ctr; L := Length (D);
      if L > 0.0 then Acc := Acc + ((S3 / L) * D); end if;
      if Length (Acc) < 1.0E-12 then
         Grad := (0.0, 0.0, 1.0);
      else
         Grad := Normalize (Acc);
      end if;

      Edges := Tet_Edge_List (Case_Id);
      for E in Tetra_Edge loop
         Need := False;
         for K in Edges'Range loop
            if Edges (K) = E then
               Need := True;
               exit;
            end if;
         end loop;
         if Need then
            Va := Natural (Tetra_Edge_Verts (E) (0));
            Vb := Natural (Tetra_Edge_Verts (E) (1));
            --  Local vertex indices 0..3 stored in Cube_Corner-typed slots.
            Vert (E) := Interpolate_Edge
              (Pos (Va), Pos (Vb), Scl (Va), Scl (Vb), Isolevel);
         end if;
      end loop;

      while I <= 6 and then Edges (I) >= 0 loop
         E0 := Edges (I);
         E1 := Edges (I + 1);
         E2 := Edges (I + 2);
         if E0 < 0 or else E1 < 0 or else E2 < 0 then
            exit;
         end if;
         if Out_Count >= 12 then
            return;
         end if;
         Out_Count := Out_Count + 1;
         Out_Tris (Out_Count) :=
           (A  => Vert (Tetra_Edge (E0)),
            B  => Vert (Tetra_Edge (E1)),
            C  => Vert (Tetra_Edge (E2)),
            NA => Grad, NB => Grad, NC => Grad);
         I := I + 3;
      end loop;
   end Triangulate_Tet;

   procedure Marching_Tetrahedra_Cell
     (P0, P1, P2, P3, P4, P5, P6, P7 : Point3;
      S0, S1, S2, S3, S4, S5, S6, S7 : Real;
      Isolevel  : Iso_Level;
      Out_Tris  : out Small_Triangle_List;
      Out_Count : out Natural)
   is
      Tets : constant Tetrahedra_Six := Split_Six;
      Pos  : constant Corner_Points :=
        [P0, P1, P2, P3, P4, P5, P6, P7];
      Scl  : constant Corner_Scalars :=
        [S0, S1, S2, S3, S4, S5, S6, S7];
      Iso  : constant Real := Real (Isolevel);
      C    : Tetra_Corners;
   begin
      Out_Count := 0;
      Out_Tris :=
        [others => (A => (0.0, 0.0, 0.0), B => (0.0, 0.0, 0.0),
                    C => (0.0, 0.0, 0.0),
                    NA => (0.0, 0.0, 0.0), NB => (0.0, 0.0, 0.0),
                    NC => (0.0, 0.0, 0.0))];
      for T in Tets'Range loop
         C := Tets (T).Corners;
         Triangulate_Tet
           (Pos (C (0)), Pos (C (1)), Pos (C (2)), Pos (C (3)),
            Scl (C (0)), Scl (C (1)), Scl (C (2)), Scl (C (3)),
            Iso, Out_Tris, Out_Count);
      end loop;
   end Marching_Tetrahedra_Cell;

   -------------------------------------------------------------------------
   -- 8. Field fixtures
   -------------------------------------------------------------------------

   procedure Fill_Sphere_SDF
     (Values    : out Scalar_Grid3;
      Positions : out Position_Grid3;
      Origin    : Point3;
      Spacing   : Real;
      Center    : Point3;
      Radius    : Non_Negative)
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
                 (Origin.X + Spacing * Real (I - Values'First (1)),
                  Origin.Y + Spacing * Real (J - Values'First (2)),
                  Origin.Z + Spacing * Real (K - Values'First (3)));
               Positions (I, J, K) := P;
               Values (I, J, K) := Distance_Between (P, Center) - Radius;
            end loop;
         end loop;
      end loop;
   end Fill_Sphere_SDF;

   procedure Fill_Plane_Field
     (Values       : out Scalar_Grid3;
      Positions    : out Position_Grid3;
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
                 (Origin.X + Spacing * Real (I - Values'First (1)),
                  Origin.Y + Spacing * Real (J - Values'First (2)),
                  Origin.Z + Spacing * Real (K - Values'First (3)));
               Positions (I, J, K) := P;
               Values (I, J, K) := Dot (P - Plane_Point, N);
            end loop;
         end loop;
      end loop;
   end Fill_Plane_Field;

   procedure Fill_Gyroid_Field
     (Values    : out Scalar_Grid3;
      Positions : out Position_Grid3;
      Origin    : Point3;
      Spacing   : Real;
      Scale     : Real := 1.0)
   is
      P : Point3;
      SX, SY, SZ : Real;
   begin
      if Spacing <= 0.0 or else Scale <= 0.0 then
         raise Invalid_Argument with "Fill_Gyroid_Field: bad Spacing/Scale";
      end if;
      for I in Values'Range (1) loop
         for J in Values'Range (2) loop
            for K in Values'Range (3) loop
               P :=
                 (Origin.X + Spacing * Real (I - Values'First (1)),
                  Origin.Y + Spacing * Real (J - Values'First (2)),
                  Origin.Z + Spacing * Real (K - Values'First (3)));
               Positions (I, J, K) := P;
               SX := Scale * P.X;
               SY := Scale * P.Y;
               SZ := Scale * P.Z;
               Values (I, J, K) :=
                 Sin_F (SX) * Cos_F (SY)
                 + Sin_F (SY) * Cos_F (SZ)
                 + Sin_F (SZ) * Cos_F (SX);
            end loop;
         end loop;
      end loop;
   end Fill_Gyroid_Field;

   -------------------------------------------------------------------------
   -- 9. Level_Set_Band
   -------------------------------------------------------------------------

   function Empty_Band return Level_Set_Band is
      B : Level_Set_Band;
   begin
      B.Count := 0;
      return B;
   end Empty_Band;

   function Count_Band_Points (B : Level_Set_Band) return Natural is
   begin
      return Natural (B.Count);
   end Count_Band_Points;

   function Collect_Level_Set_Band
     (Values    : Scalar_Grid3;
      Positions : Position_Grid3;
      Isolevel  : Iso_Level;
      Epsilon   : Non_Negative) return Level_Set_Band
   is
      B   : Level_Set_Band := Empty_Band;
      Iso : constant Real := Real (Isolevel);
      V   : Real;
   begin
      for I in Values'Range (1) loop
         for J in Values'Range (2) loop
            for K in Values'Range (3) loop
               V := Values (I, J, K);
               if abs (V - Iso) <= Epsilon then
                  if B.Count = Max_Band_Points then
                     raise Band_Capacity
                       with "Collect_Level_Set_Band: capacity exceeded";
                  end if;
                  B.Count := B.Count + 1;
                  B.Points (B.Count) := Positions (I, J, K);
                  B.Values (B.Count) := V;
               end if;
            end loop;
         end loop;
      end loop;
      return B;
   end Collect_Level_Set_Band;

end Isosurfaces;
