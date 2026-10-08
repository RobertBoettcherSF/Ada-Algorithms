package LZJB is
   -- Define a custom 8-bit unsigned type for byte manipulation
   type Byte is mod 256;
   
   -- Define a dynamically sized array for byte buffers
   type Byte_Array is array (Positive range <>) of Byte;

   -- Exception raised upon invalid stream states or constraint violations
   LZJB_Error : exception;

   -- =========================================================================
   -- LZJB Variants (Compression and Decompression operations)
   -- =========================================================================

   -- Compress: Encodes a byte array using LZJB sliding-window matching
   function Compress (Input : Byte_Array) return Byte_Array;

   -- Decompress: Restores original data. Requires Expected_Size to allocate
   -- the precise output buffer and prevent stream overflow attacks.
   function Decompress (Input : Byte_Array; Expected_Size : Natural) return Byte_Array;

end LZJB;
