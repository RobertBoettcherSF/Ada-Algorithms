with Interfaces;

package Key_Exchange is
   pragma Pure;

   -- Strong typing for domain objects. We use Unsigned_32 to allow safe
   -- intermediate calculations inside Unsigned_64 without overflow.
   type Key_Value is new Interfaces.Unsigned_32;

   -- Exceptions
   Invalid_Parameters_Error : exception;
   Authentication_Error     : exception;

   -- 1. Core Mathematical Utilities
   -- -----------------------------------------------------------------------
   
   function Modular_Add (A, B, Modulus : Key_Value) return Key_Value
     with Global => null,
          Pre    => Modulus > 0 and then A < Modulus and then B < Modulus,
          Post   => Modular_Add'Result < Modulus;

   function Modular_Multiply (A, B, Modulus : Key_Value) return Key_Value
     with Global => null,
          Pre    => Modulus > 0 and then A < Modulus and then B < Modulus,
          Post   => Modular_Multiply'Result < Modulus;

   function Modular_Exponentiation (Base, Exponent, Modulus : Key_Value) return Key_Value
     with Global => null,
          Pre    => Modulus > 0,
          Post   => Modular_Exponentiation'Result < Modulus;

   function Modular_Inverse (Value, Modulus : Key_Value) return Key_Value
     with Global => null,
          Pre    => Modulus > 1 and then Value > 0 and then Value < Modulus;
   -- Raises Invalid_Parameters_Error if Value and Modulus are not coprime.

   -- 2. Diffie-Hellman Key Exchange (Anonymous)
   -- -----------------------------------------------------------------------
   
   function DH_Generate_Public (Generator, Private_Key, Prime : Key_Value) return Key_Value
     with Global => null,
          Pre    => Prime > 1 and then Generator < Prime,
          Post   => DH_Generate_Public'Result < Prime;

   function DH_Compute_Secret (Remote_Public, Local_Private, Prime : Key_Value) return Key_Value
     with Global => null,
          Pre    => Prime > 1 and then Remote_Public < Prime,
          Post   => DH_Compute_Secret'Result < Prime;

   procedure DH_Validate_Public_Key (Public_Key, Prime : Key_Value)
     with Global => null,
          Pre    => Prime > 2;
   -- Raises Invalid_Parameters_Error if Public_Key is susceptible to small subgroup attacks
   -- (e.g., if Public_Key is 0, 1, or Prime - 1).

   -- 3. Password-Authenticated Diffie-Hellman Key Exchange (Simplified SPEKE)
   -- -----------------------------------------------------------------------
   -- Uses a shared password as the generator to prevent Man-in-the-Middle attacks.
   
   function PAKA_Generate_Public (Password, Private_Key, Prime : Key_Value) return Key_Value
     with Global => null,
          Pre    => Prime > 1 and then Password < Prime,
          Post   => PAKA_Generate_Public'Result < Prime;

   function PAKA_Compute_Secret (Remote_Public, Local_Private, Prime, Password : Key_Value) return Key_Value
     with Global => null,
          Pre    => Prime > 1 and then Remote_Public < Prime,
          Post   => PAKA_Compute_Secret'Result < Prime;

   -- 4. Shamir's Three-Pass Protocol (Commutative Key Exchange)
   -- -----------------------------------------------------------------------
   -- Allows message exchange without prior shared secrets using commutative encryption.
   
   procedure Shamir_Generate_Keys (Prime, E_Key : Key_Value; D_Key : out Key_Value)
     with Global => null,
          Pre    => Prime > 2 and then E_Key > 0 and then E_Key < Prime - 1;
   -- Computes decryption key D_Key as the modular inverse of E_Key mod (Prime - 1).
   -- Raises Invalid_Parameters_Error if gcd(E_Key, Prime - 1) /= 1.

   function Shamir_Pass_1 (Message, Local_E, Prime : Key_Value) return Key_Value
     with Global => null,
          Pre    => Prime > 1 and then Message < Prime,
          Post   => Shamir_Pass_1'Result < Prime;

   function Shamir_Pass_2 (Cipher_1, Remote_E, Prime : Key_Value) return Key_Value
     with Global => null,
          Pre    => Prime > 1 and then Cipher_1 < Prime,
          Post   => Shamir_Pass_2'Result < Prime;

   function Shamir_Pass_3 (Cipher_2, Local_D, Prime : Key_Value) return Key_Value
     with Global => null,
          Pre    => Prime > 1 and then Cipher_2 < Prime,
          Post   => Shamir_Pass_3'Result < Prime;

   function Shamir_Final_Decrypt (Cipher_3, Remote_D, Prime : Key_Value) return Key_Value
     with Global => null,
          Pre    => Prime > 1 and then Cipher_3 < Prime,
          Post   => Shamir_Final_Decrypt'Result < Prime;

end Key_Exchange;
