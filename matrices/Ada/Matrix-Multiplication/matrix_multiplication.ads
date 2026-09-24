--  Matrix_Multiplication — Ada 2023 educational survey package for Wikipedia
--  "Matrix multiplication algorithm": taxonomy of classical / Strassen / CW /
--  Cannon / Freivalds / SUMMA / laser-family methods, with runnable sketches
--  for Classical, Strassen (7-product), Cannon (sequential mesh simulation),
--  and Freivalds verification (exact Integer). CW / SUMMA / Laser are
--  catalogue-only (Not_Implemented / Galactic_Only). Self-contained; siblings
--  linked in README only — no package dependencies.
--  Cap n ≤ 32; educational Float for multiply, Integer for Freivalds.
--  Primary source:
--  https://en.wikipedia.org/wiki/Matrix_multiplication_algorithm

pragma Ada_2022;

package Matrix_Multiplication
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   Max_N : constant := 32;

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   --  Float matrices for runnable multiply sketches.
   type Matrix is array (Positive range <>, Positive range <>) of Float;

   --  Exact Integer matrices / vectors for Freivalds verification path.
   type Int_Matrix is array (Positive range <>, Positive range <>) of Integer;
   type Int_Vector is array (Positive range <>) of Integer;

   Default_Leaf   : constant Positive := 1;
   Default_Grid_P : constant Natural := 0;
   Default_Trials : constant Positive := 8;
   Default_Seed   : constant Natural := 1;

   type Status is
     (Ok,
      Dimension_Error,
      Ill_Started,
      Not_Implemented,
      Galactic_Only);
   --  Not_Implemented / Galactic_Only: CW, SUMMA, Laser_Family (and Freivalds
   --  when dispatched through Multiply) are catalogue-only rejects.

   type Multiply_Result is record
      C                 : Matrix (1 .. Max_N, 1 .. Max_N) :=
                            [others => [others => 0.0]];
      N                 : Dimension := 0;
      Stat              : Status := Ill_Started;
      Success           : Boolean := False;
      Scalar_Multiplies : Natural := 0;
      Recursion_Depth   : Natural := 0;
      Padded_N          : Dimension := 0;
      Grid_P            : Natural := 0;
      Block_Size        : Natural := 0;
      Shift_Count       : Natural := 0;
      Method            : Natural := 0;
      --  Method encodes Method_Kind'Pos when Success or catalogue reject.
   end record;

   --  Monte Carlo one-sided Freivalds verdict.
   type Verdict is (Equal_Probably, Unequal, Dimension_Error);

   type Verify_Result is record
      Stat        : Verdict := Dimension_Error;
      N           : Dimension := 0;
      Trials_Used : Natural := 0;
      Failures    : Natural := 0;
      Seed_Final  : Natural := 0;
   end record;

   type Int_Multiply_Result is record
      C       : Int_Matrix (1 .. Max_N, 1 .. Max_N) :=
                  [others => [others => 0]];
      N       : Dimension := 0;
      Success : Boolean := False;
   end record;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-5;

   ---------------------------------------------------------------------------
   -- Method taxonomy
   ---------------------------------------------------------------------------

   type Method_Kind is
     (Classical,
      Strassen,
      Coppersmith_Winograd,
      Cannon,
      Freivalds_Verify,
      SUMMA,
      Laser_Family);
   --  SUMMA / Coppersmith_Winograd / Laser_Family: catalogue placeholders.
   --  Freivalds_Verify: verification (not a multiplier); use Verify_Freivalds.

   Classical_Exponent_Const : constant Float := 3.0;
   CW_Exponent_Const        : constant Float := 2.3755;
   Laser_Exponent_Const     : constant Float := 2.373;
   SUMMA_Exponent_Const     : constant Float := 3.0;
   Cannon_Exponent_Const    : constant Float := 3.0;
   Freivalds_Exponent_Const : constant Float := 2.0;
   --  Freivalds is O(k n^2) verification cost (not multiply exponent).

   type Method_Info is record
      Kind            : Method_Kind;
      Exponent        : Float;
      Practical       : Boolean;
      Runnable_Sketch : Boolean;
      Year            : Natural;
      Is_Parallel     : Boolean;
      Is_Verification : Boolean;
   end record;

   ---------------------------------------------------------------------------
   -- Historical milestone table (queryable)
   ---------------------------------------------------------------------------

   type Milestone is record
      Year     : Natural;
      Exponent : Float;
      Label    : String (1 .. 52);
      Len      : Natural;
   end record;

   Milestone_Count : constant Positive := 8;

   ---------------------------------------------------------------------------
   -- Numeric / structural helpers (Float)
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Epsilon_Tol) return Boolean
     with Pre => Tol >= 0.0, Global => null;

   function Mat_Near
     (A, B : Matrix; Tol : Float := Epsilon_Tol) return Boolean
     with Pre =>
       A'Length (1) = B'Length (1)
       and then A'Length (2) = B'Length (2)
       and then Tol >= 0.0,
          Global => null;

   function Norm_Frobenius (A : Matrix) return Float
     with Global => null;

   function Diff_Frobenius (A, B : Matrix) return Float
     with Pre =>
       A'Length (1) = B'Length (1)
       and then A'Length (2) = B'Length (2),
          Global => null;

   function Is_Square (A : Matrix) return Boolean
     with Global => null;

   function Is_Square_Int (A : Int_Matrix) return Boolean
     with Global => null;

   function Is_Power_Of_Two (N : Natural) return Boolean
     with Global => null;

   function Next_Power_Of_Two (N : Natural) return Natural
     with Pre => N <= Max_N, Global => null;

   function Divides (P, N : Natural) return Boolean
     with Global => null;

   function Is_Valid_Grid (N, P : Natural) return Boolean
     with Global => null;

   function Mat_Add (A, B : Matrix) return Matrix
     with Pre =>
       A'Length (1) = B'Length (1)
       and then A'Length (2) = B'Length (2),
          Global => null;

   function Mat_Sub (A, B : Matrix) return Matrix
     with Pre =>
       A'Length (1) = B'Length (1)
       and then A'Length (2) = B'Length (2),
          Global => null;

   function Mat_Scale (A : Matrix; S : Float) return Matrix
     with Global => null;

   ---------------------------------------------------------------------------
   -- Padding / trimming (Strassen)
   ---------------------------------------------------------------------------

   function Pad_To_Power_Of_Two (A : Matrix) return Matrix
     with Pre =>
       Is_Square (A)
       and then A'Length (1) <= Max_N
       and then A'Length (1) >= 1,
          Global => null;

   function Trim (A : Matrix; N : Dimension) return Matrix
     with Pre =>
       Is_Square (A)
       and then N >= 1
       and then N <= A'Length (1),
          Global => null;

   ---------------------------------------------------------------------------
   -- Float builders
   ---------------------------------------------------------------------------

   function Zeros (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   function Ones (N : Dimension; Value : Float := 1.0) return Matrix
     with Pre => N >= 1, Global => null;

   function Identity (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   function Sequential_Fill (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   function Deterministic (N : Dimension; Seed : Natural := 1) return Matrix
     with Pre => N >= 1, Global => null;

   function Make_Hilbert (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   ---------------------------------------------------------------------------
   -- Integer builders / helpers (Freivalds path)
   ---------------------------------------------------------------------------

   function Int_Zeros (N : Dimension) return Int_Matrix
     with Pre => N >= 1, Global => null;

   function Int_Ones (N : Dimension; Value : Integer := 1) return Int_Matrix
     with Pre => N >= 1, Global => null;

   function Int_Identity (N : Dimension) return Int_Matrix
     with Pre => N >= 1, Global => null;

   function Int_Sequential_Fill (N : Dimension) return Int_Matrix
     with Pre => N >= 1, Global => null;

   function Int_Deterministic
     (N : Dimension; Seed : Natural := 1) return Int_Matrix
     with Pre => N >= 1, Global => null;

   function Int_Mat_Equal (A, B : Int_Matrix) return Boolean
     with Pre =>
       A'Length (1) = B'Length (1)
       and then A'Length (2) = B'Length (2),
          Global => null;

   function Int_Mat_Vec (A : Int_Matrix; X : Int_Vector) return Int_Vector
     with Pre =>
       A'Length (2) = X'Length
       and then A'Length (1) >= 1
       and then X'Length >= 1,
          Global => null;

   function Corrupt_Entry
     (A : Int_Matrix; Row, Col : Positive; Offset : Integer := 1)
      return Int_Matrix
     with Pre =>
       Is_Square_Int (A)
       and then Row in A'Range (1)
       and then Col in A'Range (2),
          Global => null;

   procedure LCG_Next (State : in out Natural)
     with Global => null;

   function LCG_Bit (State : in out Natural) return Integer
     with Global => null;

   function Random_01_Vector
     (N : Dimension; Seed : in out Natural) return Int_Vector
     with Pre => N >= 1, Global => null;

   ---------------------------------------------------------------------------
   -- Taxonomy queries
   ---------------------------------------------------------------------------

   function Method_Count return Positive
     with Global => null;

   function Method_Name (M : Method_Kind) return String
     with Global => null;

   function Exponent_Of (M : Method_Kind) return Float
     with Global => null;

   function Is_Practical (M : Method_Kind) return Boolean
     with Global => null;

   function Supports_Runnable (M : Method_Kind) return Boolean
     with Global => null;
   --  True for Classical, Strassen, Cannon, Freivalds_Verify.
   --  False for Coppersmith_Winograd, SUMMA, Laser_Family.

   function Describe (M : Method_Kind) return String
     with Global => null;

   function Classify_Method (M : Method_Kind) return Method_Info
     with Global => null;

   function Get_Milestone (Index : Positive) return Milestone
     with Pre => Index <= Milestone_Count, Global => null;

   function Milestone_Label (Index : Positive) return String
     with Pre => Index <= Milestone_Count, Global => null;

   ---------------------------------------------------------------------------
   -- Complexity estimator / recommendation
   ---------------------------------------------------------------------------

   function Estimated_Ops (N : Natural; Method : Method_Kind) return Float
     with Pre => N >= 1 and then N <= Max_N, Global => null;
   --  N ** Exponent_Of(Method) as educational Float.

   function Recommend_Method
     (N : Natural; Prefer_Parallel : Boolean := False) return Method_Kind
     with Pre => N >= 1 and then N <= Max_N, Global => null;
   --  Educational heuristic:
   --    Prefer_Parallel and N ≥ 2 → Cannon (mesh sketch)
   --    N ≥ 16 → Strassen (borderline teaching regime)
   --    else → Classical
   --  Never recommends CW / SUMMA / Laser / Freivalds_Verify.

   ---------------------------------------------------------------------------
   -- Runnable sketches (Float multiply)
   ---------------------------------------------------------------------------

   function Multiply_Classical (A, B : Matrix) return Multiply_Result
     with Pre =>
       Is_Square (A)
       and then Is_Square (B)
       and then A'Length (1) = B'Length (1),
          Global => null;

   function Multiply_Strassen
     (A    : Matrix;
      B    : Matrix;
      Leaf : Positive := Default_Leaf) return Multiply_Result
     with Pre =>
       Is_Square (A)
       and then Is_Square (B)
       and then A'Length (1) = B'Length (1)
       and then Leaf >= 1,
          Global => null;

   function Multiply_Cannon
     (A      : Matrix;
      B      : Matrix;
      Grid_P : Natural := Default_Grid_P) return Multiply_Result
     with Pre =>
       Is_Square (A)
       and then Is_Square (B)
       and then A'Length (1) = B'Length (1),
          Global => null;
   --  Sequential simulation of Cannon (1969) on a P×P PE mesh.
   --  Grid_P = 0 defaults to P = n (element-per-PE).

   --  Dispatch by Method_Kind. Classical / Strassen / Cannon run sketches;
   --  CW / SUMMA / Laser / Freivalds_Verify return catalogue reject.
   function Multiply
     (A      : Matrix;
      B      : Matrix;
      Method : Method_Kind;
      Leaf   : Positive := Default_Leaf;
      Grid_P : Natural := Default_Grid_P) return Multiply_Result
     with Pre =>
       Is_Square (A)
       and then Is_Square (B)
       and then A'Length (1) = B'Length (1)
       and then Leaf >= 1,
          Global => null;

   function Product_Matrix (R : Multiply_Result) return Matrix
     with Pre => R.Success and then R.N >= 1, Global => null;

   ---------------------------------------------------------------------------
   -- Freivalds verification (Integer)
   ---------------------------------------------------------------------------

   function Multiply_Classical_Int
     (A, B : Int_Matrix) return Int_Multiply_Result
     with Pre =>
       Is_Square_Int (A)
       and then Is_Square_Int (B)
       and then A'Length (1) = B'Length (1),
          Global => null;

   function Int_Product_Matrix (R : Int_Multiply_Result) return Int_Matrix
     with Pre => R.Success and then R.N >= 1, Global => null;

   function Verify_Freivalds
     (A      : Int_Matrix;
      B      : Int_Matrix;
      C      : Int_Matrix;
      Trials : Positive := Default_Trials;
      Seed   : Natural := Default_Seed) return Verify_Result
     with Pre =>
       Is_Square_Int (A)
       and then Is_Square_Int (B)
       and then Is_Square_Int (C)
       and then A'Length (1) = B'Length (1)
       and then A'Length (1) = C'Length (1),
          Global => null;
   --  Monte Carlo: for each trial draw r ∈ {0,1}^n; check A(Br)=Cr.
   --  AB=C ⇒ always Equal_Probably; AB≠C ⇒ P(miss) ≤ 2^{-Trials}.

   function Verify_Freivalds_Once
     (A : Int_Matrix; B : Int_Matrix; C : Int_Matrix; Seed : in out Natural)
      return Verdict
     with Pre =>
       Is_Square_Int (A)
       and then Is_Square_Int (B)
       and then Is_Square_Int (C)
       and then A'Length (1) = B'Length (1)
       and then A'Length (1) = C'Length (1),
          Global => null;

end Matrix_Multiplication;
