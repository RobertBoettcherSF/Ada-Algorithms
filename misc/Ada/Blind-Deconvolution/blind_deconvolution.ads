--------------------------------------------------------------------------------
-- Package: Blind_Deconvolution
-- Description: Implementation of Blind Deconvolution algorithms for 1D signals
--              as described in the Wikipedia article. Includes iterative and 
--              non-iterative variants.
--------------------------------------------------------------------------------
package Blind_Deconvolution is

   -- Strong typing for numerical stability
   type Real is new Long_Float;
   type Signal_Array is array (Integer range <>) of Real;

   -- Exceptions for error handling
   Invalid_Input      : exception;
   Dimension_Mismatch : exception;
   Convergence_Error  : exception;

   -----------------------------------------------------------------------------
   -- Iterative Algorithms
   -----------------------------------------------------------------------------

   -- Variant 1: Maximum Likelihood (Richardson-Lucy Blind Deconvolution)
   -- Widely used in optical astronomy and image restoration. Iteratively updates
   -- both the signal estimate and the Point Spread Function (PSF).
   procedure Richardson_Lucy_Blind (
      Observed   : in Signal_Array;
      Iterations : in Positive;
      Signal     : in out Signal_Array;
      PSF        : in out Signal_Array
   );

   -- Variant 2: Alternating Minimization (Gradient Descent Proxy)
   -- Alternates between optimizing the Signal and the PSF, commonly used in
   -- generalized blind deconvolution (e.g., Ayers-Dainty inspired 1D proxy).
   procedure Alternating_Minimization_Blind (
      Observed   : in Signal_Array;
      Iterations : in Positive;
      Signal     : in out Signal_Array;
      PSF        : in out Signal_Array;
      Alpha      : in Real := 0.01 -- Learning rate
   );

   -----------------------------------------------------------------------------
   -- Non-Iterative Algorithms
   -----------------------------------------------------------------------------

   -- Variant 3: Regularized Linear Inverse (Wiener Filter Proxy)
   -- Represents non-iterative approaches used in seismic data / audio processing.
   -- Uses a known or assumed PSF constraint and a Signal-to-Noise Ratio (SNR) parameter.
   function Wiener_Proxy_Deconvolution (
      Observed : in Signal_Array;
      PSF      : in Signal_Array;
      SNR      : in Real
   ) return Signal_Array;

   -----------------------------------------------------------------------------
   -- Helper Functions (Exposed for Testing and V&V)
   -----------------------------------------------------------------------------
   function Convolve (X, H : Signal_Array) return Signal_Array;
   procedure Normalize (S : in out Signal_Array);
   function Reverse_Array (S : Signal_Array) return Signal_Array;

end Blind_Deconvolution;
