--  Marching_Triangles — Ada 2023 educational package for marching
--  triangles: surface reconstruction from a 3-D point cloud into a
--  polygon mesh via seed-triangle selection and advancing-front growth.
--  Faster classroom alternative to full 3-D Delaunay / Bowyer–Watson
--  surface reconstruction. Distinct from Marching Cubes (isosurface
--  extraction on a scalar grid).
--  Primary source:
--  https://en.wikipedia.org/wiki/Marching_triangles
--  Sibling packages (README only; do not `with`):
--    Ada-Marching-Cubes, Ada-Marching-Squares, Ada-Marching-Tetrahedrons,
--    Ada-Bowyer-Watson, Ada-Polygon-Triangulation —
--    RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Marching_Triangles
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   type Real is digits 15;

   --  Soft classroom limit on input cloud points.
   Max_Points : constant Positive := 64;

   --  A simple surface on N points has O(N) triangles; keep a generous
   --  fixed buffer for the educational advancing-front sketch.
   Max_Triangles : constant Positive := 192;

   --  Frontier / boundary edge capacity during growth.
   Max_Boundary_Edges : constant Positive := 256;

   subtype Point_Count is Natural range 0 .. Max_Points;
   subtype Point_Index is Positive range 1 .. Max_Points;

   subtype Triangle_Count is Natural range 0 .. Max_Triangles;
   subtype Triangle_Index is Positive range 1 .. Max_Triangles;

   subtype Edge_Count is Natural range 0 .. Max_Boundary_Edges;
   subtype Edge_Index is Positive range 1 .. Max_Boundary_Edges;

   --  3-D sample on the unknown surface.
   type Point3 is record
      X, Y, Z : Real := 0.0;
   end record;

   --  Unorganized point cloud (indices relative to Cloud'First → 1).
   type Point_Array is array (Point_Index range <>) of Point3;

   --  Mesh face: three vertex indices into the input cloud
   --  (1-based after remapping Cloud'First → 1).
   type Triangle is record
      A, B, C : Point_Index := 1;
   end record;

   type Triangle_Array is array (Triangle_Index range <>) of Triangle;

   type Mesh is record
      Tris  : Triangle_Array (1 .. Max_Triangles) :=
                [others => (A => 1, B => 1, C => 1)];
      Count : Triangle_Count := 0;
   end record;

   --  Undirected edge key (Lo <= Hi) for boundary-set membership.
   type Edge_Key is record
      Lo, Hi : Point_Index := 1;
   end record;

   type Edge_Key_Array is array (Edge_Index range <>) of Edge_Key;

   type Boundary_Edge_Set is record
      Edges : Edge_Key_Array (1 .. Max_Boundary_Edges) :=
                [others => (Lo => 1, Hi => 1)];
      Count : Edge_Count := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when Cloud'Length < 3, Cloud'Length > Max_Points, when
   --  near-duplicate samples are detected, or when no non-degenerate
   --  seed triangle can be formed (educational policy).

   Capacity_Exceeded : exception;
   --  Raised if triangle / frontier buffers would overflow (should not
   --  occur for Max_Points educational inputs).

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near_Point (A, B : Point3; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Dist3 (A, B : Point3) return Real
     with Global => null;
   --  Euclidean distance in R^3.

   function Dist3_Squared (A, B : Point3) return Real
     with Global => null;
   --  Squared Euclidean distance (avoids a sqrt in comparisons).

   function Dot (U, V : Point3) return Real
     with Global => null;
   --  Treat Point3 as a free vector for educational vector algebra.

   function Cross (U, V : Point3) return Point3
     with Global => null;
   --  3-D cross product U × V.

   function Sub (A, B : Point3) return Point3
     with Global => null;
   --  Vector A − B.

   function Length (V : Point3) return Real
     with Global => null;

   function Normalize (V : Point3) return Point3
     with Global => null;
   --  Unit vector; returns (0,0,0) if ||V|| ≤ Epsilon.

   ---------------------------------------------------------------------------
   -- Triangle / edge helpers
   ---------------------------------------------------------------------------

   function Normal_Of_Triangle (A, B, C : Point3) return Point3
     with Global => null;
   --  Unit normal of triangle ABC via (B−A)×(C−A). Zero if degenerate.

   function Triangle_Area (A, B, C : Point3) return Real
     with Global => null;
   --  ½ ||(B−A)×(C−A)||.

   function Make_Edge_Key (I, J : Point_Index) return Edge_Key
     with Global => null;
   --  Canonical undirected key with Lo = min(I,J), Hi = max(I,J).

   function Same_Edge (E1, E2 : Edge_Key) return Boolean
     with Global => null;

   function Contains_Edge
     (Set : Boundary_Edge_Set; Key : Edge_Key) return Boolean
     with Global => null;

   procedure Toggle_Boundary_Edge
     (Set : in out Boundary_Edge_Set; Key : Edge_Key)
     with Global => null;
   --  Educational boundary maintenance: if Key is already on the frontier,
   --  remove it (interior edge); otherwise insert it. Raises
   --  Capacity_Exceeded if the set would grow past Max_Boundary_Edges.

   function Has_Near_Duplicate
     (Cloud : Point_Array; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Seed selection / advancing front (documented heuristics)
   ---------------------------------------------------------------------------
   --  Heuristics (classroom sketch, not CGAL Advancing Front):
   --    1. Seed: among all triples with positive area, pick the triangle
   --       of smallest perimeter that still has area > Area_Tol. Prefer
   --       locally compact seeds over long skinny ones.
   --    2. Frontier: maintain the undirected boundary edge set of the
   --       current mesh. Each new triangle toggles its three edges.
   --    3. Grow: for each frontier edge (I,J), consider unused points P
   --       within Candidate_Radius_Factor · ||Pi−Pj|| of the edge midpoint.
   --       Score = Dist3(P, midpoint) + sliver penalty; require the new
   --       triangle area > Area_Tol. Reject same-side nearly-coplanar
   --       candidates (avoids double-covering planar patches); allow
   --       opposite-side or significantly out-of-plane points (patches
   --       and small polyhedra). Prefer the smallest score. Mark P used
   --       once attached.
   --    4. Stop when no frontier edge admits a valid unused candidate,
   --       or all points are used / Max_Triangles is reached.
   --  This is intentionally simpler than full 3-D Delaunay filtering or
   --  CGAL's radius/plausibility priority queue.

   Area_Tol : constant Real := 1.0E-12;
   Candidate_Radius_Factor : constant Real := 2.5;

   function Find_Seed_Triangle
     (Cloud : Point_Array) return Triangle
     with Global => null;
   --  Returns a seed Triangle (indices remapped so Cloud'First → 1).
   --  Raises Invalid_Argument if no non-degenerate seed exists.

   function Reconstruct_Mesh (Cloud : Point_Array) return Mesh
     with Global => null;
   --  Marching-triangles advancing-front reconstruction of Cloud.
   --  Requires Cloud'Length in 3 .. Max_Points and no near-duplicates;
   --  otherwise raises Invalid_Argument. Returns triangles whose vertex
   --  indices are 1-based relative to Cloud'First mapped to 1.

   function Triangle_Count_Of (M : Mesh) return Triangle_Count
     with Global => null;

   function Get_Triangle
     (M : Mesh; Index : Triangle_Index) return Triangle
     with Pre => Index <= M.Count, Global => null;

   function All_Indices_In_Range
     (M : Mesh; N : Point_Count) return Boolean
     with Pre => N >= 1, Global => null;
   --  True iff every vertex index of every triangle lies in 1 .. N.

end Marching_Triangles;
