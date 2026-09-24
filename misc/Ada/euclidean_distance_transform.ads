--  Euclidean_Distance_Transform — Ada 2023 educational package for the
--  Euclidean distance transform (distance map / distance field) on a
--  small binary 2-D grid. Primary source:
--  https://en.wikipedia.org/wiki/Distance_transform
--  Sibling packages (README only; do not `with`):
--    Ada-Geometric-Hashing, Ada-Quickhull (ahead) —
--    RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Euclidean_Distance_Transform
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   --  Soft classroom limits on grid size (tiny grids for exact O(n²) EDT).
   Max_Width  : constant Positive := 64;
   Max_Height : constant Positive := 64;

   subtype Col_Index is Positive range 1 .. Max_Width;
   subtype Row_Index is Positive range 1 .. Max_Height;
   subtype Width_Count  is Natural range 0 .. Max_Width;
   subtype Height_Count is Natural range 0 .. Max_Height;

   --  Binary image: True = feature / foreground (obstacle) pixel with
   --  distance 0; False = background.  Convention matches the Wikipedia
   --  “nearest obstacle / boundary pixel” view.
   type Binary_Image is
     array (Row_Index range <>, Col_Index range <>) of Boolean;

   --  Exact Euclidean distance map (√ of squared distance to nearest
   --  feature).  Feature pixels store 0.0.
   type Distance_Map is
     array (Row_Index range <>, Col_Index range <>) of Real;

   --  Squared Euclidean distance map (integer grid distances; avoids √).
   --  Useful for exact comparisons without floating round-off.
   type Squared_Distance_Map is
     array (Row_Index range <>, Col_Index range <>) of Natural;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when an image is empty (zero rows or columns), exceeds
   --  Max_Width / Max_Height, contains no feature pixels, or an index is
   --  out of range for Distance_At / Squared_Distance_At.

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Has_Feature (Image : Binary_Image) return Boolean
     with Global => null;
   --  True iff at least one pixel is True (a feature).

   function Feature_Count (Image : Binary_Image) return Natural
     with Global => null;

   function Width_Of  (Image : Binary_Image) return Width_Count
     with Global => null;
   function Height_Of (Image : Binary_Image) return Height_Count
     with Global => null;

   ---------------------------------------------------------------------------
   -- Exact Euclidean distance transform (naive O((W·H)²) classroom EDT)
   ---------------------------------------------------------------------------

   function Squared_Distance_Transform
     (Image : Binary_Image) return Squared_Distance_Map
     with Global => null;
   --  For every pixel (r,c), store min over feature (fr,fc) of
   --  (r−fr)² + (c−fc)².  Exact on the integer grid.
   --  Raises Invalid_Argument if Image is empty, oversized, or featureless.

   function Distance_Transform
     (Image : Binary_Image) return Distance_Map
     with Global => null;
   --  Exact Euclidean distance map: √ of Squared_Distance_Transform.
   --  Raises Invalid_Argument under the same conditions.

   function Distance_At
     (Map : Distance_Map; Row, Col : Positive) return Real
     with Global => null;
   --  Read Map (Row, Col).  Raises Invalid_Argument if out of bounds.

   function Squared_Distance_At
     (Map : Squared_Distance_Map; Row, Col : Positive) return Natural
     with Global => null;
   --  Read Map (Row, Col).  Raises Invalid_Argument if out of bounds.

   ---------------------------------------------------------------------------
   -- Separable exact EDT (Meijster-style educational sketch)
   ---------------------------------------------------------------------------

   function Meijster_Squared_Distance_Transform
     (Image : Binary_Image) return Squared_Distance_Map
     with Global => null;
   --  Exact squared EDT via 1-D column distances then per-row lower
   --  envelope of parabolas (Meijster / Felzenszwalb–Huttenlocher style).
   --  Same Invalid_Argument conditions as Squared_Distance_Transform.
   --  Result must match the naive transform on every valid image.

   ---------------------------------------------------------------------------
   -- Chamfer approximation (teaching contrast — not exact Euclidean)
   ---------------------------------------------------------------------------

   --  Classic 3-4 chamfer local weights (city-block diagonal ≈ 4/3).
   Chamfer_Ortho    : constant Natural := 3;
   Chamfer_Diagonal : constant Natural := 4;

   function Chamfer_Distance_Transform
     (Image : Binary_Image) return Distance_Map
     with Global => null;
   --  Two-pass forward/backward chamfer (3-4 weights), then scaled by
   --  1/Chamfer_Ortho so orthogonal steps ≈ 1.  Approximate only —
   --  use for classroom contrast with the exact EDT, not for exact
   --  Euclidean queries.  Same Invalid_Argument conditions.

end Euclidean_Distance_Transform;
