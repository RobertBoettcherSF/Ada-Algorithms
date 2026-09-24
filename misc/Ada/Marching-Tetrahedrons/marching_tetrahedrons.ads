--  Marching_Tetrahedrons — Ada 2023 educational implementation of the
--  marching tetrahedra (marching tetrahedrons) isosurface extraction
--  algorithm: cube→6-tet split, 16 tetra cases, edge interpolation,
--  single-cell and full-grid marching, normals / mesh stats.
--  Based on Wikipedia "Marching tetrahedra" and Doi & Koide (1991).

pragma Ada_2022;

package Marching_Tetrahedrons
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

   --  One tetrahedron as four cube-corner indices.
   type Tetra_Corners is array (0 .. 3) of Cube_Corner;

   type Tetrahedron is record
      Corners : Tetra_Corners;
   end record;

   --  Six tetrahedra that tile one cube (share the main diagonal 0–6).
   type Tetrahedra_Six is array (1 .. 6) of Tetrahedron;

   --  Case index from four corner signs relative to the isolevel (0..15).
   subtype Case_Index is Natural range 0 .. 15;

   --  Local tetra edge id (0..5) among the four tetra vertices.
   subtype Tetra_Edge is Natural range 0 .. 5;

   type Triangle is record
      A, B, C       : Point3;
      NA, NB, NC    : Normal3 := (0.0, 0.0, 0.0);
   end record;

   --  At most two triangles per tetrahedron configuration.
   type Small_Triangle_List is array (1 .. 2) of Triangle;

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
   type Scalar_Field is
     array (Natural range <>, Natural range <>, Natural range <>) of Real;

   --  Matching 3-D position lattice for the same index extents.
   type Position_Field is
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
   -- 1. Split_Cube_Into_Tetrahedra
   ---------------------------------------------------------------------------

   function Split_Cube_Into_Tetrahedra return Tetrahedra_Six
     with Global => null;
   --  Fixed mapping of the six irregular tetrahedra that tile a cube by
   --  cutting diagonally through each pair of opposing faces; all share
   --  the main diagonal between corners 0 and 6.

   ---------------------------------------------------------------------------
   -- 2. Tetra_Case_Index
   ---------------------------------------------------------------------------

   function Tetra_Case_Index
     (S0, S1, S2, S3 : Real;
      Isolevel       : Real) return Case_Index
     with Global => null;
   --  Bit i set when Si < Isolevel (strictly inside the "below" halfspace).

   ---------------------------------------------------------------------------
   -- 3. Interpolate_Edge_Vertex
   ---------------------------------------------------------------------------

   function Interpolate_Edge_Vertex
     (P0, P1 : Point3;
      V0, V1 : Real;
      Isolevel : Real) return Point3
     with Global => null;
   --  Linearly interpolate the isolevel crossing on segment P0–P1.
   --  Raises Degenerate_Geometry when V0 = V1 (no unique crossing).

   procedure Interpolate_Edge_Vertex
     (P0, P1 : Point3;
      V0, V1 : Real;
      G0, G1 : Vec3;
      Isolevel : Real;
      Position : out Point3;
      Gradient : out Vec3)
     with Global => null;
   --  Same position interpolation plus linearly blended gradient/normal.

   ---------------------------------------------------------------------------
   -- 4. Triangulate_Tetrahedron
   ---------------------------------------------------------------------------

   procedure Triangulate_Tetrahedron
     (P0, P1, P2, P3 : Point3;
      S0, S1, S2, S3 : Real;
      Isolevel       : Real;
      Out_Tris       : out Small_Triangle_List;
      Out_Count      : out Natural)
     with Post   => Out_Count <= 2,
          Global => null;
   --  Emit 0..2 triangles for one tetrahedron's isosurface slice.
   --  Out_Tris (1 .. Out_Count) are meaningful; unused slots are zeroed.

   ---------------------------------------------------------------------------
   -- 5. March_Single_Cube
   ---------------------------------------------------------------------------

   procedure March_Single_Cube
     (Corner_Pos : Position_Field;
      Corner_Val : Scalar_Field;
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
   --  Split one grid cell into six tets, triangulate each, append to Acc.
   --  Raises Mesh_Capacity if Acc cannot hold the new triangles.

   ---------------------------------------------------------------------------
   -- 6. March_Grid
   ---------------------------------------------------------------------------

   function March_Grid
     (Values   : Scalar_Field;
      Positions : Position_Field;
      Isolevel : Real) return Mesh
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
   -- 7. Estimate_Normal / Face_Normal
   ---------------------------------------------------------------------------

   function Face_Normal (T : Triangle) return Normal3
     with Global => null;
   --  Unit normal from (B−A)×(C−A); raises Degenerate_Geometry if area ≈ 0.

   function Estimate_Normal
     (P0, P1, P2, P3 : Point3;
      S0, S1, S2, S3 : Real) return Normal3
     with Global => null;
   --  Finite-difference gradient estimate from the four tetra samples
   --  (centroid-centered), normalized. Falls back to +Z if degenerate.

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

   ---------------------------------------------------------------------------
   -- Deterministic field fixtures (tests / demos)
   ---------------------------------------------------------------------------

   procedure Fill_Sphere_SDF
     (Values     : out Scalar_Field;
      Positions  : out Position_Field;
      Origin     : Point3;
      Spacing    : Real;
      Center     : Point3;
      Radius     : Non_Negative)
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
     (Values     : out Scalar_Field;
      Positions  : out Position_Field;
      Origin     : Point3;
      Spacing    : Real;
      Plane_Point : Point3;
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

end Marching_Tetrahedrons;
