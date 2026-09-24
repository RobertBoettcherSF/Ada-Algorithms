with Ada.Numerics.Elementary_Functions;

package Transform_Coding is

   -- Strong typing for algorithm-specific data
   type Data_Array is array (Integer range <>) of Float;
   type Quantized_Array is array (Integer range <>) of Integer;

   -- Exception for invalid algorithm parameters (e.g., negative quantization steps)
   Invalid_Argument : exception;

   -- =========================================================================
   -- Variant 1: Discrete Cosine Transform (DCT-II)
   -- Widely used in audio/image compression (e.g., JPEG, MP3).
   -- Concentrates signal energy in the lower frequencies.
   -- =========================================================================
   function DCT (Input : Data_Array) return Data_Array;
   function Inverse_DCT (Input : Data_Array) return Data_Array;

   -- =========================================================================
   -- Variant 2: Discrete Wavelet Transform (Haar Wavelet)
   -- Used in modern transform coding (e.g., JPEG 2000).
   -- Provides both frequency and spatial domain localization.
   -- Requires an even-length array.
   -- =========================================================================
   function Haar_Transform (Input : Data_Array) return Data_Array;
   function Inverse_Haar_Transform (Input : Data_Array) return Data_Array;

   -- =========================================================================
   -- Quantization (The lossy step of Transform Coding)
   -- Reduces precision of transform coefficients to compress data.
   -- =========================================================================
   function Quantize (Input : Data_Array; Step_Size : Float) return Quantized_Array;
   function Dequantize (Input : Quantized_Array; Step_Size : Float) return Data_Array;

end Transform_Coding;
