package body Ordered_Dithering is

   -------------------------------------------------------------------
   -- Helper: Is_Power_Of_Two
   -- Validates if the requested matrix dimension is valid
   -------------------------------------------------------------------
   function Is_Power_Of_Two (N : Positive) return Boolean is
      Val : Positive := N;
   begin
      while Val > 1 loop
         if Val mod 2 /= 0 then
            return False;
         end if;
         Val := Val / 2;
      end loop;
      return True;
   end Is_Power_Of_Two;

   -------------------------------------------------------------------
   -- Helper: Quantize
   -- Converts a normalized float [0.0, 1.0] to a quantized 8-bit color
   -------------------------------------------------------------------
   function Quantize (Value : Float; Levels : Positive) return Color_8Bit is
      Steps   : constant Float := Float (Levels - 1);
      Scaled  : constant Float := Value * Steps;
      Rounded : constant Integer := Integer (Float'Rounding (Scaled));
      Result  : Float;
   begin
      if Rounded <= 0 then
         return 0;
      elsif Rounded >= Integer (Levels - 1) then
         return 255;
      end if;
      Result := (Float (Rounded) / Steps) * 255.0;
      return Color_8Bit (Float'Rounding (Result));
   end Quantize;

   -------------------------------------------------------------------
   -- Variant: Pre-calculated Threshold Map (Bayer Matrix)
   -------------------------------------------------------------------
   function Generate_Bayer_Matrix (Dim : Positive) return Bayer_Matrix is
      Result : Bayer_Matrix (0 .. Dim - 1, 0 .. Dim - 1);

      -- Recursive generator for standard integer Bayer map
      function Bayer_Value (X, Y : Natural; D : Positive) return Natural is
         Half : Natural;
         Base : Natural;
      begin
         if D = 1 then
            return 0;
         end if;

         Half := D / 2;
         Base := 4 * Bayer_Value (X mod Half, Y mod Half, Half);

         if X < Half and Y < Half then
            return Base;
         elsif X >= Half and Y < Half then
            return Base + 2;
         elsif X < Half and Y >= Half then
            return Base + 3;
         else
            return Base + 1;
         end if;
      end Bayer_Value;

   begin
      if not Is_Power_Of_Two (Dim) then
         raise Invalid_Matrix_Dimension;
      end if;

      for Y in 0 .. Dim - 1 loop
         for X in 0 .. Dim - 1 loop
            -- Wikipedia normalization formula equivalent: M(i,j)/n^2 - 0.5
            -- Maps values evenly across the range [-0.5, 0.5)
            Result (X, Y) := (Float (Bayer_Value (X, Y, Dim)) / Float (Dim * Dim)) - 0.5;
         end loop;
      end loop;

      return Result;
   end Generate_Bayer_Matrix;

   -------------------------------------------------------------------
   -- Variant: Monochrome Ordered Dithering
   -------------------------------------------------------------------
   procedure Apply_Monochrome (
      Image      : in out Grayscale_Image;
      Matrix_Dim : in Positive;
      Levels     : in Positive := 2
   ) is
      Matrix  : Bayer_Matrix (0 .. Matrix_Dim - 1, 0 .. Matrix_Dim - 1);
      Val     : Float;
      Map_Val : Float;
   begin
      -- Edge cases and validation
      if Image'Length (1) = 0 or else Image'Length (2) = 0 then
         raise Empty_Image_Error;
      end if;
      if Levels < 2 then
         raise Invalid_Levels_Error;
      end if;

      Matrix := Generate_Bayer_Matrix (Matrix_Dim);

      for Y in Image'Range (2) loop
         for X in Image'Range (1) loop
            Val := Float (Image (X, Y)) / 255.0;
            -- Modulo ensures tiling of the matrix across image dimensions
            Map_Val := Matrix (Natural (X - Image'First(1)) mod Matrix_Dim,
                               Natural (Y - Image'First(2)) mod Matrix_Dim);

            -- Core Wikipedia algorithm adjustment
            Val := Val + (Map_Val / Float (Levels - 1));

            -- Clamp boundaries
            if Val < 0.0 then Val := 0.0; end if;
            if Val > 1.0 then Val := 1.0; end if;

            Image (X, Y) := Quantize (Val, Levels);
         end loop;
      end loop;
   end Apply_Monochrome;

   -------------------------------------------------------------------
   -- Variant: Color Ordered Dithering
   -------------------------------------------------------------------
   procedure Apply_Color (
      Image      : in out Color_Image;
      Matrix_Dim : in Positive;
      Levels_R   : in Positive := 2;
      Levels_G   : in Positive := 2;
      Levels_B   : in Positive := 2
   ) is
      Matrix  : Bayer_Matrix (0 .. Matrix_Dim - 1, 0 .. Matrix_Dim - 1);
      Map_Val : Float;
      Val_R, Val_G, Val_B : Float;
   begin
      if Image'Length (1) = 0 or else Image'Length (2) = 0 then
         raise Empty_Image_Error;
      end if;
      if Levels_R < 2 or else Levels_G < 2 or else Levels_B < 2 then
         raise Invalid_Levels_Error;
      end if;

      Matrix := Generate_Bayer_Matrix (Matrix_Dim);

      for Y in Image'Range (2) loop
         for X in Image'Range (1) loop
            Map_Val := Matrix (Natural (X - Image'First(1)) mod Matrix_Dim,
                               Natural (Y - Image'First(2)) mod Matrix_Dim);

            -- Process Red Channel
            Val_R := Float (Image (X, Y).R) / 255.0 + (Map_Val / Float (Levels_R - 1));
            if Val_R < 0.0 then Val_R := 0.0; end if;
            if Val_R > 1.0 then Val_R := 1.0; end if;
            Image (X, Y).R := Quantize (Val_R, Levels_R);

            -- Process Green Channel
            Val_G := Float (Image (X, Y).G) / 255.0 + (Map_Val / Float (Levels_G - 1));
            if Val_G < 0.0 then Val_G := 0.0; end if;
            if Val_G > 1.0 then Val_G := 1.0; end if;
            Image (X, Y).G := Quantize (Val_G, Levels_G);

            -- Process Blue Channel
            Val_B := Float (Image (X, Y).B) / 255.0 + (Map_Val / Float (Levels_B - 1));
            if Val_B < 0.0 then Val_B := 0.0; end if;
            if Val_B > 1.0 then Val_B := 1.0; end if;
            Image (X, Y).B := Quantize (Val_B, Levels_B);
         end loop;
      end loop;
   end Apply_Color;

end Ordered_Dithering;
