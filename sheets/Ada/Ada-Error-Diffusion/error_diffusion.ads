-- error_diffusion.ads
package Error_Diffusion is

   -- Strong typing for algorithm-specific data
   type Color_Value is new Float range 0.0 .. 255.0;
   type Image_Grid is array (Integer range <>, Integer range <>) of Color_Value;

   type Kernel_Element is record
      Dx     : Integer; -- X offset from current pixel
      Dy     : Integer; -- Y offset from current pixel
      Weight : Float;   -- Error distribution fraction
   end record;

   type Diffusion_Kernel is array (Positive range <>) of Kernel_Element;

   -- Predefined Kernels representing ALL variants from the Wikipedia article
   function Floyd_Steinberg_Kernel return Diffusion_Kernel;
   function Jarvis_Judice_Ninke_Kernel return Diffusion_Kernel;
   function Stucki_Kernel return Diffusion_Kernel;
   function Atkinson_Kernel return Diffusion_Kernel;
   function Burkes_Kernel return Diffusion_Kernel;
   function Sierra3_Kernel return Diffusion_Kernel;
   function Sierra2_Row_Kernel return Diffusion_Kernel;
   function Sierra_Lite_Kernel return Diffusion_Kernel;

   -- Constants
   Quantization_Threshold : constant Color_Value := 127.5;

   -- Main Procedure for Error Diffusion (Handles both 1D and 2D arrays dynamically)
   procedure Apply_Diffusion
     (Image  : in out Image_Grid;
      Kernel : in Diffusion_Kernel);

   -- Exceptions
   Invalid_Image_Error : exception;

end Error_Diffusion;
