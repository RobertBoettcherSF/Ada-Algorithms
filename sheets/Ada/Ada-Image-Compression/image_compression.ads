-- image_compression.ads
-- Package specification for Image Compression algorithms.
-- Implements variants of lossless (RLE, Delta) and lossy (Quantization) compression.

package Image_Compression is

   -- =========================================================================
   -- Base Types & Data Structures
   -- =========================================================================
   
   -- 8-bit color representation (0 to 255)
   type Color_Value is mod 256; 
   
   -- Standard RGB Pixel
   type Pixel is record
      R, G, B : Color_Value;
   end record;
   
   -- A 1D Image representation (can represent a flattened 2D image)
   type Image_1D is array (Positive range <>) of Pixel;

   -- Exceptions for error handling
   Empty_Image_Error : exception;
   Invalid_Data_Error : exception;

   -- =========================================================================
   -- Variant 1: Run-Length Encoding (RLE) - Lossless Compression
   -- Efficient for images with large contiguous areas of the same color.
   -- =========================================================================
   
   type RLE_Pair is record
      Count : Positive;
      Val   : Pixel;
   end record;
   
   type RLE_Sequence is array (Positive range <>) of RLE_Pair;

   -- Compresses a 1D Image into an RLE sequence.
   function Compress_RLE (Img : Image_1D) return RLE_Sequence;
   
   -- Decompresses an RLE sequence back into a 1D Image.
   function Decompress_RLE (Seq : RLE_Sequence) return Image_1D;

   -- =========================================================================
   -- Variant 2: Delta Encoding - Lossless Differential Compression
   -- Stores the difference between adjacent pixels. Excellent for gradients.
   -- =========================================================================
   
   -- Differences between 8-bit values range from -255 to 255.
   type Color_Diff is range -255 .. 255; 
   
   type Delta_Pixel is record
      dR, dG, dB : Color_Diff;
   end record;
   
   type Delta_Sequence is array (Positive range <>) of Delta_Pixel;

   -- Compresses an image into a series of pixel differences.
   -- Note: Requires keeping track of the First Pixel separately to decompress.
   function Compress_Delta (Img : Image_1D) return Delta_Sequence;
   
   -- Decompresses a delta sequence given the foundational starting pixel.
   function Decompress_Delta (Seq : Delta_Sequence; First_Pixel : Pixel) return Image_1D;

   -- =========================================================================
   -- Variant 3: Color Quantization - Lossy Compression
   -- Reduces the color space by dropping the least significant bits.
   -- =========================================================================
   
   -- Applies quantization in-place. Levels_To_Drop (0-8) determines bits lost.
   procedure Quantize_Colors (Img : in out Image_1D; Levels_To_Drop : Natural);

end Image_Compression;
