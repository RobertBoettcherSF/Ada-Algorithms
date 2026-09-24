-- video_compression.ads
package Video_Compression is

   -- Custom Exceptions for Robustness & Validation
   Invalid_Input_Error     : exception;
   Quantization_Zero_Error : exception;

   -- Fundamental 8x8 block types (used in MPEG/JPEG standards)
   type Index_8 is range 0 .. 7;
   type Block_8x8 is array (Index_8, Index_8) of Float;
   type Integer_Block_8x8 is array (Index_8, Index_8) of Integer;
   type Quant_Matrix is array (Index_8, Index_8) of Integer;

   -- ==========================================
   -- Variant 1: Spatial Transform (Intra-frame)
   -- ==========================================
   -- Forward and Inverse Discrete Cosine Transforms (DCT)
   function Forward_DCT (Input : Block_8x8) return Block_8x8;
   function Inverse_DCT (Input : Block_8x8) return Block_8x8;

   -- ==========================================
   -- Variant 2: Quantization (Compression Level)
   -- ==========================================
   -- Reduces precision of frequency coefficients to save space
   function Quantize (Input : Block_8x8; Q : Quant_Matrix) return Integer_Block_8x8;
   function Dequantize (Input : Integer_Block_8x8; Q : Quant_Matrix) return Block_8x8;

   -- ==========================================
   -- Variant 3: Color Space / Chroma Subsampling
   -- ==========================================
   type Image_Plane is array (Natural range <>, Natural range <>) of Integer;
   type Chroma_Format is (YUV_444, YUV_422, YUV_420);

   -- Downsamples chroma planes based on the target format
   function Subsample (Plane : Image_Plane; Format : Chroma_Format) return Image_Plane;

   -- ==========================================
   -- Variant 4: Entropy Coding
   -- ==========================================
   type RLE_Element is record
      Value : Integer;
      Count : Positive;
   end record;
   type RLE_Array is array (Positive range <>) of RLE_Element;

   -- Run-Length Encoding compresses long runs of identical values (often zeros post-quantization)
   function RLE_Encode (Input : Integer_Block_8x8) return RLE_Array;

end Video_Compression;
