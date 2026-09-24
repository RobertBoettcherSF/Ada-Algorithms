package ElGamal_Encryption is

   -- Prime modulus for the finite field Z_p (using 10^9 + 7, a prime < 2^31)
   Modulus_Value : constant := 1_000_000_007;

   type Plaintext_T is mod Modulus_Value;

   -- Exceptions
   Invalid_Key_Error        : exception;
   Invalid_Ciphertext_Error : exception;
   Invalid_Signature_Error  : exception;

   -- Key generation record representing a public/private key pair and generator
   type Key_Pair_T is record
      Generator  : Plaintext_T;
      Public_Key : Plaintext_T;
      Private_Key : Plaintext_T;
   end record;

   -- Ciphertext record representing (c1, c2)
   type Ciphertext_T is record
      C1 : Plaintext_T;
      C2 : Plaintext_T;
   end record;

   -- Signature record representing (r, s)
   type Signature_T is record
      R : Plaintext_T;
      S : Plaintext_T;
   end record;

   -- Helper: Modular exponentiation (Base ** Exp mod Modulus)
   function Mod_Exp (Base, Exp : Plaintext_T) return Plaintext_T
     with Post => Mod_Exp'Result = Mod_Exp'Result;

   -- Helper: Greatest common divisor (Euclidean algorithm)
   function GCD (A, B : Plaintext_T) return Plaintext_T;

   -- Helper: Modular inverse using Extended Euclidean Algorithm
   function Mod_Inverse (A : Plaintext_T) return Plaintext_T
     with Pre => A /= 0,
          Post => (Mod_Inverse'Result * A) = 1;

   -- Generate a key pair given a generator and a private key
   procedure Generate_Keys (Generator   : in     Plaintext_T;
                            Private_Key : in     Plaintext_T;
                            Keys        :    out Key_Pair_T)
     with Pre => Generator > 1 and then Generator < Plaintext_T'Last
             and then Private_Key > 0 and then Private_Key < Plaintext_T'Last,
          Post => Keys.Generator = Generator and then Keys.Public_Key = Mod_Exp (Generator, Private_Key);

   -- Encrypt a message using an ephemeral key k
   function Encrypt (Message      : Plaintext_T;
                     Public_Key   : Plaintext_T;
                     Generator    : Plaintext_T;
                     Ephemeral_K  : Plaintext_T) return Ciphertext_T
     with Pre => Ephemeral_K > 0 and then Ephemeral_K < Plaintext_T'Last;

   -- Decrypt a ciphertext
   function Decrypt (Cipher      : Ciphertext_T;
                     Private_Key : Plaintext_T) return Plaintext_T;

   -- Homomorphic multiplication of two ciphertexts
   function Multiply_Ciphertexts (C1, C2 : Ciphertext_T) return Ciphertext_T;

   -- Sign a message (ElGamal Signature Scheme)
   function Sign (Message      : Plaintext_T;
                  Private_Key  : Plaintext_T;
                  Generator    : Plaintext_T;
                  Ephemeral_K  : Plaintext_T) return Signature_T
     with Pre => Ephemeral_K > 0 and then Ephemeral_K < Plaintext_T'Last
             and then GCD (Ephemeral_K, Plaintext_T'Last) = 1;

   -- Verify an ElGamal signature
   function Verify (Message    : Plaintext_T;
                    Sig        : Signature_T;
                    Public_Key : Plaintext_T;
                    Generator  : Plaintext_T) return Boolean;

end ElGamal_Encryption;
