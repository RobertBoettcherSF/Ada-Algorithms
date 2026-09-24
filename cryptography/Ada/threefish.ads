package Threefish is
   pragma Pure;

   -- Threefish operates on 64-bit unsigned integers (Little-endian interpretation at byte level,
   -- though this implementation operates mathematically on the words directly).
   type Word is mod 2**64;
   type Word_Array is array (Natural range <>) of Word;

   -- Threefish always uses a 128-bit tweak (two 64-bit words).
   subtype Tweak_Block is Word_Array (0 .. 1);

   -- Block types for the standard 256-bit, 512-bit, and 1024-bit variants.
   subtype Block_256  is Word_Array (0 .. 3);
   subtype Block_512  is Word_Array (0 .. 7);
   subtype Block_1024 is Word_Array (0 .. 15);

   -- Keys are always the same size as the plaintext blocks.
   subtype Key_256  is Block_256;
   subtype Key_512  is Block_512;
   subtype Key_1024 is Block_1024;

   -- Exceptions for edge cases and validation.
   Invalid_Block_Size : exception;

   -----------------------------------------------------------------------------
   -- STATICALLY-TYPED VARIANTS (Compile-Time Safe)
   -----------------------------------------------------------------------------
   
   -- 256-bit Block (72 Rounds)
   procedure Encrypt_256 (Key        : in  Key_256;
                          Tweak      : in  Tweak_Block;
                          Plaintext  : in  Block_256;
                          Ciphertext : out Block_256)
     with Global => null,
          Post   => Ciphertext'Initialized;

   procedure Decrypt_256 (Key        : in  Key_256;
                          Tweak      : in  Tweak_Block;
                          Ciphertext : in  Block_256;
                          Plaintext  : out Block_256)
     with Global => null,
          Post   => Plaintext'Initialized;

   -- 512-bit Block (72 Rounds)
   procedure Encrypt_512 (Key        : in  Key_512;
                          Tweak      : in  Tweak_Block;
                          Plaintext  : in  Block_512;
                          Ciphertext : out Block_512)
     with Global => null,
          Post   => Ciphertext'Initialized;

   procedure Decrypt_512 (Key        : in  Key_512;
                          Tweak      : in  Tweak_Block;
                          Ciphertext : in  Block_512;
                          Plaintext  : out Block_512)
     with Global => null,
          Post   => Plaintext'Initialized;

   -- 1024-bit Block (80 Rounds)
   procedure Encrypt_1024 (Key        : in  Key_1024;
                           Tweak      : in  Tweak_Block;
                           Plaintext  : in  Block_1024;
                           Ciphertext : out Block_1024)
     with Global => null,
          Post   => Ciphertext'Initialized;

   procedure Decrypt_1024 (Key        : in  Key_1024;
                           Tweak      : in  Tweak_Block;
                           Ciphertext : in  Block_1024;
                           Plaintext  : out Block_1024)
     with Global => null,
          Post   => Plaintext'Initialized;

   -----------------------------------------------------------------------------
   -- DYNAMIC VARIANTS
   -----------------------------------------------------------------------------
   
   -- These variants accept any array bounds, dynamically check the length, 
   -- and raise Invalid_Block_Size if the length is not 4, 8, or 16 words.
   -- Preconditions enforce that all arrays share the same physical length.
   
   procedure Encrypt_Dynamic (Key        : in  Word_Array;
                              Tweak      : in  Tweak_Block;
                              Plaintext  : in  Word_Array;
                              Ciphertext : out Word_Array)
     with Global => null,
          Pre    => Key'Length = Plaintext'Length and then 
                    Ciphertext'Length = Plaintext'Length;

   procedure Decrypt_Dynamic (Key        : in  Word_Array;
                              Tweak      : in  Tweak_Block;
                              Ciphertext : in  Word_Array;
                              Plaintext  : out Word_Array)
     with Global => null,
          Pre    => Key'Length = Ciphertext'Length and then 
                    Plaintext'Length = Ciphertext'Length;

end Threefish;
