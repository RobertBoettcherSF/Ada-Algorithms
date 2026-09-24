--  Biconjugate_Gradient — Ada 2023 educational package for Wikipedia
--  "Biconjugate gradient method" (Fletcher, 1976): iterative solver for
--  nonsymmetric (or indefinite) linear systems Ax = b. Maintains a pair
--  of residual / search-direction sequences and needs matvecs with both
--  A and Aᵀ (real transpose). Does NOT require SPD/symmetry. Cap n ≤ 16;
--  dense Float. Classic BiCG only — BiCGSTAB is a sibling topic (README).
--  Primary source:
--  https://en.wikipedia.org/wiki/Biconjugate_gradient_method
--  Siblings: Ada-Conjugate-Gradient / Ada-Gauss-Seidel /
--  Ada-Gaussian-Elimination / Ada-Stones-Method (README links).

pragma Ada_2022;

package Biconjugate_Gradient
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

   --  Tol      : stop when ‖r‖₂ ≤ Tol
   --  Max_Iter : hard iteration budget; 0 means use 2N (generous Krylov
   --             budget for nonsymmetric BiCG; CG uses N for SPD)
   type Parameters is record
      Tol      : Float   := 1.0E-6;
      Max_Iter : Natural := 0;
   end record;

   Default_Parameters : constant Parameters := (Tol => 1.0E-6, Max_Iter => 0);

   type Status is
     (Converged, Iteration_Limit, Breakdown, Ill_Started, Dimension_Error);

   type Result is record
      X          : Vector (1 .. Max_N) := [others => 0.0];
      N          : Dimension := 0;
      Iterations : Natural := 0;
      Residual   : Float := 0.0;
      Stat       : Status := Ill_Started;
      Success    : Boolean := False;
   end record;

   type Example_Kind is
     (Nonsym_DD, Conv_Diff_1D, SPD_Poisson, Fixed_2x2, Fixed_3x3);

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-10;

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
   --  y = A x

   function Mat_Vec_T (A : Matrix; X : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length,
          Global => null;
   --  y = Aᵀ x  (real transpose matvec; no explicit transpose stored)

   function Transpose (A : Matrix) return Matrix
     with Pre => A'Length (1) = A'Length (2), Global => null;

   function Is_Symmetric
     (A : Matrix; Tol : Float := 1.0E-6) return Boolean
     with Pre => A'Length (1) = A'Length (2) and then Tol >= 0.0,
          Global => null;

   function Is_Diagonally_Dominant (A : Matrix) return Boolean
     with Pre => A'Length (1) = A'Length (2), Global => null;

   function Residual (A : Matrix; X, B : Vector) return Vector
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length = B'Length,
          Global => null;
   --  r = b − A x

   function Residual_Norm (A : Matrix; X, B : Vector) return Float
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = X'Length
            and then X'Length = B'Length,
          Global => null;
   --  ‖b − A x‖₂

   ---------------------------------------------------------------------------
   -- Example generators (nonsymmetric + SPD recovery)
   ---------------------------------------------------------------------------

   function Make_Example
     (Kind : Example_Kind; N : Dimension) return Matrix
     with Pre =>
       (case Kind is
          when Fixed_2x2 => N = 2,
          when Fixed_3x3 => N = 3,
          when others    => N >= 1),
       Global => null;
   --  Nonsym_DD     : nonsymmetric diagonally dominant (row-wise)
   --  Conv_Diff_1D  : convection–diffusion-ish tridiagonal (nonsym)
   --  SPD_Poisson   : (−1, 2, −1) discrete Laplacian (SPD; BiCG still works)
   --  Fixed_2x2     : small nonsym with known solution path (N must be 2)
   --  Fixed_3x3     : small nonsym with known solution path (N must be 3)

   function Make_RHS_Ones (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   function Zero_Vector (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   ---------------------------------------------------------------------------
   -- Classical unpreconditioned BiCG for Ax = b
   ---------------------------------------------------------------------------

   function Biconjugate_Gradient
     (A      : Matrix;
      B      : Vector;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length = X0'Length
            and then B'Length >= 1
            and then B'Length <= Max_N;
   --  Unpreconditioned BiCG (real A). Shadow residual r̃₀ := r₀.
   --  Detects Breakdown when ρ = r̃ᵀ r or p̃ᵀ A p vanishes.

   function Solve
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
     with Pre => A'Length (1) = A'Length (2)
            and then A'Length (2) = B'Length
            and then B'Length >= 1
            and then B'Length <= Max_N
            and then (X0'Length = 0 or else X0'Length = B'Length);
   --  Convenience wrapper: empty X0 ⇒ start at the zero vector.
   --  Returns Dimension_Error / Ill_Started on bad input via Status
   --  when length checks fail at runtime (Pre also guards).

end Biconjugate_Gradient;
