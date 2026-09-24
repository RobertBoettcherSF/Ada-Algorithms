with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Riemersma_Dithering is

   -- Private helper to rotate/flip a quadrant appropriately for Hilbert curve
   procedure Rot (N : Natural; X, Y : in out Natural; RX, RY : Natural) is
      T : Natural;
   begin
      if RY = 0 then
         if RX = 1 then
            X := N - 1 - X;
            Y := N - 1 - Y;
         end if;
         -- Swap X and Y
         T := X;
         X := Y;
         Y := T;
      end if;
   end Rot;

   procedure D2XY (N : Positive; D : Natural; X, Y : out Positive) is
      T_D : Natural := D;
      T_X : Natural := 0;
      T_Y : Natural := 0;
      S   : Natural := 1;
      RX, RY : Natural;
   begin
      while S < N loop
         RX := (T_D / 2) mod 2;
         RY := (T_D + RX) mod 2;
         Rot (S, T_X, T_Y, RX, RY);
         T_X := T_X + S * RX;
         T_Y := T_Y + S * RY;
         T_D := T_D / 4;
         S   := S * 2;
      end loop;
      X := T_X + 1;
      Y := T_Y + 1;
   end D2XY;

   procedure Apply_Dither
     (Target       : in out Gray_Image;
      Curve        : in Curve_Type := Hilbert;
      Decay        : in Decay_Model := Exponential;
      History_Size : in Integer := 16)
   is
   begin
      -- Edge case: Empty bounds
      if Target'Length(1) = 0 or Target'Length(2) = 0 then
         return;
      end if;

      -- Edge case: Invalid history scale
      if History_Size < 1 then
         raise Invalid_Parameter_Error;
      end if;

      -- Inner declarative region encapsulates data dependent on dynamic History_Size constraint
      declare
         Width  : constant Natural := Target'Length(1);
         Height : constant Natural := Target'Length(2);

         type Float_Array is array (1 .. History_Size) of Float;
         Weights : Float_Array;
         Errors  : Float_Array := (others => 0.0);
         Sum_Weights : Float := 0.0;

         X, Y : Positive;
         Linear_Pos : Natural := 0;
         Grid_Size  : Positive := 1;

         Old_Pixel, New_Pixel : Float;
         Error_Total, Adj_Pixel : Float;

         -- State for simple iteration variants
         Current_X : Positive := Target'First(1);
         Current_Y : Positive := Target'First(2);
         Moving_Right : Boolean := True;

         -- Internal variant handling: Calculate Weights matrix
         procedure Compute_Weights is
            Alpha : constant Float := 2.0 / Float(History_Size);
         begin
            for I in 1 .. History_Size loop
               if Decay = Exponential then
                  Weights(I) := Exp (-Alpha * Float(I - 1));
               else 
                  Weights(I) := Float(History_Size - I + 1) / Float(History_Size);
               end if;
               Sum_Weights := Sum_Weights + Weights(I);
            end loop;
            -- Normalize so weights sum strictly to 1.0
            for I in 1 .. History_Size loop
               Weights(I) := Weights(I) / Sum_Weights;
            end loop;
         end Compute_Weights;

         -- Retrieves next image coordinate depending on requested Variant
         procedure Next_Coordinate (Found_X, Found_Y : out Positive; Valid : out Boolean) is
         begin
            Valid := False; Found_X := 1; Found_Y := 1;
            
            case Curve is
               when Hilbert =>
                  while Linear_Pos < Grid_Size * Grid_Size loop
                     D2XY (Grid_Size, Linear_Pos, Found_X, Found_Y);
                     Linear_Pos := Linear_Pos + 1;
                     -- Align Hilbert coordinates 1..N to grid boundaries of Target array
                     Found_X := Found_X - 1 + Target'First(1);
                     Found_Y := Found_Y - 1 + Target'First(2);
                     
                     if Found_X <= Target'Last(1) and then Found_Y <= Target'Last(2) then
                        Valid := True; exit;
                     end if;
                  end loop;

               when Serpentine =>
                  if Current_Y <= Target'Last(2) then
                     Found_X := Current_X; Found_Y := Current_Y; Valid := True;
                     if Moving_Right then
                        if Current_X < Target'Last(1) then Current_X := Current_X + 1;
                        else Current_Y := Current_Y + 1; Moving_Right := False; end if;
                     else
                        if Current_X > Target'First(1) then Current_X := Current_X - 1;
                        else Current_Y := Current_Y + 1; Moving_Right := True; end if;
                     end if;
                  end if;

               when Raster =>
                  if Current_Y <= Target'Last(2) then
                     Found_X := Current_X; Found_Y := Current_Y; Valid := True;
                     if Current_X < Target'Last(1) then Current_X := Current_X + 1;
                     else Current_X := Target'First(1); Current_Y := Current_Y + 1; end if;
                  end if;
            end case;
         end Next_Coordinate;
         
         Valid_Cord : Boolean;
      begin
         Compute_Weights;
         
         -- Calculate Grid_Size for Hilbert fractal bound check
         if Curve = Hilbert then
            while Grid_Size < Width or Grid_Size < Height loop
               Grid_Size := Grid_Size * 2;
            end loop;
         end if;

         -- Main Application Loop
         loop
            Next_Coordinate (X, Y, Valid_Cord);
            exit when not Valid_Cord;

            Old_Pixel := Float (Target (X, Y));
            
            Error_Total := 0.0;
            for I in 1 .. History_Size loop
               Error_Total := Error_Total + Errors(I) * Weights(I);
            end loop;

            Adj_Pixel := Old_Pixel + Error_Total;
            
            -- Thresholding
            if Adj_Pixel < 128.0 then
               New_Pixel := 0.0;
               Target (X, Y) := 0;
            else
               New_Pixel := 255.0;
               Target (X, Y) := 255;
            end if;

            -- Propagate Quantization Error backward into history
            for I in reverse 2 .. History_Size loop
               Errors(I) := Errors(I - 1);
            end loop;
            Errors(1) := Adj_Pixel - New_Pixel;
         end loop;
      end;
   end Apply_Dither;

end Riemersma_Dithering;
