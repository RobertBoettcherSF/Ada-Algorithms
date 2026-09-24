package ECDSA is

   --  We use Long_Long_Integer to prevent overflow during intermediate multiplications
   --  prior to the modulo operation.
   type Value_Type is new Long_Long_Integer;
   
   --  Field elements (mod P) and Scalars (mod N)
   subtype Field_Element is Value_Type range 0 .. Value_Type'Last;
   subtype Scalar is Value_Type range 0 .. Value_Type'Last;

   --  Representation of a Point on the Elliptic Curve, including the Point at Infinity
   type Point (Is_Infinity : Boolean := True) is record
      case Is_Infinity is
         when True => null;
         when False =>
            X : Field_Element;
            Y : Field_Element;
      end case;
   end record;

   --  Domain Parameters defining the specific Elliptic Curve (y^2 = x^3 + Ax + B mod P)
   type Domain_Parameters is record
      P : Field_Element;
      A : Field_Element;
      B : Field_Element;
      G : Point (Is_Infinity => False);
      N : Scalar;
   end record;

   --  The signature output structure
   type Signature is record
      R : Scalar;
      S : Scalar;
   end record;

   --  Exceptions for invalid states or edge cases requiring retries
   Invalid_Domain_Parameters : exception;
   Invalid_Signature         : exception;
   Retry_K_Error             : exception;
   Math_Error                : exception;

   --  Helper Functions (exposed for testing completeness)
   function Mod_Add (X, Y, M : Field_Element) return Field_Element
     with Pre => M > 0;
     
   function Mod_Sub (X, Y, M : Field_Element) return Field_Element
     with Pre => M > 0;
     
   function Mod_Mul (X, Y, M : Field_Element) return Field_Element
     with Pre => M > 0;
     
   function Mod_Inv (A, M : Field_Element) return Field_Element
     with Pre => M > 0;

   --  Curve Arithmetic Subprograms
   function Point_Add (P1, P2 : Point; Params : Domain_Parameters) return Point;
   
   function Point_Double (P1 : Point; Params : Domain_Parameters) return Point;
   
   function Scalar_Mult (K : Scalar; P1 : Point; Params : Domain_Parameters) return Point;

   --  Variant 1: Key Generation
   --  Derives the public key point Q from the private key D.
   function Generate_Key (Params : Domain_Parameters; Private_D : Scalar) return Point
     with Pre => Private_D > 0 and Private_D < Params.N;

   --  Variant 2: Signature Generation
   --  Produces (R, S) signature. Nonce_K is passed explicitly to allow deterministic testing
   --  and to avoid hard-coupling to an RNG.
   function Sign
     (Params       : Domain_Parameters;
      Message_Hash : Scalar;
      Private_D    : Scalar;
      Nonce_K      : Scalar) return Signature
     with Pre => Private_D > 0 and Private_D < Params.N
             and Nonce_K > 0 and Nonce_K < Params.N;

   --  Variant 3: Signature Verification
   --  Validates that a signature matches the message hash and the public key Q.
   function Verify
     (Params       : Domain_Parameters;
      Message_Hash : Scalar;
      Sig          : Signature;
      Public_Q     : Point) return Boolean;

end ECDSA;
