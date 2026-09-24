--  Variational_Method — Ada 2023 educational package for the calculus of
--  variations (functionals, Euler–Lagrange, discrete path length / Dirichlet
--  energy) with a small quantum-mechanics variational-principle application
--  (Gaussian trial for the harmonic oscillator; energy upper bound).
--  Primary source: Wikipedia "Calculus of variations" (Variational method
--  redirects there). QM companion: "Variational method (quantum mechanics)".
--  Sibling survey (link only): Ada-Rayleigh-Ritz-Method.

pragma Ada_2022;

package Variational_Method
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Polylines / discrete paths: at most Max_Points vertices.
   Max_Points : constant Positive := 64;
   --  1-D quantum grids (wavefunction samples).
   Max_Grid : constant Positive := 64;

   subtype Point_Count is Natural range 0 .. Max_Points;
   subtype Point_Index is Positive range 1 .. Max_Points;
   subtype Grid_Count is Natural range 0 .. Max_Grid;
   subtype Grid_Index is Positive range 1 .. Max_Grid;

   type Point is record
      X : Real := 0.0;
      Y : Real := 0.0;
   end record;

   --  Discrete path y(x) sampled at ordered abscissae (nondecreasing X).
   type Path is array (Point_Index range <>) of Point;

   --  1-D real wavefunction samples on a uniform grid.
   type Wave is array (Grid_Index range <>) of Real;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;
   Degenerate        : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-10;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Clamp (V, Lo, Hi : Real) return Real
     with Pre => Lo <= Hi, Global => null;

   ---------------------------------------------------------------------------
   -- Path construction
   ---------------------------------------------------------------------------

   function Straight_Line_Path
     (X0, Y0, X1, Y1 : Real;
      N              : Point_Count) return Path
     with Pre => N >= 2 and then X1 /= X0,
          Global => null;
   --  N equally spaced nodes on the segment from (X0,Y0) to (X1,Y1).

   function Bowed_Path
     (X0, Y0, X1, Y1 : Real;
      N              : Point_Count;
      Amplitude      : Real) return Path
     with Pre => N >= 2 and then X1 /= X0,
          Global => null;
   --  Straight line plus Amplitude * sin(π t) bow in the Y direction
   --  (t ∈ [0,1] along the parameter). Endpoints unchanged.

   function Linear_Interpolation_Y
     (X0, Y0, X1, Y1, X : Real) return Real
     with Pre => X1 /= X0, Global => null;

   ---------------------------------------------------------------------------
   -- Classical functionals on polylines
   ---------------------------------------------------------------------------

   function Path_Length (P : Path) return Non_Negative
     with Pre => P'Length >= 1, Global => null;
   --  Sum of Euclidean segment lengths. Single point → 0.

   function Segment_Count (P : Path) return Natural
     with Global => null;
   --  Max(0, Length − 1).

   function Dirichlet_Energy (P : Path) return Non_Negative
     with Pre => P'Length >= 2, Global => null;
   --  Discrete ∫ (y')² dx ≈ Σ (Δy)²/Δx  (trapezoid-consistent for piecewise
   --  linear paths). Minimizer with fixed endpoints is the straight line.

   function Functional_Trapezoid_Arc (P : Path) return Non_Negative
     with Pre => P'Length >= 2, Global => null;
   --  Trapezoid / polyline evaluation of ∫ √(1+(y')²) dx ≡ Path_Length for
   --  piecewise-linear paths (exact on each segment).

   function Functional_Trapezoid_Dirichlet (P : Path) return Non_Negative
     with Pre => P'Length >= 2, Global => null;
   --  Alias of Dirichlet_Energy (∫ (y')² dx on the polyline).

   function Functional_Simpson_Arc (P : Path) return Non_Negative
     with Pre => P'Length >= 2, Global => null;
   --  Composite Simpson on equal-Δx grids for L=√(1+(y')²) using centered
   --  finite differences for y'; falls back to Path_Length if Δx uneven.

   ---------------------------------------------------------------------------
   -- Euler–Lagrange residuals (finite differences)
   ---------------------------------------------------------------------------

   function Mean_Abs_Second_Difference (P : Path) return Non_Negative
     with Pre => P'Length >= 3, Global => null;
   --  For L=(y')² the EL equation is y''=0. Mean absolute discrete second
   --  difference of interior Y values (uniform Δx assumed; scaled by 1/Δx²
   --  when Δx is constant).

   function Euler_Lagrange_Residual_Dirichlet (P : Path) return Non_Negative
     with Pre => P'Length >= 3, Global => null;
   --  Same as Mean_Abs_Second_Difference: stationarity residual for Dirichlet.

   function Max_Abs_Length_Gradient (P : Path) return Non_Negative
     with Pre => P'Length >= 3, Global => null;
   --  Max |∂J/∂y_i| for arc-length J over interior nodes (finite-difference
   --  partials of Path_Length). Near zero at the straight-line minimizer.

   ---------------------------------------------------------------------------
   -- Discrete path improvement (gradient / coordinate descent)
   ---------------------------------------------------------------------------

   procedure Improve_Path_Gradient
     (P          : in out Path;
      Step       : Real := 0.05;
      Iterations : Natural := 50;
      Objective  : Natural := 0)
     with Pre => P'Length >= 3 and then Step > 0.0, Global => null;
   --  Fix endpoints; move interior Y to reduce objective.
   --  Objective 0 = Path_Length, 1 = Dirichlet_Energy.
   --  Uses a simple finite-difference gradient step with damping.

   procedure Improve_Path_Coordinate
     (P          : in out Path;
      Step       : Real := 0.1;
      Iterations : Natural := 40;
      Objective  : Natural := 0)
     with Pre => P'Length >= 3 and then Step > 0.0, Global => null;
   --  Coordinate descent: for each interior node try ±Step and keep better.

   ---------------------------------------------------------------------------
   -- Quantum variational helpers (1-D)
   ---------------------------------------------------------------------------

   function Harmonic_Ground_Exact return Real
     with Global => null;
   --  Exact ground energy of H = −d²/dx² + x²  →  E₀ = 1.

   function Gaussian_Trial_Energy_Analytic (Alpha : Positive_Real) return Real
     with Global => null;
   --  Analytic Rayleigh quotient for ψ(x) ∝ exp(−α x²/2) under
   --  H = −d²/dx² + x²:  E(α) = α/2 + 1/(2α).  Minimum 1 at α = 1.

   function Optimal_Gaussian_Alpha return Positive_Real
     with Global => null;
   --  α* = 1 for the analytic Gaussian trial above.

   function Normalize (Psi : Wave; DX : Positive_Real) return Wave
     with Pre => Psi'Length >= 1, Global => null;
   --  L²-normalize on a uniform grid with spacing DX (trapezoid weights
   --  approximated by DX * Σ ψ²). Raises Degenerate if ‖ψ‖ ≈ 0.

   function Discrete_Norm2 (Psi : Wave; DX : Positive_Real) return Non_Negative
     with Pre => Psi'Length >= 1, Global => null;

   function Rayleigh_Energy
     (Psi : Wave;
      X   : Wave;
      DX  : Positive_Real) return Real
     with Pre => Psi'Length >= 3
                 and then X'Length = Psi'Length
                 and then DX > 0.0,
          Global => null;
   --  Discrete ⟨ψ|H|ψ⟩/⟨ψ|ψ⟩ for H = −d²/dx² + x² on a uniform grid:
   --  kinetic via second differences, potential xᵢ² ψᵢ.

   function Quantum_Trial_Energy
     (Alpha : Positive_Real;
      X_Min : Real := -6.0;
      X_Max : Real := 6.0;
      N     : Grid_Count := 61) return Real
     with Pre => N >= 5 and then X_Max > X_Min, Global => null;
   --  Build ψᵢ = exp(−α xᵢ²/2) on [X_Min,X_Max], return Rayleigh_Energy.

   function Optimize_Gaussian_Alpha
     (Alpha_Lo : Positive_Real := 0.3;
      Alpha_Hi : Positive_Real := 3.0;
      Steps    : Positive := 40;
      X_Min    : Real := -6.0;
      X_Max    : Real := 6.0;
      N        : Grid_Count := 61) return Real
     with Pre => Alpha_Hi > Alpha_Lo
                 and then N >= 5
                 and then X_Max > X_Min,
          Global => null;
   --  Grid search for α minimizing Quantum_Trial_Energy; returns best α.

   function Make_Gaussian_Wave
     (Alpha : Positive_Real;
      X_Min : Real;
      X_Max : Real;
      N     : Grid_Count) return Wave
     with Pre => N >= 2 and then X_Max > X_Min, Global => null;

   function Make_Uniform_Grid
     (X_Min : Real;
      X_Max : Real;
      N     : Grid_Count) return Wave
     with Pre => N >= 2 and then X_Max > X_Min, Global => null;

end Variational_Method;
