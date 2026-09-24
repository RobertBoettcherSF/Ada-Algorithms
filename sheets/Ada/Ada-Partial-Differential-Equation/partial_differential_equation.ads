--  Partial_Differential_Equation — Ada 2023 educational survey package for
--  Wikipedia "Partial differential equation": taxonomy (elliptic /
--  parabolic / hyperbolic / degenerate) plus thin self-contained 1D
--  sketches (Poisson+Thomas, FTCS heat, upwind advection / leapfrog wave).
--  Sibling packages (Finite Difference Method, Crank–Nicolson,
--  Lax–Wendroff, upcoming Multigrid) are linked in the README only —
--  this repo does not `with` them.
--  Primary source:
--  https://en.wikipedia.org/wiki/Partial_differential_equation

pragma Ada_2022;

package Partial_Differential_Equation
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
   --  Raised for H ≤ 0, Dt ≤ 0, Alpha < 0, c < 0 (upwind), empty /
   --  too-short grids, FTCS / CFL violations, degenerate Thomas pivot,
   --  or mismatched lengths.

   Epsilon_Tol     : constant Real := 1.0E-10;
   Pivot_Tol       : constant Real := 1.0E-12;
   Discriminant_Tol : constant Real := 1.0E-12;
   --  |B² − A·C| ≤ Discriminant_Tol counts as parabolic (near-zero).

   ---------------------------------------------------------------------------
   -- Taxonomy (second-order linear PDE in two variables)
   ---------------------------------------------------------------------------

   --  For A u_xx + 2 B u_xy + C u_yy + lower-order = 0, classify by
   --  discriminant Δ = B² − A·C:
   --    Δ < 0 → Elliptic,  Δ = 0 → Parabolic,  Δ > 0 → Hyperbolic.
   --  If A = B = C = 0 the principal part vanishes → Degenerate.
   type PDE_Class is (Elliptic, Parabolic, Hyperbolic, Degenerate);

   function Classify_2nd_Order (A, B, C : Real) return PDE_Class
     with Global => null;

   function Class_Name (C : PDE_Class) return String
     with Global => null;

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
   -- Elliptic sketch: 1D Poisson −u'' = g (Dirichlet + Thomas)
   ---------------------------------------------------------------------------

   --  G holds the RHS at N interior nodes (N = G'Length ≥ 1).
   --  Returns length N+2 with U(1)=Left, U(N+2)=Right, interior solved.
   --  Embedded Thomas (TDMA); no sibling `with`.
   --  Raises Invalid_Argument if H ≤ 0, G empty, N+2 > Max_Points,
   --  or a Thomas pivot is degenerate.
   function Solve_Poisson_1D
     (G     : Grid;
      Left  : Real;
      Right : Real;
      H     : Real) return Grid
     with Global => null;

   ---------------------------------------------------------------------------
   -- Parabolic sketch: FTCS heat  u_t = α u_xx
   ---------------------------------------------------------------------------

   --  True iff α ≥ 0, H > 0, Dt > 0 and r = α Δt / H² ≤ 1/2.
   function Heat_FTCS_Stable (Alpha, H, Dt : Real) return Boolean
     with Global => null;

   --  One Forward-Time Central-Space step. Dirichlet ends set to
   --  Left / Right. Stability requires r = α Δt / H² ≤ 1/2.
   --  Raises Invalid_Argument if H ≤ 0, Dt ≤ 0, Alpha < 0, U'Length < 3,
   --  or not Heat_FTCS_Stable.
   function Heat_FTCS_Step
     (U           : Grid;
      Alpha, H, Dt : Real;
      Left, Right : Real) return Grid
     with Global => null;

   ---------------------------------------------------------------------------
   -- Hyperbolic sketches: upwind advection / leapfrog wave
   ---------------------------------------------------------------------------

   --  Courant number ν = C · Dt / H for advection (C ≥ 0 upwind).
   --  Raises Invalid_Argument if H ≤ 0 or Dt ≤ 0.
   function CFL_Advection (C, H, Dt : Real) return Real
     with Global => null;

   --  Courant number λ = |C| · Dt / H for the wave equation.
   --  Raises Invalid_Argument if H ≤ 0 or Dt ≤ 0.
   function CFL_Wave (C, H, Dt : Real) return Real
     with Global => null;

   --  One first-order upwind step for u_t + C u_x = 0 with C ≥ 0
   --  (backward difference). U(1) is the inflow Dirichlet value and
   --  is copied unchanged; interiors use the upwind stencil.
   --  Requires ν = C Δt / H ≤ 1. Raises Invalid_Argument if C < 0,
   --  H ≤ 0, Dt ≤ 0, U'Length < 2, or CFL violated.
   function Advection_Upwind_Step
     (U        : Grid;
      C, H, Dt : Real) return Grid
     with Global => null;

   --  One leapfrog step for u_tt = C² u_xx:
   --    U_Next = 2 U_Curr − U_Prev + λ² (U_{j−1} − 2 U_j + U_{j+1})
   --  with λ = C Δt / H. Dirichlet ends set to Left / Right.
   --  Requires |λ| ≤ 1 and matching lengths. Raises Invalid_Argument
   --  on bad geometry, length mismatch, Length < 3, or CFL violation.
   function Wave_Leapfrog_Step
     (U_Curr, U_Prev : Grid;
      C, H, Dt       : Real;
      Left, Right    : Real) return Grid
     with Global => null;

end Partial_Differential_Equation;
