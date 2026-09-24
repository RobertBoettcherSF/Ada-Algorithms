--  Isosurfaces — Ada 2023 educational package for isosurfaces (3-D level
--  sets): sampling a scalar volume, classifying voxels relative to an
--  isolevel, estimating gradients / normals, and lightweight extraction
--  helpers (Surface Nets lite, Dual Contouring lite, marching-tetrahedra
--  single-cell wrapper). Based on Wikipedia "Isosurface". Related to but
--  distinct from Marching_Cubes / Marching_Tetrahedrons (those packages
--  own the full lookup-table APIs); this layer does NOT embed a 256-case
--  marching-cubes table.

pragma Ada_2022;

package Isosurfaces
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

   type Iso_Level is new Real;

   --  Cube corners 0..7 (unit cell / grid cell local indices):
   --    0=(0,0,0) 1=(1,0,0) 2=(1,1,0) 3=(0,1,0)
   --    4=(0,0,1) 5=(1,0,1) 6=(1,1,1) 7=(0,1,1)
   subtype Cube_Corner is Natural range 0 .. 7;

   type Vertex_Class is (Inside, Outside, On_Surface);

   type Triangle is record
      A, B, C    : Point3;
      NA, NB, NC : Normal3 := (0.0, 0.0, 0.0);
   end record;

   --  At most 12 triangles from one cube via 6-tet split (2 per tet).
   type Small_Triangle_List is array (1 .. 12) of Triangle;

   Max_Triangles : constant Positive := 8_192;
   subtype Triangle_Count is Natural range 0 .. Max_Triangles;
   subtype Triangle_Index is Positive range 1 .. Max_Triangles;
   type Triangle_Array is array (Triangle_Index) of Triangle;

   type Mesh is record
      Tris  : Triangle_Array;
      Count : Triangle_Count := 0;
   end record;

   type Mesh_Stats is record
      Triangle_Count : Natural := 0;
      Vertex_Slots   : Natural := 0;
      Min_Corner     : Point3  := (0.0, 0.0, 0.0);
      Max_Corner     : Point3  := (0.0, 0.0, 0.0);
   end record;

   Max_Band_Points : constant Positive := 4_096;
   subtype Band_Count is Natural range 0 .. Max_Band_Points;
   subtype Band_Index is Positive range 1 .. Max_Band_Points;
   type Band_Point_Array is array (Band_Index) of Point3;
   type Band_Value_Array is array (Band_Index) of Real;

   type Level_Set_Band is record
      Points : Band_Point_Array;
      Values : Band_Value_Array;
      Count  : Band_Count := 0;
   end record;

   --  Educational scalar grids stay modest (samples per axis).
   Max_Grid_Dim : constant Positive := 32;
   subtype Grid_Dim is Positive range 2 .. Max_Grid_Dim;

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
   Band_Capacity       : exception;

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

   ---------------------------------------------------------------------------
   -- 1. Evaluate_Field / Sample_Trilinear
   ---------------------------------------------------------------------------

   function Evaluate_Field
     (Values : Scalar_Grid3;
      I, J, K : Natural) return Real
     with Pre    => I in Values'Range (1)
                      and then J in Values'Range (2)
                      and then K in Values'Range (3),
          Global => null;
   --  Direct grid sample at integer indices (I=X, J=Y, K=Z).

   function Sample_Trilinear
     (Values    : Scalar_Grid3;
      Positions : Position_Grid3;
      P         : Point3) return Real
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
   --  Trilinear interpolate f at world point P on a regular lattice.
   --  Raises Invalid_Argument when P lies outside the grid AABB.

   ---------------------------------------------------------------------------
   -- 2. Is_Inside / Classify_Vertex
   ---------------------------------------------------------------------------

   function Is_Inside
     (Value    : Real;
      Isolevel : Iso_Level) return Boolean
     with Global => null;
   --  True when Value < Isolevel (strictly inside the "below" halfspace).

   function Classify_Vertex
     (Value     : Real;
      Isolevel  : Iso_Level;
      Tolerance : Non_Negative := 1.0E-5) return Vertex_Class
     with Global => null;
   --  On_Surface when |Value − Isolevel| ≤ Tolerance; else Inside / Outside.

   ---------------------------------------------------------------------------
   -- 3. Estimate_Gradient / Estimate_Normal
   ---------------------------------------------------------------------------

   function Estimate_Gradient
     (Values    : Scalar_Grid3;
      Positions : Position_Grid3;
      I, J, K   : Natural) return Vec3
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Values'First (3) = Positions'First (3)
                      and then Values'Last (3) = Positions'Last (3)
                      and then I in Values'Range (1)
                      and then J in Values'Range (2)
                      and then K in Values'Range (3)
                      and then Values'Length (1) >= 2
                      and then Values'Length (2) >= 2
                      and then Values'Length (3) >= 2,
          Global => null;
   --  Central (or one-sided at borders) finite-difference ∇f.

   function Estimate_Normal
     (Values    : Scalar_Grid3;
      Positions : Position_Grid3;
      I, J, K   : Natural) return Normal3
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Values'First (3) = Positions'First (3)
                      and then Values'Last (3) = Positions'Last (3)
                      and then I in Values'Range (1)
                      and then J in Values'Range (2)
                      and then K in Values'Range (3)
                      and then Values'Length (1) >= 2
                      and then Values'Length (2) >= 2
                      and then Values'Length (3) >= 2,
          Global => null;
   --  Normalized ∇f (surface normal pointing toward increasing scalar).
   --  Falls back to +Z if the gradient is degenerate.

   ---------------------------------------------------------------------------
   -- 4. Extract_Via_Surface_Nets_Lite
   ---------------------------------------------------------------------------

   function Extract_Via_Surface_Nets_Lite
     (Values    : Scalar_Grid3;
      Positions : Position_Grid3;
      Isolevel  : Iso_Level) return Mesh
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
   --  Educational Surface Nets: one dual vertex per active cell (average of
   --  edge intersections), connect to active +X/+Y/+Z neighbours with quads
   --  (two triangles). Raises Invalid_Argument if an axis > Max_Grid_Dim.

   ---------------------------------------------------------------------------
   -- 5. Extract_Via_Dual_Contouring_Lite
   ---------------------------------------------------------------------------

   function Extract_Via_Dual_Contouring_Lite
     (Values    : Scalar_Grid3;
      Positions : Position_Grid3;
      Isolevel  : Iso_Level) return Mesh
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
   --  Educational Dual Contouring lite: dual vertex = average of Hermite
   --  edge intersections, then projected along the average normal through
   --  the cell centre (no SVD / full QEF). Same neighbour connectivity as
   --  Surface Nets lite.

   ---------------------------------------------------------------------------
   -- 6. Marching_Tetrahedra_Cell
   ---------------------------------------------------------------------------

   procedure Marching_Tetrahedra_Cell
     (P0, P1, P2, P3, P4, P5, P6, P7 : Point3;
      S0, S1, S2, S3, S4, S5, S6, S7 : Real;
      Isolevel  : Iso_Level;
      Out_Tris  : out Small_Triangle_List;
      Out_Count : out Natural)
     with Post   => Out_Count <= 12,
          Global => null;
   --  Compact cube→6-tet isosurface slice for one cell (local 16-case tet
   --  table; no 256-cube lookup). Consistent with Ada-Marching-Tetrahedrons
   --  diagonal-0–6 split. Out_Tris (1 .. Out_Count) are meaningful.

   ---------------------------------------------------------------------------
   -- 7. Mesh helpers
   ---------------------------------------------------------------------------

   function Face_Normal (T : Triangle) return Normal3
     with Global => null;
   --  Unit normal from (B−A)×(C−A); raises Degenerate_Geometry if area ≈ 0.

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

   procedure Append_Mesh (Dest : in out Mesh; Src : Mesh)
     with Global => null;
   --  Append all triangles from Src onto Dest; raises Mesh_Capacity if full.

   function Merge_Meshes (A, B : Mesh) return Mesh
     with Global => null;
   --  Fresh mesh containing triangles of A then B.
   --  Raises Mesh_Capacity when A.Count + B.Count > Max_Triangles.

   ---------------------------------------------------------------------------
   -- 8. Field fixtures
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

   procedure Fill_Gyroid_Field
     (Values    : out Scalar_Grid3;
      Positions : out Position_Grid3;
      Origin    : Point3;
      Spacing   : Real;
      Scale     : Real := 1.0)
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Values'First (3) = Positions'First (3)
                      and then Values'Last (3) = Positions'Last (3)
                      and then Spacing > 0.0
                      and then Scale > 0.0,
          Global => null;
   --  Sample sin(sx)·cos(sy) + sin(sy)·cos(sz) + sin(sz)·cos(sx)
   --  with s = Scale (classic triply periodic gyroid approximate field).

   ---------------------------------------------------------------------------
   -- 9. Level_Set_Band
   ---------------------------------------------------------------------------

   function Collect_Level_Set_Band
     (Values    : Scalar_Grid3;
      Positions : Position_Grid3;
      Isolevel  : Iso_Level;
      Epsilon   : Non_Negative) return Level_Set_Band
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Values'First (3) = Positions'First (3)
                      and then Values'Last (3) = Positions'Last (3),
          Global => null;
   --  Collect grid samples with |f − Isolevel| ≤ Epsilon (shell / band).
   --  Raises Band_Capacity when more than Max_Band_Points qualify.

   function Empty_Band return Level_Set_Band
     with Post   => Empty_Band'Result.Count = 0,
          Global => null;

   function Count_Band_Points (B : Level_Set_Band) return Natural
     with Post   => Count_Band_Points'Result = Natural (B.Count),
          Global => null;

end Isosurfaces;
