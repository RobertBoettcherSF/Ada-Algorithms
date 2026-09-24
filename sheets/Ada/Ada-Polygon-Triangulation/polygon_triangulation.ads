--  Polygon_Triangulation — Ada 2023 educational package for triangulating
--  a simple polygon without holes via ear clipping (two ears theorem).
--  Vertices are ordinary points; output is n−2 triangles whose union is P.
--  Primary source:
--  https://en.wikipedia.org/wiki/Polygon_triangulation
--  Sibling packages (README only; do not `with`):
--    Ada-Bowyer-Watson, Ada-Quasitriangulation, Ada-Delaunay-Triangulation,
--    Ada-Marching-Triangles — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Polygon_Triangulation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   type Real is digits 15;

   --  Soft classroom limit on polygon vertices.
   Max_Vertices : constant Positive := 64;

   --  A simple n-gon triangulates into exactly n−2 triangles (no Steiner
   --  points). Buffer sized for Max_Vertices.
   Max_Triangles : constant Positive := Max_Vertices - 2;

   subtype Vertex_Count is Natural range 0 .. Max_Vertices;
   subtype Vertex_Index is Positive range 1 .. Max_Vertices;

   subtype Triangle_Count is Natural range 0 .. Max_Triangles;
   subtype Triangle_Index is Positive range 1 .. Max_Triangles;

   type Point is record
      X, Y : Real := 0.0;
   end record;

   --  Polygon vertices in order around the boundary. Preferred orientation
   --  is counterclockwise (CCW). Clockwise (CW) inputs are accepted and
   --  normalized internally by reversing a working copy so that convex /
   --  ear tests remain consistent with positive Orient2D.
   type Point_Array is array (Vertex_Index range <>) of Point;

   --  Triangle stores three vertex indices into the original input polygon
   --  (1-based relative to Polygon'First mapped to 1).
   type Triangle is record
      A, B, C : Vertex_Index := 1;
   end record;

   type Triangle_Array is array (Triangle_Index range <>) of Triangle;

   type Triangulation is record
      Tris  : Triangle_Array (1 .. Max_Triangles) :=
                [others => (A => 1, B => 1, C => 1)];
      Count : Triangle_Count := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when Polygon'Length < 3, Polygon'Length > Max_Vertices, when
   --  consecutive / closing vertices are near-duplicates, when the polygon
   --  is near-degenerate (near-zero area), or when ear clipping cannot
   --  progress (educational failure on non-simple / self-intersecting
   --  inputs that pass the lightweight Is_Simple_Enough pre-check).

   Capacity_Exceeded : exception;
   --  Raised if triangle buffers would overflow (should not occur for
   --  Max_Vertices educational inputs).

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

   ---------------------------------------------------------------------------
   -- Orientation / predicates (educational floating-point)
   ---------------------------------------------------------------------------
   --  These predicates use plain Float arithmetic. They are adequate for
   --  classroom examples with well-separated vertices, but are NOT robust
   --  adaptive-precision predicates (Shewchuk) and are NOT a substitute
   --  for CGAL / exact geometric kernels. Documented educational caveat.

   function Orient2D (A, B, C : Point) return Real
     with Global => null;
   --  Twice signed area of triangle ABC: (B-A)×(C-A).
   --  > 0 ⇒ C left of directed AB (CCW); < 0 ⇒ right (CW); ≈ 0 ⇒ collinear.

   function CCW (A, B, C : Point) return Boolean
     with Global => null;
   --  True iff Orient2D (A, B, C) > Epsilon (strictly counterclockwise).

   function Point_In_Triangle
     (P, A, B, C : Point; Strict : Boolean := True) return Boolean
     with Global => null;
   --  True iff P lies inside triangle ABC. When Strict is True, P must be
   --  strictly inside (not on a boundary edge). Uses consistent orientation
   --  of (A,B,P), (B,C,P), (C,A,P) relative to Orient2D (A,B,C).

   ---------------------------------------------------------------------------
   -- Polygon measures / vertex classification
   ---------------------------------------------------------------------------

   function Signed_Area (Polygon : Point_Array) return Real
     with Global => null;
   --  Shoelace formula: positive for CCW, negative for CW.

   function Area (Polygon : Point_Array) return Real
     with Global => null;
   --  Absolute polygon area |Signed_Area| / 2 via shoelace (returns
   --  |Signed_Area| / 2.0).

   function Is_CCW (Polygon : Point_Array) return Boolean
     with Global => null;
   --  True iff Signed_Area (Polygon) > Epsilon.

   function Is_Convex_Vertex
     (Polygon : Point_Array; Index : Vertex_Index) return Boolean
     with Pre => Index in Polygon'Range and then Polygon'Length >= 3,
          Global => null;
   --  For a CCW-normalized view of Polygon, true iff the turn at Index is
   --  a left turn (interior angle < π). CW polygons are conceptually
   --  reversed for this test so the same geometric convexity is reported.

   function Is_Ear
     (Polygon : Point_Array; Index : Vertex_Index) return Boolean
     with Pre => Index in Polygon'Range and then Polygon'Length >= 3,
          Global => null;
   --  Ear-tip test (Wikipedia ear clipping): Index is convex, and no other
   --  polygon vertex (except Index and its two adjacent vertices) lies
   --  strictly inside the triangle formed by (prev, Index, next). The
   --  diagonal (prev, next) then lies inside the polygon.

   function Is_Simple_Enough (Polygon : Point_Array) return Boolean
     with Global => null;
   --  Lightweight educational pre-check: n in 3 .. Max_Vertices, no
   --  consecutive / closing near-duplicates, and |Signed_Area| above
   --  Epsilon. Does NOT prove simplicity (no full O(n²) edge-crossing
   --  sweep); self-intersecting inputs may still fail later in
   --  Triangulate_Ear_Clip with Invalid_Argument.

   ---------------------------------------------------------------------------
   -- Ear-clipping triangulation
   ---------------------------------------------------------------------------

   function Triangulate_Ear_Clip (Polygon : Point_Array) return Triangulation
     with Global => null;
   --  Triangulate a simple polygon without holes by repeatedly clipping
   --  ears (O(n²) educational implementation of the two ears theorem).
   --  Requires Polygon'Length in 3 .. Max_Vertices and Is_Simple_Enough;
   --  otherwise raises Invalid_Argument. Returns exactly n−2 triangles
   --  whose vertices are 1-based indices into a dense copy of Polygon
   --  (Polygon'First maps to 1, …, Polygon'Last maps to n).
   --
   --  Steps:
   --    1. Validate; build a working vertex ring (normalize to CCW).
   --    2. While ≥ 4 vertices remain: find an ear tip, emit the triangle
   --       (prev, tip, next) with original indices, remove the tip.
   --    3. Emit the final remaining triangle.
   --
   --  Complexity: O(n²) ear searches (each Is_Ear scans O(n) vertices).
   --  Faster O(n) monotone / Chazelle methods exist; this package teaches
   --  the classical ear-clipping approach only.

   function Triangle_Count_Of (T : Triangulation) return Triangle_Count
     with Global => null;

   function Get_Triangle
     (T : Triangulation; Index : Triangle_Index) return Triangle
     with Pre => Index <= T.Count, Global => null;

   function Uses_Vertex
     (Tri : Triangle; V : Vertex_Index) return Boolean
     with Global => null;

end Polygon_Triangulation;
