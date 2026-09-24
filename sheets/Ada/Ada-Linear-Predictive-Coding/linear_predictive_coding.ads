-- linear_predictive_coding.ads
-- Linear Predictive Coding (LPC) implementation including Autocorrelation, Covariance, and Burg variants.

package Linear_Predictive_Coding is
   
   type Real is new Float;
   type Signal_Array is array (Positive range <>) of Real;
   type Coefficients_Array is array (Positive range <>) of Real;
   type Matrix_Array is array (Positive range <>, Positive range <>) of Real;

   -- Exceptions
   Invalid_Order : exception;
   Empty_Signal  : exception;
   Math_Error    : exception;

   -- Supported LPC estimation variants
   type LPC_Variant is (Autocorrelation, Covariance, Burg);

   -- Main LPC Analysis procedure
   -- Estimates the current sample as a linear combination of past samples.
   procedure Analyze
     (Signal   : in  Signal_Array;
      Order    : in  Positive;
      Variant  : in  LPC_Variant;
      Coeffs   : out Coefficients_Array;
      Residual : out Signal_Array);

   -- Main LPC Synthesis procedure
   -- Reconstructs the signal using coefficients and the residual.
   function Synthesize
     (Coeffs   : Coefficients_Array;
      Residual : Signal_Array) return Signal_Array;

   -- Helper Functions (Exposed for robust component testing)
   function Compute_Autocorrelation (Signal : Signal_Array; Lags : Natural) return Signal_Array;
   procedure Levinson_Durbin (R : in Signal_Array; Order : in Positive; A : out Coefficients_Array; Error : out Real);
   function Solve_Linear_System (A : Matrix_Array; B : Coefficients_Array) return Coefficients_Array;

end Linear_Predictive_Coding;
