-- halftoning.ads
-- Specification for Halftoning algorithms
-- Covers multiple variants: Simple Thresholding, Ordered Dithering, and Error Diffusion.

package Halftoning is
   
   -- Strong typing for image representation
   type Pixel_Value is mod 256; -- 8-bit Grayscale (0 = Black, 255 = White)
   type Image_Grid is array (Positive range <>, Positive range <>) of Pixel_Value;
   
   -- Variant 1: Simple Patterning / Thresholding
   -- Non-preemptive basic threshold calculation.
   -- Compares each pixel against a fixed threshold value.
   procedure Simple_Threshold (Image     : in out Image_Grid; 
                               Threshold : in Pixel_Value := 128);
                               
   -- Variant 2: Ordered Dithering (Bayer Matrix)
   -- Static, position-dependent dithering. 
   -- Uses a 4x4 Bayer matrix to pattern the output based on spatial indices.
   procedure Ordered_Dither (Image : in out Image_Grid);
   
   -- Variant 3: Error Diffusion (Floyd-Steinberg)
   -- Dynamic dithering that pushes quantization error to adjacent pixels.
   -- Propagates error to Right (7/16), Bottom-Left (3/16), Bottom (5/16), Bottom-Right (1/16).
   procedure Floyd_Steinberg_Dither (Image : in out Image_Grid);

end Halftoning;
