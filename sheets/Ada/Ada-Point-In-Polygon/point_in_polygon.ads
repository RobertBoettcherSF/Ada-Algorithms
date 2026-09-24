--  Point_In_Polygon — Ada 2023 educational package for the classical
--  point-in-polygon (PIP) problem: decide whether a query point lies
--  inside, outside, or on the boundary of a simple planar polygon.
--  Implements ray casting (even–odd / crossing number) and the winding
--  number (nonzero) rule, including Dan Sunday's angle-free winding
--  update. Primary source:
--  https://en.wikipedia.org/wiki/Point_in_polygon
--  Sibling packages (README only; do not `with`):
--    Ada-Shoelace-Algorithm, Ada-Polygon-Triangulation,
--    Ada-Nearest-Neighbor-Search / Ada-Nesting / Ada-MBB (ahead) —
--    RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Point_In_Polygon
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

   --  Polygon vertices in order around the boundary (open ring; the
   --  implementation closes with (x_{n+1},y_{n+1}) = (x_1,y_1)).
   --  Both counterclockwise (CCW) and clockwise (CW) orders are accepted;
   --  even–odd is orientation-invariant; winding returns nonzero for
   --  either orientation when the point is enclosed.
   type Point_Array is array (Vertex_Index range <>) of Point;

   --  Educational alias: a polygon is just an ordered vertex array.
   subtype Polygon is Point_Array;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when Polygon'Length < 3 or Polygon'Length > Max_Vertices.

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

   function Orient2D (A, B, C : Point) return Real
     with Global => null;
   --  Twice signed area of triangle ABC: (B−A)×(C−A).
   --  > 0 ⇒ C left of directed AB; < 0 ⇒ right; ≈ 0 ⇒ collinear.

   ---------------------------------------------------------------------------
   -- Boundary / edge tests
   ---------------------------------------------------------------------------
   --  Boundary policy (closed polygon convention):
   --    • On_Boundary reports True when the query is within Tol of any
   --      edge segment (including vertices).
   --    • Contains_Even_Odd and Contains_Winding return True for such
   --      boundary points (treat the polygon as a closed set).
   --    • For a strict-interior query use:
   --        not On_Boundary (P, Poly) and then Contains_* (P, Poly).
   --  Horizontal edges and vertex hits in the ray tests follow the classic
   --  "count only if the other endpoint lies strictly above the ray"
   --  convention (Wikipedia / Jordan-curve even–odd), matching Sunday's
   --  upward/downward crossing rules so finite-precision vertex hits do
   --  not double-count.

   function Point_On_Segment
     (P, A, B : Point; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True iff P lies within Tol of the closed segment AB (collinear and
   --  within the axis-aligned bounding box of AB, expanded by Tol).

   function On_Boundary
     (P : Point; Poly : Polygon; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True iff P is within Tol of any edge of Poly (including vertices).
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Vertices.

   ---------------------------------------------------------------------------
   -- Point-in-polygon predicates
   ---------------------------------------------------------------------------
   --  Ray casting / even–odd (crossing number): cast a horizontal ray from
   --  P to +∞ and count edge crossings; odd ⇒ inside (Jordan curve).
   --
   --  Winding number (nonzero rule): accumulate +1 / −1 for upward /
   --  downward crossings where Orient2D shows P on the interior side
   --  (Dan Sunday, 2001 — no trigonometry). Nonzero ⇒ inside.
   --
   --  For simple polygons both agree on the interior. They may disagree
   --  on self-overlapping / complex regions (pentagram hole, etc.); that
   --  case is out of educational scope here.

   function Crossing_Number (P : Point; Poly : Polygon) return Natural
     with Global => null;
   --  Number of proper crossings of the +x ray from P with Poly's edges.
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Vertices.

   function Winding_Number (P : Point; Poly : Polygon) return Integer
     with Global => null;
   --  Signed winding of Poly about P (Sunday). Zero ⇒ outside for a
   --  simple polygon. Raises Invalid_Argument if n < 3 or > Max_Vertices.

   function Contains_Even_Odd (P : Point; Poly : Polygon) return Boolean
     with Global => null;
   --  Even–odd fill rule: True iff On_Boundary or Crossing_Number is odd.
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Vertices.

   function Contains_Winding (P : Point; Poly : Polygon) return Boolean
     with Global => null;
   --  Nonzero winding rule: True iff On_Boundary or Winding_Number ≠ 0.
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Vertices.

   function Contains
     (P : Point; Poly : Polygon; Use_Winding : Boolean := False)
      return Boolean
     with Global => null;
   --  Convenience: Use_Winding False ⇒ Contains_Even_Odd, else
   --  Contains_Winding. Same Invalid_Argument policy.

end Point_In_Polygon;
