--  Lenstra_Lenstra_Lovasz — Ada 2023 educational package for Wikipedia
--  "Lenstra–Lenstra–Lovász lattice basis reduction algorithm" (LLL, 1982):
--  polynomial-time approximate shortest / nearly-orthogonal integer lattice
--  basis via Gram–Schmidt, size-reduction, and Lovász condition swaps.
--  Floating Real (digits 15) GS for classroom clarity; δ default 3/4.
--  Cap Max_Dim = 8; small 2–4 dimensional teaching examples.
--  Primary source:
--  https://en.wikipedia.org/wiki/Lenstra–Lenstra–Lovász_lattice_basis_reduction_algorithm
--  Siblings: Ada-Gram-Schmidt, Ada-Integer-Linear-Programming; next Trial
--  division (README links).

pragma Ada_2022;

package Lenstra_Lenstra_Lovasz
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Real GS + integer lattice)
   ---------------------------------------------------------------------------

   type Real is digits 15;

   Max_Dim : constant := 8;

   subtype Dimension is Natural range 0 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;

   --  Integer ambient / lattice coordinates.
   type Vector is array (Positive range <>) of Integer;

   --  Fixed-capacity vector for Basis components (use 1 .. Ambient_Dim).
   type Fixed_Vector is array (1 .. Max_Dim) of Integer;

   --  Row-oriented lattice basis: B(I) is basis vector b_I (length Ambient).
   --  Only indices 1 .. Ambient_Dim of each Fixed_Vector are meaningful;
   --  Ambient_Dim is recovered as the shared coordinate length passed to
   --  Make_Basis / carried by Basis_Bundle, or inferred when using Matrix.
   type Basis is array (Positive range <>) of Fixed_Vector;

   --  Dense integer matrix view: rows = basis vectors (same convention).
   type Matrix is
     array (Positive range <>, Positive range <>) of Integer;

   --  Real working vectors / matrices for Gram–Schmidt.
   type Real_Vector is array (Positive range <>) of Real;
   type Real_Matrix is
     array (Positive range <>, Positive range <>) of Real;

   --  Bundle: N basis vectors in ambient dimension M (both ≤ Max_Dim).
   type Basis_Bundle (N : Dimension := 0; M : Dimension := 0) is record
      B : Basis (1 .. Max_Dim) := [others => [others => 0]];
   end record;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Real := 1.0E-9;
   Mu_Tol      : constant Real := 1.0E-6;   -- size-reduction float slack
   Lovasz_Tol  : constant Real := 1.0E-6;   -- Lovász float slack
   Default_Delta : constant Real := 0.75;   -- classic δ = 3/4

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Dot (U, V : Vector) return Real
     with Pre => U'Length = V'Length, Global => null;

   function Dot (U, V : Real_Vector) return Real
     with Pre => U'Length = V'Length, Global => null;

   function Norm2 (V : Vector) return Real
     with Global => null;
   --  Squared Euclidean norm ‖V‖₂² as Real.

   function Norm2 (V : Real_Vector) return Real
     with Global => null;

   function Euclidean_Norm (V : Vector) return Real
     with Global => null;

   function Euclidean_Norm (V : Real_Vector) return Real
     with Global => null;

   --  Nearest integer ⌊x⌉ (half away from zero via Real'Rounding).
   function Nearest_Integer (X : Real) return Integer
     with Global => null;

   ---------------------------------------------------------------------------
   -- Construction / conversion
   ---------------------------------------------------------------------------

   function Make_Vector (X : Vector) return Fixed_Vector
     with Pre => X'Length >= 1 and then X'Length <= Max_Dim,
          Global => null;
   --  Copy X into a Fixed_Vector (remaining slots 0).

   function Slice (V : Fixed_Vector; M : Dimension) return Vector
     with Pre => M >= 1, Global => null;
   --  First M coordinates of V as an unconstrained Vector.

   function Make_Basis (Rows : Matrix) return Basis_Bundle
     with Pre => Rows'Length (1) >= 1
            and then Rows'Length (2) >= 1
            and then Rows'Length (1) <= Max_Dim
            and then Rows'Length (2) <= Max_Dim,
          Global => null;
   --  Each matrix row becomes one basis vector.

   function To_Matrix (Bundle : Basis_Bundle) return Matrix
     with Pre => Bundle.N >= 1 and then Bundle.M >= 1,
          Global => null;

   function Copy_Basis (Bundle : Basis_Bundle) return Basis_Bundle
     with Global => null;

   ---------------------------------------------------------------------------
   -- Gram–Schmidt (floating, unnormalized)
   ---------------------------------------------------------------------------

   --  On output: Bstar(i,*) = b*_i, Mu(i,j) = μ_{i,j} for j < i (0 on/above).
   --  Bstar_Norm2(i) = ‖b*_i‖₂².
   procedure Gram_Schmidt
     (Bundle      : Basis_Bundle;
      Bstar       : out Real_Matrix;
      Mu          : out Real_Matrix;
      Bstar_Norm2 : out Real_Vector)
     with Pre => Bundle.N >= 1
            and then Bundle.M >= 1
            and then Bstar'Length (1) >= Bundle.N
            and then Bstar'Length (2) >= Bundle.M
            and then Mu'Length (1) >= Bundle.N
            and then Mu'Length (2) >= Bundle.N
            and then Bstar_Norm2'Length >= Bundle.N;

   ---------------------------------------------------------------------------
   -- Predicates / volume
   ---------------------------------------------------------------------------

   function Is_Size_Reduced
     (Bundle : Basis_Bundle; Tol : Real := Mu_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  |μ_{i,j}| ≤ 1/2 + Tol for all 1 ≤ j < i ≤ N.

   function Satisfies_Lovasz
     (Bundle : Basis_Bundle;
      Reduction_Delta : Real := Default_Delta;
      Tol    : Real := Lovasz_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;
   --  δ‖b*_{k-1}‖² ≤ ‖b*_k‖² + μ_{k,k-1}²‖b*_{k-1}‖² (+Tol slack).

   function Is_LLL_Reduced
     (Bundle : Basis_Bundle;
      Reduction_Delta : Real := Default_Delta;
      Tol    : Real := Mu_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   --  Educational lattice volume ≈ ∏ ‖b*_i‖ (absolute parallelepiped volume).
   function Volume (Bundle : Basis_Bundle) return Real
     with Pre => Bundle.N >= 1 and then Bundle.M >= 1,
          Global => null;

   function Max_Euclidean_Norm (Bundle : Basis_Bundle) return Real
     with Pre => Bundle.N >= 1 and then Bundle.M >= 1,
          Global => null;

   function Sum_Squared_Norms (Bundle : Basis_Bundle) return Real
     with Pre => Bundle.N >= 1 and then Bundle.M >= 1,
          Global => null;

   ---------------------------------------------------------------------------
   -- LLL reduction
   ---------------------------------------------------------------------------

   --  LLL-reduce Bundle with parameter δ ∈ (1/4, 1]. Default δ = 3/4.
   --  Raises Invalid_Argument if N = 0, M = 0, or Reduction_Delta ≤ 1/4, or Reduction_Delta > 1.
   function LLL_Reduce
     (Bundle : Basis_Bundle;
      Reduction_Delta : Real := Default_Delta) return Basis_Bundle
     with Pre => Bundle.N <= Max_Dim and then Bundle.M <= Max_Dim;

   --  Matrix convenience: rows in, rows out (same shape).
   function LLL_Reduce
     (B     : Matrix;
      Reduction_Delta : Real := Default_Delta) return Matrix
     with Pre => B'Length (1) >= 1
            and then B'Length (2) >= 1
            and then B'Length (1) <= Max_Dim
            and then B'Length (2) <= Max_Dim;

   --  Basis-array convenience: Ambient is coordinate length of each vector.
   function LLL_Reduce
     (B       : Basis;
      Ambient : Dimension;
      Reduction_Delta : Real := Default_Delta) return Basis
     with Pre => B'Length >= 1
            and then Ambient >= 1
            and then B'Length <= Max_Dim
            and then Ambient <= Max_Dim;

end Lenstra_Lenstra_Lovasz;
