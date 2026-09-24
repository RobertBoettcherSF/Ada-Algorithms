-------------------------------------------------------------------------------
--  Package: Xiaolin_Wu
--
--  Description:
--    Implementation of Xiaolin Wu's antialiased line algorithm and variants:
--      1. Standard Xiaolin Wu line rasterization (drawing across a 2D buffer).
--      2. Pixel callback variant for memory-efficient streaming rendering.
--      3. Alpha blending variant with configurable background/foreground colors.
--      4. Clamped / Clipped viewport line rasterization.
--
--  Standards: Ada 2022 / Ada 2023 (ISO/IEC 8652:2023)
-------------------------------------------------------------------------------

package Xiaolin_Wu is

   -- Coordinate and intensity types
   type Coordinate is range -16#7FFF_FFFF# .. 16#7FFF_FFFF#;
   type Pixel_Coordinate is range 0 .. 16#7FFF_FFFF#;
   type Real is digits 12;

   subtype Intensity is Real range 0.0 .. 1.0;
   subtype Byte is Natural range 0 .. 255;

   -- Color record for RGBA rendering and blending
   type RGBA_Color is record
      Red   : Byte := 0;
      Green : Byte := 0;
      Blue  : Byte := 0;
      Alpha : Byte := 255;
   end record;

   type Point_2D is record
      X : Real;
      Y : Real;
   end record;

   -- Framebuffer 2D grid
   type Intensity_Grid is
     array (Pixel_Coordinate range <>, Pixel_Coordinate range <>) of Intensity;

   type Color_Grid is
     array (Pixel_Coordinate range <>, Pixel_Coordinate range <>) of RGBA_Color;

   -- Callback profile for streaming rasterizer (anonymous access-to-subprogram
   -- to allow passing locally defined subprograms without accessibility violations)
   type Plot_Callback is access procedure
     (X         : Pixel_Coordinate;
      Y         : Pixel_Coordinate;
      Coverage  : Intensity);

   -- Exception raised on illegal configurations
   Dimension_Error : exception;
   Invalid_Point   : exception;

   ----------------------------------------------------------------------------
   -- Helper Functions
   ----------------------------------------------------------------------------

   function Round_Coord (Val : Real) return Coordinate is
     (Coordinate (Real'Rounding (Val)));

   function Floor_Coord (Val : Real) return Coordinate is
     (Coordinate (Real'Floor (Val)));

   function Fractional_Part (Val : Real) return Real is
     (Val - Real'Floor (Val));

   function Reverse_Fractional_Part (Val : Real) return Real is
     (1.0 - Fractional_Part (Val));

   function Blend_Over
     (Foreground : RGBA_Color;
      Background : RGBA_Color;
      Coverage   : Intensity) return RGBA_Color
   with
     Global => null;

   function Color_To_Grayscale (C : RGBA_Color) return Byte is
     (Byte (Real (C.Red) * 0.299 + Real (C.Green) * 0.587 + Real (C.Blue) * 0.114));

   ----------------------------------------------------------------------------
   -- Variant 1: Buffer-based Line Drawing (Standard Grayscale Coverage)
   ----------------------------------------------------------------------------
   procedure Draw_Line
     (Buffer : in out Intensity_Grid;
      P0     : Point_2D;
      P1     : Point_2D)
   with
     Global => null;

   ----------------------------------------------------------------------------
   -- Variant 2: Callback-based Line Rasterization (Memory-free Streaming)
   ----------------------------------------------------------------------------
   procedure Draw_Line_Callback
     (P0       : Point_2D;
      P1       : Point_2D;
      Max_X    : Pixel_Coordinate;
      Max_Y    : Pixel_Coordinate;
      Callback : not null access procedure
                   (X        : Pixel_Coordinate;
                    Y        : Pixel_Coordinate;
                    Coverage : Intensity))
   with
     Global => null;

   ----------------------------------------------------------------------------
   -- Variant 3: RGBA Direct Alpha-Blending Line Rasterization
   ----------------------------------------------------------------------------
   procedure Draw_Line_RGBA
     (Buffer     : in out Color_Grid;
      P0         : Point_2D;
      P1         : Point_2D;
      Line_Color : RGBA_Color)
   with
     Global => null;

   ----------------------------------------------------------------------------
   -- Variant 4: Clipped Line Rasterization (Strict Viewport Bounds)
   ----------------------------------------------------------------------------
   procedure Draw_Line_Clipped
     (Buffer : in out Intensity_Grid;
      P0     : Point_2D;
      P1     : Point_2D;
      Min_X  : Pixel_Coordinate;
      Min_Y  : Pixel_Coordinate;
      Max_X  : Pixel_Coordinate;
      Max_Y  : Pixel_Coordinate)
   with
     Pre => Min_X <= Max_X and then Min_Y <= Max_Y,
     Global => null;

end Xiaolin_Wu;
