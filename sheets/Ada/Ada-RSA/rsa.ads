with Ada.Numerics.Big_Numbers.Big_Integers;

package RSA is
   use Ada.Numerics.Big_Numbers.Big_Integers;

   -- Using Big_Integers to handle arbitrary-size mathematics required for RSA
   subtype RSA_Integer is Big_Integer;

   -- Helper for simpler initialization from tests and external usage
   function To_RSA (Value : Integer) return RSA_Integer;
   function To_RSA (Value : String) return RSA_Integer;

   -- Core Mathematical Constants
   Zero : constant RSA_Integer := To_Big_Integer (0);
   One  : constant RSA_Integer := To_Big_Integer (1);
   Two  : constant RSA_Integer := To_Big_Integer (2);

   -- Types for RSA Keys
   type Public_Key is record
      N : RSA_Integer := Zero;
      E : RSA_Integer := Zero;
   end record;

   type Private_Key is record
      N : RSA_Integer := Zero;
      D : RSA_Integer := Zero;
   end record;

   type Key_Pair is record
      Pub  : Public_Key;
      Priv : Private_Key;
   end record;

   -- Named Exceptions for Error Handling
   Invalid_Key_Error       : exception;
   Message_Too_Large_Error : exception;
   Math_Error              : exception;

   -- Core Math Helpers
   -- Computes: (Base ^ Exponent) mod Modulus
   function Modular_Exponentiation (Base, Exponent, Modulus : RSA_Integer) return RSA_Integer
     with Pre => Exponent >= Zero and Modulus > Zero,
          Post => Modular_Exponentiation'Result >= Zero and Modular_Exponentiation'Result < Modulus;

   -- Greatest Common Divisor
   function GCD (A, B : RSA_Integer) return RSA_Integer
     with Pre => A >= Zero and B >= Zero;

   -- Extended Euclidean Algorithm (AX + BY = GCD(A, B))
   -- Returns GCD(A, B) and mutates X, Y to the Bezout coefficients
   function Extended_GCD (A, B : RSA_Integer; X, Y : out RSA_Integer) return RSA_Integer;

   -- Least Common Multiple
   function LCM (A, B : RSA_Integer) return RSA_Integer
     with Pre => A > Zero and B > Zero;

   -- Modular Multiplicative Inverse
   -- Returns X such that (A * X) mod M = 1
   function Modular_Inverse (A, M : RSA_Integer) return RSA_Integer
     with Pre => A > Zero and M > One;

   -- Variant: RSA Key Generation (Textbook Variant)
   -- Generates keys given distinct primes P, Q, and public exponent E.
   -- P and Q are assumed prime (primality check omitted for deterministic speed).
   function Generate_Key_Pair (P, Q, E : RSA_Integer) return Key_Pair
     with Pre => P > One and Q > One and P /= Q and E > One;

   -- Variant: RSA Encryption (Textbook Variant)
   function Encrypt (Plaintext : RSA_Integer; Key : Public_Key) return RSA_Integer
     with Pre => Plaintext >= Zero and Plaintext < Key.N;

   -- Variant: RSA Decryption (Textbook Variant)
   function Decrypt (Ciphertext : RSA_Integer; Key : Private_Key) return RSA_Integer
     with Pre => Ciphertext >= Zero and Ciphertext < Key.N;

   -- Variant: RSA Blinding (Against Timing Attacks)
   -- Incorporates a random factor R to mask the decryption exponentiation timing.
   function Decrypt_Blinded (Ciphertext : RSA_Integer; Key : Private_Key; Pub_E : RSA_Integer; R : RSA_Integer) return RSA_Integer
     with Pre => Ciphertext >= Zero and Ciphertext < Key.N and R > Zero and R < Key.N;

   -- Variant: RSA Digital Signature Generation
   function Sign (Message : RSA_Integer; Key : Private_Key) return RSA_Integer
     with Pre => Message >= Zero and Message < Key.N;

   -- Variant: RSA Digital Signature Verification
   function Verify (Signature : RSA_Integer; Message : RSA_Integer; Key : Public_Key) return Boolean
     with Pre => Signature >= Zero and Signature < Key.N and Message >= Zero and Message < Key.N;

end RSA;
