--  dithering.adb
--  Implementation of the Dithering algorithms.

with Ada.Numerics.Float_Random;

package body Dithering is

   use Ada.Numerics.Float_Random;

   Rand_Gen : Generator;

   -------------------------------------------------------------------------
   --  Helper Functions
   -------------------------------------------------------------------------

   function Clamp (Val : Color_Value) return Color_Value is
   begin
      if Val < 0.0 then
         return 0.0;
      elsif Val > 1.0 then
         return 1.0;
      else
         return Val;
      end if;
   end Clamp;

   function Round_To_Palette
     (Val       : Color_Value;
      Threshold : Color_Value := 0.5) return Color_Value
   is
   begin
      if Val < Threshold then
         return 0.0;
      else
         return 1.0;
      end if;
   end Round_To_Palette;

   -------------------------------------------------------------------------
   --  1. Threshold Dither
   -------------------------------------------------------------------------

   procedure Threshold_Dither
     (Img       : in out Image;
      Threshold : Color_Value := 0.5)
   is
   begin
      for Y in Img'Range (1) loop
         for X in Img'Range (2) loop
            Img (Y, X) := Round_To_Palette (Clamp (Img (Y, X)), Threshold);
         end loop;
      end loop;
   end Threshold_Dither;

   -------------------------------------------------------------------------
   --  2. Random Dither
   -------------------------------------------------------------------------

   procedure Random_Dither (Img : in out Image) is
      Noise : Color_Value;
   begin
      for Y in Img'Range (1) loop
         for X in Img'Range (2) loop
            --  Generate noise between -0.25 and +0.25
            Noise := Color_Value (Random (Rand_Gen)) * 0.5 - 0.25;
            Img (Y, X) := Round_To_Palette (Clamp (Img (Y, X) + Noise));
         end loop;
      end loop;
   end Random_Dither;

   -------------------------------------------------------------------------
   --  3. Ordered Dither (2x2 Bayer Matrix)
   -------------------------------------------------------------------------

   procedure Ordered_Dither_2x2 (Img : in out Image) is
      type Matrix_2x2 is array (0 .. 1, 0 .. 1) of Color_Value;
      --  Normalized 2x2 Bayer Matrix (0 to 3 divided by 4)
      Bayer : constant Matrix_2x2 :=
        ((0.0 / 4.0, 2.0 / 4.0),
         (3.0 / 4.0, 1.0 / 4.0));
      M_X, M_Y : Natural;
   begin
      for Y in Img'Range (1) loop
         for X in Img'Range (2) loop
            M_Y := (Y - Img'First (1)) mod 2;
            M_X := (X - Img'First (2)) mod 2;

            --  Add matrix value minus 0.5 as a bias threshold
            if Clamp (Img (Y, X)) + (Bayer (M_Y, M_X) - 0.5) >= 0.5 then
               Img (Y, X) := 1.0;
            else
               Img (Y, X) := 0.0;
            end if;
         end loop;
      end loop;
   end Ordered_Dither_2x2;

   -------------------------------------------------------------------------
   --  4. Floyd-Steinberg Dither
   -------------------------------------------------------------------------

   procedure Floyd_Steinberg_Dither (Img : in out Image) is
      Old_Pixel   : Color_Value;
      New_Pixel   : Color_Value;
      Quant_Error : Color_Value;
   begin
      for Y in Img'Range (1) loop
         for X in Img'Range (2) loop
            Old_Pixel := Img (Y, X);
            New_Pixel := Round_To_Palette (Clamp (Old_Pixel));
            Img (Y, X) := New_Pixel;
            Quant_Error := Old_Pixel - New_Pixel;

            if X + 1 <= Img'Last (2) then
               Img (Y, X + 1) := Img (Y, X + 1) +
                 Quant_Error * (7.0 / 16.0);
            end if;

            if Y + 1 <= Img'Last (1) then
               if X - 1 >= Img'First (2) then
                  Img (Y + 1, X - 1) := Img (Y + 1, X - 1) +
                    Quant_Error * (3.0 / 16.0);
               end if;
               Img (Y + 1, X) := Img (Y + 1, X) +
                 Quant_Error * (5.0 / 16.0);
               if X + 1 <= Img'Last (2) then
                  Img (Y + 1, X + 1) := Img (Y + 1, X + 1) +
                    Quant_Error * (1.0 / 16.0);
               end if;
            end if;
         end loop;
      end loop;
   end Floyd_Steinberg_Dither;

   -------------------------------------------------------------------------
   --  5. Atkinson Dither
   -------------------------------------------------------------------------

   procedure Atkinson_Dither (Img : in out Image) is
      Old_Pixel   : Color_Value;
      New_Pixel   : Color_Value;
      Quant_Error : Color_Value;
   begin
      for Y in Img'Range (1) loop
         for X in Img'Range (2) loop
            Old_Pixel := Img (Y, X);
            New_Pixel := Round_To_Palette (Clamp (Old_Pixel));
            Img (Y, X) := New_Pixel;
            --  Atkinson only propagates 3/4 of the error (1/8 to 6 neighbors)
            Quant_Error := (Old_Pixel - New_Pixel) / 8.0;

            if X + 1 <= Img'Last (2) then
               Img (Y, X + 1) := Img (Y, X + 1) + Quant_Error;
            end if;
            if X + 2 <= Img'Last (2) then
               Img (Y, X + 2) := Img (Y, X + 2) + Quant_Error;
            end if;

            if Y + 1 <= Img'Last (1) then
               if X - 1 >= Img'First (2) then
                  Img (Y + 1, X - 1) := Img (Y + 1, X - 1) + Quant_Error;
               end if;
               Img (Y + 1, X) := Img (Y + 1, X) + Quant_Error;
               if X + 1 <= Img'Last (2) then
                  Img (Y + 1, X + 1) := Img (Y + 1, X + 1) + Quant_Error;
               end if;
            end if;

            if Y + 2 <= Img'Last (1) then
               Img (Y + 2, X) := Img (Y + 2, X) + Quant_Error;
            end if;
         end loop;
      end loop;
   end Atkinson_Dither;

   -------------------------------------------------------------------------
   --  6. Jarvis-Judice-Ninke Dither
   -------------------------------------------------------------------------

   procedure Jarvis_Judice_Ninke_Dither (Img : in out Image) is
      Old_Pixel   : Color_Value;
      New_Pixel   : Color_Value;
      Quant_Error : Color_Value;
   begin
      for Y in Img'Range (1) loop
         for X in Img'Range (2) loop
            Old_Pixel := Img (Y, X);
            New_Pixel := Round_To_Palette (Clamp (Old_Pixel));
            Img (Y, X) := New_Pixel;
            Quant_Error := (Old_Pixel - New_Pixel) / 48.0;

            --  Row 0
            if X + 1 <= Img'Last (2) then
               Img (Y, X + 1) := Img (Y, X + 1) + Quant_Error * 7.0;
            end if;
            if X + 2 <= Img'Last (2) then
               Img (Y, X + 2) := Img (Y, X + 2) + Quant_Error * 5.0;
            end if;

            --  Row 1
            if Y + 1 <= Img'Last (1) then
               if X - 2 >= Img'First (2) then
                  Img (Y + 1, X - 2) := Img (Y + 1, X - 2) +
                    Quant_Error * 3.0;
               end if;
               if X - 1 >= Img'First (2) then
                  Img (Y + 1, X - 1) := Img (Y + 1, X - 1) +
                    Quant_Error * 5.0;
               end if;
               Img (Y + 1, X) := Img (Y + 1, X) + Quant_Error * 7.0;
               if X + 1 <= Img'Last (2) then
                  Img (Y + 1, X + 1) := Img (Y + 1, X + 1) +
                    Quant_Error * 5.0;
               end if;
               if X + 2 <= Img'Last (2) then
                  Img (Y + 1, X + 2) := Img (Y + 1, X + 2) +
                    Quant_Error * 3.0;
               end if;
            end if;

            --  Row 2
            if Y + 2 <= Img'Last (1) then
               if X - 2 >= Img'First (2) then
                  Img (Y + 2, X - 2) := Img (Y + 2, X - 2) +
                    Quant_Error * 1.0;
               end if;
               if X - 1 >= Img'First (2) then
                  Img (Y + 2, X - 1) := Img (Y + 2, X - 1) +
                    Quant_Error * 3.0;
               end if;
               Img (Y + 2, X) := Img (Y + 2, X) + Quant_Error * 5.0;
               if X + 1 <= Img'Last (2) then
                  Img (Y + 2, X + 1) := Img (Y + 2, X + 1) +
                    Quant_Error * 3.0;
               end if;
               if X + 2 <= Img'Last (2) then
                  Img (Y + 2, X + 2) := Img (Y + 2, X + 2) +
                    Quant_Error * 1.0;
               end if;
            end if;
         end loop;
      end loop;
   end Jarvis_Judice_Ninke_Dither;

   -------------------------------------------------------------------------
   --  7. Stucki Dither
   -------------------------------------------------------------------------

   procedure Stucki_Dither (Img : in out Image) is
      Old_Pixel   : Color_Value;
      New_Pixel   : Color_Value;
      Quant_Error : Color_Value;
   begin
      for Y in Img'Range (1) loop
         for X in Img'Range (2) loop
            Old_Pixel := Img (Y, X);
            New_Pixel := Round_To_Palette (Clamp (Old_Pixel));
            Img (Y, X) := New_Pixel;
            Quant_Error := (Old_Pixel - New_Pixel) / 42.0;

            if X + 1 <= Img'Last (2) then
               Img (Y, X + 1) := Img (Y, X + 1) + Quant_Error * 8.0;
            end if;
            if X + 2 <= Img'Last (2) then
               Img (Y, X + 2) := Img (Y, X + 2) + Quant_Error * 4.0;
            end if;

            if Y + 1 <= Img'Last (1) then
               if X - 2 >= Img'First (2) then
                  Img (Y + 1, X - 2) := Img (Y + 1, X - 2) +
                    Quant_Error * 2.0;
               end if;
               if X - 1 >= Img'First (2) then
                  Img (Y + 1, X - 1) := Img (Y + 1, X - 1) +
                    Quant_Error * 4.0;
               end if;
               Img (Y + 1, X) := Img (Y + 1, X) + Quant_Error * 8.0;
               if X + 1 <= Img'Last (2) then
                  Img (Y + 1, X + 1) := Img (Y + 1, X + 1) +
                    Quant_Error * 4.0;
               end if;
               if X + 2 <= Img'Last (2) then
                  Img (Y + 1, X + 2) := Img (Y + 1, X + 2) +
                    Quant_Error * 2.0;
               end if;
            end if;

            if Y + 2 <= Img'Last (1) then
               if X - 2 >= Img'First (2) then
                  Img (Y + 2, X - 2) := Img (Y + 2, X - 2) +
                    Quant_Error * 1.0;
               end if;
               if X - 1 >= Img'First (2) then
                  Img (Y + 2, X - 1) := Img (Y + 2, X - 1) +
                    Quant_Error * 2.0;
               end if;
               Img (Y + 2, X) := Img (Y + 2, X) + Quant_Error * 4.0;
               if X + 1 <= Img'Last (2) then
                  Img (Y + 2, X + 1) := Img (Y + 2, X + 1) +
                    Quant_Error * 2.0;
               end if;
               if X + 2 <= Img'Last (2) then
                  Img (Y + 2, X + 2) := Img (Y + 2, X + 2) +
                    Quant_Error * 1.0;
               end if;
            end if;
         end loop;
      end loop;
   end Stucki_Dither;

begin
   Reset (Rand_Gen);
end Dithering;
