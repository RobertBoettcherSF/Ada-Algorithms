package Fletchers_Checksum is
   pragma Pure;

   -- Custom modular types to handle exact bit-widths
   type Byte   is mod 2**8;
   type Word16 is mod 2**16;
   type Word32 is mod 2**32;
   type Word64 is mod 2**64;

   -- Array types for data processing
   type Byte_Array   is array (Positive range <>) of Byte;
   type Word16_Array is array (Positive range <>) of Word16;
   type Word32_Array is array (Positive range <>) of Word32;

   -- =========================================================
   -- Fletcher-16 (Operates on 8-bit blocks, modulo 255)
   -- =========================================================
   
   -- Computes the standard Fletcher-16 checksum
   function Fletcher_16_Naive (Data : Byte_Array) return Word16;
   
   -- Computes the Fletcher-16 checksum grouping additions to avoid 
   -- expensive modulo operations at each step. 
   function Fletcher_16_Optimized (Data : Byte_Array) return Word16;

   -- =========================================================
   -- Fletcher-32 (Operates on 16-bit blocks, modulo 65535)
   -- =========================================================
   function Fletcher_32 (Data : Word16_Array) return Word32;

   -- =========================================================
   -- Fletcher-64 (Operates on 32-bit blocks, modulo 4294967295)
   -- =========================================================
   function Fletcher_64 (Data : Word32_Array) return Word64;

   -- =========================================================
   -- Helper / Utility Functions
   -- =========================================================
   
   type Check_Bytes_16 is record
      CB0 : Byte;
      CB1 : Byte;
   end record;
   
   -- Calculates the two check bytes that, when appended to the original
   -- data, will result in a Fletcher-16 checksum of 0.
   function Generate_Check_Bytes_16 (Data : Byte_Array) return Check_Bytes_16;

end Fletchers_Checksum;
