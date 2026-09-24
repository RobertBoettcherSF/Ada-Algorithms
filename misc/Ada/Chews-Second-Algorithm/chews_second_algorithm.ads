--  Chews_Second_Algorithm — Ada 2023 educational package for Chew's
--  second algorithm: 2-D Delaunay refinement / quality mesh generation
--  with a constrained PSLG and an educational ≥30° minimum-angle target.
--  Insert Steiner points (circumcenters of skinny triangles, or midpoints
--  of segments rejected by the Chew opposite-side / encroachment rule)
--  until every triangle meets the angle bound (or a Steiner budget is
--  exhausted). When a constrained segment is split, previously inserted
--  circumcenter Steiner points inside its diametral ball are removed
--  (Chew-flavored cleanup; educational sketch).
--  Primary source:
--  https://en.wikipedia.org/wiki/Chew's_second_algorithm
--  (Wikipedia redirects to Delaunay refinement; notes distinguish Chew
--  vs Ruppert.)
--  Sibling packages (README only; do not `with`):
--    Ada-Rupperts-Algorithm, Ada-Delaunay-Triangulation (survey),
--    Ada-Bowyer-Watson — planned ahead in the RobertBoettcherSF series.
--  Embedded incremental Delaunay is self-contained (Bowyer–Watson style);
--  this package does NOT `with` sibling triangulation packages.

pragma Ada_2022;

