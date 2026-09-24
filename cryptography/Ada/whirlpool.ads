--------------------------------------------------------------------------------
-- Package: Whirlpool (ISO/IEC 10118-3 / NESSIE Cryptographic Hash Function)
-- Description: Provides a complete, secure, and type-safe implementation of the
--              Whirlpool 512-bit cryptographic hash function in Ada 2023.
--------------------------------------------------------------------------------

package Whirlpool is

   -- Domain Types
   type Byte is mod 256;
   type State_Matrix is array (0 .. 7, 0 .. 7) of Byte;
   type Digest is array (0 .. 63) of Byte;
   type Block is array (0 .. 63) of Byte;
   type Message is array (Positive range <>) of Byte;

   -- Exceptions
   Invalid_Message : exception;
   Cryptographic_Error : exception;

   -- Public Subprograms
   function Hash (Data : Message) return Digest
      with Global => null;

   function Hash_String (S : String) return Digest
      with Global => null;

   function Digest_To_Hex (D : Digest) return String
      with Global => null,
           Post => Digest_To_Hex'Result'Length = 128;

end Whirlpool;
