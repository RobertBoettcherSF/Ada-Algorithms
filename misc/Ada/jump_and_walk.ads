--  Jump_And_Walk — Ada 2023 educational package for the Jump-and-Walk
--  algorithm: point location in a planar triangulation with almost no
--  preprocessing. Sample a few candidate triangles (the "jump"), start
--  from the one whose centroid is closest to the query Q, then walk
--  triangle-to-triangle toward Q (Lawson / Green–Sibson style) until the
--  containing simplex is found. Predecessor walks pick a single random
--  start; Jump-and-Walk improves the start by a cheap random sample.
--  Used in practice by Qhull, Triangle, and CGAL.
--  Primary source:
--  https://en.wikipedia.org/wiki/Jump-and-Walk_algorithm
--  Sibling packages (README only; do not `with`):
--    Ada-GJK, Ada-Geometric-Hashing — planned ahead in the
--    RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Jump_And_Walk
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   type Real is digits 15;

   Max_Points    : constant Positive := 64;
   Max_Triangles : constant Positive := 64;

   subtype Point_Count is Natural range 0 .. Max_Points;
   subtype Point_Index is Positive range 1 .. Max_Points;

   subtype Triangle_Count is Natural range 0 .. Max_Triangles;
   subtype Triangle_Index is Positive range 1 .. Max_Triangles;

   --  Neighbor across an edge: triangle index, or -1 for a boundary edge.
   subtype Neighbor_Id is Integer range -1 .. Max_Triangles;

   type Point is record
      X, Y : Real := 0.0;
   end record;

   type Point_Array is array (Point_Index range <>) of Point;

   --  Triangle stores three vertex indices into Mesh.Points.
   --  Orientation of (A,B,C) should be counterclockwise for consistent walks.
   type Triangle is record
      A, B, C : Point_Index := 1;
   end record;

   type Triangle_Array is array (Triangle_Index range <>) of Triangle;

   --  Neighbors(T).N1 = triangle across edge BC (opposite A), or -1.
   --  Neighbors(T).N2 = triangle across edge CA (opposite B), or -1.
   --  Neighbors(T).N3 = triangle across edge AB (opposite C), or -1.
   type Adjacency is record
      N1, N2, N3 : Neighbor_Id := -1;
   end record;

   type Adjacency_Array is array (Triangle_Index range <>) of Adjacency;

   type Mesh is record
      Points         : Point_Array (1 .. Max_Points) :=
                         [others => (X => 0.0, Y => 0.0)];
      Num_Points     : Point_Count := 0;
      Tris           : Triangle_Array (1 .. Max_Triangles) :=
                         [others => (A => 1, B => 1, C => 1)];
      Neighbors      : Adjacency_Array (1 .. Max_Triangles) :=
                         [others => (N1 => -1, N2 => -1, N3 => -1)];
      Num_Triangles  : Triangle_Count := 0;
   end record;

   --  Locate result: 0 ⇒ not found (empty mesh rejected separately;
   --  walk exited across a boundary ⇒ query treated as outside).
   subtype Locate_Result is Natural range 0 .. Max_Triangles;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when Mesh.Num_Triangles = 0 (empty mesh), or when a fan /
   --  mesh builder receives too few / too many points.

   Capacity_Exceeded : exception;
   --  Raised if a builder would exceed Max_Points / Max_Triangles.

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
   -- Orientation / point-in-triangle (educational floating-point)
   ---------------------------------------------------------------------------
   --  Predicates use plain Float arithmetic. Adequate for classroom
   --  examples with well-separated sites; NOT robust adaptive-precision
   --  predicates (Shewchuk) and NOT a CGAL / exact geometric kernel.

   function Orient2D (A, B, C : Point) return Real
     with Global => null;
   --  Twice signed area of triangle ABC: (B-A)×(C-A).
   --  > 0 ⇒ C left of directed AB (CCW); < 0 ⇒ right (CW); ≈ 0 ⇒ collinear.

   function CCW (A, B, C : Point) return Boolean
     with Global => null;
   --  True iff Orient2D (A, B, C) > Epsilon.

   function Point_In_Triangle
     (Q : Point; A, B, C : Point) return Boolean
     with Global => null;
   --  True iff Q lies in the closed triangle ABC (same half-plane for each
   --  oriented edge, allowing the Epsilon band on the boundary). Assumes
   --  ABC is oriented counterclockwise (Orient2D (A,B,C) > 0).

   function Point_In_Triangle
     (Q : Point; M : Mesh; T : Triangle_Index) return Boolean
     with Pre => T <= M.Num_Triangles, Global => null;

   function Centroid (A, B, C : Point) return Point
     with Global => null;

   function Centroid (M : Mesh; T : Triangle_Index) return Point
     with Pre => T <= M.Num_Triangles, Global => null;

   ---------------------------------------------------------------------------
   -- Mesh accessors / educational fan builder
   ---------------------------------------------------------------------------

   function Triangle_Count_Of (M : Mesh) return Triangle_Count
     with Global => null;

   function Get_Triangle (M : Mesh; Index : Triangle_Index) return Triangle
     with Pre => Index <= M.Num_Triangles, Global => null;

   function Get_Neighbors (M : Mesh; Index : Triangle_Index) return Adjacency
     with Pre => Index <= M.Num_Triangles, Global => null;

   function Build_Convex_Fan (Points : Point_Array) return Mesh
     with Global => null;
   --  Fan triangulation of a strictly convex polygon given in CCW order:
   --  triangles (1, i, i+1) for i = 2 .. N-1, with opposite-edge adjacency
   --  filled and outer edges marked -1. Requires Points'Length in 3 ..
   --  Max_Points; otherwise raises Invalid_Argument. Does not verify
   --  convexity (educational caller contract).

   ---------------------------------------------------------------------------
   -- Walk (Lawson / Green–Sibson) — pure teaching primitive
   ---------------------------------------------------------------------------

   function Walk_From
     (Query : Point;
      M     : Mesh;
      Start : Triangle_Index) return Locate_Result
     with Pre => Start <= M.Num_Triangles and then M.Num_Triangles > 0,
          Global => null;
   --  From Start, step across the edge that separates the current triangle
   --  from Query until Point_In_Triangle holds, or a boundary neighbor (-1)
   --  is encountered. Returns the containing triangle index, or 0 if the
   --  walk exits the mesh (Query treated as outside / not found).
   --  Educational: no cycle detection beyond a hard step limit of
   --  Max_Triangles; a corrupted adjacency table may return 0.

   ---------------------------------------------------------------------------
   -- Jump-and-Walk locate
   ---------------------------------------------------------------------------

   Default_Sample_Count : constant Positive := 8;
   --  Educational sample budget for the jump phase (clamped to mesh size).

   function Locate
     (Query : Point;
      M     : Mesh;
      Seed  : Natural := 0) return Locate_Result;
   --  Jump-and-Walk point location. Raises Invalid_Argument if
   --  M.Num_Triangles = 0. Samples up to Default_Sample_Count triangle
   --  indices (seeded RNG; Seed = 0 uses a fixed educational default),
   --  picks the sample whose centroid is closest to Query (squared
   --  distance), then Walk_From that start. Returns 0 if the walk exits
   --  (Query outside the triangulated domain).

   function Locate_Jump_And_Walk
     (Query         : Point;
      M             : Mesh;
      Seed          : Natural := 0;
      Sample_Count  : Positive := Default_Sample_Count) return Locate_Result;
   --  Same as Locate with an explicit jump sample budget (clamped to
   --  M.Num_Triangles). Raises Invalid_Argument on an empty mesh.

end Jump_And_Walk;