package Chews_Second_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   type Real is digits 15;

   --  Soft classroom limit on total sites after refinement (input + Steiner).
   Max_Points : constant Positive := 64;

   --  Default / soft cap on Steiner insertions per Refine call.
   Max_Steiner_Default : constant Natural := 32;

   --  Educational default minimum angle (degrees). Full Chew is often cited
   --  up to about 28.6°; classroom default uses 30° as a practical target
   --  (termination under Float + budget is not theoretically guaranteed).
   Default_Min_Angle : constant Real := 30.0;

   --  Triangle storage during incremental construction + refinement.
   Max_Triangles : constant Positive := 256;

   --  Hole boundary edges during one Bowyer–Watson insertion.
   Max_Hole_Edges : constant Positive := 128;

   --  Constrained segments (PSLG sketch).
   Max_Segments : constant Positive := 64;

   subtype Point_Count is Natural range 0 .. Max_Points;
   subtype Point_Index is Positive range 1 .. Max_Points + 3;
   --  Indices 1 .. N are sites; N+1 .. N+3 may hold super-triangle
   --  vertices during internal Delaunay construction.

   subtype Triangle_Count is Natural range 0 .. Max_Triangles;
   subtype Triangle_Index is Positive range 1 .. Max_Triangles;

   subtype Segment_Count is Natural range 0 .. Max_Segments;
   subtype Segment_Index is Positive range 1 .. Max_Segments;

   type Point is record
      X, Y : Real := 0.0;
   end record;

   type Point_Array is array (Point_Index range <>) of Point;

   --  Constrained segment: endpoints are 1-based indices into the current
   --  working point table (input sites, later also Steiner midpoints).
   type Segment is record
      A, B : Point_Index := 1;
   end record;

   type Segment_Array is array (Segment_Index range <>) of Segment;

   --  Triangle stores three vertex indices. Orientation is CCW after build.
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

   --  Result of Refine: refined site table + triangulation + Steiner tally.
   type Refine_Result is record
      Points           : Point_Array (1 .. Max_Points) :=
                           [others => (X => 0.0, Y => 0.0)];
      Num_Points       : Point_Count := 0;
      Mesh             : Triangulation;
      Steiner_Inserted : Natural := 0;
      Min_Angle_Achieved : Real := 0.0;
      --  Smallest corner angle (degrees) among output triangles, or 180
      --  if the mesh is empty.
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for too few / too many points, near-duplicates, bad angle
   --  bounds (Min_Angle_Degrees <= 0 or >= 60), or segment indices out
   --  of range / coincident endpoints.

   Capacity_Exceeded : exception;
   --  Raised if internal triangle / hole / point buffers would overflow.

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

   function Dist (A, B : Point) return Real
     with Global => null;
   --  Euclidean distance (Sqrt of Dist2).

   ---------------------------------------------------------------------------
   -- Orientation / predicates (educational floating-point)
   ---------------------------------------------------------------------------
   --  Plain Real arithmetic — adequate for well-separated classroom
   --  examples, NOT robust adaptive-precision predicates (Shewchuk) and
   --  NOT a substitute for Triangle / CGAL.

   function Orient2D (A, B, C : Point) return Real
     with Global => null;
   --  Twice signed area of ABC. > 0 ⇒ CCW; < 0 ⇒ CW; ≈ 0 ⇒ collinear.

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
   -- Quality / angle helpers
   ---------------------------------------------------------------------------

   function Angle_Degrees_At (A, B, C : Point) return Real
     with Global => null;
   --  Interior angle (degrees) at vertex B of triangle ABC, in (0, 180).
   --  Near-degenerate edges may return a clamped educational value.

   function Triangle_Min_Angle_Degrees (A, B, C : Point) return Real
     with Global => null;
   --  Smallest of the three corner angles of triangle ABC (degrees).

   function Is_Skinny
     (A, B, C : Point; Min_Angle_Degrees : Real) return Boolean
     with Pre => Min_Angle_Degrees > 0.0, Global => null;
   --  True iff Triangle_Min_Angle_Degrees (A,B,C) < Min_Angle_Degrees.

   function Aspect_Ratio (A, B, C : Point) return Real
     with Global => null;
   --  Educational R / r proxy: longest_edge / shortest_edge (>= 1).

   ---------------------------------------------------------------------------
   -- Encroachment / Chew opposite-side (educational)
   ---------------------------------------------------------------------------

   function Encroaches_Segment
     (Seg_A, Seg_B, P : Point) return Boolean
     with Global => null;
   --  True iff P lies strictly inside the open diametral circle of segment
   --  Seg_A–Seg_B. Used both for encroachment tests and for Chew's
   --  diametral-ball cleanup of prior circumcenter Steiner points.

   function Point_Encroaches_Any_Segment
     (P        : Point;
      Points   : Point_Array;
      Segments : Segment_Array) return Boolean
     with Global => null;

   function Circumcenter_Opposite_Side
     (Seg_A, Seg_B, Tri_Rep, Circ : Point) return Boolean
     with Global => null;
   --  Chew-flavored rejection: True iff Tri_Rep (e.g. skinny-triangle
   --  centroid) and Circ lie strictly on opposite sides of line Seg_A–Seg_B.
   --  Distinct from Ruppert's pure diametral-encroachment priority queue.

   ---------------------------------------------------------------------------
   -- Bounds / duplicate check
   ---------------------------------------------------------------------------

   function Bounds_Of (Points : Point_Array) return Bounding_Box
     with Pre => Points'Length >= 1, Global => null;

   function Has_Near_Duplicate
     (Points : Point_Array; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Embedded incremental Delaunay (Bowyer–Watson style, self-contained)
   ---------------------------------------------------------------------------

   function Triangulate (Points : Point_Array) return Triangulation
     with Global => null;
   --  2-D Delaunay triangulation via embedded Bowyer–Watson.
   --  Requires Points'Length in 3 .. Max_Points and no near-duplicates;
   --  otherwise raises Invalid_Argument.

   function Triangle_Count_Of (T : Triangulation) return Triangle_Count
     with Global => null;

   function Get_Triangle
     (T : Triangulation; Index : Triangle_Index) return Triangle
     with Pre => Index <= T.Count, Global => null;

   function Shares_Vertex
     (Tri : Triangle; V : Point_Index) return Boolean
     with Global => null;

   function Is_Delaunay_Edge_Empty
     (Points : Point_Array; T : Triangulation) return Boolean
     with Global => null;

   function Mesh_Min_Angle_Degrees
     (Points : Point_Array; T : Triangulation) return Real
     with Global => null;
   --  Minimum corner angle over all triangles in T (degrees). Returns
   --  180.0 if T is empty.

   function Count_Skinny
     (Points : Point_Array;
      T      : Triangulation;
      Min_Angle_Degrees : Real) return Natural
     with Pre => Min_Angle_Degrees > 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Chew's second algorithm refinement
   ---------------------------------------------------------------------------

   function Refine
     (Points            : Point_Array;
      Segments          : Segment_Array;
      Min_Angle_Degrees : Real := Default_Min_Angle;
      Max_Steiner       : Natural := Max_Steiner_Default)
      return Refine_Result
     with Global => null;
   --  Chew-style Delaunay refine of Points with constrained Segments
   --  (PSLG sketch) until every triangle has min angle >=
   --  Min_Angle_Degrees, or Max_Steiner Steiner events have occurred, or
   --  Max_Points capacity is reached.
   --
   --  Steps (Wikipedia / classroom sketch):
   --    1. T := Triangulate (Points)  -- constrained-ish via segment list
   --    2. While skinny triangles remain and budget allows:
   --         c := circumcenter of a skinny triangle t
   --         if c lies on the opposite side of some constrained segment s
   --            as t (Chew rule), OR c encroaches s:
   --              split s at its midpoint; remove prior circumcenter
   --              Steiner points inside the diametral ball of s
   --         else insert c (if inside a slightly expanded bounding box)
   --    3. Retriangulate after each insertion / split.
   --
   --  Contrast with Ruppert (sibling Ada-Rupperts-Algorithm): Ruppert
   --  maintains an explicit encroached-segment queue and prefers splitting
   --  encroached segments before inserting circumcenters; Chew rejects a
   --  circumcenter that falls across a segment and cleans diametral-ball
   --  Steiner points on split. Educational Float caps do NOT claim Chew's
   --  ~28.6° termination guarantee.
   --
   --  Raises Invalid_Argument if Points'Length < 3, > Max_Points,
   --  near-duplicates, Min_Angle_Degrees <= 0.0 or >= 60.0, or bad
   --  segment indices / coincident endpoints. Empty Segments is allowed
   --  (point-set-only refinement).

   function Get_Point
     (R : Refine_Result; Index : Point_Index) return Point
     with Pre => Index <= R.Num_Points, Global => null;

   function Result_Point_Count (R : Refine_Result) return Point_Count
     with Global => null;

end Chews_Second_Algorithm;
