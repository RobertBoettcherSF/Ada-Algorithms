--  Arnoldi — Ada 2023 educational package for Wikipedia "Arnoldi iteration":
--  modified Gram–Schmidt Krylov process building an orthonormal basis V_m
--  and an upper Hessenberg H_m for a general (possibly nonsymmetric) A;
--  optional Ritz values = eigenvalues of H_m when H is nearly symmetric
--  (Jacobi sketch; solid path on symmetric A where H ≈ tridiagonal).
--  Cap n ≤ 16; dense educational Float.
--  Primary source:
--  https://en.wikipedia.org/wiki/Arnoldi_iteration
--  Siblings: Ada-Lanczos (Hermitian reduction), Ada-Power-Iteration,
--  Ada-Inverse-Iteration, Ada-QR-Algorithm, Ada-Jacobi-Eigenvalue,
--  Ada-Gram-Schmidt; upcoming Eigenvalue survey (README links).

pragma Ada_2022;

package Arnoldi
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   Max_N : constant := 16;

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   type Vector is array (Positive range <>) of Float;
   type Matrix is array (Positive range <>, Positive range <>) of Float;

   --  M           : Krylov / Arnoldi steps requested (1 .. Max_N),
   --                clipped to n at run time
   --  Tol         : breakdown when h_{j+1,j} ≤ Tol
   --  Max_QR_Iter : Jacobi sweep budget when extracting Ritz from H
   --  Keep_V      : store Arnoldi basis columns in Result.V
   type Parameters is record
      M           : Natural := 8;
      Tol         : Float   := 1.0E-8;
      Max_QR_Iter : Natural := 64;
      Keep_V      : Boolean := True;
   end record;

   Default_Parameters : constant Parameters :=
     (M => 8, Tol => 1.0E-8, Max_QR_Iter => 64, Keep_V => True);

   type Status is
     (Ok,
      Breakdown,
      Iteration_Limit,
      Ill_Started,
      Dimension_Error);

   --  H (1 .. Steps, 1 .. Steps) = upper Hessenberg projection.
   --  H_Extra = h_{m+1,m} (subdiagonal after last column; may be 0 on
   --  breakdown or when Steps = n).
   --  Ritz_Values filled when Run/Iterate diagonalizes a nearly-symmetric H
   --  (typical for symmetric A); Has_Ritz marks that path.
   --  V columns 1 .. Steps hold Arnoldi vectors when Has_V.
   type Result is record
      H              : Matrix (1 .. Max_N, 1 .. Max_N) :=
                         [others => [others => 0.0]];
      V              : Matrix (1 .. Max_N, 1 .. Max_N) :=
                         [others => [others => 0.0]];
      Ritz_Values    : Vector (1 .. Max_N) := [others => 0.0];
      Ritz_Vectors   : Matrix (1 .. Max_N, 1 .. Max_N) :=
                         [others => [others => 0.0]];
      N              : Dimension := 0;
      M_Requested    : Natural := 0;
      Steps          : Natural := 0;
      H_Extra        : Float := 0.0;
      Stat           : Status := Ill_Started;
      Success        : Boolean := False;
      Has_V          : Boolean := False;
      Has_Ritz       : Boolean := False;
      Has_Ritz_Vecs  : Boolean := False;
   end record;

   type Example_Kind is
     (Diagonal_Known,
      Poisson_1D,
      Known_Spectrum_Symmetric,
      Nonsymmetric_DD);

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-10;
   Norm_Tol    : constant Float := 1.0E-14;
   Sym_Tol     : constant Float := 1.0E-5;
   Hess_Tol    : constant Float := 1.0E-5;

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

   --  True if A(i,j)=0 for all i > j+1 (upper Hessenberg), within Tol.
   function Is_Upper_Hessenberg
     (A : Matrix; Tol : Float := Hess_Tol) return Boolean
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

   --  Frobenius ‖A V − V H‖ over leading N×M (ignores h_{m+1,m} term).
   function Arnoldi_Relation_Residual
     (A : Matrix; V, H : Matrix; N, M : Dimension) return Float
     with Pre => N >= 1 and then M >= 1
            and then N <= Max_N and then M <= Max_N
            and then A'Length (1) = N and then A'Length (2) = N,
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

   function Make_Nonsymmetric_DD (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  Strictly diagonally dominant nonsymmetric teaching matrix.

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
   -- Arnoldi MGS recurrence + optional Ritz extraction
   ---------------------------------------------------------------------------

   --  Build V_m and upper Hessenberg H_m (no Ritz solve).
   --  On Breakdown, Steps < M and H_Extra ≈ 0 (invariant subspace).
   function Build_Hessenberg
     (A      : Matrix;
      V0     : Vector;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = V0'Length
            and then V0'Length >= 1
            and then V0'Length <= Max_N;

   --  Build_Hessenberg; if H is nearly symmetric, Jacobi → Ritz values.
   --  Prefer this path on symmetric A (H ≈ tridiagonal). For clearly
   --  nonsymmetric H, Success still holds with Has_Ritz = False.
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

   --  Approximate Ritz vector y = V z for eigenpair (θ, z) of H.
   --  Z is length Steps; returns length-N vector in ambient space.
   function Ritz_Vector
     (Res : Result; Z : Vector) return Vector
     with Pre => Res.Has_V
            and then Res.Steps >= 1
            and then Res.N >= 1
            and then Z'Length = Res.Steps;

end Arnoldi;
