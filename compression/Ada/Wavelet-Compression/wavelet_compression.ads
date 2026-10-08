-- wavelet_compression.ads
-- Specification for the Wavelet Compression algorithms (Lossy and Lossless)

package Wavelet_Compression is

   -- Custom Types for 1D and 2D Signals
   type Signal_1D is array (Positive range <>) of Float;
   --  Wider than Integer. A detail is a difference, about twice a sample,
   --  and each further level can double that again. 2**31 is not an Integer.
   --  Arithmetic is done in Detail: Detail (B) - Detail (A), never
   --  Detail (B - A), which overflows in Integer first. The average of
   --  two Integer samples fits back in Integer.
   type Detail is new Long_Integer;
   type Signal_1D_Int is array (Positive range <>) of Detail;
   type Sample_1D is array (Positive range <>) of Integer;
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
   
   --  One level of the lifting S-transform. The step is
   --  d = y - x, s = x + floor(d/2), and never forms x+y.
   function Forward_Haar_1D_Lossless (Input : Signal_1D_Int) return Signal_1D_Int;

   --  Inverse: x = s - floor(d/2), y = x + d.
   function Inverse_Haar_1D_Lossless (Input : Signal_1D_Int) return Signal_1D_Int;

   --  Levels of the same step on the low-pass prefix. Levels = 0 copies
   --  the signal. The length must be divisible by 2**Levels; otherwise
   --  Invalid_Dimensions (the exception is the contract, no Pre).
   function Forward_Haar_Levels
     (Input : Signal_1D_Int; Levels : Natural) return Signal_1D_Int;

   function Inverse_Haar_Levels
     (Input : Signal_1D_Int; Levels : Natural) return Signal_1D_Int;

   --  One level on Integer samples. The average is converted back to
   --  Integer; the detail stays a Detail.
   function Forward_Haar_Samples (Input : Sample_1D) return Signal_1D_Int;
   function Inverse_Haar_Samples (Input : Signal_1D_Int) return Sample_1D;

end Wavelet_Compression;
