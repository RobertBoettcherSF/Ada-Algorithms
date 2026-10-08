with Ada.Numerics.Complex_Types; use Ada.Numerics.Complex_Types;

package FFT is
   -- Unconstrained array for handling dynamic sizes of complex numbers
   type Complex_Array is array (Integer range <>) of Complex;
   
   -- Exception raised when algorithm assumptions (e.g. Radix-2 lengths) fail
   FFT_Error : exception;

   -- Variant 1: Cooley-Tukey Radix-2 Decimation-in-Time (Recursive)
   function FFT_Recursive_DIT (Input : Complex_Array) return Complex_Array;

   -- Variant 2: Cooley-Tukey Radix-2 Decimation-in-Frequency (Recursive)
   function FFT_Recursive_DIF (Input : Complex_Array) return Complex_Array;

   -- Variant 3: Cooley-Tukey Radix-2 (Iterative with Bit-Reversal)
   function FFT_Iterative (Input : Complex_Array) return Complex_Array;

   -- Variant 4: Inverse Fast Fourier Transform (using DIT)
   function IFFT (Input : Complex_Array) return Complex_Array;

   -- Helper functions for validation and padding logic
   function Is_Power_Of_2 (N : Natural) return Boolean;
   function Next_Power_Of_2 (N : Natural) return Natural;
end FFT;
