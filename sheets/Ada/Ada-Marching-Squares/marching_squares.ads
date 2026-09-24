--  Marching_Squares — Ada 2023 educational implementation of the
--  marching squares contouring algorithm: 16 cell cases, edge
--  interpolation, saddle disambiguation, isolines and isobands on
--  grids, and isolines on triangles.
--  Based on Wikipedia "Marching squares".

pragma Ada_2022;

package Marching_Squares
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

   --  Cell corners (clockwise from top-left, matching Wikipedia MSB→LSB):
   --    0 = top-left (NW), 1 = top-right (NE),
   --    2 = bottom-right (SE), 3 = bottom-left (SW)
   subtype Cell_Corner is Natural range 0 .. 3;

   --  Cell edges: 0=top, 1=right, 2=bottom, 3=left
   subtype Cell_Edge is Natural range 0 .. 3;

   --  4-bit case index from corner signs (0..15).
   subtype Case_Index is Natural range 0 .. 15;

   --  Triangle vertex index for March_Triangle_Isoline.
   subtype Tri_Vertex is Natural range 0 .. 2;

   type Segment is record
      A, B : Point2;
   end record;

   --  At most two isoline segments per square cell.
   type Small_Segment_List is array (1 .. 2) of Segment;

   Max_Segments : constant Positive := 16_384;
   subtype Segment_Count is Natural range 0 .. Max_Segments;
   subtype Segment_Index is Positive range 1 .. Max_Segments;
   type Segment_Array is array (Segment_Index) of Segment;

   type Polyline is record
      Segs  : Segment_Array;
      Count : Segment_Count := 0;
   end record;

   type Polyline_Stats is record
      Segment_Count : Natural := 0;
      Min_Corner    : Point2  := (0.0, 0.0);
      Max_Corner    : Point2  := (0.0, 0.0);
      Total_Length  : Non_Negative := 0.0;
   end record;

   --  Simple polygon for one isoband cell (triangle fan / ring).
   Max_Band_Verts : constant Positive := 8;
   subtype Band_Vert_Count is Natural range 0 .. Max_Band_Verts;
   type Band_Vertex_Array is array (1 .. Max_Band_Verts) of Point2;

   type Band_Polygon is record
      Verts : Band_Vertex_Array;
      Count : Band_Vert_Count := 0;
   end record;

   Max_Bands : constant Positive := 8_192;
   subtype Band_Count is Natural range 0 .. Max_Bands;
   subtype Band_Index is Positive range 1 .. Max_Bands;
   type Band_Array is array (Band_Index) of Band_Polygon;

   type Band_List is record
      Bands : Band_Array;
      Count : Band_Count := 0;
   end record;

   --  Educational scalar grids stay modest (samples per axis).
   Max_Grid_Dim : constant Positive := 64;
   subtype Grid_Dim is Positive range 2 .. Max_Grid_Dim;

   --  Unconstrained 2-D scalar field (I = column/X, J = row/Y).
   type Scalar_Field is
     array (Natural range <>, Natural range <>) of Real;

   type Position_Field is
     array (Natural range <>, Natural range <>) of Point2;

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

   function Cell_Corner_Offset (C : Cell_Corner) return Vec2
     with Global => null;
   --  Local (0/1,0/1) offset: 0=(0,1), 1=(1,1), 2=(1,0), 3=(0,0)
   --  in unit-cell coordinates with Y upward (top = Y=1).

   ---------------------------------------------------------------------------
   -- 1. Cell_Case_Index
   ---------------------------------------------------------------------------

   function Cell_Case_Index
     (TL, TR, BR, BL : Real;
      Isolevel       : Real) return Case_Index
     with Global => null;
   --  Bit set when corner value >= Isolevel.
   --  Bits: TL=8, TR=4, BR=2, BL=1 (MSB top-left → LSB bottom-left).

   ---------------------------------------------------------------------------
   -- 2. Interpolate_Edge
   ---------------------------------------------------------------------------

   function Interpolate_Edge
     (P0, P1 : Point2;
      V0, V1 : Real;
      Isolevel : Real) return Point2
     with Global => null;
   --  Linearly interpolate the isolevel crossing on segment P0–P1.
   --  Raises Degenerate_Geometry when V0 = V1 (no unique crossing).

   ---------------------------------------------------------------------------
   -- 3. Lookup_Segments / March_Cell_Isoline
   ---------------------------------------------------------------------------

   procedure Lookup_Segments
     (Index      : Case_Index;
      Center_Avg : Real;
      Isolevel   : Real;
      Edge_A     : out Integer;
      Edge_B     : out Integer;
      Edge_C     : out Integer;
      Edge_D     : out Integer;
      Seg_Count  : out Natural)
     with Post   => Seg_Count <= 2,
          Global => null;
   --  16-case edge-pair table. Edge ids 0..3; unused edges are -1.
   --  Ambiguous cases 5 and 10 use Center_Avg vs Isolevel.

   procedure March_Cell_Isoline
     (TL, TR, BR, BL : Point2;
      V_TL, V_TR, V_BR, V_BL : Real;
      Isolevel : Real;
      Out_Segs : out Small_Segment_List;
      Out_Count : out Natural)
     with Post   => Out_Count <= 2,
          Global => null;
   --  Emit 0..2 isoline segments for one 2x2 cell (with saddle resolve).

   ---------------------------------------------------------------------------
   -- 4. Disambiguate_Saddle
   ---------------------------------------------------------------------------

   function Disambiguate_Saddle
     (TL, TR, BR, BL : Real;
      Isolevel       : Real) return Boolean
     with Global => null;
   --  Average the four corner samples; return True when the cell-center
   --  average is >= Isolevel (the "center above" saddle connection).

   function Saddle_Center_Above
     (Center_Avg : Real;
      Isolevel   : Real) return Boolean
     with Global => null;
   --  True when Center_Avg >= Isolevel.

   ---------------------------------------------------------------------------
   -- 5. March_Grid_Isolines
   ---------------------------------------------------------------------------

   function March_Grid_Isolines
     (Values    : Scalar_Field;
      Positions : Position_Field;
      Isolevel  : Real) return Polyline
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Values'Length (1) >= 2
                      and then Values'Length (2) >= 2,
          Global => null;
   --  March every cell of a 2-D scalar grid into a segment list.
   --  Raises Invalid_Argument when any axis exceeds Max_Grid_Dim.

   ---------------------------------------------------------------------------
   -- 6. March_Cell_Isoband / March_Grid_Isobands
   ---------------------------------------------------------------------------

   procedure March_Cell_Isoband
     (TL, TR, BR, BL : Point2;
      V_TL, V_TR, V_BR, V_BL : Real;
      Lo, Hi : Real;
      Poly : out Band_Polygon)
     with Pre    => Lo <= Hi,
          Global => null;
   --  Emit a simple polygon for the portion of the cell where Lo <= f <= Hi.

   function March_Grid_Isobands
     (Values    : Scalar_Field;
      Positions : Position_Field;
      Lo, Hi    : Real) return Band_List
     with Pre    => Lo <= Hi
                      and then Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Values'Length (1) >= 2
                      and then Values'Length (2) >= 2,
          Global => null;

   ---------------------------------------------------------------------------
   -- 7. March_Triangle_Isoline
   ---------------------------------------------------------------------------

   procedure March_Triangle_Isoline
     (P0, P1, P2 : Point2;
      S0, S1, S2 : Real;
      Isolevel   : Real;
      Out_Segs   : out Small_Segment_List;
      Out_Count  : out Natural)
     with Post   => Out_Count <= 1,
          Global => null;
   --  Contour a single triangle (3 corners, 8 cases); 0 or 1 segment.

   ---------------------------------------------------------------------------
   -- 8. Field fixtures
   ---------------------------------------------------------------------------

   procedure Fill_Height_Field
     (Values    : out Scalar_Field;
      Positions : out Position_Field;
      Origin    : Point2;
      Spacing   : Real;
      Slope_X   : Real;
      Slope_Y   : Real;
      Base      : Real := 0.0)
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Spacing > 0.0,
          Global => null;
   --  Sample f = Base + Slope_X*X + Slope_Y*Y on a regular lattice.

   procedure Fill_Radial_Field
     (Values    : out Scalar_Field;
      Positions : out Position_Field;
      Origin    : Point2;
      Spacing   : Real;
      Center    : Point2;
      Peak      : Real := 1.0)
     with Pre    => Values'First (1) = Positions'First (1)
                      and then Values'Last (1) = Positions'Last (1)
                      and then Values'First (2) = Positions'First (2)
                      and then Values'Last (2) = Positions'Last (2)
                      and then Spacing > 0.0,
          Global => null;
   --  Sample f = Peak - |P−Center| (cone / radial height).

   ---------------------------------------------------------------------------
   -- 9. Count_Segments / Polyline_Stats helpers
   ---------------------------------------------------------------------------

   function Count_Segments (P : Polyline) return Natural
     with Post   => Count_Segments'Result = Natural (P.Count),
          Global => null;

   function Compute_Polyline_Stats (P : Polyline) return Polyline_Stats
     with Global => null;

   function Empty_Polyline return Polyline
     with Post   => Empty_Polyline'Result.Count = 0,
          Global => null;

   function Empty_Band_List return Band_List
     with Post   => Empty_Band_List'Result.Count = 0,
          Global => null;

   procedure Append_Segment (P : in out Polyline; S : Segment)
     with Global => null;
   --  Raises Capacity_Exceeded when full.

   procedure Append_Band (L : in out Band_List; B : Band_Polygon)
     with Global => null;
   --  Raises Capacity_Exceeded when full; skips empty polygons.

end Marching_Squares;
