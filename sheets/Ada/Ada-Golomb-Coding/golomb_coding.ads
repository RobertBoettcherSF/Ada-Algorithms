-- golomb_coding.ads
-- Specification for Golomb coding algorithm and its variants.

package Golomb_Coding is

   -- Custom exception for decoding errors
   Invalid_Bit_String : exception;

   -- =========================================================================
   -- 1. Standard Golomb Coding
   -- Encodes non-negative integers using a tunable parameter M.
   -- =========================================================================
   function Encode_Golomb (N : Natural; M : Positive) return String;
   
   -- Decodes and returns the value, outputting how many bits were consumed.
   function Decode_Golomb (Bits : String; M : Positive; Consumed : out Natural) return Natural;
   
   -- Convenience wrapper: verifies all bits are consumed.
   function Decode_Golomb_Exact (Bits : String; M : Positive) return Natural;


   -- =========================================================================
   -- 2. Rice Coding (Variant)
   -- Special case of Golomb coding where M is a power of 2 (M = 2^K).
   -- More efficient as it uses standard binary for the remainder.
   -- =========================================================================
   function Encode_Rice (N : Natural; K : Natural) return String;
   
   function Decode_Rice (Bits : String; K : Natural; Consumed : out Natural) return Natural;
   
   function Decode_Rice_Exact (Bits : String; K : Natural) return Natural;


   -- =========================================================================
   -- 3. Signed Golomb Coding (Variant)
   -- Handles negative numbers by mapping them to non-negative integers 
   -- using Zig-Zag encoding before Golomb encoding.
   -- =========================================================================
   function Encode_Signed_Golomb (N : Integer; M : Positive) return String;
   
   function Decode_Signed_Golomb (Bits : String; M : Positive; Consumed : out Natural) return Integer;
   
   function Decode_Signed_Golomb_Exact (Bits : String; M : Positive) return Integer;

private
   -- Mathematical helper: ceiling of base-2 logarithm
   function Ceiling_Log2 (Value : Positive) return Natural;
   
   -- Helpers for truncated binary encoding/decoding used in standard Golomb
   function Encode_Truncated_Binary (Value : Natural; M : Positive) return String;
   function Decode_Truncated_Binary (Bits : String; M : Positive; Consumed : out Natural) return Natural;
   
   -- Bit manipulation helpers
   function Int_To_Binary_String (Value : Natural; Bits : Natural) return String;
   function Binary_String_To_Int (Bits : String) return Natural;
end Golomb_Coding;
