--  Marching_Cubes — Ada 2023 educational implementation of the
--  marching cubes isosurface extraction algorithm: 256 cube cases,
--  edge interpolation, face asymptotic-decider helper, single-cell
--  and full-grid marching, normals / mesh stats, and field fixtures.
--  Based on Wikipedia "Marching cubes" (Lorensen & Cline 1987).

pragma Ada_2022;

package Marching_Cubes
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 6;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   type Vec3 is record
      X, Y, Z : Real := 0.0;
   end record;

   subtype Point3  is Vec3;
   subtype Normal3 is Vec3;

   --  Cube corners 0..7 (unit cell / grid cell local indices):
   --    0=(0,0,0) 1=(1,0,0) 2=(1,1,0) 3=(0,1,0)
   --    4=(0,0,1) 5=(1,0,1) 6=(1,1,1) 7=(0,1,1)
   subtype Cube_Corner is Natural range 0 .. 7;

   --  Cube edges 0..11 (Paul Bourke / classic MC numbering):
   --    0:0-1  1:1-2  2:2-3  3:3-0
   --    4:4-5  5:5-6  6:6-7  7:7-4
   --    8:0-4  9:1-5 10:2-6 11:3-7
   subtype Cube_Edge is Natural range 0 .. 11;

   --  8-bit case index from eight corner signs (0..255).
   subtype Case_Index is Natural range 0 .. 255;

   --  Cube faces 0..5 for asymptotic-decider helper:
   --    0=-X  1=+X  2=-Y  3=+Y  4=-Z  5=+Z
   subtype Cube_Face is Natural range 0 .. 5;

   type Triangle is record
      A, B, C    : Point3;
      NA, NB, NC : Normal3 := (0.0, 0.0, 0.0);
   end record;

   --  Classic MC emits at most five triangles per cube.
   type Small_Triangle_List is array (1 .. 5) of Triangle;

   --  Edge-id triplets for Lookup_Triangles (unused slots = -1).
   type Edge_Id_Triplet is array (1 .. 3) of Integer;
   type Edge_Id_List is array (1 .. 5) of Edge_Id_Triplet;

   Max_Triangles : constant Positive := 16_384;
   subtype Triangle_Count is Natural range 0 .. Max_Triangles;
   subtype Triangle_Index is Positive range 1 .. Max_Triangles;
   type Triangle_Array is array (Triangle_Index) of Triangle;

   type Mesh is record
      Tris  : Triangle_Array;
      Count : Triangle_Count := 0;
   end record;

   type Mesh_Stats is record
      Triangle_Count : Natural := 0;
      Vertex_Slots   : Natural := 0;  -- Count * 3
      Min_Corner     : Point3  := (0.0, 0.0, 0.0);
      Max_Corner     : Point3  := (0.0, 0.0, 0.0);
   end record;

   --  Educational scalar grids stay modest (samples per axis).
   Max_Grid_Dim : constant Positive := 32;
   subtype Grid_Dim is Positive range 2 .. Max_Grid_Dim;

   --  Unconstrained 3-D scalar field (I, J, K). Callers must keep each
   --  dimension within Max_Grid_Dim for March_Grid.
   type Scalar_Grid3 is
     array (Natural range <>, Natural range <>, Natural range <>) of Real;

   type Position_Grid3 is
     array (Natural range <>, Natural range <>, Natural range <>) of Point3;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;
   Mesh_Capacity       : exception;

   ---------------------------------------------------------------------------
   -- Vector / numeric helpers
   ---------------------------------------------------------------------------

   function Length (V : Vec3) return Non_Negative
     with Global => null;

   function Normalize (V : Vec3) return Normal3
     with Pre    => Length (V) > 0.0,
          Post   => abs (Length (Normalize'Result) - 1.0) <= 1.0E-4,
          Global => null;

   function Dot (A, B : Vec3) return Real
     with Global => null;

   function Cross (A, B : Vec3) return Vec3
     with Global => null;

   function "-" (A, B : Vec3) return Vec3
     with Global => null;

   function "+" (A, B : Vec3) return Vec3
     with Global => null;

   function "*" (S : Real; V : Vec3) return Vec3
     with Global => null;

   function Clamp (X, Lo, Hi : Real) return Real
     with Pre    => Lo <= Hi,
          Post   => Clamp'Result >= Lo and then Clamp'Result <= Hi,
          Global => null;

   function Distance_Between (A, B : Vec3) return Non_Negative
     with Global => null;

   function Cube_Corner_Offset (C : Cube_Corner) return Vec3
     with Global => null;
   --  Local (0/1,0/1,0/1) offset of cube corner C in a unit cell.

   ---------------------------------------------------------------------------
   -- 1. Cube_Case_Index
   ---------------------------------------------------------------------------

   function Cube_Case_Index
     (S0, S1, S2, S3, S4, S5, S6, S7 : Real;
      Isolevel                       : Real) return Case_Index
     with Global => null;
   --  Bit i set when Si < Isolevel (classic Lorensen/Bourke convention).

   function Cube_Case_Index
     (Corners  : Scalar_Grid3;
      I_Cell, J_Cell, K_Cell : Natural;
      Isolevel : Real) return Case_Index
     with Pre    => I_Cell >= Corners'First (1)
                      and then J_Cell >= Corners'First (2)
                      and then K_Cell >= Corners'First (3)
                      and then I_Cell < Corners'Last (1)
                      and then J_Cell < Corners'Last (2)
                      and then K_Cell < Corners'Last (3),
          Global => null;
   --  Same index from eight samples of a cell in a 3-D grid.

   ---------------------------------------------------------------------------
   -- 2. Interpolate_Edge_Vertex
   ---------------------------------------------------------------------------

   function Interpolate_Edge_Vertex
     (P0, P1   : Point3;
      V0, V1   : Real;
      Isolevel : Real) return Point3
     with Global => null;
   --  Linearly interpolate the isolevel crossing on segment P0–P1.
   --  Raises Degenerate_Geometry when V0 = V1 (no unique crossing).

   procedure Interpolate_Edge_Vertex
     (P0, P1   : Point3;
      V0, V1   : Real;
      G0, G1   : Vec3;
      Isolevel : Real;
      Position : out Point3;
      Gradient : out Vec3)
     with Global => null;
   --  Same position interpolation plus linearly blended gradient/normal.

   ---------------------------------------------------------------------------
   -- 3. Lookup_Triangles / March_Cube
   ---------------------------------------------------------------------------

   procedure Lookup_Triangles
     (Index     : Case_Index;
      Edges     : out Edge_Id_List;
      Out_Count : out Natural)
     with Post   => Out_Count <= 5,
          Global => null;
   --  256-case triangulation table: each entry is three cube-edge ids.
   --  Unused triplets are (-1,-1,-1). Classic educational table (Bourke).

   procedure March_Cube
     (P0, P1, P2, P3, P4, P5, P6, P7 : Point3;
      S0, S1, S2, S3, S4, S5, S6, S7 : Real;
      Isolevel  : Real;
      Out_Tris  : out Small_Triangle_List;
      Out_Count : out Natural)
     with Post   => Out_Count <= 5,
          Global => null;
   --  Emit 0..5 triangles for one cube using the triangulation table.
   --  Out_Tris (1 .. Out_Count) are meaningful; unused slots are zeroed.

   procedure March_Single_Cube
     (Corner_Pos : Position_Grid3;
      Corner_Val : Scalar_Grid3;
      I_Cell, J_Cell, K_Cell : Natural;
      Isolevel   : Real;
      Acc        : in out Mesh)
     with Pre    => Corner_Pos'First (1) = Corner_Val'First (1)
                      and then Corner_Pos'Last (1) = Corner_Val'Last (1)
                      and then Corner_Pos'First (2) = Corner_Val'First (2)
                      and then Corner_Pos'Last (2) = Corner_Val'Last (2)
                      and then Corner_Pos'First (3) = Corner_Val'First (3)
                      and then Corner_Pos'Last (3) = Corner_Val'Last (3)
                      and then I_Cell >= Corner_Val'First (1)
                      and then J_Cell >= Corner_Val'First (2)
                      and then K_Cell >= Corner_Val'First (3)
                      and then I_Cell < Corner_Val'Last (1)
                      and then J_Cell < Corner_Val'Last (2)
                      and then K_Cell < Corner_Val'Last (3),
          Global => null;
   --  March one grid cell and append triangles to Acc.
   --  Raises Mesh_Capacity if Acc cannot hold the new triangles.

   ---------------------------------------------------------------------------
   -- 4. Asymptotic_Decider / Disambiguate_Face
   ---------------------------------------------------------------------------

   function Asymptotic_Decider
     (F00, F10, F11, F01 : Real;
      Isolevel           : Real) return Boolean
     with Global => null;
   --  Nielson & Hamann (1991) face-saddle test on a bilinear face.
   --  Corners in cyclic order around the face: (0,0),(1,0),(1,1),(0,1).
   --  Returns True when the positive (above-isolevel) pair should connect
   --  along the F00–F11 diagonal topology branch.

   function Disambiguate_Face
     (Corners  : Scalar_Grid3;
      I_Cell, J_Cell, K_Cell : Natural;
      Face     : Cube_Face;
      Isolevel : Real) return Boolean
     with Pre    => I_Cell >= Corners'First (1)
                      and then J_Cell >= Corners'First (2)
                      and then K_Cell >= Corners'First (3)
                      and then I_Cell < Corners'Last (1)
                      and then J_Cell < Corners'Last (2)
                      and then K_Cell < Corners'Last (3),
          Global => null;
   --  Apply Asymptotic_Decider to one face of the given grid cell.
   --  Face corners are taken in cyclic order matching Asymptotic_Decider.

   function Face_Is_Ambiguous
     (F00, F10, F11, F01 : Real;
      Isolevel           : Real) return Boolean
     with Global => null;
   --  True when face corners alternate above/below the isolevel
   --  (classic face ambiguity of marching cubes).

   ---------------------------------------------------------------------------
   -- 5. March_Grid
   ---------------------------------------------------------------------------

   function March_Grid
     (Values    : Scalar_Grid3;
      Positions : Position_Grid3;
      Isolevel  : Real) return Mesh
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Values'First (3) = Positions'First (3)
                      and then Values'Last (3) = Positions'Last (3)
                      and then Values'Length (1) >= 2
                      and then Values'Length (2) >= 2
                      and then Values'Length (3) >= 2,
          Global => null;
   --  March every cell of a small 3-D scalar grid into a triangle mesh.
   --  Raises Invalid_Argument when any axis exceeds Max_Grid_Dim.

   ---------------------------------------------------------------------------
   -- 6. Estimate_Vertex_Normal / Face_Normal
   ---------------------------------------------------------------------------

   function Face_Normal (T : Triangle) return Normal3
     with Global => null;
   --  Unit normal from (B−A)×(C−A); raises Degenerate_Geometry if area ≈ 0.

   function Estimate_Vertex_Normal
     (Values : Scalar_Grid3;
      Positions : Position_Grid3;
      I, J, K : Natural) return Normal3
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Values'First (3) = Positions'First (3)
                      and then Values'Last (3) = Positions'Last (3)
                      and then I in Values'Range (1)
                      and then J in Values'Range (2)
                      and then K in Values'Range (3),
          Global => null;
   --  Central-difference gradient of the scalar field at (I,J,K),
   --  normalized (falls back to +Z if degenerate). Points toward
   --  increasing scalar.

   ---------------------------------------------------------------------------
   -- 7. Field fixtures
   ---------------------------------------------------------------------------

   procedure Fill_Sphere_SDF
     (Values    : out Scalar_Grid3;
      Positions : out Position_Grid3;
      Origin    : Point3;
      Spacing   : Real;
      Center    : Point3;
      Radius    : Non_Negative)
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Values'First (3) = Positions'First (3)
                      and then Values'Last (3) = Positions'Last (3)
                      and then Spacing > 0.0,
          Global => null;
   --  Sample signed distance |P−Center|−Radius on a regular lattice.

   procedure Fill_Plane_Field
     (Values       : out Scalar_Grid3;
      Positions    : out Position_Grid3;
      Origin       : Point3;
      Spacing      : Real;
      Plane_Point  : Point3;
      Plane_Normal : Normal3)
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Values'First (3) = Positions'First (3)
                      and then Values'Last (3) = Positions'Last (3)
                      and then Spacing > 0.0
                      and then Length (Plane_Normal) > 0.0,
          Global => null;
   --  Sample signed distance to a plane (Dot(P−Plane_Point, N_hat)).

   procedure Fill_Metaball_Field
     (Values    : out Scalar_Grid3;
      Positions : out Position_Grid3;
      Origin    : Point3;
      Spacing   : Real;
      C1, C2    : Point3;
      R1, R2    : Non_Negative)
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Values'First (3) = Positions'First (3)
                      and then Values'Last (3) = Positions'Last (3)
                      and then Spacing > 0.0,
          Global => null;
   --  Sample f = R1^2/|P−C1|^2 + R2^2/|P−C2|^2 − 1 (soft metaballs).
   --  Near a centre the potential is clamped to a large finite value.

   ---------------------------------------------------------------------------
   -- 8. Count_Triangles / Mesh_Stats helpers
   ---------------------------------------------------------------------------

   function Count_Triangles (M : Mesh) return Natural
     with Post   => Count_Triangles'Result = Natural (M.Count),
          Global => null;

   function Compute_Mesh_Stats (M : Mesh) return Mesh_Stats
     with Global => null;

   function Empty_Mesh return Mesh
     with Post   => Empty_Mesh'Result.Count = 0,
          Global => null;

   procedure Append_Triangle (M : in out Mesh; T : Triangle)
     with Global => null;
   --  Raises Mesh_Capacity when full.

end Marching_Cubes;
