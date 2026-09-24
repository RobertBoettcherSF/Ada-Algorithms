--  Freivalds — Ada 2023 educational package for Wikipedia "Freivalds' algorithm":
--  probabilistic (Monte Carlo) verification of matrix products AB =? C
--  without forming AB fully. Random 0/1 vector r; check A(Br) = Cr.
--  One-sided error ≤ 1/2 per trial; k independent trials → ≤ 2^{-k}.
--  Cap n ≤ 32; educational Integer (exact arithmetic). Seeded LCG PRNG.
--  Primary source:
--  https://en.wikipedia.org/wiki/Freivalds'_algorithm
--  Siblings (README links only — no package deps):
--  Ada-Strassen, Ada-Coppersmith-Winograd (upcoming),
--  Ada-System-of-Linear-Equations

pragma Ada_2022;

package Freivalds
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain types / capacity
   ---------------------------------------------------------------------------

   Max_N : constant := 32;

   subtype Dimension is Natural range 0 .. Max_N;
   subtype Dim_Index is Positive range 1 .. Max_N;

   --  Exact Integer entries for clean probability statements (0/1 probes).
   type Matrix is array (Positive range <>, Positive range <>) of Integer;
   type Vector is array (Positive range <>) of Integer;

   --  Monte Carlo one-sided verdict:
   --    Equal_Probably  — all trials matched (AB = C always ⇒ this; AB ≠ C
   --                      may still yield this with Prob ≤ 2^{-Trials})
   --    Unequal         — some trial found A(Br) ≠ Cr ⇒ AB ≠ C for sure
   --    Dimension_Error — incompatible / empty / oversized shapes
   type Verdict is (Equal_Probably, Unequal, Dimension_Error);

   type Verify_Result is record
      Stat         : Verdict := Dimension_Error;
      N            : Dimension := 0;
      Trials_Used  : Natural := 0;
      Failures     : Natural := 0;  --  trials that detected inequality
      Seed_Final   : Natural := 0;  --  LCG state after last draw
   end record;

   type Multiply_Result is record
      C       : Matrix (1 .. Max_N, 1 .. Max_N) :=
                  [others => [others => 0]];
      N       : Dimension := 0;
      Success : Boolean := False;
   end record;

   Invalid_Argument : exception;

   Default_Trials : constant Positive := 8;
   Default_Seed   : constant Natural := 1;

   ---------------------------------------------------------------------------
   -- Structure / equality helpers
   ---------------------------------------------------------------------------

   function Is_Square (A : Matrix) return Boolean
     with Global => null;

   function Mat_Equal (A, B : Matrix) return Boolean
     with Pre =>
       A'Length (1) = B'Length (1)
       and then A'Length (2) = B'Length (2),
          Global => null;

   function Vec_Equal (U, V : Vector) return Boolean
     with Pre => U'Length = V'Length, Global => null;

   function Mat_Max_Abs (A : Matrix) return Natural
     with Global => null;

   ---------------------------------------------------------------------------
   -- Linear-algebra helpers (exact Integer)
   ---------------------------------------------------------------------------

   function Mat_Vec (A : Matrix; X : Vector) return Vector
     with Pre =>
       A'Length (2) = X'Length
       and then A'Length (1) >= 1
       and then X'Length >= 1,
          Global => null;
   --  y = A x  (uses Long_Integer accumulators)

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

   function Mat_Scale (A : Matrix; S : Integer) return Matrix
     with Global => null;

   function Vec_Sub (U, V : Vector) return Vector
     with Pre => U'Length = V'Length, Global => null;

   ---------------------------------------------------------------------------
   -- Seeded educational LCG (reproducible tests)
   ---------------------------------------------------------------------------

   --  Classic educational LCG on Natural:
   --  state := (A * state + C) mod 2^31, then a *high* bit for {0,1}
   --  (low bits of 2^k-modulus LCGs are patterned). Teaching PRNG only.

   procedure LCG_Next (State : in out Natural)
     with Global => null;

   function LCG_Bit (State : in out Natural) return Integer
     with Global => null;
   --  Returns 0 or 1; advances State.

   function Random_01_Vector
     (N : Dimension; Seed : in out Natural) return Vector
     with Pre => N >= 1, Global => null;
   --  r ∈ {0,1}^N drawn from the LCG starting at Seed (updated).

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Zeros (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   function Ones (N : Dimension; Value : Integer := 1) return Matrix
     with Pre => N >= 1, Global => null;

   function Identity (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;

   function Sequential_Fill (N : Dimension) return Matrix
     with Pre => N >= 1, Global => null;
   --  A(i,j) = (i - 1) * N + j   (1-based row-major)

   function Deterministic (N : Dimension; Seed : Natural := 1) return Matrix
     with Pre => N >= 1, Global => null;
   --  Small entries in 0 .. 9 from a hash of (Seed, i, j).

   function Zero_Vector (N : Dimension) return Vector
     with Pre => N >= 1, Global => null;

   function Ones_Vector (N : Dimension; Value : Integer := 1) return Vector
     with Pre => N >= 1, Global => null;

   function Corrupt_Entry
     (A : Matrix; Row, Col : Positive; Offset : Integer := 1) return Matrix
     with Pre =>
       Is_Square (A)
       and then Row in A'Range (1)
       and then Col in A'Range (2),
          Global => null;
   --  Copy of A with A(Row,Col) := A(Row,Col) + Offset (deliberate wrong C).

   ---------------------------------------------------------------------------
   -- Classical multiply (exact oracle)
   ---------------------------------------------------------------------------

   function Multiply_Classical (A, B : Matrix) return Multiply_Result
     with Pre =>
       Is_Square (A)
       and then Is_Square (B)
       and then A'Length (1) = B'Length (1),
          Global => null;
   --  Standard O(n^3) Integer product. Requires 1 ≤ n ≤ Max_N.

   function Product_Matrix (R : Multiply_Result) return Matrix
     with Pre => R.Success and then R.N >= 1, Global => null;

   function Matrices_Equal (A, B : Matrix) return Boolean
     with Pre =>
       Is_Square (A)
       and then Is_Square (B)
       and then A'Length (1) = B'Length (1),
          Global => null;
   --  Exact entrywise equality of leading squares (same size).

   ---------------------------------------------------------------------------
   -- Freivalds verify (Monte Carlo, one-sided error)
   ---------------------------------------------------------------------------

   function Verify
     (A      : Matrix;
      B      : Matrix;
      C      : Matrix;
      Trials : Positive := Default_Trials;
      Seed   : Natural := Default_Seed) return Verify_Result
     with Pre =>
       Is_Square (A)
       and then Is_Square (B)
       and then Is_Square (C)
       and then A'Length (1) = B'Length (1)
       and then A'Length (1) = C'Length (1),
          Global => null;
   --  For each trial t = 1 .. Trials:
   --    draw r ∈ {0,1}^n; compute Br, A(Br), Cr; if unequal → Unequal.
   --  If all trials match → Equal_Probably.
   --  If AB = C, always Equal_Probably (no false "Unequal").
   --  If AB ≠ C, P(Equal_Probably) ≤ 2^{-Trials} (ideal independent bits).
   --  Requires 1 ≤ n ≤ Max_N; else Dimension_Error.

   function Verify_Once
     (A : Matrix; B : Matrix; C : Matrix; Seed : in out Natural)
      return Verdict
     with Pre =>
       Is_Square (A)
       and then Is_Square (B)
       and then Is_Square (C)
       and then A'Length (1) = B'Length (1)
       and then A'Length (1) = C'Length (1),
          Global => null;
   --  Single Freivalds trial; updates Seed. Same dimension rules as Verify.

end Freivalds;
