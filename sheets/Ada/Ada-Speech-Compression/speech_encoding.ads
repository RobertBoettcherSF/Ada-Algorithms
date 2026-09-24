-- speech_encoding.ads
-- Specification for Speech Encoding algorithms
-- Implements variants of waveform coding and differential coding.

package Speech_Encoding is

   -- Basic types for audio samples
   type Audio_Sample is digits 6; -- Floating point representation
   
   -- Array types for sequences of samples
   type Audio_Buffer is array (Positive range <>) of Audio_Sample;
   
   -- Exceptions for edge cases and invalid data
   Invalid_Sample_Error : exception;
   Empty_Buffer_Error   : exception;

   -------------------------------------------------------------------
   -- VARIANT 1: Mu-Law Companding (G.711 Standard Algorithm)
   -- Used primarily in North America and Japan for speech encoding.
   -------------------------------------------------------------------
   
   -- Compresses a linear PCM sample into a logarithmic scale.
   -- Input must be in the range -1.0 to 1.0.
   function Mu_Law_Encode (Sample : Audio_Sample) return Audio_Sample;
   
   -- Expands a logarithmic Mu-Law sample back to linear PCM.
   function Mu_Law_Decode (Encoded : Audio_Sample) return Audio_Sample;


   -------------------------------------------------------------------
   -- VARIANT 2: A-Law Companding (G.711 Standard Algorithm)
   -- Used primarily in Europe and the rest of the world.
   -------------------------------------------------------------------
   
   -- Compresses a linear PCM sample using the A-Law algorithm.
   function A_Law_Encode (Sample : Audio_Sample) return Audio_Sample;
   
   -- Expands an A-Law sample back to linear PCM.
   function A_Law_Decode (Encoded : Audio_Sample) return Audio_Sample;


   -------------------------------------------------------------------
   -- VARIANT 3: Differential Pulse-Code Modulation (DPCM)
   -- Encodes the difference between consecutive samples to save space.
   -------------------------------------------------------------------
   
   -- Encodes a buffer of linear samples into differential samples.
   procedure DPCM_Encode (Input : in Audio_Buffer; Output : out Audio_Buffer);
   
   -- Decodes a buffer of differential samples back to linear samples.
   procedure DPCM_Decode (Input : in Audio_Buffer; Output : out Audio_Buffer);

private
   -- Helper constants
   Mu_Constant : constant Audio_Sample := 255.0;
   A_Constant  : constant Audio_Sample := 87.56;

end Speech_Encoding;
