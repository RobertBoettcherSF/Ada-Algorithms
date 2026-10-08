package Warped_LPC is
   
   -- Define a high-precision real number type for signal processing
   type Real is new Long_Float;
   
   -- Unconstrained arrays for flexible signal lengths and orders
   type Real_Array is array (Natural range <>) of Real;

   -- Exceptions for edge-case and contract violations
   Invalid_Order : exception;
   Invalid_Input : exception;

   -- Variant 1: Standard LPC Autocorrelation Analysis (Using unit delays)
   -- Predicts the standard spectral envelope representation
   procedure Standard_Autocorrelation (
      Input      : in  Real_Array;
      Order      : in  Positive;
      Auto_Corrs : out Real_Array);

   -- Variant 2: Warped LPC Autocorrelation Analysis (Using all-pass filters)
   -- Modifies the spectral representation using a Bark-scale approximated warped frequency 
   procedure Warped_Autocorrelation (
      Input      : in  Real_Array;
      Order      : in  Positive;
      Lambda     : in  Real;
      Auto_Corrs : out Real_Array);

   -- Resolves Autocorrelations to Predictor Coefficients using Levinson-Durbin Recursion
   -- Extracted as a modular step to handle both Standard and Warped Autocorrelations
   procedure Levinson_Durbin (
      Auto_Corrs : in  Real_Array;
      Order      : in  Positive;
      Coeffs     : out Real_Array;
      Error_Var  : out Real);

end Warped_LPC;
