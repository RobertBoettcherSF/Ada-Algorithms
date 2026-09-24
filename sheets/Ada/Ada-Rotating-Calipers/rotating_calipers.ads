--  Rotating_Calipers — Ada 2023 educational package for the rotating
--  calipers method on a convex polygon: antipodal pairs, diameter
--  (maximum vertex distance), and width (minimum distance between
--  parallel supporting lines). Optionally sketches a minimum-area
--  oriented bounding rectangle.
--  Primary source:
--  https://en.wikipedia.org/wiki/Rotating_calipers
--  Sibling packages (README only; do not `with`):
--    Ada-Shoelace-Algorithm, Ada-Polygon-Triangulation,
--    Ada-Convex-Hull / Ada-Minimum-Bounding-Box (ahead) —
--    RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Rotating_Calipers
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   --  Soft classroom limit on polygon vertices.
   Max_Vertices : constant Positive := 64;

   subtype Vertex_Count is Natural range 0 .. Max_Vertices;
   subtype Vertex_Index is Positive range 1 .. Max_Vertices;

   type Point is record
      X, Y : Real := 0.0;
   end record;

   --  Convex polygon vertices in counterclockwise (CCW) order around the
   --  boundary (open ring; helpers close with wrap-around). Call
   --  Ensure_Convex_CCW to validate / normalize, or pass an already
   --  convex CCW polygon to Diameter / Width / Antipodal_Pairs.
   type Point_Array is array (Vertex_Index range <>) of Point;

   --  Educational alias: a polygon is just an ordered vertex array.
   subtype Polygon is Point_Array;

   --  One antipodal pair of vertex indices (1-based into the dense
   --  copy used by caliper routines: Polygon'First maps to 1).
   type Antipodal_Pair is record
      I, J : Vertex_Index := 1;
   end record;

   --  Buffer sized for O(n) antipodal pairs on Max_Vertices.
   Max_Pairs : constant Positive := 2 * Max_Vertices;

   subtype Pair_Count is Natural range 0 .. Max_Pairs;
   subtype Pair_Index is Positive range 1 .. Max_Pairs;

   type Antipodal_Pair_Array is array (Pair_Index range <>) of Antipodal_Pair;

   type Antipodal_List is record
      Pairs : Antipodal_Pair_Array (1 .. Max_Pairs) :=
                [others => (I => 1, J => 1)];
      Count : Pair_Count := 0;
   end record;

   --  Oriented bounding rectangle (axis-aligned in a rotated frame).
   --  Educational sketch: corners of a candidate min-area OBB.
   type Bounding_Rect is record
      Corner   : Point_Array (1 .. 4) := [others => (X => 0.0, Y => 0.0)];
      Area     : Real := 0.0;
      Width    : Real := 0.0;
      Height   : Real := 0.0;
      Angle    : Real := 0.0;  --  edge direction of the flush caliper (radians)
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when Polygon'Length < 3 or > Max_Vertices, when the polygon
   --  is not strictly convex (or near-degenerate), or when caliper
   --  buffers would overflow (should not occur for Max_Vertices inputs).

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

   function Cross (Ax, Ay, Bx, By : Real) return Real
     with Global => null;
   --  2D cross product A×B = Ax·By − Ay·Bx (signed parallelogram area).

   function Cross (A, B : Point) return Real
     with Global => null;
   --  Cross of vectors A and B as points-from-origin: A.X·B.Y − A.Y·B.X.

   function Dot (A, B : Point) return Real
     with Global => null;
   --  Dot product A·B = A.X·B.X + A.Y·B.Y.

   function Orient2D (A, B, C : Point) return Real
     with Global => null;
   --  Twice signed area of triangle ABC: (B−A)×(C−A).
   --  > 0 ⇒ C left of directed AB (CCW); < 0 ⇒ right (CW); ≈ 0 ⇒ collinear.

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
   --  Caliper entry points call this internally.

   ---------------------------------------------------------------------------
   -- Rotating calipers
   ---------------------------------------------------------------------------
   --  Classical idea (Shamos 1978; phrase coined by Toussaint): rotate a
   --  pair of parallel supporting lines ("calipers") around a convex
   --  polygon. Whenever one blade lies flush on an edge, the opposite
   --  contact is an antipodal vertex (or edge). All antipodal pairs are
   --  generated in O(n); diameter and width follow in the same pass.
   --
   --  Diameter: max ‖Pi − Pj‖ over antipodal vertex pairs.
   --  Width:    min distance between parallel supporting lines
   --            (distance from each edge to its antipodal vertex).
   --
   --  Floating-point arithmetic is educational — adequate for well-
   --  separated classroom examples, not a production exact kernel.

   function Antipodal_Pairs (Poly : Polygon) return Antipodal_List
     with Global => null;
   --  All antipodal vertex pairs of a convex polygon via rotating
   --  calipers (O(n)). Input is validated / normalized with
   --  Ensure_Convex_CCW. Pair indices are 1-based into the dense CCW
   --  copy (same vertex order as Ensure_Convex_CCW).

   function Diameter (Poly : Polygon) return Real
     with Global => null;
   --  Maximum Euclidean distance between any two vertices (= max over
   --  antipodal pairs). O(n) rotating calipers; raises Invalid_Argument
   --  if Poly is not a valid convex polygon.

   function Diameter_Squared (Poly : Polygon) return Real
     with Global => null;
   --  Squared diameter (avoids a final square root). Same validation.

   function Diameter_Endpoints (Poly : Polygon) return Antipodal_Pair
     with Global => null;
   --  One antipodal pair realizing the diameter (indices into the dense
   --  CCW copy from Ensure_Convex_CCW).

   function Width (Poly : Polygon) return Real
     with Global => null;
   --  Minimum width: min over edges of (distance from the edge line to
   --  the antipodal supporting vertex). Educational O(n) caliper pass.
   --  Raises Invalid_Argument if Poly is not a valid convex polygon.

   function Min_Area_Rect (Poly : Polygon) return Bounding_Rect
     with Global => null;
   --  Educational sketch of a minimum-area oriented bounding rectangle:
   --  for each edge as a flush caliper base, form the OBB from the four
   --  supporting lines and keep the candidate of least area. O(n).
   --  Raises Invalid_Argument if Poly is not a valid convex polygon.

   function Pair_Count_Of (L : Antipodal_List) return Pair_Count
     with Global => null;

   function Get_Pair
     (L : Antipodal_List; Index : Pair_Index) return Antipodal_Pair
     with Pre => Index <= L.Count, Global => null;

   ---------------------------------------------------------------------------
   -- Brute-force oracles (tests / teaching contrasts)
   ---------------------------------------------------------------------------

   function Brute_Diameter (Poly : Polygon) return Real
     with Global => null;
   --  O(n²) max pairwise vertex distance (no convexity required beyond
   --  vertex count). Raises Invalid_Argument if n < 2 or n > Max_Vertices.

   function Brute_Width (Poly : Polygon) return Real
     with Global => null;
   --  O(n²) educational width: for each edge, take max distance of any
   --  vertex to the edge line, then min over edges. Requires convex CCW
   --  (validated). Used to cross-check Width on small polygons.

end Rotating_Calipers;
