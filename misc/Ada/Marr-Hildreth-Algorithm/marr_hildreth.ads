-- marr_hildreth.ads
-- Specification for the Marr-Hildreth Edge Detection Algorithm and its variants.

with Ada.Containers.Indefinite_Vectors;

package Marr_Hildreth is

   -- Custom strongly typed definitions for image processing
   type Intensity is delta 0.001 range -10000.0 .. 10000.0;
   type Binary_Pixel is (Background, Edge);

   type Image_Grid is array (Positive range <>, Positive range <>) of Intensity;
   type Edge_Grid  is array (Positive range <>, Positive range <>) of Binary_Pixel;

   -- Configuration parameters for algorithm variants
   type Kernel_Size is range 3 .. 101;
   
   type Parameters is record
      Sigma           : Float := 1.0;          -- Gaussian standard deviation
      Sigma_Ratio     : Float := 1.6;          -- Ratio for Difference of Gaussians (DoG)
      Kernel_Dim      : Kernel_Size := 5;      -- Size of filter kernel (must be odd)
      Threshold       : Intensity := 0.01;     -- Zero-crossing gradient threshold
   end record;

   -- Exceptions for error handling
   Invalid_Kernel_Size  : exception;
   Invalid_Image_Bounds : exception;
   Invalid_Parameters   : exception;

   -- Helper procedures and functions
   function Validate_Parameters (Params : Parameters) return Boolean;
   
   function Create_LoG_Kernel (Params : Parameters) return Image_Grid;
   function Create_DoG_Kernel (Params : Parameters) return Image_Grid;

   -- Core Variant 1: Laplacian of Gaussian (LoG) Edge Detection
   procedure Detect_Edges_LoG
     (Input_Image  : in  Image_Grid;
      Output_Edges : out Edge_Grid;
      Params       : in  Parameters);

   -- Core Variant 2: Difference of Gaussians (DoG) Fast Approximation
   procedure Detect_Edges_DoG
     (Input_Image  : in  Image_Grid;
      Output_Edges : out Edge_Grid;
      Params       : in  Parameters);

   -- Zero-crossing detection helper
   procedure Detect_Zero_Crossings
     (Filtered_Image : in  Image_Grid;
      Output_Edges   : out Edge_Grid;
      Threshold      : in  Intensity);

end Marr_Hildreth;
