--  Linear_Multistep_Methods — Ada 2023 educational package for Wikipedia
--  "Linear multistep method": k-step schemes for the scalar IVP
--    y' = f(t, y)
--  of the form
--    Σ_{j=0}^{k} α_j y_{n+j} = h Σ_{j=0}^{k} β_j f(t_{n+j}, y_{n+j}).
--  Explicit when β_k = 0 (Adams–Bashforth); implicit when β_k ≠ 0
--  (Adams–Moulton, BDF). Catalogue covers AB2–AB4, AM2 (trapezoid),
--  AM3, BDF1 (backward Euler), and BDF2, plus bootstrap Advance_*
--  helpers and a light zero-stability / root-condition check.
--  Primary source:
--  https://en.wikipedia.org/wiki/Linear_multistep_method

pragma Ada_2022;

package Linear_Multistep_Methods
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Educational Long_Float-precision real (digits 15).
   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Right-hand side f(t, y) of the scalar IVP y' = f(t, y).
   type ODE_Fn is access function (T, Y : Real) return Real;

   --  Optional analytic ∂f/∂y for Newton on implicit steps.
   type Partial_Y_Fn is access function (T, Y : Real) return Real;

   --  Dense history of past values (Y or F). Index 1 = most recent
   --  (time level n), Index 2 = n−1, Index 3 = n−2, …
   type History is array (Positive range <>) of Real;

   ---------------------------------------------------------------------------
   -- Method catalogue / taxonomy
   ---------------------------------------------------------------------------

   type Method_Kind is
     (AB2, AB3, AB4,
      AM2_Trapezoid, AM3,
      BDF1, BDF2);

   function Method_Name (M : Method_Kind) return String
     with Global => null;

   function Is_Explicit (M : Method_Kind) return Boolean
     with Global => null;

   function Is_Implicit (M : Method_Kind) return Boolean
     with Global => null;

   function Order (M : Method_Kind) return Positive
     with Global => null;

   --  Number of steps k in the linear multistep formula.
   function Step_Number (M : Method_Kind) return Positive
     with Global => null;

   ---------------------------------------------------------------------------
   -- Nonlinear solver config (implicit methods)
   ---------------------------------------------------------------------------

   type Solver_Kind is (Fixed_Point, Newton);

   type Config is record
      Max_Iterations : Positive      := 50;
      Tol            : Positive_Real := 1.0E-12;
      Solver         : Solver_Kind   := Newton;
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument : exception;
   --  Raised for null F, H ≤ 0, bad interval, inconsistent history
   --  lengths, or failed nonlinear convergence on an implicit step.

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  |A − B| ≤ Tol.

   function Abs_Error (Approx, Exact : Real) return Non_Negative
     with Global => null;
   --  |Approx − Exact|.

   --  Exact solution of y' = λ y, y(0) = Y0:  Y0 · e^{λ T}.
   function Exact_Exponential
     (Lambda, T : Real;
      Y0        : Real := 1.0) return Real
     with Global => null;

   ---------------------------------------------------------------------------
   -- Classic coefficients (β for AB/AM; α/β for BDF)
   -- Convention for Adams: y_{n+1} = y_n + h Σ β_j f_{n+1-j}
   -- (β_0 multiplies the newest slope that is known / unknown).
   ---------------------------------------------------------------------------

   --  AB2: β = (3/2, −1/2) for (f_n, f_{n−1}); β_{new}=0 (explicit).
   AB2_Beta_N   : constant Real :=  3.0 / 2.0;
   AB2_Beta_Nm1 : constant Real := -1.0 / 2.0;

   --  AB3: β = (23/12, −16/12, 5/12) for (f_n, f_{n−1}, f_{n−2}).
   AB3_Beta_N   : constant Real :=  23.0 / 12.0;
   AB3_Beta_Nm1 : constant Real := -16.0 / 12.0;
   AB3_Beta_Nm2 : constant Real :=   5.0 / 12.0;

   --  AB4: β = (55/24, −59/24, 37/24, −9/24).
   AB4_Beta_N   : constant Real :=  55.0 / 24.0;
   AB4_Beta_Nm1 : constant Real := -59.0 / 24.0;
   AB4_Beta_Nm2 : constant Real :=  37.0 / 24.0;
   AB4_Beta_Nm3 : constant Real :=  -9.0 / 24.0;

   --  AM2 / trapezoid: y_{n+1} = y_n + (h/2)(f_{n+1} + f_n).
   AM2_Beta_Np1 : constant Real := 1.0 / 2.0;
   AM2_Beta_N   : constant Real := 1.0 / 2.0;

   --  AM3 (2-step Adams–Moulton, order 3):
   --    y_{n+1} = y_n + h (5/12 f_{n+1} + 8/12 f_n − 1/12 f_{n−1}).
   AM3_Beta_Np1 : constant Real :=  5.0 / 12.0;
   AM3_Beta_N   : constant Real :=  8.0 / 12.0;
   AM3_Beta_Nm1 : constant Real := -1.0 / 12.0;

   --  BDF1 (backward Euler): y_{n+1} − y_n = h f_{n+1}.
   BDF1_Alpha_Np1 : constant Real :=  1.0;
   BDF1_Alpha_N   : constant Real := -1.0;
   BDF1_Beta_Np1  : constant Real :=  1.0;

   --  BDF2: (3/2) y_{n+1} − 2 y_n + (1/2) y_{n−1} = h f_{n+1}
   --  equivalently y_{n+1} = (4/3) y_n − (1/3) y_{n−1} + (2/3) h f_{n+1}.
   BDF2_Alpha_Np1 : constant Real :=  3.0 / 2.0;
   BDF2_Alpha_N   : constant Real := -2.0;
   BDF2_Alpha_Nm1 : constant Real :=  1.0 / 2.0;
   BDF2_Beta_Np1  : constant Real :=  1.0;

   ---------------------------------------------------------------------------
   -- Explicit Adams–Bashforth one-step advances
   -- F_Hist(1)=f_n, F_Hist(2)=f_{n−1}, …  (length = k for ABk)
   ---------------------------------------------------------------------------

   --  AB2: y_{n+1} = y_n + h (3/2 f_n − 1/2 f_{n−1}).
   --  Computes f_n = F(T,Y) and uses F_Prev = f_{n−1}.
   function Adams_Bashforth_2_Step
     (F      : ODE_Fn;
      T      : Real;
      Y      : Real;
      F_Prev : Real;
      H      : Real) return Real
     with Pre => F /= null, Global => null;

   --  AB3: needs F_Hist length 2 = (f_{n−1}, f_{n−2}); f_n from F(T,Y).
   --  Or pass full F_Hist length 3 = (f_n, f_{n−1}, f_{n−2}) via overload.
   function Adams_Bashforth_3_Step
     (F      : ODE_Fn;
      T      : Real;
      Y      : Real;
      F_Hist : History;
      H      : Real) return Real
     with Pre => F /= null, Global => null;
   --  F_Hist must have length 2 (prev slopes) or 3 (incl. f_n).

   function Adams_Bashforth_4_Step
     (F      : ODE_Fn;
      T      : Real;
      Y      : Real;
      F_Hist : History;
      H      : Real) return Real
     with Pre => F /= null, Global => null;
   --  F_Hist length 3 (prev) or 4 (incl. f_n).

   ---------------------------------------------------------------------------
   -- Implicit Adams–Moulton / BDF one-step advances
   ---------------------------------------------------------------------------

   --  AM2 trapezoidal / Crank–Nicolson scalar step:
   --    y_{n+1} = y_n + (h/2)(f(t_n+h,y_{n+1}) + f(t_n,y_n)).
   function Adams_Moulton_2_Step
     (F     : ODE_Fn;
      T     : Real;
      Y     : Real;
      H     : Real;
      Cfg   : Config       := (others => <>);
      DF_DY : Partial_Y_Fn := null) return Real
     with Pre => F /= null, Global => null;

   --  AM3: y_{n+1} = y_n + h (5/12 f_{n+1} + 8/12 f_n − 1/12 f_{n−1}).
   --  F_Prev = f_{n−1}; f_n computed from F(T,Y).
   function Adams_Moulton_3_Step
     (F      : ODE_Fn;
      T      : Real;
      Y      : Real;
      F_Prev : Real;
      H      : Real;
      Cfg    : Config       := (others => <>);
      DF_DY  : Partial_Y_Fn := null) return Real
     with Pre => F /= null, Global => null;

   --  BDF1 = backward Euler: y_{n+1} = y_n + h f(t_n+h, y_{n+1}).
   function BDF1_Step
     (F     : ODE_Fn;
      T     : Real;
      Y     : Real;
      H     : Real;
      Cfg   : Config       := (others => <>);
      DF_DY : Partial_Y_Fn := null) return Real
     with Pre => F /= null, Global => null;

   --  BDF2: y_{n+1} = (4/3) y_n − (1/3) y_{n−1} + (2/3) h f(t_n+h,y_{n+1}).
   --  Y_Prev = y_{n−1}.
   function BDF2_Step
     (F      : ODE_Fn;
      T      : Real;
      Y      : Real;
      Y_Prev : Real;
      H      : Real;
      Cfg    : Config       := (others => <>);
      DF_DY  : Partial_Y_Fn := null) return Real
     with Pre => F /= null, Global => null;

   ---------------------------------------------------------------------------
   -- Interval Advance_* helpers (bootstrap first k−1 steps with RK4,
   -- then apply the multistep formula). Documented bootstrap.
   ---------------------------------------------------------------------------

   function Advance_AB2
     (F  : ODE_Fn;
      T0 : Real;
      Y0 : Real;
      T1 : Real;
      N  : Positive) return Real
     with Pre => F /= null, Global => null;

   function Advance_AB3
     (F  : ODE_Fn;
      T0 : Real;
      Y0 : Real;
      T1 : Real;
      N  : Positive) return Real
     with Pre => F /= null, Global => null;

   function Advance_AB4
     (F  : ODE_Fn;
      T0 : Real;
      Y0 : Real;
      T1 : Real;
      N  : Positive) return Real
     with Pre => F /= null, Global => null;

   function Advance_AM2
     (F     : ODE_Fn;
      T0    : Real;
      Y0    : Real;
      T1    : Real;
      N     : Positive;
      Cfg   : Config       := (others => <>);
      DF_DY : Partial_Y_Fn := null) return Real
     with Pre => F /= null, Global => null;

   function Advance_AM3
     (F     : ODE_Fn;
      T0    : Real;
      Y0    : Real;
      T1    : Real;
      N     : Positive;
      Cfg   : Config       := (others => <>);
      DF_DY : Partial_Y_Fn := null) return Real
     with Pre => F /= null, Global => null;

   function Advance_BDF1
     (F     : ODE_Fn;
      T0    : Real;
      Y0    : Real;
      T1    : Real;
      N     : Positive;
      Cfg   : Config       := (others => <>);
      DF_DY : Partial_Y_Fn := null) return Real
     with Pre => F /= null, Global => null;

   function Advance_BDF2
     (F     : ODE_Fn;
      T0    : Real;
      Y0    : Real;
      T1    : Real;
      N     : Positive;
      Cfg   : Config       := (others => <>);
      DF_DY : Partial_Y_Fn := null) return Real
     with Pre => F /= null, Global => null;

   ---------------------------------------------------------------------------
   -- Zero-stability / root condition (educational, light)
   ---------------------------------------------------------------------------

   --  True when the first characteristic polynomial ρ of M satisfies the
   --  root condition (all roots |ζ| ≤ 1, roots on the unit circle simple).
   --  For degree-2 methods the roots are computed exactly; higher-order
   --  catalogue entries return the known textbook result (all zero-stable).
   function Characteristic_Polynomial_Roots_OK
     (M : Method_Kind) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Educational sample ODEs (library-level for 'Access in tests)
   ---------------------------------------------------------------------------

   function F_Decay (T, Y : Real) return Real;
   function F_Growth (T, Y : Real) return Real;
   function F_Decay_2 (T, Y : Real) return Real;
   function F_Stiff (T, Y : Real) return Real;
   function F_Logistic (T, Y : Real) return Real;

   --  Analytic ∂f/∂y companions for Newton demos.
   function DF_Decay (T, Y : Real) return Real;
   function DF_Growth (T, Y : Real) return Real;
   function DF_Decay_2 (T, Y : Real) return Real;
   function DF_Stiff (T, Y : Real) return Real;
   function DF_Logistic (T, Y : Real) return Real;

end Linear_Multistep_Methods;
