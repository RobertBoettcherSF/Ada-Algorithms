pragma Ada_2022;
with Interfaces;

package Chacha is
   
   --  Basic domain types mapping the 32-bit word and byte structures
   type Word is new Interfaces.Unsigned_32;
   type Bytes is array (Natural range <>) of Interfaces.Unsigned_8;

   --  Domain subtypes for cryptographic parameters
   subtype Key_256  is Bytes (0 .. 31);
   subtype Nonce_96 is Bytes (0 .. 11);
   subtype Nonce_64 is Bytes (0 .. 7);

   --  Supported algorithmic variants based on the number of rounds
   type Rounds is (ChaCha8, ChaCha12, ChaCha20);

   --  ========================================================================
   --  High-Level Encryption/Decryption APIs
   --  (ChaCha is a symmetric stream cipher, so encrypt and decrypt are the same)
   --  ========================================================================

   --  IETF RFC 7539 Variant: 96-bit nonce, 32-bit block counter
   procedure Encrypt_IETF
     (Key     : in     Key_256;
      Nonce   : in     Nonce_96;
      Counter : in     Word;
      Data    : in out Bytes;
      Variant : in     Rounds := ChaCha20)
     with Global => null,
          Post   => Data'Length = Data'Old'Length;

   --  Original Bernstein Variant: 64-bit nonce, 64-bit block counter
   procedure Encrypt_Original
     (Key     : in     Key_256;
      Nonce   : in     Nonce_64;
      Counter : in     Interfaces.Unsigned_64;
      Data    : in out Bytes;
      Variant : in     Rounds := ChaCha20)
     with Global => null,
          Post   => Data'Length = Data'Old'Length;

   --  ========================================================================
   --  Internal / Low-Level APIs (Visible for testing and advanced usage)
   --  ========================================================================

   subtype Block_Type is Bytes (0 .. 63);
   type State_Array is array (0 .. 15) of Word;

   --  The core mixing function for 4 words
   procedure Quarter_Round (A, B, C, D : in out Word)
     with Global => null;

   --  Generates a single 64-byte keystream block from an initialized state
   procedure Generate_Block
     (Initial_State : in     State_Array;
      Variant       : in     Rounds;
      Block         :    out Block_Type)
     with Global => null;

end Chacha;
