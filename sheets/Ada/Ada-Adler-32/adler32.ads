-- adler32.ads
-- Specification for the Adler-32 checksum algorithm
with Interfaces;

package Adler32 is
   -- Use strong typing to prevent accidental mixing of data types
   type Byte is new Interfaces.Unsigned_8;
   type Byte_Array is array (Positive range <>) of Byte;
   type Checksum is new Interfaces.Unsigned_32;

   -- Modulo constant for Adler-32 (largest prime less than 65536)
   Base : constant Interfaces.Unsigned_32 := 65521;

   -- Variant 1: Basic Preemptive/Standard Modulo
   -- Calculates the Adler-32 checksum by applying the modulo operation
   -- at every single byte iteration. Safe but computationally expensive.
   function Calculate_Basic (Data : Byte_Array) return Checksum;

   -- Variant 2: Optimized / Deferred Modulo
   -- Optimization mentioned in the article: Since 5552 bytes can be summed 
   -- without 32-bit overflow, we defer the modulo operation to the end 
   -- of 5552-byte blocks. This significantly improves performance.
   function Calculate_Optimized (Data : Byte_Array) return Checksum;

   -- Helper Function: Convert standard Ada String to algorithm-specific Byte_Array
   function To_Byte_Array (Str : String) return Byte_Array;

end Adler32;
