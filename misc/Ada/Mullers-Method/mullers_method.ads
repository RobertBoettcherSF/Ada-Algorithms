--  Mullers_Method — Ada 2023 educational package for Wikipedia
--  "Muller's method": open scalar root finder that fits a parabola
--  through the last three iterates and takes the parabolic root
--  closest to the newest point. Due to David E. Muller (1956).
--  Real-valued educational path: requires non-negative discriminant;
--  complex roots are documented as optional / out of scope here.
--  Order of convergence ≈ 1.84 for simple roots (faster than secant).
--  Primary source:
--  https://en.wikipedia.org/wiki/Muller%27s_method
--  Siblings: Ada-Newtons-Method / Ada-Ridders-Method /
--  Ada-Secant-Method (README links; some forthcoming).

pragma Ada_2022;

package Mullers_Method
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Objective f : R → R whose root is sought.
   type Objective_Fn is access function (X : Real) return Real;

   --  Max_Iterations : hard outer iteration budget
   --  Tol            : stop when |f(x)| ≤ Tol or |Δx| ≤ Tol
   type Config is record
      Max_Iterations : Positive      := 100;
      Tol            : Positive_Real := 1.0E-10;
   end record;

   type Status_Kind is
     (Ok,
      Degenerate,
      Max_Iterations_Reached);

   type Result is record
      Root       : Real        := 0.0;
      Iterations : Natural     := 0;
      Success    : Boolean     := False;
      Status     : Status_Kind := Max_Iterations_Reached;
      Final_F    : Real        := 0.0;
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

   --  True iff the three starts are pairwise distinct.
   function Starts_Distinct (X0, X1, X2 : Real) return Boolean
     with Global => null;

   --  One Muller update (Wikipedia real formula):
   --    h0 = x1−x0,  h1 = x2−x1
   --    δ0 = (f1−f0)/h0,  δ1 = (f2−f1)/h1
   --    a = (δ1−δ0)/(h1+h0),  b = a·h1+δ1,  c = f2
   --    x3 = x2 − 2c / (b + sign(b)·√(b²−4ac))
   --  Raises Invalid_Argument if points coincide, denominator is zero,
   --  or the discriminant is negative (real-only path).
   function Next_Point
     (X0, X1, X2 : Real;
      F0, F1, F2 : Real) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- Core algorithm
   ---------------------------------------------------------------------------

   --  Find a root of F by Muller's method starting at X0, X1, X2.
   --  Coincident starts, non-positive step denominators, or a negative
   --  parabolic discriminant yield Success=False, Status=Degenerate
   --  (does not raise). Null F raises Invalid_Argument.
   function Find_Root
     (F   : Objective_Fn;
      X0  : Real;
      X1  : Real;
      X2  : Real;
      Cfg : Config := (others => <>)) return Result
     with Pre => F /= null, Global => null;

   --  Convenience overload with explicit Tol / Max_Iterations.
   function Find_Root
     (F              : Objective_Fn;
      X0             : Real;
      X1             : Real;
      X2             : Real;
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
   --  (x−1)(x−2)(x−3) = x³ − 6x² + 11x − 6; roots 1, 2, 3.

   function Poly_Shifted (X : Real) return Real;
   --  (x−1/2)(x+3); roots 1/2, −3.

   function Cubic_One_Root (X : Real) return Real;
   --  x³ − x − 1; unique real root ≈ 1.324717957.

   function Wiki_Cubic (X : Real) return Real;
   --  −x³ − x + 7; Wikipedia example real root ≈ 1.7392038612200968.

   function Sin_Fn (X : Real) return Real;
   function Cos_Fn (X : Real) return Real;

   function Exp_Linear (X : Real) return Real;
   --  e^x − 2; root ln 2.

   function Atan_Shift (X : Real) return Real;
   --  arctan(x) − 1/2.

   function Steep_Exp (X : Real) return Real;
   --  e^x − e; root 1.

   function Cos_Minus_X3 (X : Real) return Real;
   --  cos(x) − x³; root ≈ 0.865474.

   function Always_Positive (X : Real) return Real;
   --  identically 1 (no real root).

   function Constant_Zero (X : Real) return Real;
   --  identically 0 (every point is a root).

end Mullers_Method;
