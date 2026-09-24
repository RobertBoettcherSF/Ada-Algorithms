--  Sparse_Matrix body — COO / CSR / CSC conversions and SpMV.

pragma Ada_2022;

package body Sparse_Matrix is

   ---------------------------------------------------------------------------
   -- Local helpers
   ---------------------------------------------------------------------------

   function Abs_F (X : Float) return Float is
   begin
      if X < 0.0 then
         return -X;
      else
         return X;
      end if;
   end Abs_F;

   procedure Ensure_Capacity (Nnz : Natural) is
   begin
      if Nnz > Max_Nnz then
         raise Capacity_Exceeded
           with "nnz exceeds Max_Nnz=" & Max_Nnz'Image;
      end if;
   end Ensure_Capacity;

   --  Simple LCG (Numerical Recipes style) for deterministic builders.
   type U32 is mod 2 ** 32;

   procedure Lcg_Next (State : in out U32) is
   begin
      State := State * 1664525 + 1013904223;
   end Lcg_Next;

   function Lcg_Float (State : in out U32) return Float is
   begin
      Lcg_Next (State);
      return Float (State) / Float (U32'Last);
   end Lcg_Float;

   function Lcg_Index (State : in out U32; Lo, Hi : Positive) return Positive
   is
      Span : constant Natural := Hi - Lo + 1;
   begin
      Lcg_Next (State);
      return Lo + Natural (State mod U32 (Span));
   end Lcg_Index;

   --  Sort triplets by (Row, Col) ascending — insertion sort (nnz ≤ 512).
   procedure Sort_By_Row_Col (T : in out Triplet_Array) is
      Key : Triplet;
      J   : Natural;
   begin
      for I in T'First + 1 .. T'Last loop
         Key := T (I);
         J   := I - 1;
         while J >= T'First
           and then (T (J).Row > Key.Row
             or else (T (J).Row = Key.Row and then T (J).Col > Key.Col))
         loop
            T (J + 1) := T (J);
            J := J - 1;
         end loop;
         T (J + 1) := Key;
      end loop;
   end Sort_By_Row_Col;

   procedure Sort_By_Col_Row (T : in out Triplet_Array) is
      Key : Triplet;
      J   : Natural;
   begin
      for I in T'First + 1 .. T'Last loop
         Key := T (I);
         J   := I - 1;
         while J >= T'First
           and then (T (J).Col > Key.Col
             or else (T (J).Col = Key.Col and then T (J).Row > Key.Row))
         loop
            T (J + 1) := T (J);
            J := J - 1;
         end loop;
         T (J + 1) := Key;
      end loop;
   end Sort_By_Col_Row;

   --  Coalesce consecutive equal (Row,Col) by summing Values; returns new Nnz.
   function Coalesce_In_Place (T : in out Triplet_Array) return Nnz_Count is
      W : Natural := 0;
   begin
      if T'Length = 0 then
         return 0;
      end if;
      W := T'First;
      for R in T'First + 1 .. T'Last loop
         if T (R).Row = T (W).Row and then T (R).Col = T (W).Col then
            T (W).Value := T (W).Value + T (R).Value;
         else
            W := W + 1;
            T (W) := T (R);
         end if;
      end loop;
      return Nnz_Count (W - T'First + 1);
   end Coalesce_In_Place;

   ---------------------------------------------------------------------------
   -- Numeric / density helpers
   ---------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Epsilon_Tol) return Boolean is
   begin
      return Abs_F (A - B) <= Tol;
   end Near;

   function Vec_Near
     (A, B : Vector; Tol : Float := Epsilon_Tol) return Boolean
   is
   begin
      for I in A'Range loop
         if not Near (A (I), B (B'First + (I - A'First)), Tol) then
            return False;
         end if;
      end loop;
      return True;
   end Vec_Near;

   function Mat_Near
     (A, B : Dense_Matrix; Tol : Float := Epsilon_Tol) return Boolean
   is
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            if not Near
              (A (I, J),
               B (B'First (1) + (I - A'First (1)),
                  B'First (2) + (J - A'First (2))),
               Tol)
            then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Mat_Near;

   function Density (Nnz : Natural; Rows, Cols : Natural) return Float is
      Denom : constant Natural := Rows * Cols;
   begin
      if Denom = 0 then
         return 0.0;
      end if;
      return Float (Nnz) / Float (Denom);
   end Density;

   function Sparsity (Nnz : Natural; Rows, Cols : Natural) return Float is
   begin
      return 1.0 - Density (Nnz, Rows, Cols);
   end Sparsity;

   function Count_Nnz
     (A : Dense_Matrix; Tol : Float := Epsilon_Tol) return Natural
   is
      C : Natural := 0;
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            if Abs_F (A (I, J)) > Tol then
               C := C + 1;
            end if;
         end loop;
      end loop;
      return C;
   end Count_Nnz;

   function Density
     (A : Dense_Matrix; Tol : Float := Epsilon_Tol) return Float
   is
   begin
      return Density (Count_Nnz (A, Tol), A'Length (1), A'Length (2));
   end Density;

   function Sparsity
     (A : Dense_Matrix; Tol : Float := Epsilon_Tol) return Float
   is
   begin
      return 1.0 - Density (A, Tol);
   end Sparsity;

   function Density (C : COO) return Float is
   begin
      return Density (Natural (C.Nnz), Natural (C.Rows), Natural (C.Cols));
   end Density;

   function Sparsity (C : COO) return Float is
   begin
      return 1.0 - Density (C);
   end Sparsity;

   function Density (C : CSR) return Float is
   begin
      return Density (Natural (C.Nnz), Natural (C.Rows), Natural (C.Cols));
   end Density;

   function Sparsity (C : CSR) return Float is
   begin
      return 1.0 - Density (C);
   end Sparsity;

   function Density (C : CSC) return Float is
   begin
      return Density (Natural (C.Nnz), Natural (C.Rows), Natural (C.Cols));
   end Density;

   function Sparsity (C : CSC) return Float is
   begin
      return 1.0 - Density (C);
   end Sparsity;

   ---------------------------------------------------------------------------
   -- Dense construction
   ---------------------------------------------------------------------------

   function Zero_Dense (Rows, Cols : Dim) return Dense_Matrix is
      Z : constant Dense_Matrix (1 .. Rows, 1 .. Cols) :=
        [others => [others => 0.0]];
   begin
      return Z;
   end Zero_Dense;

   function Zero_Vector (N : Dim) return Vector is
      Z : constant Vector (1 .. N) := [others => 0.0];
   begin
      return Z;
   end Zero_Vector;

   function From_Dense
     (A : Dense_Matrix; Tol : Float := Epsilon_Tol) return COO
   is
      Rows : constant Dim := Dim (A'Length (1));
      Cols : constant Dim := Dim (A'Length (2));
      Nnz  : constant Natural := Count_Nnz (A, Tol);
      K    : Natural := 0;
   begin
      Ensure_Capacity (Nnz);
      declare
         Result : COO (Nnz_Count (Nnz), Rows, Cols);
      begin
         for I in A'Range (1) loop
            for J in A'Range (2) loop
               if Abs_F (A (I, J)) > Tol then
                  K := K + 1;
                  Result.Entries (K) :=
                    (Row   => Index (I - A'First (1) + 1),
                     Col   => Index (J - A'First (2) + 1),
                     Value => A (I, J));
               end if;
            end loop;
         end loop;
         return Result;
      end;
   end From_Dense;

   function To_Dense (C : COO) return Dense_Matrix is
      A : Dense_Matrix (1 .. C.Rows, 1 .. C.Cols) :=
        [others => [others => 0.0]];
   begin
      for K in 1 .. C.Nnz loop
         declare
            T : constant Triplet := C.Entries (K);
         begin
            if T.Row not in 1 .. C.Rows or else T.Col not in 1 .. C.Cols then
               raise Invalid_Argument with "COO triplet out of bounds";
            end if;
            A (T.Row, T.Col) := A (T.Row, T.Col) + T.Value;
         end;
      end loop;
      return A;
   end To_Dense;

   function To_Dense (C : CSR) return Dense_Matrix is
      A : Dense_Matrix (1 .. C.Rows, 1 .. C.Cols) :=
        [others => [others => 0.0]];
   begin
      for I in 1 .. C.Rows loop
         for P in C.Row_Ptr (I) .. C.Row_Ptr (I + 1) - 1 loop
            A (I, C.Col_Ind (P)) := A (I, C.Col_Ind (P)) + C.Values (P);
         end loop;
      end loop;
      return A;
   end To_Dense;

   function To_Dense (C : CSC) return Dense_Matrix is
      A : Dense_Matrix (1 .. C.Rows, 1 .. C.Cols) :=
        [others => [others => 0.0]];
   begin
      for J in 1 .. C.Cols loop
         for P in C.Col_Ptr (J) .. C.Col_Ptr (J + 1) - 1 loop
            A (C.Row_Ind (P), J) := A (C.Row_Ind (P), J) + C.Values (P);
         end loop;
      end loop;
      return A;
   end To_Dense;

   function Dense_Mat_Vec (A : Dense_Matrix; X : Vector) return Vector is
      Y : Vector (A'Range (1)) := [others => 0.0];
   begin
      for I in A'Range (1) loop
         declare
            Acc : Float := 0.0;
         begin
            for J in A'Range (2) loop
               Acc := Acc + A (I, J) * X (X'First + (J - A'First (2)));
            end loop;
            Y (I) := Acc;
         end;
      end loop;
      return Y;
   end Dense_Mat_Vec;

   ---------------------------------------------------------------------------
   -- Get / Set
   ---------------------------------------------------------------------------

   function Get (A : Dense_Matrix; I, J : Index) return Float is
   begin
      return A (I, J);
   end Get;

   procedure Set (A : in out Dense_Matrix; I, J : Index; Value : Float) is
   begin
      A (I, J) := Value;
   end Set;

   function Get (C : CSR; I, J : Index) return Float is
      Acc : Float := 0.0;
   begin
      for P in C.Row_Ptr (I) .. C.Row_Ptr (I + 1) - 1 loop
         if C.Col_Ind (P) = J then
            Acc := Acc + C.Values (P);
         end if;
      end loop;
      return Acc;
   end Get;

   function Get (C : CSC; I, J : Index) return Float is
      Acc : Float := 0.0;
   begin
      for P in C.Col_Ptr (J) .. C.Col_Ptr (J + 1) - 1 loop
         if C.Row_Ind (P) = I then
            Acc := Acc + C.Values (P);
         end if;
      end loop;
      return Acc;
   end Get;

   function Get (C : COO; I, J : Index) return Float is
      Acc : Float := 0.0;
   begin
      for K in 1 .. C.Nnz loop
         if C.Entries (K).Row = I and then C.Entries (K).Col = J then
            Acc := Acc + C.Entries (K).Value;
         end if;
      end loop;
      return Acc;
   end Get;

   ---------------------------------------------------------------------------
   -- Format conversions
   ---------------------------------------------------------------------------

   function To_CSR (C : COO) return CSR is
      Buf : Triplet_Array := C.Entries;
      N   : Nnz_Count;
   begin
      if C.Nnz = 0 then
         declare
            Empty : CSR (0, C.Rows, C.Cols);
         begin
            for I in Empty.Row_Ptr'Range loop
               Empty.Row_Ptr (I) := 1;
            end loop;
            return Empty;
         end;
      end if;

      for K in Buf'Range loop
         if Buf (K).Row not in 1 .. C.Rows
           or else Buf (K).Col not in 1 .. C.Cols
         then
            raise Invalid_Argument with "COO triplet out of bounds in To_CSR";
         end if;
      end loop;

      Sort_By_Row_Col (Buf);
      N := Coalesce_In_Place (Buf);

      declare
         Result : CSR (N, C.Rows, C.Cols);
         K      : Positive := 1;
         P      : Positive := 1;
      begin
         Result.Row_Ptr (1) := 1;
         for R in 1 .. C.Rows loop
            while K <= N and then Buf (Buf'First + (K - 1)).Row = R loop
               Result.Values (P)  := Buf (Buf'First + (K - 1)).Value;
               Result.Col_Ind (P) := Buf (Buf'First + (K - 1)).Col;
               P := P + 1;
               K := K + 1;
            end loop;
            Result.Row_Ptr (R + 1) := P;
         end loop;
         return Result;
      end;
   end To_CSR;

   function To_CSC (C : COO) return CSC is
      Buf : Triplet_Array := C.Entries;
      N   : Nnz_Count;
   begin
      if C.Nnz = 0 then
         declare
            Empty : CSC (0, C.Rows, C.Cols);
         begin
            for I in Empty.Col_Ptr'Range loop
               Empty.Col_Ptr (I) := 1;
            end loop;
            return Empty;
         end;
      end if;

      for K in Buf'Range loop
         if Buf (K).Row not in 1 .. C.Rows
           or else Buf (K).Col not in 1 .. C.Cols
         then
            raise Invalid_Argument with "COO triplet out of bounds in To_CSC";
         end if;
      end loop;

      Sort_By_Col_Row (Buf);
      N := Coalesce_In_Place (Buf);

      declare
         Result : CSC (N, C.Rows, C.Cols);
         K      : Positive := 1;
         P      : Positive := 1;
      begin
         Result.Col_Ptr (1) := 1;
         for Col in 1 .. C.Cols loop
            while K <= N and then Buf (Buf'First + (K - 1)).Col = Col loop
               Result.Values (P)  := Buf (Buf'First + (K - 1)).Value;
               Result.Row_Ind (P) := Buf (Buf'First + (K - 1)).Row;
               P := P + 1;
               K := K + 1;
            end loop;
            Result.Col_Ptr (Col + 1) := P;
         end loop;
         return Result;
      end;
   end To_CSC;

   function To_COO (C : CSR) return COO is
      Result : COO (C.Nnz, C.Rows, C.Cols);
      K      : Natural := 0;
   begin
      for I in 1 .. C.Rows loop
         for P in C.Row_Ptr (I) .. C.Row_Ptr (I + 1) - 1 loop
            K := K + 1;
            Result.Entries (K) :=
              (Row => I, Col => C.Col_Ind (P), Value => C.Values (P));
         end loop;
      end loop;
      return Result;
   end To_COO;

   function To_COO (C : CSC) return COO is
      Result : COO (C.Nnz, C.Rows, C.Cols);
      K      : Natural := 0;
   begin
      for J in 1 .. C.Cols loop
         for P in C.Col_Ptr (J) .. C.Col_Ptr (J + 1) - 1 loop
            K := K + 1;
            Result.Entries (K) :=
              (Row => C.Row_Ind (P), Col => J, Value => C.Values (P));
         end loop;
      end loop;
      return Result;
   end To_COO;

   function To_CSC (C : CSR) return CSC is
   begin
      return To_CSC (To_COO (C));
   end To_CSC;

   function To_CSR (C : CSC) return CSR is
   begin
      return To_CSR (To_COO (C));
   end To_CSR;

   function Is_Valid_CSR (C : CSR) return Boolean is
   begin
      if C.Rows = 0 then
         return C.Nnz = 0;
      end if;
      if C.Row_Ptr (1) /= 1 then
         return False;
      end if;
      if C.Row_Ptr (C.Rows + 1) /= Natural (C.Nnz) + 1 then
         return False;
      end if;
      for I in 1 .. C.Rows loop
         if C.Row_Ptr (I + 1) < C.Row_Ptr (I) then
            return False;
         end if;
         for P in C.Row_Ptr (I) .. C.Row_Ptr (I + 1) - 1 loop
            if P < 1 or else P > Natural (C.Nnz) then
               return False;
            end if;
            if C.Col_Ind (P) not in 1 .. C.Cols then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Valid_CSR;

   function Is_Valid_CSC (C : CSC) return Boolean is
   begin
      if C.Cols = 0 then
         return C.Nnz = 0;
      end if;
      if C.Col_Ptr (1) /= 1 then
         return False;
      end if;
      if C.Col_Ptr (C.Cols + 1) /= Natural (C.Nnz) + 1 then
         return False;
      end if;
      for J in 1 .. C.Cols loop
         if C.Col_Ptr (J + 1) < C.Col_Ptr (J) then
            return False;
         end if;
         for P in C.Col_Ptr (J) .. C.Col_Ptr (J + 1) - 1 loop
            if P < 1 or else P > Natural (C.Nnz) then
               return False;
            end if;
            if C.Row_Ind (P) not in 1 .. C.Rows then
               return False;
            end if;
         end loop;
      end loop;
      return True;
   end Is_Valid_CSC;

   ---------------------------------------------------------------------------
   -- SpMV
   ---------------------------------------------------------------------------

   function SpMV_CSR (A : CSR; X : Vector) return Vector is
      Y : Vector (1 .. A.Rows) := [others => 0.0];
   begin
      if X'Length /= A.Cols then
         raise Invalid_Argument with "SpMV_CSR: X length /= Cols";
      end if;
      for I in 1 .. A.Rows loop
         declare
            Acc : Float := 0.0;
         begin
            for P in A.Row_Ptr (I) .. A.Row_Ptr (I + 1) - 1 loop
               Acc := Acc
                 + A.Values (P)
                 * X (X'First + (A.Col_Ind (P) - 1));
            end loop;
            Y (I) := Acc;
         end;
      end loop;
      return Y;
   end SpMV_CSR;

   function SpMV_CSC (A : CSC; X : Vector) return Vector is
      Y : Vector (1 .. A.Rows) := [others => 0.0];
   begin
      if X'Length /= A.Cols then
         raise Invalid_Argument with "SpMV_CSC: X length /= Cols";
      end if;
      for J in 1 .. A.Cols loop
         declare
            Xj : constant Float := X (X'First + (J - 1));
         begin
            for P in A.Col_Ptr (J) .. A.Col_Ptr (J + 1) - 1 loop
               Y (A.Row_Ind (P)) := Y (A.Row_Ind (P)) + A.Values (P) * Xj;
            end loop;
         end;
      end loop;
      return Y;
   end SpMV_CSC;

   function SpMV_COO (A : COO; X : Vector) return Vector is
      Y : Vector (1 .. A.Rows) := [others => 0.0];
   begin
      if X'Length /= A.Cols then
         raise Invalid_Argument with "SpMV_COO: X length /= Cols";
      end if;
      for K in 1 .. A.Nnz loop
         declare
            T : constant Triplet := A.Entries (K);
         begin
            Y (T.Row) :=
              Y (T.Row) + T.Value * X (X'First + (T.Col - 1));
         end;
      end loop;
      return Y;
   end SpMV_COO;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Diagonal (Diag : Vector) return COO is
      N    : constant Dim := Dim (Diag'Length);
      Nnz0 : Natural := 0;
   begin
      for V of Diag loop
         if Abs_F (V) > Epsilon_Tol then
            Nnz0 := Nnz0 + 1;
         end if;
      end loop;
      Ensure_Capacity (Nnz0);
      declare
         Result : COO (Nnz_Count (Nnz0), N, N);
         K      : Natural := 0;
         I      : Positive := 1;
      begin
         for V of Diag loop
            if Abs_F (V) > Epsilon_Tol then
               K := K + 1;
               Result.Entries (K) :=
                 (Row => Index (I), Col => Index (I), Value => V);
            end if;
            I := I + 1;
         end loop;
         return Result;
      end;
   end Diagonal;

   function Diagonal_CSR (Diag : Vector) return CSR is
   begin
      return To_CSR (Diagonal (Diag));
   end Diagonal_CSR;

   function Tridiagonal
     (Lower, Main, Upper : Vector) return COO
   is
      N    : constant Dim := Dim (Main'Length);
      Nnz0 : Natural := 0;
      Buf  : Triplet_Array (1 .. 3 * Max_N);
   begin
      --  Main diagonal
      for I in 1 .. Natural (N) loop
         declare
            V : constant Float := Main (Main'First + (I - 1));
         begin
            if Abs_F (V) > Epsilon_Tol then
               Nnz0 := Nnz0 + 1;
               Buf (Nnz0) :=
                 (Row => Index (I), Col => Index (I), Value => V);
            end if;
         end;
      end loop;
      --  Lower (i, i−1) for i = 2 .. N
      for I in 1 .. Natural (N) - 1 loop
         declare
            V : constant Float := Lower (Lower'First + (I - 1));
         begin
            if Abs_F (V) > Epsilon_Tol then
               Nnz0 := Nnz0 + 1;
               Buf (Nnz0) :=
                 (Row => Index (I + 1), Col => Index (I), Value => V);
            end if;
         end;
      end loop;
      --  Upper (i, i+1) for i = 1 .. N−1
      for I in 1 .. Natural (N) - 1 loop
         declare
            V : constant Float := Upper (Upper'First + (I - 1));
         begin
            if Abs_F (V) > Epsilon_Tol then
               Nnz0 := Nnz0 + 1;
               Buf (Nnz0) :=
                 (Row => Index (I), Col => Index (I + 1), Value => V);
            end if;
         end;
      end loop;
      Ensure_Capacity (Nnz0);
      declare
         Result : COO (Nnz_Count (Nnz0), N, N);
      begin
         for K in 1 .. Nnz0 loop
            Result.Entries (K) := Buf (K);
         end loop;
         return Result;
      end;
   end Tridiagonal;

   function Tridiagonal_CSR
     (Lower, Main, Upper : Vector) return CSR
   is
   begin
      return To_CSR (Tridiagonal (Lower, Main, Upper));
   end Tridiagonal_CSR;

   function Identity (N : Dim) return CSR is
      Ones : constant Vector (1 .. N) := [others => 1.0];
   begin
      return Diagonal_CSR (Ones);
   end Identity;

   function Random_COO
     (Rows, Cols   : Dim;
      Target_Nnz   : Nnz_Count;
      Seed         : Natural := 42;
      Value_Scale  : Float   := 1.0) return COO
   is
      State : U32 := U32 (Seed) + 1;
      --  Occupancy map as flat boolean array over Max_N*Max_N
      Occupied : array (1 .. Max_N, 1 .. Max_N) of Boolean :=
        [others => [others => False]];
      Placed   : Natural := 0;
      Guard    : Natural := 0;
      Max_Try  : constant Natural :=
        Natural (Target_Nnz) * 20 + Natural (Rows) * Natural (Cols) + 8;
      Result   : COO (Target_Nnz, Rows, Cols);
   begin
      if Rows = 0 or else Cols = 0 or else Target_Nnz = 0 then
         declare
            Empty : COO (0, Rows, Cols);
         begin
            return Empty;
         end;
      end if;

      while Placed < Natural (Target_Nnz) and then Guard < Max_Try loop
         declare
            R : constant Positive :=
              Lcg_Index (State, 1, Positive (Rows));
            C : constant Positive :=
              Lcg_Index (State, 1, Positive (Cols));
            V : Float;
         begin
            Guard := Guard + 1;
            if not Occupied (R, C) then
               Occupied (R, C) := True;
               Placed := Placed + 1;
               V := (Lcg_Float (State) * 2.0 - 1.0) * Value_Scale;
               if Abs_F (V) < 1.0E-3 then
                  V := Value_Scale;
               end if;
               Result.Entries (Placed) :=
                 (Row => Index (R), Col => Index (C), Value => V);
            end if;
         end;
      end loop;

      if Placed < Natural (Target_Nnz) then
         --  Shrink by rebuilding with actual count
         declare
            Shrunk : COO (Nnz_Count (Placed), Rows, Cols);
         begin
            for K in 1 .. Placed loop
               Shrunk.Entries (K) := Result.Entries (K);
            end loop;
            return Shrunk;
         end;
      end if;
      return Result;
   end Random_COO;

   ---------------------------------------------------------------------------
   -- Taxonomy
   ---------------------------------------------------------------------------

   function Format_Name (F : Format_Kind) return String is
   begin
      case F is
         when Coordinate_COO =>
            return "COO (Coordinate list)";
         when Compressed_Row_CSR =>
            return "CSR (Compressed Sparse Row / Yale)";
         when Compressed_Column_CSC =>
            return "CSC (Compressed Sparse Column)";
         when Diagonal_DIA =>
            return "DIA (Diagonal)";
         when ELLPACK_ELL =>
            return "ELL (ELLPACK)";
         when Blocked_BSR =>
            return "Blocked / BSR";
      end case;
   end Format_Name;

   function Implemented (F : Format_Kind) return Boolean is
   begin
      case F is
         when Coordinate_COO | Compressed_Row_CSR | Compressed_Column_CSC =>
            return True;
         when Diagonal_DIA | ELLPACK_ELL | Blocked_BSR =>
            return False;
      end case;
   end Implemented;

   function Forthcoming (F : Format_Kind) return Boolean is
   begin
      return not Implemented (F);
   end Forthcoming;

end Sparse_Matrix;
