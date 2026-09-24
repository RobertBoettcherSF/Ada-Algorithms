package Warnock_Algorithm with
   SPARK_Mode => Off
is

   --  ----------------------------------------------------------------------
   --  Domain Types and Basic Geometry
   --  ----------------------------------------------------------------------

   type Real is digits 12;

   type Color_Component is range 0 .. 255;

   type RGBA_Color is record
      Red   : Color_Component := 0;
      Green : Color_Component := 0;
      Blue  : Color_Component := 0;
      Alpha : Color_Component := 255;
   end record;

   Black : constant RGBA_Color := (Red => 0,   Green => 0,   Blue => 0,   Alpha => 255);
   White : constant RGBA_Color := (Red => 255, Green => 255, Blue => 255, Alpha => 255);
   Red   : constant RGBA_Color := (Red => 255, Green => 0,   Blue => 0,   Alpha => 255);
   Green : constant RGBA_Color := (Red => 0,   Green => 255, Blue => 0,   Alpha => 255);
   Blue  : constant RGBA_Color := (Red => 0,   Green => 0,   Blue => 255, Alpha => 255);

   type Point_2D is record
      X : Real := 0.0;
      Y : Real := 0.0;
   end record;

   type Viewport_Area is record
      Min_X : Real := 0.0;
      Min_Y : Real := 0.0;
      Max_X : Real := 1.0;
      Max_Y : Real := 1.0;
   end record;

   type Plane_Equation is record
      A : Real := 0.0;
      B : Real := 0.0;
      C : Real := 1.0;
      D : Real := 0.0;
   end record;

   type Point_Array is array (Positive range <>) of Point_2D;

   subtype Polygon_Vertex_Count is Positive range 1 .. 64;

   type Polygon_Record (Vertex_Count : Polygon_Vertex_Count := 3) is record
      Vertices : Point_Array (1 .. Vertex_Count);
      Plane    : Plane_Equation;
      Color    : RGBA_Color;
   end record;

   type Polygon_Array is array (Positive range <>) of Polygon_Record;

   type Relationship_Type is
     (Disjoint_Polygon,
      Contained_Polygon,
      Surrounding_Polygon,
      Intersecting_Polygon);

   type Quad_Split is array (1 .. 4) of Viewport_Area;

   type Pixel_Index is range 0 .. 4096;

   type Framebuffer is array
     (Pixel_Index range <>, Pixel_Index range <>) of RGBA_Color;

   --  Exceptions
   Invalid_Area_Error     : exception;
   Degenerate_Plane_Error : exception;
   Invalid_Vertex_Error   : exception;

   --  ----------------------------------------------------------------------
   --  Helper & Geometric Query Subprograms
   --  ----------------------------------------------------------------------

   function Is_Valid_Area (Area : Viewport_Area) return Boolean;

   function Area_Width (Area : Viewport_Area) return Real with
      Pre => Is_Valid_Area (Area);

   function Area_Height (Area : Viewport_Area) return Real with
      Pre => Is_Valid_Area (Area);

   function Area_Center (Area : Viewport_Area) return Point_2D with
      Pre => Is_Valid_Area (Area);

   function Split_Area (Area : Viewport_Area) return Quad_Split with
      Pre => Is_Valid_Area (Area);

   function Evaluate_Z
     (Plane : Plane_Equation;
      P     : Point_2D) return Real with
      Pre => Plane.C /= 0.0;

   function Classify_Relationship
     (Poly : Polygon_Record;
      Area : Viewport_Area) return Relationship_Type with
      Pre => Is_Valid_Area (Area) and then Poly.Vertex_Count >= 3;

   function Find_Frontmost_Surrounding
     (Polygons : Polygon_Array;
      Area     : Viewport_Area) return Natural with
      Pre => Is_Valid_Area (Area);

   --  ----------------------------------------------------------------------
   --  Warnock Algorithm Variants
   --  ----------------------------------------------------------------------

   --  Variant 1: Standard Recursive Point/Sample Resolution.
   --  Subdivides area until resolution threshold is met or simple case occurs.
   procedure Render_Standard
     (Polygons         : Polygon_Array;
      Area             : Viewport_Area;
      Background_Color : RGBA_Color;
      Resolution_Limit : Real;
      Output_Color     : out RGBA_Color) with
      Pre => Is_Valid_Area (Area) and then Resolution_Limit > 0.0;

   --  Variant 2: Depth-Limited Rasterization into a Discrete Framebuffer.
   --  Rasterizes geometry into an allocated grid using Warnock quadtree splits.
   procedure Render_Framebuffer
     (Polygons         : Polygon_Array;
      Area             : Viewport_Area;
      Background_Color : RGBA_Color;
      Buffer           : in out Framebuffer;
      Max_Depth        : Natural) with
      Pre => Is_Valid_Area (Area);

   --  Variant 3: Adaptive Subdivision with Anti-Aliased Area Supersampling.
   --  Averages colors across 4 sub-quadrants when boundary ambiguity persists.
   procedure Render_Adaptive_Supersampled
     (Polygons         : Polygon_Array;
      Area             : Viewport_Area;
      Background_Color : RGBA_Color;
      Resolution_Limit : Real;
      Output_Color     : out RGBA_Color) with
      Pre => Is_Valid_Area (Area) and then Resolution_Limit > 0.0;

   --  Variant 4: Diagnostic Quadtree Node Counter.
   --  Measures spatial subdivision complexity by returning total visited nodes.
   procedure Render_Diagnostic_Stats
     (Polygons         : Polygon_Array;
      Area             : Viewport_Area;
      Background_Color : RGBA_Color;
      Resolution_Limit : Real;
      Total_Nodes      : out Natural;
      Max_Depth_Hit    : out Natural) with
      Pre => Is_Valid_Area (Area) and then Resolution_Limit > 0.0;

end Warnock_Algorithm;
