-- speech_encoding.adb
-- Implementation of Speech Encoding variants

with Ada.Numerics.Generic_Elementary_Functions;

package body Speech_Encoding is

   package Math is new Ada.Numerics.Generic_Elementary_Functions (Audio_Sample);
   use Math;

   -- Helper Function: Returns the sign of the sample (1.0 or -1.0)
   function Sign (X : Audio_Sample) return Audio_Sample is
   begin
      if X < 0.0 then
         return -1.0;
      elsif X > 0.0 then
         return 1.0;
      else
         return 0.0;
      end if;
   end Sign;

   -- Helper Function: Validates sample bounds (-1.0 to 1.0)
   procedure Validate_Bounds (X : Audio_Sample) is
   begin
      if X < -1.0 or else X > 1.0 then
         raise Invalid_Sample_Error with "Sample out of normalized bounds (-1.0 to 1.0)";
      end if;
   end Validate_Bounds;

   -------------------------------------------------------------------
   -- Mu-Law Implementation
   -------------------------------------------------------------------
   function Mu_Law_Encode (Sample : Audio_Sample) return Audio_Sample is
      Abs_Sample : Audio_Sample := abs(Sample);
   begin
      Validate_Bounds(Sample);
      -- F(x) = sgn(x) * ln(1 + mu * |x|) / ln(1 + mu)
      return Sign(Sample) * (Log (1.0 + Mu_Constant * Abs_Sample) / Log (1.0 + Mu_Constant));
   end Mu_Law_Encode;

   function Mu_Law_Decode (Encoded : Audio_Sample) return Audio_Sample is
      Abs_Encoded : Audio_Sample := abs(Encoded);
   begin
      Validate_Bounds(Encoded);
      -- F^-1(y) = sgn(y) * (1 / mu) * ((1 + mu)^|y| - 1)
      return Sign(Encoded) * (1.0 / Mu_Constant) * (Exp (Abs_Encoded * Log (1.0 + Mu_Constant)) - 1.0);
   end Mu_Law_Decode;

   -------------------------------------------------------------------
   -- A-Law Implementation
   -------------------------------------------------------------------
   function A_Law_Encode (Sample : Audio_Sample) return Audio_Sample is
      Abs_Sample : Audio_Sample := abs(Sample);
      Threshold  : constant Audio_Sample := 1.0 / A_Constant;
      Divisor    : constant Audio_Sample := 1.0 + Log (A_Constant);
   begin
      Validate_Bounds(Sample);
      if Abs_Sample < Threshold then
         -- Linear region
         return Sign(Sample) * (A_Constant * Abs_Sample) / Divisor;
      else
         -- Logarithmic region
         return Sign(Sample) * (1.0 + Log (A_Constant * Abs_Sample)) / Divisor;
      end if;
   end A_Law_Encode;

   function A_Law_Decode (Encoded : Audio_Sample) return Audio_Sample is
      Abs_Encoded : Audio_Sample := abs(Encoded);
      Threshold   : constant Audio_Sample := 1.0 / (1.0 + Log (A_Constant));
   begin
      Validate_Bounds(Encoded);
      if Abs_Encoded < Threshold then
         -- Linear region
         return Sign(Encoded) * (Abs_Encoded * (1.0 + Log (A_Constant))) / A_Constant;
      else
         -- Logarithmic region
         return Sign(Encoded) * (Exp (Abs_Encoded * (1.0 + Log (A_Constant)) - 1.0)) / A_Constant;
      end if;
   end A_Law_Decode;

   -------------------------------------------------------------------
   -- DPCM Implementation
   -------------------------------------------------------------------
   procedure DPCM_Encode (Input : in Audio_Buffer; Output : out Audio_Buffer) is
      Previous : Audio_Sample := 0.0;
   begin
      if Input'Length = 0 then
         raise Empty_Buffer_Error with "Cannot encode an empty buffer";
      end if;
      
      for I in Input'Range loop
         -- Encode the difference between current and previous sample
         Output(I) := Input(I) - Previous;
         Previous  := Input(I);
      end loop;
   end DPCM_Encode;

   procedure DPCM_Decode (Input : in Audio_Buffer; Output : out Audio_Buffer) is
      Accumulator : Audio_Sample := 0.0;
   begin
      if Input'Length = 0 then
         raise Empty_Buffer_Error with "Cannot decode an empty buffer";
      end if;
      
      for I in Input'Range loop
         -- Reconstruct the original sample by adding the difference
         Accumulator := Accumulator + Input(I);
         Output(I)   := Accumulator;
      end loop;
   end DPCM_Decode;

end Speech_Encoding;
