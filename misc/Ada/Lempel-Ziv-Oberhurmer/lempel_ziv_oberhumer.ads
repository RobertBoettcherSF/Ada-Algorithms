-- ============================================================================
-- Package Specification: Lempel_Ziv_Oberhumer (LZO)
-- Description: Lossless data compression library focused on rapid decompression.
--              Implements LZO1, LZO1X, LZO1Y, LZO1Z, and LZO-RLE variants.
-- ============================================================================

package Lempel_Ziv_Oberhumer is

   -- Basic byte representation
   type Byte is mod 256;
   type Byte_Array is array (Natural range <>) of Byte;

   -- Supported LZO Algorithm Variants
   type LZO_Variant is (
      LZO1,     -- Basic byte-oriented LZO variant with 12-bit lookback offset
      LZO1X,    -- Standard variant (Linux kernel/zram default) with 16-bit offset
      LZO1Y,    -- High-ratio variant optimized for larger match block sizes
      LZO1Z,    -- Variant utilizing stateful offset recycling and transposed bits
      LZO_RLE   -- Run-Length Encoding enhanced LZO variant for redundant memory pages
   );

   -- Exceptions for Robust Error Handling
   Corrupt_Input_Error  : exception;
   Buffer_Overrun_Error : exception;
   Invalid_Data_Error   : exception;

   -- Calculates the worst-case compressed buffer size requirement
   function Max_Compressed_Size (Input_Length : Natural) return Natural;

   -- Unified Compression / Decompression Interface
   procedure Compress (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural;
      Variant    : in  LZO_Variant := LZO1X
   );

   procedure Decompress (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural;
      Variant    : in  LZO_Variant := LZO1X
   );

   -- Modular Variant-Specific Compression Procedures
   procedure Compress_LZO1 (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   );
   procedure Decompress_LZO1 (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   );

   procedure Compress_LZO1X (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   );
   procedure Decompress_LZO1X (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   );

   procedure Compress_LZO1Y (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   );
   procedure Decompress_LZO1Y (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   );

   procedure Compress_LZO1Z (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   );
   procedure Decompress_LZO1Z (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   );

   procedure Compress_LZO_RLE (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   );
   procedure Decompress_LZO_RLE (
      Input      : in  Byte_Array;
      Output     : out Byte_Array;
      Output_Len : out Natural
   );

   -- Validation and Analytics Helper Functions
   function Calculate_Compression_Ratio (Uncompressed_Size, Compressed_Size : Natural) return Float;
   function Verify_Equality (Buf1, Buf2 : Byte_Array) return Boolean;

end Lempel_Ziv_Oberhumer;
