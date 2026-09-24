-- discrete_fourier_transform.ads
-- Specification for the Discrete Fourier Transform algorithm and its variants.
with Ada.Numerics.Complex_Types;

package Discrete_Fourier_Transformation is
   use Ada.Numerics.Complex_Types;

   -- Custom types for strong typing and algorithm-specific data
   type Complex_Array is array (Integer range <>) of Complex;
   type Real_Array is array (Integer range <>) of Float;
   type Complex_Matrix is array (Integer range <>, Integer range <>) of Complex;

   -- Exception for edge cases
   Empty_Array_Error : exception;

   -- Variant 1: Standard Forward 1D DFT
   -- Converts a time-domain complex signal into the frequency domain.
   function Forward_DFT (Input : Complex_Array) return Complex_Array;

   -- Variant 2: Standard Inverse 1D DFT (IDFT)
   -- Converts a frequency-domain complex signal back into the time domain.
   function Inverse_DFT (Input : Complex_Array) return Complex_Array;

   -- Variant 3: Unitary Forward 1D DFT
   -- Normalized variant preserving the Euclidean norm (energy) using 1/sqrt(N).
   function Unitary_Forward_DFT (Input : Complex_Array) return Complex_Array;

   -- Variant 4: Unitary Inverse 1D DFT
   -- Normalized inverse variant using 1/sqrt(N).
   function Unitary_Inverse_DFT (Input : Complex_Array) return Complex_Array;

   -- Variant 5: Real-Valued Forward 1D DFT
   -- Optimized variant conceptually for real-valued inputs (produces conjugate-symmetric output).
   function Real_Forward_DFT (Input : Real_Array) return Complex_Array;

   -- Variant 6: Multidimensional (2D) Forward DFT
   -- Commonly used in image processing and spatial frequencies.
   function Forward_2D_DFT (Input : Complex_Matrix) return Complex_Matrix;

end Discrete_Fourier_Transformation;
