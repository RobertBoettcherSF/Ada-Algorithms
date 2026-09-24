with Ada.Numerics.Big_Numbers.Big_Integers;

package Eddsa is
   use Ada.Numerics.Big_Numbers.Big_Integers;

   --  Represents a point on a Twisted Edwards Curve.
   type Point is record
      X : Big_Integer;
      Y : Big_Integer;
   end record;

   --  Represents an EdDSA signature consisting of a point R and a scalar S.
   type Signature is record
      R : Point;
      S : Big_Integer;
   end record;

   --  Holds the parameters for the Twisted Edwards Curve (e.g., Ed25519).
   type Curve_Parameters is record
      P : Big_Integer; -- Prime field
      A : Big_Integer; -- Curve equation coefficient
      D : Big_Integer; -- Curve equation coefficient
      L : Big_Integer; -- Subgroup order of the generator
      B : Point;       -- Generator point
      C : Big_Integer; -- Cofactor
   end record;

   --  Provides the parameters for the standard Ed25519 curve.
   function Get_Ed25519_Curve return Curve_Parameters;

   --  Validates whether a given point lies on the specified curve.
   function Is_On_Curve (Curve : Curve_Parameters; Pt : Point) return Boolean;

   --  Core Point Arithmetic
   function Point_Add (Curve : Curve_Parameters; P1, P2 : Point) return Point
     with Pre => Is_On_Curve (Curve, P1) and then Is_On_Curve (Curve, P2),
          Post => Is_On_Curve (Curve, Point_Add'Result);

   function Point_Multiply (Curve : Curve_Parameters; Scalar : Big_Integer; Pt : Point) return Point
     with Pre => Is_On_Curve (Curve, Pt),
          Post => Is_On_Curve (Curve, Point_Multiply'Result);

   --  Derives the public key (Point) from a secret key string.
   function Generate_Public_Key (Curve : Curve_Parameters; Secret_Key : String) return Point
     with Post => Is_On_Curve (Curve, Generate_Public_Key'Result);

   --  ========================================================================
   --  EdDSA Variants
   --  ========================================================================

   --  1. Pure EdDSA (Default variant)
   function Sign_Pure
     (Curve      : Curve_Parameters;
      Message    : String;
      Secret_Key : String) return Signature
     with Post => Is_On_Curve (Curve, Sign_Pure'Result.R);

   function Verify_Pure
     (Curve   : Curve_Parameters;
      Message : String;
      Pub_Key : Point;
      Sig     : Signature) return Boolean
     with Pre => Is_On_Curve (Curve, Pub_Key) and then Is_On_Curve (Curve, Sig.R);

   --  2. Hash EdDSA (EdDSAph) - pre-hashes the message for streaming support
   function Sign_Hash
     (Curve      : Curve_Parameters;
      Message    : String;
      Secret_Key : String) return Signature
     with Post => Is_On_Curve (Curve, Sign_Hash'Result.R);

   function Verify_Hash
     (Curve   : Curve_Parameters;
      Message : String;
      Pub_Key : Point;
      Sig     : Signature) return Boolean
     with Pre => Is_On_Curve (Curve, Pub_Key) and then Is_On_Curve (Curve, Sig.R);

   --  3. Context EdDSA (EdDSActx) - binds a specific context string to the hash
   function Sign_Context
     (Curve      : Curve_Parameters;
      Message    : String;
      Context    : String;
      Secret_Key : String) return Signature
     with Post => Is_On_Curve (Curve, Sign_Context'Result.R);

   function Verify_Context
     (Curve   : Curve_Parameters;
      Message : String;
      Context : String;
      Pub_Key : Point;
      Sig     : Signature) return Boolean
     with Pre => Is_On_Curve (Curve, Pub_Key) and then Is_On_Curve (Curve, Sig.R);

   --  Exceptions
   Division_By_Zero : exception;

private
   function Point_To_String (Pt : Point) return String;
   function Pseudo_Hash (Data : String; Modulus : Big_Integer) return Big_Integer;
end Eddsa;
