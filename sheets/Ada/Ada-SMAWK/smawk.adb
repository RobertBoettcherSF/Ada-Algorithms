--  Smawk body — dense helpers, Monge/TM checkers, naive + SMAWK row minima.

pragma Ada_2022;

package body Smawk
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Scratch dense matrix for Dense → Lookup adapter (educational,
   -- single-threaded; not re-entrant).
   ---------------------------------------------------------------------------

   Scratch      : Dense_Matrix (1 .. Max_N, 1 .. Max_M) :=
     [others => [others => 0.0]];
   Scratch_Rows : Dim_N := 0;
   Scratch_Cols : Dim_M := 0;

   function Scratch_Lookup (Row, Col : Positive) return Float is
   begin
      return Scratch (Row, Col);
   end Scratch_Lookup;

   ---------------------------------------------------------------------------
   -- Dense helpers
   ---------------------------------------------------------------------------

   function Zero_Dense (Rows, Cols : Natural) return Dense_Matrix is
      A : constant Dense_Matrix (1 .. Rows, 1 .. Cols) :=
        [others => [others => 0.0]];
   begin
      return A;
   end Zero_Dense;

   function Get
     (A : Dense_Matrix; Row, Col : Positive) return Float is
   begin
      return A (Row, Col);
   end Get;

   procedure Set
     (A : in out Dense_Matrix; Row, Col : Positive; Value : Float) is
   begin
      A (Row, Col) := Value;
   end Set;

   function Near (X, Y : Float; Tol : Float := 1.0E-5) return Boolean is
   begin
      return abs (X - Y) <= Tol;
   end Near;

   ---------------------------------------------------------------------------
   -- Checkers
   ---------------------------------------------------------------------------

   function Is_Totally_Monotone (A : Dense_Matrix) return Boolean is
   begin
      if A'Length (1) = 0 or else A'Length (2) = 0 then
         return True;
      end if;
      --  A(i,j) > A(i,j') ⇒ A(i',j) >= A(i',j') for i < i', j < j'.
      for I in A'First (1) .. A'Last (1) - 1 loop
         for Ip in I + 1 .. A'Last (1) loop
            for J in A'First (2) .. A'Last (2) - 1 loop
               for Jp in J + 1 .. A'Last (2) loop
                  if A (I, J) > A (I, Jp)
                    and then A (Ip, J) < A (Ip, Jp)
                  then
                     return False;
                  end if;
               end loop;
            end loop;
         end loop;
      end loop;
      return True;
   end Is_Totally_Monotone;

   function Is_Monge (A : Dense_Matrix) return Boolean is
   begin
      if A'Length (1) = 0 or else A'Length (2) = 0 then
         return True;
      end if;
      for I in A'First (1) .. A'Last (1) - 1 loop
         for Ip in I + 1 .. A'Last (1) loop
            for J in A'First (2) .. A'Last (2) - 1 loop
               for Jp in J + 1 .. A'Last (2) loop
                  if A (I, J) + A (Ip, Jp) > A (I, Jp) + A (Ip, J) then
                     return False;
                  end if;
               end loop;
            end loop;
         end loop;
      end loop;
      return True;
   end Is_Monge;

   function Is_Row_Minima_Monotone (A : Dense_Matrix) return Boolean is
      Arg : Argmin_Array (A'Range (1));
   begin
      if A'Length (1) = 0 or else A'Length (2) = 0 then
         return True;
      end if;
      Arg := Naive_Row_Minima (A);
      for I in Arg'First .. Arg'Last - 1 loop
         if Arg (I) > Arg (I + 1) then
            return False;
         end if;
      end loop;
      return True;
   end Is_Row_Minima_Monotone;

   ---------------------------------------------------------------------------
   -- Naive
   ---------------------------------------------------------------------------

   function Naive_Row_Minima (A : Dense_Matrix) return Argmin_Array is
      Result : Argmin_Array (A'Range (1));
      Best   : Col_Index;
      Best_V : Float;
   begin
      for I in A'Range (1) loop
         Best   := Col_Index (A'First (2));
         Best_V := A (I, A'First (2));
         for J in A'First (2) + 1 .. A'Last (2) loop
            if A (I, J) < Best_V then
               Best_V := A (I, J);
               Best   := Col_Index (J);
            end if;
         end loop;
         Result (I) := Best;
      end loop;
      return Result;
   end Naive_Row_Minima;

   function Naive_Row_Minima
     (Lookup     : not null Matrix_Lookup;
      Rows, Cols : Positive) return Argmin_Array
   is
      Result : Argmin_Array (1 .. Rows);
      Best   : Col_Index;
      Best_V : Float;
   begin
      for I in 1 .. Rows loop
         Best   := 1;
         Best_V := Lookup (I, 1);
         for J in 2 .. Cols loop
            declare
               V : constant Float := Lookup (I, J);
            begin
               if V < Best_V then
                  Best_V := V;
                  Best   := Col_Index (J);
               end if;
            end;
         end loop;
         Result (I) := Best;
      end loop;
      return Result;
   end Naive_Row_Minima;

   ---------------------------------------------------------------------------
   -- SMAWK core (row/col index lists)
   ---------------------------------------------------------------------------

   type Index_Buf is array (1 .. Max_N) of Positive;
   type Col_Buf is array (1 .. Max_M) of Positive;

   procedure SMAWK_Recurse
     (Lookup  : not null Matrix_Lookup;
      Rows    : Index_Buf;
      N_Rows  : Natural;
      Cols    : Col_Buf;
      N_Cols  : Natural;
      Out_Arg : in out Argmin_Array);

   --  Reduce: prune columns that cannot hold a row minimum. Stack-based
   --  (Graham-scan / all-nearest-smaller-values style). After reduce,
   --  N_Out <= N_Rows when N_Rows >= 1.
   procedure Reduce
     (Lookup : not null Matrix_Lookup;
      Rows   : Index_Buf;
      N_Rows : Natural;
      Cols   : Col_Buf;
      N_Cols : Natural;
      Out_C  : out Col_Buf;
      N_Out  : out Natural)
   is
      Stack : Col_Buf := [others => 1];
      Top   : Natural := 0;
   begin
      if N_Rows = 0 then
         N_Out := 0;
         Out_C := Stack;
         return;
      end if;

      for K in 1 .. N_Cols loop
         declare
            C : constant Positive := Cols (K);
         begin
            while Top > 0
              and then Top <= N_Rows
              and then Lookup (Rows (Top), Stack (Top))
                         > Lookup (Rows (Top), C)
            loop
               Top := Top - 1;
            end loop;
            if Top < N_Rows then
               Top := Top + 1;
               Stack (Top) := C;
            end if;
         end;
      end loop;

      Out_C := Stack;
      N_Out := Top;
   end Reduce;

   procedure SMAWK_Recurse
     (Lookup  : not null Matrix_Lookup;
      Rows    : Index_Buf;
      N_Rows  : Natural;
      Cols    : Col_Buf;
      N_Cols  : Natural;
      Out_Arg : in out Argmin_Array)
   is
      Red_C  : Col_Buf;
      N_Red  : Natural;
      Even_R : Index_Buf;
      N_Even : Natural := 0;
   begin
      if N_Rows = 0 or else N_Cols = 0 then
         return;
      end if;

      if N_Rows = 1 then
         declare
            Best   : Positive := Cols (1);
            Best_V : Float := Lookup (Rows (1), Cols (1));
         begin
            for K in 2 .. N_Cols loop
               declare
                  V : constant Float := Lookup (Rows (1), Cols (K));
               begin
                  if V < Best_V then
                     Best_V := V;
                     Best   := Cols (K);
                  end if;
               end;
            end loop;
            Out_Arg (Rows (1)) := Col_Index (Best);
         end;
         return;
      end if;

      Reduce (Lookup, Rows, N_Rows, Cols, N_Cols, Red_C, N_Red);

      if N_Red = 0 then
         return;
      end if;

      --  Recurse on even-positioned rows in the current list (2, 4, …).
      for K in 1 .. N_Rows loop
         if K rem 2 = 0 then
            N_Even := N_Even + 1;
            Even_R (N_Even) := Rows (K);
         end if;
      end loop;

      if N_Even > 0 then
         SMAWK_Recurse (Lookup, Even_R, N_Even, Red_C, N_Red, Out_Arg);
      end if;

      --  Interpolate odd-positioned rows between neighboring even minima.
      declare
         procedure Fill_Odd (Pos : Positive) is
            R       : constant Positive := Rows (Pos);
            Left_C  : Positive;
            Right_C : Positive;
            Best    : Positive;
            Best_V  : Float;
            Lo, Hi  : Natural;
         begin
            if Pos = 1 then
               Left_C := Red_C (1);
            else
               Left_C := Positive (Out_Arg (Rows (Pos - 1)));
            end if;

            if Pos = N_Rows then
               Right_C := Red_C (N_Red);
            else
               Right_C := Positive (Out_Arg (Rows (Pos + 1)));
            end if;

            Lo := 1;
            Hi := N_Red;
            for K in 1 .. N_Red loop
               if Red_C (K) = Left_C then
                  Lo := K;
               end if;
               if Red_C (K) = Right_C then
                  Hi := K;
               end if;
            end loop;
            if Lo > Hi then
               declare
                  T : constant Natural := Lo;
               begin
                  Lo := Hi;
                  Hi := T;
               end;
            end if;

            Best   := Red_C (Lo);
            Best_V := Lookup (R, Best);
            for K in Lo + 1 .. Hi loop
               declare
                  V : constant Float := Lookup (R, Red_C (K));
               begin
                  if V < Best_V then
                     Best_V := V;
                     Best   := Red_C (K);
                  end if;
               end;
            end loop;
            Out_Arg (R) := Col_Index (Best);
         end Fill_Odd;
      begin
         for Pos in 1 .. N_Rows loop
            if Pos rem 2 = 1 then
               Fill_Odd (Pos);
            end if;
         end loop;
      end;
   end SMAWK_Recurse;

   function SMAWK_Row_Minima
     (Lookup     : not null Matrix_Lookup;
      Rows, Cols : Positive) return Argmin_Array
   is
      Rbuf : Index_Buf;
      Cbuf : Col_Buf;
      Arg  : Argmin_Array (1 .. Rows) := [others => 1];
   begin
      for I in 1 .. Rows loop
         Rbuf (I) := I;
      end loop;
      for J in 1 .. Cols loop
         Cbuf (J) := J;
      end loop;
      SMAWK_Recurse (Lookup, Rbuf, Rows, Cbuf, Cols, Arg);
      return Arg;
   end SMAWK_Row_Minima;

   function SMAWK_Row_Minima (A : Dense_Matrix) return Argmin_Array is
      Rows : constant Positive := A'Length (1);
      Cols : constant Positive := A'Length (2);
   begin
      Scratch_Rows := Dim_N (Rows);
      Scratch_Cols := Dim_M (Cols);
      for I in 1 .. Rows loop
         for J in 1 .. Cols loop
            Scratch (I, J) :=
              A (A'First (1) + I - 1, A'First (2) + J - 1);
         end loop;
      end loop;
      return SMAWK_Row_Minima (Scratch_Lookup'Access, Rows, Cols);
   end SMAWK_Row_Minima;

   ---------------------------------------------------------------------------
   -- Bind dense → Bound_Lookup
   ---------------------------------------------------------------------------

   procedure Bind_Dense (A : Dense_Matrix) is
      Rows : constant Positive := A'Length (1);
      Cols : constant Positive := A'Length (2);
   begin
      Scratch_Rows := Dim_N (Rows);
      Scratch_Cols := Dim_M (Cols);
      for I in 1 .. Rows loop
         for J in 1 .. Cols loop
            Scratch (I, J) :=
              A (A'First (1) + I - 1, A'First (2) + J - 1);
         end loop;
      end loop;
   end Bind_Dense;

   function Bound_Rows return Dim_N is
   begin
      return Scratch_Rows;
   end Bound_Rows;

   function Bound_Cols return Dim_M is
   begin
      return Scratch_Cols;
   end Bound_Cols;

   function Bound_Lookup (Row, Col : Positive) return Float is
   begin
      return Scratch (Row, Col);
   end Bound_Lookup;

   ---------------------------------------------------------------------------
   -- Builders
   ---------------------------------------------------------------------------

   function Build_Monge_Product
     (Rows, Cols : Positive;
      C          : Float := -1.0) return Dense_Matrix
   is
      A : Dense_Matrix (1 .. Rows, 1 .. Cols);
   begin
      for I in 1 .. Rows loop
         for J in 1 .. Cols loop
            A (I, J) := Float (I) + Float (J)
              + C * Float (I) * Float (J);
         end loop;
      end loop;
      return A;
   end Build_Monge_Product;

   function Build_Squared_Distance
     (Rows, Cols : Positive) return Dense_Matrix
   is
      A : Dense_Matrix (1 .. Rows, 1 .. Cols);
      D : Float;
   begin
      for I in 1 .. Rows loop
         for J in 1 .. Cols loop
            D := Float (I) - Float (J);
            A (I, J) := D * D;
         end loop;
      end loop;
      return A;
   end Build_Squared_Distance;

   function Build_Antitone_Product
     (Rows, Cols : Positive) return Dense_Matrix
   is
      A : Dense_Matrix (1 .. Rows, 1 .. Cols);
   begin
      for I in 1 .. Rows loop
         for J in 1 .. Cols loop
            A (I, J) := Float (I) * (-Float (J));
         end loop;
      end loop;
      return A;
   end Build_Antitone_Product;

   function Build_Non_Monotone_Example return Dense_Matrix is
      --  2×2 whose row minima are top-right and bottom-left:
      --    [ 2  1 ]
      --    [ 0  3 ]
      A : Dense_Matrix (1 .. 2, 1 .. 2);
   begin
      A (1, 1) := 2.0;
      A (1, 2) := 1.0;
      A (2, 1) := 0.0;
      A (2, 2) := 3.0;
      return A;
   end Build_Non_Monotone_Example;

end Smawk;
