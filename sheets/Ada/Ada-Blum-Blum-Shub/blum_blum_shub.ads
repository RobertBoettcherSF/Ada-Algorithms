with Interfaces;

package Blum_Blum_Shub is

   use type Interfaces.Unsigned_64;

   -- Subtypes for strong typing and domain clarity
   subtype Prime_Type   is Interfaces.Unsigned_64;
   subtype Modulus_Type is Interfaces.Unsigned_64;
   subtype Seed_Type    is Interfaces.Unsigned_64;

   -- Exceptions for validation failures
   Invalid_Parameters : exception;
   Invalid_Seed       : exception;

   -- Opaque or record type representing generator state
   type Generator is private;

   -- Helper validation functions
   function Is_Prime (N : Interfaces.Unsigned_64) return Boolean;
   function Is_Blum_Prime (N : Interfaces.Unsigned_64) return Boolean;
   function Compute_GCD (A, B : Interfaces.Unsigned_64) return Interfaces.Unsigned_64;

   -- Initialize the Blum Blum Shub generator with two distinct Blum primes (p, q == 3 mod 4)
   -- and a seed coprime to M (where M = p * q).
   procedure Initialize 
     (Gen  : out Generator; 
      P    : in  Prime_Type; 
      Q    : in  Prime_Type; 
      Seed : in  Seed_Type)
     with Pre => P > 2 and then Q > 2 and then P /= Q;

   -- Variant 1: Generate the next pseudo-random bit (least significant bit of state squared mod M)
   function Next_Bit (Gen : in out Generator) return Boolean;

   -- Variant 2: Generate an 8-bit octet (byte) by sequentially extracting 8 bits
   function Next_Byte (Gen : in out Generator) return Interfaces.Unsigned_8;

   -- Variant 3: Generate a block of bits (up to 64 bits) packed into an Unsigned_64 integer
   function Next_Bits (Gen : in out Generator; Count : Positive) return Interfaces.Unsigned_64
     with Pre => Count <= 64;

   -- Peek at the current internal state without advancing the generator
   function Peek_State (Gen : Generator) return Modulus_Type;

private

   type Generator is record
       P     : Interfaces.Unsigned_64 := 0;
       Q     : Interfaces.Unsigned_64 := 0;
       M     : Interfaces.Unsigned_64 := 0;
       State : Interfaces.Unsigned_64 := 0;
   end record;

end Blum_Blum_Shub;
