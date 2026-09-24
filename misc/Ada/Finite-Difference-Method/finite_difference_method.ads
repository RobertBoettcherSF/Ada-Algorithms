--  Finite_Difference_Method — Ada 2023 educational package for Wikipedia
--  "Finite difference method": approximate derivatives on a uniform grid
--  and discretize simple 1D BVPs / parabolic steps.
--  Classroom focus:
--    • forward / backward / central first derivatives
--    • central second derivative
--    • 1D Poisson −u'' = g with Dirichlet BCs (tridiagonal + Thomas)
--    • optional FTCS heat step with stability r ≤ 1/2
--  Primary source:
--  https://en.wikipedia.org/wiki/Finite_difference_method

pragma Ada_2022;

package Finite_Difference_Method
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Long_Float-class Real, digits 15)
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Points : constant Positive := 512;

   subtype Point_Count is Positive range 1 .. Max_Points;
   subtype Point_Index is Positive range 1 .. Max_Points;

   --  1D samples on a uniform grid (1-based).
   type Grid is array (Positive range <>) of Real;

   Invalid_Argument : exception;
   --  Raised for H ≤ 0, empty / too-short grids, r > 1/2 (FTCS),
   --  degenerate Thomas pivot, or mismatched lengths.

   Epsilon_Tol : constant Real := 1.0E-10;
   Pivot_Tol   : constant Real := 1.0E-12;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Abs_Error (Approx, Exact : Real) return Non_Negative
     with Global => null;

   function Vec_Near
     (A, B : Grid; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   --  Discrete L² error: sqrt(H · Σ (U − Exact)²).
   function L2_Error
     (U, Exact : Grid; H : Real) return Non_Negative
     with Pre => U'Length = Exact'Length
            and then U'Length >= 1
            and then H > 0.0,
          Global => null;

   --  Max-norm error max_j |U_j − Exact_j|.
   function Max_Error (U, Exact : Grid) return Non_Negative
     with Pre => U'Length = Exact'Length and then U'Length >= 1,
          Global => null;

   ---------------------------------------------------------------------------
   -- Grid geometry helpers
   ---------------------------------------------------------------------------

   --  Abscissa X_Min + (J − 1)·H (1-based index J).
   function X_At (X_Min, H : Real; J : Positive) return Real
     with Pre => H > 0.0, Global => null;

   --  Sample analytic F at X_Min + (j−1)·H for j = 1 .. N.
   generic
      with function F (X : Real) return Real;
   function Sample
     (N     : Point_Count;
      H     : Real;
      X_Min : Real := 0.0) return Grid;

   ---------------------------------------------------------------------------
   -- First-derivative finite differences
   ---------------------------------------------------------------------------

   --  Forward: f'(x_i) ≈ (f(x_i+H) − f(x_i)) / H
   --  Result length = F'Length − 1; Result(k) at F'First + k − 1.
   --  Raises Invalid_Argument if H ≤ 0 or F'Length < 2.
   function Diff_Forward (F : Grid; H : Real) return Grid
     with Global => null;

   --  Backward: f'(x_i) ≈ (f(x_i) − f(x_i−H)) / H
   --  Result length = F'Length − 1; Result(k) at F'First + k
   --  (i.e. the right endpoint of each consecutive pair).
   --  Raises Invalid_Argument if H ≤ 0 or F'Length < 2.
   function Diff_Backward (F : Grid; H : Real) return Grid
     with Global => null;

   --  Central: f'(x_i) ≈ (f(x_i+H) − f(x_i−H)) / (2H)
   --  Result length = F'Length − 2; Result(k) at interior F'First + k.
   --  Raises Invalid_Argument if H ≤ 0 or F'Length < 3.
   function Diff_Central (F : Grid; H : Real) return Grid
     with Global => null;

   ---------------------------------------------------------------------------
   -- Second-derivative central stencil
   ---------------------------------------------------------------------------

   --  f''(x_i) ≈ (f(x_i+H) − 2 f(x_i) + f(x_i−H)) / H²
   --  Result length = F'Length − 2; interior points.
   --  Raises Invalid_Argument if H ≤ 0 or F'Length < 3.
   function Diff2_Central (F : Grid; H : Real) return Grid
     with Global => null;

   ---------------------------------------------------------------------------
   -- 1D Poisson −u'' = g with Dirichlet BCs
   ---------------------------------------------------------------------------

   --  Discretize −u'' = g on a uniform mesh with spacing H.
   --  G holds the RHS at the N interior nodes (N = G'Length ≥ 1).
   --  Unknowns u_1 .. u_N satisfy the tridiagonal system
   --    (−u_{j−1} + 2 u_j − u_{j+1}) / H² = g_j
   --  with u_0 = U_Left, u_{N+1} = U_Right folded into the RHS.
   --  Returns the full discrete solution of length N+2:
   --    U(1) = U_Left, U(2 .. N+1) = interior, U(N+2) = U_Right.
   --  Solved by the Thomas (TDMA) algorithm (embedded; no external with).
   --  Raises Invalid_Argument if H ≤ 0, G empty, N+2 > Max_Points,
   --  or a Thomas pivot is degenerate.
   function Solve_Poisson_1D
     (G       : Grid;
      H       : Real;
      U_Left  : Real := 0.0;
      U_Right : Real := 0.0) return Grid
     with Global => null;

   ---------------------------------------------------------------------------
   -- Explicit FTCS heat step  u_t = κ u_xx
   ---------------------------------------------------------------------------

   --  One Forward-Time Central-Space step on a grid that includes
   --  Dirichlet endpoints (those entries are copied unchanged):
   --    u_j^{n+1} = u_j^n + R (u_{j−1}^n − 2 u_j^n + u_{j+1}^n)
   --  where R = κ Δt / H². Stability requires R ≤ 1/2.
   --  Raises Invalid_Argument if R < 0, R > 1/2, or U'Length < 3.
   function Heat_FTCS_Step (U : Grid; R : Real) return Grid
     with Global => null;

   --  True iff 0 ≤ R ≤ 1/2 (FTCS stability region, inclusive).
   function FTCS_Stable (R : Real) return Boolean
     with Global => null;

end Finite_Difference_Method;
