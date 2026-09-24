--  Line Drawing Algorithms (ISO/IEC 8652:2023)
--  Comprehensive implementations of classical raster line drawing algorithms:
--  Naive (Slope-Intercept), Digital Differential Analyzer (DDA),
--  Bresenham's Integer Algorithm, Midpoint Algorithm, and Xiaolin Wu's Antialiased Line Algorithm.

package Line_Drawing is

   --  Coordinate system domain types
   type Coordinate is range -100_000 .. 100_000;
   type Coordinate_Distance is range 0 .. 200_000;
   type Intensity is delta 0.001 range 0.0 .. 1.0;

   type Point is record
      X : Coordinate := 0;
      Y : Coordinate := 0;
   end record;

   type Shaded_Point is record
      Coord : Point;
      Alpha : Intensity := 1.0;
   end record;

   type Point_Array is array (Positive range <>) of Point;
   type Shaded_Point_Array is array (Positive range <>) of Shaded_Point;

   --  Exception raised when capacity bounds are violated or parameters are invalid
   Invalid_Line_Error : exception;

   --  Helper calculation functions
   function Manhattan_Distance (P1, P2 : Point) return Coordinate_Distance with
     Global => null;

   function Chebyshev_Distance (P1, P2 : Point) return Coordinate_Distance with
     Global => null;

   function Expected_Point_Count (P1, P2 : Point) return Positive with
     Global => null;

   --  Variant 1: Naive Line Algorithm (Floating-Point Slope-Intercept)
   --  Uses y = m * x + b directly. Handles steep and reverse slopes by stepping
   --  along the dominant axis.
   function Naive_Line (Start_Pt, End_Pt : Point) return Point_Array with
     Global => null,
     Post   => Naive_Line'Result'Length = Expected_Point_Count (Start_Pt, End_Pt)
               and then Naive_Line'Result (Naive_Line'Result'First) = Start_Pt
               and then Naive_Line'Result (Naive_Line'Result'Last) = End_Pt;

   --  Variant 2: Digital Differential Analyzer (DDA)
   --  Increments coordinates using floating-point additions per step along dominant axis.
   function DDA_Line (Start_Pt, End_Pt : Point) return Point_Array with
     Global => null,
     Post   => DDA_Line'Result'Length = Expected_Point_Count (Start_Pt, End_Pt)
               and then DDA_Line'Result (DDA_Line'Result'First) = Start_Pt
               and then DDA_Line'Result (DDA_Line'Result'Last) = End_Pt;

   --  Variant 3: Bresenham's Line Algorithm
   --  Fast integer-only algorithm that tracks error accumulation across all 8 octants.
   function Bresenham_Line (Start_Pt, End_Pt : Point) return Point_Array with
     Global => null,
     Post   => Bresenham_Line'Result'Length = Expected_Point_Count (Start_Pt, End_Pt)
               and then Bresenham_Line'Result (Bresenham_Line'Result'First) = Start_Pt
               and then Bresenham_Line'Result (Bresenham_Line'Result'Last) = End_Pt;

   --  Variant 4: Midpoint Line Algorithm
   --  Decision-variable formulation based on implicit line equation F(x, y) = 0.
   function Midpoint_Line (Start_Pt, End_Pt : Point) return Point_Array with
     Global => null,
     Post   => Midpoint_Line'Result'Length = Expected_Point_Count (Start_Pt, End_Pt)
               and then Midpoint_Line'Result (Midpoint_Line'Result'First) = Start_Pt
               and then Midpoint_Line'Result (Midpoint_Line'Result'Last) = End_Pt;

   --  Variant 5: Xiaolin Wu's Antialiased Line Algorithm
   --  Sub-pixel anti-aliasing distributing intensity across adjacent pixel pairs.
   function Xiaolin_Wu_Line (Start_Pt, End_Pt : Point) return Shaded_Point_Array with
     Global => null,
     Post   => Xiaolin_Wu_Line'Result'Length >= 1;

end Line_Drawing;
