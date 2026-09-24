-- error_diffusion.adb
package body Error_Diffusion is

   -- =========================================================================
   -- Helper Functions
   -- =========================================================================
   function Clamp (Value : Float) return Color_Value is
   begin
      if Value > 255.0 then
         return 255.0;
      elsif Value < 0.0 then
         return 0.0;
      else
         return Color_Value (Value);
      end if;
   end Clamp;

   -- =========================================================================
   -- Kernel Definitions (All variants from Wikipedia)
   -- =========================================================================
   function Floyd_Steinberg_Kernel return Diffusion_Kernel is
   begin
      return ((1, 0, 7.0/16.0), (-1, 1, 3.0/16.0), (0, 1, 5.0/16.0), (1, 1, 1.0/16.0));
   end Floyd_Steinberg_Kernel;

   function Jarvis_Judice_Ninke_Kernel return Diffusion_Kernel is
   begin
      return ((1, 0, 7.0/48.0), (2, 0, 5.0/48.0),
              (-2, 1, 3.0/48.0), (-1, 1, 5.0/48.0), (0, 1, 7.0/48.0), (1, 1, 5.0/48.0), (2, 1, 3.0/48.0),
              (-2, 2, 1.0/48.0), (-1, 2, 3.0/48.0), (0, 2, 5.0/48.0), (1, 2, 3.0/48.0), (2, 2, 1.0/48.0));
   end Jarvis_Judice_Ninke_Kernel;

   function Stucki_Kernel return Diffusion_Kernel is
   begin
      return ((1, 0, 8.0/42.0), (2, 0, 4.0/42.0),
              (-2, 1, 2.0/42.0), (-1, 1, 4.0/42.0), (0, 1, 8.0/42.0), (1, 1, 4.0/42.0), (2, 1, 2.0/42.0),
              (-2, 2, 1.0/42.0), (-1, 2, 2.0/42.0), (0, 2, 4.0/42.0), (1, 2, 2.0/42.0), (2, 2, 1.0/42.0));
   end Stucki_Kernel;

   function Atkinson_Kernel return Diffusion_Kernel is
   begin
      -- Note: Atkinson intentionally only diffuses 3/4 of the error.
      return ((1, 0, 1.0/8.0), (2, 0, 1.0/8.0),
              (-1, 1, 1.0/8.0), (0, 1, 1.0/8.0), (1, 1, 1.0/8.0),
              (0, 2, 1.0/8.0));
   end Atkinson_Kernel;

   function Burkes_Kernel return Diffusion_Kernel is
   begin
      return ((1, 0, 8.0/32.0), (2, 0, 4.0/32.0),
              (-2, 1, 2.0/32.0), (-1, 1, 4.0/32.0), (0, 1, 8.0/32.0), (1, 1, 4.0/32.0), (2, 1, 2.0/32.0));
   end Burkes_Kernel;

   function Sierra3_Kernel return Diffusion_Kernel is
   begin
      return ((1, 0, 5.0/32.0), (2, 0, 3.0/32.0),
              (-2, 1, 2.0/32.0), (-1, 1, 4.0/32.0), (0, 1, 5.0/32.0), (1, 1, 4.0/32.0), (2, 1, 2.0/32.0),
              (-1, 2, 2.0/32.0), (0, 2, 3.0/32.0), (1, 2, 2.0/32.0));
   end Sierra3_Kernel;

   function Sierra2_Row_Kernel return Diffusion_Kernel is
   begin
      return ((1, 0, 4.0/16.0), (2, 0, 3.0/16.0),
              (-2, 1, 1.0/16.0), (-1, 1, 2.0/16.0), (0, 1, 3.0/16.0), (1, 1, 2.0/16.0), (2, 1, 1.0/16.0));
   end Sierra2_Row_Kernel;

   function Sierra_Lite_Kernel return Diffusion_Kernel is
   begin
      return ((1, 0, 2.0/4.0),
              (-1, 1, 1.0/4.0), (0, 1, 1.0/4.0));
   end Sierra_Lite_Kernel;

   -- =========================================================================
   -- Core Algorithm Execution
   -- =========================================================================
   procedure Apply_Diffusion
     (Image  : in out Image_Grid;
      Kernel : in Diffusion_Kernel)
   is
      Old_Pixel   : Color_Value;
      New_Pixel   : Color_Value;
      Quant_Error : Float;
      Target_X    : Integer;
      Target_Y    : Integer;
   begin
      -- Edge Case: Empty grid
      if Image'Length(1) = 0 or else Image'Length(2) = 0 then
         raise Invalid_Image_Error;
      end if;

      for Y in Image'Range(2) loop
         for X in Image'Range(1) loop
            Old_Pixel := Image (X, Y);
            
            -- Quantize pixel to strictly binary palette (black=0 or white=255)
            if Old_Pixel > Quantization_Threshold then
               New_Pixel := 255.0;
            else
               New_Pixel := 0.0;
            end if;
            
            Image (X, Y) := New_Pixel;
            
            -- Calculate quantization error to diffuse
            Quant_Error := Float (Old_Pixel) - Float (New_Pixel);

            -- Distribute the error to neighboring unvisited pixels based on Kernel
            for K of Kernel loop
               Target_X := X + K.Dx;
               Target_Y := Y + K.Dy;
               
               -- Ensure the target pixel is within image boundaries
               if Target_X in Image'Range(1) and Target_Y in Image'Range(2) then
                  declare
                     Diffused_Value : Float := Float (Image (Target_X, Target_Y)) + (Quant_Error * K.Weight);
                  begin
                     Image (Target_X, Target_Y) := Clamp (Diffused_Value);
                  end;
               end if;
            end loop;
         end loop;
      end loop;
   end Apply_Diffusion;

end Error_Diffusion;
