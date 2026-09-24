with Interfaces; use Interfaces;

package Delta_Encoding is
   --  Custom types for strong typing
   type Integer_Array is array (Positive range <>) of Integer;
   type Byte_Array is array (Positive range <>) of Unsigned_8;

   --  Exception for handling edge cases
   Empty_Input_Error : exception;

   --  Variant 1: Arithmetic Delta Encoding (Simple Differencing)
   --  Calculates the difference between sequential data points.
   function Encode_Integer_Delta (Input : Integer_Array) return Integer_Array;
   
   --  Reconstructs original integer data from deltas.
   function Decode_Integer_Delta (Input : Integer_Array) return Integer_Array;

   --  Variant 2: Logical XOR Delta Encoding
   --  Uses bitwise XOR instead of subtraction (common in networking/hardware).
   function Encode_Byte_XOR_Delta (Input : Byte_Array) return Byte_Array;
   
   --  Reconstructs original byte data from XOR deltas.
   function Decode_Byte_XOR_Delta (Input : Byte_Array) return Byte_Array;

end Delta_Encoding;
