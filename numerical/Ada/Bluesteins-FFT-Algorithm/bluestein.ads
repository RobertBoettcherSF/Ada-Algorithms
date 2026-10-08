-- bluestein.ads
with Ada.Numerics.Complex_Types;
use Ada.Numerics.Complex_Types;

package Bluestein is

   -- Strong typing: custom array type for sequence operations
   type Complex_Array is array (Integer range <>) of Complex;

   -- Exception raised when invalid parameters or empty sequences are passed
   Invalid_Size : exception;

   -- Variant 1: Forward Discrete Fourier Transform using Bluestein's algorithm
   -- Handles arbitrary length arrays in O(N log N) time
   function Forward_FFT (Input : Complex_Array) return Complex_Array;

   -- Variant 2: Inverse Discrete Fourier Transform using Bluestein's algorithm
   -- Reconstructs the original sequence from its frequency domain representation
   function Inverse_FFT (Input : Complex_Array) return Complex_Array;

   -- Variant 3: General Chirp-Z Transform (CZT)
   -- Computes X_k = sum_{n=0}^{N-1} Input(n) * A^(-n) * W^(n*k)
   -- Evaluates the Z-transform along a spiral contour defined by A and W.
   function Chirp_Z_Transform (Input : Complex_Array;
                               A     : Complex;
                               W     : Complex;
                               M_Out : Positive) return Complex_Array;

   -- Helper Function: Standard Radix-2 Cooley-Tukey FFT 
   -- Requires Input length to be a power of 2. Exposed for testing/reuse.
   function Radix2_FFT (Input : Complex_Array; Inverse : Boolean := False) return Complex_Array;

end Bluestein;
