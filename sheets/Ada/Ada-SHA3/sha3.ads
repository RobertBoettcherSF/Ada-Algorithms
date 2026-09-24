package SHA3
  with Pure
is
   --  Basic type definitions for strong typing
   type Byte is mod 2**8;
   type Byte_Array is array (Natural range <>) of Byte;

   --  Explicit subtypes for standard SHA-3 fixed-length outputs
   subtype Hash_224 is Byte_Array (1 .. 28);
   subtype Hash_256 is Byte_Array (1 .. 32);
   subtype Hash_384 is Byte_Array (1 .. 48);
   subtype Hash_512 is Byte_Array (1 .. 64);

   --  Standard SHA-3 variants (Static output length)
   function SHA3_224 (Message : Byte_Array) return Hash_224
     with Global => null;

   function SHA3_256 (Message : Byte_Array) return Hash_256
     with Global => null;

   function SHA3_384 (Message : Byte_Array) return Hash_384
     with Global => null;

   function SHA3_512 (Message : Byte_Array) return Hash_512
     with Global => null;

   --  SHAKE variants (Dynamic output length, extendable output functions - XOF)
   function SHAKE_128 (Message : Byte_Array; Output_Length : Natural) return Byte_Array
     with Global => null,
          Post   => SHAKE_128'Result'Length = Output_Length;

   function SHAKE_256 (Message : Byte_Array; Output_Length : Natural) return Byte_Array
     with Global => null,
          Post   => SHAKE_256'Result'Length = Output_Length;

end SHA3;
