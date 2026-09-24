--  Gospers_Algorithm — Ada 2023 educational package for Wikipedia
--  "Gosper's algorithm": indefinite hypergeometric summation.
--  Finds a hypergeometric antidifference S for term t when one exists:
--    S(n+1) − S(n) = t(n).
--  Educational core: dense univariate polynomials over Rational (Num/Den),
--  Gosper normal form of a rational ratio R(n)=t(n+1)/t(n)=A(n)/B(n),
--  polynomial certificate X, and verification on sample integers.
--  Subset: polynomial terms, geometric terms r^n, and rational-ratio
--  hypergeometric terms (no Pochhammer / factorial CAS). Max_Degree = 12.
--  Primary source:
--  https://en.wikipedia.org/wiki/Gosper's_algorithm
--  Sibling style (README only — do not `with`): Ada-Polynomial-Long-Division.

pragma Ada_2022;

package Gospers_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Bounds
   ---------------------------------------------------------------------------

   --  Soft classroom bound: highest power that fits in a Polynomial.
   Max_Degree : constant := 12;

   subtype Degree_Index is Natural range 0 .. Max_Degree;

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

   function Abs_Val (R : Rational) return Rational
     with Global => null;

   function Pow_Nat (Base : Rational; Exp : Natural) return Rational
     with Global => null;

   ---------------------------------------------------------------------------
   -- Dense univariate polynomials over Q
   -- Coeffs(I) = coefficient of n^I; Coeffs(0) = constant.
   ---------------------------------------------------------------------------

   type Coeff_Array is array (Degree_Index) of Rational;

   type Polynomial is record
      Coeffs : Coeff_Array := [others => Zero_Q];
   end record;

   Zero_Poly : constant Polynomial := (Coeffs => [others => Zero_Q]);

   function Trim (P : Polynomial) return Polynomial
     with Global => null;

   function Normalize (P : Polynomial) return Polynomial
     renames Trim;

   function Degree (P : Polynomial) return Integer
     with Global => null,
          Post   => Degree'Result >= -1
            and then Degree'Result <= Integer (Max_Degree);

   function Is_Zero (P : Polynomial) return Boolean
     with Global => null;

   function Leading_Coefficient (P : Polynomial) return Rational
     with Global => null;

   function Equal (A, B : Polynomial) return Boolean
     with Global => null;

   function Monomial
     (Coeff : Rational; Power : Natural) return Polynomial
     with Global => null;

   function Constant_Poly (Coeff : Rational) return Polynomial
     with Global => null;

   function Integer_Poly (C : Integer) return Polynomial
     with Global => null;

   function Add (A, B : Polynomial) return Polynomial
     with Global => null;

   function Sub (A, B : Polynomial) return Polynomial
     with Global => null;

   function Mul (A, B : Polynomial) return Polynomial
     with Global => null;

   function Scale (P : Polynomial; S : Rational) return Polynomial
     with Global => null;

   --  Exact Euclidean division over Q. Raises Division_By_Zero if Divisor=0.
   procedure Divide
     (Dividend  :     Polynomial;
      Divisor   :     Polynomial;
      Quotient  : out Polynomial;
      Remainder : out Polynomial)
     with Global => null;

   --  Raise Invalid_Argument if Remainder ≠ 0.
   function Exact_Quotient (Dividend, Divisor : Polynomial) return Polynomial
     with Global => null;

   --  Monic content-free GCD over Q (LC = 1 when nonzero).
   function Poly_GCD (A, B : Polynomial) return Polynomial
     with Global => null;

   --  P(n + K) for integer K (classroom bound on resulting degree).
   function Shift (P : Polynomial; K : Integer) return Polynomial
     with Global => null;

   --  Evaluate P at integer N.
   function Eval (P : Polynomial; N : Integer) return Rational
     with Global => null;

   ---------------------------------------------------------------------------
   -- Hypergeometric term specification (educational subset)
   ---------------------------------------------------------------------------

   --  Polynomial_Term : t(n) = Poly(n)
   --  Ratio_Term      : t(n+1)/t(n) = A(n)/B(n), with seed t(Seed_N)=Seed_T
   --  Geometric_Term  : t(n) = Ratio^n  (seed t(0)=1)
   type Term_Kind is (Polynomial_Term, Ratio_Term, Geometric_Term);

   type Term_Spec is record
      Kind   : Term_Kind := Polynomial_Term;
      Poly   : Polynomial := Zero_Poly;
      A      : Polynomial := Integer_Poly (1);
      B      : Polynomial := Integer_Poly (1);
      Ratio  : Rational := One_Q;
      Seed_N : Integer := 0;
      Seed_T : Rational := One_Q;
   end record;

   function Make_Polynomial_Term (P : Polynomial) return Term_Spec
     with Global => null;

   function Make_Ratio_Term
     (A, B : Polynomial;
      Seed_N : Integer := 0;
      Seed_T : Rational := One_Q) return Term_Spec
     with Global => null;

   function Make_Geometric_Term (R : Rational) return Term_Spec
     with Global => null;

   ---------------------------------------------------------------------------
   -- Antidifference certificate / result
   ---------------------------------------------------------------------------

   --  When Found: S(n+1)−S(n)=t(n).
   --  Certificate (Gosper): S(n) = (B_Gosper(n−1)·X(n)/C_Gosper(n)) · t(n).
   --  For polynomial terms, S_Poly is also filled (closed form polynomial).
   type Antidifference_Spec is record
      A_Gosper             : Polynomial := Integer_Poly (1);
      B_Gosper             : Polynomial := Integer_Poly (1);
      C_Gosper             : Polynomial := Integer_Poly (1);
      X                    : Polynomial := Zero_Poly;
      S_Poly               : Polynomial := Zero_Poly;
      Is_Polynomial_Closed : Boolean := False;
   end record;

   type Gosper_Result is record
      Found          : Boolean := False;
      Antidifference : Antidifference_Spec;
   end record;

   --  Rewrite ratio A/B into Gosper form a/b · c(n+1)/c(n).
   procedure Gosper_Normal_Form
     (A_In, B_In           :     Polynomial;
      A_Out, B_Out, C_Out  : out Polynomial)
     with Global => null;

   --  Solve a(n) X(n+1) − b(n−1) X(n) = c(n) for polynomial X.
   --  Found = False if no polynomial solution within Max_Degree.
   procedure Solve_Certificate
     (A_G, B_G, C_G :     Polynomial;
      X             : out Polynomial;
      Found         : out Boolean)
     with Global => null;

   --  Main entry: try to find a hypergeometric antidifference.
   function Try_Gosper_Sum (Term : Term_Spec) return Gosper_Result
     with Global => null;

   --  Check S(N+1)−S(N)=t(N) at integer N using the certificate / closed form.
   --  Raises Invalid_Argument on zero denominators in the evaluation path.
   function Verify_Telescoping
     (Term : Term_Spec;
      Anti : Antidifference_Spec;
      N    : Integer) return Boolean
     with Global => null;

   --  Evaluate t(N) for supported term kinds.
   function Eval_Term (Term : Term_Spec; N : Integer) return Rational
     with Global => null;

   --  Evaluate S(N) from certificate (and term).
   function Eval_Antidifference
     (Term : Term_Spec;
      Anti : Antidifference_Spec;
      N    : Integer) return Rational
     with Global => null;

end Gospers_Algorithm;
