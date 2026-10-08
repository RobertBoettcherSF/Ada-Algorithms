-- universal_codes.ads
-- Package specification for Universal Codes (Data Compression)
-- Implements Unary, Elias Gamma, Elias Delta, Elias Omega, and Fibonacci coding.

package Universal_Codes is

   -- Strong typing for bits to prevent integer contamination and enhance safety
   type Bit is range 0 .. 1;
   type Bit_Array is array (Positive range <>) of Bit;

   -- Exceptions for error handling
   Decoding_Error : exception;
   Invalid_Input_Error : exception;

   -- Unary Coding
   -- Encodes N as N-1 ones followed by a zero
   function Encode_Unary (N : Positive) return Bit_Array;
   function Decode_Unary (Bits : Bit_Array) return Positive;

   -- Elias Gamma Coding
   -- Asymptotically optimal for integers whose probability decreases as a power of 2
   function Encode_Elias_Gamma (N : Positive) return Bit_Array;
   function Decode_Elias_Gamma (Bits : Bit_Array) return Positive;

   -- Elias Delta Coding
   -- Better than Gamma for large integers
   function Encode_Elias_Delta (N : Positive) return Bit_Array;
   function Decode_Elias_Delta (Bits : Bit_Array) return Positive;

   -- Elias Omega Coding
   -- Recursive encoding structure
   function Encode_Elias_Omega (N : Positive) return Bit_Array;
   function Decode_Elias_Omega (Bits : Bit_Array) return Positive;

   -- Fibonacci Coding
   -- Based on Zeckendorf's theorem, inherently resilient due to absence of consecutive 1s in payload
   function Encode_Fibonacci (N : Positive) return Bit_Array;
   function Decode_Fibonacci (Bits : Bit_Array) return Positive;

   -- Utility Function: Convert string of '0' and '1' to Bit_Array for easier testing
   function To_Bits (S : String) return Bit_Array;

end Universal_Codes;
