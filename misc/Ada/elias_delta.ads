-- elias_delta.ads
package Elias_Delta is

   type Bit is (Zero, One);
   type Bit_Vector is array (Positive range <>) of Bit;

   -- Exceptions for error handling
   Invalid_Input : exception;
   Invalid_Code  : exception;

   -- Core Elias Delta Coding for strictly positive integers (X >= 1)
   function Encode (X : Positive) return String;
   function Decode (S : String) return Positive;

   -- Strongly-typed Bit_Vector interface
   function Encode_Bits (X : Positive) return Bit_Vector;
   function Decode_Bits (Bits : Bit_Vector) return Positive;

   -- Variant 1: Non-negative integers (X >= 0) using +1 offset mapping
   function Encode_Non_Negative (X : Natural) return String;
   function Decode_Non_Negative (S : String) return Natural;

   -- Variant 2: All signed integers (positive, zero, negative) using ZigZag mapping
   function Encode_Integer (X : Integer) return String;
   function Decode_Integer (S : String) return Integer;

   -- Modular helper functions exposed for testing and advanced use
   function Integer_To_Binary (N : Positive) return String;
   function Binary_To_Integer (S : String) return Positive;
   function Gamma_Encode (N : Positive) return String;
   function Gamma_Decode (S : String; Last_Index : out Positive) return Positive;
   function ZigZag_Encode (X : Integer) return Positive;
   function ZigZag_Decode (P : Positive) return Integer;

end Elias_Delta;
