--  Kalman_Filter — Ada 2023 educational package for Wikipedia
--  "Kalman filter" / linear quadratic estimation (Rudolf E. Kálmán, 1960):
--  discrete-time linear Gaussian predict / update for state estimation from
--  noisy measurements. Implements the Wikipedia discrete KF:
--    Predict:  x̂_{k|k-1} = F x̂ + B u ;  P_{k|k-1} = F P Fᵀ + Q
--    Update:   ỹ = z − H x̂ ;  S = H P Hᵀ + R ;  K = P Hᵀ S⁻¹
--              x̂_{k|k} = x̂ + K ỹ ;  P via Joseph form (numerically preferred)
--  Scalar (1-D) specialization plus fixed small dense vector form (Max_Dim=4).
--  Related (not implemented): extended KF (EKF), unscented KF (UKF).

pragma Ada_2022;

package Kalman_Filter
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types
   ---------------------------------------------------------------------------

   --  Digits 12 for stable covariance / gain arithmetic.
   type Real is digits 12;

   subtype Non_Negative is Real range 0.0 .. Real'Last;
   subtype Positive_Real is Real range Real'Model_Small .. Real'Last;

   Max_Dim : constant Positive := 4;
   subtype Dim_Count is Natural  range 0 .. Max_Dim;
   subtype Dim_Index is Positive range 1 .. Max_Dim;

   --  Index subtype is Positive so null slices (1 .. 0) are legal;
   --  Cap at Max_Dim is enforced by Pre / runtime checks.
   type Vector is array (Positive range <>) of Real;
   type Matrix is array (Positive range <>, Positive range <>) of Real;

   ---------------------------------------------------------------------------
   -- Exceptions
   ---------------------------------------------------------------------------

   Invalid_Argument    : exception;
   Degenerate_Geometry : exception;
   Capacity_Exceeded   : exception;

   ---------------------------------------------------------------------------
   -- Numeric helpers
   ---------------------------------------------------------------------------

   Epsilon_Tol : constant Real := 1.0E-8;
   --  Absolute |S| / pivot below which innovation covariance is singular.
   Singularity_Tol : constant Real := 1.0E-14;

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Identity (N : Dim_Count) return Matrix
     with Pre => N >= 1, Global => null;
   --  N×N identity. Raises Invalid_Argument if N = 0.

   ---------------------------------------------------------------------------
   -- Dense linear algebra (fixed small dimension)
   ---------------------------------------------------------------------------

   function Zero_Vector (N : Dim_Count) return Vector
     with Pre => N >= 1, Global => null;

   function Zero_Matrix (Rows, Cols : Dim_Count) return Matrix
     with Pre => Rows >= 1 and then Cols >= 1, Global => null;

   function Transpose (A : Matrix) return Matrix
     with Pre => A'Length (1) >= 1 and then A'Length (2) >= 1,
          Global => null;

   function "+" (A, B : Matrix) return Matrix
     with Pre => A'First (1) = B'First (1)
       and then A'Last (1) = B'Last (1)
       and then A'First (2) = B'First (2)
       and then A'Last (2) = B'Last (2),
          Global => null;

   function "-" (A, B : Matrix) return Matrix
     with Pre => A'First (1) = B'First (1)
       and then A'Last (1) = B'Last (1)
       and then A'First (2) = B'First (2)
       and then A'Last (2) = B'Last (2),
          Global => null;

   function "*" (A, B : Matrix) return Matrix
     with Pre => A'Length (2) = B'Length (1)
       and then A'First (2) = B'First (1),
          Global => null;

   function "*" (A : Matrix; V : Vector) return Vector
     with Pre => A'Length (2) = V'Length and then A'First (2) = V'First,
          Global => null;

   function "+" (U, V : Vector) return Vector
     with Pre => U'First = V'First and then U'Last = V'Last,
          Global => null;

   function "-" (U, V : Vector) return Vector
     with Pre => U'First = V'First and then U'Last = V'Last,
          Global => null;

   function Scale (A : Matrix; S : Real) return Matrix
     with Global => null;

   function Scale (V : Vector; S : Real) return Vector
     with Global => null;

   --  Solve S X = B for square nonsingular S (Gaussian elimination with
   --  partial pivoting). Used for Kalman gain K = P Hᵀ S⁻¹.
   function Solve (S, B : Matrix) return Matrix
     with Pre => S'Length (1) = S'Length (2)
       and then S'Length (1) = B'Length (1)
       and then S'First (1) = B'First (1)
       and then S'First (1) = S'First (2),
          Global => null;
   --  Raises Degenerate_Geometry if S is (near-)singular.

   function Invert (S : Matrix) return Matrix
     with Pre => S'Length (1) = S'Length (2) and then S'Length (1) >= 1,
          Global => null;
   --  S⁻¹ via Solve(S, I). Raises Degenerate_Geometry if singular.

   ---------------------------------------------------------------------------
   -- Scalar Kalman filter (1-D state & measurement)
   ---------------------------------------------------------------------------

   type Scalar_State is record
      X : Real := 0.0;   --  state estimate x̂
      P : Real := 1.0;   --  variance P (≥ 0 when healthy)
   end record;

   procedure Scalar_Predict
     (State : in out Scalar_State;
      F     : Real;
      B     : Real;
      U     : Real;
      Q     : Real)
     with Pre => Q >= 0.0,
          Global => null;
   --  x̂ ← F x̂ + B u ;  P ← F² P + Q.
   --  Raises Invalid_Argument if Q < 0.

   procedure Scalar_Update
     (State      : in out Scalar_State;
      Z          : Real;
      H          : Real;
      R          : Real;
      Innovation : out Real;
      Gain       : out Real)
     with Pre => R >= 0.0,
          Global => null;
   --  ỹ = z − H x̂ ;  S = H² P + R ;  K = P H / S ;
   --  x̂ ← x̂ + K ỹ ;  Joseph: P ← (1−K H)² P + K² R.
   --  Raises Invalid_Argument if R < 0;
   --  Degenerate_Geometry if |S| < Singularity_Tol.

   procedure Scalar_Step
     (State      : in out Scalar_State;
      F, B, U, Q : Real;
      Z, H, R    : Real;
      Innovation : out Real;
      Gain       : out Real)
     with Pre => Q >= 0.0 and then R >= 0.0,
          Global => null;
   --  Scalar_Predict then Scalar_Update.

   ---------------------------------------------------------------------------
   -- Fixed small-dimension vector Kalman filter
   ---------------------------------------------------------------------------

   type Filter_State (N : Dim_Count := Max_Dim) is record
      X : Vector (1 .. N) := [others => 0.0];
      P : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   end record;

   --  Discrete linear model x' = F x + B u + w,  z = H x + v.
   --  B is optional: set Has_Control False and leave B unused.
   type Model (N : Dim_Count := Max_Dim; M : Dim_Count := Max_Dim) is record
      F           : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      H           : Matrix (1 .. M, 1 .. N) := [others => [others => 0.0]];
      Q           : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      R           : Matrix (1 .. M, 1 .. M) := [others => [others => 0.0]];
      B           : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
      Has_Control : Boolean := False;
   end record;

   procedure Predict
     (State : in out Filter_State;
      F     : Matrix;
      Q     : Matrix;
      B     : Matrix;
      U     : Vector;
      Use_B : Boolean := False)
     with Pre => State.N >= 1
       and then F'Length (1) = State.N
       and then F'Length (2) = State.N
       and then Q'Length (1) = State.N
       and then Q'Length (2) = State.N,
          Global => null;
   --  x̂ ← F x̂ (+ B u when Use_B);  P ← F P Fᵀ + Q.
   --  Raises Invalid_Argument on dimension mismatch when Use_B.

   procedure Predict
     (State : in out Filter_State;
      F     : Matrix;
      Q     : Matrix)
     with Pre => State.N >= 1
       and then F'Length (1) = State.N
       and then F'Length (2) = State.N
       and then Q'Length (1) = State.N
       and then Q'Length (2) = State.N,
          Global => null;
   --  Predict without control input.

   procedure Update
     (State      : in out Filter_State;
      Z          : Vector;
      H          : Matrix;
      R          : Matrix;
      Innovation : out Vector;
      Gain       : out Matrix)
     with Pre => State.N >= 1
       and then Z'Length >= 1
       and then H'Length (1) = Z'Length
       and then H'Length (2) = State.N
       and then R'Length (1) = Z'Length
       and then R'Length (2) = Z'Length,
          Global => null;
   --  Wikipedia update with Joseph covariance form.
   --  Raises Degenerate_Geometry if S is singular.

   procedure Filter_Step
     (State      : in out Filter_State;
      Mdl        : Model;
      Z          : Vector;
      U          : Vector;
      Innovation : out Vector;
      Gain       : out Matrix)
     with Pre => State.N = Mdl.N
       and then State.N >= 1
       and then Z'Length = Mdl.M,
          Global => null;
   --  Predict then Update using model matrices (U used iff Mdl.Has_Control).

   procedure Filter_Step
     (State      : in out Filter_State;
      Mdl        : Model;
      Z          : Vector;
      Innovation : out Vector;
      Gain       : out Matrix)
     with Pre => State.N = Mdl.N
       and then State.N >= 1
       and then Z'Length = Mdl.M
       and then not Mdl.Has_Control,
          Global => null;

end Kalman_Filter;
