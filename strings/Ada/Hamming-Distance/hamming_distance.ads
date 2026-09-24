with Interfaces;

package Hamming_Distance is

   -- Raised when comparing vectors or strings of unequal length.
   -- The Hamming distance is strictly defined only for sequences of equal length.
   Length_Mismatch_Error : exception;

   -- Custom strongly-typed definition for Boolean/Binary sequences,
   -- commonly used in telecommunications and error-correction codes.
   type Bit_Array is array (Positive range <>) of Boolean;

   -- Variant 1: General String Hamming Distance
   -- Used for text comparison, genetic sequences (DNA), and general strings.
   function Distance (S1, S2 : String) return Natural;

   -- Variant 2: Bit Array Hamming Distance
   -- Used for Boolean arrays and binary sequences.
   function Distance (B1, B2 : Bit_Array) return Natural;

   -- Variant 3: Unsigned 64-bit Integer Hamming Distance
   -- Hardware-level/bitwise variant. Calculates distance by XORing
   -- two integers and counting the number of set bits (popcount).
   function Distance (U1, U2 : Interfaces.Unsigned_64) return Natural;

   -- Variant 4: Hamming Weight of a String
   -- The Hamming weight is the number of non-zero symbols in a string.
   -- It is equivalent to the Hamming distance from the zero-vector (or spaces).
   function Weight (S : String; Zero_Char : Character := ' ') return Natural;

end Hamming_Distance;
