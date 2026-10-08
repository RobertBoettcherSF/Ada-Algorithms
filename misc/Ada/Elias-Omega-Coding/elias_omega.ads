-- elias_omega.ads
-- Specification for Elias Omega Coding and its generalizations.

package Elias_Omega is

   -- Exceptions
   Invalid_Input   : exception;
   Decoding_Error  : exception;

   -- Bit type and representation
   type Bit is (Zero, One);
   type Bit_Array is array (Positive range <>) of Bit;

   -- Variant 1: Standard Elias Omega Encoding for Positive Integers (N >= 1)
   function Encode (N : Positive) return Bit_Array;

   -- Variant 1: Standard Elias Omega Decoding from Bit Stream
   function Decode (Bits : Bit_Array; Index : in out Positive) return Positive;

   -- Variant 2: Non-Negative Integer Encoding (N >= 0)
   -- Encodes N by encoding N + 1
   function Encode_Non_Negative (N : Natural) return Bit_Array;
   function Decode_Non_Negative (Bits : Bit_Array; Index : in out Positive) return Natural;

   -- Variant 3: Signed Integer Encoding (All integers: 0, 1, -1, 2, -2, ...)
   -- Maps integers to positive integers via bijection before encoding.
   function Encode_Signed (N : Integer) return Bit_Array;
   function Decode_Signed (Bits : Bit_Array; Index : in out Positive) return Integer;

   -- Helper function to convert Bit_Array to String for display
   function To_String (Bits : Bit_Array) return String;

end Elias_Omega;
