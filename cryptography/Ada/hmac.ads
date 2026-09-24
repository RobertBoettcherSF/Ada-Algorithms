package HMAC is
   pragma Pure;

   -- Standardize on unsigned 8-bit bytes for cryptography
   type Byte is mod 256;
   type Byte_Array is array (Natural range <>) of Byte;

   -- Strong typing for algorithm parameters
   subtype Block_Size_Type is Positive;
   subtype Hash_Size_Type is Positive;

   -- The HMAC algorithm is parameterized by the underlying cryptographic Hash function.
   -- Using an Ada 2022 generic package allows instantiation with any hash (e.g., MD5, SHA256).
   generic
      Block_Size : Block_Size_Type;
      Hash_Size  : Hash_Size_Type;
      with function Hash (Data : Byte_Array) return Byte_Array;
   package Core is
      -- Pre-computes and returns HMAC for Byte_Array
      function Compute
        (Key     : Byte_Array;
         Message : Byte_Array) return Byte_Array
      with
         Global => null,
         Pre    => Block_Size >= Hash_Size,
         Post   => Compute'Result'Length = Hash_Size;

      -- Convenience variant for string inputs (ASCII/Latin-1 mapped)
      function Compute_String
        (Key     : String;
         Message : String) return Byte_Array
      with
         Global => null,
         Pre    => Block_Size >= Hash_Size,
         Post   => Compute_String'Result'Length = Hash_Size;

      -- Normalizes the key to exactly Block_Size (known as K' in RFC 2104)
      -- Exposed publicly for verification and testing.
      function Normalize_Key (Key : Byte_Array) return Byte_Array
      with
         Global => null,
         Post   => Normalize_Key'Result'Length = Block_Size;
   end Core;

end HMAC;
