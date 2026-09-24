--  ==========================================================================
--  Package: Twofish
--  Description: Implementation of the Twofish symmetric block cipher (128-bit
--               block size, support for 128, 192, and 256-bit keys) in Ada 2023.
--  ==========================================================================

with Interfaces;

package Twofish is
   pragma Pure;
   pragma Warnings (Off, "-gnatw.t"); -- Suppress warning about trivial postconditions

   -- Domain types using Interfaces for strict typing and portability
   subtype Byte is Interfaces.Unsigned_8;
   subtype Word32 is Interfaces.Unsigned_32;

   type Byte_Array is array (Positive range <>) of Byte;
   type Word_Array is array (Natural range <>) of Word32;

   -- Key sizes in bytes
   subtype Key_128_Bytes is Byte_Array (1 .. 16);
   subtype Key_192_Bytes is Byte_Array (1 .. 24);
   subtype Key_256_Bytes is Byte_Array (1 .. 32);

   -- Block size: 16 bytes (128 bits) or 4 32-bit words
   subtype Block_Bytes is Byte_Array (1 .. 16);
   subtype Block_Words is Word_Array (0 .. 3);

   -- Key length variants
   type Key_Length_Type is (Key_128, Key_192, Key_256);

   -- Cryptographic context storing precomputed subkeys and round keys
   type Twofish_Context (Key_Len : Key_Length_Type := Key_128) is record
      Subkeys : Word_Array (0 .. 39);
      S_Box   : Word_Array (0 .. 255);
   end record;

   -- Exceptions for invalid input parameters
   Invalid_Key_Length  : exception;
   Invalid_Data_Length : exception;

   -- Key setup subprograms for 128, 192, and 256-bit keys
   procedure Key_Setup_128 (Key     : in     Key_128_Bytes;
                            Context :    out Twofish_Context)
     with Pre  => Key'Length = 16,
          Post => Context.Key_Len = Key_128;

   procedure Key_Setup_192 (Key     : in     Key_192_Bytes;
                            Context :    out Twofish_Context)
     with Pre  => Key'Length = 24,
          Post => Context.Key_Len = Key_192;

   procedure Key_Setup_256 (Key     : in     Key_256_Bytes;
                            Context :    out Twofish_Context)
     with Pre  => Key'Length = 32,
          Post => Context.Key_Len = Key_256;

   -- Encryption and decryption subprograms
   procedure Encrypt (Context    : in     Twofish_Context;
                      Plaintext  : in     Block_Bytes;
                      Ciphertext :    out Block_Bytes)
     with Pre  => Plaintext'Length = 16,
          Post => Ciphertext'Length = 16;

   procedure Decrypt (Context    : in     Twofish_Context;
                      Ciphertext : in     Block_Bytes;
                      Plaintext  :    out Block_Bytes)
     with Pre  => Ciphertext'Length = 16,
          Post => Plaintext'Length = 16;

end Twofish;
