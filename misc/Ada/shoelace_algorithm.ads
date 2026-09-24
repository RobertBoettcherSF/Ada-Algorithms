--  Shoelace_Algorithm — Ada 2023 educational package for the shoelace
--  formula (Gauss's area formula / surveyor's formula): area of a simple
--  polygon from Cartesian vertex coordinates via cross-multiplying
--  successive edge terms, like threading shoelaces.
--  Primary source:
--  https://en.wikipedia.org/wiki/Shoelace_algorithm
--  Sibling packages (README only; do not `with`):
--    Ada-Polygon-Triangulation, Ada-Triangulation,
--    Ada-Rotating-Calipers / Ada-Point-In-Polygon (ahead) —
--    RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Shoelace_Algorithm
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
   --  Preferred orientation is counterclockwise (CCW): Signed_Area > 0.
   type Point_Array is array (Vertex_Index range <>) of Point;

   --  Educational alias: a polygon is just an ordered vertex array.
   subtype Polygon is Point_Array;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when Polygon'Length < 3 or Polygon'Length > Max_Vertices, or
   --  when Centroid is requested for a near-degenerate (near-zero area)
   --  polygon.

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Near_Point (A, B : Point; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   ---------------------------------------------------------------------------
   -- Shoelace measures
   ---------------------------------------------------------------------------
   --  Classical formula (Wikipedia):
   --
   --    A = (1/2) | Σ_{i=1}^{n} (x_i y_{i+1} − x_{i+1} y_i) |
   --
   --  with (x_{n+1}, y_{n+1}) = (x_1, y_1). Signed_Area keeps the sign of
   --  the sum (positive for CCW, negative for CW); Area is |Signed_Area|.
   --  Floating-point arithmetic is educational — adequate for well-
   --  separated classroom examples, not a production exact kernel.

   function Signed_Area (Poly : Polygon) return Real
     with Global => null;
   --  Signed shoelace area (includes the 1/2 factor). Positive for a
   --  counterclockwise vertex order, negative for clockwise.
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Vertices.

   function Area (Poly : Polygon) return Real
     with Global => null;
   --  Absolute polygon area |Signed_Area (Poly)|.
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Vertices.

   function Is_CCW (Poly : Polygon) return Boolean
     with Global => null;
   --  True iff Signed_Area (Poly) > Epsilon.
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Vertices.

   function Is_CW (Poly : Polygon) return Boolean
     with Global => null;
   --  True iff Signed_Area (Poly) < −Epsilon.
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Vertices.

   ---------------------------------------------------------------------------
   -- Centroid (same cross terms; educational)
   ---------------------------------------------------------------------------
   --  For a simple polygon of signed area A ≠ 0:
   --
   --    C_x = (1/(6A)) Σ (x_i + x_{i+1}) (x_i y_{i+1} − x_{i+1} y_i)
   --    C_y = (1/(6A)) Σ (y_i + y_{i+1}) (x_i y_{i+1} − x_{i+1} y_i)
   --
   --  A is the signed area (with 1/2). The same determinants appear in the
   --  shoelace sum. Valid for simple polygons; self-overlapping cases need
   --  care and are out of educational scope here.

   function Centroid (Poly : Polygon) return Point
     with Global => null;
   --  Polygon centroid via shoelace cross terms.
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Vertices, or if
   --  |Signed_Area| ≤ Epsilon (degenerate).

   ---------------------------------------------------------------------------
   -- Twice-area determinant sum (educational building block)
   ---------------------------------------------------------------------------

   function Determinant_Sum (Poly : Polygon) return Real
     with Global => null;
   --  Σ (x_i y_{i+1} − x_{i+1} y_i) = 2 · Signed_Area. Useful when
   --  comparing with Orient2D / triangle twice-areas.
   --  Raises Invalid_Argument if Poly'Length < 3 or > Max_Vertices.

end Shoelace_Algorithm;
