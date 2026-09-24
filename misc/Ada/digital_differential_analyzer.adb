--------------------------------------------------------------------------------
-- Package Body Digital_Differential_Analyzer
--------------------------------------------------------------------------------

package body Digital_Differential_Analyzer is

   -----------------------------------------------------------------------------
   -- Helper: Max_Delta
   -- Computes the maximum absolute difference between X and Y coordinates.
   -----------------------------------------------------------------------------
   function Max_Delta (P1, P2 : Point) return Step_Count is
      Dx : constant Long_Long_Integer := abs (Long_Long_Integer (P2.X) - Long_Long_Integer (P1.X));
      Dy : constant Long_Long_Integer := abs (Long_Long_Integer (P2.Y) - Long_Long_Integer (P1.Y));
      Max_Val : constant Long_Long_Integer := (if Dx > Dy then Dx else Dy);
   begin
      if Max_Val > Long_Long_Integer (Step_Count'Last) then
         raise Invalid_Coordinate_Range;
      end if;
      return Step_Count (Max_Val);
   end Max_Delta;

   -----------------------------------------------------------------------------
   -- Variant 1: Standard Floating-Point DDA Algorithm
   -----------------------------------------------------------------------------
   function Compute_Line_Float_DDA
     (Start_Pt : Point;
      End_Pt   : Point) return Pixel_Buffer is

      Steps : constant Step_Count := Max_Delta (Start_Pt, End_Pt);
      Buffer : Pixel_Buffer (Capacity => Positive (Steps + 1));

      Dx : constant Long_Float := Long_Float (End_Pt.X) - Long_Float (Start_Pt.X);
      Dy : constant Long_Float := Long_Float (End_Pt.Y) - Long_Float (Start_Pt.Y);

      X_Inc : constant Long_Float := (if Steps = 0 then 0.0 else Dx / Long_Float (Steps));
      Y_Inc : constant Long_Float := (if Steps = 0 then 0.0 else Dy / Long_Float (Steps));

      Curr_X : Long_Float := Long_Float (Start_Pt.X);
      Curr_Y : Long_Float := Long_Float (Start_Pt.Y);
   begin
      for I in 0 .. Steps loop
         if Buffer.Length >= Buffer.Capacity then
            raise Buffer_Overflow;
         end if;
         Buffer.Length := Buffer.Length + 1;
         -- Round to nearest integer for pixel grid alignment
         Buffer.Data (Buffer.Length) := (
            X => Coordinate (Long_Float'Rounding (Curr_X)),
            Y => Coordinate (Long_Float'Rounding (Curr_Y))
         );
         Curr_X := Curr_X + X_Inc;
         Curr_Y := Curr_Y + Y_Inc;
      end loop;

      return Buffer;
   end Compute_Line_Float_DDA;

   -----------------------------------------------------------------------------
   -- Variant 2: Integer-Only / Fixed-Point DDA Algorithm
   -----------------------------------------------------------------------------
   function Compute_Line_Integer_DDA
     (Start_Pt : Point;
      End_Pt   : Point) return Pixel_Buffer is

      Steps : constant Step_Count := Max_Delta (Start_Pt, End_Pt);
      Buffer : Pixel_Buffer (Capacity => Positive (Steps + 1));

      Dx : constant Integer := Integer (End_Pt.X) - Integer (Start_Pt.X);
      Dy : constant Integer := Integer (End_Pt.Y) - Integer (Start_Pt.Y);

      -- Scale up by 65536 (2^16) for fixed-point accumulation to maintain precision
      Scale : constant := 65536;
      X_Inc : constant Long_Long_Integer :=
        (if Steps = 0 then 0 else (Long_Long_Integer (Dx) * Scale) / Long_Long_Integer (Steps));
      Y_Inc : constant Long_Long_Integer :=
        (if Steps = 0 then 0 else (Long_Long_Integer (Dy) * Scale) / Long_Long_Integer (Steps));

      Curr_X_Scaled : Long_Long_Integer := Long_Long_Integer (Start_Pt.X) * Scale;
      Curr_Y_Scaled : Long_Long_Integer := Long_Long_Integer (Start_Pt.Y) * Scale;
   begin
      for I in 0 .. Steps loop
         if Buffer.Length >= Buffer.Capacity then
            raise Buffer_Overflow;
         end if;
         Buffer.Length := Buffer.Length + 1;

         -- De-scale with rounding towards nearest
         Buffer.Data (Buffer.Length) := (
            X => Coordinate ((Curr_X_Scaled + (Scale / 2)) / Scale),
            Y => Coordinate ((Curr_Y_Scaled + (Scale / 2)) / Scale)
         );

         Curr_X_Scaled := Curr_X_Scaled + X_Inc;
         Curr_Y_Scaled := Curr_Y_Scaled + Y_Inc;
      end loop;

      return Buffer;
   end Compute_Line_Integer_DDA;

end Digital_Differential_Analyzer;
