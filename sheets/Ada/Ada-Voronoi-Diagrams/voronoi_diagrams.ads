--  Voronoi_Diagrams — Ada 2023 educational survey of 2-D Voronoi diagrams.
--  Partition of the plane into cells of nearest sites; dual of the Delaunay
--  triangulation. This classroom sketch builds a small Delaunay mesh via an
--  embedded Bowyer–Watson-style incremental procedure, then derives Voronoi
--  vertices (circumcenters) and dual edges (bounded segments / unbounded rays).
--  Primary source:
--  https://en.wikipedia.org/wiki/Voronoi_diagram
--  Sibling packages (README only; do not `with`):
--    Ada-Bowyer-Watson, Ada-Fortunes-Algorithm, Ada-Delaunay-Triangulation
--    — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Voronoi_Diagrams
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   type Real is digits 15;

   --  Soft classroom limit on input sites (plus 3 reserved super vertices).
   Max_Sites : constant Positive := 64;

   Max_Triangles : constant Positive := 256;
   Max_Hole_Edges : constant Positive := 128;

   --  One Voronoi vertex per Delaunay triangle; dual edges O(triangles).
   Max_Voronoi_Vertices : constant Positive := Max_Triangles;
   Max_Voronoi_Edges    : constant Positive := 512;

   subtype Site_Count is Natural range 0 .. Max_Sites;
   subtype Site_Index is Positive range 1 .. Max_Sites + 3;
   --  Indices 1 .. N are user sites; N+1 .. N+3 may hold super-triangle
   --  vertices during Delaunay construction (internal).

   subtype Triangle_Count is Natural range 0 .. Max_Triangles;
   subtype Triangle_Index is Positive range 1 .. Max_Triangles;

   subtype Voronoi_Vertex_Count is Natural range 0 .. Max_Voronoi_Vertices;
   subtype Voronoi_Vertex_Index is Positive range 1 .. Max_Voronoi_Vertices;

   subtype Voronoi_Edge_Count is Natural range 0 .. Max_Voronoi_Edges;
   subtype Voronoi_Edge_Index is Positive range 1 .. Max_Voronoi_Edges;

   type Point is record
      X, Y : Real := 0.0;
   end record;

   type Point_Array is array (Site_Index range <>) of Point;

   --  Triangle stores three vertex indices into the working point table.
   --  Orientation of (A,B,C) is counterclockwise after construction.
   type Triangle is record
      A, B, C : Site_Index := 1;
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
   -- Voronoi mesh (educational dual of Delaunay)
   ---------------------------------------------------------------------------

   --  Voronoi vertex = circumcenter of one Delaunay triangle.
   type Voronoi_Vertex is record
      Location          : Point := (0.0, 0.0);
      Source_Triangle   : Triangle_Index := 1;
   end record;

   type Voronoi_Vertex_Array is
     array (Voronoi_Vertex_Index range <>) of Voronoi_Vertex;

   --  Dual to a Delaunay edge between Site_A and Site_B.
   --  Bounded: segment between two circumcenters (V_From .. V_To).
   --  Unbounded: ray from V_From in Direction (perpendicular bisector
   --  of Site_A–Site_B, oriented outward from the hull). V_To unused.
   type Voronoi_Edge is record
      Site_A, Site_B : Site_Index := 1;
      Bounded        : Boolean := True;
      V_From, V_To   : Voronoi_Vertex_Index := 1;
      Direction      : Point := (0.0, 0.0);
   end record;

   type Voronoi_Edge_Array is
     array (Voronoi_Edge_Index range <>) of Voronoi_Edge;

   type Voronoi_Diagram is record
      Site_N    : Site_Count := 0;
      Sites     : Point_Array (1 .. Max_Sites) := [others => (0.0, 0.0)];
      Delaunay  : Triangulation;
      Vertices  : Voronoi_Vertex_Array (1 .. Max_Voronoi_Vertices) :=
                    [others => (Location => (0.0, 0.0), Source_Triangle => 1)];
      Vertex_N  : Voronoi_Vertex_Count := 0;
      Edges     : Voronoi_Edge_Array (1 .. Max_Voronoi_Edges) :=
                    [others => <>];
      Edge_N    : Voronoi_Edge_Count := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when Sites'Length < 1 (Nearest_Site) or < 3 (Delaunay /
   --  Build_Voronoi), Sites'Length > Max_Sites, or near-duplicate sites.

   Capacity_Exceeded : exception;
   --  Raised if internal buffers would overflow (should not occur for
   --  Max_Sites educational inputs).

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
   --  Euclidean distance (Sqrt of Dist2).

   ---------------------------------------------------------------------------
   -- Orientation / predicates (educational floating-point)
   ---------------------------------------------------------------------------
   --  Classroom Float predicates — NOT robust adaptive-precision
   --  (Shewchuk) and NOT a substitute for CGAL / exact kernels.

   function Orient2D (A, B, C : Point) return Real
     with Global => null;
   --  Twice signed area of triangle ABC: (B-A)×(C-A).
   --  > 0 ⇒ C left of directed AB (CCW); < 0 ⇒ right (CW); ≈ 0 ⇒ collinear.

   function CCW (A, B, C : Point) return Boolean
     with Global => null;

   function In_Circumcircle (A, B, C, P : Point) return Boolean
     with Global => null;
   --  True iff P lies strictly inside the circumcircle of CCW triangle ABC.

   function Circumcenter (A, B, C : Point) return Point
     with Global => null;

   function Circumradius2 (A, B, C : Point) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- Perpendicular bisector concepts (educational)
   ---------------------------------------------------------------------------

   function Midpoint (A, B : Point) return Point
     with Global => null;
   --  Midpoint of segment AB — lies on the perpendicular bisector.

   function Perpendicular_Direction (A, B : Point) return Point
     with Global => null;
   --  A unit-ish perpendicular to AB: (-(By-Ay), Bx-Ax) normalized when
   --  possible. The Voronoi edge dual to Delaunay edge AB lies on the
   --  perpendicular bisector of AB (all points equidistant from A and B).

   function On_Perpendicular_Bisector
     (Q, A, B : Point; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True iff Dist(Q,A) ≈ Dist(Q,B) within Tol (equidistance test).

   ---------------------------------------------------------------------------
   -- Bounding box / duplicate check
   ---------------------------------------------------------------------------

   function Bounds_Of (Points : Point_Array) return Bounding_Box
     with Pre => Points'Length >= 1, Global => null;

   function Has_Near_Duplicate
     (Points : Point_Array; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Embedded Bowyer–Watson-style Delaunay (copied helpers; no sibling with)
   ---------------------------------------------------------------------------

   function Delaunay_From_Sites (Sites : Point_Array) return Triangulation
     with Global => null;
   --  Incremental Delaunay triangulation of Sites (educational Float).
   --  Requires Sites'Length in 3 .. Max_Sites and no near-duplicates;
   --  otherwise raises Invalid_Argument. Triangle vertex indices are
   --  1-based in Sites order (Sites'First mapped to 1).

   function Triangle_Count_Of (T : Triangulation) return Triangle_Count
     with Global => null;

   function Get_Triangle
     (T : Triangulation; Index : Triangle_Index) return Triangle
     with Pre => Index <= T.Count, Global => null;

   function Shares_Vertex
     (Tri : Triangle; V : Site_Index) return Boolean
     with Global => null;

   function Is_Delaunay_Empty_Circle
     (Sites : Point_Array; T : Triangulation) return Boolean
     with Global => null;
   --  Empty-circumcircle check for every triangle vs every other site.

   ---------------------------------------------------------------------------
   -- Voronoi construction / nearest-site membership
   ---------------------------------------------------------------------------

   function Build_Voronoi (Sites : Point_Array) return Voronoi_Diagram
     with Global => null;
   --  1. Delaunay_From_Sites (Sites).
   --  2. Voronoi vertex i := Circumcenter of Delaunay triangle i.
   --  3. For each Delaunay edge:
   --       shared by two triangles → bounded Voronoi segment between
   --         the two circumcenters;
   --       on the convex hull (one triangle) → unbounded ray from that
   --         circumcenter along the outward perpendicular bisector.
   --  Raises Invalid_Argument under the same guards as Delaunay_From_Sites.

   function Nearest_Site
     (Query : Point; Sites : Point_Array) return Site_Index
     with Global => null;
   --  Brute-force Voronoi cell membership: index (1-based in Sites order)
   --  of the site closest to Query (ties: smallest index). Raises
   --  Invalid_Argument if Sites'Length = 0 or Sites'Length > Max_Sites.

   function Voronoi_Vertex_Count_Of
     (V : Voronoi_Diagram) return Voronoi_Vertex_Count
     with Global => null;

   function Voronoi_Edge_Count_Of
     (V : Voronoi_Diagram) return Voronoi_Edge_Count
     with Global => null;

   function Get_Voronoi_Vertex
     (V : Voronoi_Diagram; Index : Voronoi_Vertex_Index) return Voronoi_Vertex
     with Pre => Index <= V.Vertex_N, Global => null;

   function Get_Voronoi_Edge
     (V : Voronoi_Diagram; Index : Voronoi_Edge_Index) return Voronoi_Edge
     with Pre => Index <= V.Edge_N, Global => null;

   function Count_Bounded_Edges (V : Voronoi_Diagram) return Natural
     with Global => null;

   function Count_Unbounded_Edges (V : Voronoi_Diagram) return Natural
     with Global => null;

end Voronoi_Diagrams;
