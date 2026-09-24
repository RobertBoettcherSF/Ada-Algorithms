package Riemersma_Dithering is

   -- Strong typing for algorithm-specific data
   type Grayscale_Value is range 0 .. 255;
   type Gray_Image is array (Positive range <>, Positive range <>) of Grayscale_Value;

   -- Variants supported by this implementation
   type Curve_Type is (Hilbert, Serpentine, Raster);
   type Decay_Model is (Exponential, Linear);

   -- Exception raised when algorithm receives out-of-bounds parameters
   Invalid_Parameter_Error : exception;

   -- Dithers a grayscale image into a purely black-and-white (0 and 255) image
   -- applying the Riemersma localized error diffusion process.
   procedure Apply_Dither
     (Target       : in out Gray_Image;
      Curve        : in Curve_Type := Hilbert;
      Decay        : in Decay_Model := Exponential;
      History_Size : in Integer := 16);

   -- Helper function exposed for mathematical V&V testing: 
   -- Generates discrete coordinates for a space-filling Hilbert curve.
   -- N must be a power of 2. D is the linear distance (0 .. N*N - 1).
   procedure D2XY (N : Positive; D : Natural; X, Y : out Positive);

end Riemersma_Dithering;
