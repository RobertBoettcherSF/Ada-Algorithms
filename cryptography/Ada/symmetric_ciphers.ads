with Interfaces;

package Symmetric_Ciphers is
   pragma Pure;

   --  ========================================================================
   --  EXCEPTIONS
   --  ========================================================================
   
   Invalid_Key_Length : exception;
   Invalid_Input_Size : exception;

   --  ========================================================================
   --  BASE TYPES
   --  ========================================================================
   
   type Byte is new Interfaces.Unsigned_8;
   type Byte_Array is array (Natural range <>) of Byte;

   type Word32 is new Interfaces.Unsigned_32;

   --  ========================================================================
   --  BLOCK CIPHER (TEA) - Tiny Encryption Algorithm
   --  ========================================================================
   
   --  64-bit block composed of two 32-bit words
   type TEA_Block is array (0 .. 1) of Word32;
   
   --  Array of blocks for modes of operation (ECB, CBC)
   type TEA_Block_Array is array (Natural range <>) of TEA_Block;

   --  128-bit key composed of four 32-bit words
   type TEA_Key is array (0 .. 3) of Word32;

   --  Primitive: Encrypts a single 64-bit block in-place
   procedure TEA_Encrypt_Block (Block : in out TEA_Block; Key : TEA_Key)
     with Global => null;

   --  Primitive: Decrypts a single 64-bit block in-place
   procedure TEA_Decrypt_Block (Block : in out TEA_Block; Key : TEA_Key)
     with Global => null;

   --  Mode: Electronic Codebook (ECB) Encryption
   function TEA_Encrypt_ECB (Plaintext : TEA_Block_Array; Key : TEA_Key) return TEA_Block_Array
     with Global => null,
          Post => TEA_Encrypt_ECB'Result'Length = Plaintext'Length;

   --  Mode: Electronic Codebook (ECB) Decryption
   function TEA_Decrypt_ECB (Ciphertext : TEA_Block_Array; Key : TEA_Key) return TEA_Block_Array
     with Global => null,
          Post => TEA_Decrypt_ECB'Result'Length = Ciphertext'Length;

   --  Mode: Cipher Block Chaining (CBC) Encryption
   function TEA_Encrypt_CBC (Plaintext : TEA_Block_Array; Key : TEA_Key; IV : TEA_Block) return TEA_Block_Array
     with Global => null,
          Post => TEA_Encrypt_CBC'Result'Length = Plaintext'Length;

   --  Mode: Cipher Block Chaining (CBC) Decryption
   function TEA_Decrypt_CBC (Ciphertext : TEA_Block_Array; Key : TEA_Key; IV : TEA_Block) return TEA_Block_Array
     with Global => null,
          Post => TEA_Decrypt_CBC'Result'Length = Ciphertext'Length;

   --  Helper: XOR two TEA blocks
   function XOR_Blocks (Left, Right : TEA_Block) return TEA_Block
     with Global => null;

   --  ========================================================================
   --  STREAM CIPHER (ARC4)
   --  ========================================================================
   
   type ARC4_State_Array is array (Byte) of Byte;

   --  Context holds the 256-byte internal state and indices
   type ARC4_Context is record
      S : ARC4_State_Array;
      I : Byte := 0;
      J : Byte := 0;
   end record;

   --  Initializes the ARC4 state using a variable-length key (1 to 256 bytes)
   --  Raises Invalid_Key_Length if Key is empty or > 256 bytes.
   procedure ARC4_Init (Ctx : out ARC4_Context; Key : Byte_Array)
     with Global => null;

   --  Processes (Encrypts/Decrypts) the input stream using the internal state.
   --  Raises Invalid_Input_Size if Input and Output lengths differ.
   procedure ARC4_Process (Ctx : in out ARC4_Context; Input : Byte_Array; Output : out Byte_Array)
     with Global => null;

end Symmetric_Ciphers;
