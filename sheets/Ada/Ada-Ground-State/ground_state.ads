--  Ground_State — Ada 2023 educational package for quantum ground states:
--  exact spectra (1-D infinite well, harmonic oscillator), zero-point energy,
--  discrete Hermitian Hamiltonians on a grid, Jacobi lowest eigenpair,
--  variational Gaussian upper bounds, degeneracy counting, and the 1-D
--  nodeless ground-state property.
--  Primary source: Wikipedia "Ground state".
--  Sibling surveys (links only): Ada-Variational-Method, Ada-Rayleigh-Ritz-Method.

pragma Ada_2022;

package Ground_State
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   type Real is digits 15;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   --  Educational dense bound (Jacobi is fine for N ≤ Max_N).
   Max_N : constant Positive := 64;

   subtype Dim_N is Natural range 0 .. Max_N;
   subtype Index_N is Positive range 1 .. Max_N;

   --  1-D real wavefunction / eigenvector samples (1-based).
   type Wave is array (Index_N range <>) of Real;
   type Vector is array (Index_N range <>) of Real;

   --  Dense real-symmetric Hamiltonians: H (I, J).
   type Matrix is array (Index_N range <>, Index_N range <>) of Real;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument  : exception;
   Capacity_Exceeded : exception;
   Degenerate        : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers / defaults (ħ = 1, m = 1)
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-10;
   Jacobi_Tol  : constant Real := 1.0E-14;
   Default_Hbar : constant Positive_Real := 1.0;
   Default_Mass : constant Positive_Real := 1.0;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Pi_Value return Real
     with Global => null;
   --  π ≈ 3.141592653589793.

   function Clamp (V, Lo, Hi : Real) return Real
     with Pre => Lo <= Hi, Global => null;

   ---------------------------------------------------------------------------
   -- Exact model: 1-D infinite square well on [0, L]
   --   E_n = n² π² ħ² / (2 m L²),  ψ_n(x) ∝ sin(n π x / L), ground n = 1.
   ---------------------------------------------------------------------------

   function Infinite_Well_Energy
     (N     : Positive;
      L     : Positive_Real;
      Hbar  : Positive_Real := Default_Hbar;
      Mass  : Positive_Real := Default_Mass) return Positive_Real
     with Global => null;

   function Infinite_Well_Ground_Energy
     (L    : Positive_Real;
      Hbar : Positive_Real := Default_Hbar;
      Mass : Positive_Real := Default_Mass) return Positive_Real
     with Global => null;
   --  E_1 = π² ħ² / (2 m L²).

   function Infinite_Well_Psi
     (N : Positive;
      X : Real;
      L : Positive_Real) return Real
     with Pre => L > 0.0, Global => null;
   --  Normalized ψ_n(x) = √(2/L) sin(n π x / L) for x ∈ (0, L); 0 outside.

   ---------------------------------------------------------------------------
   -- Exact model: quantum harmonic oscillator
   --   E_n = (n + 1/2) ħ ω,  ground Gaussian, zero-point E_0 = ½ ħ ω.
   ---------------------------------------------------------------------------

   function Harmonic_Energy
     (N     : Natural;
      Omega : Positive_Real;
      Hbar  : Positive_Real := Default_Hbar) return Positive_Real
     with Global => null;

   function Zero_Point_Energy
     (Omega : Positive_Real;
      Hbar  : Positive_Real := Default_Hbar) return Positive_Real
     with Global => null;
   --  ½ ħ ω.

   function Harmonic_Ground_Psi
     (X     : Real;
      Omega : Positive_Real;
      Mass  : Positive_Real := Default_Mass;
      Hbar  : Positive_Real := Default_Hbar) return Real
     with Global => null;
   --  Normalized ground state (π ħ / (m ω))^{-1/4} exp(− m ω x² / (2 ħ)).

   ---------------------------------------------------------------------------
   -- Discrete 1-D Hamiltonian on a uniform interior grid
   --   Kinetic:  −(ħ²/2m) d²/dx²  →  tridiagonal stencil / dx²
   --   Potential: diagonal V(x_i)
   ---------------------------------------------------------------------------

   function Make_Uniform_Grid
     (X_Min : Real;
      X_Max : Real;
      N     : Dim_N) return Wave
     with Pre => N >= 2 and then X_Max > X_Min, Global => null;

   function Grid_Spacing (X_Min, X_Max : Real; N : Dim_N) return Positive_Real
     with Pre => N >= 2 and then X_Max > X_Min, Global => null;

   function Build_Discrete_Hamiltonian
     (X     : Wave;
      V     : Wave;
      Hbar  : Positive_Real := Default_Hbar;
      Mass  : Positive_Real := Default_Mass) return Matrix
     with Pre => X'Length >= 2
                 and then V'Length = X'Length
                 and then X'First = V'First
                 and then X'Last = V'Last,
          Global => null;
   --  Tridiagonal kinetic + diagonal V. Assumes uniform spacing from X.
   --  Raises Invalid_Argument if spacing is non-positive.

   function Build_Infinite_Well_Hamiltonian
     (L     : Positive_Real;
      N     : Dim_N;
      Hbar  : Positive_Real := Default_Hbar;
      Mass  : Positive_Real := Default_Mass) return Matrix
     with Pre => N >= 2 and then L > 0.0, Global => null;
   --  Interior points x_i = i L/(N+1), V ≡ 0 (Dirichlet walls at 0, L).

   function Build_Harmonic_Hamiltonian
     (Omega : Positive_Real;
      X_Min : Real;
      X_Max : Real;
      N     : Dim_N;
      Hbar  : Positive_Real := Default_Hbar;
      Mass  : Positive_Real := Default_Mass) return Matrix
     with Pre => N >= 2 and then X_Max > X_Min and then Omega > 0.0,
          Global => null;
   --  V(x) = ½ m ω² x² on a uniform grid in [X_Min, X_Max].

   ---------------------------------------------------------------------------
   -- Dense symmetric eigensolver (Jacobi) and ground eigenpair
   ---------------------------------------------------------------------------

   procedure Jacobi_Symmetric
     (H         : in out Matrix;
      Y         : out Matrix;
      Eigenvals : out Vector;
      N         : Dim_N;
      Tol       : Real := Jacobi_Tol)
     with Pre => N >= 1
                 and then N <= H'Length (1)
                 and then N <= H'Length (2)
                 and then N <= Y'Length (1)
                 and then N <= Y'Length (2)
                 and then N <= Eigenvals'Length
                 and then Tol > 0.0,
          Global => null;
   --  Overwrites H with approx. diagonal; Y orthonormal eigenvectors;
   --  Eigenvals (1 .. N) sorted ascending.

   procedure Lowest_Eigenpair
     (H      : Matrix;
      Energy : out Real;
      Psi    : out Vector;
      N      : Dim_N)
     with Pre => N >= 1
                 and then N <= H'Length (1)
                 and then N <= H'Length (2)
                 and then N <= Psi'Length,
          Global => null;
   --  Ground (lowest) eigenpair of real-symmetric H via Jacobi.

   function Rayleigh_Quotient (H : Matrix; Psi : Vector) return Real
     with Pre => H'First (1) = Psi'First
                 and then H'Last (1) = Psi'Last
                 and then H'First (2) = Psi'First
                 and then H'Last (2) = Psi'Last,
          Global => null;
   --  ⟨ψ|H|ψ⟩ / ⟨ψ|ψ⟩. Raises Degenerate if ‖ψ‖ = 0.

   function Residual_Norm
     (H : Matrix; Psi : Vector; Energy : Real) return Non_Negative
     with Pre => H'First (1) = Psi'First
                 and then H'Last (1) = Psi'Last
                 and then H'First (2) = Psi'First
                 and then H'Last (2) = Psi'Last,
          Global => null;
   --  ‖H ψ − E ψ‖₂.

   function Dot (A, B : Vector) return Real
     with Pre => A'First = B'First and then A'Last = B'Last, Global => null;

   function Norm2 (X : Vector) return Non_Negative
     with Global => null;

   function Norm (X : Vector) return Non_Negative
     with Global => null;

   procedure Normalize_In_Place (X : in out Vector)
     with Global => null;
   --  Euclidean normalize; raises Degenerate if ‖x‖ ≈ 0.

   ---------------------------------------------------------------------------
   -- Nodes / sign changes (1-D ground states are nodeless interiorly)
   ---------------------------------------------------------------------------

   function Count_Sign_Changes (Psi : Wave) return Natural
     with Pre => Psi'Length >= 1, Global => null;
   --  Number of interior sign changes (ignores exact zeros as non-crossings
   --  until a nonzero of opposite sign appears).

   function Is_Nodeless_Interior (Psi : Wave) return Boolean
     with Pre => Psi'Length >= 1, Global => null;
   --  True iff Count_Sign_Changes (Psi) = 0.

   ---------------------------------------------------------------------------
   -- Degeneracy
   ---------------------------------------------------------------------------

   function Degeneracy_Of_Level
     (Eigenvals : Vector;
      Index     : Index_N;
      Tol       : Real := 1.0E-8) return Positive
     with Pre => Index in Eigenvals'Range and then Tol >= 0.0,
          Global => null;
   --  Multiplicity of Eigenvals (Index) within Tol among Eigenvals'Range.

   function Isotropic_2D_Oscillator_Degeneracy (Total_Quanta : Natural)
     return Positive
     with Global => null;
   --  For E = (n_x + n_y + 1) ħ ω the level with n = n_x + n_y has
   --  degeneracy n + 1.

   function Make_Equal_Diagonal_2x2 (Lam : Real) return Matrix
     with Global => null;
   --  diag(Lam, Lam) — pedagogical doubly degenerate 2 × 2.

   ---------------------------------------------------------------------------
   -- Variational upper bound (Gaussian trial for the oscillator)
   --   ψ_α ∝ exp(−α x²/2),  E(α) = ħ² α/(4 m) + m ω²/(4 α)  ≥  E_0.
   ---------------------------------------------------------------------------

   function Variational_Gaussian_Energy
     (Alpha : Positive_Real;
      Omega : Positive_Real;
      Hbar  : Positive_Real := Default_Hbar;
      Mass  : Positive_Real := Default_Mass) return Positive_Real
     with Global => null;

   procedure Optimize_Gaussian_Trial
     (Omega      : Positive_Real;
      Best_Alpha : out Positive_Real;
      Best_Energy : out Positive_Real;
      Alpha_Lo   : Positive_Real := 0.05;
      Alpha_Hi   : Positive_Real := 20.0;
      Steps      : Positive := 80;
      Hbar       : Positive_Real := Default_Hbar;
      Mass       : Positive_Real := Default_Mass)
     with Pre => Alpha_Hi > Alpha_Lo, Global => null;
   --  Grid search for α minimizing the analytic Gaussian Rayleigh quotient.

   function Optimal_Gaussian_Alpha
     (Omega : Positive_Real;
      Mass  : Positive_Real := Default_Mass;
      Hbar  : Positive_Real := Default_Hbar) return Positive_Real
     with Global => null;
   --  Analytic α* = m ω / ħ.

end Ground_State;
