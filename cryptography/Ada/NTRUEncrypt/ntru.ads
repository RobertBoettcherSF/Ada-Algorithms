generic
   N : Positive;
   P : Positive;
   Q : Positive;
package NTRU
  with SPARK_Mode => On
is
   -- Custom types for algorithm-specific data
   subtype Degree_Type is Natural range 0 .. N - 1;
   type Coefficient_Type is new Integer;
   
   -- Polynomial represented as an array of coefficients (from X^0 to X^(N-1))
   type Polynomial is array (Degree_Type) of Coefficient_Type;

   -- Exception raised when a polynomial does not have an inverse
   Not_Invertible : exception;

   -- ==========================================
   -- Core NTRUEncrypt Operations
   -- ==========================================

   -- Generates the Public and Private keys given F and G polynomials
   procedure Generate_Key (F, G : in Polynomial;
                           Public_Key, Private_Key_F, Private_Key_Fp : out Polynomial)
     with Global => null;

   -- Encrypts a message polynomial using a random polynomial and the public key
   function Encrypt (Message, Random_Poly, Public_Key : Polynomial) return Polynomial
     with Global => null;

   -- Decrypts a ciphertext polynomial using the private keys
   function Decrypt (Ciphertext, Private_Key_F, Private_Key_Fp : Polynomial) return Polynomial
     with Global => null;

   -- ==========================================
   -- Helper Operations (Polynomial Arithmetic)
   -- ==========================================

   -- Coefficient-wise addition
   function "+" (A, B : Polynomial) return Polynomial
     with Global => null;

   -- Coefficient-wise subtraction
   function "-" (A, B : Polynomial) return Polynomial
     with Global => null;

   -- Scalar multiplication
   function "*" (Scalar : Coefficient_Type; Poly : Polynomial) return Polynomial
     with Global => null;

   -- Cyclic convolution (Polynomial multiplication in R)
   function "*" (A, B : Polynomial) return Polynomial
     with Global => null;

   -- Reduces all coefficients modulo Mod_Val to the range [0, Mod_Val - 1]
   function Modulo_Poly (Poly : Polynomial; Mod_Val : Positive) return Polynomial
     with Global => null;

   -- Centers coefficients modulo Mod_Val to the range [-(Mod_Val-1)/2, Mod_Val/2]
   function Center (Poly : Polynomial; Mod_Val : Positive) return Polynomial
     with Global => null;

   -- Computes the inverse of a polynomial modulo Mod_Val
   function Invert (Poly : Polynomial; Mod_Val : Positive) return Polynomial
     with Global => null;

end NTRU;
