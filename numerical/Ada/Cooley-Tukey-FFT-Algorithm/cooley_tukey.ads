with Ada.Numerics.Complex_Types;
use Ada.Numerics.Complex_Types;

-- Package specification for the Cooley-Tukey Fast Fourier Transform (FFT).
-- Provides both Recursive and Iterative (Bit-Reversal) variants for Radix-2 DIT.
package Cooley_Tukey is

   -- Unconstrained array of Complex numbers used as the main data structure.
   -- Can be indexed by any valid Integer range.
   type Complex_Array is array (Integer range <>) of Complex;

   -- Exception raised when the input array size is not a power of 2.
   -- Cooley-Tukey Radix-2 algorithm strictly requires power-of-2 dimensions.
   Invalid_Size_Error : exception;

   -- Validates if a given Integer is a power of 2 (e.g., 2, 4, 8, 16...).
   function Is_Power_Of_Two (N : Integer) return Boolean;

   -- Bit-Reversal Permutation
   -- Rearranges the elements of the array such that the item at index 'i'
   -- is swapped with the item at the bit-reversed index of 'i'.
   -- This is the crucial pre-processing step for the Iterative FFT.
   procedure Bit_Reverse (Data : in out Complex_Array);

   -- Radix-2 Decimation-in-Time (DIT) FFT - Iterative Variant.
   -- Highly optimized approach using bit-reversal and in-place butterfly operations.
   -- Avoids the overhead of recursive function calls.
   procedure FFT_Iterative (Data : in out Complex_Array);

   -- Radix-2 Decimation-in-Time (DIT) FFT - Recursive Variant.
   -- The classic divide-and-conquer implementation splitting into Even/Odd indices.
   procedure FFT_Recursive (Data : in out Complex_Array);

   -- Inverse Fast Fourier Transform (IFFT).
   -- Uses the mathematical property that IFFT(x) = conj(FFT(conj(x))) / N.
   -- Defaults to using the Iterative FFT variant internally for performance.
   procedure IFFT (Data : in out Complex_Array);

end Cooley_Tukey;
