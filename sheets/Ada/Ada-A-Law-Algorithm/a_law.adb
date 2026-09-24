with Ada.Numerics.Elementary_Functions;

package body A_Law is
   use Ada.Numerics.Elementary_Functions;

   -- -------------------------------------------------------------------------
   -- Internal Helper: Float Sign Extraction
   -- -------------------------------------------------------------------------
   function Sign_Float (X : Float) return Float is
   begin
      if X >= 0.0 then
         return 1.0;
      else
         return -1.0;
      end if;
   end Sign_Float;

   -- -------------------------------------------------------------------------
   -- Internal Helper: Clamp Float to [-1.0, 1.0] to prevent Float rounding errors
   -- -------------------------------------------------------------------------
   function Clamp_Float (X : Float) return Float is
   begin
      if X > 1.0 then 
         return 1.0;
      elsif X < -1.0 then 
         return -1.0;
      else 
         return X;
      end if;
   end Clamp_Float;

   -- -------------------------------------------------------------------------
   -- Internal Helper: Find Highest Set Bit (0-Indexed) for Exponent Calc
   -- -------------------------------------------------------------------------
   function Highest_Set_Bit (Val : Natural) return Integer is
      Temp : Natural := Val;
      Bit  : Integer := -1;
   begin
      while Temp > 0 loop
         Temp := Temp / 2;
         Bit := Bit + 1;
      end loop;
      return Bit;
   end Highest_Set_Bit;

   -- =========================================================================
   -- Continuous Domain Implementations
   -- =========================================================================
   function Encode_Continuous (X : Normalized_Sample; A : Float := A_Value) return Normalized_Sample is
      Abs_X : constant Float := abs (Float (X));
      Sgn_X : constant Float := Sign_Float (Float (X));
      Ln_A  : constant Float := Log (A);
      Denom : constant Float := 1.0 + Ln_A;
      Y     : Float;
   begin
      -- Two-part piecewise function based on 1/A threshold
      if Abs_X < (1.0 / A) then
         Y := (A * Abs_X) / Denom;
      else
         Y := (1.0 + Log (A * Abs_X)) / Denom;
      end if;
      
      -- Clamp required to prevent CONSTRAINT_ERROR from Floating-Point rounding
      return Normalized_Sample (Clamp_Float (Y * Sgn_X));
   end Encode_Continuous;

   function Decode_Continuous (Y : Normalized_Sample; A : Float := A_Value) return Normalized_Sample is
      Abs_Y : constant Float := abs (Float (Y));
      Sgn_Y : constant Float := Sign_Float (Float (Y));
      Ln_A  : constant Float := Log (A);
      Denom : constant Float := 1.0 + Ln_A;
      X     : Float;
   begin
      -- Inverse of the piecewise A-law function
      if Abs_Y < (1.0 / Denom) then
         X := (Abs_Y * Denom) / A;
      else
         X := Exp (Abs_Y * Denom - 1.0) / A;
      end if;
      
      -- Clamp required to prevent CONSTRAINT_ERROR from Floating-Point rounding
      return Normalized_Sample (Clamp_Float (X * Sgn_Y));
   end Decode_Continuous;

   -- =========================================================================
   -- Discrete Domain Implementations (G.711)
   -- =========================================================================
   function Encode_Discrete (X : PCM_Sample) return A_Law_Byte is
      Sign_Bit : A_Law_Byte;
      Val      : Natural;
      Exponent : Natural := 0;
      Mantissa : Natural := 0;
      Result   : A_Law_Byte;
   begin
      -- 1. Determine Sign (Bit 7: 1 for positive, 0 for negative in A-law)
      if X >= 0 then
         Sign_Bit := 128; 
         Val := Natural (X);
      else
         Sign_Bit := 0;
         Val := Natural (abs (Integer (X)));
      end if;

      -- 2. Clamp Edge Case (-4096 becomes 4095 because 13-bit max magnitude is 4095)
      if Val > 4095 then
         Val := 4095;
      end if;

      -- 3. Extract Exponent (Bits 4-6) and Mantissa (Bits 0-3)
      if Val < 32 then
         Exponent := 0;
         Mantissa := Val / 2; -- First chord scales by 2
      else
         declare
            H_Bit : constant Integer := Highest_Set_Bit (Val);
         begin
            Exponent := H_Bit - 4;
            -- Boundary clamping for safety
            if Exponent > 7 then
               Exponent := 7;
            end if;
            -- Shift magnitude by exponent to get fraction
            Mantissa := (Val / (2 ** Exponent)) mod 16;
         end;
      end if;

      -- 4. Combine Sign, Exponent, and Mantissa
      Result := Sign_Bit + A_Law_Byte (Exponent * 16) + A_Law_Byte (Mantissa);

      -- 5. Standard G.711 requires toggling even bits (XOR 0x55) to increase transition density
      return Result xor 16#55#;
   end Encode_Discrete;

   function Decode_Discrete (Y : A_Law_Byte) return PCM_Sample is
      -- 1. Undo G.711 transmission toggle
      Toggled  : constant A_Law_Byte := Y xor 16#55#;
      
      -- 2. Extract components
      Sign_Bit : constant A_Law_Byte := Toggled / 128;
      Exponent : constant Natural := Natural ((Toggled / 16) mod 8);
      Mantissa : constant Natural := Natural (Toggled mod 16);
      
      Val      : Natural;
      Result   : Integer;
   begin
      -- 3. Reconstruct linear magnitude based on exponent chord
      if Exponent = 0 then
         -- The missing "x" bit is assumed as 1 (middle of the step size) to minimize error
         Val := (Mantissa * 2) + 1; 
      else
         -- Formula applies step-center compensation (2^(e-1))
         Val := (16 + Mantissa) * (2 ** Exponent) + (2 ** (Exponent - 1));
      end if;

      -- 4. Reapply Sign
      if Sign_Bit = 1 then
         Result := Val;
      else
         Result := -Val;
      end if;

      return PCM_Sample (Result);
   end Decode_Discrete;

end A_Law;
