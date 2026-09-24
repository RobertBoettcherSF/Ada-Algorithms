--  Graham scan — Ada 2023 educational package for the 2D Graham scan
--  convex-hull algorithm (polar sort + stack, O(n log n)).
--  Primary source:
--  https://en.wikipedia.org/wiki/Graham_scan
--  Sibling packages (README only; do not `with`):
--    Ada-Quickhull, Ada-Kirkpatrick-Seidel, Ada-Rotating-Calipers,
--    Ada-Minimum-Bounding-Box,
--    Ada-Jarvis-March / Ada-Chan / Ada-Convex-Hull (ahead)
--    — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Graham_Scan
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
   --  dense 1 .. n buffer before sorting / scanning.
   type Point_Array is array (Positive range <>) of Point;

   --  Educational alias: a point set is just a point array.
   subtype Point_Set is Point_Array;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when Points'Length < 1 or > Max_Points.

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

   function Polar_Less (Pivot, A, B : Point) return Boolean
     with Global => null;
   --  True iff A precedes B in polar order around Pivot (increasing angle
   --  from +x). Ties (same ray) broken by increasing Dist2 from Pivot.

   function Signed_Area (Poly : Point_Array) return Real
     with Global => null;
   --  Shoelace signed area (with 1/2). Positive for CCW.
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Points.

   function Is_CCW (Poly : Point_Array) return Boolean
     with Global => null;
   --  True iff Signed_Area (Poly) > Epsilon (n ≥ 3).
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Points.

   ---------------------------------------------------------------------------
   -- Graham scan (2D)
   ---------------------------------------------------------------------------
   --  Classical planar Graham scan (Graham 1972; CLRS presentation):
   --    1. Pivot = lowest y-coordinate (then leftmost).
   --    2. Sort remaining points by polar angle with the pivot; break
   --       same-ray ties by distance (keep farthest on each ray).
   --    3. Scan with a stack; pop while Orient2D (next, top, p) ≤ 0
   --       (not a strict left turn) for a CCW hull.
   --  O(n log n) dominated by the polar sort; the stack pass is O(n).
   --  Educational floating predicates — adequate for well-separated
   --  classroom examples, not a production exact kernel.

   function Convex_Hull (Points : Point_Set) return Point_Array
     with Global => null;
   --  Convex hull vertices in counterclockwise (CCW) order (open ring).
   --  Raises Invalid_Argument if Points'Length < 1 or > Max_Points.
   --  A single point returns 1 vertex; a collinear / two-point set returns
   --  the extreme endpoints (1 or 2 vertices after near-duplicate drop).

   function Hull_Vertex_Count (Points : Point_Set) return Point_Count
     with Global => null;
   --  Length of Convex_Hull (Points). Same validation.

   ---------------------------------------------------------------------------
   -- Teaching oracle — Andrew monotone chain
   ---------------------------------------------------------------------------
   --  Independent O(n log n) hull used by tests to cross-check Graham scan
   --  on small classroom sets. Same Invalid_Argument contract.

   function Andrew_Monotone_Chain (Points : Point_Set) return Point_Array
     with Global => null;
   --  Andrew monotone-chain hull vertices in CCW order (open ring).
   --  Near-duplicates and near-collinear vertices dropped with ε.

end Graham_Scan;
