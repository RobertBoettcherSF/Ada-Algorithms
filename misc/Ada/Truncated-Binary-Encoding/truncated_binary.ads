package Truncated_Binary is

   -- Strongly typed numeric values specific to the domain
   type Alphabet_Size is new Positive;
   type Symbol_Value is new Natural;

   -- Exceptions for error handling
   Invalid_Symbol_Error   : exception;
   Decoding_Error         : exception;

   -- Variants of the Algorithm:
   
   -- 1. Encode: Converts a symbol into its truncated binary representation.
   function Encode (X : Symbol_Value; N : Alphabet_Size) return String;

   -- 2. Decode Stream: Decodes a symbol from a bit string, allowing trailing bits.
   -- Returns the parsed symbol and outputs how many bits were consumed.
   function Decode (Bits     : String; 
                    N        : Alphabet_Size; 
                    Consumed : out Natural) return Symbol_Value;

   -- 3. Decode Exact: Decodes a string expecting it to contain exactly ONE symbol,
   -- raising an error if the string contains extra/unconsumed bits.
   function Decode_Exact (Bits : String; N : Alphabet_Size) return Symbol_Value;

end Truncated_Binary;
