--------------------------------------------------------------------------------
-- Package Digital_Differential_Analyzer (Ada 2023)
-- Implements the Digital Differential Analyzer (DDA) line drawing algorithm
-- as described in: https://en.wikipedia.org/wiki/Digital_differential_analyzer_(graphics_algorithm)
--------------------------------------------------------------------------------

package Digital_Differential_Analyzer is

   -- Domain types for coordinates and pixel points
   type Coordinate is range -10_000 .. 10_000;
   type Step_Count is range 0 .. 20_000;

   type Point is record
      X : Coordinate;
      Y : Coordinate;
   end record;

   -- Bounded array for rasterized pixels with sensible default capacity
   Max_Points : constant := 20_001;
   type Point_Array is array (Positive range <>) of Point;

   type Pixel_Buffer (Capacity : Positive) is record
      Length : Natural := 0;
      Data   : Point_Array (1 .. Capacity);
   end record;

   -- Exceptions for error handling
   Invalid_Coordinate_Range : exception;
   Buffer_Overflow          : exception;

   -----------------------------------------------------------------------------
   -- Variant 1: Standard Floating-Point DDA Algorithm
   -- Computes line rasterization using floating-point arithmetic for slope and steps.
   -----------------------------------------------------------------------------
   function Compute_Line_Float_DDA
     (Start_Pt : Point;
      End_Pt   : Point) return Pixel_Buffer
   with
      Pre  => (abs (Long_Float (End_Pt.X) - Long_Float (Start_Pt.X)) <= 10_000.0) and
              (abs (Long_Float (End_Pt.Y) - Long_Float (Start_Pt.Y)) <= 10_000.0),
      Post => Compute_Line_Float_DDA'Result.Length > 0;

   -----------------------------------------------------------------------------
   -- Variant 2: Integer-Only / Fixed-Point DDA Algorithm (Bresenham-like / Integer DDA)
   -- Avoids floating-point overhead by using integer scaling factors.
   -----------------------------------------------------------------------------
   function Compute_Line_Integer_DDA
     (Start_Pt : Point;
      End_Pt   : Point) return Pixel_Buffer
   with
      Pre  => True,
      Post => Compute_Line_Integer_DDA'Result.Length > 0;

   -----------------------------------------------------------------------------
   -- Helper Subprograms exposed for testing and verification
   -----------------------------------------------------------------------------
   function Max_Delta (P1, P2 : Point) return Step_Count;

end Digital_Differential_Analyzer;
