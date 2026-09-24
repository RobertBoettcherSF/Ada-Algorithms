--  Lax_Wendroff — Ada 2023 educational package for Wikipedia
--  "Lax–Wendroff method": second-order finite-difference scheme for
--  hyperbolic PDEs. Classroom focus: 1D linear advection
--    u_t + a u_x = 0
--  on a periodic grid, single-step Lax–Wendroff stencil, plus the
--  optional Richtmyer two-step form (equivalent on linear advection).
--  Primary source:
--  https://en.wikipedia.org/wiki/Lax%E2%80%93Wendroff_method

pragma Ada_2022;

package Lax_Wendroff
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Long_Float-class Real, digits 15)
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Cells : constant Positive := 512;

   subtype Cell_Count is Positive range 1 .. Max_Cells;
   subtype Cell_Index is Positive range 1 .. Max_Cells;

   --  1D solution samples on a uniform periodic grid (1-based).
   type Grid is array (Positive range <>) of Real;

   --  Periodic advection state on [X_Min, X_Min + N·Dx) with N cells.
   --  Cell centres: X_Min + (j − 1)·Dx, j = 1 .. N.
   type Grid_State is record
      U     : Grid (1 .. Max_Cells) := [others => 0.0];
      N     : Cell_Count := 1;
      Dx    : Real := 1.0;
      Dt    : Real := 0.1;
      A     : Real := 1.0;   -- constant advection speed
      X_Min : Real := 0.0;
   end record;

   Invalid_Argument : exception;
   --  Raised for bad Δx / Δt (≤ 0), N out of range, empty grids,
   --  |ν| > 1 (CFL violation), or mismatched lengths.

   Epsilon_Tol : constant Real := 1.0E-10;

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

   ---------------------------------------------------------------------------
   -- Grid geometry / CFL
   ---------------------------------------------------------------------------

   --  Domain length L = N · Dx.
   function Domain_Length (State : Grid_State) return Real
     with Global => null;

   --  Cell-centre abscissa for index J (1-based, wraps conceptually
   --  only through periodic helpers; J must be in 1 .. State.N).
   function X_At (State : Grid_State; J : Cell_Index) return Real
     with Pre => J <= State.N, Global => null;

   --  Courant number ν = a · Δt / Δx.
   function CFL (A, Dt, Dx : Real) return Real
     with Global => null;

   function CFL (State : Grid_State) return Real
     with Global => null;

   --  True iff |ν| ≤ 1 (linear Lax–Wendroff stability region).
   function CFL_OK (State : Grid_State) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Construction / initial conditions
   ---------------------------------------------------------------------------

   --  Allocate an empty (zero) grid with given geometry.
   --  Raises Invalid_Argument if Dx ≤ 0 or Dt ≤ 0.
   function Make_Grid
     (N     : Cell_Count;
      Dx    : Real;
      Dt    : Real;
      A     : Real := 1.0;
      X_Min : Real := 0.0) return Grid_State
     with Global => null;

   --  Gaussian pulse Amp · exp(−((x − Centre) / Width)²) on the grid.
   --  Raises Invalid_Argument if Width ≤ 0 or Dx/Dt invalid.
   function Make_Gaussian
     (N      : Cell_Count;
      Dx     : Real;
      Dt     : Real;
      A      : Real := 1.0;
      X_Min  : Real := 0.0;
      Centre : Real := 0.5;
      Width  : Real := 0.1;
      Amp    : Real := 1.0) return Grid_State
     with Global => null;

   --  Rectangular pulse of height Amp on [Left, Right] (periodic clip
   --  against the domain); elsewhere 0. Raises Invalid_Argument if
   --  Right ≤ Left or Dx/Dt invalid.
   function Make_Pulse
     (N     : Cell_Count;
      Dx    : Real;
      Dt    : Real;
      A     : Real := 1.0;
      X_Min : Real := 0.0;
      Left  : Real := 0.25;
      Right : Real := 0.5;
      Amp   : Real := 1.0) return Grid_State
     with Global => null;

   --  Constant field U ≡ Value (exact steady state of advection).
   function Make_Constant
     (N     : Cell_Count;
      Dx    : Real;
      Dt    : Real;
      Value : Real;
      A     : Real := 1.0;
      X_Min : Real := 0.0) return Grid_State
     with Global => null;

   ---------------------------------------------------------------------------
   -- Time stepping
   ---------------------------------------------------------------------------

   --  One single-step Lax–Wendroff update (periodic):
   --    u_j^{n+1} = u_j^n − (ν/2)(u_{j+1}^n − u_{j−1}^n)
   --              + (ν²/2)(u_{j+1}^n − 2 u_j^n + u_{j−1}^n)
   --  Raises Invalid_Argument if Dx ≤ 0, Dt ≤ 0, or |ν| > 1.
   procedure Step (State : in out Grid_State);

   --  N_Steps successive Step calls.
   procedure Advance (State : in out Grid_State; N_Steps : Positive);

   --  Richtmyer two-step form (half-step predictors at midpoints, then
   --  full step). On linear advection this matches single-step LW.
   --  Raises Invalid_Argument under the same CFL / Δx / Δt rules.
   procedure Step_Richtmyer (State : in out Grid_State);

   procedure Advance_Richtmyer
     (State : in out Grid_State; N_Steps : Positive);

   ---------------------------------------------------------------------------
   -- Exact advection (periodic shift) for comparison
   ---------------------------------------------------------------------------

   --  Periodic wrap of X into [X_Min, X_Min + L).
   function Wrap_Periodic
     (X, X_Min, Length : Real) return Real
     with Pre => Length > 0.0, Global => null;

   --  Exact solution samples of linear advection: shift the *initial*
   --  profile U0 by Distance = A · T (periodic), with linear
   --  interpolation between cell centres. U0'Length must equal N.
   function Exact_Advection
     (U0       : Grid;
      N        : Cell_Count;
      Dx       : Real;
      X_Min    : Real;
      Distance : Real) return Grid
     with Pre => U0'Length = Natural (N) and then Dx > 0.0,
          Global => null;

   --  Convenience: exact field after time T from State's current U
   --  treated as the initial profile (Distance = A · T).
   function Exact_Advection
     (State : Grid_State; T : Real) return Grid
     with Global => null;

   --  Integer-cell periodic rotation of U by K cells (positive K shifts
   --  the profile in the +x direction of the data — matching advection
   --  with a > 0 when Distance = K · Dx).
   function Shift_Grid (U : Grid; K : Integer) return Grid
     with Pre => U'Length >= 1, Global => null;

   ---------------------------------------------------------------------------
   -- Errors / conservation diagnostics
   ---------------------------------------------------------------------------

   --  Discrete L² error: sqrt(Dx · Σ (U − Exact)²) over 1 .. N.
   function L2_Error
     (U, Exact : Grid; Dx : Real) return Non_Negative
     with Pre => U'Length = Exact'Length
            and then U'Length >= 1
            and then Dx > 0.0,
          Global => null;

   function L2_Error
     (State : Grid_State; Exact : Grid) return Non_Negative
     with Pre => Exact'Length = Natural (State.N), Global => null;

   --  Max-norm error max_j |U_j − Exact_j|.
   function Max_Error (U, Exact : Grid) return Non_Negative
     with Pre => U'Length = Exact'Length and then U'Length >= 1,
          Global => null;

   function Max_Error
     (State : Grid_State; Exact : Grid) return Non_Negative
     with Pre => Exact'Length = Natural (State.N), Global => null;

   --  Discrete mass Σ U_j · Dx (conserved by linear LW on periodic grids).
   function Mass (U : Grid; Dx : Real) return Real
     with Pre => U'Length >= 1 and then Dx > 0.0, Global => null;

   function Mass (State : Grid_State) return Real
     with Global => null;

   function Max_Abs (U : Grid) return Non_Negative
     with Pre => U'Length >= 1, Global => null;

end Lax_Wendroff;
