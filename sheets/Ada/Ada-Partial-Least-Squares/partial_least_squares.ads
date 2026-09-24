--  Partial_Least_Squares — Ada 2023 educational package for Wikipedia
--  "Partial least squares regression": latent-variable bilinear model
--  X = T P^T + E,  Y = U Q^T + F, maximising covariance between scores.
--  Implements PLS1 (single response) and a compact PLS2 NIPALS sketch
--  (multi-response). Herman/Svante Wold; chemometrics classic.
--
--  Normalisation / deflation (documented, not Wikipedia's imperfect PLS1
--  t-scaling): for each component
--    w ∝ X^T y;  ||w||_2 = 1;
--    t = X w;
--    p = X^T t / (t^T t);  q = y^T t / (t^T t);
--    X := X − t p^T;  y := y − t q   (y-deflation used here);
--  then B = W (P^T W)^{−1} q.  Scores t are orthogonal; w unit-norm.
--  Related: SIMPLS (de Jong) is an alternative not implemented here.

pragma Ada_2022;

package Partial_Least_Squares
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Rows       : constant Positive := 256;
   Max_Cols       : constant Positive := 128;
   Max_Responses  : constant Positive := 16;
   Max_Components : constant Positive := 64;

   subtype Row_Count       is Natural  range 0 .. Max_Rows;
   subtype Col_Count       is Natural  range 0 .. Max_Cols;
   subtype Response_Count  is Natural  range 0 .. Max_Responses;
   subtype Component_Count is Natural  range 0 .. Max_Components;
   subtype Row_Index       is Positive range 1 .. Max_Rows;
   subtype Col_Index       is Positive range 1 .. Max_Cols;
   subtype Response_Index  is Positive range 1 .. Max_Responses;
   subtype Component_Index is Positive range 1 .. Max_Components;

   --  Row-major storage: Matrix (I, J) is row I, column J.
   type Matrix is array (Row_Index range <>, Col_Index range <>) of Real;
   type Vector is array (Positive range <>) of Real;

   --  Multi-response Y (n × p).
   type Y_Matrix is array (Row_Index range <>, Response_Index range <>) of Real;
   --  Regression coefficients B (m × p).
   type Coef_Matrix is
     array (Col_Index range <>, Response_Index range <>) of Real;
   --  Y-loadings C (p × ℓ).
   type Loading_Y_Matrix is
     array (Response_Index range <>, Component_Index range <>) of Real;
   --  Dense square scratch for (P^T W) (ℓ × ℓ), indexed by component.
   type Square is
     array (Component_Index range <>, Component_Index range <>) of Real;

   type PLS1_Model is record
      N_Rows       : Row_Count       := 0;
      N_Cols       : Col_Count       := 0;
      N_Components : Component_Count := 0;
      Centered     : Boolean         := False;
      --  Regression: ŷ = B0 + X · B  (X in original scale; means applied).
      B            : Vector (1 .. Max_Cols) := [others => 0.0];
      B0           : Real := 0.0;
      X_Mean       : Vector (1 .. Max_Cols) := [others => 0.0];
      Y_Mean       : Real := 0.0;
      --  Latent factors (columns 1 .. N_Components).
      W            : Matrix (1 .. Max_Cols, 1 .. Max_Components) :=
                       [others => [others => 0.0]];
      P            : Matrix (1 .. Max_Cols, 1 .. Max_Components) :=
                       [others => [others => 0.0]];
      T            : Matrix (1 .. Max_Rows, 1 .. Max_Components) :=
                       [others => [others => 0.0]];
      Q            : Vector (1 .. Max_Components) := [others => 0.0];
   end record;

   type PLS2_Model is record
      N_Rows       : Row_Count       := 0;
      N_Cols       : Col_Count       := 0;
      N_Responses  : Response_Count  := 0;
      N_Components : Component_Count := 0;
      Centered     : Boolean         := False;
      B            : Coef_Matrix (1 .. Max_Cols, 1 .. Max_Responses) :=
                       [others => [others => 0.0]];
      B0           : Vector (1 .. Max_Responses) := [others => 0.0];
      X_Mean       : Vector (1 .. Max_Cols) := [others => 0.0];
      Y_Mean       : Vector (1 .. Max_Responses) := [others => 0.0];
      W            : Matrix (1 .. Max_Cols, 1 .. Max_Components) :=
                       [others => [others => 0.0]];
      P            : Matrix (1 .. Max_Cols, 1 .. Max_Components) :=
                       [others => [others => 0.0]];
      C            : Loading_Y_Matrix
                       (1 .. Max_Responses, 1 .. Max_Components) :=
                       [others => [others => 0.0]];
   end record;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;
   Capacity_Exceeded   : exception;
   Singular_System     : exception renames Degenerate_Geometry;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol  : constant Real := 1.0E-8;
   Cov_Stop_Tol : constant Real := 1.0E-12;
   Singularity  : constant Real := 1.0E-14;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Dot (A, B : Vector) return Real
     with Pre => A'First = B'First and then A'Last = B'Last,
          Global => null;

   function Norm2 (V : Vector) return Non_Negative
     with Global => null;

   procedure Scale (V : in out Vector; Alpha : Real)
     with Global => null;

   procedure Axpy (Y : in out Vector; Alpha : Real; X : Vector)
     with Pre => Y'First = X'First and then Y'Last = X'Last,
          Global => null;

   --  Out_M := Out_M + Alpha * U * V^T  (rank-1 update).
   procedure Outer_Add
     (Out_M : in out Matrix;
      Alpha : Real;
      U     : Vector;
      V     : Vector)
     with Pre => Out_M'Length (1) = U'Length
       and then Out_M'Length (2) = V'Length
       and then Out_M'First (1) = U'First
       and then Out_M'First (2) = V'First,
          Global => null;

   --  Y := A * X  (A is n×m, X length m, Y length n).
   procedure Mat_Vec (A : Matrix; X : Vector; Y : out Vector)
     with Pre => A'Length (2) = X'Length
       and then A'Length (1) = Y'Length
       and then A'First (2) = X'First
       and then A'First (1) = Y'First,
          Global => null;

   --  Y := A^T * X  (A is n×m, X length n, Y length m).
   procedure Mat_T_Vec (A : Matrix; X : Vector; Y : out Vector)
     with Pre => A'Length (1) = X'Length
       and then A'Length (2) = Y'Length
       and then A'First (1) = X'First
       and then A'First (2) = Y'First,
          Global => null;

   procedure Column_Means (A : Matrix; Means : out Vector)
     with Pre => A'Length (2) = Means'Length
       and then A'First (2) = Means'First
       and then A'Length (1) >= 1,
          Global => null;

   procedure Mean_Center_Columns (A : in out Matrix; Means : Vector)
     with Pre => A'Length (2) = Means'Length
       and then A'First (2) = Means'First,
          Global => null;

   --  Divide each column by sample std (population, ddof=0); zero-std → 0.
   procedure Standardize_Columns
     (A : in out Matrix; Means : Vector; Stds : out Vector)
     with Pre => A'Length (2) = Means'Length
       and then A'Length (2) = Stds'Length
       and then A'First (2) = Means'First
       and then Means'First = Stds'First
       and then A'Length (1) >= 1,
          Global => null;

   --  Solve A Z = Q for square A (destroyed) via Gaussian elimination.
   procedure Solve_Dense (A : in out Square; Q : Vector; Z : out Vector)
     with Pre => A'Length (1) = A'Length (2)
       and then A'Length (1) = Q'Length
       and then Q'Length = Z'Length
       and then A'Length (1) >= 1
       and then A'First (1) = A'First (2)
       and then A'First (1) = Q'First
       and then Q'First = Z'First,
          Global => null;
   --  Raises Degenerate_Geometry if singular.

   function Ordinary_Least_Squares_1D (X, Y : Vector) return Real
     with Pre => X'Length = Y'Length and then X'Length >= 2,
          Global => null;
   --  Slope of demeaned y ~ a·x. Raises Degenerate_Geometry if Var(X) ~ 0.

   function R_Squared (Y_True, Y_Hat : Vector) return Real
     with Pre => Y_True'Length = Y_Hat'Length and then Y_True'Length >= 1,
          Global => null;

   function RMSE (Y_True, Y_Hat : Vector) return Non_Negative
     with Pre => Y_True'Length = Y_Hat'Length and then Y_True'Length >= 1,
          Global => null;

   ---------------------------------------------------------------------------
   -- PLS1 (single response)
   ---------------------------------------------------------------------------

   function PLS1_Fit
     (X            : Matrix;
      Y            : Vector;
      N_Components : Positive;
      Center       : Boolean := True) return PLS1_Model
     with Pre => X'Length (1) = Y'Length
       and then X'Length (1) >= 1
       and then X'Length (2) >= 1
       and then X'First (1) = Y'First
       and then N_Components <= Max_Components,
          Global => null;

   function PLS1_Predict (Model : PLS1_Model; X_New : Matrix) return Vector
     with Pre => Model.N_Cols >= 1
       and then X_New'Length (2) = Model.N_Cols
       and then X_New'Length (1) >= 1,
          Global => null;

   ---------------------------------------------------------------------------
   -- PLS2 (multi-response NIPALS, educational)
   ---------------------------------------------------------------------------

   function PLS2_Fit
     (X            : Matrix;
      Y            : Y_Matrix;
      N_Components : Positive;
      Center       : Boolean := True;
      Max_Iter     : Positive := 100;
      Tol          : Real := 1.0E-8) return PLS2_Model
     with Pre => X'Length (1) = Y'Length (1)
       and then X'Length (1) >= 1
       and then X'Length (2) >= 1
       and then Y'Length (2) >= 1
       and then X'First (1) = Y'First (1)
       and then N_Components <= Max_Components
       and then Tol > 0.0,
          Global => null;

   function PLS2_Predict (Model : PLS2_Model; X_New : Matrix) return Y_Matrix
     with Pre => Model.N_Cols >= 1
       and then Model.N_Responses >= 1
       and then X_New'Length (2) = Model.N_Cols
       and then X_New'Length (1) >= 1,
          Global => null;

end Partial_Least_Squares;
