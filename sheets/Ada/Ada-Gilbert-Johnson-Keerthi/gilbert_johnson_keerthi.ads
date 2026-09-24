--  Gilbert_Johnson_Keerthi — Ada 2023 educational package for the
--  Gilbert–Johnson–Keerthi (GJK) distance algorithm in 2-D: minimum
--  distance between two convex polygons via Minkowski difference and
--  an iterative simplex search toward the origin, driven by support
--  functions. Primary source:
--  https://en.wikipedia.org/wiki/Gilbert–Johnson–Keerthi_distance_algorithm
--  Sibling packages (README only; do not `with`):
--    Ada-Rotating-Calipers, Ada-Shoelace-Algorithm,
--    Ada-Collision-Detection / Ada-Geometric-Hashing (ahead) —
--    RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Gilbert_Johnson_Keerthi
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   --  Soft classroom limit on polygon vertices.
   Max_Vertices : constant Positive := 32;

   --  Soft classroom limit on GJK outer iterations.
   Max_Iterations : constant Positive := 64;

   subtype Vertex_Count is Natural range 0 .. Max_Vertices;
   subtype Vertex_Index is Positive range 1 .. Max_Vertices;

   type Point is record
      X, Y : Real := 0.0;
   end record;

   --  Educational alias: a free vector is stored the same way as a point.
   subtype Vec2 is Point;

   --  Convex polygon vertices in counterclockwise (CCW) order around the
   --  boundary (open ring; helpers close with wrap-around). Call
   --  Ensure_Convex_CCW to validate / normalize, or pass an already
   --  convex CCW polygon to Distance / Intersect / Support.
   type Point_Array is array (Vertex_Index range <>) of Point;

   --  Educational alias: a polygon is just an ordered vertex array.
   subtype Polygon is Point_Array;

   --  Compact result of a GJK distance query.
   type Distance_Result is record
      Distance    : Real := 0.0;     --  ‖closest point on A−B to origin‖
      Intersecting : Boolean := False;
      Iterations  : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when a polygon is empty, has fewer than 3 vertices, exceeds
   --  Max_Vertices, or is not strictly convex (as documented: callers must
   --  supply convex polygons, or use Ensure_Convex_CCW first).

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
   --  Squared Euclidean distance (B − A)·(B − A).

   function Dist (A, B : Point) return Real
     with Global => null;
   --  Euclidean distance √Dist2 (A, B).

   function Norm2 (V : Vec2) return Real
     with Global => null;
   --  Squared length V·V.

   function Norm (V : Vec2) return Real
     with Global => null;
   --  Euclidean length ‖V‖₂.

   function Cross (Ax, Ay, Bx, By : Real) return Real
     with Global => null;
   --  2D cross product A×B = Ax·By − Ay·Bx (signed parallelogram area).

   function Cross (A, B : Point) return Real
     with Global => null;
   --  Cross of vectors A and B as points-from-origin: A.X·B.Y − A.Y·B.X.

   function Dot (A, B : Point) return Real
     with Global => null;
   --  Dot product A·B = A.X·B.X + A.Y·B.Y.

   function Sub (A, B : Point) return Point
     with Global => null;
   --  Vector difference A − B.

   function Add (A, B : Point) return Point
     with Global => null;
   --  Vector sum A + B.

   function Scale (V : Vec2; S : Real) return Vec2
     with Global => null;
   --  Scalar multiple S · V.

   function Negate (V : Vec2) return Vec2
     with Global => null;
   --  −V.

   function Orient2D (A, B, C : Point) return Real
     with Global => null;
   --  Twice signed area of triangle ABC: (B−A)×(C−A).
   --  > 0 ⇒ C left of directed AB (CCW); < 0 ⇒ right (CW); ≈ 0 ⇒ collinear.

   function Perp (V : Vec2) return Vec2
     with Global => null;
   --  Left perpendicular (−V.Y, V.X).

   ---------------------------------------------------------------------------
   -- Polygon measures / validation
   ---------------------------------------------------------------------------

   function Signed_Area (Poly : Polygon) return Real
     with Global => null;
   --  Shoelace signed area (with 1/2). Positive for CCW.
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Vertices.

   function Is_Convex (Poly : Polygon) return Boolean
     with Global => null;
   --  True iff every turn is a strict left turn (CCW) or every turn is a
   --  strict right turn (CW), i.e. the polygon is strictly convex.
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Vertices.

   function Is_CCW (Poly : Polygon) return Boolean
     with Global => null;
   --  True iff Signed_Area (Poly) > Epsilon.
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Vertices.

   function Ensure_Convex_CCW (Poly : Polygon) return Polygon
     with Global => null;
   --  Validate n ∈ 3 .. Max_Vertices and strict convexity; return a dense
   --  1 .. n copy in CCW order (reverse if the input was CW). Raises
   --  Invalid_Argument if not strictly convex or out of range.
   --  Distance / Intersect call this internally.

   function Centroid (Poly : Polygon) return Point
     with Global => null;
   --  Arithmetic mean of the vertices (educational; not area-weighted).
   --  Raises Invalid_Argument if Poly'Length = 0 or > Max_Vertices.

   ---------------------------------------------------------------------------
   -- Support functions (GJK building blocks)
   ---------------------------------------------------------------------------

   function Support (Poly : Polygon; Direction : Vec2) return Point
     with Global => null;
   --  Farthest vertex of Poly in Direction: argmax_v  v · Direction.
   --  Ties break toward the first maximizing index in dense order.
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Vertices.
   --  Does not require convexity for a well-defined farthest vertex, but
   --  GJK correctness needs convex polygons (documented / validated by
   --  Distance / Intersect via Ensure_Convex_CCW).

   function Support_Minkowski
     (A, B : Polygon; Dir : Vec2) return Point
     with Global => null;
   --  Support of the Minkowski difference A − B:
   --    Support (A, Dir) − Support (B, −Dir).
   --  Raises Invalid_Argument if either polygon is out of range.

   ---------------------------------------------------------------------------
   -- GJK distance / intersection
   ---------------------------------------------------------------------------
   --  Classical GJK (Gilbert, Johnson & Keerthi 1988): iteratively grow a
   --  simplex on the Minkowski difference C = A − B toward the origin,
   --  using only support queries. In 2-D the simplex is a point, a
   --  segment, or a triangle. If the origin lies in C the shapes
   --  intersect (distance 0); otherwise the closest feature of the
   --  simplex to the origin yields the separation distance.
   --
   --  Floating-point arithmetic is educational — adequate for well-
   --  separated classroom examples, not a production exact kernel.

   function Distance (A, B : Polygon) return Real
     with Global => null;
   --  Minimum Euclidean distance between convex polygons A and B.
   --  Returns 0 when they intersect or touch. O(k · (n_A + n_B)) with
   --  k ≤ Max_Iterations support steps. Raises Invalid_Argument if
   --  either polygon is empty / nonconvex-as-documented.

   function Distance_Info (A, B : Polygon) return Distance_Result
     with Global => null;
   --  Same as Distance, plus Intersecting flag and iteration count.

   function Intersect (A, B : Polygon) return Boolean
     with Global => null;
   --  True iff convex polygons A and B have nonempty intersection
   --  (including boundary touch). Educational GJK boolean loop.
   --  Raises Invalid_Argument if either polygon is invalid.

   function Distance_Squared (A, B : Polygon) return Real
     with Global => null;
   --  Squared minimum distance (avoids a final square root when separated).

   ---------------------------------------------------------------------------
   -- Teaching helpers
   ---------------------------------------------------------------------------

   function Regular_Polygon
     (N      : Vertex_Count;
      Radius : Real;
      Center : Point := (X => 0.0, Y => 0.0);
      Phase  : Real := 0.0) return Polygon
     with Global => null;
   --  Regular N-gon approximating a circle of given Radius about Center.
   --  Vertices at Center + Radius · (cos(Phase + 2π i/N), sin(...)).
   --  Raises Invalid_Argument if N < 3 or N > Max_Vertices, or Radius ≤ 0.

   function Axis_Aligned_Square
     (Center : Point; Half_Side : Real) return Polygon
     with Global => null;
   --  Axis-aligned square [Center.X±Half_Side] × [Center.Y±Half_Side] as
   --  a CCW 4-gon. Raises Invalid_Argument if Half_Side ≤ 0.

end Gilbert_Johnson_Keerthi;
