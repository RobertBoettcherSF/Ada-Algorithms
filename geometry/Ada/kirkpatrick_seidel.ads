--  Kirkpatrick–Seidel — Ada 2023 educational package for the 2D
--  Kirkpatrick–Seidel ("marriage before conquest") convex-hull
--  algorithm, output-sensitive O(n log h) in theory.
--  Primary source:
--  https://en.wikipedia.org/wiki/Kirkpatrick–Seidel_algorithm
--  Sibling packages (README only; do not `with`):
--    Ada-Quickhull, Ada-Rotating-Calipers, Ada-Minimum-Bounding-Box,
--    Ada-Graham-Scan / Ada-Jarvis-March / Ada-Chan / Ada-Convex-Hull
--    (ahead) — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Kirkpatrick_Seidel
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

   --  Unordered (or ordered) finite point set. Hull routines copy into a
   --  dense 1 .. n buffer before partitioning / recursing.
   type Point_Array is array (Positive range <>) of Point;

   --  Educational alias: a point set is just a point array.
   subtype Point_Set is Point_Array;

   --  Upper (or lower) bridge edge connecting a left subset to a right
   --  subset across a vertical separating line (marriage-before-conquest).
   type Bridge_Edge is record
      Left, Right : Point;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when Points'Length < 1 or > Max_Points (hull), or when a
   --  bridge is requested with an empty left or right set.

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

   function Signed_Area (Poly : Point_Array) return Real
     with Global => null;
   --  Shoelace signed area (with 1/2). Positive for CCW.
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Points.

   function Is_CCW (Poly : Point_Array) return Boolean
     with Global => null;
   --  True iff Signed_Area (Poly) > Epsilon (n ≥ 3).
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Points.

   ---------------------------------------------------------------------------
   -- Kirkpatrick–Seidel (2D, marriage before conquest)
   ---------------------------------------------------------------------------
   --  Classroom sketch of Kirkpatrick & Seidel (1986): instead of conquering
   --  (recursing) first and marrying (bridging) later, find the median
   --  vertical line, compute the upper / lower bridge that crosses it, discard
   --  points that cannot contribute hull edges, then recurse on the surviving
   --  left and right subsets. Theoretical O(n log h); this educational body
   --  uses a clear O(|L|·|R|·n) bridge scan (exact asymptotic machinery of
   --  median-of-slopes is simplified) but still returns correct hulls for the
   --  classroom tests. Floating predicates — not a production exact kernel.

   function Upper_Bridge
     (Left_Set, Right_Set : Point_Set) return Bridge_Edge
     with Global => null;
   --  Upper tangent (bridge) between two vertically separated point sets:
   --  every point of Left_Set ∪ Right_Set lies on or below the directed
   --  edge Left → Right. Raises Invalid_Argument if either set is empty
   --  or either length exceeds Max_Points.

   function Lower_Bridge
     (Left_Set, Right_Set : Point_Set) return Bridge_Edge
     with Global => null;
   --  Lower tangent (bridge): every point lies on or above Left → Right.
   --  Same Invalid_Argument contract as Upper_Bridge.

   function Convex_Hull (Points : Point_Set) return Point_Array
     with Global => null;
   --  Convex hull vertices in counterclockwise (CCW) order (open ring).
   --  Assembles upper + lower KS hulls. Raises Invalid_Argument if
   --  Points'Length < 1 or > Max_Points. A single point returns 1 vertex;
   --  a collinear / two-point set returns the extreme endpoints.

   function Hull_Vertex_Count (Points : Point_Set) return Point_Count
     with Global => null;
   --  Length of Convex_Hull (Points). Same validation.

   ---------------------------------------------------------------------------
   -- Teaching oracle — Andrew monotone chain
   ---------------------------------------------------------------------------
   --  Independent O(n log n) hull used by tests to cross-check KS on small
   --  classroom sets. Same Invalid_Argument contract.

   function Andrew_Monotone_Chain (Points : Point_Set) return Point_Array
     with Global => null;
   --  Andrew monotone-chain hull vertices in CCW order (open ring).
   --  Near-duplicates and near-collinear vertices dropped with ε.

end Kirkpatrick_Seidel;
