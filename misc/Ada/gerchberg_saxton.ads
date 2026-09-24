with Ada.Numerics.Generic_Complex_Types;
with Ada.Numerics.Generic_Complex_Elementary_Functions;

package Gerchberg_Saxton is

   -- Strong typing for algorithm-specific data
   type Real is new Long_Float;
   
   package Complex_Types is new Ada.Numerics.Generic_Complex_Types (Real);
   use Complex_Types;
   
   package Complex_Math is new Ada.Numerics.Generic_Complex_Elementary_Functions (Complex_Types);
   
   type Real_Array is array (Positive range <>) of Real;
   type Complex_Array is array (Positive range <>) of Complex;

   -- Exceptions for edge cases
   Invalid_Input_Error      : exception;
   Dimension_Mismatch_Error : exception;

   -- Discrete Fourier Transform utility functions
   function DFT (Input : Complex_Array) return Complex_Array;
   function IDFT (Input : Complex_Array) return Complex_Array;

   -- Variant 1: Standard Gerchberg-Saxton (Error Reduction Algorithm)
   -- Retrieves phase by iteratively bouncing between spatial and frequency domains,
   -- replacing amplitudes with the known Source and Target amplitudes.
   function Standard_GS (Source_Amp, Target_Amp : Real_Array;
                         Max_Iter               : Natural) return Real_Array;

   -- Variant 2: Hybrid Input-Output (HIO) Variant
   -- A popular variant (often credited to Fienup) that uses a relaxation parameter (Beta)
   -- to avoid stagnation in local minima during phase retrieval.
   function Hybrid_Input_Output_GS (Source_Amp, Target_Amp : Real_Array;
                                    Max_Iter               : Natural;
                                    Beta                   : Real) return Real_Array;

end Gerchberg_Saxton;
