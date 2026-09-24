--  Crank_Nicolson — Ada 2023 educational package for Wikipedia
--  "Crank–Nicolson method": implicit finite-difference scheme for the
--  1D heat equation u_t = α u_xx, averaging forward and backward Euler
--  in time with a central second-difference in space.
--  Classroom focus:
--    • one CN time step (tridiagonal + embedded Thomas)
--    • multi-step advance with fixed Dirichlet BCs
--    • r-parameter and Fourier amplification (unconditional stability)
--  Primary source:
--  https://en.wikipedia.org/wiki/Crank%E2%80%93Nicolson_method

pragma Ada_2022;

package Crank_Nicolson
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

   --  1D samples on a uniform grid (1-based), including Dirichlet ends.
   type Grid is array (Positive range <>) of Real;

   Invalid_Argument : exception;
   --  Raised for H ≤ 0, Dt ≤ 0, Alpha ≤ 0, grids shorter than 3,
   --  N_Steps / lengths out of range, or a degenerate Thomas pivot.

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
   -- Crank–Nicolson parameter and stability helpers
   ---------------------------------------------------------------------------

   --  r = α Δt / (2 H²). Raises Invalid_Argument if H ≤ 0, Dt ≤ 0,
   --  or Alpha ≤ 0.
   function R_Param (Alpha, Dt, H : Real) return Real
     with Global => null;

   --  Fourier amplification factor for wave number phase Theta = κ H:
   --    A = (1 − 4 r sin²(Θ/2)) / (1 + 4 r sin²(Θ/2)).
   --  For the linear heat equation, |A| ≤ 1 for all r ≥ 0 and all Θ.
   --  Raises Invalid_Argument if R < 0.
   function Amplification_Factor (R, Theta : Real) return Real
     with Global => null;

   --  True iff |Amplification_Factor(R, Theta)| ≤ 1 + Tol.
   function Amplification_Bounded
     (R, Theta : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   --  Educational check: for several representative Θ in (0, π],
   --  |A(R, Θ)| ≤ 1. Returns True for any R ≥ 0 (and True for the
   --  trivial R = 0 case). Raises Invalid_Argument if R < 0.
   function Unconditionally_Stable (R : Real) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Heat equation: Crank–Nicolson time stepping
   ---------------------------------------------------------------------------

   --  One Crank–Nicolson step for u_t = α u_xx on a uniform 1D grid
   --  that includes Dirichlet endpoints.
   --  Assembles the tridiagonal system with r = α Δt / (2 H²):
   --    −r U^{n+1}_{j−1} + (1+2r) U^{n+1}_j − r U^{n+1}_{j+1}
   --      = r U^n_{j−1} + (1−2r) U^n_j + r U^n_{j+1}
   --  folds Left_BC / Right_BC (values at the *next* time level) into
   --  the RHS, and solves with an embedded Thomas (TDMA) sweep.
   --  Returns a Grid with the same bounds as U; endpoints are set to
   --  Left_BC and Right_BC.
   --  Raises Invalid_Argument if H ≤ 0, Dt ≤ 0, Alpha ≤ 0, U'Length < 3,
   --  U'Length > Max_Points, or a Thomas pivot is degenerate.
   function Heat_CN_Step
     (U        : Grid;
      H        : Real;
      Dt       : Real;
      Alpha    : Real;
      Left_BC  : Real := 0.0;
      Right_BC : Real := 0.0) return Grid
     with Global => null;

   --  Apply Heat_CN_Step N_Steps times starting from U0, with fixed
   --  (time-independent) Dirichlet BCs. Returns the field after
   --  N_Steps · Dt. Raises Invalid_Argument under the same rules as
   --  Heat_CN_Step, or if N_Steps is out of a sane educational range
   --  (enforced by Positive).
   function Heat_CN_Advance
     (U0       : Grid;
      H        : Real;
      Dt       : Real;
      Alpha    : Real;
      N_Steps  : Positive;
      Left_BC  : Real := 0.0;
      Right_BC : Real := 0.0) return Grid
     with Global => null;

end Crank_Nicolson;
