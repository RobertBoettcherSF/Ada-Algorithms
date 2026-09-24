with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package Elias_Gamma_Coding is
   
   -- Strong type for Elias bit streams to ensure validity and prevent 
   -- arbitrary strings from being mistakenly processed as coded streams.
   type Elias_Bit_Stream is private;
   
   -- Exceptions
   Invalid_Bit_Stream : exception;
   Overflow_Error     : exception;
   
   -- =========================================================================
   -- Variant 1: Standard Elias Gamma Coding
   -- Target: Strictly Positive Integers (x >= 1)
   -- =========================================================================
   function Encode_Positive (Value : Positive) return Elias_Bit_Stream;
   function Decode_Positive (Stream : Elias_Bit_Stream) return Positive;
   
   -- =========================================================================
   -- Variant 2: Zero-extended Elias Gamma Coding
   -- Target: Non-Negative Integers (x >= 0)
   -- Method: Adds 1 before encoding, subtracts 1 after decoding.
   -- =========================================================================
   function Encode_Non_Negative (Value : Natural) return Elias_Bit_Stream;
   function Decode_Non_Negative (Stream : Elias_Bit_Stream) return Natural;
   
   -- =========================================================================
   -- Variant 3: Integer Elias Gamma Coding
   -- Target: All Integers (Negative, Zero, Positive)
   -- Method: Uses a standard bijection: 0->1, x>0 -> 2x, x<0 -> -2x+1
   -- =========================================================================
   function Encode_Integer (Value : Integer) return Elias_Bit_Stream;
   function Decode_Integer (Stream : Elias_Bit_Stream) return Integer;
   
   -- =========================================================================
   -- Helper routines for constructing and inspecting bit streams
   -- =========================================================================
   function To_Stream (S : String) return Elias_Bit_Stream;
   function To_String (Stream : Elias_Bit_Stream) return String;
   
private
   type Elias_Bit_Stream is record
      Data : Unbounded_String;
   end record;
   
end Elias_Gamma_Coding;
