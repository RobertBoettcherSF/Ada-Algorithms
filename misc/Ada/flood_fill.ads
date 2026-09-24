--  Flood_Fill — Ada 2023 educational implementation of seed / flood fill
--  variants (recursive 4/8-way, stack/queue iterative, span/scanline,
--  boundary fill, pattern fill, connected-region measure).
--  Based on Wikipedia "Flood fill" and classic CG literature.

pragma Ada_2022;

package Flood_Fill
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Educational grids stay modest so recursive demos cannot blow the stack
   --  in tests; iterative variants scale to Max_Dim x Max_Dim safely.
   Max_Dim : constant Positive := 64;

   subtype Dim_Range is Positive range 1 .. Max_Dim;
   subtype Color_Id  is Natural range 0 .. 255;

   type Pixel_Coord is record
      Row : Dim_Range := 1;
      Col : Dim_Range := 1;
   end record;

   type Connectivity is (Four_Way, Eight_Way);

   --  Unconstrained 2-D colour grid (row, column). Callers must keep both
   --  dimensions within Max_Dim for stack/queue/span helpers.
   type Grid is array (Positive range <>, Positive range <>) of Color_Id;

   --  Repeating pattern tile for Pattern_Flood_Fill.
   Max_Pattern : constant Positive := 8;
   subtype Pattern_Dim is Positive range 1 .. Max_Pattern;
   type Pattern_Grid is
     array (Positive range <>, Positive range <>) of Color_Id;

   type Fill_Result is record
      Pixels_Changed : Natural := 0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Out_Of_Bounds    : exception;
   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Grid helpers
   ---------------------------------------------------------------------------

   function In_Bounds
     (G : Grid; Row, Col : Integer) return Boolean
     with Global => null;

   function Get_Color
     (G : Grid; P : Pixel_Coord) return Color_Id
     with Pre    => In_Bounds (G, Integer (P.Row), Integer (P.Col)),
          Global => null;

   procedure Set_Color
     (G : in out Grid; P : Pixel_Coord; C : Color_Id)
     with Pre    => In_Bounds (G, Integer (P.Row), Integer (P.Col)),
          Global => null;

   function Count_Color (G : Grid; C : Color_Id) return Natural
     with Global => null;

   function Same_Grid (A, B : Grid) return Boolean
     with Pre    => A'First (1) = B'First (1)
                      and then A'Last (1) = B'Last (1)
                      and then A'First (2) = B'First (2)
                      and then A'Last (2) = B'Last (2),
          Global => null;

   --  Raise Invalid_Argument if G exceeds Max_Dim in either axis, or if
   --  Start is outside G.
   procedure Validate_Start (G : Grid; Start : Pixel_Coord)
     with Global => null;

   ---------------------------------------------------------------------------
   -- 1. Classic recursive four-way seed fill
   ---------------------------------------------------------------------------

   procedure Flood_Fill_Recursive_4
     (G                  : in out Grid;
      Start              : Pixel_Coord;
      Target, Replacement : Color_Id;
      Result             : out Fill_Result)
     with Pre    => In_Bounds (G, Integer (Start.Row), Integer (Start.Col)),
          Global => null;

   ---------------------------------------------------------------------------
   -- 2. Classic recursive eight-way seed fill (corners connected)
   ---------------------------------------------------------------------------

   procedure Flood_Fill_Recursive_8
     (G                  : in out Grid;
      Start              : Pixel_Coord;
      Target, Replacement : Color_Id;
      Result             : out Fill_Result)
     with Pre    => In_Bounds (G, Integer (Start.Row), Integer (Start.Col)),
          Global => null;

   ---------------------------------------------------------------------------
   -- 3. Iterative explicit-stack (DFS-like) flood fill
   ---------------------------------------------------------------------------

   procedure Flood_Fill_Stack
     (G                  : in out Grid;
      Start              : Pixel_Coord;
      Target, Replacement : Color_Id;
      Conn               : Connectivity;
      Result             : out Fill_Result)
     with Pre    => In_Bounds (G, Integer (Start.Row), Integer (Start.Col)),
          Global => null;

   ---------------------------------------------------------------------------
   -- 4. Iterative queue (BFS-like) flood fill
   ---------------------------------------------------------------------------

   procedure Flood_Fill_Queue
     (G                  : in out Grid;
      Start              : Pixel_Coord;
      Target, Replacement : Color_Id;
      Conn               : Connectivity;
      Result             : out Fill_Result)
     with Pre    => In_Bounds (G, Integer (Start.Row), Integer (Start.Col)),
          Global => null;

   ---------------------------------------------------------------------------
   -- 5. Span / scanline filling (four-way connectivity)
   ---------------------------------------------------------------------------

   procedure Flood_Fill_Span
     (G                  : in out Grid;
      Start              : Pixel_Coord;
      Target, Replacement : Color_Id;
      Result             : out Fill_Result)
     with Pre    => In_Bounds (G, Integer (Start.Row), Integer (Start.Col)),
          Global => null;

   ---------------------------------------------------------------------------
   -- 6. Boundary fill (fill until border colour; 4- and 8-way)
   ---------------------------------------------------------------------------

   procedure Boundary_Fill_4
     (G            : in out Grid;
      Start        : Pixel_Coord;
      Border, Fill : Color_Id;
      Result       : out Fill_Result)
     with Pre    => In_Bounds (G, Integer (Start.Row), Integer (Start.Col)),
          Global => null;

   procedure Boundary_Fill_8
     (G            : in out Grid;
      Start        : Pixel_Coord;
      Border, Fill : Color_Id;
      Result       : out Fill_Result)
     with Pre    => In_Bounds (G, Integer (Start.Row), Integer (Start.Col)),
          Global => null;

   ---------------------------------------------------------------------------
   -- 7. Pattern flood fill (visited-mask so Inside stays sound)
   ---------------------------------------------------------------------------

   procedure Pattern_Flood_Fill
     (G       : in out Grid;
      Start   : Pixel_Coord;
      Target  : Color_Id;
      Pattern : Pattern_Grid;
      Conn    : Connectivity := Four_Way;
      Result  : out Fill_Result)
     with Pre    => In_Bounds (G, Integer (Start.Row), Integer (Start.Col))
                      and then Pattern'Length (1) >= 1
                      and then Pattern'Length (2) >= 1,
          Global => null;

   ---------------------------------------------------------------------------
   -- 8. Count / measure connected region without mutating (or with count)
   ---------------------------------------------------------------------------

   function Count_Connected
     (G      : Grid;
      Start  : Pixel_Coord;
      Target : Color_Id;
      Conn   : Connectivity := Four_Way) return Natural
     with Pre    => In_Bounds (G, Integer (Start.Row), Integer (Start.Col)),
          Global => null;

   --  Alias framing: measure the region that a seed fill would cover.
   function Measure_Region
     (G      : Grid;
      Start  : Pixel_Coord;
      Target : Color_Id;
      Conn   : Connectivity := Four_Way) return Natural
     with Pre    => In_Bounds (G, Integer (Start.Row), Integer (Start.Col)),
          Global => null;

end Flood_Fill;
