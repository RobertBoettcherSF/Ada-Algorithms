-- mu_law.adb
-- Implementation body for the Mu-law algorithm package.

with Ada.Numerics.Elementary_Functions; 
use Ada.Numerics.Elementary_Functions;

package body Mu_Law is

   -- =========================================================================
   -- Helper Functions
   -- =========================================================================

   -- Helper function to extract the mathematical sign of a float
   function Sign (Value : Float) return Float is
   begin
      if Value > 0.0 then
         return 1.0;
      elsif Value < 0.0 then
         return -1.0;
      else
         return 0.0;
      end if;
   end Sign;

   -- =========================================================================
   -- Continuous / Analog Variants
   -- =========================================================================

   function Encode_Continuous (X  : Normalized_Signal;
                               Mu : Float := 255.0) return Normalized_Signal is
   begin
      -- Edge Case Validation: Mu must be strictly positive
      if Mu <= 0.0 then
         raise Invalid_Mu_Error;
      end if;

      -- F(x) = sgn(x) * ln(1 + u|x|) / ln(1 + u)
      return Normalized_Signal (Sign(X) * Log(1.0 + Mu * (abs X)) / Log(1.0 + Mu));
   end Encode_Continuous;

   function Decode_Continuous (Y  : Normalized_Signal;
                               Mu : Float := 255.0) return Normalized_Signal is
   begin
      -- Edge Case Validation: Mu must be strictly positive
      if Mu <= 0.0 then
         raise Invalid_Mu_Error;
      end if;

      -- F^-1(y) = sgn(y) * (1/u) * ((1 + u)^|y| - 1)
      -- Note: Parantheses around (abs Y) are required due to Ada operator precedence
      return Normalized_Signal (Sign(Y) * (1.0 / Mu) * ((1.0 + Mu) ** (abs Y) - 1.0));
   end Decode_Continuous;

   -- =========================================================================
   -- Discrete / Digital Variants
   -- =========================================================================

   function Encode_Digital (X : PCM_14_Bit) return Mu_Law_8_Bit is
      Normalized_X : Normalized_Signal;
      Normalized_Y : Float;
      Companded    : Float;
   begin
      -- Scale 14-bit integer to normalized float range [-1.0, 1.0]
      Normalized_X := Float(X) / 8192.0; 
      
      -- Apply continuous compression formula
      Normalized_Y := Encode_Continuous(Normalized_X, 255.0);
      
      -- Scale back to 8-bit signed range [-127.0, 127.0]
      Companded := Normalized_Y * 127.0;
      
      -- Safely cast to bounded integer with clipping for floating-point inaccuracies
      if Companded > 127.0 then
         return 127;
      elsif Companded < -128.0 then
         return -128;
      else
         return Mu_Law_8_Bit (Companded);
      end if;
   end Encode_Digital;


   function Decode_Digital (Y : Mu_Law_8_Bit) return PCM_14_Bit is
      Normalized_Y : Normalized_Signal;
      Normalized_X : Float;
      Expanded     : Float;
   begin
      -- Scale 8-bit companded integer to normalized float range [-1.0, 1.0]
      Normalized_Y := Float(Y) / 127.0;
      
      -- Edge case clamping to avoid Constraint_Error if Float(Y)/127.0 > 1.0
      if Normalized_Y > 1.0 then 
         Normalized_Y := 1.0;
      elsif Normalized_Y < -1.0 then 
         Normalized_Y := -1.0; 
      end if;

      -- Apply continuous expansion formula
      Normalized_X := Decode_Continuous(Normalized_Y, 255.0);
      
      -- Scale back to 14-bit linear range
      Expanded := Normalized_X * 8192.0;
      
      -- Safely cast back to PCM_14_Bit range with clipping
      if Expanded > 8191.0 then
         return 8191;
      elsif Expanded < -8192.0 then
         return -8192;
      else
         return PCM_14_Bit (Expanded);
      end if;
   end Decode_Digital;

end Mu_Law;
