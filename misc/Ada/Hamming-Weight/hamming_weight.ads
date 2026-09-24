-- hamming_weight.ads
-- Specification for the Hamming Weight (Population Count) algorithms.
package Hamming_Weight is

   -- Custom modular type to ensure 32-bit width and safe bitwise operations.
   -- Modular types in Ada naturally support logical operators (and, or, xor).
   type Word_32 is mod 2**32;
   
   -- Custom type to represent the number of set bits (0 to 32).
   type Bit_Count is range 0 .. 32;

   -- ========================================================================
   -- Variant 1: Naive (Shift and Count)
   -- Iterates through each bit, masking with 1 and shifting right.
   -- ========================================================================
   function Naive_Count (Value : Word_32) return Bit_Count;

   -- ========================================================================
   -- Variant 2: Brian Kernighan's / Wegner's Algorithm
   -- Clears the lowest set bit in each iteration (Value and (Value - 1)).
   -- Very efficient for words with sparse 1s.
   -- ========================================================================
   function Kernighan_Count (Value : Word_32) return Bit_Count;

   -- ========================================================================
   -- Variant 3: Parallel / Tree-like Reduction (SWAR)
   -- Constant time O(1) algorithm using SIMD Within A Register techniques.
   -- Groups bits into 2s, 4s, 8s, 16s and adds them in parallel.
   -- ========================================================================
   function SWAR_Count (Value : Word_32) return Bit_Count;

   -- ========================================================================
   -- Variant 4: SWAR using Multiplication
   -- Optimization of the SWAR method using a 32-bit modular multiplication
   -- to accumulate the sums of 8-bit blocks in the highest byte.
   -- ========================================================================
   function SWAR_Multiply_Count (Value : Word_32) return Bit_Count;

   -- ========================================================================
   -- Variant 5: Precomputed Lookup Table
   -- Uses a 256-element array to look up the popcount of each 8-bit chunk.
   -- ========================================================================
   function Lookup_Table_Count (Value : Word_32) return Bit_Count;

private
   -- Helper type for an 8-bit chunk
   type Byte is mod 2**8;
   
   -- Array type for the lookup table mapping a Byte to its popcount
   type Lookup_Array is array (Byte) of Bit_Count;

end Hamming_Weight;
