--  Lanczos — Ada 2023 educational package for Wikipedia "Lanczos algorithm":
--  three-term recurrence building an orthonormal Krylov basis V_m and a
--  real symmetric tridiagonal T_m for a symmetric / Hermitian A; Ritz
--  values = eigenvalues of T_m via an inlined Jacobi sketch.
--  Cap n ≤ 32; dense educational Float; optional full reorthogonalization.
--  Primary source:
--  https://en.wikipedia.org/wiki/Lanczos_algorithm
--  Siblings: Ada-Power-Iteration, Ada-QR-Algorithm, Ada-Gram-Schmidt;
--  upcoming Ada-Arnoldi / Eigenvalue survey (README links).

pragma Ada_2022;

package Lanczos
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   Max_N : constant := 32;

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   type Vector is array (Positive range <>) of Float;
   type Matrix is array (Positive range <>, Positive range <>) of Float;

   --  M               : Krylov / Lanczos steps requested (1 .. Max_N),
   --                    clipped to n at run time
   --  Tol             : breakdown when β_{j+1} ≤ Tol
   --  Reorthogonalize : full reorth of w against v_1..v_j (recommended)
   --  Max_QR_Iter     : Jacobi sweep budget when diagonalizing T_m
   --  Keep_V          : store Lanczos basis columns in Result.V
   type Parameters is record
      M               : Natural := 8;
      Tol             : Float   := 1.0E-8;
      Reorthogonalize : Boolean := True;
      Max_QR_Iter     : Natural := 64;
      Keep_V          : Boolean := True;
   end record;

   Default_Parameters : constant Parameters :=
     (M => 8, Tol => 1.0E-8, Reorthogonalize => True,
      Max_QR_Iter => 64, Keep_V => True);

   type Status is
     (Ok,
      Breakdown,
      Iteration_Limit,
      Ill_Started,
      Dimension_Error,
      Not_Symmetric);

   --  Alphas (1 .. Steps) = α_j on the diagonal of T.
   --  Betas  (1 .. Steps) = β_{j+1} (subdiagonal; Betas(j) links v_j, v_{j+1}).
   --  Ritz_Values (1 .. Steps) = eigenvalues of T (sorted ascending).
   --  V columns 1 .. Steps hold the Lanczos vectors when Has_V.
   type Result is record
      Alphas         : Vector (1 .. Max_N) := [others => 0.0];
      Betas          : Vector (1 .. Max_N) := [others => 0.0];
      Ritz_Values    : Vector (1 .. Max_N) := [others => 0.0];
      V              : Matrix (1 .. Max_N, 1 .. Max_N) :=
                         [others => [others => 0.0]];
      Ritz_Vectors   : Matrix (1 .. Max_N, 1 .. Max_N) :=
                         [others => [others => 0.0]];
      N              : Dimension := 0;
      M_Requested    : Natural := 0;
      Steps          : Natural := 0;
      Stat           : Status := Ill_Started;
      Success        : Boolean := False;
      Has_V          : Boolean := False;
      Has_Ritz_Vecs  : Boolean := False;
      Beta_Next      : Float := 0.0;
   end record;

   type Example_Kind is
     (Diagonal_Known,
      Poisson_1D,
      Known_Spectrum_Symmetric);

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-10;
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

   function Normalize (V : Vector) return Vector
     with Pre => V'Length >= 1, Global => null;
   --  V / ‖V‖₂. Raises Invalid_Argument if ‖V‖ ≤ Norm_Tol.

   function Column (A : Matrix; J : Positive) return Vector
     with Pre => J in A'Range (2), Global => null;

   procedure Set_Column
     (A : in out Matrix; J : Positive; V : Vector)
     with Pre => J in A'Range (2)
            and then V'Length = A'Length (1);

   --  Max | (Vᵀ V)_ij − δ_ij | over the leading N×K block of columns.
   function Orthogonality_Residual
     (V : Matrix; N, K : Dimension) return Float
     with Pre => N >= 1 and then K >= 1
            and then N <= Max_N and then K <= Max_N,
          Global => null;

   ---------------------------------------------------------------------------
   -- Tridiagonal T from α / β, Ritz residual helpers
   ---------------------------------------------------------------------------

   --  Dense T with diagonal Alphas (1 .. M) and sub/super Betas (1 .. M-1)
   --  where Betas (J) = β_{J+1}.
   function Make_Tridiagonal
     (Alphas : Vector; Betas : Vector; M : Dimension) return Matrix
     with Pre => M >= 1
            and then Alphas'Length >= M
            and then Betas'Length >= M,
          Global => null;

   --  ‖A y − θ y‖₂ for a Ritz pair (θ, y).
   function Ritz_Residual_Norm
     (A : Matrix; Y : Vector; Theta : Float) return Float
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = Y'Length
            and then Y'Length >= 1,
          Global => null;

   ---------------------------------------------------------------------------
   -- Example / builder matrices
   ---------------------------------------------------------------------------

   function Make_Diagonal (Eigs : Vector) return Matrix
     with Pre => Eigs'Length >= 1 and then Eigs'Length <= Max_N,
          Global => null;

   function Make_Poisson_1D (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  SPD tridiagonal (−1, 2, −1); λ_k = 2 − 2 cos(k π / (N+1)).

   function Make_Known_Spectrum_Symmetric
     (Eigs : Vector) return Matrix
     with Pre => Eigs'Length >= 1 and then Eigs'Length <= Max_N,
          Global => null;
   --  Orthogonal similarity Q diag(Eigs) Qᵀ (deterministic MGS seed).

   function Make_Example
     (Kind : Example_Kind; N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   function Poisson_Eigenvalue
     (N : Dimension; K : Dim_Index) return Float
     with Pre => N >= 1 and then K <= N, Global => null;

   function Make_Ones_Vector (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   function Make_Unit_Vector
     (N : Dimension; K : Dim_Index) return Vector
     with Pre => N >= 1 and then K <= N, Global => null;

   function Make_Perturbed_Basis
     (N : Dimension; K : Dim_Index; Eps : Float := 0.1) return Vector
     with Pre => N >= 1 and then K <= N, Global => null;

   ---------------------------------------------------------------------------
   -- Lanczos three-term recurrence + Ritz extraction
   ---------------------------------------------------------------------------

   --  Build V_m, α, β via the three-term recurrence (no Ritz solve).
   --  On Breakdown, Steps < M and Beta_Next ≈ 0 (invariant subspace).
   function Build_Tridiagonal
     (A      : Matrix;
      V0     : Vector;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = V0'Length
            and then V0'Length >= 1
            and then V0'Length <= Max_N;

   --  Build_Tridiagonal then diagonalize T_m (Jacobi sketch) → Ritz values.
   function Run
     (A      : Matrix;
      V0     : Vector;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = V0'Length
            and then V0'Length >= 1
            and then V0'Length <= Max_N;

   --  Default start v₀ = ones / ‖ones‖.
   function Run
     (A      : Matrix;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) <= Max_N and then A'Length (2) <= Max_N;

   --  Alias for Run (A, V0, Params).
   function Iterate
     (A      : Matrix;
      V0     : Vector;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = V0'Length
            and then V0'Length >= 1
            and then V0'Length <= Max_N;

   --  Approximate Ritz vector y = V z for eigenpair (θ, z) of T.
   --  Z is length Steps; returns length-N vector in ambient space.
   function Ritz_Vector
     (Res : Result; Z : Vector) return Vector
     with Pre => Res.Has_V
            and then Res.Steps >= 1
            and then Res.N >= 1
            and then Z'Length = Res.Steps;

end Lanczos;
