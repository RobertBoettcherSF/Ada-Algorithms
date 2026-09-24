--  Frank_Wolfe_Algorithm — Ada 2023 educational package for Wikipedia
--  "Frank–Wolfe algorithm" (conditional gradient): minimize a smooth
--  convex f over a compact convex set D by repeatedly solving a linear
--  minimization oracle (LMO) and taking a convex-combination step toward
--  the LMO vertex. Projection-free; stops on the duality gap.
--  Primary source: https://en.wikipedia.org/wiki/Frank%E2%80%93Wolfe_algorithm
--  Siblings: Ada-Gradient-Descent / Ada-Line-Search / Ada-Simplex-Algorithm
--  (README links).

pragma Ada_2022;

package Frank_Wolfe_Algorithm
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;
   subtype Unit_Interval is Real range 0.0 .. 1.0;

   Max_Dim : constant := 16;
   subtype Dim_Count is Positive range 1 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;

   --  Point / vector in R^n (n ≤ Max_Dim).
   type Point is array (Dim_Index range <>) of Real;
   subtype Vector is Point;

   --  Open_Loop         : γ_k = 2/(k+2) (classic Frank–Wolfe schedule)
   --  Exact_Line_Search : minimize f((1−γ)x + γ s) over γ ∈ [0,1]
   --  Armijo            : backtracking from γ=1 along s−x
   type Step_Mode_Kind is (Open_Loop, Exact_Line_Search, Armijo);

   --  Max_Iterations   : outer Frank–Wolfe iteration budget
   --  Gap_Tol          : stop when duality gap G(x) ≤ Gap_Tol
   --  Step_Tol         : stop when ‖Δx‖ ≤ Step_Tol
   --  Step_Mode        : open-loop / exact segment search / Armijo
   --  Armijo_C         : sufficient-decrease constant c₁ ∈ (0,1)
   --  Line_Search_Rho  : multiply γ by this on each Armijo backtrack
   --  Max_Line_Search  : max Armijo / exact-search evaluations
   --  Exact_Tol        : golden-section tolerance on the segment
   --  Fd_Eps           : finite-difference step for numerical gradient
   type Config is record
      Max_Iterations  : Positive         := 500;
      Gap_Tol         : Non_Negative     := 1.0E-6;
      Step_Tol        : Non_Negative     := 1.0E-12;
      Step_Mode       : Step_Mode_Kind   := Open_Loop;
      Armijo_C        : Positive_Real    := 1.0E-4;
      Line_Search_Rho : Positive_Real    := 0.5;
      Max_Line_Search : Positive         := 40;
      Exact_Tol       : Positive_Real    := 1.0E-10;
      Fd_Eps          : Positive_Real    := 1.0E-7;
   end record;

   Default_Config : constant Config := (others => <>);

   type Result is record
      Final_Point : Point (1 .. Max_Dim) := [others => 0.0];
      Final_Value : Real         := 0.0;
      Final_Gap   : Non_Negative := 0.0;
      Dim         : Dim_Count    := 1;
      Iterations  : Natural      := 0;
      Success     : Boolean      := False;
   end record;

   --  Smooth objective f : R^n → R (evaluated on D).
   type Objective_Fn is access function (X : Point) return Real;

   --  Optional analytical gradient ∇f.
   type Grad_Fn is access function (X : Point) return Point;

   --  Linear minimization oracle: s ∈ argmin_{z ∈ D} ⟨g, z⟩.
   type LMO_Fn is access function (G : Point) return Point;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument   : exception;
   Line_Search_Failed : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Point_Near
     (A, B : Point; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   function Norm2 (X : Point) return Non_Negative
     with Global => null;

   function Dot (A, B : Point) return Real
     with Pre => A'Length = B'Length, Global => null;

   function Add (A, B : Point) return Point
     with Pre => A'Length = B'Length, Global => null;

   function Sub (A, B : Point) return Point
     with Pre => A'Length = B'Length, Global => null;

   function Scale (C : Real; X : Point) return Point
     with Global => null;

   function Convex_Combination
     (Gamma : Unit_Interval; X, S : Point) return Point
     with Pre => X'Length = S'Length, Global => null;
   --  (1−γ) x + γ s.

   ---------------------------------------------------------------------------
   -- Core primitives (exposed for unit tests)
   ---------------------------------------------------------------------------

   function Finite_Difference_Gradient
     (Obj : Objective_Fn;
      X   : Point;
      Eps : Positive_Real := 1.0E-7) return Point
     with Pre => Obj /= null and then X'Length >= 1, Global => null;
   --  Central finite-difference gradient (2n evaluations).

   function Open_Loop_Step (K : Natural) return Unit_Interval
     with Global => null;
   --  γ_k = 2 / (k + 2).

   function Duality_Gap (Grad, X, S : Point) return Non_Negative
     with Pre => Grad'Length = X'Length and then X'Length = S'Length,
          Global => null;
   --  G(x) = ⟨∇f(x), x − s⟩ with s = LMO(∇f(x)).

   function Duality_Gap
     (Grad : Point; X : Point; LMO : LMO_Fn) return Non_Negative
     with Pre => Grad'Length = X'Length and then LMO /= null,
          Global => null;

   function Armijo_Accept
     (F_New, F_Old, Gamma, C1, Dir_Deriv : Real) return Boolean
     with Global => null;
   --  True iff F_New ≤ F_Old + C1·γ·Dir_Deriv (Dir_Deriv = ⟨g, s−x⟩).

   function Exact_Line_Search
     (Obj      : Objective_Fn;
      X, S     : Point;
      Tol      : Positive_Real;
      Max_Evals : Positive) return Unit_Interval
     with Pre => Obj /= null and then X'Length = S'Length, Global => null;
   --  Golden-section minimization of φ(γ)=f((1−γ)x+γ s) on [0,1].

   function Armijo_Line_Search
     (Obj    : Objective_Fn;
      X, S   : Point;
      F, Dir_Deriv : Real;
      C1     : Positive_Real;
      Rho    : Positive_Real;
      Max_LS : Positive) return Unit_Interval
     with Pre => Obj /= null
            and then X'Length = S'Length
            and then C1 < 1.0
            and then Rho < 1.0,
          Global => null;
   --  Armijo backtracking from γ=1 along s−x.
   --  Raises Line_Search_Failed if no γ accepted within Max_LS tries.

   ---------------------------------------------------------------------------
   -- Linear minimization oracles
   ---------------------------------------------------------------------------

   function LMO_Simplex (G : Point) return Point
     with Pre => G'Length >= 1, Global => null;
   --  Probability simplex Δ^{n−1}: s = e_{i*} with i* = argmin_i g_i.

   function LMO_Box (G, Lower, Upper : Point) return Point
     with Pre => G'Length = Lower'Length
            and then Lower'Length = Upper'Length
            and then G'Length >= 1,
          Global => null;
   --  Axis-aligned box [L,U]^n: s_i = L_i if g_i > 0 else U_i.

   function LMO_L1_Ball
     (G : Point; Radius : Non_Negative := 1.0) return Point
     with Pre => G'Length >= 1, Global => null;
   --  ℓ₁ ball of radius R: s = −R · sign(g_{i*}) e_{i*} (i* = argmax |g_i|).
   --  If G = 0, returns the origin.

   --  Package-level adapters so LMO_Box / LMO_L1_Ball can be passed as LMO_Fn
   --  (access-to-subprogram cannot point at nested test wrappers).
   procedure Set_Box_Bounds (Lower, Upper : Point)
     with Pre => Lower'Length = Upper'Length
            and then Lower'Length >= 1
            and then Lower'Length <= Max_Dim;

   function Active_Box_LMO (G : Point) return Point
     with Pre => G'Length >= 1;

   procedure Set_L1_Radius (Radius : Non_Negative);

   function Active_L1_LMO (G : Point) return Point
     with Pre => G'Length >= 1;

   ---------------------------------------------------------------------------
   -- Built-in demo objectives (+ analytical gradients)
   ---------------------------------------------------------------------------

   function Sphere (X : Point) return Real
     with Global => null;
   --  f(x) = Σ x_i²; unconstrained min 0 at the origin.

   function Sphere_Grad (X : Point) return Point
     with Global => null;
   --  ∇f = 2x.

   function Shifted_Quadratic (X : Point) return Real
     with Global => null;
   --  f(x) = ½ Σ (x_i − t_i)² with t_i = 1/n (unconstrained min at uniform).
   --  On the simplex the uniform barycenter is feasible and optimal.

   function Shifted_Quadratic_Grad (X : Point) return Point
     with Global => null;

   function Weighted_Quadratic (X : Point) return Real
     with Global => null;
   --  f(x) = ½ Σ i · x_i²  (positive-definite bowl; prefers small indices).

   function Weighted_Quadratic_Grad (X : Point) return Point
     with Global => null;

   function Linear_Ones (X : Point) return Real
     with Global => null;
   --  f(x) = Σ x_i; ∇f = (1,…,1). Useful over a box / ℓ₁ ball.

   function Linear_Ones_Grad (X : Point) return Point
     with Global => null;

   ---------------------------------------------------------------------------
   -- Driver
   ---------------------------------------------------------------------------

   function Minimize
     (Objective : Objective_Fn;
      X0        : Point;
      LMO       : LMO_Fn;
      Grad      : Grad_Fn := null;
      Cfg       : Config := Default_Config) return Result
     with Pre => Objective /= null
            and then LMO /= null
            and then X0'Length >= 1
            and then X0'Length <= Max_Dim,
          Global => null;
   --  Frank–Wolfe / conditional gradient. Grad null → central FD.
   --  Success when duality gap ≤ Gap_Tol (or ‖Δx‖ ≤ Step_Tol).

end Frank_Wolfe_Algorithm;
