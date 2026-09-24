package LZSS is
   pragma Pure;

   -- We define a strong type for bytes to handle raw data safely.
   type Byte is mod 2**8;
   type Byte_Array is array (Positive range <>) of Byte;

   -- Algorithmic configuration constants for LZSS sliding window mechanism.
   -- Standard typical LZSS values are 4096 window size and 18 lookahead.
   Window_Size    : constant := 4096;
   Lookahead_Size : constant := 18;
   Min_Match      : constant := 3;

   -- =========================================================================
   -- VARIANT 1: Logical Tokens Algorithm
   -- =========================================================================
   -- This variant demonstrates the raw algorithm logic by emitting parsed tokens
   -- without binary bit-packing, allowing verification of the window behavior.

   type Token_Kind is (Literal, Reference);
   
   type Token (Kind : Token_Kind := Literal) is record
      case Kind is
         when Literal =>
            Value : Byte;
         when Reference =>
            Distance : Positive; -- How far back in the window (1 .. Window_Size)
            Length   : Positive; -- Length of the match (Min_Match .. Lookahead_Size)
      end case;
   end record;
   
   type Token_Array is array (Positive range <>) of Token;

   -- Compresses bytes into an array of Token variant records.
   procedure Compress_Logical (Input  : in  Byte_Array;
                               Output : out Token_Array;
                               Count  : out Natural);

   -- Decompresses Token variant records back into raw bytes.
   procedure Decompress_Logical (Input  : in  Token_Array;
                                 Output : out Byte_Array;
                                 Count  : out Natural);

   -- =========================================================================
   -- VARIANT 2: Binary Packed Algorithm (Practical implementation)
   -- =========================================================================
   -- Standard LZSS: Pack data sequentially into bits.
   -- Literal Token: '1' flag + 8-bit literal byte.
   -- Reference Token: '0' flag + 12-bit distance + 4-bit length.

   function Compress (Input : Byte_Array) return Byte_Array;
   function Decompress (Input : Byte_Array; Original_Size : Natural) return Byte_Array;

   -- Raised when decompressing malformed data or using insufficient buffers.
   Compression_Error : exception;

end LZSS;
