--  Nesting_Algorithm — Ada 2023 educational package for nesting /
--  stock-cutting sketches: make efficient use of linear stock (1D) or
--  a rectangular plate (2D) by placing pieces without overlap.
--  Primary source:
--  https://en.wikipedia.org/wiki/Nesting_algorithm
--  Sibling packages (README only; do not `with`):
--    Ada-Point-In-Polygon, Ada-Shoelace-Algorithm,
--    Ada-Bin-Packing / cutting-stock siblings (ahead) —
--    RobertBoettcherSF Ada algorithm series.

pragma Ada_2022;

package Nesting_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain / capacity (educational classroom bounds)
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15). Lengths and
   --  areas use Real; piece counts use Natural / Piece_Index.
   type Real is digits 15;

   --  Soft classroom limit on pieces in one nesting call.
   Max_Pieces : constant Positive := 32;

   subtype Piece_Count is Natural range 0 .. Max_Pieces;
   subtype Piece_Index is Positive range 1 .. Max_Pieces;

   --  1D piece lengths (educational Natural-as-Real lengths).
   type Length_Array is array (Piece_Index range <>) of Real;

   --  Axis-aligned rectangle (Width × Height). Origin of a placement is
   --  the lower-left corner on the plate.
   type Rectangle is record
      Width  : Real := 0.0;
      Height : Real := 0.0;
   end record;

   type Rect_Array is array (Piece_Index range <>) of Rectangle;

   type Placement is record
      X, Y          : Real    := 0.0;  -- lower-left on the plate
      Width, Height : Real    := 0.0;  -- oriented size after optional rotate
      Piece_Index   : Natural := 0;    -- 1-based index into input Pieces
      Rotated       : Boolean := False;
      Placed        : Boolean := False;
   end record;

   type Placement_Array is array (Piece_Index range <>) of Placement;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised when stock / plate dimensions are nonpositive, Kerf < 0,
   --  the piece list is empty or exceeds Max_Pieces, or any piece has a
   --  nonpositive length / width / height.

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon : constant Real := 1.0E-9;

   function Near (A, B : Real; Tol : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Area_Of (R : Rectangle) return Real
     with Global => null;
   --  R.Width * R.Height (no validation).

   ---------------------------------------------------------------------------
   -- 1D linear nesting / stock cutting
   ---------------------------------------------------------------------------
   --  Wikipedia: for an existing set there is only one position where a
   --  new cut can be placed — at the end of the last cut. Validation is
   --  the simple identity
   --
   --    Scrap = Stock − Yield − Kerf_total
   --
   --  where Yield is the sum of placed piece lengths and Kerf_total is
   --  (n−1)·Kerf for n ≥ 1 placed pieces (kerf between successive cuts;
   --  zero when n ≤ 1). Pieces are considered in input order (no sorting).
   --  Nest_1D places as many leading pieces as fit; Fits is True iff
   --  every piece was placed (Scrap ≥ 0 and Placed_Count = Pieces'Length).

   type Nest_1D_Result is record
      Used_Length  : Real        := 0.0;  -- Yield + Kerf_Total
      Yield        : Real        := 0.0;  -- sum of placed lengths
      Kerf_Total   : Real        := 0.0;
      Scrap        : Real        := 0.0;  -- Stock − Yield − Kerf_Total
      Stock        : Real        := 0.0;
      Placed_Count : Piece_Count := 0;
      Fits         : Boolean     := False;
   end record;

   function Nest_1D
     (Stock  : Real;
      Pieces : Length_Array;
      Kerf   : Real := 0.0) return Nest_1D_Result
     with Global => null;
   --  Place pieces end-to-end on a stock of length Stock with Kerf
   --  between consecutive pieces.
   --  Raises Invalid_Argument if Stock ≤ 0, Kerf < 0, Pieces is empty
   --  or longer than Max_Pieces, or any piece length is ≤ 0.

   function Scrap_1D
     (Stock, Yield, Kerf_Total : Real) return Real
     with Global => null;
   --  Educational identity: Stock − Yield − Kerf_Total (no validation).

   ---------------------------------------------------------------------------
   -- 2D axis-aligned rectangle nesting (shelf / first-fit decreasing)
   ---------------------------------------------------------------------------
   --  Wikipedia notes plate (2D) nesting is significantly more complex
   --  (many candidate cut positions, rotations, intersection checks).
   --  This package teaches a classical *shelf / level* heuristic:
   --
   --    1. Sort pieces by decreasing height (ties: decreasing width).
   --    2. Open horizontal shelves (levels) from the bottom of the plate.
   --    3. First-fit: place each piece in the first shelf that has enough
   --       remaining width; else open a new shelf if height permits.
   --    4. Optional 90° rotation: for each piece try the orientation
   --       (W×H or H×W) that fits the candidate shelf / new level.
   --
   --  No freeform irregular nesting, no guillotine tree search, no CAD.
   --  Placements are axis-aligned; Utilization = (sum placed areas) /
   --  (Plate_Width × Plate_Height).

   type Nest_2D_Result is record
      Placements   : Placement_Array (1 .. Max_Pieces);
      Placed_Count : Piece_Count := 0;
      Utilization  : Real        := 0.0;  -- placed area / plate area
      Used_Area    : Real        := 0.0;
      Plate_Area   : Real        := 0.0;
      All_Fit      : Boolean     := False;
   end record;

   function Nest_2D_Shelf
     (Plate_Width  : Real;
      Plate_Height : Real;
      Pieces       : Rect_Array;
      Allow_Rotate : Boolean := False) return Nest_2D_Result
     with Global => null;
   --  Shelf / first-fit decreasing packing of axis-aligned rectangles
   --  into a Plate_Width × Plate_Height plate.
   --  Raises Invalid_Argument if plate sides ≤ 0, Pieces empty or longer
   --  than Max_Pieces, or any rectangle has Width ≤ 0 or Height ≤ 0.

   function Rectangles_Overlap
     (A_X, A_Y, A_W, A_H : Real;
      B_X, B_Y, B_W, B_H : Real;
      Tol                : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True iff the open interiors of axis-aligned A and B intersect
   --  (touching edges only is not an overlap when Tol = 0 conceptually;
   --  with Tol, expand slightly). Educational intersection check.

   function Fits_In_Plate
     (X, Y, W, H           : Real;
      Plate_Width          : Real;
      Plate_Height         : Real;
      Tol                  : Real := Epsilon) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  True iff the axis-aligned box [X,X+W]×[Y,Y+H] lies inside the
   --  plate [0,Plate_Width]×[0,Plate_Height] within Tol.

end Nesting_Algorithm;
