--  Ridders_Method — Ada 2023 educational package for Wikipedia
--  "Ridders' method": bracketed root finder combining false position
--  with an exponential transform so that the three sample values of
--  h(x) = f(x) e^{a x} lie on a straight line through the midpoint.
--  Due to C. Ridders. Guaranteed bracketed convergence; quadratic in
--  iterates for smooth f (order ~√2 per function evaluation).
--  Primary source:
--  https://en.wikipedia.org/wiki/Ridders%27_method
--  Siblings: Ada-False-Position-Method / Ada-Bisection-Method /
--  Ada-Newtons-Method (README links; some forthcoming).

pragma Ada_2022;

package Ridders_Method
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
   --  Tol            : stop when |b−a| ≤ Tol or |f(root)| ≤ Tol
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

   ---------------------------------------------------------------------------
   -- Core algorithm
   ---------------------------------------------------------------------------

   --  One Ridders update: given bracket [X0, X2] with opposite signs,
   --  return the Wikipedia x₃ candidate (does not re-bracket).
   --  F1 must be f((X0+X2)/2). Raises Invalid_Argument if the
   --  discriminant under the square root is non-positive.
   --  Uses
   --    x₃ = x₁ + (x₁−x₀)·sign(f₀)·f₁ / √(f₁² − f₀·f₂)
   function Next_Point
     (X0, X2     : Real;
      F0, F1, F2 : Real) return Real
     with Global => null;

   --  Find a root of F on bracket [A, B] by Ridders' method.
   --  On invalid bracket returns Success=False, Status=Invalid_Bracket
   --  (does not raise). Null F raises Invalid_Argument.
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

end Ridders_Method;
