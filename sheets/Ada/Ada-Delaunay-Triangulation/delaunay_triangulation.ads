--  Delaunay_Triangulation — Ada 2023 educational survey package for
--  2-D Delaunay triangulation of a finite point set. A triangulation is
--  Delaunay when no site lies strictly inside the circumcircle of any
--  triangle (empty-circle / empty-circumcircle property). Equivalently,
--  it maximizes the minimum angle among all triangulations of the sites.
--  Dual of the Voronoi diagram: circumcenters are Voronoi vertices.
--  Primary source:
--  https://en.wikipedia.org/wiki/Delaunay_triangulation
--  Implementation: embedded Bowyer–Watson incremental construction
--  (self-contained; does NOT `with` sibling packages).
--  Sibling packages (README only; do not `with`):
--    Ada-Bowyer-Watson, Ada-Fortunes-Algorithm, Ada-Voronoi-Diagrams,
--    Ada-Rupperts-Algorithm, Ada-Chews-Second-Algorithm —
--    RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Delaunay_Triangulation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   type Real is digits 15;

   --  Soft classroom limit on input sites (plus 3 reserved super vertices).
   Max_Points : constant Positive := 64;

   --  Worst-case triangle storage during incremental construction:
   --  O(n) final triangles, but with the super-triangle and temporaries
   --  we keep a generous fixed buffer.
   Max_Triangles : constant Positive := 256;

   --  Hole boundary edges during one Bowyer–Watson insertion.
   Max_Hole_Edges : constant Positive := 128;

   subtype Point_Count is Natural range 0 .. Max_Points;
   subtype Point_Index is Positive range 1 .. Max_Points + 3;
   --  Indices 1 .. N are user sites; N+1 .. N+3 may hold super-triangle
   --  vertices during construction (internal).

   subtype Triangle_Count is Natural range 0 .. Max_Triangles;
   subtype Triangle_Index is Positive range 1 .. Max_Triangles;

   type Point is record
      X, Y : Real := 0.0;
   end record;

   type Point_Array is array (Point_Index range <>) of Point;

   --  Triangle stores three vertex indices into the working point table.
   --  Orientation of (A,B,C) is counterclockwise after construction.
   type Triangle is record
      A, B, C : Point_Index := 1;
   end record;

   type Triangle_Array is array (Triangle_Index range <>) of Triangle;

   type Triangulation is record
      Tris  : Triangle_Array (1 .. Max_Triangles) :=
                [others => (A => 1, B => 1, C => 1)];
      Count : Triangle_Count := 0;
   end record;

   type Bounding_Box is record
      Min_X, Min_Y, Max_X, Max_Y : Real := 0.0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when Points'Length < 3, Points'Length > Max_Points, or when
   --  duplicate / near-duplicate sites are detected (educational policy).

   Capacity_Exceeded : exception;
   --  Raised if internal triangle / hole buffers would overflow
   --  (should not occur for Max_Points educational inputs).

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
   --  classroom examples with well-separated sites, but are NOT robust
   --  adaptive-precision predicates (Shewchuk) and are NOT a substitute
   --  for CGAL / exact geometric kernels. Documented educational caveat.

   function Orient2D (A, B, C : Point) return Real
     with Global => null;
   --  Twice signed area of triangle ABC: (B-A)×(C-A).
   --  > 0 ⇒ C left of directed AB (CCW); < 0 ⇒ right (CW); ≈ 0 ⇒ collinear.

   function CCW (A, B, C : Point) return Boolean
     with Global => null;
   --  True iff Orient2D (A, B, C) > Epsilon (strictly counterclockwise).

   function In_Circumcircle (A, B, C, P : Point) return Boolean
     with Global => null;
   --  True iff P lies strictly inside the circumcircle of triangle ABC.
   --  Assumes ABC is oriented counterclockwise (Orient2D > 0). Uses the
   --  classic 3×3 determinant form centered at P (educational Float).

   function Circumcenter (A, B, C : Point) return Point
     with Global => null;
   --  Circumcenter of non-degenerate triangle ABC. Near-collinear inputs
   --  may produce large coordinates; callers should ensure Orient2D ≠ 0.

   function Circumradius2 (A, B, C : Point) return Real
     with Global => null;
   --  Squared circumradius of ABC (via circumcenter).

   ---------------------------------------------------------------------------
   -- Bounding box / duplicate check
   ---------------------------------------------------------------------------

   function Bounds_Of (Points : Point_Array) return Bounding_Box
     with Pre => Points'Length >= 1, Global => null;

   function Has_Near_Duplicate
     (Points : Point_Array; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True iff some pair of distinct sites is within Tol (Euclidean
   --  Dist2 ≤ Tol²). Used to raise Invalid_Argument before triangulate.

   ---------------------------------------------------------------------------
   -- Delaunay triangulation (embedded Bowyer–Watson)
   ---------------------------------------------------------------------------

   function Triangulate (Points : Point_Array) return Triangulation
     with Global => null;
   --  Compute a 2-D Delaunay triangulation of Points via embedded
   --  Bowyer–Watson incremental construction. Requires Points'Length in
   --  3 .. Max_Points and no near-duplicates; otherwise raises
   --  Invalid_Argument. Returns triangles whose vertices are 1-based
   --  indices into Points (order preserved: Points'First maps to 1).
   --
   --  Steps (Wikipedia incremental / Bowyer–Watson description):
   --    1. Build a large super-triangle containing all sites.
   --    2. Insert each site: collect bad triangles (In_Circumcircle),
   --       form the polygonal hole from unique boundary edges, delete
   --       bad triangles, connect each hole edge to the new site.
   --    3. Remove every triangle that still references a super vertex.
   --
   --  Complexity of this educational implementation: O(n²) circumcircle
   --  tests (no connectivity walk). With triangle adjacency the same
   --  algorithm reaches O(n log n) expected for many distributions.

   function Triangle_Count_Of (T : Triangulation) return Triangle_Count
     with Global => null;

   function Get_Triangle
     (T : Triangulation; Index : Triangle_Index) return Triangle
     with Pre => Index <= T.Count, Global => null;

   function Shares_Vertex
     (Tri : Triangle; V : Point_Index) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Delaunay verification / legalization sketch
   ---------------------------------------------------------------------------

   function Is_Delaunay
     (Points : Point_Array; T : Triangulation) return Boolean
     with Global => null;
   --  Empty-circle check: for every triangle Tri and every site P not a
   --  vertex of Tri, require not In_Circumcircle (Tri, P). True ⇒ the
   --  educational Float empty-circle property holds (may fail on
   --  near-cocircular or near-collinear classroom degeneracies).

   function Is_Delaunay_Edge_Empty
     (Points : Point_Array; T : Triangulation) return Boolean
     with Global => null;
   --  Alias of Is_Delaunay (historical / sibling naming).

   function Edge_Needs_Flip
     (A, B, C, D : Point) return Boolean
     with Global => null;
   --  Flip legalization sketch: given adjacent triangles △ABC and △ADB
   --  sharing edge AB (equivalently △ABD, △BCD with shared BD in wiki
   --  figures), return True if D lies inside the circumcircle of ABC
   --  (so AB is illegal and should be flipped to CD). Educational only;
   --  Triangulate already produces a Delaunay mesh via cavity rebuild.

end Delaunay_Triangulation;
