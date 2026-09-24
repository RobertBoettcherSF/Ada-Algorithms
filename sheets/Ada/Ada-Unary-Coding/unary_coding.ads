-- unary_coding.ads
-- Package specification for Unary Coding algorithms

package Unary_Coding is

   -- Strong typing: Define custom types for our domain
   type Unary_Value is new Natural;
   
   -- Exception for handling malformed, empty, or invalid unary strings
   Invalid_Encoding : exception;

   -- =========================================================================
   -- Variant 1: Standard Unary Coding (N ones followed by a zero)
   -- Used for non-negative integers (N >= 0)
   -- Example: 3 -> "1110", 0 -> "0"
   -- =========================================================================
   function Encode_Ones_Zero (N : Unary_Value) return String;
   function Decode_Ones_Zero (Code : String) return Unary_Value;

   -- =========================================================================
   -- Variant 2: Alternative Unary Coding (N zeros followed by a one)
   -- Used for non-negative integers (N >= 0)
   -- Example: 3 -> "0001", 0 -> "1"
   -- =========================================================================
   function Encode_Zeros_One (N : Unary_Value) return String;
   function Decode_Zeros_One (Code : String) return Unary_Value;

   -- =========================================================================
   -- Variant 3: Positive Unary Coding (1-based index)
   -- Used for strictly positive integers (N >= 1), encoded as N-1 ones and a 0
   -- Common in algorithms like Elias Gamma coding
   -- Example: 1 -> "0", 4 -> "1110"
   -- =========================================================================
   function Encode_Positive_Ones (N : Positive) return String;
   function Decode_Positive_Ones (Code : String) return Positive;

end Unary_Coding;
