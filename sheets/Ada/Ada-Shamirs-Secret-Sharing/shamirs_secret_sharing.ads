--  Shamir's Secret Sharing Algorithm
--  Implementation of both the standard Finite Field variant (secure) and
--  the Integer Arithmetic variant (insecure, educational) as described in the
--  Wikipedia article: https://en.wikipedia.org/wiki/Shamir's_secret_sharing
package Shamirs_Secret_Sharing is

   --  ========================================================================
   --  Finite Field Variant (Secure, Standard Implementation)
   --  Operates over a prime field. We use the Mersenne prime 2^31 - 1.
   --  ========================================================================
   Prime : constant := 2_147_483_647;
   type Field_Element is mod Prime;

   --  Shares are evaluated at non-zero X coordinates.
   type Share_Identifier is range 1 .. 255;

   --  A single share representing a point (X, Y) on the polynomial.
   type Secret_Share is record
      Id    : Share_Identifier;
      Value : Field_Element;
   end record;

   type Share_Array is array (Positive range <>) of Secret_Share;
   type Coefficient_Array is array (Natural range <>) of Field_Element;

   Threshold_Error     : exception;
   Invalid_Share_Error : exception;

   --  Split the secret dynamically using an internal random number generator.
   --  This is the standard approach. K = Threshold, N = Total_Shares.
   function Split_Secret
     (Secret       : Field_Element;
      Threshold    : Positive;
      Total_Shares : Positive) return Share_Array
     with Pre => Threshold <= Total_Shares and then Total_Shares <= 255;

   --  Split the secret deterministically (static variant).
   --  Useful for verifiable secret sharing or testing, where polynomial
   --  coefficients are explicitly provided.
   function Split_Secret_Deterministic
     (Secret       : Field_Element;
      Coefficients : Coefficient_Array;
      Total_Shares : Positive) return Share_Array
     with Pre => Total_Shares <= 255 
                 and then Total_Shares >= Coefficients'Length + 1,
          Global => null;

   --  Reconstruct the secret from a set of shares using Lagrange Interpolation.
   --  Requires at least `Threshold` valid shares.
   function Reconstruct_Secret
     (Shares    : Share_Array;
      Threshold : Positive) return Field_Element
     with Pre => Shares'Length >= Threshold,
          Global => null;

   --  Helper: Evaluate polynomial at a given X.
   function Evaluate_Polynomial
     (Secret       : Field_Element;
      Coefficients : Coefficient_Array;
      X            : Field_Element) return Field_Element
     with Global => null;

   --  Helper: Calculate the modular inverse in the chosen Prime field.
   function Modular_Inverse (Value : Field_Element) return Field_Element
     with Pre => Value /= 0,
          Global => null;

   --  ========================================================================
   --  Integer Arithmetic Variant (Insecure, Conceptual Only)
   --  As explicitly noted in the article, plain integer arithmetic leaks data
   --  about the secret. Provided here to fulfill the variant requirement.
   --  ========================================================================
   type Integer_Share is record
      Id    : Positive;
      Value : Integer;
   end record;

   type Integer_Share_Array is array (Positive range <>) of Integer_Share;
   type Integer_Coefficient_Array is array (Natural range <>) of Integer;

   --  Split secret using simple integer arithmetic.
   function Split_Secret_Integer
     (Secret       : Integer;
      Coefficients : Integer_Coefficient_Array;
      Total_Shares : Positive) return Integer_Share_Array
     with Pre => Total_Shares > 0,
          Global => null;

   --  Reconstruct integer secret. 
   --  Uses Long_Float for Lagrange multipliers since integers do not cleanly divide.
   function Reconstruct_Secret_Integer
     (Shares    : Integer_Share_Array;
      Threshold : Positive) return Integer
     with Pre => Shares'Length >= Threshold,
          Global => null;

end Shamirs_Secret_Sharing;
