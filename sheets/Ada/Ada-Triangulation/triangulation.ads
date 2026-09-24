--  Triangulation — Ada 2023 educational survey package for geometric
--  triangulation: subdivision of a planar object into triangles that meet
--  edge-to-edge and vertex-to-vertex. Covers polygon triangulation (ear
--  clipping sketch) and point-set triangulation (fan from an interior
--  site, or Bowyer–Watson-lite for small sets). Self-contained: does NOT
--  `with` sibling packages.
--  Primary source:
--  https://en.wikipedia.org/wiki/Triangulation_(geometry)
--  Sibling packages (README only; do not `with`):
--    Ada-Polygon-Triangulation, Ada-Delaunay-Triangulation,
--    Ada-Rupperts-Algorithm — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Triangulation
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   type Real is digits 15;

   --  Soft classroom limit on polygon vertices / point-set sites.
   Max_Points : constant Positive := 64;

   --  An n-gon yields exactly n−2 triangles; a point set yields O(n).
   --  Bowyer–Watson-lite needs temporary headroom (super-triangle).
   Max_Triangles : constant Positive := 256;

   Max_Hole_Edges : constant Positive := 128;

   subtype Point_Count is Natural range 0 .. Max_Points;
   subtype Point_Index is Positive range 1 .. Max_Points + 3;
   --  Indices 1 .. N are user sites/vertices; N+1 .. N+3 may hold
   --  super-triangle vertices during Bowyer–Watson-lite (internal).

   subtype Triangle_Count is Natural range 0 .. Max_Triangles;
   subtype Triangle_Index is Positive range 1 .. Max_Triangles;

   type Point is record
      X, Y : Real := 0.0;
   end record;

   type Point_Array is array (Point_Index range <>) of Point;

   --  Triangle stores three 1-based vertex indices into the dense copy of
   --  the input (Points'First / Polygon'First maps to 1).
   type Triangle is record
      A, B, C : Point_Index := 1;
   end record;

   type Triangle_Array is array (Triangle_Index range <>) of Triangle;

   --  Mesh of triangles (the triangulation result).
   type Mesh is record
      Tris  : Triangle_Array (1 .. Max_Triangles) :=
                [others => (A => 1, B => 1, C => 1)];
      Count : Triangle_Count := 0;
   end record;

   --  Alias kept for readability in drivers / tests.
   subtype Triangulation_Result is Mesh;

   type Bounding_Box is record
      Min_X, Min_Y, Max_X, Max_Y : Real := 0.0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when length < 3, length > Max_Points, near-duplicate sites,
   --  near-degenerate (near-zero area) polygons, or when an educational
   --  driver cannot progress (non-simple polygon / failed cavity).

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
   -- Orientation / area / predicates (educational floating-point)
   ---------------------------------------------------------------------------
   --  Plain Float arithmetic: adequate for well-separated classroom
   --  examples, NOT robust adaptive-precision (Shewchuk) / CGAL.

   function Orient2D (A, B, C : Point) return Real
     with Global => null;
   --  Twice signed area of triangle ABC: (B-A)×(C-A).
   --  > 0 ⇒ C left of directed AB (CCW); < 0 ⇒ right (CW); ≈ 0 ⇒ collinear.

   function CCW (A, B, C : Point) return Boolean
     with Global => null;
   --  True iff Orient2D (A, B, C) > Epsilon.

   function Triangle_Area (A, B, C : Point) return Real
     with Global => null;
   --  Absolute area |Orient2D| / 2.

   function Signed_Area (Polygon : Point_Array) return Real
     with Global => null;
   --  Shoelace (twice signed area): positive for CCW, negative for CW.

   function Area (Polygon : Point_Array) return Real
     with Global => null;
   --  Absolute polygon area |Signed_Area| / 2.

   function Polygon_Triangle_Count (N : Natural) return Natural
     with Global => null;
   --  A simple n-gon (no Steiner points) triangulates into exactly n−2
   --  triangles. Returns 0 when N < 3.

   function Point_In_Triangle
     (P, A, B, C : Point; Strict : Boolean := True) return Boolean
     with Global => null;

   function In_Circumcircle (A, B, C, P : Point) return Boolean
     with Global => null;
   --  True iff P lies strictly inside the circumcircle of CCW triangle ABC.
   --  Used by the embedded Bowyer–Watson-lite sketch.

   ---------------------------------------------------------------------------
   -- Pre-checks
   ---------------------------------------------------------------------------

   function Bounds_Of (Points : Point_Array) return Bounding_Box
     with Pre => Points'Length >= 1, Global => null;

   function Has_Near_Duplicate
     (Points : Point_Array; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Is_Simple_Enough (Polygon : Point_Array) return Boolean
     with Global => null;
   --  Lightweight educational pre-check: n in 3 .. Max_Points, no
   --  consecutive / closing near-duplicates, |Signed_Area| > Epsilon.

   ---------------------------------------------------------------------------
   -- Polygon triangulation (embedded ear clipping)
   ---------------------------------------------------------------------------

   function Triangulate_Polygon (Polygon : Point_Array) return Mesh
     with Global => null;
   --  Triangulate a simple polygon without holes by ear clipping
   --  (two ears theorem; O(n²) educational). Requires length in
   --  3 .. Max_Points and Is_Simple_Enough; otherwise raises
   --  Invalid_Argument. Returns exactly n−2 triangles with 1-based
   --  indices into a dense copy of Polygon.

   ---------------------------------------------------------------------------
   -- Point-set triangulation
   ---------------------------------------------------------------------------

   function Fan_From_Vertex
     (Points : Point_Array; Apex : Point_Index) return Mesh
     with Global => null;
   --  Educational fan: emit △(Apex, i, i+1) for consecutive vertices
   --  around the cyclic order of Points (treated as a simple polygon
   --  ring). Apex must be in 1 .. N (dense). Suitable when Points are
   --  in convex position or star-shaped from Apex. Raises
   --  Invalid_Argument if N < 3, N > Max_Points, or Apex out of range.

   function Fan_From_Interior
     (Points : Point_Array) return Mesh
     with Global => null;
   --  Find an interior site P (strictly inside the convex hull of the
   --  remaining sites, approximated by: P lies inside some triangle of
   --  three hull-ish extremes — educational: pick a site of maximal
   --  depth via winding / left-of-all-hull-edges of Graham-lite). If none
   --  exists, fall back to Fan_From_Vertex from dense index 1 after
   --  sorting is skipped — instead: use angular sort around the
   --  centroid of the bounding box and fan from the first site that
   --  yields positive-area triangles covering the set.
   --  Practical educational policy implemented in the body:
   --    1. Try each site as fan apex of the convex hull ring of the
   --       other sites (star from interior).
   --    2. If no interior site, fan the convex hull from vertex 1 of a
   --       CCW hull ordering (interior sites left for BW path).
   --  Prefer Triangulate_Point_Set for general sets.

   function Triangulate_Point_Set (Points : Point_Array) return Mesh
     with Global => null;
   --  Educational point-set triangulation of Points:
   --    * If some input site lies strictly inside the convex hull of the
   --      others, fan from that interior apex onto a CCW hull ring.
   --    * Otherwise (all sites on the hull) fan the hull from one vertex.
   --    * If the fan path is not applicable (collinear / degenerate) or
   --      there are interior sites that the simple fan cannot cover,
   --      fall back to embedded Bowyer–Watson-lite (Delaunay of the
   --      sites) so every input vertex appears in the mesh.
   --  Requires length in 3 .. Max_Points and no near-duplicates;
   --  otherwise raises Invalid_Argument.

   ---------------------------------------------------------------------------
   -- Mesh accessors
   ---------------------------------------------------------------------------

   function Triangle_Count_Of (T : Mesh) return Triangle_Count
     with Global => null;

   function Get_Triangle
     (T : Mesh; Index : Triangle_Index) return Triangle
     with Pre => Index <= T.Count, Global => null;

   function Uses_Vertex
     (Tri : Triangle; V : Point_Index) return Boolean
     with Global => null;

end Triangulation;
