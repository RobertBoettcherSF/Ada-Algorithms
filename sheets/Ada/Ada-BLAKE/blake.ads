package Blake
  with Pure
is
   --  Basic Byte and Array types used for passing data
   type Byte is mod 2**8;
   type Byte_Array is array (Natural range <>) of Byte;

   --  Explicit subtypes for the outputs of each BLAKE variant
   subtype Digest_224 is Byte_Array (0 .. 27);
   subtype Digest_256 is Byte_Array (0 .. 31);
   subtype Digest_384 is Byte_Array (0 .. 47);
   subtype Digest_512 is Byte_Array (0 .. 63);

   --  BLAKE-224 Hash (32-bit words, 512-bit blocks, 224-bit output)
   function Hash_224 (Message : Byte_Array) return Digest_224
     with Global => null;

   --  BLAKE-256 Hash (32-bit words, 512-bit blocks, 256-bit output)
   function Hash_256 (Message : Byte_Array) return Digest_256
     with Global => null;

   --  BLAKE-384 Hash (64-bit words, 1024-bit blocks, 384-bit output)
   function Hash_384 (Message : Byte_Array) return Digest_384
     with Global => null;

   --  BLAKE-512 Hash (64-bit words, 1024-bit blocks, 512-bit output)
   function Hash_512 (Message : Byte_Array) return Digest_512
     with Global => null;

end Blake;
