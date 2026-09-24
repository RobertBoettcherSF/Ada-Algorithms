--  Newton_Multiplicative_Inverse — Ada 2023 educational package for
--  Wikipedia "Newton's method" § Multiplicative inverses of numbers and
--  power series: Newton–Raphson reciprocal iteration
--    x_{n+1} = x_n (2 − a x_n)
--  (multiply / subtract only), optional division via b · reciprocal(a),
--  and a truncated Newton lift for formal power-series inverses
--  (degree ≤ 8). Educational Long_Float.
--  Primary sources:
--  https://en.wikipedia.org/wiki/Newton's_method#Multiplicative_inverses_of_numbers_and_power_series
--  https://en.wikipedia.org/wiki/Multiplicative_inverse
--  Siblings (README): Ada-Rounding-Functions, Ada-Nth-Root; upcoming
--  Multiplicative inverse Algorithms, Toom–Cook, Schönhage–Strassen,
--  Karatsuba.

pragma Ada_2022;

package Newton_Multiplicative_Inverse
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (educational Long_Float)
   ---------------------------------------------------------------------------

   Default_Tol      : constant Long_Float := 1.0E-12;
   Default_Max_Iter : constant Positive   := 100;

   Epsilon_Tol : constant Long_Float := 1.0E-12;
   Near_Tol    : constant Long_Float := 1.0E-9;

   --  Status of Reciprocal_Newton / Divide_Newton / Series_Inverse_Newton.
   --  Bad_Domain ≡ A = 0 (or series constant term p0 = 0).
   type Status_Kind is
     (Converged,
      Bad_Domain,
      Max_Iterations_Reached);

   type Reciprocal_Result is record
      Value      : Long_Float  := 0.0;
      Iterations : Natural     := 0;
      Status     : Status_Kind := Bad_Domain;
   end record;

   Invalid_Argument : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near
     (A, B : Long_Float; Tol : Long_Float := Near_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Abs_Error (A, B : Long_Float) return Long_Float
     with Global => null;

   --  |Approx − Exact| / |Exact|; if Exact = 0 return |Approx|.
   function Rel_Error (Approx, Exact : Long_Float) return Long_Float
     with Global => null;

   --  Oracle reciprocal: 1.0 / A. Raises Invalid_Argument if A = 0.
   function Exact_Reciprocal (A : Long_Float) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Newton–Raphson reciprocal (scalar)
   ---------------------------------------------------------------------------

   --  Find x = 1/a by Newton on f(x) = 1/x − a:
   --    x_{n+1} = x_n (2 − a x_n)
   --  Initial guess: dyadic scale |a| into [1/2, 1), seed with the classic
   --  linear NR-division approximant (48/17) − (32/17) M, then restore
   --  sign and scale. Does not raise; A = 0 → Status = Bad_Domain.
   function Reciprocal_Newton
     (A        : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Reciprocal_Result
     with Pre => Tol >= 0.0, Global => null;

   --  Convenience: Reciprocal_Newton with defaults; raises Invalid_Argument
   --  if Status ≠ Converged.
   function Reciprocal (A : Long_Float) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Division via reciprocal: b / a = b · (1/a)
   ---------------------------------------------------------------------------

   --  Compute B / A as B * Reciprocal_Newton(A). Value holds the quotient;
   --  Iterations / Status come from the reciprocal solve. A = 0 → Bad_Domain.
   function Divide_Newton
     (B, A     : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Reciprocal_Result
     with Pre => Tol >= 0.0, Global => null;

   --  Convenience; raises Invalid_Argument if not converged (incl. A = 0).
   function Divide (B, A : Long_Float) return Long_Float
     with Global => null;

   ---------------------------------------------------------------------------
   -- Formal power-series inverse (truncated Newton lift, degree ≤ 8)
   ---------------------------------------------------------------------------

   --  For p(t) = p0 + p1 t + … + p_d t^d with p0 ≠ 0, compute q of degree
   --  ≤ d such that (p · q) truncated to degree d equals 1, by iterating
   --  the same Newton map in the truncated series ring:
   --    q ← trunc_d ( q · (2 − p · q) )
   --  starting from q0 = 1/p0. Educational cap Max_Series_Degree = 8.
   Max_Series_Degree : constant := 8;
   subtype Series_Index is Natural range 0 .. Max_Series_Degree;

   type Series_Coeffs is array (Series_Index range <>) of Long_Float;

   type Series_Result is record
      Coeffs     : Series_Coeffs (Series_Index) := [others => 0.0];
      Degree     : Series_Index                 := 0;
      Iterations : Natural                      := 0;
      Status     : Status_Kind                  := Bad_Domain;
   end record;

   --  Invert P(0 .. Degree). Requires P'First = 0 and P'Last ≥ Degree;
   --  only coefficients 0 .. Degree are used. P(0) = 0 → Bad_Domain.
   function Series_Inverse_Newton
     (P        : Series_Coeffs;
      Degree   : Series_Index;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Series_Result
     with Pre => Tol >= 0.0
                 and then P'First = 0
                 and then P'Last >= Degree,
          Global => null;

end Newton_Multiplicative_Inverse;
