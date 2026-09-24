--  Newtons_Method — Ada 2023 educational package for Wikipedia
--  "Newton's method" (Newton–Raphson): open scalar root finder that
--  iterates the tangent-line update
--    x_{n+1} = x_n − f(x_n)/f'(x_n)
--  when f' is nonzero. Quadratic convergence for simple roots under
--  standard smoothness assumptions; may fail near horizontal tangents.
--  Primary source:
--  https://en.wikipedia.org/wiki/Newton%27s_method
--  Sibling: Ada-Newtons-Method-in-Optimization (minimize f via Hessian;
--  different problem). Root-finding siblings: Ridders / Halley / Muller /
--  False-Position / Bisection (README links; some forthcoming).

pragma Ada_2022;

package Newtons_Method
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

   --  Analytic derivative f' : R → R (same access-to-function shape).
   type Derivative_Fn is access function (X : Real) return Real;

   --  Max_Iterations  : hard outer iteration budget
   --  Tol             : stop when |f(x)| ≤ Tol or |Δx| ≤ Tol
   --  Min_Derivative  : |f'| below this → Status = Degenerate
   --  Damping         : step factor λ ∈ (0,1]; λ=1 is classical Newton
   --  Use_Safeguard   : if True, backtrack λ when |f| increases (light)
   type Config is record
      Max_Iterations : Positive      := 100;
      Tol            : Positive_Real := 1.0E-10;
      Min_Derivative : Positive_Real := 1.0E-14;
      Damping        : Positive_Real := 1.0;
      Use_Safeguard  : Boolean       := False;
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

   --  One Newton (optionally damped) step:
   --    X_Next = X − Damping · F_Val / F_Deriv
   --  Raises Invalid_Argument if |F_Deriv| is zero (caller should
   --  normally use Find_Root which returns Degenerate instead).
   function Next_Point
     (X       : Real;
      F_Val   : Real;
      F_Deriv : Real;
      Damping : Positive_Real := 1.0) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- Core algorithm
   ---------------------------------------------------------------------------

   --  Find a root of F starting at X0 by Newton–Raphson.
   --  Requires analytic F_Prime. Tiny |f'| yields Success=False,
   --  Status=Degenerate (does not raise). Null F or F_Prime raises
   --  Invalid_Argument.
   function Find_Root
     (F       : Objective_Fn;
      F_Prime : Derivative_Fn;
      X0      : Real;
      Cfg     : Config := (others => <>)) return Result
     with Pre => F /= null and then F_Prime /= null, Global => null;

   --  Convenience overload with explicit Tol / Max_Iterations
   --  (classical undamped Newton; default Min_Derivative / Damping).
   function Find_Root
     (F              : Objective_Fn;
      F_Prime        : Derivative_Fn;
      X0             : Real;
      Tol            : Positive_Real;
      Max_Iterations : Positive := 100) return Result
     with Pre => F /= null and then F_Prime /= null, Global => null;

   ---------------------------------------------------------------------------
   -- Educational sample objectives + analytic derivatives
   -- (library-level for 'Access in tests)
   ---------------------------------------------------------------------------

   function Poly_Linear (X : Real) return Real;
   function Poly_Linear_Prime (X : Real) return Real;
   --  2x − 4; root at 2; f' = 2.

   function Poly_Quad (X : Real) return Real;
   function Poly_Quad_Prime (X : Real) return Real;
   --  x² − 2; roots ±√2; f' = 2x.

   function Sqrt_Target_A return Real;
   --  Constant a used by Sqrt_Obj (default 612, Wikipedia example).

   function Sqrt_Obj (X : Real) return Real;
   function Sqrt_Obj_Prime (X : Real) return Real;
   --  x² − a; Heron's / Babylonian square-root special case.

   function Poly_Cubic (X : Real) return Real;
   function Poly_Cubic_Prime (X : Real) return Real;
   --  (x−1)(x−2)(x−3) = x³ − 6x² + 11x − 6; roots 1, 2, 3.

   function Poly_Shifted (X : Real) return Real;
   function Poly_Shifted_Prime (X : Real) return Real;
   --  (x−1/2)(x+3); roots 1/2, −3.

   function Cubic_One_Root (X : Real) return Real;
   function Cubic_One_Root_Prime (X : Real) return Real;
   --  x³ − x − 1; unique real root ≈ 1.324717957.

   function Sin_Fn (X : Real) return Real;
   function Sin_Fn_Prime (X : Real) return Real;
   --  sin x; f' = cos x.

   function Cos_Fn (X : Real) return Real;
   function Cos_Fn_Prime (X : Real) return Real;
   --  cos x; f' = −sin x.

   function Exp_Linear (X : Real) return Real;
   function Exp_Linear_Prime (X : Real) return Real;
   --  e^x − 2; root ln 2; f' = e^x.

   function Atan_Shift (X : Real) return Real;
   function Atan_Shift_Prime (X : Real) return Real;
   --  arctan(x) − 1/2; f' = 1/(1+x²).

   function Steep_Exp (X : Real) return Real;
   function Steep_Exp_Prime (X : Real) return Real;
   --  e^x − e; root 1; f' = e^x.

   function Cos_Minus_X3 (X : Real) return Real;
   function Cos_Minus_X3_Prime (X : Real) return Real;
   --  cos(x) − x³; Wikipedia example root ≈ 0.865474.

   function Flat_Derivative (X : Real) return Real;
   function Flat_Derivative_Prime (X : Real) return Real;
   --  x² − 1; f' = 2x — zero at x=0 (Degenerate when started there).

   function Constant_One (X : Real) return Real;
   function Constant_One_Prime (X : Real) return Real;
   --  f ≡ 1, f' ≡ 0 — always Degenerate (no root, zero derivative).

end Newtons_Method;
