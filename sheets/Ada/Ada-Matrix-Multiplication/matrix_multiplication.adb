--  Matrix_Multiplication educational body: taxonomy / exponents, Classical /
--  Strassen / Cannon sketches, Freivalds Integer verify, catalogue reject for
--  CW / SUMMA / Laser_Family.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Matrix_Multiplication
  with SPARK_Mode => Off
is

   use Ada.Numerics.Elementary_Functions;

   ---------------------------------------------------------------------------
   -- Milestone table
   ---------------------------------------------------------------------------

   function Pad_Label (S : String) return Milestone is
      M : Milestone;
   begin
      M.Len := Natural'Min (S'Length, M.Label'Length);
      M.Label := [others => ' '];
      M.Label (1 .. M.Len) := S (S'First .. S'First + M.Len - 1);
      return M;
   end Pad_Label;

   function Make_Milestone
     (Year : Natural; Exp : Float; S : String) return Milestone
   is
      M : Milestone := Pad_Label (S);
   begin
      M.Year     := Year;
      M.Exponent := Exp;
      return M;
   end Make_Milestone;

   Milestones : constant array (1 .. Milestone_Count) of Milestone :=
     [Make_Milestone (1969, 2.807_355, "Strassen seven-product recursion"),
      Make_Milestone (1969, 3.0,       "Cannon systolic 2D-mesh multiply"),
      Make_Milestone (1979, 2.0,       "Freivalds probabilistic verify"),
      Make_Milestone (1981, 2.522,     "Schonhage / Pan era improvements"),
      Make_Milestone (1990, 2.3755,    "Coppersmith-Winograd classic bound"),
      Make_Milestone (1995, 3.0,       "SUMMA scalable universal MM"),
      Make_Milestone (2010, 2.3737,    "Stothers laser-method refinement"),
      Make_Milestone (2014, 2.3728639, "Le Gall further laser improvement")];

   ---------------------------------------------------------------------------
   -- LCG (Freivalds)
   ---------------------------------------------------------------------------

   LCG_Mul : constant := 1_103_515_245;
   LCG_Add : constant := 12_345;
   LCG_Mod : constant := 2 ** 31;

   ---------------------------------------------------------------------------
   -- Float helpers
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

   function Is_Square_Int (A : Int_Matrix) return Boolean is
   begin
      return A'Length (1) = A'Length (2);
   end Is_Square_Int;

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

   function Divides (P, N : Natural) return Boolean is
   begin
      return P > 0 and then N mod P = 0;
   end Divides;

   function Is_Valid_Grid (N, P : Natural) return Boolean is
   begin
      return P >= 1 and then N >= P and then N <= Max_N and then Divides (P, N);
   end Is_Valid_Grid;

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
   -- Float builders
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
      R   : Matrix (1 .. N, 1 .. N);
      Phi : constant Float := 0.618_033_988_7;
      Raw : Float;
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
   -- Integer builders / Freivalds helpers
   ---------------------------------------------------------------------------

   function Int_Zeros (N : Dimension) return Int_Matrix is
      R : constant Int_Matrix (1 .. N, 1 .. N) := [others => [others => 0]];
   begin
      return R;
   end Int_Zeros;

   function Int_Ones
     (N : Dimension; Value : Integer := 1) return Int_Matrix
   is
      R : Int_Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            R (I, J) := Value;
         end loop;
      end loop;
      return R;
   end Int_Ones;

   function Int_Identity (N : Dimension) return Int_Matrix is
      R : Int_Matrix (1 .. N, 1 .. N) := [others => [others => 0]];
   begin
      for I in 1 .. N loop
         R (I, I) := 1;
      end loop;
      return R;
   end Int_Identity;

   function Int_Sequential_Fill (N : Dimension) return Int_Matrix is
      R : Int_Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            R (I, J) := (I - 1) * N + J;
         end loop;
      end loop;
      return R;
   end Int_Sequential_Fill;

   function Int_Deterministic
     (N : Dimension; Seed : Natural := 1) return Int_Matrix
   is
      R : Int_Matrix (1 .. N, 1 .. N);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            R (I, J) := Integer ((Seed + 17 * I + 31 * J) mod 10);
         end loop;
      end loop;
      return R;
   end Int_Deterministic;

   function Int_Mat_Equal (A, B : Int_Matrix) return Boolean is
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
   end Int_Mat_Equal;

   function Int_Vec_Equal (U, V : Int_Vector) return Boolean is
      Off : constant Integer := V'First - U'First;
   begin
      for I in U'Range loop
         if U (I) /= V (I + Off) then
            return False;
         end if;
      end loop;
      return True;
   end Int_Vec_Equal;

   function Int_Mat_Vec (A : Int_Matrix; X : Int_Vector) return Int_Vector is
      Y   : Int_Vector (A'Range (1));
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
   end Int_Mat_Vec;

   function Corrupt_Entry
     (A : Int_Matrix; Row, Col : Positive; Offset : Integer := 1)
      return Int_Matrix
   is
      R : Int_Matrix (A'Range (1), A'Range (2));
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            R (I, J) := A (I, J);
         end loop;
      end loop;
      R (Row, Col) := R (Row, Col) + Offset;
      return R;
   end Corrupt_Entry;

   procedure LCG_Next (State : in out Natural) is
      S : Long_Integer;
   begin
      S := (Long_Integer (LCG_Mul) * Long_Integer (State)
            + Long_Integer (LCG_Add)) mod Long_Integer (LCG_Mod);
      State := Natural (S);
   end LCG_Next;

   function LCG_Bit (State : in out Natural) return Integer is
   begin
      LCG_Next (State);
      --  Use a high bit: low bits of 2^k LCGs are patterned.
      return Integer ((State / 2**16) mod 2);
   end LCG_Bit;

   function Random_01_Vector
     (N : Dimension; Seed : in out Natural) return Int_Vector
   is
      R : Int_Vector (1 .. N);
   begin
      for I in 1 .. N loop
         R (I) := LCG_Bit (Seed);
      end loop;
      return R;
   end Random_01_Vector;

   ---------------------------------------------------------------------------
   -- Taxonomy
   ---------------------------------------------------------------------------

   function Method_Count return Positive is
   begin
      return Method_Kind'Pos (Method_Kind'Last)
           - Method_Kind'Pos (Method_Kind'First) + 1;
   end Method_Count;

   function Method_Name (M : Method_Kind) return String is
   begin
      case M is
         when Classical =>
            return "Classical";
         when Strassen =>
            return "Strassen";
         when Coppersmith_Winograd =>
            return "Coppersmith-Winograd";
         when Cannon =>
            return "Cannon";
         when Freivalds_Verify =>
            return "Freivalds-Verify";
         when SUMMA =>
            return "SUMMA";
         when Laser_Family =>
            return "Laser-Family";
      end case;
   end Method_Name;

   function Exponent_Of (M : Method_Kind) return Float is
   begin
      case M is
         when Classical =>
            return Classical_Exponent_Const;
         when Strassen =>
            return Log (7.0) / Log (2.0);
         when Coppersmith_Winograd =>
            return CW_Exponent_Const;
         when Cannon =>
            return Cannon_Exponent_Const;
         when Freivalds_Verify =>
            return Freivalds_Exponent_Const;
         when SUMMA =>
            return SUMMA_Exponent_Const;
         when Laser_Family =>
            return Laser_Exponent_Const;
      end case;
   end Exponent_Of;

   function Is_Practical (M : Method_Kind) return Boolean is
   begin
      case M is
         when Classical | Strassen | Cannon | Freivalds_Verify | SUMMA =>
            return True;
         when Coppersmith_Winograd | Laser_Family =>
            return False;
      end case;
   end Is_Practical;

   function Supports_Runnable (M : Method_Kind) return Boolean is
   begin
      case M is
         when Classical | Strassen | Cannon | Freivalds_Verify =>
            return True;
         when Coppersmith_Winograd | SUMMA | Laser_Family =>
            return False;
      end case;
   end Supports_Runnable;

   function Describe (M : Method_Kind) return String is
   begin
      case M is
         when Classical =>
            return "Triple-loop O(n^3) dense product";
         when Strassen =>
            return "Seven-product recursive block multiply";
         when Coppersmith_Winograd =>
            return "Galactic asymptotic omega~2.3755 (catalogue)";
         when Cannon =>
            return "Systolic 2D-mesh MM (sequential simulation)";
         when Freivalds_Verify =>
            return "Monte Carlo AB=?C fingerprint (Integer)";
         when SUMMA =>
            return "Scalable Universal Matrix Multiply (catalogue)";
         when Laser_Family =>
            return "Post-CW laser-method refinements (catalogue)";
      end case;
   end Describe;

   function Classify_Method (M : Method_Kind) return Method_Info is
      Info : Method_Info;
   begin
      Info.Kind            := M;
      Info.Exponent        := Exponent_Of (M);
      Info.Practical       := Is_Practical (M);
      Info.Runnable_Sketch := Supports_Runnable (M);
      case M is
         when Classical =>
            Info.Year := 0;
            Info.Is_Parallel := False;
            Info.Is_Verification := False;
         when Strassen =>
            Info.Year := 1969;
            Info.Is_Parallel := False;
            Info.Is_Verification := False;
         when Coppersmith_Winograd =>
            Info.Year := 1990;
            Info.Is_Parallel := False;
            Info.Is_Verification := False;
         when Cannon =>
            Info.Year := 1969;
            Info.Is_Parallel := True;
            Info.Is_Verification := False;
         when Freivalds_Verify =>
            Info.Year := 1979;
            Info.Is_Parallel := False;
            Info.Is_Verification := True;
         when SUMMA =>
            Info.Year := 1995;
            Info.Is_Parallel := True;
            Info.Is_Verification := False;
         when Laser_Family =>
            Info.Year := 2010;
            Info.Is_Parallel := False;
            Info.Is_Verification := False;
      end case;
      return Info;
   end Classify_Method;

   function Get_Milestone (Index : Positive) return Milestone is
   begin
      return Milestones (Index);
   end Get_Milestone;

   function Milestone_Label (Index : Positive) return String is
      M : constant Milestone := Milestones (Index);
   begin
      return M.Label (1 .. M.Len);
   end Milestone_Label;

   function Estimated_Ops (N : Natural; Method : Method_Kind) return Float is
   begin
      return Exp (Exponent_Of (Method) * Log (Float (N)));
   end Estimated_Ops;

   function Recommend_Method
     (N : Natural; Prefer_Parallel : Boolean := False) return Method_Kind
   is
   begin
      if Prefer_Parallel and then N >= 2 then
         return Cannon;
      elsif N >= 16 then
         return Strassen;
      else
         return Classical;
      end if;
   end Recommend_Method;

   ---------------------------------------------------------------------------
   -- Classical / Strassen internals
   ---------------------------------------------------------------------------

   procedure Classical_Block
     (A, B  : Matrix;
      C     : out Matrix;
      Mults : out Natural)
   is
      N   : constant Natural := A'Length (1);
      AI0 : constant Positive := A'First (1);
      AJ0 : constant Positive := A'First (2);
      BI0 : constant Positive := B'First (1);
      BJ0 : constant Positive := B'First (2);
      CI0 : constant Positive := C'First (1);
      CJ0 : constant Positive := C'First (2);
      Sum : Float;
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

   function Block_NW (M : Matrix) return Matrix is
      N  : constant Natural  := M'Length (1) / 2;
      R  : Matrix (1 .. N, 1 .. N);
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
      N  : constant Natural  := M'Length (1) / 2;
      R  : Matrix (1 .. N, 1 .. N);
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
      N  : constant Natural  := M'Length (1) / 2;
      R  : Matrix (1 .. N, 1 .. N);
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
      N  : constant Natural  := M'Length (1) / 2;
      R  : Matrix (1 .. N, 1 .. N);
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
      N  : constant Natural  := Src'Length (1);
      I0 : constant Positive := Dest'First (1);
      J0 : constant Positive := Dest'First (2);
   begin
      for I in 1 .. N loop
         for J in 1 .. N loop
            Dest (I0 + I - 1, J0 + J - 1) :=
              Src (Src'First (1) + I - 1, Src'First (2) + J - 1);
         end loop;
      end loop;
   end Embed_NW;

   procedure Embed_NE (Dest : in out Matrix; Src : Matrix) is
      N  : constant Natural  := Src'Length (1);
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
      N  : constant Natural  := Src'Length (1);
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
      N  : constant Natural  := Src'Length (1);
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

   procedure Strassen_Rec
     (A, B  : Matrix;
      C     : out Matrix;
      Leaf  : Positive;
      Mults : out Natural;
      Depth : out Natural)
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
         T1 := Mat_Add (A11, A22);
         T2 := Mat_Add (B11, B22);
         Strassen_Rec (T1, T2, M1, Leaf, Mults_K, Depth_K);
         Total_M := Total_M + Mults_K;
         if Depth_K > Max_D then
            Max_D := Depth_K;
         end if;

         T1 := Mat_Add (A21, A22);
         Strassen_Rec (T1, B11, M2, Leaf, Mults_K, Depth_K);
         Total_M := Total_M + Mults_K;
         if Depth_K > Max_D then
            Max_D := Depth_K;
         end if;

         T2 := Mat_Sub (B12, B22);
         Strassen_Rec (A11, T2, M3, Leaf, Mults_K, Depth_K);
         Total_M := Total_M + Mults_K;
         if Depth_K > Max_D then
            Max_D := Depth_K;
         end if;

         T2 := Mat_Sub (B21, B11);
         Strassen_Rec (A22, T2, M4, Leaf, Mults_K, Depth_K);
         Total_M := Total_M + Mults_K;
         if Depth_K > Max_D then
            Max_D := Depth_K;
         end if;

         T1 := Mat_Add (A11, A12);
         Strassen_Rec (T1, B22, M5, Leaf, Mults_K, Depth_K);
         Total_M := Total_M + Mults_K;
         if Depth_K > Max_D then
            Max_D := Depth_K;
         end if;

         T1 := Mat_Sub (A21, A11);
         T2 := Mat_Add (B11, B12);
         Strassen_Rec (T1, T2, M6, Leaf, Mults_K, Depth_K);
         Total_M := Total_M + Mults_K;
         if Depth_K > Max_D then
            Max_D := Depth_K;
         end if;

         T1 := Mat_Sub (A12, A22);
         T2 := Mat_Add (B21, B22);
         Strassen_Rec (T1, T2, M7, Leaf, Mults_K, Depth_K);
         Total_M := Total_M + Mults_K;
         if Depth_K > Max_D then
            Max_D := Depth_K;
         end if;

         C11 := Mat_Add (Mat_Add (M1, M4), Mat_Sub (M7, M5));
         C12 := Mat_Add (M3, M5);
         C21 := Mat_Add (M2, M4);
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
   -- Cannon internals
   ---------------------------------------------------------------------------

   procedure Copy_Tile
     (Src              : Matrix;
      Src_Bi, Src_Bj   : Natural;
      Dest             : in out Matrix;
      Dst_Bi, Dst_Bj   : Natural;
      BS               : Positive)
   is
      Sr0 : constant Positive := Src'First (1) + Src_Bi * BS;
      Sc0 : constant Positive := Src'First (2) + Src_Bj * BS;
      Dr0 : constant Positive := Dest'First (1) + Dst_Bi * BS;
      Dc0 : constant Positive := Dest'First (2) + Dst_Bj * BS;
   begin
      for I in 0 .. BS - 1 loop
         for J in 0 .. BS - 1 loop
            Dest (Dr0 + I, Dc0 + J) := Src (Sr0 + I, Sc0 + J);
         end loop;
      end loop;
   end Copy_Tile;

   procedure Block_MAC
     (Loc_A, Loc_B : Matrix;
      Loc_C        : in out Matrix;
      Bi, Bj       : Natural;
      BS           : Positive)
   is
      Ar0 : constant Positive := Loc_A'First (1) + Bi * BS;
      Ac0 : constant Positive := Loc_A'First (2) + Bj * BS;
      Br0 : constant Positive := Loc_B'First (1) + Bi * BS;
      Bc0 : constant Positive := Loc_B'First (2) + Bj * BS;
      Cr0 : constant Positive := Loc_C'First (1) + Bi * BS;
      Cc0 : constant Positive := Loc_C'First (2) + Bj * BS;
      Sum : Float;
   begin
      for I in 0 .. BS - 1 loop
         for J in 0 .. BS - 1 loop
            Sum := Loc_C (Cr0 + I, Cc0 + J);
            for K in 0 .. BS - 1 loop
               Sum := Sum
                 + Loc_A (Ar0 + I, Ac0 + K) * Loc_B (Br0 + K, Bc0 + J);
            end loop;
            Loc_C (Cr0 + I, Cc0 + J) := Sum;
         end loop;
      end loop;
   end Block_MAC;

   procedure Shift_A_Left (Loc_A : in out Matrix; P, BS : Positive) is
      Tmp : Matrix (Loc_A'Range (1), Loc_A'Range (2));
   begin
      for Bi in 0 .. P - 1 loop
         for Bj in 0 .. P - 1 loop
            declare
               Src_Bj : constant Natural := (Bj + 1) mod P;
            begin
               Copy_Tile
                 (Src => Loc_A, Src_Bi => Bi, Src_Bj => Src_Bj,
                  Dest => Tmp, Dst_Bi => Bi, Dst_Bj => Bj, BS => BS);
            end;
         end loop;
      end loop;
      Loc_A := Tmp;
   end Shift_A_Left;

   procedure Shift_B_Up (Loc_B : in out Matrix; P, BS : Positive) is
      Tmp : Matrix (Loc_B'Range (1), Loc_B'Range (2));
   begin
      for Bi in 0 .. P - 1 loop
         for Bj in 0 .. P - 1 loop
            declare
               Src_Bi : constant Natural := (Bi + 1) mod P;
            begin
               Copy_Tile
                 (Src => Loc_B, Src_Bi => Src_Bi, Src_Bj => Bj,
                  Dest => Tmp, Dst_Bi => Bi, Dst_Bj => Bj, BS => BS);
            end;
         end loop;
      end loop;
      Loc_B := Tmp;
   end Shift_B_Up;

   ---------------------------------------------------------------------------
   -- Fail helpers / public multiply
   ---------------------------------------------------------------------------

   function Fail_Dim (M : Method_Kind) return Multiply_Result is
      R : Multiply_Result;
   begin
      R.Stat    := Dimension_Error;
      R.Success := False;
      R.Method  := Method_Kind'Pos (M);
      return R;
   end Fail_Dim;

   function Fail_Catalogue
     (M : Method_Kind; S : Status) return Multiply_Result
   is
      R : Multiply_Result;
   begin
      R.Stat    := S;
      R.Success := False;
      R.Method  := Method_Kind'Pos (M);
      return R;
   end Fail_Catalogue;

   function Multiply_Classical (A, B : Matrix) return Multiply_Result is
      N     : constant Natural := A'Length (1);
      R     : Multiply_Result;
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
         return Fail_Dim (Classical);
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
      R.Method            := Method_Kind'Pos (Classical);
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
      N     : constant Natural := A'Length (1);
      R     : Multiply_Result;
      P     : Natural;
      Mults : Natural;
      Depth : Natural;
   begin
      if N < 1 or else N > Max_N
        or else A'Length (2) /= N
        or else B'Length (1) /= N
        or else B'Length (2) /= N
      then
         return Fail_Dim (Strassen);
      end if;

      P := Next_Power_Of_Two (N);
      if P > Max_N then
         return Fail_Dim (Strassen);
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
         R.Method            := Method_Kind'Pos (Strassen);
         for I in 1 .. N loop
            for J in 1 .. N loop
               R.C (I, J) := C_Pad (I, J);
            end loop;
         end loop;
         return R;
      end;
   end Multiply_Strassen;

   function Multiply_Cannon
     (A      : Matrix;
      B      : Matrix;
      Grid_P : Natural := Default_Grid_P) return Multiply_Result
   is
      N  : constant Natural := A'Length (1);
      R  : Multiply_Result;
      P  : Natural;
      BS : Natural;
   begin
      if N < 1 or else N > Max_N
        or else A'Length (2) /= N
        or else B'Length (1) /= N
        or else B'Length (2) /= N
      then
         return Fail_Dim (Cannon);
      end if;

      if Grid_P = 0 then
         P := N;
      else
         P := Grid_P;
      end if;

      if not Is_Valid_Grid (N, P) then
         R := Fail_Dim (Cannon);
         R.N := N;
         R.Grid_P := P;
         return R;
      end if;

      BS := N / P;
      R.N := N;
      R.Grid_P := P;
      R.Block_Size := BS;
      R.Method := Method_Kind'Pos (Cannon);

      declare
         Loc_A : Matrix (1 .. N, 1 .. N);
         Loc_B : Matrix (1 .. N, 1 .. N);
         Loc_C : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];

         AI0 : constant Positive := A'First (1);
         AJ0 : constant Positive := A'First (2);
         BI0 : constant Positive := B'First (1);
         BJ0 : constant Positive := B'First (2);
      begin
         for I in 0 .. N - 1 loop
            for J in 0 .. N - 1 loop
               Loc_A (1 + I, 1 + J) := A (AI0 + I, AJ0 + J);
               Loc_B (1 + I, 1 + J) := B (BI0 + I, BJ0 + J);
            end loop;
         end loop;

         declare
            Align_A : Matrix (1 .. N, 1 .. N);
            Align_B : Matrix (1 .. N, 1 .. N);
         begin
            for Bi in 0 .. P - 1 loop
               for Bj in 0 .. P - 1 loop
                  declare
                     Src_A_Bj : constant Natural := (Bi + Bj) mod P;
                     Src_B_Bi : constant Natural := (Bi + Bj) mod P;
                  begin
                     Copy_Tile
                       (Src => Loc_A, Src_Bi => Bi, Src_Bj => Src_A_Bj,
                        Dest => Align_A, Dst_Bi => Bi, Dst_Bj => Bj,
                        BS => BS);
                     Copy_Tile
                       (Src => Loc_B, Src_Bi => Src_B_Bi, Src_Bj => Bj,
                        Dest => Align_B, Dst_Bi => Bi, Dst_Bj => Bj,
                        BS => BS);
                  end;
               end loop;
            end loop;
            Loc_A := Align_A;
            Loc_B := Align_B;
         end;

         for Step in 1 .. P loop
            for Bi in 0 .. P - 1 loop
               for Bj in 0 .. P - 1 loop
                  Block_MAC (Loc_A, Loc_B, Loc_C, Bi, Bj, BS);
               end loop;
            end loop;
            if Step < P then
               Shift_A_Left (Loc_A, P, BS);
               Shift_B_Up (Loc_B, P, BS);
            end if;
         end loop;

         R.Shift_Count := P;
         for I in 1 .. N loop
            for J in 1 .. N loop
               R.C (I, J) := Loc_C (I, J);
            end loop;
         end loop;
         R.Stat := Ok;
         R.Success := True;
      end;

      return R;
   end Multiply_Cannon;

   function Multiply
     (A      : Matrix;
      B      : Matrix;
      Method : Method_Kind;
      Leaf   : Positive := Default_Leaf;
      Grid_P : Natural := Default_Grid_P) return Multiply_Result
   is
   begin
      case Method is
         when Classical =>
            return Multiply_Classical (A, B);
         when Strassen =>
            return Multiply_Strassen (A, B, Leaf);
         when Cannon =>
            return Multiply_Cannon (A, B, Grid_P);
         when Freivalds_Verify =>
            return Fail_Catalogue (Method, Not_Implemented);
         when Coppersmith_Winograd | SUMMA =>
            return Fail_Catalogue (Method, Not_Implemented);
         when Laser_Family =>
            return Fail_Catalogue (Method, Galactic_Only);
      end case;
   end Multiply;

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

   ---------------------------------------------------------------------------
   -- Integer classical / Freivalds
   ---------------------------------------------------------------------------

   function Multiply_Classical_Int
     (A, B : Int_Matrix) return Int_Multiply_Result
   is
      N   : constant Natural := A'Length (1);
      R   : Int_Multiply_Result;
      Acc : Long_Integer;
      AI0 : constant Positive := A'First (1);
      AJ0 : constant Positive := A'First (2);
      BI0 : constant Positive := B'First (1);
      BJ0 : constant Positive := B'First (2);
   begin
      if N < 1 or else N > Max_N
        or else A'Length (2) /= N
        or else B'Length (1) /= N
        or else B'Length (2) /= N
      then
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
   end Multiply_Classical_Int;

   function Int_Product_Matrix (R : Int_Multiply_Result) return Int_Matrix is
      P : Int_Matrix (1 .. R.N, 1 .. R.N);
   begin
      for I in 1 .. R.N loop
         for J in 1 .. R.N loop
            P (I, J) := R.C (I, J);
         end loop;
      end loop;
      return P;
   end Int_Product_Matrix;

   function Verify_Freivalds_Once
     (A : Int_Matrix; B : Int_Matrix; C : Int_Matrix; Seed : in out Natural)
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
         AA  : Int_Matrix (1 .. N, 1 .. N);
         BB  : Int_Matrix (1 .. N, 1 .. N);
         CC  : Int_Matrix (1 .. N, 1 .. N);
         Rv  : Int_Vector (1 .. N);
         Br  : Int_Vector (1 .. N);
         ABr : Int_Vector (1 .. N);
         Cr  : Int_Vector (1 .. N);
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

         Rv  := Random_01_Vector (N, Seed);
         Br  := Int_Mat_Vec (BB, Rv);
         ABr := Int_Mat_Vec (AA, Br);
         Cr  := Int_Mat_Vec (CC, Rv);

         if Int_Vec_Equal (ABr, Cr) then
            return Equal_Probably;
         else
            return Unequal;
         end if;
      end;
   end Verify_Freivalds_Once;

   function Verify_Freivalds
     (A      : Int_Matrix;
      B      : Int_Matrix;
      C      : Int_Matrix;
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
         V := Verify_Freivalds_Once (A, B, C, S);
         Res.Trials_Used := Res.Trials_Used + 1;
         if V = Dimension_Error then
            Res.Stat := Dimension_Error;
            Res.Seed_Final := S;
            return Res;
         elsif V = Unequal then
            Res.Failures := Res.Failures + 1;
            Res.Stat := Unequal;
            Res.Seed_Final := S;
            return Res;
         end if;
      end loop;

      Res.Stat := Equal_Probably;
      Res.Seed_Final := S;
      return Res;
   end Verify_Freivalds;

end Matrix_Multiplication;
