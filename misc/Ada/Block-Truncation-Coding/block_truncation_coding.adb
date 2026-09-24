with Ada.Numerics.Elementary_Functions; use Ada.Numerics.Elementary_Functions;

package body Block_Truncation_Coding is

   -----------------------------------------------------------------------------
   -- Calculates the mean pixel value (x-bar) of a 4x4 block.
   -----------------------------------------------------------------------------
   function Calculate_Mean (Block : Block_4x4) return Float is
      Sum : Float := 0.0;
   begin
      for I in 1..4 loop
         for J in 1..4 loop
            Sum := Sum + Float (Block(I, J));
         end loop;
      end loop;
      return Sum / 16.0;
   end Calculate_Mean;

   -----------------------------------------------------------------------------
   -- Calculates the population standard deviation (sigma) of a 4x4 block.
   -----------------------------------------------------------------------------
   function Calculate_Std_Dev (Block : Block_4x4; Mean : Float) return Float is
      Sum_Sq_Diff : Float := 0.0;
      Diff        : Float;
   begin
      for I in 1..4 loop
         for J in 1..4 loop
            Diff := Float (Block(I, J)) - Mean;
            Sum_Sq_Diff := Sum_Sq_Diff + (Diff * Diff);
         end loop;
      end loop;
      return Sqrt (Sum_Sq_Diff / 16.0);
   end Calculate_Std_Dev;

   -----------------------------------------------------------------------------
   -- Clamps mathematical float operations safely back into the 0..255 range.
   -----------------------------------------------------------------------------
   function Clamp_Pixel (Value : Float) return Pixel_Value is
   begin
      if Value <= 0.0 then
         return 0;
      elsif Value >= 255.0 then
         return 255;
      else
         return Pixel_Value (Float'Rounding(Value));
      end if;
   end Clamp_Pixel;

   -----------------------------------------------------------------------------
   -- Block Encoding Logic
   -----------------------------------------------------------------------------
   procedure Encode_Block (
      Input   : in  Block_4x4;
      Output  : out BTC_Encoded_Block;
      Variant : in  BTC_Variant := Standard_BTC
   ) is
      Mean     : Float;
      Std_Dev  : Float;
      Q        : Integer := 0; -- Count of pixels >= Mean
      A_Float  : Float;
      B_Float  : Float;
   begin
      Mean := Calculate_Mean(Input);

      -- Pass 1: Generate bitmap mask and calculate Q (number of bits >= mean)
      for I in 1..4 loop
         for J in 1..4 loop
            if Float (Input(I, J)) >= Mean then
               Output.Bitmap(I, J) := True;
               Q := Q + 1;
            else
               Output.Bitmap(I, J) := False;
            end if;
         end loop;
      end loop;

      -- Edge Case Validation: Prevent division by zero if all pixels are uniform.
      if Q = 0 or else Q = 16 then
         Output.A := Clamp_Pixel (Mean);
         Output.B := Clamp_Pixel (Mean);
         return;
      end if;

      -- Pass 2: Calculate upper and lower quantization bounds based on variant
      case Variant is
         
         when Standard_BTC =>
            -- Mathematical derivation preserving Mean and Variance
            Std_Dev := Calculate_Std_Dev (Input, Mean);
            A_Float := Mean - Std_Dev * Sqrt (Float(Q) / Float(16 - Q));
            B_Float := Mean + Std_Dev * Sqrt (Float(16 - Q) / Float(Q));
            
            Output.A := Clamp_Pixel (A_Float);
            Output.B := Clamp_Pixel (B_Float);

         when AMBTC =>
            -- Absolute Moment BTC (Preserves Mean and First Absolute Central Moment)
            declare
               Sum_Upper : Float := 0.0;
               Sum_Lower : Float := 0.0;
            begin
               for I in 1..4 loop
                  for J in 1..4 loop
                     if Output.Bitmap(I, J) then
                        Sum_Upper := Sum_Upper + Float (Input(I, J));
                     else
                        Sum_Lower := Sum_Lower + Float (Input(I, J));
                     end if;
                  end loop;
               end loop;
               
               A_Float := Sum_Lower / Float(16 - Q);
               B_Float := Sum_Upper / Float(Q);
               
               Output.A := Clamp_Pixel (A_Float);
               Output.B := Clamp_Pixel (B_Float);
            end;
      end case;
   end Encode_Block;

   -----------------------------------------------------------------------------
   -- Block Decoding Logic
   -----------------------------------------------------------------------------
   procedure Decode_Block (
      Input  : in  BTC_Encoded_Block;
      Output : out Block_4x4
   ) is
   begin
      for I in 1..4 loop
         for J in 1..4 loop
            if Input.Bitmap(I, J) then
               Output(I, J) := Input.B;
            else
               Output(I, J) := Input.A;
            end if;
         end loop;
      end loop;
   end Decode_Block;

end Block_Truncation_Coding;
