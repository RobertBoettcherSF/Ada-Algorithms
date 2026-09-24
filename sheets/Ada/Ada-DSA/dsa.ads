with Interfaces;

package DSA is
   pragma Preelaborate;

   -- We use a 32-bit type for base values to guarantee that all intermediate
   -- multiplications (which double the bit width) fit safely into standard 64-bit
   -- integers without overflow.
   type DSA_Value is new Interfaces.Unsigned_32;

   -- Public domain parameters for the Digital Signature Algorithm.
   type DSA_Parameters is record
      P : DSA_Value; -- Prime modulus
      Q : DSA_Value; -- Prime divisor of P - 1
      G : DSA_Value; -- Generator
   end record;

   -- An asymmetric key pair bound to specific parameters.
   type Key_Pair is record
      Params : DSA_Parameters;
      X      : DSA_Value; -- Private key
      Y      : DSA_Value; -- Public key
   end record;

   -- The resulting R and S values of a DSA signature.
   type Signature is record
      R : DSA_Value;
      S : DSA_Value;
   end record;

   -- Specific exceptions raised upon invariant violations.
   Invalid_Parameter_Error : exception;
   Invalid_Signature_Error : exception;
   Generation_Error        : exception;

   -- Core mathematical primitives exposed for completeness and testing.
   -- Calculates (Base ^ Exponent) mod Modulus.
   function Mod_Exp (Base, Exponent, Modulus : DSA_Value) return DSA_Value
     with Pre => Modulus > 0;

   -- Calculates the modular multiplicative inverse using Extended Euclidean Algorithm.
   function Mod_Inverse (Value, Modulus : DSA_Value) return DSA_Value
     with Pre => Modulus > 0 and Value > 0;

   -- Key Generation Phase.
   -- Constructs a Key_Pair from domain parameters and a chosen private key X.
   function Generate_Key_Pair (Params : DSA_Parameters; X : DSA_Value) return Key_Pair
     with Pre => Params.P > 0 and then Params.Q > 0 and then X > 0 and then X < Params.Q;

   -- Signature Generation Phase (Variant 1: Standard / Preemptive).
   -- Accepts a pre-chosen or random secret K.
   function Sign_Standard
     (Params : DSA_Parameters;
      X      : DSA_Value;
      K      : DSA_Value;
      Hash   : DSA_Value) return Signature
     with Pre => Params.P > 0 and then Params.Q > 0 and then
                 X > 0 and then X < Params.Q and then
                 K > 0 and then K < Params.Q;

   -- Signature Generation Phase (Variant 2: Deterministic / Dynamic).
   -- Generates K internally based on the Hash and Private Key X (simulating RFC 6979).
   function Sign_Deterministic
     (Params : DSA_Parameters;
      X      : DSA_Value;
      Hash   : DSA_Value) return Signature
     with Pre => Params.P > 0 and then Params.Q > 0 and then
                 X > 0 and then X < Params.Q;

   -- Signature Verification Phase.
   -- Returns True if the Signature is valid for the given Hash and Public Key Y.
   function Verify
     (Params : DSA_Parameters;
      Y      : DSA_Value;
      Hash   : DSA_Value;
      Sig    : Signature) return Boolean
     with Pre => Params.P > 0 and then Params.Q > 0 and then Y > 0;

end DSA;
