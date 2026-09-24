package Ordered_Dithering is

   -- Strong typing for algorithm-specific data
   type Color_8Bit is mod 256;
   type Image_Index is new Positive;

   -- 2D Array for monochrome images
   type Grayscale_Image is array (Image_Index range <>, Image_Index range <>) of Color_8Bit;

   -- Record for RGB pixel data
   type RGB_Pixel is record
      R, G, B : Color_8Bit;
   end record;

   -- 2D Array for color images
   type Color_Image is array (Image_Index range <>, Image_Index range <>) of RGB_Pixel;

   -- Threshold matrix definition (using floats for pre-calculated normalized values)
   type Bayer_Matrix is array (Natural range <>, Natural range <>) of Float;

   -- Exceptions for edge cases and invalid inputs
   Invalid_Matrix_Dimension : exception;
   Empty_Image_Error        : exception;
   Invalid_Levels_Error     : exception;

   -- =========================================================================
   -- Variant 1: Pre-calculated Threshold Map Generation (Bayer Matrix)
   -- Can generate 2x2, 4x4, 8x8, etc. (Must be power of 2)
   -- =========================================================================
   function Generate_Bayer_Matrix (Dim : Positive) return Bayer_Matrix;

   -- =========================================================================
   -- Variant 2: Monochrome Image Dithering
   -- Applies the threshold map to a single-channel image.
   -- Levels dictate quantization (2 = 1-bit B&W, 4 = 2-bit grayscale, etc.)
   -- =========================================================================
   procedure Apply_Monochrome (
      Image      : in out Grayscale_Image;
      Matrix_Dim : in Positive;
      Levels     : in Positive := 2
   );

   -- =========================================================================
   -- Variant 3: Color Image Dithering
   -- Applies the algorithm independently to each RGB channel.
   -- =========================================================================
   procedure Apply_Color (
      Image      : in out Color_Image;
      Matrix_Dim : in Positive;
      Levels_R   : in Positive := 2;
      Levels_G   : in Positive := 2;
      Levels_B   : in Positive := 2
   );

   -- Helper functions
   function Is_Power_Of_Two (N : Positive) return Boolean;
   function Quantize (Value : Float; Levels : Positive) return Color_8Bit;

end Ordered_Dithering;
