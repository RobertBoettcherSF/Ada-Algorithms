with Interfaces;

package Tiny_Encryption_Algorithm
  with Pure
is
   --  Strong typing: Define algorithm-specific types over Unsigned_32.
   --  Using a subtype provides seamless access to bitwise intrinsic operators
   --  (Shift_Left, Shift_Right, xor, and, or) without verbose casting.
   subtype Word is Interfaces.Unsigned_32;

   --  A TEA/XTEA block is exactly 64 bits (two 32-bit words).
   type Block_64 is array (0 .. 1) of Word;

   --  The key is always 128 bits (four 32-bit words) across all variants.
   type Key_128 is array (0 .. 3) of Word;

   --  XXTEA operates on variable-length arrays of 32-bit words.
   type Word_Array is array (Natural range <>) of Word;

   --  Exception raised when XXTEA is provided with a block smaller than 64 bits (2 words).
   Invalid_Block_Size : exception;

   -----------------------------------------------------------------------------
   --  TEA (Tiny Encryption Algorithm)
   -----------------------------------------------------------------------------

   procedure TEA_Encrypt (Data : in out Block_64; Key : Key_128)
     with Global => null;

   procedure TEA_Decrypt (Data : in out Block_64; Key : Key_128)
     with Global => null;

   -----------------------------------------------------------------------------
   --  XTEA (eXtended TEA)
   -----------------------------------------------------------------------------

   --  XTEA resolves weaknesses in the TEA key schedule.
   --  Defaults to 32 cycles (64 rounds) as specified in the original paper.
   procedure XTEA_Encrypt (Data : in out Block_64; Key : Key_128; Num_Rounds : Positive := 32)
     with Global => null;

   procedure XTEA_Decrypt (Data : in out Block_64; Key : Key_128; Num_Rounds : Positive := 32)
     with Global => null;

   -----------------------------------------------------------------------------
   --  XXTEA (Corrected Block TEA)
   -----------------------------------------------------------------------------

   --  XXTEA operates on variable-length blocks.
   procedure XXTEA_Encrypt (Data : in out Word_Array; Key : Key_128)
     with Global => null;

   procedure XXTEA_Decrypt (Data : in out Word_Array; Key : Key_128)
     with Global => null;

end Tiny_Encryption_Algorithm;
