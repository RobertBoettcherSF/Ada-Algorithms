--  Minimum_Bounding_Box — Ada 2023 educational package for 2D minimum
--  bounding box algorithms: axis-aligned AABB and oriented min-area OBB
--  via a rotating-calipers style enumeration on the convex hull.
--  Primary source:
--  https://en.wikipedia.org/wiki/Minimum_bounding_box_algorithms
--  Sibling packages (README only; do not `with`):
--    Ada-Rotating-Calipers, Ada-Convex-Hull, Ada-Shoelace-Algorithm —
--    RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Minimum_Bounding_Box
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   --  Soft classroom limit on input points / hull vertices.
   Max_Points : constant Positive := 64;

   subtype Point_Count is Natural range 0 .. Max_Points;
   subtype Point_Index is Positive range 1 .. Max_Points;

   type Point is record
      X, Y : Real := 0.0;
   end record;

   --  Unordered (or ordered) finite point set. Hull / box routines copy
   --  into a dense 1 .. n buffer before computing.
   type Point_Array is array (Positive range <>) of Point;

   --  Educational alias: a point set is just a point array.
   subtype Point_Set is Point_Array;

   ---------------------------------------------------------------------------
   -- Axis-aligned bounding box (AABB)
   ---------------------------------------------------------------------------

   --  Smallest enclosing rectangle with sides parallel to the axes.
   --  Defined by extremal coordinates; Area = (Max_X-Min_X)*(Max_Y-Min_Y).
   type Axis_Aligned_Box is record
      Min_X, Min_Y : Real := 0.0;
      Max_X, Max_Y : Real := 0.0;
      Area         : Real := 0.0;
   end record;

   ---------------------------------------------------------------------------
   -- Oriented bounding box (OBB)
   ---------------------------------------------------------------------------

   --  Minimum-area oriented rectangle. Corners are in CCW order around
   --  the boundary. Angle is the direction (radians) of the flush edge
   --  used as the caliper base (atan2 of that edge).
   type Oriented_Box is record
      Corner : Point_Array (1 .. 4) := [others => (X => 0.0, Y => 0.0)];
      Width  : Real := 0.0;
      Height : Real := 0.0;
      Angle  : Real := 0.0;
      Area   : Real := 0.0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when Points'Length < 1 or > Max_Points, or when a hull /
   --  box construction cannot proceed (e.g. all points coincide in a
   --  degenerate way that leaves no finite box candidate — rare for
   --  classroom AABB / OBB paths which still accept a single point).

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
   --  2D cross product A×B = Ax·By − Ay·Bx.

   function Cross (A, B : Point) return Real
     with Global => null;
   --  Cross of vectors A and B as points-from-origin.

   function Dot (A, B : Point) return Real
     with Global => null;
   --  Dot product A·B.

   function Orient2D (A, B, C : Point) return Real
     with Global => null;
   --  Twice signed area of triangle ABC: (B−A)×(C−A).
   --  > 0 ⇒ C left of directed AB (CCW); < 0 ⇒ right (CW); ≈ 0 ⇒ collinear.

   ---------------------------------------------------------------------------
   -- Convex hull (educational Andrew monotone chain)
   ---------------------------------------------------------------------------
   --  The min-area enclosing box of a point set equals that of its convex
   --  hull (Freeman–Shapira / Toussaint). This package embeds a simple
   --  O(n log n) Andrew monotone-chain hull so callers may pass arbitrary
   --  point sets (not only convex polygons). Duplicate / near-collinear
   --  vertices are dropped with an ε-threshold.

   function Convex_Hull (Points : Point_Set) return Point_Array
     with Global => null;
   --  Convex hull vertices in CCW order (open ring). Raises
   --  Invalid_Argument if Points'Length < 1 or > Max_Points.
   --  A single point or collinear segment returns 1 or 2 vertices.

   function Hull_Vertex_Count (Points : Point_Set) return Point_Count
     with Global => null;
   --  Length of Convex_Hull (Points). Same validation.

   ---------------------------------------------------------------------------
   -- Axis-aligned bounding box
   ---------------------------------------------------------------------------

   function Axis_Aligned_Bounding_Box
     (Points : Point_Set) return Axis_Aligned_Box
     with Global => null;
   --  Min/max X and Y over the point set; Area = width · height.
   --  O(n). Raises Invalid_Argument if Points'Length < 1 or > Max_Points.
   --  A single point yields a zero-area degenerate box.

   function AABB_Area (Box : Axis_Aligned_Box) return Real
     with Global => null;
   --  Returns Box.Area (accessor for teaching symmetry with OBB).

   function AABB_Width (Box : Axis_Aligned_Box) return Real
     with Global => null;

   function AABB_Height (Box : Axis_Aligned_Box) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- Oriented minimum-area bounding box (rotating-calipers style)
   ---------------------------------------------------------------------------
   --  Freeman–Shapira / Toussaint observation: at least one side of a
   --  minimum-area enclosing rectangle is collinear with an edge of the
   --  convex hull. Enumerate each hull edge as a flush caliper base,
   --  project all hull vertices onto the edge direction and its left
   --  normal, form the candidate OBB, and keep the least area. O(h)
   --  after the hull (h = hull size), overall O(n log n) for a general
   --  point set. Educational floating arithmetic — adequate for
   --  well-separated classroom examples.

   function Min_Area_Oriented_Box
     (Points : Point_Set) return Oriented_Box
     with Global => null;
   --  Minimum-area oriented bounding box of Points. Internally computes
   --  the convex hull, then enumerates flush-edge candidates. Returns
   --  corners (CCW), Width, Height, Angle (radians), Area.
   --  Raises Invalid_Argument if Points'Length < 1 or > Max_Points.

   function OBB_Area (Box : Oriented_Box) return Real
     with Global => null;

   function OBB_Width (Box : Oriented_Box) return Real
     with Global => null;

   function OBB_Height (Box : Oriented_Box) return Real
     with Global => null;

   function OBB_Angle (Box : Oriented_Box) return Real
     with Global => null;

   function OBB_Corner
     (Box : Oriented_Box; Index : Point_Index) return Point
     with Pre => Index in 1 .. 4, Global => null;

   ---------------------------------------------------------------------------
   -- Brute / teaching contrasts
   ---------------------------------------------------------------------------

   function Brute_Min_Area_OBB
     (Points : Point_Set) return Oriented_Box
     with Global => null;
   --  Same flush-edge enumeration as Min_Area_Oriented_Box (educational
   --  alias used by tests to emphasise the hull-edge criterion). For
   --  classroom point sets these coincide; both raise Invalid_Argument
   --  on empty / oversized input.

end Minimum_Bounding_Box;
