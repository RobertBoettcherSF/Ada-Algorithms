--  Contour_Lines — Ada 2023 educational package for contour lines
--  (isolines / isopleths): level sets of a scalar field f(x,y), contour
--  intervals, multi-level contour maps, gradients perpendicular to
--  isolines, spacing classification, transect profiles, and labeling.
--  Based on Wikipedia "Contour line". Related to but distinct from
--  Marching_Squares (that package owns the full 16-case API).

pragma Ada_2022;

package Contour_Lines
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 6;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   type Vec2 is record
      X, Y : Real := 0.0;
   end record;

   subtype Point2 is Vec2;

   type Level_Value is new Real;
   type Contour_Interval_Value is new Real;

   type Segment is record
      A, B : Point2;
   end record;

   --  At most two isoline segments per 2x2 cell.
   type Small_Segment_List is array (1 .. 2) of Segment;

   Max_Segments : constant Positive := 1_024;
   subtype Segment_Count is Natural range 0 .. Max_Segments;
   subtype Segment_Index is Positive range 1 .. Max_Segments;
   type Segment_Array is array (Segment_Index) of Segment;

   type Polyline is record
      Segs  : Segment_Array;
      Count : Segment_Count := 0;
      Level : Level_Value := 0.0;
   end record;

   Max_Levels : constant Positive := 16;
   subtype Level_Count is Natural range 0 .. Max_Levels;
   subtype Level_Index is Positive range 1 .. Max_Levels;
   type Level_Array is array (Level_Index) of Level_Value;
   type Polyline_Array is array (Level_Index) of Polyline;

   type Contour_Map is record
      Levels      : Level_Array;
      Contours    : Polyline_Array;
      Count       : Level_Count := 0;
      Interval    : Contour_Interval_Value := 1.0;
      Min_Level   : Level_Value := 0.0;
      Max_Level   : Level_Value := 0.0;
   end record;

   Max_Profile : constant Positive := 256;
   subtype Profile_Count is Natural range 0 .. Max_Profile;
   subtype Profile_Index is Positive range 1 .. Max_Profile;
   type Profile_Value_Array is array (Profile_Index) of Real;
   type Profile_Point_Array is array (Profile_Index) of Point2;

   type Transect_Profile is record
      Points : Profile_Point_Array;
      Values : Profile_Value_Array;
      Count  : Profile_Count := 0;
   end record;

   --  Educational scalar grids stay modest.
   Max_Grid_Dim : constant Positive := 64;
   subtype Grid_Dim is Positive range 2 .. Max_Grid_Dim;

   type Scalar_Field is
     array (Natural range <>, Natural range <>) of Real;

   type Position_Field is
     array (Natural range <>, Natural range <>) of Point2;

   type Slope_Class is (Gentle, Moderate, Steep, Cliff, Flat);

   type Isoline_Kind is
     (Generic_Isoline, Contour, Isobar, Isotherm, Isohyet,
      Isobath, Isoheight, Isopleth);

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;
   Capacity_Exceeded   : exception;

   ---------------------------------------------------------------------------
   -- Vector / numeric helpers
   ---------------------------------------------------------------------------

   function Length (V : Vec2) return Non_Negative
     with Global => null;

   function Normalize (V : Vec2) return Vec2
     with Pre    => Length (V) > 0.0,
          Post   => abs (Length (Normalize'Result) - 1.0) <= 1.0E-4,
          Global => null;

   function Dot (A, B : Vec2) return Real
     with Global => null;

   function "-" (A, B : Vec2) return Vec2
     with Global => null;

   function "+" (A, B : Vec2) return Vec2
     with Global => null;

   function "*" (S : Real; V : Vec2) return Vec2
     with Global => null;

   function Clamp (X, Lo, Hi : Real) return Real
     with Pre    => Lo <= Hi,
          Post   => Clamp'Result >= Lo and then Clamp'Result <= Hi,
          Global => null;

   function Distance_Between (A, B : Vec2) return Non_Negative
     with Global => null;

   function Perp (V : Vec2) return Vec2
     with Global => null;
   --  Rotate 90° counterclockwise: (x,y) → (−y, x).

   ---------------------------------------------------------------------------
   -- 1. Contour_Interval / Level_From_Index
   ---------------------------------------------------------------------------

   function Contour_Level_Count
     (Min_Level : Level_Value;
      Max_Level : Level_Value;
      Interval  : Contour_Interval_Value) return Natural
     with Pre    => Interval > 0.0 and then Max_Level >= Min_Level,
          Global => null;
   --  Number of arithmetic contour levels from Min through Max inclusive
   --  at the given contour interval (cartographic contour interval).

   function Level_From_Index
     (Min_Level : Level_Value;
      Interval  : Contour_Interval_Value;
      Index     : Natural) return Level_Value
     with Pre    => Interval > 0.0,
          Global => null;
   --  Level = Min_Level + Index * Interval (0-based index).

   function Contour_Interval_Of
     (Min_Level : Level_Value;
      Max_Level : Level_Value;
      Levels    : Positive) return Contour_Interval_Value
     with Pre    => Max_Level > Min_Level and then Levels >= 2,
          Global => null;
   --  Interval that yields Levels equally spaced elevations.

   ---------------------------------------------------------------------------
   -- 2. Sample_Height_Field / Bilinear_Sample
   ---------------------------------------------------------------------------

   function Sample_Height_Field
     (Values : Scalar_Field;
      I, J   : Natural) return Real
     with Pre    => I in Values'Range (1) and then J in Values'Range (2),
          Global => null;
   --  Direct grid sample at integer indices (I = column/X, J = row/Y).

   function Bilinear_Sample
     (Values    : Scalar_Field;
      Positions : Position_Field;
      P         : Point2) return Real
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Values'Length (1) >= 2
                      and then Values'Length (2) >= 2,
          Global => null;
   --  Bilinear interpolate f at world point P on a regular lattice.
   --  Raises Invalid_Argument when P lies outside the grid AABB.

   ---------------------------------------------------------------------------
   -- 3. Gradient_2D / Gradient_Perpendicular_Check
   ---------------------------------------------------------------------------

   function Gradient_2D
     (Values    : Scalar_Field;
      Positions : Position_Field;
      I, J      : Natural) return Vec2
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then I in Values'Range (1)
                      and then J in Values'Range (2)
                      and then Values'Length (1) >= 2
                      and then Values'Length (2) >= 2,
          Global => null;
   --  Central (or one-sided at borders) finite-difference ∇f.

   function Gradient_Magnitude (G : Vec2) return Non_Negative
     with Global => null;

   function Gradient_Perpendicular_Check
     (Gradient       : Vec2;
      Contour_Tangent : Vec2;
      Tolerance      : Real := 1.0E-3) return Boolean
     with Pre    => Tolerance >= 0.0,
          Global => null;
   --  True when |∇f · T| / (|∇f||T|) ≤ Tolerance (gradient ⊥ contour).
   --  Returns True when either vector is degenerate (undefined check).

   ---------------------------------------------------------------------------
   -- 4. Trace_Isoline_Cell / Extract_Isolines_At_Level
   ---------------------------------------------------------------------------

   procedure Trace_Isoline_Cell
     (TL, TR, BR, BL : Point2;
      V_TL, V_TR, V_BR, V_BL : Real;
      Level     : Level_Value;
      Out_Segs  : out Small_Segment_List;
      Out_Count : out Natural)
     with Post   => Out_Count <= 2,
          Global => null;
   --  Compact 2×2 cell isoline extraction (marching-squares style cases,
   --  owned here for contour-map work; not the full Marching_Squares API).

   function Extract_Isolines_At_Level
     (Values    : Scalar_Field;
      Positions : Position_Field;
      Level     : Level_Value) return Polyline
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Values'Length (1) >= 2
                      and then Values'Length (2) >= 2,
          Global => null;
   --  Extract all isoline segments at one level across the grid.

   ---------------------------------------------------------------------------
   -- 5. Build_Contour_Map
   ---------------------------------------------------------------------------

   function Build_Contour_Map
     (Values    : Scalar_Field;
      Positions : Position_Field;
      Min_Level : Level_Value;
      Max_Level : Level_Value;
      Interval  : Contour_Interval_Value) return Contour_Map
     with Pre    => Interval > 0.0
                      and then Max_Level >= Min_Level
                      and then Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Values'Length (1) >= 2
                      and then Values'Length (2) >= 2,
          Global => null;
   --  Extract isolines for every arithmetic contour level in [Min, Max].

   function Empty_Contour_Map return Contour_Map
     with Post   => Empty_Contour_Map'Result.Count = 0,
          Global => null;

   function Contour_Map_Level_Count (M : Contour_Map) return Natural
     with Post   => Contour_Map_Level_Count'Result = Natural (M.Count),
          Global => null;

   ---------------------------------------------------------------------------
   -- 6. Classify_Spacing
   ---------------------------------------------------------------------------

   function Classify_Spacing
     (Grad_Mag          : Non_Negative;
      Steep_Threshold   : Non_Negative := 1.0;
      Cliff_Threshold   : Non_Negative := 5.0;
      Gentle_Threshold  : Non_Negative := 0.25) return Slope_Class
     with Pre    => Gentle_Threshold <= Steep_Threshold
                      and then Steep_Threshold <= Cliff_Threshold,
          Global => null;
   --  Close contours ⇔ large |∇f| (steep); distant ⇔ gentle / flat.

   function Spacing_From_Gradient
     (Grad_Mag : Non_Negative;
      Interval : Contour_Interval_Value) return Non_Negative
     with Pre    => Interval > 0.0,
          Global => null;
   --  Approximate map-plane spacing between successive contours ≈ Δh / |∇f|.

   ---------------------------------------------------------------------------
   -- 7. Closest_Contour_Label / Format helpers
   ---------------------------------------------------------------------------

   function Closest_Contour_Label
     (Value    : Level_Value;
      Min_Level : Level_Value;
      Interval : Contour_Interval_Value) return Level_Value
     with Pre    => Interval > 0.0,
          Global => null;
   --  Nearest arithmetic contour level to Value (educational labeling).

   function Isoline_Kind_Name (K : Isoline_Kind) return String
     with Global => null;

   function Format_Level_Label
     (Level : Level_Value;
      Kind  : Isoline_Kind := Contour) return String
     with Global => null;
   --  Short educational label, e.g. "contour 100" or "isobar 1013".

   ---------------------------------------------------------------------------
   -- 8. Profile_Along_Line
   ---------------------------------------------------------------------------

   function Profile_Along_Line
     (Values    : Scalar_Field;
      Positions : Position_Field;
      A, B      : Point2;
      Samples   : Positive) return Transect_Profile
     with Pre    => Samples >= 2
                      and then Samples <= Max_Profile
                      and then Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Values'Length (1) >= 2
                      and then Values'Length (2) >= 2,
          Global => null;
   --  Sample f along straight transect A→B (Wikipedia plan/profile view).

   function Empty_Profile return Transect_Profile
     with Post   => Empty_Profile'Result.Count = 0,
          Global => null;

   ---------------------------------------------------------------------------
   -- 9. Field fixtures
   ---------------------------------------------------------------------------

   procedure Fill_Hill_Field
     (Values    : out Scalar_Field;
      Positions : out Position_Field;
      Origin    : Point2;
      Spacing   : Real;
      Center    : Point2;
      Peak      : Real := 10.0;
      Width     : Real := 3.0)
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Spacing > 0.0
                      and then Width > 0.0,
          Global => null;
   --  Gaussian-like hill: Peak * exp(−r² / Width²).

   procedure Fill_Valley_Field
     (Values    : out Scalar_Field;
      Positions : out Position_Field;
      Origin    : Point2;
      Spacing   : Real;
      Center    : Point2;
      Floor_H   : Real := 0.0;
      Depth     : Real := 8.0;
      Width     : Real := 3.0)
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Spacing > 0.0
                      and then Width > 0.0,
          Global => null;
   --  Depression: Floor_H − Depth * exp(−r² / Width²).

   procedure Fill_Ridge_Field
     (Values    : out Scalar_Field;
      Positions : out Position_Field;
      Origin    : Point2;
      Spacing   : Real;
      Axis_Y    : Real;
      Peak      : Real := 10.0;
      Width     : Real := 2.0)
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Spacing > 0.0
                      and then Width > 0.0,
          Global => null;
   --  Linear ridge along X: Peak * exp(−(Y−Axis_Y)² / Width²).

   ---------------------------------------------------------------------------
   -- Polyline helpers
   ---------------------------------------------------------------------------

   function Empty_Polyline return Polyline
     with Post   => Empty_Polyline'Result.Count = 0,
          Global => null;

   function Count_Segments (P : Polyline) return Natural
     with Post   => Count_Segments'Result = Natural (P.Count),
          Global => null;

   procedure Append_Segment (P : in out Polyline; S : Segment)
     with Global => null;
   --  Raises Capacity_Exceeded when full.

   function Total_Length (P : Polyline) return Non_Negative
     with Global => null;

end Contour_Lines;
