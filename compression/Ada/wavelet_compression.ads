-- wavelet_compression.ads
-- Specification for the Wavelet Compression algorithms (Lossy and Lossless)

package Wavelet_Compression is

   -- Custom Types for 1D and 2D Signals
   type Signal_1D is array (Positive range <>) of Float;
   type Signal_1D_Int is array (Positive range <>) of Integer;
   type Signal_2D is array (Positive range <>, Positive range <>) of Float;

   -- Exceptions
   Invalid_Dimensions : exception;

   -- =========================================================
   -- Variant 1: Lossy Compression (Floating Point)
   -- Uses standard Haar averaging and differencing.
   -- =========================================================
   
   -- Computes a single-level 1D Haar Wavelet Transform
   function Forward_Haar_1D (Input : Signal_1D) return Signal_1D;
   
   -- Reconstructs the original 1D signal from the transformed signal
   function Inverse_Haar_1D (Input : Signal_1D) return Signal_1D;

   -- Computes a single-level 2D Haar Wavelet Transform (rows then columns)
   function Forward_Haar_2D (Input : Signal_2D) return Signal_2D;
   
   -- Reconstructs the 2D signal (columns then rows)
   function Inverse_Haar_2D (Input : Signal_2D) return Signal_2D;

   -- Quantization step for compression: Sets coefficients below Threshold to 0.0
   function Quantize (Input : Signal_1D; Threshold : Float) return Signal_1D;

   -- =========================================================
   -- Variant 2: Lossless Compression (Integer Lifting Scheme)
   -- Exact reconstruction with integer arithmetic (S-transform).
   -- =========================================================
   
   -- Computes a single-level 1D integer wavelet transform
   function Forward_Haar_1D_Lossless (Input : Signal_1D_Int) return Signal_1D_Int;
   
   -- Reconstructs the original 1D integer signal perfectly
   function Inverse_Haar_1D_Lossless (Input : Signal_1D_Int) return Signal_1D_Int;

end Wavelet_Compression;
