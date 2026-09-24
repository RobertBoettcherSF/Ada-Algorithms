-- floyd_steinberg.adb
package body Floyd_Steinberg is

   -----------------------------------------------------------------------------
   -- Helper: Quantize
   -- Converts a continuous Color_Value into a discrete palette value (0.0 or 1.0)
   -----------------------------------------------------------------------------
   function Quantize (Value : Color_Value) return Color_Value is
   begin
      if Value < 0.5 then
         return 0.0;
      else
         return 1.0;
      end if;
   end Quantize;

   -----------------------------------------------------------------------------
   -- Dither_Standard
   -- Distributes error: Right (7/16), Down-Left (3/16), Down (5/16), Down-Right (1/16)
   -----------------------------------------------------------------------------
   procedure Dither_Standard (Img : in out Image) is
      Old_Pixel   : Color_Value;
      New_Pixel   : Color_Value;
      Quant_Error : Color_Value;
   begin
      if Img'Length(1) = 0 or else Img'Length(2) = 0 then
         raise Invalid_Image_Error with "Standard Dither: Image bounds cannot be empty";
      end if;

      for Y in Img'Range(2) loop
         for X in Img'Range(1) loop
            Old_Pixel   := Img (X, Y);
            New_Pixel   := Quantize (Old_Pixel);
            Img (X, Y)  := New_Pixel;
            Quant_Error := Old_Pixel - New_Pixel;

            -- Pixel to the right
            if X + 1 <= Img'Last(1) then
               Img (X + 1, Y) := Img (X + 1, Y) + Quant_Error * (7.0 / 16.0);
            end if;
            
            -- Pixel to the bottom-left
            if X - 1 >= Img'First(1) and then Y + 1 <= Img'Last(2) then
               Img (X - 1, Y + 1) := Img (X - 1, Y + 1) + Quant_Error * (3.0 / 16.0);
            end if;
            
            -- Pixel to the bottom
            if Y + 1 <= Img'Last(2) then
               Img (X, Y + 1) := Img (X, Y + 1) + Quant_Error * (5.0 / 16.0);
            end if;
            
            -- Pixel to the bottom-right
            if X + 1 <= Img'Last(1) and then Y + 1 <= Img'Last(2) then
               Img (X + 1, Y + 1) := Img (X + 1, Y + 1) + Quant_Error * (1.0 / 16.0);
            end if;
         end loop;
      end loop;
   end Dither_Standard;

   -----------------------------------------------------------------------------
   -- Dither_Serpentine
   -- Alternates direction row by row. Odd rows mirror the error distribution.
   -----------------------------------------------------------------------------
   procedure Dither_Serpentine (Img : in out Image) is
      Old_Pixel     : Color_Value;
      New_Pixel     : Color_Value;
      Quant_Error   : Color_Value;
      Left_To_Right : Boolean := True;
   begin
      if Img'Length(1) = 0 or else Img'Length(2) = 0 then
         raise Invalid_Image_Error with "Serpentine Dither: Image bounds cannot be empty";
      end if;

      for Y in Img'Range(2) loop
         if Left_To_Right then
            -- Scan Left to Right
            for X in Img'Range(1) loop
               Old_Pixel   := Img (X, Y);
               New_Pixel   := Quantize (Old_Pixel);
               Img (X, Y)  := New_Pixel;
               Quant_Error := Old_Pixel - New_Pixel;

               if X + 1 <= Img'Last(1) then
                  Img (X + 1, Y) := Img (X + 1, Y) + Quant_Error * (7.0 / 16.0);
               end if;
               if X - 1 >= Img'First(1) and then Y + 1 <= Img'Last(2) then
                  Img (X - 1, Y + 1) := Img (X - 1, Y + 1) + Quant_Error * (3.0 / 16.0);
               end if;
               if Y + 1 <= Img'Last(2) then
                  Img (X, Y + 1) := Img (X, Y + 1) + Quant_Error * (5.0 / 16.0);
               end if;
               if X + 1 <= Img'Last(1) and then Y + 1 <= Img'Last(2) then
                  Img (X + 1, Y + 1) := Img (X + 1, Y + 1) + Quant_Error * (1.0 / 16.0);
               end if;
            end loop;
         else
            -- Scan Right to Left (mirrored distribution)
            for X in reverse Img'Range(1) loop
               Old_Pixel   := Img (X, Y);
               New_Pixel   := Quantize (Old_Pixel);
               Img (X, Y)  := New_Pixel;
               Quant_Error := Old_Pixel - New_Pixel;

               -- Right-to-Left: "Forward" is X - 1
               if X - 1 >= Img'First(1) then
                  Img (X - 1, Y) := Img (X - 1, Y) + Quant_Error * (7.0 / 16.0);
               end if;
               
               -- "Bottom-Right" mirrored is Bottom-Left (X + 1)
               if X + 1 <= Img'Last(1) and then Y + 1 <= Img'Last(2) then
                  Img (X + 1, Y + 1) := Img (X + 1, Y + 1) + Quant_Error * (3.0 / 16.0);
               end if;
               
               -- Bottom remains the same
               if Y + 1 <= Img'Last(2) then
                  Img (X, Y + 1) := Img (X, Y + 1) + Quant_Error * (5.0 / 16.0);
               end if;
               
               -- "Bottom-Left" mirrored is Bottom-Right (X - 1)
               if X - 1 >= Img'First(1) and then Y + 1 <= Img'Last(2) then
                  Img (X - 1, Y + 1) := Img (X - 1, Y + 1) + Quant_Error * (1.0 / 16.0);
               end if;
            end loop;
         end if;
         
         Left_To_Right := not Left_To_Right;
      end loop;
   end Dither_Serpentine;

end Floyd_Steinberg;
