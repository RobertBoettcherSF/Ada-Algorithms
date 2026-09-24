-- rice_coding.ads
-- Package specification for Rice and Golomb entropy encoding algorithms.
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Rice_Coding is

   -- Custom strong types for algorithmic boundaries
   type Unsigned_Value is mod 2**32;
   type Signed_Value is range -2**31 .. 2**31 - 1;
   
   -- Parameter K (where divisor M = 2^K for Rice coding)
   type Rice_Parameter is range 0 .. 31; 
   
   -- Parameter M (divisor for generalized Golomb coding)
   type Golomb_Parameter is range 1 .. 2**31 - 1;

   -- Exceptions
   Decoding_Error : exception;
   Invalid_Parameter : exception;

   -- =========================================================================
   -- Variant 1: Standard Rice Coding (Non-negative integers)
   -- =========================================================================
   function Encode_Rice (Value : Unsigned_Value; K : Rice_Parameter) return Unbounded_String;
   function Decode_Rice (Bits : Unbounded_String; K : Rice_Parameter) return Unsigned_Value;

   -- =========================================================================
   -- Variant 2: Signed Rice Coding
   -- Uses ZigZag (overlap) mapping: 0->0, -1->1, 1->2, -2->3, 2->4, etc.
   -- =========================================================================
   function Encode_Signed_Rice (Value : Signed_Value; K : Rice_Parameter) return Unbounded_String;
   function Decode_Signed_Rice (Bits : Unbounded_String; K : Rice_Parameter) return Signed_Value;

   -- =========================================================================
   -- Variant 3: Generalized Golomb Coding
   -- Rice coding is a special case of Golomb coding where M is a power of 2.
   -- =========================================================================
   function Encode_Golomb (Value : Unsigned_Value; M : Golomb_Parameter) return Unbounded_String;
   function Decode_Golomb (Bits : Unbounded_String; M : Golomb_Parameter) return Unsigned_Value;

private
   -- Helper Functions for internal conversion and math
   function Ceil_Log2 (N : Golomb_Parameter) return Natural;
   function ZigZag_Encode (Value : Signed_Value) return Unsigned_Value;
   function ZigZag_Decode (Value : Unsigned_Value) return Signed_Value;
   function To_Unary_String (Value : Unsigned_Value) return String;
   function To_Binary_String (Value : Unsigned_Value; Bits : Natural) return String;
   function Decode_Unary (Bits : Unbounded_String; Index : in out Positive) return Unsigned_Value;
   function Decode_Binary (Bits : String) return Unsigned_Value;

end Rice_Coding;
