-- audio_compression.adb
-- Package body implementing audio compression algorithms.

with Ada.Numerics.Elementary_Functions;
use Ada.Numerics.Elementary_Functions;

package body Audio_Compression is

   -- =========================================================================
   -- HELPER FUNCTIONS
   -- =========================================================================

   -- Safely clamps a Float back into the bounds of a 16-bit PCM integer
   function Clamp_To_PCM_16 (Value : Float) return PCM_16 is
   begin
      if Value > 32767.0 then
         return 32767;
      elsif Value < -32768.0 then
         return -32768;
      else
         return PCM_16 (Value);
      end if;
   end Clamp_To_PCM_16;

   -- Safely clamps a Float back into the bounds of an 8-bit PCM integer
   function Clamp_To_PCM_8 (Value : Float) return PCM_8 is
   begin
      if Value > 127.0 then
         return 127;
      elsif Value < -128.0 then
         return -128;
      else
         return PCM_8 (Value);
      end if;
   end Clamp_To_PCM_8;

   -- Returns the sign of a floating-point number
   function Sgn (Value : Float) return Float is
   begin
      if Value > 0.0 then return 1.0;
      elsif Value < 0.0 then return -1.0;
      else return 0.0;
      end if;
   end Sgn;

   -- =========================================================================
   -- MU-LAW IMPLEMENTATION
   -- Formula: F(x) = sgn(x) * (ln(1 + u*|x|) / ln(1 + u))
   -- =========================================================================
   function Encode_Mu_Law (Sample : PCM_16) return PCM_8 is
      Norm_X, Abs_X, Encoded : Float;
   begin
      -- Normalize 16-bit sample to [-1.0, 1.0]
      Norm_X := Float(Sample) / 32768.0;
      Abs_X  := abs(Norm_X);
      
      -- Apply Mu-law transformation
      Encoded := Sgn(Norm_X) * (Log(1.0 + Mu_Value * Abs_X) / Log(1.0 + Mu_Value));
      
      -- Scale to 8-bit and clamp
      return Clamp_To_PCM_8(Encoded * 128.0);
   end Encode_Mu_Law;

   function Decode_Mu_Law (Sample : PCM_8) return PCM_16 is
      Norm_Y, Abs_Y, Decoded : Float;
   begin
      -- Normalize 8-bit sample to [-1.0, 1.0]
      Norm_Y := Float(Sample) / 128.0;
      Abs_Y  := abs(Norm_Y);
      
      -- Apply inverse Mu-law transformation: x = sgn(y) * (1/u) * ((1+u)^|y| - 1)
      Decoded := Sgn(Norm_Y) * (1.0 / Mu_Value) * (((1.0 + Mu_Value) ** Abs_Y) - 1.0);
      
      -- Scale back to 16-bit and clamp
      return Clamp_To_PCM_16(Decoded * 32768.0);
   end Decode_Mu_Law;

   -- =========================================================================
   -- A-LAW IMPLEMENTATION
   -- Piecewise logarithmic compression.
   -- =========================================================================
   function Encode_A_Law (Sample : PCM_16) return PCM_8 is
      Norm_X, Encoded, Abs_X : Float;
   begin
      Norm_X := Float(Sample) / 32768.0;
      Abs_X := abs(Norm_X);
      
      if Abs_X < (1.0 / A_Value) then
         Encoded := Sgn(Norm_X) * ((A_Value * Abs_X) / (1.0 + Log(A_Value)));
      else
         Encoded := Sgn(Norm_X) * ((1.0 + Log(A_Value * Abs_X)) / (1.0 + Log(A_Value)));
      end if;
      
      return Clamp_To_PCM_8(Encoded * 128.0);
   end Encode_A_Law;

   function Decode_A_Law (Sample : PCM_8) return PCM_16 is
      Norm_Y, Decoded, Abs_Y : Float;
      Threshold : constant Float := 1.0 / (1.0 + Log(A_Value));
   begin
      Norm_Y := Float(Sample) / 128.0;
      Abs_Y := abs(Norm_Y);
      
      if Abs_Y < Threshold then
         Decoded := Sgn(Norm_Y) * ((Abs_Y * (1.0 + Log(A_Value))) / A_Value);
      else
         Decoded := Sgn(Norm_Y) * (Exp(-1.0 + Abs_Y * (1.0 + Log(A_Value))) / A_Value);
      end if;
      
      return Clamp_To_PCM_16(Decoded * 32768.0);
   end Decode_A_Law;

   -- =========================================================================
   -- DPCM IMPLEMENTATION (Differential PCM)
   -- =========================================================================
   function Encode_DPCM (Input : Buffer_16) return Buffer_16 is
      Result : Buffer_16 (Input'Range);
      Previous_Sample : Integer := 0;
      Diff : Integer;
   begin
      -- Edge Case: Empty buffer
      if Input'Length = 0 then
         return Result;
      end if;

      for I in Input'Range loop
         -- Calculate difference using wider type to prevent overflow
         Diff := Integer(Input(I)) - Previous_Sample;
         
         -- Clamp difference to fit in 16-bit PCM limit (introduces loss on extreme deltas)
         if Diff > 32767 then Diff := 32767;
         elsif Diff < -32768 then Diff := -32768;
         end if;
         
         Result(I) := PCM_16(Diff);
         Previous_Sample := Integer(Input(I));
      end loop;
      
      return Result;
   end Encode_DPCM;

   function Decode_DPCM (Input : Buffer_16) return Buffer_16 is
      Result : Buffer_16 (Input'Range);
      Previous_Sample : Integer := 0;
      Current_Val : Integer;
   begin
      -- Edge Case: Empty buffer
      if Input'Length = 0 then
         return Result;
      end if;

      for I in Input'Range loop
         -- Reconstruct by adding difference to previous sample
         Current_Val := Integer(Input(I)) + Previous_Sample;
         
         -- Clamp to prevent overflow on reconstruction
         if Current_Val > 32767 then Current_Val := 32767;
         elsif Current_Val < -32768 then Current_Val := -32768;
         end if;
         
         Result(I) := PCM_16(Current_Val);
         Previous_Sample := Current_Val;
      end loop;
      
      return Result;
   end Decode_DPCM;

end Audio_Compression;
