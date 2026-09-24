-- halftoning.adb
-- Implementation of the Halftoning algorithms

package body Halftoning is

   ----------------------------------------------------------
   -- Variant 1: Simple Thresholding
   ----------------------------------------------------------
   procedure Simple_Threshold (Image     : in out Image_Grid; 
                               Threshold : in Pixel_Value := 128) is
   begin
      for I in Image'Range(1) loop
         for J in Image'Range(2) loop
            if Image(I, J) >= Threshold then
               Image(I, J) := 255; -- Map to White
            else
               Image(I, J) := 0;   -- Map to Black
            end if;
         end loop;
      end loop;
   end Simple_Threshold;

   ----------------------------------------------------------
   -- Variant 2: Ordered Dithering
   ----------------------------------------------------------
   procedure Ordered_Dither (Image : in out Image_Grid) is
      type Matrix_4x4 is array (0..3, 0..3) of Integer;
      
      -- Standard 4x4 Bayer Matrix scaled to 0-255 ranges
      Bayer : constant Matrix_4x4 :=
        ((  0, 128,  32, 160),
         (192,  64, 224,  96),
         ( 48, 176,  16, 144),
         (240, 112, 208,  80));
         
      Row_Mod, Col_Mod : Integer;
      Threshold_Value  : Pixel_Value;
   begin
      for I in Image'Range(1) loop
         for J in Image'Range(2) loop
            -- Normalize array index to 0-3 for matrix lookup, 
            -- safeguarding against non-standard array bounds.
            Row_Mod := (I - Image'First(1)) mod 4;
            Col_Mod := (J - Image'First(2)) mod 4;
            
            Threshold_Value := Pixel_Value(Bayer(Row_Mod, Col_Mod));
            
            if Image(I, J) > Threshold_Value then
               Image(I, J) := 255;
            else
               Image(I, J) := 0;
            end if;
         end loop;
      end loop;
   end Ordered_Dither;

   ----------------------------------------------------------
   -- Variant 3: Error Diffusion (Floyd-Steinberg)
   ----------------------------------------------------------
   procedure Floyd_Steinberg_Dither (Image : in out Image_Grid) is
      -- We must use a temporary Integer grid to handle negative values
      -- and over-255 values caused by error accumulation before clamping.
      type Work_Grid is array (Image'Range(1), Image'Range(2)) of Integer;
      Work : Work_Grid;
      
      Old_Pixel, New_Pixel : Integer;
      Quant_Error          : Integer;
   begin
      -- Edge case: Empty input handled inherently by range loops.
      
      -- 1. Initialize working grid with image pixel values
      for I in Image'Range(1) loop
         for J in Image'Range(2) loop
            Work(I, J) := Integer(Image(I, J));
         end loop;
      end loop;

      -- 2. Process image top-to-bottom, left-to-right
      for I in Work'Range(1) loop
         for J in Work'Range(2) loop
            Old_Pixel := Work(I, J);
            
            -- Quantize to binary (0 or 255)
            if Old_Pixel >= 128 then
               New_Pixel := 255;
            else
               New_Pixel := 0;
            end if;
            
            Work(I, J) := New_Pixel;
            Quant_Error := Old_Pixel - New_Pixel;
            
            -- Propagate error to neighboring pixels if within bounds
            
            -- Right: 7/16
            if J + 1 <= Work'Last(2) then
               Work(I, J + 1) := Work(I, J + 1) + (Quant_Error * 7) / 16;
            end if;
            
            -- Bottom Left: 3/16
            if I + 1 <= Work'Last(1) and then J - 1 >= Work'First(2) then
               Work(I + 1, J - 1) := Work(I + 1, J - 1) + (Quant_Error * 3) / 16;
            end if;
            
            -- Bottom: 5/16
            if I + 1 <= Work'Last(1) then
               Work(I + 1, J) := Work(I + 1, J) + (Quant_Error * 5) / 16;
            end if;
            
            -- Bottom Right: 1/16
            if I + 1 <= Work'Last(1) and then J + 1 <= Work'Last(2) then
               Work(I + 1, J + 1) := Work(I + 1, J + 1) + (Quant_Error * 1) / 16;
            end if;
         end loop;
      end loop;

      -- 3. Write back clamped values to output Image
      for I in Image'Range(1) loop
         for J in Image'Range(2) loop
            if Work(I, J) < 0 then
               Image(I, J) := 0;
            elsif Work(I, J) > 255 then
               Image(I, J) := 255;
            else
               Image(I, J) := Pixel_Value(Work(I, J));
            end if;
         end loop;
      end loop;
   end Floyd_Steinberg_Dither;

end Halftoning;
