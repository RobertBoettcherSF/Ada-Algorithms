--  Faugere_F4 — Ada 2023 educational sketch of Faugère's F4 algorithm.
--  Computes a Gröbner basis of a bivariate ideal over Q by reducing many
--  S-polynomials at once via Gaussian elimination on a Macaulay-style matrix.
--  Sparse terms (Coeff, Exp_X, Exp_Y); Rational GCD-reduced; Lex / Grevlex.
--  Wikipedia: https://en.wikipedia.org/wiki/Faug%C3%A8re_F4_algorithm
--  Classroom bounds only — not a production CAS. F5 is mentioned in README only.

pragma Ada_2022;

package Faugere_F4
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Bounds (classroom-sized; keep tests fast)
   ---------------------------------------------------------------------------

   Max_Degree  : constant := 8;   -- per variable (absolute cap)
   Max_Terms   : constant := 48;
   Max_Polys   : constant := 16;
   Max_Matrix  : constant := 48;  -- rows / columns of the F4 matrix
   Max_Pairs   : constant := 64;

   subtype Exp_Type is Natural range 0 .. Max_Degree;
   subtype Term_Count is Natural range 0 .. Max_Terms;
   subtype Term_Index is Positive range 1 .. Max_Terms;
   subtype Poly_Count is Natural range 0 .. Max_Polys;
   subtype Poly_Index is Positive range 1 .. Max_Polys;

   Invalid_Argument      : exception;
   Division_By_Zero      : exception;
   Incomplete_Computation : exception;
   --  Raised when Max_Steps, Max_Deg, Max_Polys, Max_Matrix, or Max_Pairs
   --  prevent finishing a Gröbner basis. Documented educational limit.

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

   function Reduce_Q (R : Rational) return Rational
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

   --  LCM of monomials x^AX y^AY and x^BX y^BY.
   procedure Monomial_LCM
     (AX, AY, BX, BY :     Exp_Type;
      LX, LY         : out Exp_Type)
     with Global => null;

   ---------------------------------------------------------------------------
   -- Sparse bivariate polynomials over Q
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

   type Poly_Array is array (Poly_Index) of Polynomial;

   function Normalize
     (P     : Polynomial;
      Order : Monomial_Order := Grevlex) return Polynomial
     with Global => null;

   function Is_Zero (P : Polynomial) return Boolean
     with Global => null;

   function Equal
     (A, B  : Polynomial;
      Order : Monomial_Order := Grevlex) return Boolean
     with Global => null;

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

   function Uni_X (Coeff : Rational; Power : Natural) return Polynomial
     with Global => null;

   function Uni_Y (Coeff : Rational; Power : Natural) return Polynomial
     with Global => null;

   function LT (P : Polynomial; Order : Monomial_Order) return Term
     with Global => null;

   function LM
     (P     : Polynomial;
      Order : Monomial_Order;
      Exp_X : out Exp_Type;
      Exp_Y : out Exp_Type) return Boolean
     with Global => null;

   function LC (P : Polynomial; Order : Monomial_Order) return Rational
     with Global => null;

   function Add
     (A, B  : Polynomial;
      Order : Monomial_Order := Grevlex) return Polynomial
     with Global => null;

   function Sub
     (A, B  : Polynomial;
      Order : Monomial_Order := Grevlex) return Polynomial
     with Global => null;

   function Scale
     (P     : Polynomial;
      S     : Rational;
      Order : Monomial_Order := Grevlex) return Polynomial
     with Global => null;

   function Mul_Term
     (T     : Term;
      P     : Polynomial;
      Order : Monomial_Order := Grevlex) return Polynomial
     with Global => null;

   function Mul
     (A, B  : Polynomial;
      Order : Monomial_Order := Grevlex) return Polynomial
     with Global => null;

   ---------------------------------------------------------------------------
   -- Multivariate reduction / S-polynomials
   ---------------------------------------------------------------------------

   --  Remainder of multivariate division of F by Divisors(1 .. N).
   --  Raises Invalid_Argument if N = 0; Division_By_Zero if any divisor is 0.
   function Normal_Form
     (F        : Polynomial;
      Divisors : Poly_Array;
      N        : Poly_Count;
      Order    : Monomial_Order) return Polynomial
     with Global => null;

   --  Classic S-polynomial (Buchberger):
   --    S(f,g) = (t / LT(f)) * f - (t / LT(g)) * g
   --  where t = LCM(LM(f), LM(g)). Raises Invalid_Argument if either is zero.
   function S_Polynomial
     (F, G  : Polynomial;
      Order : Monomial_Order) return Polynomial
     with Global => null;

   --  True iff LM(F) is divisible by LM of some basis element (LT-ideal membership).
   function LT_In_Ideal
     (F     : Polynomial;
      Basis : Poly_Array;
      N     : Poly_Count;
      Order : Monomial_Order) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Faugère F4 (educational sketch)
   ---------------------------------------------------------------------------

   --  Compute a Gröbner basis of <Generators(1 .. N)> by F4-style batch
   --  reduction: select critical pairs, build a Macaulay-style matrix of
   --  monomial multiples, row-reduce over Q, extract new leading terms.
   --
   --  Max_Deg   : refuse pairs / multiples whose LCM total degree exceeds this
   --              (also capped by package Max_Degree). Default 6.
   --  Max_Steps : maximum F4 matrix iterations. Default 32.
   --  Complete  : True if Buchberger criterion satisfied within bounds;
   --              False if the returned basis may be incomplete (also raises
   --              Incomplete_Computation when the caller would otherwise hang
   --              on a hard capacity limit such as Max_Polys / Max_Matrix).
   --
   --  Raises Invalid_Argument if N = 0 or any generator is the zero polynomial
   --  or Max_Deg = 0. Raises Incomplete_Computation if Max_Polys / Max_Pairs /
   --  Max_Matrix capacity is exceeded before completion.
   procedure Groebner_Basis_F4
     (Generators :     Poly_Array;
      N          :     Poly_Count;
      Order      :     Monomial_Order;
      Basis      : out Poly_Array;
      Basis_N    : out Poly_Count;
      Complete   : out Boolean;
      Max_Deg    :     Natural := 6;
      Max_Steps  :     Natural := 32)
     with Global => null;

end Faugere_F4;
