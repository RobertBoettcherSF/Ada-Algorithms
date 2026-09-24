with Ada.Numerics.Elementary_Functions;

package body Computer_Vision is

   -- Helper: Clamps a calculated float value to the valid 8-bit Pixel_Value bounds.
   -- This safely handles negative values (from convolutions) and overflows.
   function Clamp (Value : Float) return Pixel_Value is
   begin
      if Value < 0.0 then
         return 0;
      elsif Value > 255.0 then
         return 255;
      else
         return Pixel_Value (Value);
      end if;
   end Clamp;

   -- Helper: Retrieves a pixel from the image if coordinates are in bounds.
   -- Implements zero-padding for borders during convolution.
   function Get_Pixel (Img : Image; R, C : Integer) return Pixel_Value is
   begin
      if R >= Img'First (1) and R <= Img'Last (1) and
         C >= Img'First (2) and C <= Img'Last (2)
      then
         return Img (R, C);
      else
         return 0; -- Zero-padding for out of bounds
      end if;
   end Get_Pixel;

   function To_Grayscale_Average (Input : RGB_Image) return Image is
      Result : Image (Input'Range (1), Input'Range (2));
      Avg    : Float;
   begin
      -- Dynamic check for edge cases despite preconditions to ensure strong safety
      if Input'Length (1) = 0 or Input'Length (2) = 0 then
         raise Dimension_Error;
      end if;

      for R in Input'Range (1) loop
         for C in Input'Range (2) loop
            -- Simple mean of the RGB channels
            Avg := Float (Input (R, C).R) + Float (Input (R, C).G) + Float (Input (R, C).B);
            Result (R, C) := Clamp (Avg / 3.0);
         end loop;
      end loop;
      return Result;
   end To_Grayscale_Average;

   function To_Grayscale_Luminosity (Input : RGB_Image) return Image is
      Result : Image (Input'Range (1), Input'Range (2));
      Lum    : Float;
   begin
      if Input'Length (1) = 0 or Input'Length (2) = 0 then
         raise Dimension_Error;
      end if;

      for R in Input'Range (1) loop
         for C in Input'Range (2) loop
            -- Human perception weighted luminance coefficients (Rec. 709)
            Lum := 0.2126 * Float (Input (R, C).R) +
                   0.7152 * Float (Input (R, C).G) +
                   0.0722 * Float (Input (R, C).B);
            Result (R, C) := Clamp (Lum);
         end loop;
      end loop;
      return Result;
   end To_Grayscale_Luminosity;

   function Convolve (Input : Image; K : Kernel) return Image is
      Result : Image (Input'Range (1), Input'Range (2));
      Sum    : Float;
   begin
      if Input'Length (1) = 0 or Input'Length (2) = 0 then
         raise Dimension_Error;
      end if;

      for R in Input'Range (1) loop
         for C in Input'Range (2) loop
            Sum := 0.0;
            -- Apply the 3x3 kernel around the current pixel
            for KR in Kernel_Coordinate loop
               for KC in Kernel_Coordinate loop
                  Sum := Sum + K (KR, KC) *
                         Float (Get_Pixel (Input, R + Integer (KR), C + Integer (KC)));
               end loop;
            end loop;
            Result (R, C) := Clamp (Sum);
         end loop;
      end loop;
      return Result;
   end Convolve;

   function Sobel_X (Input : Image) return Image is
   begin
      return Convolve (Input, Sobel_X_Kernel);
   end Sobel_X;

   function Sobel_Y (Input : Image) return Image is
   begin
      return Convolve (Input, Sobel_Y_Kernel);
   end Sobel_Y;

   function Sobel_Magnitude (Input : Image) return Image is
      Result : Image (Input'Range (1), Input'Range (2));
      Sum_X  : Float;
      Sum_Y  : Float;
      Mag    : Float;
   begin
      if Input'Length (1) = 0 or Input'Length (2) = 0 then
         raise Dimension_Error;
      end if;

      for R in Input'Range (1) loop
         for C in Input'Range (2) loop
            Sum_X := 0.0;
            Sum_Y := 0.0;
            
            -- Combine the application of X and Y kernels to avoid dual-pass overhead
            for KR in Kernel_Coordinate loop
               for KC in Kernel_Coordinate loop
                  declare
                     -- Retrieve pixel once for both gradient calculations
                     P : constant Float := Float (Get_Pixel (Input, R + Integer (KR), C + Integer (KC)));
                  begin
                     Sum_X := Sum_X + Sobel_X_Kernel (KR, KC) * P;
                     Sum_Y := Sum_Y + Sobel_Y_Kernel (KR, KC) * P;
                  end;
               end loop;
            end loop;
            
            -- Euclidean distance combining both directional gradients
            Mag := Ada.Numerics.Elementary_Functions.Sqrt (Sum_X * Sum_X + Sum_Y * Sum_Y);
            Result (R, C) := Clamp (Mag);
         end loop;
      end loop;
      return Result;
   end Sobel_Magnitude;

end Computer_Vision;
