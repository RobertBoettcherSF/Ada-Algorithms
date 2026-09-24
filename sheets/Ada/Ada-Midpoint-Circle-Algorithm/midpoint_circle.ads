package Midpoint_Circle with
   SPARK_Mode => Off
is

   -- Domain-specific coordinate and dimension types
   type Coordinate is range -1_000_000 .. 1_000_000;
   type Radius_Type is range 0 .. 1_000_000;

   type Point is record
      X : Coordinate;
      Y : Coordinate;
   end record;

   type Point_Array is array (Positive range <>) of Point;

   type Horizontal_Span is record
      Y       : Coordinate;
      Left_X  : Coordinate;
      Right_X : Coordinate;
   end record;

   type Span_Array is array (Positive range <>) of Horizontal_Span;

   -- Exceptions for error handling
   Buffer_Too_Small : exception;

   -- Returns the theoretical maximum number of boundary points for a circle of given radius.
   -- A circle of radius R visits at most R + 1 octant steps, generating up to 8 * (R + 1) points.
   function Max_Boundary_Points (Radius : Radius_Type) return Natural is
     (if Radius = 0 then 1 else Natural (Radius + 1) * 8);

   -- Returns the maximum horizontal spans needed to render a filled circle of given radius.
   function Max_Filled_Spans (Radius : Radius_Type) return Natural is
     (if Radius = 0 then 1 else Natural (Radius * 2 + 1));

   -- Evaluates the implicit circle function: f(x, y) = (x - X0)^2 + (y - Y0)^2 - R^2
   function Implicit_Circle_Function
     (Pt     : Point;
      Center : Point;
      Radius : Radius_Type) return Long_Long_Integer;

   -- Computes the Chebyshev distance (L_inf metric) between two points
   function Chebyshev_Distance (P1, P2 : Point) return Coordinate;

   -- Variant 1: Standard Midpoint Circle Algorithm (Octant symmetry, outline generation)
   procedure Generate_Circle_Outline
     (Center : Point;
      Radius : Radius_Type;
      Output : out Point_Array;
      Count  : out Natural)
   with
      Pre  => Output'Length >= Max_Boundary_Points (Radius),
      Post => Count <= Output'Length;

   -- Variant 2: Jesko's Method (Optimized decision variable tracking using inner differences)
   procedure Generate_Circle_Jesko
     (Center : Point;
      Radius : Radius_Type;
      Output : out Point_Array;
      Count  : out Natural)
   with
      Pre  => Output'Length >= Max_Boundary_Points (Radius),
      Post => Count <= Output'Length;

   -- Variant 3: Filled Circle Rasterizer (Generates non-overlapping horizontal spans)
   procedure Generate_Filled_Circle_Spans
     (Center : Point;
      Radius : Radius_Type;
      Output : out Span_Array;
      Count  : out Natural)
   with
      Pre  => Output'Length >= Max_Filled_Spans (Radius),
      Post => Count <= Output'Length;

   -- Variant 4: Point classification against circle boundary
   type Location_Type is (Inside, On_Boundary, Outside);

   function Classify_Point
     (Pt     : Point;
      Center : Point;
      Radius : Radius_Type) return Location_Type;

   -- Variant 5: Direct pixel-drawing callback interface (generic)
   generic
      with procedure Put_Pixel (X, Y : Coordinate);
   procedure Draw_Circle (Center : Point; Radius : Radius_Type);

end Midpoint_Circle;
