--  Coppersmith_Winograd — Ada 2023 educational survey package for Wikipedia
--  "Coppersmith–Winograd algorithm" and the asymptotic complexity of matrix
--  multiplication. Catalogues classical / Strassen / CW / laser-family
--  exponents (ω in O(n^ω)), provides runnable Classical and Strassen sketches
--  (Float, n ≤ 32), and deliberately does NOT implement the galactic CW /
--  laser tensor recursion. Self-contained; siblings linked in README only.
--  Primary sources:
--  https://en.wikipedia.org/wiki/Coppersmith%E2%80%93Winograd_algorithm
--  https://en.wikipedia.org/wiki/Computational_complexity_of_matrix_multiplication
--  https://en.wikipedia.org/wiki/Matrix_multiplication_algorithm

pragma Ada_2022;

package Coppersmith_Winograd
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   Max_N : constant := 32;

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   type Matrix is array (Positive range <>, Positive range <>) of Float;

   --  Leaf threshold for Strassen recursion: when block size ≤ Leaf, use
   --  classical multiply. Leaf = 1 is pure Strassen (educational).
   Default_Leaf : constant Positive := 1;

   type Status is
     (Ok,
      Dimension_Error,
      Ill_Started,
      Not_Implemented,
      Galactic_Only);
   --  Not_Implemented / Galactic_Only: CW and laser-family Multiply are
   --  catalogue-only (enormous hidden constants; not coded here).

   type Multiply_Result is record
      C                 : Matrix (1 .. Max_N, 1 .. Max_N) :=
                            [others => [others => 0.0]];
      N                 : Dimension := 0;
      Stat              : Status := Ill_Started;
      Success           : Boolean := False;
      Scalar_Multiplies : Natural := 0;
      Recursion_Depth   : Natural := 0;
      Padded_N          : Dimension := 0;
      Method            : Natural := 0;
      --  Method encodes Method_Kind'Pos when Success or galactic reject.
   end record;

   Invalid_Argument : exception;

   Epsilon_Tol : constant Float := 1.0E-5;
   --  Slightly loose: Strassen accumulates more Float roundoff than classical.

   ---------------------------------------------------------------------------
   -- Method taxonomy (asymptotic matrix-multiplication families)
   ---------------------------------------------------------------------------

   type Method_Kind is
     (Classical,
      Strassen,
      Coppersmith_Winograd,
      Laser_Family);
   --  Laser_Family: post-CW laser-method refinements (Stothers, Vassilevska
   --  Williams, Le Gall, Alman–Williams, …). Catalogue placeholder only.

   --  Documented exponents (sources in README / comments):
   --    Classical            : 3.0
   --    Strassen (1969)      : log_2(7) ≈ 2.8073549
   --    Coppersmith–Winograd : 2.3755  (1990 classic bound, often cited)
   --    Laser_Family         : 2.373   (educational placeholder ≈ mid-2010s)
   Classical_Exponent_Const : constant Float := 3.0;
   CW_Exponent_Const        : constant Float := 2.3755;
   Laser_Exponent_Const     : constant Float := 2.373;

   type Method_Info is record
      Kind             : Method_Kind;
      Exponent         : Float;
      Practical        : Boolean;
      Runnable_Sketch  : Boolean;
      Year             : Natural;
   end record;

   ---------------------------------------------------------------------------
   -- Historical milestone table (queryable)
   ---------------------------------------------------------------------------

   type Milestone is record
      Year     : Natural;
      Exponent : Float;
      Label    : String (1 .. 48);
      Len      : Natural;
   end record;

   Milestone_Count : constant Positive := 6;

   ---------------------------------------------------------------------------
   -- Numeric / structural helpers
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

   function Is_Power_Of_Two (N : Natural) return Boolean
     with Global => null;

   function Next_Power_Of_Two (N : Natural) return Natural
     with Pre => N <= Max_N, Global => null;

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
   -- Padding / trimming (educational pad-and-trim for Strassen)
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
   -- Builders
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
   -- Taxonomy queries
   ---------------------------------------------------------------------------

   function Method_Count return Positive
     with Global => null;
   --  Number of Method_Kind values (= 4).

   function Method_Name (M : Method_Kind) return String
     with Global => null;

   function Exponent_Of (M : Method_Kind) return Float
     with Global => null;
   --  Classical → 3.0; Strassen → Log(7)/Log(2); CW → 2.3755;
   --  Laser_Family → 2.373 (placeholder).

   function Is_Practical (M : Method_Kind) return Boolean
     with Global => null;
   --  True for Classical and (borderline) Strassen; False for CW / Laser.

   function Supports_Runnable (M : Method_Kind) return Boolean
     with Global => null;
   --  True only for Classical and Strassen sketches in this package.

   function Describe (M : Method_Kind) return String
     with Global => null;

   function Classify_Method (M : Method_Kind) return Method_Info
     with Global => null;

   function Get_Milestone (Index : Positive) return Milestone
     with Pre => Index <= Milestone_Count, Global => null;

   function Milestone_Label (Index : Positive) return String
     with Pre => Index <= Milestone_Count, Global => null;

   ---------------------------------------------------------------------------
   -- Complexity estimator: Float(N)**Exponent_Of(Method)
   ---------------------------------------------------------------------------

   function Estimated_Ops (N : Natural; Method : Method_Kind) return Float
     with Pre => N >= 1 and then N <= Max_N, Global => null;

   ---------------------------------------------------------------------------
   -- Runnable sketches
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

   --  Dispatch by Method_Kind. Classical / Strassen run sketches;
   --  Coppersmith_Winograd and Laser_Family return galactic reject
   --  (Success=False, Stat in {Not_Implemented, Galactic_Only}).
   function Multiply
     (A      : Matrix;
      B      : Matrix;
      Method : Method_Kind;
      Leaf   : Positive := Default_Leaf) return Multiply_Result
     with Pre =>
       Is_Square (A)
       and then Is_Square (B)
       and then A'Length (1) = B'Length (1)
       and then Leaf >= 1,
          Global => null;

   function Product_Matrix (R : Multiply_Result) return Matrix
     with Pre => R.Success and then R.N >= 1, Global => null;

end Coppersmith_Winograd;
