pragma Ada_2022;
with Interfaces;

package Csprng is
   -- =========================================================================
   -- Cryptographically Secure Pseudorandom Number Generator (CSPRNG)
   -- Implements variants from the domain: a number-theoretic generator (BBS)
   -- and a stream-cipher-based generator (ChaCha20).
   -- =========================================================================

   type Byte is new Interfaces.Unsigned_8;
   type Word is new Interfaces.Unsigned_32;
   type Long_Word is new Interfaces.Unsigned_64;
   type Byte_Array is array (Natural range <>) of Byte;

   -- Exceptions for edge cases and invalid inputs
   Invalid_Prime_Exception : exception;
   Invalid_Seed_Exception  : exception;

   -- =========================================================================
   -- Variant 1: Number-Theoretic CSPRNG (Blum Blum Shub)
   -- Suitable for theoretical cryptography. Relies on the hardness of integer
   -- factorization. (Using 64-bit bounds for functional demonstration).
   -- =========================================================================
   type Bbs_State is private;

   -- Initializes the BBS state.
   -- P and Q must be distinct primes congruent to 3 modulo 4.
   -- Seed must be coprime to M (P * Q) and non-zero.
   function Bbs_Initialize (P, Q : Word; Seed : Long_Word) return Bbs_State
     with Global => null;

   -- Generates a single pseudo-random bit using BBS.
   procedure Bbs_Next_Bit (State : in out Bbs_State; Result : out Boolean)
     with Global => null;

   -- Generates a full byte by composing 8 bits from BBS.
   procedure Bbs_Generate_Byte (State : in out Bbs_State; Result : out Byte)
     with Global => null;


   -- =========================================================================
   -- Variant 2: Stream Cipher CSPRNG (ChaCha20)
   -- Suitable for practical, high-speed applications (e.g., /dev/urandom).
   -- =========================================================================
   type Chacha_State is private;
   type Key_Type is array (0 .. 7) of Word;
   type Nonce_Type is array (0 .. 1) of Word;

   -- Initializes the ChaCha20 state with a 256-bit key and 64-bit nonce.
   function Chacha_Initialize (Key : Key_Type; Nonce : Nonce_Type) return Chacha_State
     with Global => null;

   -- Generates an arbitrary number of random bytes. Buffer size dictates amount.
   procedure Chacha_Generate_Bytes (State : in out Chacha_State; Buffer : out Byte_Array)
     with Global => null;

   -- Reseeds the generator by replacing the key and resetting the block counter.
   procedure Chacha_Reseed (State : in out Chacha_State; New_Key : Key_Type)
     with Global => null;

private
   type Bbs_State is record
      M : Long_Word := 1;
      X : Long_Word := 1;
   end record;

   type Chacha_Internal_State is array (0 .. 15) of Word;
   
   type Chacha_State is record
      State     : Chacha_Internal_State := [others => 0];
      Buffer    : Byte_Array (0 .. 63)  := [others => 0];
      Available : Natural               := 0;
   end record;

end Csprng;
