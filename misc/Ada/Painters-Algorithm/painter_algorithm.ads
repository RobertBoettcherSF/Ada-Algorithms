-- Package specification for the Painter's Algorithm in Ada 2023.
-- Implements depth sorting, rasterization (back-to-front), cycle detection
-- (topological sort for cyclic overlap resolution), and Newell-Newell-Sancha
-- priority sorting heuristics.

package Painter_Algorithm is

   -- Domain-specific floating-point and screen coordinate types
   type Coordinate is digits 6;
   type Depth_Value is digits 6;

   subtype Screen_X is Natural range 0 .. 1023;
   subtype Screen_Y is Natural range 0 .. 1023;

   -- Color representation (RGBA 8-bit channels)
   type Color_Component is mod 256;
   type RGBA_Color is record
      Red   : Color_Component := 0;
      Green : Color_Component := 0;
      Blue  : Color_Component := 0;
      Alpha : Color_Component := 255;
   end record;

   Black_Color : constant RGBA_Color := (Red => 0, Green => 0, Blue => 0, Alpha => 255);
   White_Color : constant RGBA_Color := (Red => 255, Green => 255, Blue => 255, Alpha => 255);

   -- 2D and 3D geometric point primitives
   type Point_2D is record
      X : Coordinate := 0.0;
      Y : Coordinate := 0.0;
   end record;

   type Point_3D is record
      X : Coordinate  := 0.0;
      Y : Coordinate  := 0.0;
      Z : Depth_Value := 0.0;
   end record;

   subtype Vertex_Count_Range is Positive range 1 .. 64;
   type Vertex_Array is array (Positive range <>) of Point_3D;

   -- Convex polygon representation with at least 3 vertices
   type Polygon (Vertex_Count : Vertex_Count_Range := 3) is record
      Id       : Positive;
      Color    : RGBA_Color;
      Vertices : Vertex_Array (1 .. Vertex_Count);
   end record;

   type Polygon_Array is array (Positive range <>) of Polygon;

   -- Framebuffer grid
   type Framebuffer is array (Screen_X range <>, Screen_Y range <>) of RGBA_Color;

   -- Exceptions
   Invalid_Polygon_Error : exception;
   Cyclic_Overlap_Error  : exception;
   Index_Error           : exception;

   ----------------------------------------------------------------------------
   -- Geometry and Depth Helper Functions
   ----------------------------------------------------------------------------

   function Min_Depth (P : Polygon) return Depth_Value is
     (Depth_Value'Min (P.Vertices (P.Vertices'First).Z,
                       (if P.Vertices'Length > 1
                        then Min_Depth ((Vertex_Count => P.Vertex_Count - 1,
                                         Id           => P.Id,
                                         Color        => P.Color,
                                         Vertices     => P.Vertices (P.Vertices'First + 1 .. P.Vertices'Last)))
                        else P.Vertices (P.Vertices'First).Z)))
   with
     Pre => P.Vertex_Count >= 1;

   function Max_Depth (P : Polygon) return Depth_Value;

   function Centroid_Depth (P : Polygon) return Depth_Value
   with
     Pre => P.Vertex_Count >= 3;

   function Bounding_Boxes_Overlap_2D (P, Q : Polygon) return Boolean
   with
     Pre => P.Vertex_Count >= 3 and then Q.Vertex_Count >= 3;

   function Point_In_Polygon_2D (Pt : Point_2D; Poly : Polygon) return Boolean
   with
     Pre => Poly.Vertex_Count >= 3;

   ----------------------------------------------------------------------------
   -- Variant 1: Standard Depth-Sort Painter's Algorithm
   -- Sorts polygons strictly by their farthest depth (max Z) and paints them.
   ----------------------------------------------------------------------------

   procedure Sort_Polygons_Depth (Polygons : in out Polygon_Array)
   with
     Post => (if Polygons'Length > 1 then
                (for all I in Polygons'First .. Polygons'Last - 1 =>
                   Max_Depth (Polygons (I)) >= Max_Depth (Polygons (I + 1))));

   procedure Render_Standard (Polygons : in out Polygon_Array;
                              Buffer   : in out Framebuffer)
   with
     Global => null;

   ----------------------------------------------------------------------------
   -- Variant 2: Centroid-Based Painter's Algorithm
   -- Sorts polygons by their geometric centroid Z coordinate.
   ----------------------------------------------------------------------------

   procedure Sort_Polygons_Centroid (Polygons : in out Polygon_Array)
   with
     Post => (if Polygons'Length > 1 then
                (for all I in Polygons'First .. Polygons'Last - 1 =>
                   Centroid_Depth (Polygons (I)) >= Centroid_Depth (Polygons (I + 1))));

   procedure Render_Centroid (Polygons : in out Polygon_Array;
                              Buffer   : in out Framebuffer)
   with
     Global => null;

   ----------------------------------------------------------------------------
   -- Variant 3: Newell-Newell-Sancha Depth-Sort with Overlap Resolution
   -- Applies the 5-step Newell priority tests to resolve ordering ambiguity.
   ----------------------------------------------------------------------------

   function Polygons_Must_Precede (P, Q : Polygon) return Boolean
   with
     Pre => P.Vertex_Count >= 3 and then Q.Vertex_Count >= 3;

   procedure Render_Newell_Sorted (Polygons : in out Polygon_Array;
                                   Buffer   : in out Framebuffer)
   with
     Global => null;

   ----------------------------------------------------------------------------
   -- Variant 4: Cyclic Overlap Detection & Topological Painter's Algorithm
   -- Builds a dependency DAG and paints in topological order; detects cycles.
   ----------------------------------------------------------------------------

   procedure Render_Topological (Polygons : in Polygon_Array;
                                 Buffer   : in out Framebuffer)
   with
     Global => null;

   ----------------------------------------------------------------------------
   -- Utility Procedures
   ----------------------------------------------------------------------------

   procedure Clear_Framebuffer (Buffer : in out Framebuffer;
                                Color  : RGBA_Color := Black_Color);

   procedure Rasterize_Polygon (P      : Polygon;
                                Buffer : in out Framebuffer)
   with
     Pre => P.Vertex_Count >= 3;

end Painter_Algorithm;
