--  Multigrid_Methods — Ada 2023 educational package for Wikipedia
--  "Multigrid method": geometric multigrid for 1D Poisson −u'' = f
--  on a uniform hierarchy (H = 2h).
--  Classroom focus:
--    • discrete 1D Poisson operator (−1, 2, −1)/H²
--    • weighted Jacobi / Gauss–Seidel smoothers
--    • restriction (injection / full-weighting) and linear prolongation
--    • two-grid V-cycle and recursive geometric V-cycle
--    • coarsest solve via embedded Thomas (TDMA)
--  Primary source:
--  https://en.wikipedia.org/wiki/Multigrid_method

pragma Ada_2022;

package Multigrid_Methods
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Long_Float-class Real, digits 15)
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Power-of-two friendly cap: 2^8 + 1 points including Dirichlet ends.
   Max_Points : constant Positive := 257;

   subtype Point_Count is Positive range 1 .. Max_Points;
   subtype Point_Index is Positive range 1 .. Max_Points;

   --  1D samples on a uniform grid (1-based), including Dirichlet ends.
   type Grid is array (Positive range <>) of Real;

   Invalid_Argument : exception;
   --  Raised for H ≤ 0, grids shorter than 3, non-compatible fine/coarse
   --  sizes, Nu / Level out of range, Omega ≤ 0, Max_Points overflow,
   --  degenerate Thomas pivot, or mismatched lengths.

   Epsilon_Tol : constant Real := 1.0E-10;
   Pivot_Tol   : constant Real := 1.0E-12;

   --  Classic 1D weighted-Jacobi damping for the (−1,2,−1) stencil.
   Default_Omega : constant Real := 2.0 / 3.0;

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

   --  Discrete residual L² on interiors: sqrt(H · Σ (F − A U)²).
   function Residual_L2 (U, F : Grid; H : Real) return Non_Negative
     with Global => null;

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

   --  Coarse length for geometric H = 2h: (Fine_N − 1)/2 + 1.
   --  Raises Invalid_Argument if Fine_N < 3 or Fine_N − 1 is odd.
   function Coarse_Length (Fine_N : Positive) return Positive
     with Global => null;

   --  True iff Fine_N ≥ 3, Fine_N − 1 even, and Coarse_N = Coarse_Length.
   function Compatible_Sizes (Fine_N, Coarse_N : Positive) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Discrete 1D Poisson operator  A u = (−u_{j−1} + 2 u_j − u_{j+1}) / H²
   ---------------------------------------------------------------------------

   --  Apply A on a full grid (Dirichlet ends included). Result has the same
   --  length; endpoints are set to 0.0 (residual-friendly); interiors use
   --  the standard second-difference stencil.
   --  Raises Invalid_Argument if H ≤ 0 or U'Length < 3.
   function Apply_Poisson_1D (U : Grid; H : Real) return Grid
     with Global => null;

   ---------------------------------------------------------------------------
   -- Smoothers for −u'' = f with Dirichlet BCs held fixed
   ---------------------------------------------------------------------------

   --  ν sweeps of weighted Jacobi with weight Omega (default 2/3).
   --  Endpoints of U are left unchanged. F is the full-grid RHS
   --  (endpoints unused). Raises Invalid_Argument if H ≤ 0, Omega ≤ 0,
   --  lengths mismatch, or U'Length < 3.
   procedure Smooth_Jacobi
     (U     : in out Grid;
      F     : Grid;
      H     : Real;
      Nu    : Natural;
      Omega : Real := Default_Omega)
     with Global => null;

   --  ν sweeps of Gauss–Seidel (lexicographic left→right).
   --  Raises Invalid_Argument if H ≤ 0, lengths mismatch, or U'Length < 3.
   procedure Smooth_Gauss_Seidel
     (U  : in out Grid;
      F  : Grid;
      H  : Real;
      Nu : Natural)
     with Global => null;

   ---------------------------------------------------------------------------
   -- Intergrid transfers (geometric H = 2h)
   ---------------------------------------------------------------------------

   --  Injection: Coarse(j) ← Fine(2j−1). Ends map to ends.
   --  Raises Invalid_Argument if sizes are incompatible.
   function Restrict_Injection (Fine : Grid) return Grid
     with Global => null;

   --  Full-weighting 1-2-1: interiors
   --    Coarse(j) = (Fine(2j−2) + 2 Fine(2j−1) + Fine(2j)) / 4;
   --  ends copied. Raises Invalid_Argument if sizes are incompatible.
   function Restrict_Full_Weighting (Fine : Grid) return Grid
     with Global => null;

   --  Linear prolongation: odd fine nodes ← coarse; even ← average.
   --  Raises Invalid_Argument if sizes are incompatible.
   function Prolong_Linear (Coarse : Grid; Fine_N : Positive) return Grid
     with Global => null;

   ---------------------------------------------------------------------------
   -- Coarsest direct solve (embedded Thomas)
   ---------------------------------------------------------------------------

   --  Solve A U = F on a full grid of length ≥ 3 with Dirichlet
   --  U(1)=U_Left, U(N)=U_Right. Interior RHS taken from F(2 .. N−1).
   --  Embedded Thomas (TDMA); no sibling `with`.
   --  Raises Invalid_Argument if H ≤ 0, F'Length < 3, F'Length > Max_Points,
   --  or a Thomas pivot is degenerate.
   function Solve_Coarse_Thomas
     (F       : Grid;
      H       : Real;
      U_Left  : Real := 0.0;
      U_Right : Real := 0.0) return Grid
     with Global => null;

   ---------------------------------------------------------------------------
   -- Two-grid and V-cycle
   ---------------------------------------------------------------------------

   --  One two-grid V-cycle: pre-smooth → restrict residual (full weighting)
   --  → Thomas on coarse → prolong + correct → post-smooth.
   --  Uses weighted Jacobi unless Use_Gauss_Seidel is True.
   --  Raises Invalid_Argument on bad H / sizes / Omega.
   procedure Two_Grid_V_Cycle
     (U                : in out Grid;
      F                : Grid;
      H                : Real;
      Nu_1             : Natural := 2;
      Nu_2             : Natural := 2;
      Omega            : Real := Default_Omega;
      Use_Gauss_Seidel : Boolean := False)
     with Global => null;

   --  Recursive geometric V-cycle. Level is the remaining coarsening
   --  depth: when Level = 0 or the grid has ≤ 3 points, solve with
   --  Thomas; otherwise pre-smooth, restrict, recurse at Level−1 with
   --  spacing 2H, prolong+correct, post-smooth.
   --  Raises Invalid_Argument on bad H / sizes / Omega / Level overflow.
   procedure V_Cycle
     (U                : in out Grid;
      F                : Grid;
      H                : Real;
      Level            : Natural;
      Nu_1             : Natural := 2;
      Nu_2             : Natural := 2;
      Omega            : Real := Default_Omega;
      Use_Gauss_Seidel : Boolean := False)
     with Global => null;

   --  Convenience wrapper: start from zero (Dirichlet ends from F ends
   --  if Use_F_Ends, else 0), run N_Cycles V-cycles. Returns the
   --  approximate solution. Level defaults to a full hierarchy for N.
   function Solve_Poisson_MG
     (F                : Grid;
      H                : Real;
      N_Cycles         : Positive := 5;
      Level            : Natural := Natural'Last;
      Nu_1             : Natural := 2;
      Nu_2             : Natural := 2;
      Omega            : Real := Default_Omega;
      Use_Gauss_Seidel : Boolean := False)
     return Grid
     with Global => null;

end Multigrid_Methods;
