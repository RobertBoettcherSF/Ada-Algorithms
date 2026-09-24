-- floyd_steinberg.ads
package Floyd_Steinberg is

   -- Use custom float type for high-precision error diffusion
   type Color_Value is new Float;
   
   -- 2D Array representing the image (grayscale, normalized 0.0 to 1.0)
   type Image is array (Integer range <>, Integer range <>) of Color_Value;

   -- Exception raised when processing images with invalid dimensions
   Invalid_Image_Error : exception;

   -- Standard Left-to-Right Floyd-Steinberg Dithering
   -- Processes every row from left to right, pushing quantization error forward
   procedure Dither_Standard (Img : in out Image);

   -- Serpentine Floyd-Steinberg Dithering
   -- Alternates left-to-right and right-to-left scanning per row to reduce visual artifacts
   procedure Dither_Serpentine (Img : in out Image);

private

   -- Helper function to find the nearest palette color (black: 0.0, white: 1.0)
   function Quantize (Value : Color_Value) return Color_Value;

end Floyd_Steinberg;
