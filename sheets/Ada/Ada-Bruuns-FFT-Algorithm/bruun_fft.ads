with Ada.Numerics.Generic_Complex_Types;

package Bruun_FFT is
   -- Define a high-precision real number type for signal processing
   type Real is new Long_Float;
   
   -- Instantiate complex types and functions over our Real type
   package Complex_Types is new Ada.Numerics.Generic_Complex_Types (Real);
   use Complex_Types;
   
   -- Arrays for signal representations
   type Real_Array is array (Natural range <>) of Real;
   type Complex_Array is array (Natural range <>) of Complex;
   
   -- Variant 1: Bruun's FFT for Real Data (Power of Two sizes)
   -- Proposed by G. Bruun in 1978. Reduces multiplications by recursively 
   -- evaluating polynomials with purely real coefficients (z^M - a*z^(M/2) + 1).
   procedure FFT_Power_Of_Two_Real (Input  : in     Real_Array;
                                    Output :    out Complex_Array);
                                    
   -- Variant 2: Bruun's FFT for Complex Data (Power of Two sizes)
   -- Generalizes the Bruun polynomial tree for standard complex arrays.
   procedure FFT_Power_Of_Two_Complex (Input  : in     Complex_Array;
                                       Output :    out Complex_Array);
                                       
   -- Variant 3: Bruun's FFT for Arbitrary Even Composite Sizes
   -- As generalized by H. Murakami in 1996 to handle non-power-of-two composite lengths.
   procedure FFT_Arbitrary_Composite (Input  : in     Complex_Array;
                                      Output :    out Complex_Array);

   -- Exception raised when sizing rules are violated
   Invalid_Size_Error : exception;
end Bruun_FFT;
