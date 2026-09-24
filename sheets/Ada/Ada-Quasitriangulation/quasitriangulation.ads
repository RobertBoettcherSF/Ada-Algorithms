--  Quasitriangulation — Ada 2023 educational package for quasi-triangulation.
--  A quasi-triangulation is a subdivision into simplices whose "vertices"
--  are arbitrary sloped line segments (not points). It is a topological
--  triangulation, not a classical geometric triangulation of a point set,
--  and may share some Delaunay-like characteristics.
--  Primary source:
--  https://en.wikipedia.org/wiki/Quasitriangulation
--  Sibling packages (README only; do not `with`):
--    Ada-Bowyer-Watson, Ada-Voronoi-Diagrams, Ada-Delaunay-Triangulation,
--    Ada-Polygon-Triangulation — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Quasitriangulation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   type Real is digits 15;

   --  Soft classroom limit on segment-sites ("vertices" of the quasi-mesh).
   Max_Segments : constant Positive := 32;

   --  Triangular faces in the combinatorial 2-D complex.
   Max_Faces : constant Positive := 64;

   --  Undirected edges of the dual sketch / face skeleton.
   Max_Edges : constant Positive := 96;

   subtype Segment_Count is Natural range 0 .. Max_Segments;
   subtype Segment_Index is Positive range 1 .. Max_Segments;

   subtype Face_Count_T is Natural range 0 .. Max_Faces;
   subtype Face_Index is Positive range 1 .. Max_Faces;

   subtype Edge_Count_T is Natural range 0 .. Max_Edges;
   subtype Edge_Index is Positive range 1 .. Max_Edges;

   ---------------------------------------------------------------------------
   -- Geometry: points and oriented segment-sites
   ---------------------------------------------------------------------------

   type Point is record
      X, Y : Real := 0.0;
   end record;

   type Point_Array is array (Positive range <>) of Point;

   --  Oriented line segment used as a "vertex object" of the quasi-mesh.
   --  Classical point triangulation is the special case where every site
   --  degenerates to a point (zero length, or A ≈ B).
   type Segment is record
      A, B : Point := (0.0, 0.0);
   end record;

   type Segment_Array is array (Segment_Index range <>) of Segment;

   ---------------------------------------------------------------------------
   -- Combinatorial simplex / face (2-D: three segment-site indices)
   ---------------------------------------------------------------------------

   --  A 2-simplex whose corners are segment-sites (topological triangle).
   type Simplex is record
      U, V, W : Segment_Index := 1;
   end record;

   type Simplex_Array is array (Face_Index range <>) of Simplex;

   --  Undirected edge between two segment-sites (labels only).
   type Edge is record
      P, Q : Segment_Index := 1;
   end record;

   type Edge_Array is array (Edge_Index range <>) of Edge;

   type Quasi_Mesh is record
      Seg_N  : Segment_Count := 0;
      Segs   : Segment_Array (1 .. Max_Segments) := [others => <>];
      Face_N : Face_Count_T := 0;
      Faces  : Simplex_Array (1 .. Max_Faces) :=
                 [others => (U => 1, V => 1, W => 1)];
      Edge_N : Edge_Count_T := 0;
      Edges  : Edge_Array (1 .. Max_Edges) := [others => (P => 1, Q => 1)];
   end record;

   ---------------------------------------------------------------------------
   -- Intersection classification (educational Float)
   ---------------------------------------------------------------------------

   type Intersection_Kind is
     (None,                --  disjoint (no shared point in the closed sense)
      Proper_Cross,        --  interiors cross at a single interior point
      Endpoint_Touch,      --  share an endpoint / T-junction touch
      Collinear_Overlap);  --  overlap on a positive-length collinear span

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for empty / oversized inputs, degenerate segments when
   --  forbidden, crossing segment sets when a non-crossing set is required,
   --  or faces that reference out-of-range segment indices.

   Capacity_Exceeded : exception;
   --  Raised if face / edge buffers would overflow (should not occur for
   --  Max_Segments educational inputs).

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near_Point (A, B : Point; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Dist2 (A, B : Point) return Real
     with Global => null;
   --  Squared Euclidean distance.

   function Distance (A, B : Point) return Real
     with Global => null;

   function Midpoint (S : Segment) return Point
     with Global => null;
   --  Midpoint of segment S — used as a proxy site for Delaunay-like sketches.

   function Segment_Length (S : Segment) return Real
     with Global => null;

   function Is_Point_Site (S : Segment; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True iff A ≈ B (classical point vertex disguised as a segment).

   ---------------------------------------------------------------------------
   -- Orientation / predicates (educational floating-point)
   ---------------------------------------------------------------------------
   --  Classroom Float predicates — NOT robust adaptive-precision (Shewchuk)
   --  and NOT a substitute for CGAL / exact geometric kernels.

   function Orient2D (A, B, C : Point) return Real
     with Global => null;
   --  Twice signed area of triangle ABC: (B-A)×(C-A).
   --  > 0 ⇒ C left of directed AB (CCW); < 0 ⇒ right (CW); ≈ 0 ⇒ collinear.

   function CCW (A, B, C : Point) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Segment intersection helpers
   ---------------------------------------------------------------------------

   function Classify_Intersection (S, T : Segment) return Intersection_Kind
     with Global => null;
   --  Educational classification of how two closed segments meet.
   --  Proper_Cross ⇒ interiors cross; Endpoint_Touch ⇒ share endpoint /
   --  grazing touch; Collinear_Overlap ⇒ positive collinear overlap;
   --  None ⇒ otherwise disjoint under Float tolerances.

   function Segments_Properly_Cross (S, T : Segment) return Boolean
     with Global => null;
   --  True iff Classify_Intersection = Proper_Cross.

   function Has_Proper_Crossing (Segs : Segment_Array) return Boolean
     with Global => null;
   --  True iff some unordered pair of distinct segments properly crosses.

   ---------------------------------------------------------------------------
   -- Classical point triangulation vs quasi
   ---------------------------------------------------------------------------

   function All_Point_Sites
     (Segs : Segment_Array; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True iff every segment is a point-site (A ≈ B).

   function Is_Classical_Point_Setting
     (M : Quasi_Mesh; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True iff the mesh's sites are all point-sites — i.e. the structure
   --  could be read as an ordinary geometric triangulation of points.

   function Is_Quasi_Setting
     (M : Quasi_Mesh; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True iff at least one site has positive length (true quasi case).

   ---------------------------------------------------------------------------
   -- Build a tiny educational quasi-triangulation
   ---------------------------------------------------------------------------

   function Build_From_Segments (Segs : Segment_Array) return Quasi_Mesh
     with Global => null;
   --  Build a combinatorial 2-D topological triangulation whose vertices
   --  are the given oriented segments (non-crossing required).
   --  Requires Segs'Length in 3 .. Max_Segments, no zero-length segments,
   --  and no Proper_Cross pairs; otherwise raises Invalid_Argument.
   --
   --  Construction sketch (classroom):
   --    1. Reject crossings / degeneracies.
   --    2. Place a proxy point at each segment midpoint.
   --    3. Triangulate the midpoints with a tiny incremental fan from the
   --       lowest-then-leftmost midpoint (gift-wrap style for the hull,
   --       then fan-fill) — faces store segment indices, not midpoints.
   --    4. Derive the undirected edge set from the faces.
   --
   --  This is a topological / combinatorial sketch: the geometric embedding
   --  of faces is not claimed to be a classical Euclidean triangulation of
   --  the segment bodies themselves (Wikipedia: not geometric in that sense).

   function From_Point_Sites (Pts : Point_Array) return Quasi_Mesh
     with Global => null;
   --  Convenience: wrap each point as a zero-length Segment and call
   --  Build_From_Segments. Raises Invalid_Argument if Pts'Length not in
   --  3 .. Max_Segments.

   ---------------------------------------------------------------------------
   -- Combinatorial queries
   ---------------------------------------------------------------------------

   function Segment_Count_Of (M : Quasi_Mesh) return Segment_Count
     with Global => null;

   function Face_Count (M : Quasi_Mesh) return Face_Count_T
     with Global => null;

   function Edge_Count (M : Quasi_Mesh) return Edge_Count_T
     with Global => null;

   function Get_Segment
     (M : Quasi_Mesh; Index : Segment_Index) return Segment
     with Pre => Index <= M.Seg_N, Global => null;

   function Get_Face
     (M : Quasi_Mesh; Index : Face_Index) return Simplex
     with Pre => Index <= M.Face_N, Global => null;

   function Get_Edge
     (M : Quasi_Mesh; Index : Edge_Index) return Edge
     with Pre => Index <= M.Edge_N, Global => null;

   function Faces_Reference_Valid_Sites (M : Quasi_Mesh) return Boolean
     with Global => null;
   --  Every face corner is in 1 .. Seg_N and the three corners are distinct.

   function Is_Topological_Triangulation (M : Quasi_Mesh) return Boolean
     with Global => null;
   --  Educational checklist:
   --    • Seg_N >= 3, Face_N >= 1
   --    • Faces_Reference_Valid_Sites
   --    • every face has three distinct corners
   --    • derived edges cover all face sides
   --    • Euler_Check holds for a disk triangulation

   function Euler_Characteristic (M : Quasi_Mesh) return Integer
     with Global => null;
   --  V - E + F using Seg_N, Edge_N, Face_N (triangular faces only;
   --  outer face not counted). For a triangulated disk this is 1.

   function Euler_Check (M : Quasi_Mesh) return Boolean
     with Global => null;
   --  True iff Euler_Characteristic (M) = 1 (disk) or the trivial
   --  single-triangle case V=3,E=3,F=1 (also χ=1).

   ---------------------------------------------------------------------------
   -- Delaunay-like educational stub
   ---------------------------------------------------------------------------

   function Refine_Toward_Delaunay_Like (M : Quasi_Mesh) return Quasi_Mesh
     with Global => null;
   --  Educational stub: returns a copy of M after a documented no-op /
   --  midpoint-proxy empty-circle sketch pass. Does NOT implement a true
   --  segment Delaunay / constrained Delaunay / Voronoi-of-segments kernel.
   --  Documented as a classroom placeholder relating quasi-triangulations
   --  to Delaunay-like characteristics (Wikipedia). Raises Invalid_Argument
   --  if M is empty.

end Quasitriangulation;
