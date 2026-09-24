--  Eigenvalue_Algorithms — Ada 2023 educational survey package for
--  Wikipedia "Eigenvalue algorithm": taxonomy + minimal working sketches
--  of major families (power / inverse / Rayleigh quotient iteration,
--  unshifted QR, Jacobi for symmetric, Lanczos / Arnoldi Krylov builds).
--  Self-contained; sibling packages linked in README only — not deps.
--  Cap n ≤ 12; educational Float.
--  Primary source: https://en.wikipedia.org/wiki/Eigenvalue_algorithm

pragma Ada_2022;

package Eigenvalue_Algorithms
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   Max_N : constant := 12;

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   type Vector is array (Positive range <>) of Float;
   type Matrix is array (Positive range <>, Positive range <>) of Float;

   --  Tol      : residual / off-diag stop
   --  Max_Iter : hard budget (power / inverse / RQI / QR sweeps)
   --  Mu       : fixed shift for Inverse (ignored unless Has_Shift)
   --  Has_Shift: True ⇒ Inverse / Rayleigh use Mu (RQI may override)
   --  M        : Krylov steps for Lanczos / Arnoldi (0 ⇒ min(N, 4))
   --  Max_Sweeps: Jacobi sweep budget
   type Parameters is record
      Tol        : Float   := 1.0E-6;
      Max_Iter   : Natural := 200;
      Mu         : Float   := 0.0;
      Has_Shift  : Boolean := False;
      M          : Natural := 0;
      Max_Sweeps : Natural := 50;
   end record;

   Default_Parameters : constant Parameters :=
     (Tol => 1.0E-6, Max_Iter => 200, Mu => 0.0,
      Has_Shift => False, M => 0, Max_Sweeps => 50);

   type Status is
     (Ok, Converged, Iteration_Limit, Breakdown, Singular_Shift,
      Not_Symmetric, Ill_Started, Dimension_Error, Not_Implemented);

   --  Single eigenpair (Power / Inverse / Rayleigh).
   type Eigenpair_Result is record
      Eigenvalue  : Float := 0.0;
      Eigenvector : Vector (1 .. Max_N) := [others => 0.0];
      N           : Dimension := 0;
      Iterations  : Natural := 0;
      Residual    : Float := 0.0;
      Mu          : Float := 0.0;
      Stat        : Status := Ill_Started;
      Success     : Boolean := False;
   end record;

   --  Full / partial spectrum (Jacobi / QR).
   type Spectrum_Result is record
      Eigenvalues  : Vector (1 .. Max_N) := [others => 0.0];
      Eigenvectors : Matrix (1 .. Max_N, 1 .. Max_N) :=
                       [others => [others => 0.0]];
      Final_A      : Matrix (1 .. Max_N, 1 .. Max_N) :=
                       [others => [others => 0.0]];
      N            : Dimension := 0;
      Iterations   : Natural := 0;
      Off_Diag     : Float := 0.0;
      Stat         : Status := Ill_Started;
      Success      : Boolean := False;
      Has_Vectors  : Boolean := False;
   end record;

   --  Thin Krylov build (Lanczos tridiagonal / Arnoldi Hessenberg).
   type Krylov_Result is record
      Alphas     : Vector (1 .. Max_N) := [others => 0.0];
      Betas      : Vector (1 .. Max_N) := [others => 0.0];
      H          : Matrix (1 .. Max_N, 1 .. Max_N) :=
                     [others => [others => 0.0]];
      V          : Matrix (1 .. Max_N, 1 .. Max_N) :=
                     [others => [others => 0.0]];
      N          : Dimension := 0;
      Steps      : Natural := 0;
      M_Requested : Natural := 0;
      Beta_Next  : Float := 0.0;
      H_Extra    : Float := 0.0;
      Has_V      : Boolean := False;
      Stat       : Status := Ill_Started;
      Success    : Boolean := False;
   end record;

   ---------------------------------------------------------------------------
   -- Method taxonomy (Wikipedia iterative / dense / Krylov families)
   ---------------------------------------------------------------------------

   type Method_Kind is
     (Power,
      Inverse,
      Rayleigh_Quotient,
      QR_Iteration,
      Jacobi_Symmetric,
      Lanczos,
      Arnoldi,
      Divide_And_Conquer);
   --  Divide_And_Conquer: catalogue-only (symmetric tridiagonal Cuppen /
   --  LAPACK path); Not_Implemented when dispatched.

   type Goal_Kind is
     (Want_Dominant,
      Want_Near_Shift,
      Want_Full_Spectrum,
      Want_Extremal_Few);

   type Method_Info is record
      Kind            : Method_Kind;
      Needs_Symmetric : Boolean;
      Uses_Shift      : Boolean;
      Full_Spectrum   : Boolean;
      Krylov          : Boolean;
      Runnable_Sketch : Boolean;
   end record;

   type Matrix_Properties is record
      N         : Dimension := 0;
      Symmetric : Boolean := False;
      Tridiagonal : Boolean := False;
      Diagonal  : Boolean := False;
   end record;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-10;
   Pivot_Tol   : constant Float := 1.0E-12;
   Norm_Tol    : constant Float := 1.0E-14;
   Sym_Tol     : constant Float := 1.0E-5;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Vec_Near
     (A, B : Vector; Tol : Float := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   function Dot (U, V : Vector) return Float
     with Pre => U'Length = V'Length, Global => null;

   function Norm2 (V : Vector) return Float
     with Global => null;

   function Scale (V : Vector; S : Float) return Vector
     with Global => null;

   function Add (U, V : Vector) return Vector
     with Pre => U'Length = V'Length, Global => null;

   function Sub (U, V : Vector) return Vector
     with Pre => U'Length = V'Length, Global => null;

   function Mat_Vec (A : Matrix; X : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length,
          Global => null;

   function Is_Square (A : Matrix) return Boolean
     with Global => null;

   function Is_Symmetric
     (A : Matrix; Tol : Float := Sym_Tol) return Boolean
     with Pre => A'Length (1) = A'Length (2) and then Tol >= 0.0,
          Global => null;

   function Is_Tridiagonal
     (A : Matrix; Tol : Float := Epsilon_Tol) return Boolean
     with Pre => A'Length (1) = A'Length (2) and then Tol >= 0.0,
          Global => null;

   function Is_Diagonal
     (A : Matrix; Tol : Float := Epsilon_Tol) return Boolean
     with Pre => A'Length (1) = A'Length (2) and then Tol >= 0.0,
          Global => null;

   function Normalize (V : Vector) return Vector
     with Pre => V'Length >= 1, Global => null;

   function Identity (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   function Off_Diag_Norm (A : Matrix) return Float
     with Pre => A'Length (1) = A'Length (2) and then A'Length (1) >= 1,
          Global => null;

   function Column (A : Matrix; J : Positive) return Vector
     with Pre => J in A'Range (2), Global => null;

   ---------------------------------------------------------------------------
   -- Rayleigh quotient and eigen residual
   ---------------------------------------------------------------------------

   function Rayleigh_Quotient (A : Matrix; X : Vector) return Float
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length >= 1,
          Global => null;
   --  R(A, x) = (xᵀ A x) / (xᵀ x)

   function Eigen_Residual
     (A : Matrix; X : Vector; Lambda : Float) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length >= 1,
          Global => null;
   --  r = A x − λ x

   function Eigen_Residual_Norm
     (A : Matrix; X : Vector; Lambda : Float) return Float
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length >= 1,
          Global => null;
   --  ‖A x − λ x‖₂

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Make_Diagonal (Eigs : Vector) return Matrix
     with Pre => Eigs'Length >= 1 and then Eigs'Length <= Max_N,
          Global => null;

   function Make_Poisson_1D (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  (−1, 2, −1) Dirichlet Laplacian; λ_k = 2 − 2 cos(kπ/(N+1)).

   function Make_Known_Spectrum_Symmetric (Eigs : Vector) return Matrix
     with Pre => Eigs'Length >= 1 and then Eigs'Length <= Max_N,
          Global => null;
   --  Q diag(Eigs) Qᵀ via deterministic MGS Q.

   function Make_Nonsymmetric (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  Upper-triangular-ish: diag = N, superdiag = 1, subdiag = 0.25.

   function Make_Ones_Vector (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   function Make_Unit_Vector
     (N : Dimension; K : Dim_Index) return Vector
     with Pre => N >= 1 and then K <= N, Global => null;

   function Make_Perturbed_Basis
     (N : Dimension; K : Dim_Index; Eps : Float := 0.1) return Vector
     with Pre => N >= 1 and then K <= N, Global => null;

   function Poisson_Eigenvalue
     (N : Dimension; K : Dim_Index) return Float
     with Pre => N >= 1 and then K <= N, Global => null;

   ---------------------------------------------------------------------------
   -- Taxonomy helpers
   ---------------------------------------------------------------------------

   function Classify_Matrix
     (A : Matrix; Tol : Float := Sym_Tol) return Matrix_Properties
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) >= 1
            and then A'Length (1) <= Max_N
            and then Tol >= 0.0,
          Global => null;

   function Recommend_Method
     (P         : Matrix_Properties;
      Goal      : Goal_Kind := Want_Dominant;
      Has_Shift : Boolean := False) return Method_Kind
     with Global => null;
   --  Heuristic:
   --    Want_Near_Shift ∨ Has_Shift → Inverse (or Rayleigh_Quotient)
   --    Want_Full_Spectrum ∧ Symmetric → Jacobi_Symmetric (n≤8) else QR
   --    Want_Extremal_Few ∧ Symmetric → Lanczos
   --    Want_Extremal_Few ∧ not Symmetric → Arnoldi
   --    Want_Dominant → Power
   --    else Power

   function Classify_Method (K : Method_Kind) return Method_Info
     with Global => null;

   function Method_Name (K : Method_Kind) return String
     with Global => null;

   function Method_Count return Positive
     with Global => null;

   ---------------------------------------------------------------------------
   -- Runnable sketches: single eigenpair
   ---------------------------------------------------------------------------

   function Power_Dominant
     (A      : Matrix;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Eigenpair_Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X0'Length
            and then X0'Length >= 1
            and then X0'Length <= Max_N;
   --  y ← A x, x ← y/‖y‖, λ ← R(A,x) until residual ≤ Tol.

   function Inverse_Near
     (A      : Matrix;
      Mu     : Float;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Eigenpair_Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X0'Length
            and then X0'Length >= 1
            and then X0'Length <= Max_N;
   --  Fixed-shift inverse iteration: solve (A − μ I) y = x repeatedly.

   function Rayleigh_Quotient_Iterate
     (A      : Matrix;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Eigenpair_Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X0'Length
            and then X0'Length >= 1
            and then X0'Length <= Max_N;
   --  Update μ ← R(A,x) each step (cubic local convergence typical).

   ---------------------------------------------------------------------------
   -- Runnable sketches: spectrum
   ---------------------------------------------------------------------------

   function Jacobi_Diagonalize
     (S      : Matrix;
      Params : Parameters := Default_Parameters) return Spectrum_Result
     with Pre => S'Length (1) = S'Length (2)
            and then S'Length (1) >= 1
            and then S'Length (1) <= Max_N;
   --  Cyclic Jacobi plane rotations for real symmetric S.

   function QR_Unshifted
     (A      : Matrix;
      Params : Parameters := Default_Parameters) return Spectrum_Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) >= 1
            and then A'Length (1) <= Max_N;
   --  Unshifted QR via Modified Gram–Schmidt; prefer tiny symmetric cases.

   ---------------------------------------------------------------------------
   -- Runnable sketches: thin Krylov builds
   ---------------------------------------------------------------------------

   function Lanczos_Build
     (A      : Matrix;
      V0     : Vector;
      Params : Parameters := Default_Parameters) return Krylov_Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = V0'Length
            and then V0'Length >= 1
            and then V0'Length <= Max_N;
   --  Three-term recurrence → α, β (requires symmetric A).

   function Arnoldi_Build
     (A      : Matrix;
      V0     : Vector;
      Params : Parameters := Default_Parameters) return Krylov_Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = V0'Length
            and then V0'Length >= 1
            and then V0'Length <= Max_N;
   --  MGS Arnoldi → upper Hessenberg H_m (general A).

   ---------------------------------------------------------------------------
   -- Dispatcher
   ---------------------------------------------------------------------------

   function Run_Eigenpair
     (A      : Matrix;
      X0     : Vector;
      Kind   : Method_Kind;
      Params : Parameters := Default_Parameters) return Eigenpair_Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X0'Length
            and then X0'Length >= 1
            and then X0'Length <= Max_N;
   --  Dispatch Power / Inverse / Rayleigh. Others → Not_Implemented.

   function Run_Spectrum
     (A      : Matrix;
      Kind   : Method_Kind;
      Params : Parameters := Default_Parameters) return Spectrum_Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (1) >= 1
            and then A'Length (1) <= Max_N;
   --  Dispatch Jacobi_Symmetric / QR_Iteration. Else Not_Implemented.

   function Run_Auto_Eigenpair
     (A      : Matrix;
      X0     : Vector;
      Goal   : Goal_Kind := Want_Dominant;
      Params : Parameters := Default_Parameters) return Eigenpair_Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X0'Length
            and then X0'Length >= 1
            and then X0'Length <= Max_N;
   --  Classify → Recommend → Run_Eigenpair (falls back to Power).

end Eigenvalue_Algorithms;
