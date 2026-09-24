--  Bisection_Method — Ada 2023 educational package for Wikipedia
--  "Bisection method" (interval halving / binary search / dichotomy):
--  classic bracketed root finder that repeatedly replaces [a,b] by the
--  half-interval that still contains a sign change of continuous f.
--  Guaranteed linear convergence; robust but relatively slow.
--  Primary source:
--  https://en.wikipedia.org/wiki/Bisection_method
--  Siblings: Ada-False-Position-Method / Ada-Ridders-Method /
--  Ada-ITP-Method (README links).

pragma Ada_2022;

package Bisection_Method
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Objective f : R → R whose root is sought on a bracket [A, B].
   type Objective_Fn is access function (X : Real) return Real;

   --  Max_Iterations : hard outer iteration budget
   --  Tol            : stop when (b−a)/2 < Tol or |f(c)| < Tol
   type Config is record
      Max_Iterations : Positive      := 100;
      Tol            : Positive_Real := 1.0E-10;
   end record;

   type Status_Kind is
     (Ok,
      Invalid_Bracket,
      Max_Iterations_Reached,
      Degenerate);

   type Result is record
      Root       : Real        := 0.0;
      Iterations : Natural     := 0;
      Success    : Boolean     := False;
      Status     : Status_Kind := Invalid_Bracket;
      Final_F    : Real        := 0.0;
      Bracket_A  : Real        := 0.0;
      Bracket_B  : Real        := 0.0;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   --  Classical sign: −1 if X < 0, 0 if X = 0, +1 if X > 0.
   function Sign (X : Real) return Real
     with Global => null,
          Post => Sign'Result = -1.0
             or else Sign'Result = 0.0
             or else Sign'Result = 1.0;

   --  True iff A ≠ B and f(A)·f(B) < 0 (strict opposite signs).
   function Bracket_Valid
     (A, B : Real;
      F    : Objective_Fn) return Boolean
     with Pre => F /= null, Global => null;

   --  Classic iteration estimate: ⌈log₂((B−A)/Tol)⌉ when B≠A and Tol>0;
   --  returns 0 if the half-width is already within Tol.
   function Iterations_Needed
     (A, B : Real;
      Tol  : Positive_Real) return Natural
     with Global => null;

   ---------------------------------------------------------------------------
   -- Core algorithm
   ---------------------------------------------------------------------------

   --  One classic bisection midpoint:
   --    C = (A + B) / 2
   function Next_Point (A, B : Real) return Real
     with Global => null;

   --  Find a root of F on bracket [A, B] by classic bisection.
   --  On invalid bracket returns Success=False, Status=Invalid_Bracket
   --  (does not raise). Null F raises Invalid_Argument.
   --  Stops when (B−A)/2 < Tol, |f(C)| < Tol, or Max_Iterations.
   function Find_Root
     (F   : Objective_Fn;
      A   : Real;
      B   : Real;
      Cfg : Config := (others => <>)) return Result
     with Pre => F /= null, Global => null;

   --  Convenience overload with explicit Tol / Max_Iterations.
   function Find_Root
     (F              : Objective_Fn;
      A              : Real;
      B              : Real;
      Tol            : Positive_Real;
      Max_Iterations : Positive := 100) return Result
     with Pre => F /= null, Global => null;

   ---------------------------------------------------------------------------
   -- Educational sample objectives (library-level for 'Access in tests)
   ---------------------------------------------------------------------------

   function Poly_Linear (X : Real) return Real;
   --  2x − 4; root at 2.

   function Poly_Quad (X : Real) return Real;
   --  x² − 2; roots ±√2.

   function Poly_Cubic (X : Real) return Real;
   --  (x−1)(x−2)(x−3); roots 1, 2, 3.

   function Poly_Shifted (X : Real) return Real;
   --  (x−1/2)(x+3); roots 1/2, −3.

   function Cubic_One_Root (X : Real) return Real;
   --  x³ − x − 1; unique real root ≈ 1.324717957.

   function Wiki_Cubic (X : Real) return Real;
   --  x³ − x − 2; Wikipedia bisection example; root ≈ 1.5213797068.

   function Sin_Fn (X : Real) return Real;
   function Cos_Fn (X : Real) return Real;
   function Exp_Linear (X : Real) return Real;
   --  e^x − 2; root ln 2.

   function Atan_Shift (X : Real) return Real;
   --  arctan(x) − 1/2.

   function Steep_Exp (X : Real) return Real;
   --  e^x − e; root 1.

   function Always_Positive (X : Real) return Real;
   function Always_Negative (X : Real) return Real;
   function Same_Sign_Ends (X : Real) return Real;
   --  x² + 1 (never changes sign).

   function Flat_Zero (X : Real) return Real;
   --  identically 0.

end Bisection_Method;
