-- mu_law.ads
-- Specification for the Mu-law algorithm package.
-- Implements variants for both continuous/analog signals and discrete/digital PCM samples.

package Mu_Law is

   -- =========================================================================
   -- Types and Exceptions
   -- =========================================================================
   
   -- Represents a continuous audio signal bounded between -1.0 and 1.0
   subtype Normalized_Signal is Float range -1.0 .. 1.0;
   
   -- 14-bit Signed Linear PCM data (used as input in North American standard digital domain)
   type PCM_14_Bit is range -8192 .. 8191;
   
   -- 8-bit companded signal (represented here mathematically as a signed byte for algebraic symmetry)
   type Mu_Law_8_Bit is range -128 .. 127;

   -- Exception raised when an invalid compression parameter (Mu) is provided
   Invalid_Mu_Error : exception;

   -- =========================================================================
   -- Subprogram Declarations (Continuous/Analog Variants)
   -- =========================================================================

   -- Variant 1: Continuous (Analog) Mu-law Encoding (Compression)
   -- Mathematically compresses a signal's dynamic range.
   -- @param X: The input normalized signal (-1.0 <= X <= 1.0)
   -- @param Mu: The compression parameter (Standard is 255.0 in North America)
   function Encode_Continuous (X  : Normalized_Signal;
                               Mu : Float := 255.0) return Normalized_Signal;

   -- Variant 2: Continuous (Analog) Mu-law Decoding (Expansion)
   -- Mathematically expands a signal back to its original dynamic range.
   -- @param Y: The compressed normalized signal (-1.0 <= Y <= 1.0)
   -- @param Mu: The compression parameter (Standard is 255.0 in North America)
   function Decode_Continuous (Y  : Normalized_Signal;
                               Mu : Float := 255.0) return Normalized_Signal;


   -- =========================================================================
   -- Subprogram Declarations (Discrete/Digital Variants)
   -- =========================================================================

   -- Variant 3: Digital Mu-law Encoding
   -- Converts a 14-bit linear PCM signal into an 8-bit companded signal
   -- via mathematical translation of the continuous variant.
   function Encode_Digital (X : PCM_14_Bit) return Mu_Law_8_Bit;

   -- Variant 4: Digital Mu-law Decoding
   -- Converts an 8-bit companded signal back into a 14-bit linear PCM signal.
   function Decode_Digital (Y : Mu_Law_8_Bit) return PCM_14_Bit;

end Mu_Law;
