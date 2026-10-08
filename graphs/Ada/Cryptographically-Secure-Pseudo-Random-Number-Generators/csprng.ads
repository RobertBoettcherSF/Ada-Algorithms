pragma Assertion_Policy (Pre => Check, Post => Check, Pre'Class => Check);

with Interfaces;

package Csprng is

   -- Basic types for cryptography
   type Byte is mod 256;
   type Byte_Array is array (Positive range <>) of Byte;

   -- Abstract root type for CSPRNG instances
   type Abstract_Csprng is abstract tagged record
      Is_Seeded : Boolean := False;
   end record;

   -- Exception for invalid initialization parameters
   Crypto_Error : exception;

   -- Core generation procedure with class-wide precondition
   procedure Generate (Gen : in out Abstract_Csprng; Data : out Byte_Array) is abstract
     with Pre'Class => Gen.Is_Seeded;

   -------------------------------------------------------------------------
   -- VARIANT 1: ChaCha20 Generator
   -- Cryptographic Primitive Design (Stream Cipher)
   -------------------------------------------------------------------------
   type Cha_Cha_20_Generator is new Abstract_Csprng with private;
   type Cha_Cha_Key is new Byte_Array (1 .. 32);
   type Cha_Cha_Nonce is new Byte_Array (1 .. 8);

   procedure Initialize (Gen   : out Cha_Cha_20_Generator;
                         Key   : in  Cha_Cha_Key;
                         Nonce : in  Cha_Cha_Nonce)
     with Post => Gen.Is_Seeded;

   procedure Generate (Gen : in out Cha_Cha_20_Generator; Data : out Byte_Array);

   -------------------------------------------------------------------------
   -- VARIANT 2: Blum Blum Shub Generator
   -- Number-Theoretic Design (Provably Secure under QR factorization)
   -------------------------------------------------------------------------
   type Bbs_Prime is mod 2**16;
   type Bbs_State is mod 2**32;
   type Bbs_Generator is new Abstract_Csprng with private;

   procedure Initialize (Gen  : out Bbs_Generator;
                         P    : in  Bbs_Prime;
                         Q    : in  Bbs_Prime;
                         Seed : in  Bbs_State)
     with Post => Gen.Is_Seeded;

   procedure Generate (Gen : in out Bbs_Generator; Data : out Byte_Array);

   -------------------------------------------------------------------------
   -- VARIANT 3: RC4 Generator
   -- Historical Design (Mentioned as formally used but now insecure)
   -------------------------------------------------------------------------
   type Rc4_Generator is new Abstract_Csprng with private;

   procedure Initialize (Gen : out Rc4_Generator;
                         Key : in  Byte_Array)
     with Post => Gen.Is_Seeded;

   procedure Generate (Gen : in out Rc4_Generator; Data : out Byte_Array);

private

   subtype U32 is Interfaces.Unsigned_32;
   type Cha_Cha_State is array (0 .. 15) of U32;

   type Cha_Cha_20_Generator is new Abstract_Csprng with record
      State        : Cha_Cha_State := [others => 0];
      Buffer       : Byte_Array (1 .. 64) := [others => 0];
      Buffer_Index : Positive := 65;
   end record;

   type Bbs_Generator is new Abstract_Csprng with record
      M, X : Bbs_State := 0;
   end record;

   type Rc4_State_Array is array (Byte) of Byte;
   
   type Rc4_Generator is new Abstract_Csprng with record
      S    : Rc4_State_Array := [others => 0];
      I, J : Byte := 0;
   end record;

end Csprng;
