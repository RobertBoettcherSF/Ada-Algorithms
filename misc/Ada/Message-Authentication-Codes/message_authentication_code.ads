--  Message Authentication Code (MAC) Implementations
--
--  This package provides a standalone, warning-free implementation of three
--  classic MAC variants: HMAC, CBC-MAC, and Prefix-MAC.
--  It relies on internal, simplified cryptographic primitives (Hash, Block Cipher)
--  designed explicitly to illustrate the correct operational structure of these
--  MAC algorithms without relying on heavy external cryptography libraries.

package Message_Authentication_Code 
  with Pure 
is

   --  Domain specific types for cryptography data
   type Byte is mod 256;
   type Byte_Array is array (Positive range <>) of Byte;

   --  Constants defining the sizes for our internal cryptographic primitives
   Hash_Block_Size  : constant Positive := 16;
   Hash_Output_Size : constant Positive := 16;

   --  Constrained subtypes for specific data roles
   subtype Block_Array is Byte_Array (1 .. Hash_Block_Size);
   subtype Hash_Array  is Byte_Array (1 .. Hash_Output_Size);

   --  Exceptions for invalid inputs
   Invalid_Key_Error     : exception;
   Invalid_Message_Error : exception;

   --  Variant 1: HMAC (Hash-based Message Authentication Code)
   --  RFC 2104 standard construct. Combines a hash function with a secret key.
   --  Safe against length-extension attacks.
   function HMAC
     (Key     : Byte_Array;
      Message : Byte_Array) return Hash_Array
     with Global => null;

   --  Variant 2: CBC-MAC (Cipher Block Chaining MAC)
   --  Generates a MAC using a block cipher in Cipher Block Chaining mode.
   --  The MAC is the final encrypted block. Includes ISO/IEC 9797-1 padding.
   function CBC_MAC
     (Key     : Block_Array;
      Message : Byte_Array) return Block_Array
     with Global => null;

   --  Variant 3: Prefix-MAC (Secret Prefix MAC)
   --  Computes MAC = Hash (Key || Message).
   --  Included for historical illustration; vulnerable to length-extension
   --  attacks if the underlying hash uses a standard Merkle-Damgard construction.
   function Prefix_MAC
     (Key     : Byte_Array;
      Message : Byte_Array) return Hash_Array
     with Global => null;

   --  Helper: A simplified hash function to serve as the underlying primitive.
   function Simple_Hash (Message : Byte_Array) return Hash_Array
     with Global => null;

   --  Helper: A simplified 10-round block cipher to serve as the primitive.
   function Simple_Encrypt (Key : Block_Array; Block : Block_Array) return Block_Array
     with Global => null;

end Message_Authentication_Code;
