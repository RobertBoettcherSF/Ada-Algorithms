--  Halleys_Method — Ada 2023 educational package for Wikipedia
--  "Halley's method": open scalar root finder in the Householder class
--  (order 2 after Newton). Classic rational Halley iteration uses f, f',
--  and f'' and converges cubically for simple roots under standard
--  smoothness assumptions:
--    x <- x − (2 f f') / (2 (f')² − f f'')
--  when the denominator is nonzero. Halley's irrational method (square
--  root form) is documented as Forthcoming only.
--  Primary source:
--  https://en.wikipedia.org/wiki/Halley%27s_method
--  Root-finding siblings: Newton / Muller / Ridders (README links).

pragma Ada_2022;

package Halleys_Method
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

   --  Analytic first derivative f' : R → R.
   type Derivative_Fn is access function (X : Real) return Real;

   --  Analytic second derivative f'' : R → R (same access-to-function shape).
   type Second_Derivative_Fn is access function (X : Real) return Real;

   --  Max_Iterations   : hard outer iteration budget
   --  Tol              : stop when |f(x)| ≤ Tol or |Δx| ≤ Tol
   --  Min_Denominator  : |2 (f')² − f f''| below this → Status = Degenerate
   type Config is record
      Max_Iterations  : Positive      := 100;
      Tol             : Positive_Real := 1.0E-10;
      Min_Denominator : Positive_Real := 1.0E-14;
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

   --  One classic Halley (rational) step:
   --    X_Next = X − (2 F_Val F_Deriv) / (2 F_Deriv² − F_Val F_Second)
   --  Raises Invalid_Argument if the denominator is zero (caller should
   --  normally use Find_Root which returns Degenerate instead).
   function Next_Point
     (X        : Real;
      F_Val    : Real;
      F_Deriv  : Real;
      F_Second : Real) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- Core algorithm
   ---------------------------------------------------------------------------

   --  Find a root of F starting at X0 by classic Halley iteration.
   --  Requires analytic F_Prime and F_Second. Tiny |2 (f')² − f f''|
   --  (or a vanishing Halley numerator while |f| is still large) yields
   --  Success=False, Status=Degenerate (does not raise). Null F, F_Prime,
   --  or F_Second raises Invalid_Argument.
   function Find_Root
     (F         : Objective_Fn;
      F_Prime   : Derivative_Fn;
      F_Second  : Second_Derivative_Fn;
      X0        : Real;
      Cfg       : Config := (others => <>)) return Result
     with Pre => F /= null
                   and then F_Prime /= null
                   and then F_Second /= null,
          Global => null;

   --  Convenience overload with explicit Tol / Max_Iterations
   --  (default Min_Denominator).
   function Find_Root
     (F              : Objective_Fn;
      F_Prime        : Derivative_Fn;
      F_Second       : Second_Derivative_Fn;
      X0             : Real;
      Tol            : Positive_Real;
      Max_Iterations : Positive := 100) return Result
     with Pre => F /= null
                   and then F_Prime /= null
                   and then F_Second /= null,
          Global => null;

   ---------------------------------------------------------------------------
   -- Educational sample objectives + analytic first and second derivatives
   -- (library-level for 'Access in tests)
   ---------------------------------------------------------------------------

   function Poly_Linear (X : Real) return Real;
   function Poly_Linear_Prime (X : Real) return Real;
   function Poly_Linear_Second (X : Real) return Real;
   --  2x − 4; root at 2; f' = 2; f'' = 0.

   function Poly_Quad (X : Real) return Real;
   function Poly_Quad_Prime (X : Real) return Real;
   function Poly_Quad_Second (X : Real) return Real;
   --  x² − 2; roots ±√2; f' = 2x; f'' = 2.

   function Sqrt_Target_A return Real;
   --  Constant a used by Sqrt_Obj (default 612, Wikipedia-style example).

   function Sqrt_Obj (X : Real) return Real;
   function Sqrt_Obj_Prime (X : Real) return Real;
   function Sqrt_Obj_Second (X : Real) return Real;
   --  x² − a; Halley square-root special case (cubic convergence).

   function Poly_Cubic (X : Real) return Real;
   function Poly_Cubic_Prime (X : Real) return Real;
   function Poly_Cubic_Second (X : Real) return Real;
   --  (x−1)(x−2)(x−3) = x³ − 6x² + 11x − 6; roots 1, 2, 3.

   function Poly_Shifted (X : Real) return Real;
   function Poly_Shifted_Prime (X : Real) return Real;
   function Poly_Shifted_Second (X : Real) return Real;
   --  (x−1/2)(x+3); roots 1/2, −3; f'' = 2.

   function Cubic_One_Root (X : Real) return Real;
   function Cubic_One_Root_Prime (X : Real) return Real;
   function Cubic_One_Root_Second (X : Real) return Real;
   --  x³ − x − 1; unique real root ≈ 1.324717957.

   function Sin_Fn (X : Real) return Real;
   function Sin_Fn_Prime (X : Real) return Real;
   function Sin_Fn_Second (X : Real) return Real;
   --  sin x; f' = cos x; f'' = −sin x.

   function Cos_Fn (X : Real) return Real;
   function Cos_Fn_Prime (X : Real) return Real;
   function Cos_Fn_Second (X : Real) return Real;
   --  cos x; f' = −sin x; f'' = −cos x.

   function Exp_Linear (X : Real) return Real;
   function Exp_Linear_Prime (X : Real) return Real;
   function Exp_Linear_Second (X : Real) return Real;
   --  e^x − 2; root ln 2; f' = f'' = e^x.

   function Atan_Shift (X : Real) return Real;
   function Atan_Shift_Prime (X : Real) return Real;
   function Atan_Shift_Second (X : Real) return Real;
   --  arctan(x) − 1/2; f' = 1/(1+x²); f'' = −2x/(1+x²)².

   function Steep_Exp (X : Real) return Real;
   function Steep_Exp_Prime (X : Real) return Real;
   function Steep_Exp_Second (X : Real) return Real;
   --  e^x − e; root 1; f' = f'' = e^x.

   function Cos_Minus_X3 (X : Real) return Real;
   function Cos_Minus_X3_Prime (X : Real) return Real;
   function Cos_Minus_X3_Second (X : Real) return Real;
   --  cos(x) − x³; root ≈ 0.865474; f'' = −cos x − 6x.

   function Flat_Derivative (X : Real) return Real;
   function Flat_Derivative_Prime (X : Real) return Real;
   function Flat_Derivative_Second (X : Real) return Real;
   --  x² − 1; f' = 2x; f'' = 2 — f' zero at x=0 (Degenerate when started there).

   function Constant_One (X : Real) return Real;
   function Constant_One_Prime (X : Real) return Real;
   function Constant_One_Second (X : Real) return Real;
   --  f ≡ 1, f' ≡ 0, f'' ≡ 0 — always Degenerate (no root).

end Halleys_Method;
