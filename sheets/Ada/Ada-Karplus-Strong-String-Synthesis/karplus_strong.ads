-- karplus_strong.ads
-- Package specification for the Karplus-Strong string synthesis algorithm.

package Karplus_Strong is

   -- Use standard Float for audio samples (typically -1.0 to 1.0)
   type Sample_Type is new Float;
   
   -- Array to hold audio frames
   type Sample_Array is array (Positive range <>) of Sample_Type;

   -- Exceptions for edge cases and invalid configurations
   Invalid_Frequency : exception;
   Invalid_Parameter : exception;

   -- 1. Standard Karplus-Strong Plucked String Synthesis
   -- Uses a basic averaging low-pass filter: y[n] = decay * 0.5 * (x[n] + x[n-1])
   procedure Plucked_String (
      Output       : in out Sample_Array;
      Sample_Rate  : in Sample_Type;
      Frequency    : in Sample_Type;
      Decay_Factor : in Sample_Type := 0.996
   );

   -- 2. Kevin Karplus & Alex Strong Drum Synthesis Variant
   -- Introduces a 50% chance (or custom Blend_Factor) to invert the sign 
   -- of the feedback, scattering the harmonics to sound drum-like.
   procedure Drum_Sound (
      Output       : in out Sample_Array;
      Sample_Rate  : in Sample_Type;
      Frequency    : in Sample_Type;
      Blend_Factor : in Sample_Type := 0.5;
      Decay_Factor : in Sample_Type := 0.996
   );

   -- 3. Jaffe-Smith Tuned String (Extended Karplus-Strong)
   -- Because integer-length delay lines limit exact tuning, this variant 
   -- adds an all-pass filter to introduce a fractional delay, achieving exact pitch.
   procedure Tuned_String (
      Output       : in out Sample_Array;
      Sample_Rate  : in Sample_Type;
      Frequency    : in Sample_Type;
      Decay_Factor : in Sample_Type := 0.996
   );

end Karplus_Strong;
