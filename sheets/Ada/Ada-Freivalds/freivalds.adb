--  Freivalds' algorithm body: exact Integer classical multiply, LCG,
--  Mat_Vec, and Monte Carlo product verification.

pragma Ada_2022;

package body Freivalds
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- LCG constants (educational; not crypto)
   --   state' = (A_Mul * state + A_Add) mod Modulus
   -- Park–Miller uses 16807 / 2^31−1; we keep a small Natural-friendly form.
   ---------------------------------------------------------------------------

   LCG_Mul : constant := 1103515245;
   LCG_Add : constant := 12345;
   LCG_Mod : constant := 2**31;  --  2147483648; Natural holds 0 .. 2^31−1

   ---------------------------------------------------------------------------
   -- Structure helpers
   ---------------------------------------------------------------------------

   function Is_Square (A : Matrix) return Boolean is
   begin
      return A'Length (1) = A'Length (2);
   end Is_Square;

   function Mat_Equal (A, B : Matrix) return Boolean is
      I_Off : constant Integer := B'First (1) - A'First (1);
      J_Off : constant Integer := B'First (2) - A'First (2);
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            if A (I, J) /= B (I + I_Off, J + J_Off) then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Mat_Equal;

   function Vec_Equal (U, V : Vector) return Boolean is
      Off : constant Integer := V'First - U'First;
   begin
      for I in U'Range loop
         if U (I) /= V (I + Off) then
            return False;
         end if;
      end loop;
      return True;
   end Vec_Equal;

   function Mat_Max_Abs (A : Matrix) return Natural is
      M : Natural := 0;
      V : Natural;
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            V := abs (A (I, J));
            if V > M then
               M := V;
            end if;
         end loop;
      end loop;
      return M;
   end Mat_Max_Abs;

   ---------------------------------------------------------------------------
   -- Linear algebra
   ---------------------------------------------------------------------------

   function Mat_Vec (A : Matrix; X : Vector) return Vector is
      Y   : Vector (A'Range (1));
      Acc : Long_Integer;
      X0  : constant Positive := X'First;
   begin
      for I in A'Range (1) loop
         Acc := 0;
         for J in A'Range (2) loop
            Acc := Acc
              + Long_Integer (A (I, J))
                * Long_Integer (X (X0 + (J - A'First (2))));
         end loop;
         Y (I) := Integer (Acc);
      end loop;
      return Y;
   end Mat_Vec;

   function Mat_Add (A, B : Matrix) return Matrix is
      R     : Matrix (A'Range (1), A'Range (2));
      I_Off : constant Integer := B'First (1) - A'First (1);
      J_Off : constant Integer := B'First (2) - A'First (2);
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            R (I, J) := A (I, J) + B (I + I_Off, J + J_Off);
         end loop;
      end loop;
      return R;
   end Mat_Add;

   function Mat_Sub (A, B : Matrix) return Matrix is
      R     : Matrix (A'Range (1), A'Range (2));
      I_Off : constant Integer := B'First (1) - A'First (1);
      J_Off : constant Integer := B'First (2) - A'First (2);
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            R (I, J) := A (I, J) - B (I + I_Off, J + J_Off);
         end loop;
      end loop;
      return R;
   end Mat_Sub;

   function Mat_Scale (A : Matrix; S : Integer) return Matrix is
      R : Matrix (A'Range (1), A'Range (2));
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            R (I, J) := A (I, J) * S;
         end loop;
      end loop;
      return R;
   end Mat_Scale;

   function Vec_Sub (U, V : Vector) return Vector is
      R   : Vector (U'Range);
      Off : constant Integer := V'First - U'First;
   begin
      for I in U'Range loop
         R (I) := U (I) - V (I + Off);
      end loop;
      return R;
   end Vec_Sub;

   ---------------------------------------------------------------------------
   -- LCG
   ---------------------------------------------------------------------------

   procedure LCG_Next (State : in out Natural) is
      --  Compute (LCG_Mul * State + LCG_Add) mod LCG_Mod in Long_Integer,
      --  then fold into 0 .. LCG_Mod−1 fitted in Natural (0 .. 2^31−1).
      X : constant Long_Integer :=
        (Long_Integer (LCG_Mul) * Long_Integer (State)
           + Long_Integer (LCG_Add))
        mod Long_Integer (LCG_Mod);
   begin
      State := Natural (X);
   end LCG_Next;

   function LCG_Bit (State : in out Natural) return Integer is
   begin
      LCG_Next (State);
      --  Use a high bit: low bits of power-of-two-modulus LCGs are
      --  highly patterned (often period 2), which would make Freivalds
      --  probes non-independent across coordinates / trials.
      return Integer ((State / 2**16) mod 2);
   end LCG_Bit;

   function Random_01_Vector
     (N : Dimension; Seed : in out Natural) return Vector
   is
      R : Vector (1 .. N);
   begin
      for I in 1 .. N loop
         R (I) := LCG_Bit (Seed);
      end loop;
      return R;
   end Random_01_Vector;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Zeros (N : Dimension) return Matrix is
      Z : constant Matrix (1 .. N, 1 .. N) := [others => [others => 0]];
   begin
      return Z;
   end Zeros;

   function Ones (N : Dimension; Value : Integer := 1) return Matrix is
      O : constant Matrix (1 .. N, 1 .. N) := [others => [others => Value]];
   begin
      return O;
   end Ones;

   function Identity (N : Dimension) return Matrix is
      I : Matrix (1 .. N, 1 .. N) := [others => [others => 0]];
   begin
      for K in 1 .. N loop
         I (K, K) := 1;
      end loop;
      return I;
   end Identity;

   function Sequential_Fill (N : Dimension) return Matrix is
      A : Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            A (I, J) := (I - 1) * N + J;
         end loop;
      end loop;
      return A;
   end Sequential_Fill;

   function Deterministic (N : Dimension; Seed : Natural := 1) return Matrix is
      A : Matrix (1 .. N, 1 .. N);
      --  Small 0 .. 9 entries; hash mixes Seed, i, j.
      V : Natural;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            V := (Seed * 17 + I * 31 + J * 13) mod 10;
            A (I, J) := Integer (V);
         end loop;
      end loop;
      return A;
   end Deterministic;

   function Zero_Vector (N : Dimension) return Vector is
      Z : constant Vector (1 .. N) := [others => 0];
   begin
      return Z;
   end Zero_Vector;

   function Ones_Vector (N : Dimension; Value : Integer := 1) return Vector is
      O : constant Vector (1 .. N) := [others => Value];
   begin
      return O;
   end Ones_Vector;

   function Corrupt_Entry
     (A : Matrix; Row, Col : Positive; Offset : Integer := 1) return Matrix
   is
      R : Matrix (A'Range (1), A'Range (2));
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            R (I, J) := A (I, J);
         end loop;
      end loop;
      R (Row, Col) := R (Row, Col) + Offset;
      return R;
   end Corrupt_Entry;

   ---------------------------------------------------------------------------
   -- Classical multiply
   ---------------------------------------------------------------------------

   function Multiply_Classical (A, B : Matrix) return Multiply_Result is
      N : constant Natural := A'Length (1);
      R : Multiply_Result;
      Acc : Long_Integer;
      AI0 : constant Positive := A'First (1);
      AJ0 : constant Positive := A'First (2);
      BI0 : constant Positive := B'First (1);
      BJ0 : constant Positive := B'First (2);
   begin
      if N < 1 or else N > Max_N then
         R.Success := False;
         R.N := 0;
         return R;
      end if;

      R.N := N;
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            Acc := 0;
            for K in 0 .. N - 1 loop
               Acc := Acc
                 + Long_Integer (A (AI0 + I, AJ0 + K))
                   * Long_Integer (B (BI0 + K, BJ0 + J));
            end loop;
            R.C (I + 1, J + 1) := Integer (Acc);
         end loop;
      end loop;
      R.Success := True;
      return R;
   end Multiply_Classical;

   function Product_Matrix (R : Multiply_Result) return Matrix is
      P : Matrix (1 .. R.N, 1 .. R.N);
   begin
      for I in 1 .. R.N loop
         for J in 1 .. R.N loop
            P (I, J) := R.C (I, J);
         end loop;
      end loop;
      return P;
   end Product_Matrix;

   function Matrices_Equal (A, B : Matrix) return Boolean is
   begin
      return Mat_Equal (A, B);
   end Matrices_Equal;

   ---------------------------------------------------------------------------
   -- Freivalds
   ---------------------------------------------------------------------------

   function Verify_Once
     (A : Matrix; B : Matrix; C : Matrix; Seed : in out Natural)
      return Verdict
   is
      N : constant Natural := A'Length (1);
   begin
      if N < 1 or else N > Max_N then
         return Dimension_Error;
      end if;
      if A'Length (2) /= N
        or else B'Length (1) /= N
        or else B'Length (2) /= N
        or else C'Length (1) /= N
        or else C'Length (2) /= N
      then
         return Dimension_Error;
      end if;

      declare
         --  Work on 1 .. N views via Mat_Vec on the given bounds.
         --  Build dense 1-based copies for clean indexing.
         AA : Matrix (1 .. N, 1 .. N);
         BB : Matrix (1 .. N, 1 .. N);
         CC : Matrix (1 .. N, 1 .. N);
         R  : Vector (1 .. N);
         Br : Vector (1 .. N);
         ABr : Vector (1 .. N);
         Cr  : Vector (1 .. N);
         AI0 : constant Positive := A'First (1);
         AJ0 : constant Positive := A'First (2);
         BI0 : constant Positive := B'First (1);
         BJ0 : constant Positive := B'First (2);
         CI0 : constant Positive := C'First (1);
         CJ0 : constant Positive := C'First (2);
      begin
         for I in 0 .. N - 1 loop
            for J in 0 .. N - 1 loop
               AA (I + 1, J + 1) := A (AI0 + I, AJ0 + J);
               BB (I + 1, J + 1) := B (BI0 + I, BJ0 + J);
               CC (I + 1, J + 1) := C (CI0 + I, CJ0 + J);
            end loop;
         end loop;

         R := Random_01_Vector (N, Seed);
         Br := Mat_Vec (BB, R);
         ABr := Mat_Vec (AA, Br);
         Cr := Mat_Vec (CC, R);

         if Vec_Equal (ABr, Cr) then
            return Equal_Probably;
         else
            return Unequal;
         end if;
      end;
   end Verify_Once;

   function Verify
     (A      : Matrix;
      B      : Matrix;
      C      : Matrix;
      Trials : Positive := Default_Trials;
      Seed   : Natural := Default_Seed) return Verify_Result
   is
      N   : constant Natural := A'Length (1);
      Res : Verify_Result;
      S   : Natural := Seed;
      V   : Verdict;
   begin
      Res.N := 0;
      Res.Trials_Used := 0;
      Res.Failures := 0;
      Res.Seed_Final := Seed;

      if N < 1 or else N > Max_N then
         Res.Stat := Dimension_Error;
         return Res;
      end if;
      if A'Length (2) /= N
        or else B'Length (1) /= N
        or else B'Length (2) /= N
        or else C'Length (1) /= N
        or else C'Length (2) /= N
      then
         Res.Stat := Dimension_Error;
         return Res;
      end if;

      Res.N := N;
      for T in 1 .. Trials loop
         V := Verify_Once (A, B, C, S);
         Res.Trials_Used := Res.Trials_Used + 1;
         if V = Dimension_Error then
            Res.Stat := Dimension_Error;
            Res.Seed_Final := S;
            return Res;
         elsif V = Unequal then
            Res.Failures := Res.Failures + 1;
            Res.Stat := Unequal;
            Res.Seed_Final := S;
            return Res;  --  early exit: definitely unequal
         end if;
      end loop;

      Res.Stat := Equal_Probably;
      Res.Seed_Final := S;
      return Res;
   end Verify;

end Freivalds;
