with Interfaces; use Interfaces;

package Diffie_Hellman is

   --  Strong typing for all algorithm-specific data to prevent accidental mixing
   --  of parameters. Moduli, bases, private keys, and public keys are strictly typed.
   type Modulus_Type is new Unsigned_64;
   type Base_Type is new Unsigned_64;
   type Private_Key_Type is new Unsigned_64;
   type Public_Key_Type is new Unsigned_64;
   type Shared_Secret_Type is new Unsigned_64;

   --  Exceptions for error handling
   Invalid_Parameter  : exception;
   Invalid_Public_Key : exception;

   --  Validation helper functions (exposed for pre-conditions and user checks)
   function Is_Valid_Modulus (P : Modulus_Type) return Boolean is (P > 2);
   
   function Is_Valid_Base (G : Base_Type; P : Modulus_Type) return Boolean is 
     (G > 1 and then Modulus_Type (G) < P - 1);
     
   function Is_Valid_Private_Key (Priv : Private_Key_Type; P : Modulus_Type) return Boolean is 
     (Priv > 0 and then Modulus_Type (Priv) < P - 1);
     
   function Is_Valid_Public_Key (Pub : Public_Key_Type; P : Modulus_Type) return Boolean is 
     (Pub > 1 and then Modulus_Type (Pub) < P - 1);

   --  Variant 1: Standard Public Key Generation (Step 1 of standard DH)
   --  Computes (G ^ Priv) mod P
   function Generate_Public_Key
     (P    : Modulus_Type;
      G    : Base_Type;
      Priv : Private_Key_Type) return Public_Key_Type
     with Pre => Is_Valid_Modulus (P) and then
                 Is_Valid_Base (G, P) and then
                 Is_Valid_Private_Key (Priv, P),
          Global => null;

   --  Variant 1: Compute Standard Shared Secret (Step 2 of standard DH)
   --  Computes (Remote_Pub ^ Priv) mod P
   function Compute_Shared_Secret
     (P          : Modulus_Type;
      Remote_Pub : Public_Key_Type;
      Priv       : Private_Key_Type) return Shared_Secret_Type
     with Pre => Is_Valid_Modulus (P) and then
                 Is_Valid_Public_Key (Remote_Pub, P) and then
                 Is_Valid_Private_Key (Priv, P),
          Global => null;

   --  Variant 2: Multi-Party Diffie-Hellman Intermediate Computation
   --  Operationally identical to Compute_Shared_Secret, but types the return 
   --  as a Public_Key_Type to be safely passed to the next party in the ring.
   function Compute_Multi_Party_Intermediate
     (P          : Modulus_Type;
      Remote_Pub : Public_Key_Type;
      Priv       : Private_Key_Type) return Public_Key_Type
     with Pre => Is_Valid_Modulus (P) and then
                 Is_Valid_Public_Key (Remote_Pub, P) and then
                 Is_Valid_Private_Key (Priv, P),
          Global => null;

end Diffie_Hellman;
