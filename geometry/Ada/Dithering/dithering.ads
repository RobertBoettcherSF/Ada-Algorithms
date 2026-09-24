--  dithering.ads
--  Specification for the Dithering algorithms package.
--  Implements threshold, random, ordered, and error-diffusion variants.

package Dithering is

   --  Custom types for algorithm-specific data to enforce strong typing.
   --  We use Float to maintain precision during error diffusion.
   type Color_Value is new Float;

   --  2D Array representing a grayscale image.
   --  Values are nominally 0.0 (Black) to 1.0 (White).
   type Image is array (Natural range <>, Natural range <>) of Color_Value;

   --  ========================================================================
   --  Helper Functions
   --  ========================================================================

   --  Clamps a color value to the [0.0, 1.0] range.
   function Clamp (Val : Color_Value) return Color_Value;

   --  Rounds a color value to the nearest palette color (0.0 or 1.0).
   function Round_To_Palette
     (Val       : Color_Value;
      Threshold : Color_Value := 0.5) return Color_Value;

   --  ========================================================================
   --  Dithering Algorithm Variants
   --  ========================================================================

   --  1. Simple Thresholding (No actual dithering, basic quantization)
   procedure Threshold_Dither
     (Img       : in out Image;
      Threshold : Color_Value := 0.5);

   --  2. Random Dithering (Adds uniform random noise before thresholding)
   procedure Random_Dither (Img : in out Image);

   --  3. Ordered Dithering (Uses a 2x2 Bayer Matrix)
   procedure Ordered_Dither_2x2 (Img : in out Image);

   --  4. Floyd-Steinberg Error Diffusion Dithering (7, 3, 5, 1 / 16)
   procedure Floyd_Steinberg_Dither (Img : in out Image);

   --  5. Atkinson Error Diffusion Dithering (Reduced contrast washing)
   procedure Atkinson_Dither (Img : in out Image);

   --  6. Jarvis-Judice-Ninke Error Diffusion Dithering
   procedure Jarvis_Judice_Ninke_Dither (Img : in out Image);

   --  7. Stucki Error Diffusion Dithering (Faster, less artifacting than JJN)
   procedure Stucki_Dither (Img : in out Image);

end Dithering;
