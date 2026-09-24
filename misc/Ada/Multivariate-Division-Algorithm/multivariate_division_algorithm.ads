--  Multivariate_Division_Algorithm — Ada 2023 educational package for the
--  multivariate division algorithm in K[x,y] over the rationals.
--  Sparse term lists (coeff, exp_x, exp_y); monomial orders Lex (x > y) and
--  Grevlex. Implements LT / LM / LC, poly arithmetic, and Divide so that
--    F = sum_i Qi * Gi + R
--  and no term of R is divisible by any LT(Gi).
--  Remainder depends on divisor order unless the Gi form a Gröbner basis.
--  Primary notes / Wikipedia:
--  https://en.wikipedia.org/wiki/Multivariate_division_algorithm
--  Follow-on: Gröbner bases / Buchberger (not implemented here).
--  Sibling (README only — do not `with`): Ada-Polynomial-Long-Division.

pragma Ada_2022;

package Multivariate_Division_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Bounds (classroom-sized; keep tests fast)
   ---------------------------------------------------------------------------

   Max_Degree   : constant := 8;   -- per variable
   Max_Terms    : constant := 64;
   Max_Divisors : constant := 8;

   subtype Exp_Type is Natural range 0 .. Max_Degree;
   subtype Term_Count is Natural range 0 .. Max_Terms;
   subtype Term_Index is Positive range 1 .. Max_Terms;
   subtype Divisor_Count is Natural range 0 .. Max_Divisors;
   subtype Divisor_Index is Positive range 1 .. Max_Divisors;

   Invalid_Argument : exception;
   Division_By_Zero : exception;

   ---------------------------------------------------------------------------
   -- Exact rationals (Num/Den in lowest terms, Den > 0)
   ---------------------------------------------------------------------------

   type Rational is record
      Num : Integer := 0;
      Den : Positive := 1;
   end record;

   Zero_Q : constant Rational := (Num => 0, Den => 1);
   One_Q  : constant Rational := (Num => 1, Den => 1);

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

   function "/" (A, B : Rational) return Rational
     with Global => null;

   ---------------------------------------------------------------------------
   -- Monomial orders on N^2 (variables x > y)
   ---------------------------------------------------------------------------

   type Monomial_Order is (Lex, Grevlex);

   --  Compare monomials x^AX y^AY vs x^BX y^BY.
   --  Returns Positive if A > B, Negative if A < B, Zero if equal.
   function Compare_Monomials
     (AX, AY, BX, BY : Exp_Type;
      Order          : Monomial_Order) return Integer
     with Global => null;

   function Monomial_Divides
     (DX, DY, TX, TY : Exp_Type) return Boolean
     with Global => null;
   --  True iff x^DX y^DY divides x^TX y^TY (DX<=TX and DY<=TY).

   ---------------------------------------------------------------------------
   -- Sparse bivariate polynomials over Q
   -- Each term is Coeff · x^Exp_X · y^Exp_Y. Zero poly has Count = 0.
   ---------------------------------------------------------------------------

   type Term is record
      Coeff : Rational := Zero_Q;
      Exp_X : Exp_Type := 0;
      Exp_Y : Exp_Type := 0;
   end record;

   type Term_Array is array (Term_Index) of Term;

   type Polynomial is record
      Terms : Term_Array;
      Count : Term_Count := 0;
   end record;

   Zero_Poly : constant Polynomial :=
     (Terms => [others => (Coeff => Zero_Q, Exp_X => 0, Exp_Y => 0)],
      Count => 0);

   type Poly_Array is array (Divisor_Index) of Polynomial;

   --  Combine like terms, drop zero coeffs, sort descending by Order.
   function Normalize
     (P     : Polynomial;
      Order : Monomial_Order := Lex) return Polynomial
     with Global => null;

   function Is_Zero (P : Polynomial) return Boolean
     with Global => null;

   function Equal
     (A, B  : Polynomial;
      Order : Monomial_Order := Lex) return Boolean
     with Global => null;

   --  Single term / monomial constructors. Raises Invalid_Argument if
   --  exponents exceed Max_Degree or coeff Den = 0 path via Make_Rational.
   function Make_Term
     (Coeff : Rational;
      Exp_X : Natural;
      Exp_Y : Natural) return Term
     with Global => null;

   function From_Term (T : Term) return Polynomial
     with Global => null;

   function Monomial
     (Coeff : Rational;
      Exp_X : Natural;
      Exp_Y : Natural) return Polynomial
     with Global => null;

   function Constant_Poly (Coeff : Rational) return Polynomial
     with Global => null;

   function Integer_Poly (C : Integer) return Polynomial
     with Global => null;

   --  Univariate-in-x helper: Coeff · x^Power (y^0).
   function Uni_X (Coeff : Rational; Power : Natural) return Polynomial
     with Global => null;

   --  Univariate-in-y helper: Coeff · y^Power (x^0).
   function Uni_Y (Coeff : Rational; Power : Natural) return Polynomial
     with Global => null;

   ---------------------------------------------------------------------------
   -- Leading data (w.r.t. Order). Zero poly → Zero_Q / (0,0) / empty.
   ---------------------------------------------------------------------------

   function LT (P : Polynomial; Order : Monomial_Order) return Term
     with Global => null;

   function LM
     (P     : Polynomial;
      Order : Monomial_Order;
      Exp_X : out Exp_Type;
      Exp_Y : out Exp_Type) return Boolean
     with Global => null;
   --  Returns False if P is zero; else True and sets Exp_X, Exp_Y of LM(P).

   function LC (P : Polynomial; Order : Monomial_Order) return Rational
     with Global => null;

   ---------------------------------------------------------------------------
   -- Arithmetic
   ---------------------------------------------------------------------------

   function Add
     (A, B  : Polynomial;
      Order : Monomial_Order := Lex) return Polynomial
     with Global => null;

   function Sub
     (A, B  : Polynomial;
      Order : Monomial_Order := Lex) return Polynomial
     with Global => null;

   function Scale
     (P     : Polynomial;
      S     : Rational;
      Order : Monomial_Order := Lex) return Polynomial
     with Global => null;

   --  Multiply one term by a polynomial.
   function Mul_Term
     (T     : Term;
      P     : Polynomial;
      Order : Monomial_Order := Lex) return Polynomial
     with Global => null;

   --  Raises Invalid_Argument if a product exponent would exceed Max_Degree
   --  or if the result would need more than Max_Terms after normalize.
   function Mul
     (A, B  : Polynomial;
      Order : Monomial_Order := Lex) return Polynomial
     with Global => null;

   ---------------------------------------------------------------------------
   -- Multivariate division
   ---------------------------------------------------------------------------

   --  Classic loop (Cox–Little–O'Shea):
   --    qi := 0; r := 0; p := F
   --    while p ≠ 0:
   --      if some LT(Gi) divides LT(p): pick the smallest such i
   --         t := LT(p)/LT(Gi);  qi := qi + t;  p := p − t·Gi
   --      else
   --         r := r + LT(p);  p := p − LT(p)
   --  Identity: F = sum_{i=1..N} Quotients(i)·Divisors(i) + Remainder.
   --  No term of Remainder is divisible by any LT(Divisors(i)).
   --  Remainder may depend on the order of the divisors unless they form
   --  a Gröbner basis.
   --  Raises Invalid_Argument if N = 0.
   --  Raises Division_By_Zero if any Divisors(1 .. N) is the zero poly.
   procedure Divide
     (F         :     Polynomial;
      Divisors  :     Poly_Array;
      N         :     Divisor_Count;
      Order     :     Monomial_Order;
      Quotients : out Poly_Array;
      Remainder : out Polynomial)
     with Global => null;

end Multivariate_Division_Algorithm;
