package IDEA is
   pragma Pure;

   -- Custom modular types to represent IDEA's 16-bit blocks and 32-bit intermediates.
   type Word16 is mod 2**16;
   type Word32 is mod 2**32;

   -- Core structural types for Keys and Data
   type Key_Block is array (1 .. 8) of Word16;
   type Data_Block is array (1 .. 4) of Word16;
   
   -- IDEA uses 52 subkeys generated from the primary 128-bit key
   type Subkey_Array is array (1 .. 52) of Word16;

   -- Exception for invalid key formatting during parsing
   Invalid_Key_Format : exception;

   -- Mathematical Helper Functions
   -- Publicly visible for comprehensive testing of cryptographic primitives.
   
   -- Multiplication modulo 2**16 + 1 (with 0 interpreted as 2**16)
   function Mul (A, B : Word16) return Word16
     with Global => null;

   -- Additive inverse modulo 2**16
   function Add_Inv (X : Word16) return Word16
     with Global => null;

   -- Multiplicative inverse modulo 2**16 + 1
   function Mul_Inv (X : Word16) return Word16
     with Global => null;

   -- Parses a 32-character hexadecimal string into a 128-bit Key_Block.
   -- Raises Invalid_Key_Format if the string length is incorrect or contains invalid characters.
   function Parse_Key (Hex : String) return Key_Block
     with Global => null,
          Pre    => Hex'Length > 0;

   -- Key Schedule Generation
   
   -- Generates the 52 subkeys for encryption from a 128-bit master key
   function Generate_Encryption_Keys (Key : Key_Block) return Subkey_Array
     with Global => null;

   -- Generates the 52 subkeys for decryption from the encryption subkeys
   function Generate_Decryption_Keys (Encrypt_Keys : Subkey_Array) return Subkey_Array
     with Global => null;

   -- Core Cipher Operations
   
   -- Process a 64-bit data block using the provided array of 52 subkeys.
   -- The algorithm structure is identical for encryption and decryption.
   procedure Process_Block (Data    : in out Data_Block;
                            Subkeys : in Subkey_Array)
     with Global => null;

   -- Convenience wrapper: Encrypts a block directly using the master key.
   procedure Encrypt_Block (Data : in out Data_Block; 
                            Key  : in Key_Block)
     with Global => null;

   -- Convenience wrapper: Decrypts a block directly using the master key.
   procedure Decrypt_Block (Data : in out Data_Block; 
                            Key  : in Key_Block)
     with Global => null;

end IDEA;
