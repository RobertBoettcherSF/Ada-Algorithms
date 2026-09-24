--  Convex hull algorithms — Ada 2023 educational *survey* package for
--  classical 2D convex-hull methods on a finite point set.
--  Primary source:
--  https://en.wikipedia.org/wiki/Convex_hull_algorithms
--  Implements (self-contained; do NOT `with` sibling repos):
--    Gift wrapping / Jarvis march, Graham scan, Andrew monotone chain,
--    Quickhull; optional Method dispatcher.
--  Sibling packages (README only; do not `with`):
--    Ada-Gift-Wrapping, Ada-Graham-Scan, Ada-Quickhull,
--    Ada-Chans-Algorithm, Ada-Kirkpatrick-Seidel,
--    Ada-Rotating-Calipers, Ada-Minimum-Bounding-Box —
--    RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Convex_Hull_Algorithms
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
   --  dense 1 .. n buffer before sorting / wrapping / recursing.
   type Point_Array is array (Positive range <>) of Point;

   --  Educational alias: a point set is just a point array.
   subtype Point_Set is Point_Array;

   ---------------------------------------------------------------------------
   -- Method selector (unified dispatcher)
   ---------------------------------------------------------------------------

   type Hull_Method is
     (Gift_Wrapping_Method,
      Graham_Scan_Method,
      Andrew_Method,
      Quickhull_Method);

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when Points'Length < 1 or > Max_Points.

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon : constant Real := 1.0E-9;
   --  Absolute tolerance for Near / Near_Point / collinearity tests.

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

   function Distance_To_Line (P, A, B : Point) return Real
     with Global => null;
   --  Perpendicular distance from P to the infinite line through A and B.
   --  Returns 0 when A and B coincide (degenerate segment).

   function Signed_Area (Poly : Point_Array) return Real
     with Global => null;
   --  Shoelace signed area (with 1/2). Positive for CCW.
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Points.

   function Is_CCW (Poly : Point_Array) return Boolean
     with Global => null;
   --  True iff Signed_Area (Poly) > Epsilon (n ≥ 3).
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Points.

   ---------------------------------------------------------------------------
   -- Hull convention (all methods)
   ---------------------------------------------------------------------------
   --  Output is an *open* ring of extreme vertices in counterclockwise (CCW)
   --  order. Near-duplicates and strictly interior / edge-collinear midpoints
   --  are dropped (ε = Epsilon). Degenerate cases:
   --    • 1 unique point  → 1 vertex
   --    • 2 unique / all-collinear → the two extreme endpoints
   --  Starting vertex differs slightly by method (documented per routine);
   --  compare hulls by vertex *set*, count, CCW, and area — not by cyclic
   --  shift of the open ring. Andrew is the classroom oracle.

   ---------------------------------------------------------------------------
   -- 1. Gift wrapping / Jarvis march — O(n h)
   ---------------------------------------------------------------------------

   function Gift_Wrapping (Points : Point_Set) return Point_Array
     with Global => null;
   --  Jarvis march: start at leftmost-then-lowest; repeatedly pick the
   --  next most-CCW extreme; stop on wrap-back. O(n h).

   function Jarvis_March (Points : Point_Set) return Point_Array
     with Global => null;
   --  Educational alias for Gift_Wrapping.

   ---------------------------------------------------------------------------
   -- 2. Graham scan — O(n log n)
   ---------------------------------------------------------------------------

   function Graham_Scan (Points : Point_Set) return Point_Array
     with Global => null;
   --  Pivot = lowest-then-leftmost; polar sort; stack scan with strict
   --  left turns. Starts at the pivot. O(n log n).

   ---------------------------------------------------------------------------
   -- 3. Andrew monotone chain — O(n log n)  (classroom oracle)
   ---------------------------------------------------------------------------

   function Andrew_Monotone_Chain (Points : Point_Set) return Point_Array
     with Global => null;
   --  Lex sort; build lower then upper hull; concatenate (drop shared
   --  endpoints). Starts at the lexicographically lowest point. O(n log n).

   ---------------------------------------------------------------------------
   -- 4. Quickhull — expected O(n log n)
   ---------------------------------------------------------------------------

   function Quickhull (Points : Point_Set) return Point_Array
     with Global => null;
   --  Leftmost/rightmost extremes; recursive farthest-point on each side.
   --  Expected O(n log n); worst case O(n²). Starts at leftmost extreme.

   ---------------------------------------------------------------------------
   -- Unified dispatcher + counts
   ---------------------------------------------------------------------------

   function Convex_Hull
     (Points : Point_Set;
      Method : Hull_Method := Andrew_Method) return Point_Array
     with Global => null;
   --  Dispatch to the selected method. Same Invalid_Argument contract.
   --  Default Method is Andrew (oracle).

   function Hull_Vertex_Count
     (Points : Point_Set;
      Method : Hull_Method := Andrew_Method) return Point_Count
     with Global => null;
   --  Length of Convex_Hull (Points, Method). Same validation.

end Convex_Hull_Algorithms;
