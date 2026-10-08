package Peterson_Gorenstein_Zierler
  with SPARK_Mode => On
is
   pragma Pure;

   -- Domain types representing our Finite Field GF(11).
   Prime_Modulo : constant := 11;
   type GF_Element is mod Prime_Modulo;

   -- Polynomials are represented as arrays of coefficients.
   -- Index corresponds to the degree of the term (e.g., Poly(I) is the coefficient for x^I).
   type Index_Type is range 0 .. 1024;
   type Polynomial is array (Index_Type range <>) of GF_Element;

   --  Coefficient arrays: slot I holds the coefficient of x**I, so the
   --  index value is the degree (Derivative multiplies by I). Fixed origin 0.
   subtype Degree_Poly is Polynomial
     with Dynamic_Predicate => Degree_Poly'First = 0;

   Matrix_Singular_Error : exception;
   No_Roots_Error        : exception;

   -- Calculates the multiplicative inverse of A in GF(11)
   function Inverse (A : GF_Element) return GF_Element
     with Pre => A /= 0,
          Global => null;

   -- Evaluates the polynomial at a specific field element X
   function Evaluate (Poly : Degree_Poly; X : GF_Element) return GF_Element
     with Pre => Poly'Length > 0,
          Global => null;

   -- Computes the formal derivative of the polynomial
   function Derivative (Poly : Degree_Poly) return Degree_Poly
     with Pre => Poly'Length > 0,
          Global => null;

   -- VARIANT 1: Static Error Locator
   -- Assumes exactly `Expected_Errors` exist. Raises Matrix_Singular_Error if the 
   -- resulting syndrome matrix is singular (meaning actual errors < Expected_Errors).
   function Compute_Locator_Static (Syndromes : Polynomial; Expected_Errors : Positive) return Polynomial
     with Pre => Syndromes'Length >= Index_Type (2 * Expected_Errors),
          Global => null;

   -- VARIANT 2: Dynamic Error Locator
   -- Dynamically handles cases where the actual number of errors is less than the 
   -- assumed maximum by stepping down the matrix size when singularities are encountered.
   function Compute_Locator_Dynamic (Syndromes : Polynomial; Max_Errors : Positive) return Polynomial
     with Pre => Syndromes'Length >= Index_Type (2 * Max_Errors),
          Global => null;

   -- Chien Search Variant
   -- Evaluates the error locator polynomial to find its roots within the Galois field.
   -- Returns the Roots (which are the inverses of the actual error locations).
   function Chien_Search (Locator : Degree_Poly) return Polynomial
     with Pre => Locator'Length > 0,
          Global => null;

   -- Error Evaluator Polynomial (Omega(x))
   -- Computes Omega(x) = S(x)Lambda(x) mod x^(2t)
   function Compute_Evaluator (Syndromes : Polynomial; Locator : Degree_Poly) return Degree_Poly
     with Global => null;

   -- VARIANT A: Forney Algorithm
   -- Computes error values efficiently using the Error Evaluator and the formal derivative.
   function Calculate_Error_Values_Forney (Locator   : Degree_Poly; 
                                           Evaluator : Degree_Poly; 
                                           Roots     : Polynomial) return Polynomial
     with Pre => Locator'Length > 0,
          Global => null;

   -- VARIANT B: Direct Linear System
   -- Computes error values by setting up and solving a Vandermonde-like linear system.
   function Calculate_Error_Values_Linear (Roots     : Polynomial; 
                                           Syndromes : Polynomial) return Polynomial
     with Pre => Syndromes'Length >= Roots'Length,
          Global => null;

end Peterson_Gorenstein_Zierler;
