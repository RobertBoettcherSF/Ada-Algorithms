package Blowfish is
   pragma Pure;

   -- Custom modular types for strict typing of the 64-bit block cipher
   type Word_32 is mod 2**32;
   for Word_32'Size use 32;

   type Byte is mod 2**8;
   for Byte'Size use 8;

   type Byte_Array is array (Natural range <>) of Byte;

   -- Blowfish supports variable length keys from 32 bits (4 bytes) to 448 bits (56 bytes)
   subtype Key_Length is Natural range 4 .. 56;
   
   -- Represents a single 64-bit Blowfish block, split into two 32-bit words
   type Block is record
      Left  : Word_32;
      Right : Word_32;
   end record;

   -- Opaque context holding the algorithm's P-array and S-boxes
   type Context is private;

   Invalid_Key_Length  : exception;
   Invalid_Data_Length : exception;

   -- Initializes the P-array and S-boxes based on the given variable length key.
   procedure Setup_Key (Ctx : out Context; Key : in Byte_Array)
     with Pre    => Key'Length in Key_Length,
          Global => null;

   -- Encrypts a single 64-bit block in-place (2x 32-bit words).
   procedure Encrypt (Ctx : in Context; Left, Right : in out Word_32)
     with Global => null;

   -- Decrypts a single 64-bit block in-place (2x 32-bit words).
   procedure Decrypt (Ctx : in Context; Left, Right : in out Word_32)
     with Global => null;

   -- Encrypts an array of bytes in Electronic Codebook (ECB) mode.
   procedure Encrypt_ECB (Ctx : in Context; Data : in out Byte_Array)
     with Pre    => Data'Length mod 8 = 0,
          Global => null;

   -- Decrypts an array of bytes in Electronic Codebook (ECB) mode.
   procedure Decrypt_ECB (Ctx : in Context; Data : in out Byte_Array)
     with Pre    => Data'Length mod 8 = 0,
          Global => null;

   -- Encrypts an array of bytes in Cipher Block Chaining (CBC) mode.
   procedure Encrypt_CBC (Ctx : in Context; IV : in out Block; Data : in out Byte_Array)
     with Pre    => Data'Length mod 8 = 0,
          Global => null;

   -- Decrypts an array of bytes in Cipher Block Chaining (CBC) mode.
   procedure Decrypt_CBC (Ctx : in Context; IV : in out Block; Data : in out Byte_Array)
     with Pre    => Data'Length mod 8 = 0,
          Global => null;

   -- Utility: Converts 8 bytes to a Block (Big-Endian packing).
   function To_Block (Bytes : Byte_Array) return Block
     with Pre    => Bytes'Length = 8,
          Global => null;

   -- Utility: Converts a Block to an 8-byte array (Big-Endian unpacking).
   function To_Bytes (B : Block) return Byte_Array
     with Post   => To_Bytes'Result'Length = 8,
          Global => null;

private
   type P_Array is array (0 .. 17) of Word_32;
   type S_Box is array (0 .. 255) of Word_32;
   type S_Box_Array is array (0 .. 3) of S_Box;

   type Context is record
      P : P_Array;
      S : S_Box_Array;
   end record;
end Blowfish;
