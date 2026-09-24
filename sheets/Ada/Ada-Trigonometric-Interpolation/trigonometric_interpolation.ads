-- trigonometric_interpolation.ads
with Ada.Numerics.Long_Elementary_Functions;

package Trigonometric_Interpolation is

   -- Using Long_Float for higher precision calculations
   type Real_Array is array (Natural range <>) of Long_Float;

   -- Record holding the trigonometric polynomial coefficients.
   -- K represents the maximum degree of the polynomial terms.
   -- The Is_Even_N flag is used to correctly evaluate the final A(K) term for even N.
   type Interpolation_Coefficients (K : Natural) is record
      A         : Real_Array (0 .. K);
      B         : Real_Array (1 .. K);
      Is_Even_N : Boolean;
   end record;

   -- Raised when input array is empty
   Invalid_Data_Error : exception;

   -- Calculates the trigonometric polynomial coefficients for a given 
   -- evenly spaced set of points Y over the interval [0, 2*Pi).
   -- Handles both Even (N = 2K) and Odd (N = 2K + 1) variants.
   function Calculate_Coefficients (Y : Real_Array) return Interpolation_Coefficients;

   -- Evaluates the trigonometric polynomial at a continuous point X.
   function Evaluate (Coeffs : Interpolation_Coefficients; X : Long_Float) return Long_Float;

end Trigonometric_Interpolation;
