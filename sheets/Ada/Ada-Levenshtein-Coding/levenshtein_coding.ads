package Levenshtein_Coding is

   -- Using Long_Long_Integer to robustly support large 64-bit values
   subtype Value_Type is Long_Long_Integer range 0 .. Long_Long_Integer'Last;

   -- Strongly typed bit representation to avoid arbitrary string bugs
   type Bit is (B_0, B_1);
   type Bit_String is array (Positive range <>) of Bit;

   -- Exception raised for malformed or invalid Levenshtein encodings
   Invalid_Encoding : exception;

   -- Variant 1: Encodes a non-negative integer into a Levenshtein coded Bit_String
   function Encode (Value : Value_Type) return Bit_String;

   -- Variant 2: Decodes a Levenshtein coded Bit_String back into a non-negative integer
   function Decode (Bits : Bit_String) return Value_Type;

   -- Helper: Converts Bit_String to standard String (e.g., "1110000") for printing
   function To_String (Bits : Bit_String) return String;

   -- Helper: Converts a standard String of '0's and '1's to a Bit_String
   function To_Bit_String (Str : String) return Bit_String;

end Levenshtein_Coding;
