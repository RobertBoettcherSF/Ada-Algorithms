package A_Law is
   pragma Pure;

   -- =========================================================================
   -- Strong Typing Definitions
   -- =========================================================================
   
   -- Continuous domain requires values between -1.0 and +1.0
   type Normalized_Sample is new Float range -1.0 .. 1.0;
   
   -- Discrete 13-bit signed PCM Sample (G.711 standard input)
   type PCM_Sample is new Integer range -4096 .. 4095;
   
   -- 8-bit unsigned integer representing the transmitted A-law encoded byte
   type A_Law_Byte is mod 256; 

   -- Standard A-law companding parameter used in Europe (87.6)
   A_Value : constant Float := 87.6;

   -- =========================================================================
   -- Continuous Domain Variants (Mathematical Formulation)
   -- =========================================================================
   
   -- Encodes a normalized continuous sample into a companded continuous sample
   function Encode_Continuous (X : Normalized_Sample; A : Float := A_Value) return Normalized_Sample;
   
   -- Expands (decodes) a companded continuous sample back to normalized linear scale
   function Decode_Continuous (Y : Normalized_Sample; A : Float := A_Value) return Normalized_Sample;

   -- =========================================================================
   -- Discrete Domain Variants (G.711 8-bit PCM Standard)
   -- =========================================================================
   
   -- Compresses a 13-bit linear PCM sample into an 8-bit A-law byte 
   -- (Includes even-bit inversion 0x55 for transmission stability)
   function Encode_Discrete (X : PCM_Sample) return A_Law_Byte;
   
   -- Expands an 8-bit A-law byte back into a 13-bit linear PCM sample
   function Decode_Discrete (Y : A_Law_Byte) return PCM_Sample;

end A_Law;
