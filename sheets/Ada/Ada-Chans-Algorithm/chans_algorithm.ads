--  Chan's algorithm — Ada 2023 educational package for the 2D
--  output-sensitive convex-hull algorithm (O(n log h)).
--  Primary source:
--  https://en.wikipedia.org/wiki/Chan's_algorithm
--  Sibling packages (README only; do not `with`):
--    Ada-Graham-Scan, Ada-Gift-Wrapping, Ada-Quickhull,
--    Ada-Kirkpatrick-Seidel, Ada-Rotating-Calipers,
--    Ada-Minimum-Bounding-Box,
--    Ada-Convex-Hull (survey, ahead)
--    — RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Chans_Algorithm
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
   --  dense 1 .. n buffer before partitioning / wrapping.
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
   -- Chan's algorithm (2D)
   ---------------------------------------------------------------------------
   --  Timothy Chan (1996): output-sensitive planar convex hull in
   --  O(n log h) by combining mini-hulls (Graham / Andrew, O(m log m)
   --  each) with a Jarvis-style wrap that queries each mini-hull via a
   --  tangent / binary-search step (O(log m) ideal).
   --
   --  Classroom sketch of one successful pass with guessed size H ≈ h:
   --    1. Guess H = min(2^{2^t}, n) for t = 1, 2, … (squaring scheme).
   --    2. Partition into groups of size ≤ H; compute each mini-hull.
   --    3. Jarvis wrap: from the current hull vertex, take a tangent on
   --       every mini-hull, then pick the best candidate; abort if more
   --       than H vertices are emitted (H was too small).
   --    4. On wrap-back to the start, return the hull; else increase H.
   --
   --  Educational floating predicates — adequate for well-separated
   --  classroom examples, not a production exact kernel.
   --  Classroom simplifications are documented in the README.

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
   -- Teaching oracles — Graham scan + Andrew monotone chain
   ---------------------------------------------------------------------------
   --  Independent O(n log n) hulls used by tests to cross-check Chan on
   --  small classroom sets. Same Invalid_Argument contract. Also used
   --  internally as the mini-hull primitive (no sibling `with`).

   function Graham_Scan_Hull (Points : Point_Set) return Point_Array
     with Global => null;
   --  Classical Graham scan (polar sort + stack) → CCW open ring.

   function Andrew_Monotone_Chain (Points : Point_Set) return Point_Array
     with Global => null;
   --  Andrew monotone-chain hull vertices in CCW order (open ring).
   --  Near-duplicates and near-collinear vertices dropped with ε.

end Chans_Algorithm;
