package Post_Quantum_Crypto is
   --  Learning With Errors (LWE) lattice dimensions and modulus.
   --  Scaled down for demonstration while preserving exact cryptographic structure.
   
   type Index_N is range 1 .. 16;  -- Secret key dimension
   type Index_M is range 1 .. 32;  -- Number of equations (Public key dimension)
   
   --  Using modulo 256 arithmetic (q = 256). 
   --  This inherently handles wraps without Constraint_Error.
   type Element is mod 256;
   
   --  Strong typing for plaintext bits.
   type Message_Bit is range 0 .. 1;
   
   --  Mathematical structures
   type Vector_N is array (Index_N) of Element;
   type Vector_M is array (Index_M) of Element;
   type Matrix_M_N is array (Index_M, Index_N) of Element;
   
   type Bit_Array is array (Positive range <>) of Message_Bit;
   
   --  Key Structures
   type Secret_Key is record
      S : Vector_N;
   end record;
   
   type Public_Key is record
      A : Matrix_M_N;
      B : Vector_M;
   end record;
   
   type Ciphertext is record
      U : Vector_N;
      V : Element;
   end record;
   
   type Ciphertext_Array is array (Positive range <>) of Ciphertext;
   
   Crypto_Error : exception;

   --  ========================================================================
   --  Variant 1: Static / Deterministic Key Generation
   --  Generates a keypair from explicitly provided random matrices and error vectors.
   --  ========================================================================
   procedure Generate_Keypair_Static
     (A_Matrix : in Matrix_M_N;
      S_Vector : in Vector_N;
      E_Vector : in Vector_M;
      SK       : out Secret_Key;
      PK       : out Public_Key)
     with Global => null,
          Post => PK.A = A_Matrix and SK.S = S_Vector;

   --  ========================================================================
   --  Variant 2: Dynamic Key Generation
   --  Derives a full keypair safely seeded by a system PRNG.
   --  ========================================================================
   procedure Generate_Keypair
     (Seed : in Integer;
      SK   : out Secret_Key;
      PK   : out Public_Key)
     with Global => null;

   --  ========================================================================
   --  Variant 3: Preemptive / Single-Bit Encryption
   --  Encrypts a single bit mathematically.
   --  ========================================================================
   function Encrypt_Bit
     (Seed : in Integer;
      PK   : in Public_Key;
      Bit  : in Message_Bit) return Ciphertext
     with Global => null;

   function Decrypt_Bit
     (SK : in Secret_Key;
      CT : in Ciphertext) return Message_Bit
     with Global => null;

   --  ========================================================================
   --  Variant 4: Non-Preemptive / Batch Message Encryption
   --  Encrypts an entire array of bits into ciphertext vectors.
   --  ========================================================================
   function Encrypt_Message
     (Seed : in Integer;
      PK   : in Public_Key;
      Msg  : in Bit_Array) return Ciphertext_Array
     with Global => null,
          Pre => Msg'Length > 0,
          Post => Encrypt_Message'Result'Length = Msg'Length;

   function Decrypt_Message
     (SK  : in Secret_Key;
      CTs : in Ciphertext_Array) return Bit_Array
     with Global => null,
          Pre => CTs'Length > 0,
          Post => Decrypt_Message'Result'Length = CTs'Length;

   --  ========================================================================
   --  Validation & Invariant Helpers
   --  ========================================================================
   
   --  Uses Ada 2012/2022 quantified expression to ensure CT isn't a null vector.
   function Is_Valid_Ciphertext (CT : Ciphertext) return Boolean is
     (for some J in Index_N => CT.U (J) /= 0)
     with Global => null;

end Post_Quantum_Crypto;
