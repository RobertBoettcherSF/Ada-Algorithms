--  Levinson_Recursion — Ada 2023 educational package for Wikipedia
--  "Levinson recursion" / Levinson–Durbin: O(n^2) solution of Toeplitz
--  linear systems T x = y. Forward/backward vectors, reflection
--  (PARCOR) coefficients, and Durbin's Yule–Walker specialization for
--  linear prediction. Cap n ≤ 128; dense educational Float.
--  Primary source:
--  https://en.wikipedia.org/wiki/Levinson_recursion
--  Siblings: Ada-Thomas-Algorithm, Ada-Gaussian-Elimination (forthcoming),
--  Ada-Conjugate-Gradient (README links).

pragma Ada_2022;

package Levinson_Recursion
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types (educational Float)
   ---------------------------------------------------------------------------

   Max_N : constant := 128;

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   --  1-based educational vectors.
   type Vector is array (Positive range <>) of Float;

   --  First row (and, for symmetric T, first column) of an n×n Toeplitz
   --  matrix: R(1) = t_0 on the main diagonal, R(k) = t_{k-1} = T_{1,k}.
   --  Symmetric convention: T_{i,j} = R(1 + |i-j|).
   subtype Toeplitz_Row is Vector;

   type Status is
     (Ok, Degenerate, Ill_Started, Size_Mismatch);

   type Result is record
      X       : Vector (1 .. Max_N) := [others => 0.0];
      N       : Dimension := 0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
      Order   : Dim_Index := 1;  --  step where E_m / denom vanished
   end record;

   --  Reflection / PARCOR coefficients from Durbin or Levinson steps.
   type Reflection_Result is record
      K       : Vector (1 .. Max_N) := [others => 0.0];
      N       : Dimension := 0;   --  number of coefficients stored
      E       : Float := 0.0;     --  final prediction-error power E_N
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
      Order   : Dim_Index := 1;
   end record;

   --  Durbin / Yule–Walker prediction-coefficient result.
   type Durbin_Result is record
      A       : Vector (1 .. Max_N) := [others => 0.0];  --  a_1 .. a_P
      K       : Vector (1 .. Max_N) := [others => 0.0];  --  PARCOR k_1 .. k_P
      P       : Dimension := 0;
      E       : Float := 0.0;
      Stat    : Status := Ill_Started;
      Success : Boolean := False;
      Order   : Dim_Index := 1;
   end record;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-10;
   Pivot_Tol   : constant Float := 1.0E-12;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Vec_Near
     (A, B : Vector; Tol : Float := Epsilon_Tol) return Boolean
     with Pre => A'Length = B'Length and then Tol >= 0.0,
          Global => null;

   function Norm2 (V : Vector) return Float
     with Global => null;

   function Max_Abs (V : Vector) return Float
     with Global => null;

   function Zero_Vector (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   function Ones_Vector (N : Dimension; Value : Float := 1.0) return Vector
     with Pre => N >= 1, Global => null;

   ---------------------------------------------------------------------------
   -- Toeplitz structure helpers
   ---------------------------------------------------------------------------

   --  Entry T_{I,J} from symmetric Toeplitz row R (1-based I,J in 1..N).
   function Toeplitz_Entry
     (R : Toeplitz_Row; I, J : Positive) return Float
     with Pre => R'Length >= 1
            and then I >= 1 and then J >= 1
            and then I <= R'Length and then J <= R'Length,
          Global => null;

   --  Dense multiply y := T x for symmetric Toeplitz defined by R.
   function Multiply_Toeplitz
     (R : Toeplitz_Row; X : Vector) return Vector
     with Pre => R'Length = X'Length and then X'Length >= 1,
          Global => null;

   --  Residual r = Y − T X (dense multiply).
   function Residual
     (R : Toeplitz_Row; Y, X : Vector) return Vector
     with Pre => R'Length = Y'Length
            and then Y'Length = X'Length
            and then X'Length >= 1,
          Global => null;

   function Residual_Norm
     (R : Toeplitz_Row; Y, X : Vector) return Float
     with Pre => R'Length = Y'Length
            and then Y'Length = X'Length
            and then X'Length >= 1,
          Global => null;

   function Residual_Max_Abs
     (R : Toeplitz_Row; Y, X : Vector) return Float
     with Pre => R'Length = Y'Length
            and then Y'Length = X'Length
            and then X'Length >= 1,
          Global => null;

   --  Build a decaying SPD-ish Toeplitz row: R(1)=Diag, R(k)=Scale*Rho^{k-1}.
   procedure Make_Exponential_Toeplitz
     (N     : Dimension;
      Diag  : Float;
      Rho   : Float;
      Scale : Float := 1.0;
      R     : out Toeplitz_Row)
     with Pre => N >= 1
            and then R'First = 1 and then R'Last = N
            and then abs (Rho) < 1.0;

   --  Constant-diagonal Toeplitz: R(1)=Diag, R(k)=Off for k>1.
   procedure Make_Constant_Toeplitz
     (N          : Dimension;
      Diag, Off  : Float;
      R          : out Toeplitz_Row)
     with Pre => N >= 1
            and then R'First = 1 and then R'Last = N;

   ---------------------------------------------------------------------------
   -- Levinson solve (symmetric Toeplitz T x = Y)
   ---------------------------------------------------------------------------

   --  Classical Levinson recursion via forward/backward vectors.
   --  Returns Degenerate when |t_0| or |1−ε_f²| ≤ Pivot_Tol (singular /
   --  zero E_m analogue).
   function Solve_Levinson
     (R : Toeplitz_Row; Y : Vector) return Result
     with Pre => R'Length = Y'Length
            and then Y'Length >= 1
            and then Y'Length <= Max_N;

   --  Alias of Solve_Levinson.
   function Solve
     (R : Toeplitz_Row; Y : Vector) return Result
     with Pre => R'Length = Y'Length
            and then Y'Length >= 1
            and then Y'Length <= Max_N;

   ---------------------------------------------------------------------------
   -- Durbin / Yule–Walker and reflection (PARCOR) coefficients
   ---------------------------------------------------------------------------

   --  Durbin recursion for the Yule–Walker system
   --  T a = −ρ with ρ = (R(2),…,R(P+1)) and T the P×P Toeplitz matrix
   --  built from R(1..P). Input R must have length P+1 (lags 0..P).
   function Durbin_Yule_Walker
     (R : Toeplitz_Row) return Durbin_Result
     with Pre => R'Length >= 2 and then R'Length - 1 <= Max_N;

   --  Reflection / PARCOR coefficients k_1..k_{N−1} arising while solving
   --  an N×N Levinson system (same k-sequence as Durbin of order N−1 on
   --  R(1..N)). Also returns final E_{N−1}.
   function Reflection_Coefficients
     (R : Toeplitz_Row) return Reflection_Result
     with Pre => R'Length >= 1 and then R'Length <= Max_N;

end Levinson_Recursion;
