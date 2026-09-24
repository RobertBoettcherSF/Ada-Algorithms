--  Polynomial_Long_Division — Ada 2023 educational package for Wikipedia
--  "Polynomial long division": Euclidean division of univariate polynomials
--  over the rationals. Dense coefficient arrays with Coeffs(I) = coeff of
--  x^I (constant term at index 0). Leading zeros are stripped by Trim /
--  Normalize; Degree of the zero polynomial is -1.
--  Classic long-division loop:
--    while deg(f) ≥ deg(g):
--      t := (LC(f)/LC(g)) x^(deg f − deg g);
--      f := f − t·g;  q := q + t.
--  Identity: f = q·g + r with deg(r) < deg(g) (or r = 0).
--  Primary source:
--  https://en.wikipedia.org/wiki/Polynomial_long_division
--  Siblings (README only — do not `with`): Ada-Long-Division,
--  Ada-Euclidean-Algorithm, Ada-Polynomial-Interpolation,
--  Ada-Goldschmidt-Division, Ada-Karatsuba.

pragma Ada_2022;

package Polynomial_Long_Division
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Bounds
   ---------------------------------------------------------------------------

   --  Soft classroom bound: highest power of x that fits in a Polynomial.
   Max_Degree : constant := 32;

   subtype Degree_Index is Natural range 0 .. Max_Degree;

   Invalid_Argument  : exception;
   Division_By_Zero  : exception;

   ---------------------------------------------------------------------------
   -- Exact rationals (Num/Den in lowest terms, Den > 0)
   ---------------------------------------------------------------------------

   type Rational is record
      Num : Integer := 0;
      Den : Positive := 1;
   end record;

   Zero_Q : constant Rational := (Num => 0, Den => 1);
   One_Q  : constant Rational := (Num => 1, Den => 1);

   --  Construct and reduce to lowest terms; Den becomes positive.
   --  Raises Division_By_Zero if Den = 0.
   function Make_Rational (Num, Den : Integer) return Rational
     with Global => null;

   function Reduce (R : Rational) return Rational
     with Global => null;

   function Equal (A, B : Rational) return Boolean
     with Global => null;

   function Is_Zero (R : Rational) return Boolean
     with Global => null;

   function "+" (A, B : Rational) return Rational
     with Global => null;

   function "-" (A, B : Rational) return Rational
     with Global => null;

   function "-" (A : Rational) return Rational
     with Global => null;

   function "*" (A, B : Rational) return Rational
     with Global => null;

   --  Raises Division_By_Zero if B is zero.
   function "/" (A, B : Rational) return Rational
     with Global => null;

   function Abs_Val (R : Rational) return Rational
     with Global => null;

   ---------------------------------------------------------------------------
   -- Dense univariate polynomials over Q
   -- Convention: Coeffs(I) is the coefficient of x^I; Coeffs(0) = constant.
   -- Leading zeros are insignificant; call Trim/Normalize before Degree.
   ---------------------------------------------------------------------------

   type Coeff_Array is array (Degree_Index) of Rational;

   type Polynomial is record
      Coeffs : Coeff_Array := [others => Zero_Q];
   end record;

   Zero_Poly : constant Polynomial := (Coeffs => [others => Zero_Q]);

   --  Strip leading zero coefficients (normalize storage). Alias of Trim.
   function Trim (P : Polynomial) return Polynomial
     with Global => null;

   function Normalize (P : Polynomial) return Polynomial
     renames Trim;

   --  Degree after Trim. Zero polynomial has Degree = -1.
   function Degree (P : Polynomial) return Integer
     with Global => null,
          Post   => Degree'Result >= -1
            and then Degree'Result <= Integer (Max_Degree);

   function Is_Zero (P : Polynomial) return Boolean
     with Global => null;

   --  Leading coefficient (Coeffs(Degree)); Zero_Q if P is zero.
   function Leading_Coefficient (P : Polynomial) return Rational
     with Global => null;

   function Equal (A, B : Polynomial) return Boolean
     with Global => null;

   --  Build from a slice of coefficients; index offset = lowest power.
   --  Raises Invalid_Argument if the resulting degree would exceed Max_Degree.
   function From_Coeffs
     (C     : Coeff_Array;
      First : Degree_Index := 0;
      Last  : Degree_Index) return Polynomial
     with Global => null,
          Pre    => Last >= First;

   --  Monomial: Coeff · x^Power. Raises Invalid_Argument if Power > Max_Degree.
   function Monomial
     (Coeff : Rational; Power : Natural) return Polynomial
     with Global => null;

   function Constant_Poly (Coeff : Rational) return Polynomial
     with Global => null;

   function Integer_Poly (C : Integer) return Polynomial
     with Global => null;

   ---------------------------------------------------------------------------
   -- Arithmetic
   ---------------------------------------------------------------------------

   function Add (A, B : Polynomial) return Polynomial
     with Global => null;

   function Sub (A, B : Polynomial) return Polynomial
     with Global => null;

   --  Raises Invalid_Argument if deg(A)+deg(B) > Max_Degree.
   function Mul (A, B : Polynomial) return Polynomial
     with Global => null;

   function Scale (P : Polynomial; S : Rational) return Polynomial
     with Global => null;

   ---------------------------------------------------------------------------
   -- Polynomial long division (Euclidean division over Q)
   ---------------------------------------------------------------------------

   --  Compute Quotient and Remainder such that
   --    Dividend = Quotient * Divisor + Remainder
   --  and either Remainder is zero or Degree(Remainder) < Degree(Divisor).
   --  Raises Division_By_Zero if Divisor is the zero polynomial.
   --  Raises Invalid_Argument if an intermediate monomial would exceed
   --  Max_Degree (should not occur for valid inputs within bound).
   procedure Divide
     (Dividend :     Polynomial;
      Divisor  :     Polynomial;
      Quotient : out Polynomial;
      Remainder : out Polynomial)
     with Global => null;

end Polynomial_Long_Division;
