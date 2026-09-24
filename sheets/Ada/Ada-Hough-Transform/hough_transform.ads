-- hough_transform.ads
-- Specification for the Hough Transform algorithm and its variants.
with Ada.Numerics.Elementary_Functions;

package Hough_Transform is

   -- =========================================================================
   -- Strong Typing Definitions
   -- =========================================================================
   
   type Pixel_Coord is new Integer;
   
   -- Represents a binary edge-detected image (True = edge, False = background)
   type Binary_Image is array (Pixel_Coord range <>, Pixel_Coord range <>) of Boolean;

   -- =========================================================================
   -- Variant 1: Standard Hough Transform (Lines)
   -- =========================================================================
   
   -- Theta represents the angle in degrees [-90, 89] covering 180 degrees
   type Theta_Angle is new Integer range -90 .. 89;
   
   -- Rho represents the distance from the origin to the line
   type Rho_Distance is new Integer;
   
   -- Accumulator for Line HT: Rows = Rho, Cols = Theta
   type Line_Accumulator is array (Rho_Distance range <>, Theta_Angle range <>) of Natural;

   -- Computes the Standard Hough Transform to detect lines.
   -- Dynamically sizes the returning Accumulator based on max possible Rho.
   function Transform_Lines (Image : Binary_Image) return Line_Accumulator;

   -- =========================================================================
   -- Variant 2: Circle Hough Transform
   -- =========================================================================
   
   type Radius_Value is new Natural;
   type Radius_Array is array (Positive range <>) of Radius_Value;
   
   -- Accumulator for Circle HT: X_Center, Y_Center, and Radius index
   type Circle_Accumulator is array (Pixel_Coord range <>, Pixel_Coord range <>, Positive range <>) of Natural;

   -- Computes the Circle Hough Transform for a specified set of target radii.
   function Transform_Circles (Image : Binary_Image; Radii : Radius_Array) return Circle_Accumulator;

   -- =========================================================================
   -- Variant 3: Generalized Hough Transform (Arbitrary Shapes)
   -- =========================================================================
   -- Note: Generalized HT requires an external user-defined template (R-Table) 
   -- mapping gradient directions to displacement vectors. 
   
   type Gradient_Dir is new Integer range 0 .. 359;
   
   type Vector_Offset is record
      DX, DY : Integer;
   end record;
   
   -- Simplified representation of a single R-Table entry list
   type Displacement_List is array (Positive range <>) of Vector_Offset;
   
   -- Placeholder: Since arbitrary shapes require external input templates, 
   -- the exact R-Table structure is passed by the user. 
   -- To implement, you would iterate over edges, find their gradient, 
   -- lookup displacements in the R-Table, and cast votes in a 2D accumulator.
   type General_Accumulator is array (Pixel_Coord range <>, Pixel_Coord range <>) of Natural;
   
   -- Throws Not_Implemented exception as it requires a specific template integration
   Not_Implemented : exception;
   function Transform_Generalized (Image : Binary_Image) return General_Accumulator;

end Hough_Transform;
