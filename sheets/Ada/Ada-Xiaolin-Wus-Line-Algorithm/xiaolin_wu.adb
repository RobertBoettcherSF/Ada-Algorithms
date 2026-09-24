-------------------------------------------------------------------------------
--  Package Body: Xiaolin_Wu
--
--  Implementation of Xiaolin Wu's antialiased line algorithm.
-------------------------------------------------------------------------------

package body Xiaolin_Wu is

   ----------------------------------------------------------------------------
   -- Internal Plot Helper for Intensity Buffer
   ----------------------------------------------------------------------------
   procedure Plot_Buffer
     (Buffer : in out Intensity_Grid;
      X      : Coordinate;
      Y      : Coordinate;
      Weight : Real)
   is
   begin
      if Weight <= 0.0 then
         return;
      end if;

      if X >= Coordinate (Buffer'First (1)) and then X <= Coordinate (Buffer'Last (1))
        and then Y >= Coordinate (Buffer'First (2)) and then Y <= Coordinate (Buffer'Last (2))
      then
         declare
            PX : constant Pixel_Coordinate := Pixel_Coordinate (X);
            PY : constant Pixel_Coordinate := Pixel_Coordinate (Y);
            Cur : constant Real := Buffer (PX, PY);
            -- Standard additive coverage blending clamped to 1.0
            New_Weight : constant Real := (if Cur + Weight > 1.0 then 1.0 else Cur + Weight);
         begin
            Buffer (PX, PY) := Intensity (New_Weight);
         end;
      end if;
   end Plot_Buffer;

   ----------------------------------------------------------------------------
   -- Internal Plot Helper for RGBA Buffer
   ----------------------------------------------------------------------------
   procedure Plot_RGBA_Buffer
     (Buffer : in out Color_Grid;
      X      : Coordinate;
      Y      : Coordinate;
      Color  : RGBA_Color;
      Weight : Real)
   is
   begin
      if Weight <= 0.0 then
         return;
      end if;

      if X >= Coordinate (Buffer'First (1)) and then X <= Coordinate (Buffer'Last (1))
        and then Y >= Coordinate (Buffer'First (2)) and then Y <= Coordinate (Buffer'Last (2))
      then
         declare
            PX : constant Pixel_Coordinate := Pixel_Coordinate (X);
            PY : constant Pixel_Coordinate := Pixel_Coordinate (Y);
            Effective_Cov : constant Intensity :=
              Intensity (Real'Min (1.0, Real'Max (0.0, Weight)));
         begin
            Buffer (PX, PY) := Blend_Over (Color, Buffer (PX, PY), Effective_Cov);
         end;
      end if;
   end Plot_RGBA_Buffer;

   ----------------------------------------------------------------------------
   -- Blend_Over: Standard Alpha Compositing with Spatial Coverage Weight
   ----------------------------------------------------------------------------
   function Blend_Over
     (Foreground : RGBA_Color;
      Background : RGBA_Color;
      Coverage   : Intensity) return RGBA_Color
   is
      Cov   : constant Real := Real (Coverage);
      Fg_A  : constant Real := (Real (Foreground.Alpha) / 255.0) * Cov;
      Bg_A  : constant Real := Real (Background.Alpha) / 255.0;
      Out_A : constant Real := Fg_A + Bg_A * (1.0 - Fg_A);

      Res_R : Byte;
      Res_G : Byte;
      Res_B : Byte;
      Res_A : Byte;
   begin
      if Out_A <= 0.000_001 then
         return (Red => 0, Green => 0, Blue => 0, Alpha => 0);
      end if;

      declare
         R_Term : constant Real :=
           (Real (Foreground.Red) * Fg_A + Real (Background.Red) * Bg_A * (1.0 - Fg_A)) / Out_A;
         G_Term : constant Real :=
           (Real (Foreground.Green) * Fg_A + Real (Background.Green) * Bg_A * (1.0 - Fg_A)) / Out_A;
         B_Term : constant Real :=
           (Real (Foreground.Blue) * Fg_A + Real (Background.Blue) * Bg_A * (1.0 - Fg_A)) / Out_A;
      begin
         Res_R := Byte (Real'Min (255.0, Real'Max (0.0, Real'Rounding (R_Term))));
         Res_G := Byte (Real'Min (255.0, Real'Max (0.0, Real'Rounding (G_Term))));
         Res_B := Byte (Real'Min (255.0, Real'Max (0.0, Real'Rounding (B_Term))));
         Res_A := Byte (Real'Min (255.0, Real'Max (0.0, Real'Rounding (Out_A * 255.0))));
      end;

      return (Red => Res_R, Green => Res_G, Blue => Res_B, Alpha => Res_A);
   end Blend_Over;

   ----------------------------------------------------------------------------
   -- Variant 1: Draw_Line
   ----------------------------------------------------------------------------
   procedure Draw_Line
     (Buffer : in out Intensity_Grid;
      P0     : Point_2D;
      P1     : Point_2D)
   is
      X0 : Real := P0.X;
      Y0 : Real := P0.Y;
      X1 : Real := P1.X;
      Y1 : Real := P1.Y;

      Steep : constant Boolean := abs (Y1 - Y0) > abs (X1 - X0);
      Tmp   : Real;
   begin
      -- Handle degenerate point-line
      if X0 = X1 and then Y0 = Y1 then
         Plot_Buffer (Buffer, Round_Coord (X0), Round_Coord (Y0), 1.0);
         return;
      end if;

      if Steep then
         Tmp := X0; X0 := Y0; Y0 := Tmp;
         Tmp := X1; X1 := Y1; Y1 := Tmp;
      end if;

      if X0 > X1 then
         Tmp := X0; X0 := X1; X1 := Tmp;
         Tmp := Y0; Y0 := Y1; Y1 := Tmp;
      end if;

      declare
         Dx : constant Real := X1 - X0;
         Dy : constant Real := Y1 - Y0;
         Gradient : constant Real := (if Dx = 0.0 then 1.0 else Dy / Dx);

         -- First endpoint
         X_End_1 : constant Real := Real'Rounding (X0);
         Y_End_1 : constant Real := Y0 + Gradient * (X_End_1 - X0);
         X_Gap_1 : constant Real := Reverse_Fractional_Part (X0 + 0.5);
         PX_1    : constant Coordinate := Coordinate (Real'Floor (X_End_1));
         PY_1    : constant Coordinate := Floor_Coord (Y_End_1);

         Inter_Y : Real;
         X_End_2 : Real;
         Y_End_2 : Real;
         X_Gap_2 : Real;
         PX_2    : Coordinate;
         PY_2    : Coordinate;
      begin
         if Steep then
            Plot_Buffer (Buffer, PY_1,     PX_1, Reverse_Fractional_Part (Y_End_1) * X_Gap_1);
            Plot_Buffer (Buffer, PY_1 + 1, PX_1, Fractional_Part (Y_End_1) * X_Gap_1);
         else
            Plot_Buffer (Buffer, PX_1, PY_1,     Reverse_Fractional_Part (Y_End_1) * X_Gap_1);
            Plot_Buffer (Buffer, PX_1, PY_1 + 1, Fractional_Part (Y_End_1) * X_Gap_1);
         end if;

         Inter_Y := Y_End_1 + Gradient;

         -- Second endpoint
         X_End_2 := Real'Rounding (X1);
         Y_End_2 := Y1 + Gradient * (X_End_2 - X1);
         X_Gap_2 := Reverse_Fractional_Part (X1 + 0.5);
         PX_2    := Coordinate (Real'Floor (X_End_2));
         PY_2    := Floor_Coord (Y_End_2);

         if Steep then
            Plot_Buffer (Buffer, PY_2,     PX_2, Reverse_Fractional_Part (Y_End_2) * X_Gap_2);
            Plot_Buffer (Buffer, PY_2 + 1, PX_2, Fractional_Part (Y_End_2) * X_Gap_2);
         else
            Plot_Buffer (Buffer, PX_2, PY_2,     Reverse_Fractional_Part (Y_End_2) * X_Gap_2);
            Plot_Buffer (Buffer, PX_2, PY_2 + 1, Fractional_Part (Y_End_2) * X_Gap_2);
         end if;

         -- Main rasterization loop
         if PX_1 + 1 <= PX_2 - 1 then
            for X in PX_1 + 1 .. PX_2 - 1 loop
               if Steep then
                  Plot_Buffer
                    (Buffer,
                     Floor_Coord (Inter_Y),
                     X,
                     Reverse_Fractional_Part (Inter_Y));
                  Plot_Buffer
                    (Buffer,
                     Floor_Coord (Inter_Y) + 1,
                     X,
                     Fractional_Part (Inter_Y));
               else
                  Plot_Buffer
                    (Buffer,
                     X,
                     Floor_Coord (Inter_Y),
                     Reverse_Fractional_Part (Inter_Y));
                  Plot_Buffer
                    (Buffer,
                     X,
                     Floor_Coord (Inter_Y) + 1,
                     Fractional_Part (Inter_Y));
               end if;
               Inter_Y := Inter_Y + Gradient;
            end loop;
         end if;
      end;
   end Draw_Line;

   ----------------------------------------------------------------------------
   -- Variant 2: Draw_Line_Callback
   ----------------------------------------------------------------------------
   procedure Draw_Line_Callback
     (P0       : Point_2D;
      P1       : Point_2D;
      Max_X    : Pixel_Coordinate;
      Max_Y    : Pixel_Coordinate;
      Callback : not null access procedure
                   (X        : Pixel_Coordinate;
                    Y        : Pixel_Coordinate;
                    Coverage : Intensity))
   is
      procedure Emit_Pixel (X : Coordinate; Y : Coordinate; W : Real) is
      begin
         if W > 0.0 and then X >= 0 and then X <= Coordinate (Max_X)
           and then Y >= 0 and then Y <= Coordinate (Max_Y)
         then
            Callback
              (Pixel_Coordinate (X),
               Pixel_Coordinate (Y),
               Intensity (Real'Min (1.0, W)));
         end if;
      end Emit_Pixel;

      X0 : Real := P0.X;
      Y0 : Real := P0.Y;
      X1 : Real := P1.X;
      Y1 : Real := P1.Y;
      Steep : constant Boolean := abs (Y1 - Y0) > abs (X1 - X0);
      Tmp   : Real;
   begin
      if X0 = X1 and then Y0 = Y1 then
         Emit_Pixel (Round_Coord (X0), Round_Coord (Y0), 1.0);
         return;
      end if;

      if Steep then
         Tmp := X0; X0 := Y0; Y0 := Tmp;
         Tmp := X1; X1 := Y1; Y1 := Tmp;
      end if;

      if X0 > X1 then
         Tmp := X0; X0 := X1; X1 := Tmp;
         Tmp := Y0; Y0 := Y1; Y1 := Tmp;
      end if;

      declare
         Dx : constant Real := X1 - X0;
         Dy : constant Real := Y1 - Y0;
         Gradient : constant Real := (if Dx = 0.0 then 1.0 else Dy / Dx);

         X_End_1 : constant Real := Real'Rounding (X0);
         Y_End_1 : constant Real := Y0 + Gradient * (X_End_1 - X0);
         X_Gap_1 : constant Real := Reverse_Fractional_Part (X0 + 0.5);
         PX_1    : constant Coordinate := Coordinate (Real'Floor (X_End_1));
         PY_1    : constant Coordinate := Floor_Coord (Y_End_1);

         Inter_Y : Real;
         X_End_2 : Real;
         Y_End_2 : Real;
         X_Gap_2 : Real;
         PX_2    : Coordinate;
         PY_2    : Coordinate;
      begin
         if Steep then
            Emit_Pixel (PY_1,     PX_1, Reverse_Fractional_Part (Y_End_1) * X_Gap_1);
            Emit_Pixel (PY_1 + 1, PX_1, Fractional_Part (Y_End_1) * X_Gap_1);
         else
            Emit_Pixel (PX_1, PY_1,     Reverse_Fractional_Part (Y_End_1) * X_Gap_1);
            Emit_Pixel (PX_1, PY_1 + 1, Fractional_Part (Y_End_1) * X_Gap_1);
         end if;

         Inter_Y := Y_End_1 + Gradient;

         X_End_2 := Real'Rounding (X1);
         Y_End_2 := Y1 + Gradient * (X_End_2 - X1);
         X_Gap_2 := Reverse_Fractional_Part (X1 + 0.5);
         PX_2    := Coordinate (Real'Floor (X_End_2));
         PY_2    := Floor_Coord (Y_End_2);

         if Steep then
            Emit_Pixel (PY_2,     PX_2, Reverse_Fractional_Part (Y_End_2) * X_Gap_2);
            Emit_Pixel (PY_2 + 1, PX_2, Fractional_Part (Y_End_2) * X_Gap_2);
         else
            Emit_Pixel (PX_2, PY_2,     Reverse_Fractional_Part (Y_End_2) * X_Gap_2);
            Emit_Pixel (PX_2, PY_2 + 1, Fractional_Part (Y_End_2) * X_Gap_2);
         end if;

         if PX_1 + 1 <= PX_2 - 1 then
            for X in PX_1 + 1 .. PX_2 - 1 loop
               if Steep then
                  Emit_Pixel
                    (Floor_Coord (Inter_Y),
                     X,
                     Reverse_Fractional_Part (Inter_Y));
                  Emit_Pixel
                    (Floor_Coord (Inter_Y) + 1,
                     X,
                     Fractional_Part (Inter_Y));
               else
                  Emit_Pixel
                    (X,
                     Floor_Coord (Inter_Y),
                     Reverse_Fractional_Part (Inter_Y));
                  Emit_Pixel
                    (X,
                     Floor_Coord (Inter_Y) + 1,
                     Fractional_Part (Inter_Y));
               end if;
               Inter_Y := Inter_Y + Gradient;
            end loop;
         end if;
      end;
   end Draw_Line_Callback;

   ----------------------------------------------------------------------------
   -- Variant 3: Draw_Line_RGBA
   ----------------------------------------------------------------------------
   procedure Draw_Line_RGBA
     (Buffer     : in out Color_Grid;
      P0         : Point_2D;
      P1         : Point_2D;
      Line_Color : RGBA_Color)
   is
      X0 : Real := P0.X;
      Y0 : Real := P0.Y;
      X1 : Real := P1.X;
      Y1 : Real := P1.Y;
      Steep : constant Boolean := abs (Y1 - Y0) > abs (X1 - X0);
      Tmp   : Real;
   begin
      if X0 = X1 and then Y0 = Y1 then
         Plot_RGBA_Buffer (Buffer, Round_Coord (X0), Round_Coord (Y0), Line_Color, 1.0);
         return;
      end if;

      if Steep then
         Tmp := X0; X0 := Y0; Y0 := Tmp;
         Tmp := X1; X1 := Y1; Y1 := Tmp;
      end if;

      if X0 > X1 then
         Tmp := X0; X0 := X1; X1 := Tmp;
         Tmp := Y0; Y0 := Y1; Y1 := Tmp;
      end if;

      declare
         Dx : constant Real := X1 - X0;
         Dy : constant Real := Y1 - Y0;
         Gradient : constant Real := (if Dx = 0.0 then 1.0 else Dy / Dx);

         X_End_1 : constant Real := Real'Rounding (X0);
         Y_End_1 : constant Real := Y0 + Gradient * (X_End_1 - X0);
         X_Gap_1 : constant Real := Reverse_Fractional_Part (X0 + 0.5);
         PX_1    : constant Coordinate := Coordinate (Real'Floor (X_End_1));
         PY_1    : constant Coordinate := Floor_Coord (Y_End_1);

         Inter_Y : Real;
         X_End_2 : Real;
         Y_End_2 : Real;
         X_Gap_2 : Real;
         PX_2    : Coordinate;
         PY_2    : Coordinate;
      begin
         if Steep then
            Plot_RGBA_Buffer (Buffer, PY_1,     PX_1, Line_Color, Reverse_Fractional_Part (Y_End_1) * X_Gap_1);
            Plot_RGBA_Buffer (Buffer, PY_1 + 1, PX_1, Line_Color, Fractional_Part (Y_End_1) * X_Gap_1);
         else
            Plot_RGBA_Buffer (Buffer, PX_1, PY_1,     Line_Color, Reverse_Fractional_Part (Y_End_1) * X_Gap_1);
            Plot_RGBA_Buffer (Buffer, PX_1, PY_1 + 1, Line_Color, Fractional_Part (Y_End_1) * X_Gap_1);
         end if;

         Inter_Y := Y_End_1 + Gradient;

         X_End_2 := Real'Rounding (X1);
         Y_End_2 := Y1 + Gradient * (X_End_2 - X1);
         X_Gap_2 := Reverse_Fractional_Part (X1 + 0.5);
         PX_2    := Coordinate (Real'Floor (X_End_2));
         PY_2    := Floor_Coord (Y_End_2);

         if Steep then
            Plot_RGBA_Buffer (Buffer, PY_2,     PX_2, Line_Color, Reverse_Fractional_Part (Y_End_2) * X_Gap_2);
            Plot_RGBA_Buffer (Buffer, PY_2 + 1, PX_2, Line_Color, Fractional_Part (Y_End_2) * X_Gap_2);
         else
            Plot_RGBA_Buffer (Buffer, PX_2, PY_2,     Line_Color, Reverse_Fractional_Part (Y_End_2) * X_Gap_2);
            Plot_RGBA_Buffer (Buffer, PX_2, PY_2 + 1, Line_Color, Fractional_Part (Y_End_2) * X_Gap_2);
         end if;

         if PX_1 + 1 <= PX_2 - 1 then
            for X in PX_1 + 1 .. PX_2 - 1 loop
               if Steep then
                  Plot_RGBA_Buffer
                    (Buffer,
                     Floor_Coord (Inter_Y),
                     X,
                     Line_Color,
                     Reverse_Fractional_Part (Inter_Y));
                  Plot_RGBA_Buffer
                    (Buffer,
                     Floor_Coord (Inter_Y) + 1,
                     X,
                     Line_Color,
                     Fractional_Part (Inter_Y));
               else
                  Plot_RGBA_Buffer
                    (Buffer,
                     X,
                     Floor_Coord (Inter_Y),
                     Line_Color,
                     Reverse_Fractional_Part (Inter_Y));
                  Plot_RGBA_Buffer
                    (Buffer,
                     X,
                     Floor_Coord (Inter_Y) + 1,
                     Line_Color,
                     Fractional_Part (Inter_Y));
               end if;
               Inter_Y := Inter_Y + Gradient;
            end loop;
         end if;
      end;
   end Draw_Line_RGBA;

   ----------------------------------------------------------------------------
   -- Variant 4: Draw_Line_Clipped
   ----------------------------------------------------------------------------
   procedure Draw_Line_Clipped
     (Buffer : in out Intensity_Grid;
      P0     : Point_2D;
      P1     : Point_2D;
      Min_X  : Pixel_Coordinate;
      Min_Y  : Pixel_Coordinate;
      Max_X  : Pixel_Coordinate;
      Max_Y  : Pixel_Coordinate)
   is
      procedure Plot_Clipped (X : Coordinate; Y : Coordinate; W : Real) is
      begin
         if W <= 0.0 then
            return;
         end if;

         if X >= Coordinate (Min_X) and then X <= Coordinate (Max_X)
           and then Y >= Coordinate (Min_Y) and then Y <= Coordinate (Max_Y)
           and then X >= Coordinate (Buffer'First (1)) and then X <= Coordinate (Buffer'Last (1))
           and then Y >= Coordinate (Buffer'First (2)) and then Y <= Coordinate (Buffer'Last (2))
         then
            declare
               PX : constant Pixel_Coordinate := Pixel_Coordinate (X);
               PY : constant Pixel_Coordinate := Pixel_Coordinate (Y);
               Cur : constant Real := Buffer (PX, PY);
               New_Weight : constant Real := (if Cur + W > 1.0 then 1.0 else Cur + W);
            begin
               Buffer (PX, PY) := Intensity (New_Weight);
            end;
         end if;
      end Plot_Clipped;

      X0 : Real := P0.X;
      Y0 : Real := P0.Y;
      X1 : Real := P1.X;
      Y1 : Real := P1.Y;
      Steep : constant Boolean := abs (Y1 - Y0) > abs (X1 - X0);
      Tmp   : Real;
   begin
      if X0 = X1 and then Y0 = Y1 then
         Plot_Clipped (Round_Coord (X0), Round_Coord (Y0), 1.0);
         return;
      end if;

      if Steep then
         Tmp := X0; X0 := Y0; Y0 := Tmp;
         Tmp := X1; X1 := Y1; Y1 := Tmp;
      end if;

      if X0 > X1 then
         Tmp := X0; X0 := X1; X1 := Tmp;
         Tmp := Y0; Y0 := Y1; Y1 := Tmp;
      end if;

      declare
         Dx : constant Real := X1 - X0;
         Dy : constant Real := Y1 - Y0;
         Gradient : constant Real := (if Dx = 0.0 then 1.0 else Dy / Dx);

         X_End_1 : constant Real := Real'Rounding (X0);
         Y_End_1 : constant Real := Y0 + Gradient * (X_End_1 - X0);
         X_Gap_1 : constant Real := Reverse_Fractional_Part (X0 + 0.5);
         PX_1    : constant Coordinate := Coordinate (Real'Floor (X_End_1));
         PY_1    : constant Coordinate := Floor_Coord (Y_End_1);

         Inter_Y : Real;
         X_End_2 : Real;
         Y_End_2 : Real;
         X_Gap_2 : Real;
         PX_2    : Coordinate;
         PY_2    : Coordinate;
      begin
         if Steep then
            Plot_Clipped (PY_1,     PX_1, Reverse_Fractional_Part (Y_End_1) * X_Gap_1);
            Plot_Clipped (PY_1 + 1, PX_1, Fractional_Part (Y_End_1) * X_Gap_1);
         else
            Plot_Clipped (PX_1, PY_1,     Reverse_Fractional_Part (Y_End_1) * X_Gap_1);
            Plot_Clipped (PX_1, PY_1 + 1, Fractional_Part (Y_End_1) * X_Gap_1);
         end if;

         Inter_Y := Y_End_1 + Gradient;

         X_End_2 := Real'Rounding (X1);
         Y_End_2 := Y1 + Gradient * (X_End_2 - X1);
         X_Gap_2 := Reverse_Fractional_Part (X1 + 0.5);
         PX_2    := Coordinate (Real'Floor (X_End_2));
         PY_2    := Floor_Coord (Y_End_2);

         if Steep then
            Plot_Clipped (PY_2,     PX_2, Reverse_Fractional_Part (Y_End_2) * X_Gap_2);
            Plot_Clipped (PY_2 + 1, PX_2, Fractional_Part (Y_End_2) * X_Gap_2);
         else
            Plot_Clipped (PX_2, PY_2,     Reverse_Fractional_Part (Y_End_2) * X_Gap_2);
            Plot_Clipped (PX_2, PY_2 + 1, Fractional_Part (Y_End_2) * X_Gap_2);
         end if;

         if PX_1 + 1 <= PX_2 - 1 then
            for X in PX_1 + 1 .. PX_2 - 1 loop
               if Steep then
                  Plot_Clipped
                    (Floor_Coord (Inter_Y),
                     X,
                     Reverse_Fractional_Part (Inter_Y));
                  Plot_Clipped
                    (Floor_Coord (Inter_Y) + 1,
                     X,
                     Fractional_Part (Inter_Y));
               else
                  Plot_Clipped
                    (X,
                     Floor_Coord (Inter_Y),
                     Reverse_Fractional_Part (Inter_Y));
                  Plot_Clipped
                    (X,
                     Floor_Coord (Inter_Y) + 1,
                     Fractional_Part (Inter_Y));
               end if;
               Inter_Y := Inter_Y + Gradient;
            end loop;
         end if;
      end;
   end Draw_Line_Clipped;

end Xiaolin_Wu;
