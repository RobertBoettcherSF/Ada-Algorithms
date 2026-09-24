--  Strassen algorithm body: classical multiply, pad-and-trim, and the
--  classic 7-product recursive block scheme.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Strassen
  with SPARK_Mode => Off
is

   use Ada.Numerics.Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Mat_Near
     (A, B : Matrix; Tol : Float := Epsilon_Tol) return Boolean
   is
      I_Off : constant Integer := B'First (1) - A'First (1);
      J_Off : constant Integer := B'First (2) - A'First (2);
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            if abs (A (I, J) - B (I + I_Off, J + J_Off)) > Tol then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Mat_Near;

   function Norm_Frobenius (A : Matrix) return Float is
      S : Float := 0.0;
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            S := S + A (I, J) * A (I, J);
         end loop;
      end loop;
      return Sqrt (S);
   end Norm_Frobenius;

   function Diff_Frobenius (A, B : Matrix) return Float is
      S     : Float := 0.0;
      I_Off : constant Integer := B'First (1) - A'First (1);
      J_Off : constant Integer := B'First (2) - A'First (2);
      D     : Float;
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            D := A (I, J) - B (I + I_Off, J + J_Off);
            S := S + D * D;
         end loop;
      end loop;
      return Sqrt (S);
   end Diff_Frobenius;

   function Is_Square (A : Matrix) return Boolean is
   begin
      return A'Length (1) = A'Length (2);
   end Is_Square;

   function Is_Power_Of_Two (N : Natural) return Boolean is
   begin
      if N = 0 then
         return False;
      end if;
      declare
         P : Natural := 1;
      begin
         while P < N loop
            P := P * 2;
         end loop;
         return P = N;
      end;
   end Is_Power_Of_Two;

   function Next_Power_Of_Two (N : Natural) return Natural is
      P : Natural := 1;
   begin
      if N = 0 then
         return 0;
      end if;
      while P < N loop
         P := P * 2;
      end loop;
      return P;
   end Next_Power_Of_Two;

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

   function Mat_Scale (A : Matrix; S : Float) return Matrix is
      R : Matrix (A'Range (1), A'Range (2));
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            R (I, J) := S * A (I, J);
         end loop;
      end loop;
      return R;
   end Mat_Scale;

   ---------------------------------------------------------------------------
   -- Padding / trimming
   ---------------------------------------------------------------------------

   function Pad_To_Power_Of_Two (A : Matrix) return Matrix is
      N  : constant Natural := A'Length (1);
      P  : constant Natural := Next_Power_Of_Two (N);
      R  : Matrix (1 .. P, 1 .. P) := [others => [others => 0.0]];
      I0 : constant Positive := A'First (1);
      J0 : constant Positive := A'First (2);
   begin
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            R (1 + I, 1 + J) := A (I0 + I, J0 + J);
         end loop;
      end loop;
      return R;
   end Pad_To_Power_Of_Two;

   function Trim (A : Matrix; N : Dimension) return Matrix is
      R  : Matrix (1 .. N, 1 .. N);
      I0 : constant Positive := A'First (1);
      J0 : constant Positive := A'First (2);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            R (I, J) := A (I0 + I - 1, J0 + J - 1);
         end loop;
      end loop;
      return R;
   end Trim;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Zeros (N : Dimension) return Matrix is
      R : constant Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      return R;
   end Zeros;

   function Ones (N : Dimension; Value : Float := 1.0) return Matrix is
      R : Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            R (I, J) := Value;
         end loop;
      end loop;
      return R;
   end Ones;

   function Identity (N : Dimension) return Matrix is
      R : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      for I in 1 .. N loop
         R (I, I) := 1.0;
      end loop;
      return R;
   end Identity;

   function Sequential_Fill (N : Dimension) return Matrix is
      R : Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            R (I, J) := Float ((I - 1) * N + J);
         end loop;
      end loop;
      return R;
   end Sequential_Fill;

   function Deterministic (N : Dimension; Seed : Natural := 1) return Matrix is
      R    : Matrix (1 .. N, 1 .. N);
      Phi  : constant Float := 0.618_033_988_7;
      Raw  : Float;
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            Raw := Float (Seed + 17 * I + 31 * J) * Phi;
            R (I, J) := Raw - Float'Truncation (Raw);
            if R (I, J) < 0.0 then
               R (I, J) := R (I, J) + 1.0;
            end if;
         end loop;
      end loop;
      return R;
   end Deterministic;

   function Make_Hilbert (N : Dimension) return Matrix is
      R : Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            R (I, J) := 1.0 / Float (I + J - 1);
         end loop;
      end loop;
      return R;
   end Make_Hilbert;

   ---------------------------------------------------------------------------
   -- Internal: classical multiply on equal-sized square blocks (any bounds)
   ---------------------------------------------------------------------------

   procedure Classical_Block
     (A, B     : Matrix;
      C        : out Matrix;
      Mults    : out Natural)
   is
      N     : constant Natural := A'Length (1);
      AI0   : constant Positive := A'First (1);
      AJ0   : constant Positive := A'First (2);
      BI0   : constant Positive := B'First (1);
      BJ0   : constant Positive := B'First (2);
      CI0   : constant Positive := C'First (1);
      CJ0   : constant Positive := C'First (2);
      Sum   : Float;
   begin
      Mults := 0;
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            Sum := 0.0;
            for K in 0 .. N - 1 loop
               Sum := Sum
                 + A (AI0 + I, AJ0 + K) * B (BI0 + K, BJ0 + J);
               Mults := Mults + 1;
            end loop;
            C (CI0 + I, CJ0 + J) := Sum;
         end loop;
      end loop;
   end Classical_Block;

   ---------------------------------------------------------------------------
   -- Internal: extract / embed half-size blocks (1-based local indexing)
   ---------------------------------------------------------------------------

   function Block_NW (M : Matrix) return Matrix is
      N : constant Natural := M'Length (1) / 2;
      R : Matrix (1 .. N, 1 .. N);
      I0 : constant Positive := M'First (1);
      J0 : constant Positive := M'First (2);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            R (I, J) := M (I0 + I - 1, J0 + J - 1);
         end loop;
      end loop;
      return R;
   end Block_NW;

   function Block_NE (M : Matrix) return Matrix is
      N : constant Natural := M'Length (1) / 2;
      R : Matrix (1 .. N, 1 .. N);
      I0 : constant Positive := M'First (1);
      J0 : constant Positive := M'First (2);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            R (I, J) := M (I0 + I - 1, J0 + N + J - 1);
         end loop;
      end loop;
      return R;
   end Block_NE;

   function Block_SW (M : Matrix) return Matrix is
      N : constant Natural := M'Length (1) / 2;
      R : Matrix (1 .. N, 1 .. N);
      I0 : constant Positive := M'First (1);
      J0 : constant Positive := M'First (2);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            R (I, J) := M (I0 + N + I - 1, J0 + J - 1);
         end loop;
      end loop;
      return R;
   end Block_SW;

   function Block_SE (M : Matrix) return Matrix is
      N : constant Natural := M'Length (1) / 2;
      R : Matrix (1 .. N, 1 .. N);
      I0 : constant Positive := M'First (1);
      J0 : constant Positive := M'First (2);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            R (I, J) := M (I0 + N + I - 1, J0 + N + J - 1);
         end loop;
      end loop;
      return R;
   end Block_SE;

   procedure Embed_NW (Dest : in out Matrix; Src : Matrix) is
      N  : constant Natural := Src'Length (1);
      I0 : constant Positive := Dest'First (1);
      J0 : constant Positive := Dest'First (2);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            Dest (I0 + I - 1, J0 + J - 1) := Src (Src'First (1) + I - 1,
                                                   Src'First (2) + J - 1);
         end loop;
      end loop;
   end Embed_NW;

   procedure Embed_NE (Dest : in out Matrix; Src : Matrix) is
      N  : constant Natural := Src'Length (1);
      I0 : constant Positive := Dest'First (1);
      J0 : constant Positive := Dest'First (2);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            Dest (I0 + I - 1, J0 + N + J - 1) :=
              Src (Src'First (1) + I - 1, Src'First (2) + J - 1);
         end loop;
      end loop;
   end Embed_NE;

   procedure Embed_SW (Dest : in out Matrix; Src : Matrix) is
      N  : constant Natural := Src'Length (1);
      I0 : constant Positive := Dest'First (1);
      J0 : constant Positive := Dest'First (2);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            Dest (I0 + N + I - 1, J0 + J - 1) :=
              Src (Src'First (1) + I - 1, Src'First (2) + J - 1);
         end loop;
      end loop;
   end Embed_SW;

   procedure Embed_SE (Dest : in out Matrix; Src : Matrix) is
      N  : constant Natural := Src'Length (1);
      I0 : constant Positive := Dest'First (1);
      J0 : constant Positive := Dest'First (2);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            Dest (I0 + N + I - 1, J0 + N + J - 1) :=
              Src (Src'First (1) + I - 1, Src'First (2) + J - 1);
         end loop;
      end loop;
   end Embed_SE;

   ---------------------------------------------------------------------------
   -- Recursive Strassen on power-of-2 square matrices (equal bounds 1..N)
   ---------------------------------------------------------------------------

   procedure Strassen_Rec
     (A, B   : Matrix;
      C      : out Matrix;
      Leaf   : Positive;
      Mults  : out Natural;
      Depth  : out Natural)
   is
      N : constant Natural := A'Length (1);
   begin
      if N <= Leaf or else N = 1 then
         Classical_Block (A, B, C, Mults);
         Depth := 0;
         return;
      end if;

      declare
         H : constant Natural := N / 2;

         A11 : constant Matrix := Block_NW (A);
         A12 : constant Matrix := Block_NE (A);
         A21 : constant Matrix := Block_SW (A);
         A22 : constant Matrix := Block_SE (A);

         B11 : constant Matrix := Block_NW (B);
         B12 : constant Matrix := Block_NE (B);
         B21 : constant Matrix := Block_SW (B);
         B22 : constant Matrix := Block_SE (B);

         M1, M2, M3, M4, M5, M6, M7 : Matrix (1 .. H, 1 .. H);
         C11, C12, C21, C22         : Matrix (1 .. H, 1 .. H);

         Mults_K : Natural;
         Depth_K : Natural;
         Max_D   : Natural := 0;
         Total_M : Natural := 0;

         T1, T2 : Matrix (1 .. H, 1 .. H);
      begin
         --  M1 = (A11 + A22)(B11 + B22)
         T1 := Mat_Add (A11, A22);
         T2 := Mat_Add (B11, B22);
         Strassen_Rec (T1, T2, M1, Leaf, Mults_K, Depth_K);
         Total_M := Total_M + Mults_K;
         if Depth_K > Max_D then
            Max_D := Depth_K;
         end if;

         --  M2 = (A21 + A22) B11
         T1 := Mat_Add (A21, A22);
         Strassen_Rec (T1, B11, M2, Leaf, Mults_K, Depth_K);
         Total_M := Total_M + Mults_K;
         if Depth_K > Max_D then
            Max_D := Depth_K;
         end if;

         --  M3 = A11 (B12 - B22)
         T2 := Mat_Sub (B12, B22);
         Strassen_Rec (A11, T2, M3, Leaf, Mults_K, Depth_K);
         Total_M := Total_M + Mults_K;
         if Depth_K > Max_D then
            Max_D := Depth_K;
         end if;

         --  M4 = A22 (B21 - B11)
         T2 := Mat_Sub (B21, B11);
         Strassen_Rec (A22, T2, M4, Leaf, Mults_K, Depth_K);
         Total_M := Total_M + Mults_K;
         if Depth_K > Max_D then
            Max_D := Depth_K;
         end if;

         --  M5 = (A11 + A12) B22
         T1 := Mat_Add (A11, A12);
         Strassen_Rec (T1, B22, M5, Leaf, Mults_K, Depth_K);
         Total_M := Total_M + Mults_K;
         if Depth_K > Max_D then
            Max_D := Depth_K;
         end if;

         --  M6 = (A21 - A11)(B11 + B12)
         T1 := Mat_Sub (A21, A11);
         T2 := Mat_Add (B11, B12);
         Strassen_Rec (T1, T2, M6, Leaf, Mults_K, Depth_K);
         Total_M := Total_M + Mults_K;
         if Depth_K > Max_D then
            Max_D := Depth_K;
         end if;

         --  M7 = (A12 - A22)(B21 + B22)
         T1 := Mat_Sub (A12, A22);
         T2 := Mat_Add (B21, B22);
         Strassen_Rec (T1, T2, M7, Leaf, Mults_K, Depth_K);
         Total_M := Total_M + Mults_K;
         if Depth_K > Max_D then
            Max_D := Depth_K;
         end if;

         --  C11 = M1 + M4 - M5 + M7
         C11 := Mat_Add (Mat_Add (M1, M4), Mat_Sub (M7, M5));
         --  C12 = M3 + M5
         C12 := Mat_Add (M3, M5);
         --  C21 = M2 + M4
         C21 := Mat_Add (M2, M4);
         --  C22 = M1 - M2 + M3 + M6
         C22 := Mat_Add (Mat_Sub (M1, M2), Mat_Add (M3, M6));

         C := [others => [others => 0.0]];
         Embed_NW (C, C11);
         Embed_NE (C, C12);
         Embed_SW (C, C21);
         Embed_SE (C, C22);

         Mults := Total_M;
         Depth := Max_D + 1;
      end;
   end Strassen_Rec;

   ---------------------------------------------------------------------------
   -- Public multiply entry points
   ---------------------------------------------------------------------------

   function Fail_Dim return Multiply_Result is
      R : Multiply_Result;
   begin
      R.Stat    := Dimension_Error;
      R.Success := False;
      return R;
   end Fail_Dim;

   function Multiply_Classical (A, B : Matrix) return Multiply_Result is
      N : constant Natural := A'Length (1);
      R : Multiply_Result;
      Mults : Natural;
      C_Tmp : Matrix (1 .. N, 1 .. N);
      A_N   : Matrix (1 .. N, 1 .. N);
      B_N   : Matrix (1 .. N, 1 .. N);
      I0A   : constant Positive := A'First (1);
      J0A   : constant Positive := A'First (2);
      I0B   : constant Positive := B'First (1);
      J0B   : constant Positive := B'First (2);
   begin
      if N < 1 or else N > Max_N
        or else A'Length (2) /= N
        or else B'Length (1) /= N
        or else B'Length (2) /= N
      then
         return Fail_Dim;
      end if;

      for I in 1 .. N loop
         for J in 1 .. N loop
            A_N (I, J) := A (I0A + I - 1, J0A + J - 1);
            B_N (I, J) := B (I0B + I - 1, J0B + J - 1);
         end loop;
      end loop;

      Classical_Block (A_N, B_N, C_Tmp, Mults);

      R.N                 := N;
      R.Stat              := Ok;
      R.Success           := True;
      R.Scalar_Multiplies := Mults;
      R.Recursion_Depth   := 0;
      R.Padded_N          := 0;
      for I in 1 .. N loop
         for J in 1 .. N loop
            R.C (I, J) := C_Tmp (I, J);
         end loop;
      end loop;
      return R;
   end Multiply_Classical;

   function Multiply_Strassen
     (A    : Matrix;
      B    : Matrix;
      Leaf : Positive := Default_Leaf) return Multiply_Result
   is
      N : constant Natural := A'Length (1);
      R : Multiply_Result;
      P : Natural;
      Mults : Natural;
      Depth : Natural;
   begin
      if N < 1 or else N > Max_N
        or else A'Length (2) /= N
        or else B'Length (1) /= N
        or else B'Length (2) /= N
      then
         return Fail_Dim;
      end if;

      P := Next_Power_Of_Two (N);
      if P > Max_N then
         return Fail_Dim;
      end if;

      declare
         A_Pad : constant Matrix := Pad_To_Power_Of_Two (A);
         B_Pad : constant Matrix := Pad_To_Power_Of_Two (B);
         C_Pad : Matrix (1 .. P, 1 .. P);
      begin
         Strassen_Rec (A_Pad, B_Pad, C_Pad, Leaf, Mults, Depth);

         R.N                 := N;
         R.Stat              := Ok;
         R.Success           := True;
         R.Scalar_Multiplies := Mults;
         R.Recursion_Depth   := Depth;
         R.Padded_N          := P;
         for I in 1 .. N loop
            for J in 1 .. N loop
               R.C (I, J) := C_Pad (I, J);
            end loop;
         end loop;
         return R;
      end;
   end Multiply_Strassen;

   function Product_Matrix (R : Multiply_Result) return Matrix is
      Out_M : Matrix (1 .. R.N, 1 .. R.N);
   begin
      for I in 1 .. R.N loop
         for J in 1 .. R.N loop
            Out_M (I, J) := R.C (I, J);
         end loop;
      end loop;
      return Out_M;
   end Product_Matrix;

end Strassen;
