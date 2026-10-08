with Interfaces;

package AES is

   -- Domain types for strict typing of bytes and blocks.
   type Byte is new Interfaces.Unsigned_8;
   type Byte_Array is array (Natural range <>) of Byte;
   
   -- Standard AES Block Size is always 128 bits (16 bytes).
   type Block is array (0 .. 15) of Byte;

   -- Explicitly sized keys for the three AES variants.
   type Key_128 is array (0 .. 15) of Byte;
   type Key_192 is array (0 .. 23) of Byte;
   type Key_256 is array (0 .. 31) of Byte;

   -- Raised when an invalid length is provided to multi-block modes.
   Invalid_Length : exception;

   -----------------------------------------------------------------------------
   -- Single Block Core Algorithms (Static length)
   -----------------------------------------------------------------------------

   procedure Encrypt_Block_128 (Input : in Block; Key : in Key_128; Output : out Block)
     with Global => null;
   procedure Decrypt_Block_128 (Input : in Block; Key : in Key_128; Output : out Block)
     with Global => null;

   procedure Encrypt_Block_192 (Input : in Block; Key : in Key_192; Output : out Block)
     with Global => null;
   procedure Decrypt_Block_192 (Input : in Block; Key : in Key_192; Output : out Block)
     with Global => null;

   procedure Encrypt_Block_256 (Input : in Block; Key : in Key_256; Output : out Block)
     with Global => null;
   procedure Decrypt_Block_256 (Input : in Block; Key : in Key_256; Output : out Block)
     with Global => null;

   -----------------------------------------------------------------------------
   -- Multi-Block Electronic Codebook (ECB) Operations (Dynamic length)
   -----------------------------------------------------------------------------
   -- Handles empty arrays (0-length) gracefully.
   -- Requires Input to be a multiple of 16 bytes and Output to be sufficiently large.

   procedure Encrypt_ECB_128 (Input : in Byte_Array; Key : in Key_128; Output : out Byte_Array)
     with Global => null,
          Pre => Input'Length mod 16 = 0 and then Output'Length >= Input'Length;
          
   procedure Decrypt_ECB_128 (Input : in Byte_Array; Key : in Key_128; Output : out Byte_Array)
     with Global => null,
          Pre => Input'Length mod 16 = 0 and then Output'Length >= Input'Length;

   procedure Encrypt_ECB_192 (Input : in Byte_Array; Key : in Key_192; Output : out Byte_Array)
     with Global => null,
          Pre => Input'Length mod 16 = 0 and then Output'Length >= Input'Length;
          
   procedure Decrypt_ECB_192 (Input : in Byte_Array; Key : in Key_192; Output : out Byte_Array)
     with Global => null,
          Pre => Input'Length mod 16 = 0 and then Output'Length >= Input'Length;

   procedure Encrypt_ECB_256 (Input : in Byte_Array; Key : in Key_256; Output : out Byte_Array)
     with Global => null,
          Pre => Input'Length mod 16 = 0 and then Output'Length >= Input'Length;
          
   procedure Decrypt_ECB_256 (Input : in Byte_Array; Key : in Key_256; Output : out Byte_Array)
     with Global => null,
          Pre => Input'Length mod 16 = 0 and then Output'Length >= Input'Length;

end AES;
