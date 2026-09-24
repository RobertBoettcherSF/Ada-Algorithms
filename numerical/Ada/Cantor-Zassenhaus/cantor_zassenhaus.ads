--  Cantor–Zassenhaus algorithm — Ada 2023 educational package.
--  Factor square-free (or square-free kernel of) univariate polynomials
--  over the odd prime field F_p via distinct-degree factorization (DDF)
--  followed by equal-degree factorization (EDF) with random splitting.
--  Primary source:
--  https://en.wikipedia.org/wiki/Cantor–Zassenhaus_algorithm
--  Dense monic polynomials; coefficients reduced into 0 .. P-1.
--  Odd characteristic only (educational scope). Contrast: Berlekamp.

pragma Ada_2022;

with Interfaces;

package Cantor_Zassenhaus
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Bounds and exceptions
   ------------------------------------------------------------------

   --  Soft classroom bound: highest power of x that fits in a Polynomial.
   Max_Degree : constant := 24;

   --  At most one irreducible factor per degree unit.
   Max_Factors : constant := Max_Degree;

   subtype Degree_Index is Natural range 0 .. Max_Degree;

   --  Educational odd primes used in tests / validation bound.
   Max_Trial_Prime : constant := 10_000;

   --  Random-split budget for equal-degree factorization.
   Default_Max_Attempts : constant Positive := 64;

   Invalid_Argument : exception;

   ------------------------------------------------------------------
   --  Word / RNG state
   ------------------------------------------------------------------

   subtype U64 is Interfaces.Unsigned_64;

   ------------------------------------------------------------------
   --  Dense univariate polynomials over F_p
   --  Convention: Coeffs(I) is the coefficient of x^I (constant at 0).
   --  Values live in 0 .. P-1 after Normalize. Degree of zero = -1.
   ------------------------------------------------------------------

   type Coeff_Array is array (Degree_Index) of Natural;

   type Polynomial is record
      Coeffs : Coeff_Array := [others => 0];
   end record;

   Zero_Poly : constant Polynomial := (Coeffs => [others => 0]);

   type Factor_Array is array (1 .. Max_Factors) of Polynomial;

   ------------------------------------------------------------------
   --  Modular helpers
   ------------------------------------------------------------------

   --  Exact trial-division primality for educational sizes.
   function Is_Prime_Trial (N : Natural) return Boolean
     with Global => null;

   --  (A * B) mod M. Raises Invalid_Argument if M = 0.
   function Mul_Mod (A, B, M : Natural) return Natural
     with Global => null;

   --  (Base ^ Exp) mod Modulus via binary exponentiation.
   function Mod_Pow (Base, Exp, Modulus : Natural) return Natural
     with Global => null;

   --  Modular inverse of A modulo odd prime P (Fermat).
   --  Raises Invalid_Argument if P < 3 or A ≡ 0 (mod P).
   function Mod_Inv (A, P : Natural) return Natural
     with Global => null;

   ------------------------------------------------------------------
   --  Polynomial helpers
   ------------------------------------------------------------------

   --  Strip leading zeros conceptually; Degree of zero poly is -1.
   function Degree (P : Polynomial; Modulus : Natural) return Integer
     with Global => null,
          Post   => Degree'Result >= -1
            and then Degree'Result <= Integer (Max_Degree);

   function Is_Zero (P : Polynomial; Modulus : Natural) return Boolean
     with Global => null;

   function Leading_Coefficient
     (P : Polynomial; Modulus : Natural) return Natural
     with Global => null;

   --  Reduce coeffs mod Modulus and clear unused high slots.
   function Normalize
     (P : Polynomial; Modulus : Natural) return Polynomial
     with Global => null;

   --  Scale to leading coefficient 1. Raises Invalid_Argument if zero.
   function Make_Monic
     (P : Polynomial; Modulus : Natural) return Polynomial
     with Global => null;

   function Equal
     (A, B : Polynomial; Modulus : Natural) return Boolean
     with Global => null;

   --  Build from low-degree-first coefficients C(0) .. C(Last).
   --  Raises Invalid_Argument if Last > Max_Degree.
   function From_Coeffs
     (C        : Coeff_Array;
      Last     : Degree_Index;
      Modulus  : Natural) return Polynomial
     with Global => null;

   function Constant_Poly
     (Coeff : Natural; Modulus : Natural) return Polynomial
     with Global => null;

   --  Coeff · x^Power. Raises Invalid_Argument if Power > Max_Degree.
   function Monomial
     (Coeff : Natural; Power : Natural; Modulus : Natural)
      return Polynomial
     with Global => null;

   ------------------------------------------------------------------
   --  Arithmetic over F_p[x]
   ------------------------------------------------------------------

   function Add
     (A, B : Polynomial; Modulus : Natural) return Polynomial
     with Global => null;

   function Sub
     (A, B : Polynomial; Modulus : Natural) return Polynomial
     with Global => null;

   --  Raises Invalid_Argument if deg(A)+deg(B) > Max_Degree.
   function Mul
     (A, B : Polynomial; Modulus : Natural) return Polynomial
     with Global => null;

   --  Euclidean division: Dividend = Quotient*Divisor + Remainder,
   --  deg(Remainder) < deg(Divisor) (or Remainder = 0).
   --  Raises Invalid_Argument if Divisor is zero.
   procedure Div_Mod
     (Dividend  :     Polynomial;
      Divisor   :     Polynomial;
      Modulus   :     Natural;
      Quotient  : out Polynomial;
      Remainder : out Polynomial)
     with Global => null;

   --  Euclidean GCD over F_p; result monic when non-zero.
   function GCD
     (A, B : Polynomial; Modulus : Natural) return Polynomial
     with Global => null;

   --  Base^Exp mod Modulus_Poly in F_p[x] / (Modulus_Poly).
   --  Raises Invalid_Argument if Modulus_Poly is zero.
   function Mod_Exp
     (Base         : Polynomial;
      Exp          : U64;
      Modulus_Poly : Polynomial;
      Modulus      : Natural) return Polynomial
     with Global => null;

   --  Formal derivative over F_p.
   function Derivative
     (P : Polynomial; Modulus : Natural) return Polynomial
     with Global => null;

   --  Square-free kernel: P / gcd(P, P') (monic when non-zero).
   --  Removes repeated factors; Factor works on this kernel.
   function Square_Free
     (P : Polynomial; Modulus : Natural) return Polynomial
     with Global => null;

   ------------------------------------------------------------------
   --  Factorization (Cantor–Zassenhaus pipeline)
   ------------------------------------------------------------------

   --  Factor monic (or made monic) univariate Poly over odd prime field
   --  F_P into monic irreducible factors of the square-free kernel.
   --  Pipeline: validate P → Normalize/Make_Monic → Square_Free →
   --  distinct-degree factorization → equal-degree Cantor–Zassenhaus
   --  splits with Seed-driven LCG.
   --  Count = number of irreducible factors written into Factors(1..Count).
   --  Product of Factors recovers Square_Free(Poly) (not original powers).
   --  Seed is updated (reproducible when fixed).
   --  Raises Invalid_Argument if:
   --    P < 3, P even, P composite (when P ≤ Max_Trial_Prime),
   --    Poly is the zero polynomial, or Max_Attempts exhausted unluckily
   --    on a reducible equal-degree block (rare with Default_Max_Attempts).
   procedure Factor
     (P            :        Natural;
      Poly         :        Polynomial;
      Factors      :    out Factor_Array;
      Count        :    out Natural;
      Seed         : in out U64;
      Max_Attempts :        Positive := Default_Max_Attempts)
     with Global => null;

end Cantor_Zassenhaus;
