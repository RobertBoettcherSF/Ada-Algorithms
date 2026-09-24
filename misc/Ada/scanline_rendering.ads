--  Package specification for Scanline Rendering (Ada 2023)
--  Implements classic scanline rendering algorithms operating on 2D/3D polygons,
--  including 2D polygon fill with parity/even-odd rule, Active Edge Table (AET)
--  rasterization, depth-buffered (Z-buffer) scanline rendering for 3D scenes,
--  and scanline hidden-surface removal with edge-table processing.

package Scanline_Rendering with
  SPARK_Mode => Off
is

   --  Coordinate, color, and depth domain types
   type Screen_Coordinate_X is range 0 .. 1919;
   type Screen_Coordinate_Y is range 0 .. 1079;

   type World_Coordinate is new Float;
   subtype Depth_Value is Float;

   type Color_Component is range 0 .. 255;
   type Pixel_Color is record
      Red   : Color_Component := 0;
      Green : Color_Component := 0;
      Blue  : Color_Component := 0;
   end record;

   Black : constant Pixel_Color := (Red => 0,   Green => 0,   Blue => 0);
   White : constant Pixel_Color := (Red => 255, Green => 255, Blue => 255);
   Red   : constant Pixel_Color := (Red => 255, Green => 0,   Blue => 0);
   Green : constant Pixel_Color := (Red => 0,   Green => 255, Blue => 0);
   Blue  : constant Pixel_Color := (Red => 0,   Green => 0,   Blue => 255);

   --  2D geometric primitives
   type Point_2D is record
      X : Screen_Coordinate_X;
      Y : Screen_Coordinate_Y;
   end record;

   type Point_2D_Array is array (Positive range <>) of Point_2D;

   --  3D geometric primitives
   type Point_3D is record
      X : Screen_Coordinate_X;
      Y : Screen_Coordinate_Y;
      Z : Depth_Value;
   end record;

   type Point_3D_Array is array (Positive range <>) of Point_3D;

   type Polygon_3D is record
      Vertices : Point_3D_Array (1 .. 3);
      Color    : Pixel_Color;
   end record;

   type Polygon_3D_Array is array (Positive range <>) of Polygon_3D;

   --  Frame buffer and Z-buffer representations
   type Frame_Buffer is array (Screen_Coordinate_X, Screen_Coordinate_Y) of Pixel_Color;
   type Depth_Buffer is array (Screen_Coordinate_X, Screen_Coordinate_Y) of Depth_Value;

   --  Active Edge representation used in scanline rasterization
   type Edge_2D is record
      Y_Max     : Screen_Coordinate_Y;
      Current_X : Float;
      Inv_Slope : Float;  -- dx / dy
   end record;

   --  Exceptions
   Degenerate_Polygon_Error : exception;
   Invalid_Buffer_Range     : exception;

   --  Subprogram declarations with contracts

   --  Helper: Clears the frame buffer to a solid background color
   procedure Clear_Frame_Buffer
     (Buffer : in out Frame_Buffer;
      Color  : in     Pixel_Color := Black)
   with
      Global => null;

   --  Helper: Clears the depth buffer to a specific far-plane distance
   procedure Clear_Depth_Buffer
     (Buffer : in out Depth_Buffer;
      Depth  : in     Depth_Value := Depth_Value'Last)
   with
      Global => null;

   --  Variant 1: 2D Scanline Polygon Fill (Even-Odd / Parity rule)
   --  Fills an arbitrary simple or non-convex 2D polygon into the frame buffer.
   procedure Render_Polygon_2D
     (Buffer   : in out Frame_Buffer;
      Vertices : in     Point_2D_Array;
      Color    : in     Pixel_Color)
   with
      Pre    => Vertices'Length >= 3,
      Global => null;

   --  Variant 2: 3D Scanline Rendering with Span-level Z-Buffering
   --  Renders multiple 3D triangles using scanline interpolation of depth (Z)
   --  and applies hidden-surface determination per pixel scan.
   procedure Render_Scene_3D_ZBuffer
     (FB       : in out Frame_Buffer;
      ZB       : in out Depth_Buffer;
      Polygons : in     Polygon_3D_Array)
   with
      Global => null;

   --  Variant 3: Scanline Hidden-Surface Removal (Span-based segment classification)
   --  Determines visible spans across a single scanline among intersecting planar spans
   --  without full 2D screen depth allocation.
   procedure Render_Scanline_Spans
     (FB       : in out Frame_Buffer;
      Scan_Y   : in     Screen_Coordinate_Y;
      Polygons : in     Polygon_3D_Array)
   with
      Global => null;

   --  Helper queries for testing and validation
   function Count_Colored_Pixels
     (Buffer : in Frame_Buffer;
      Color  : in Pixel_Color) return Natural
   with
      Global => null;

   function Is_Point_Inside_Convex_Hull
     (Pt       : in Point_2D;
      Vertices : in Point_2D_Array) return Boolean
   with
      Pre    => Vertices'Length >= 3,
      Global => null;

end Scanline_Rendering;
