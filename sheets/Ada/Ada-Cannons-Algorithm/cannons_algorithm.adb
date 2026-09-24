--  Cannon's algorithm body: classical multiply and sequential simulation
--  of the P×P 2D-mesh systolic scheme (explicit block storage + shifts).

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Cannons_Algorithm
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

   function Divides (P, N : Natural) return Boolean is
   begin
      return P > 0 and then N mod P = 0;
   end Divides;

   function Is_Valid_Grid (N, P : Natural) return Boolean is
   begin
      return N >= 1
        and then N <= Max_N
        and then P >= 1
        and then P <= N
        and then N mod P = 0;
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
   -- Classical multiply
   ---------------------------------------------------------------------------

   function Multiply_Classical (A, B : Matrix) return Multiply_Result is
      N  : constant Natural := A'Length (1);
      R  : Multiply_Result;
      AI0 : constant Positive := A'First (1);
      AJ0 : constant Positive := A'First (2);
      BI0 : constant Positive := B'First (1);
      BJ0 : constant Positive := B'First (2);
      Sum : Float;
   begin
      if N < 1 or else N > Max_N then
         R.Stat := Dimension_Error;
         R.Success := False;
         return R;
      end if;

      R.N := N;
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            Sum := 0.0;
            for K in 0 .. N - 1 loop
               Sum := Sum
                 + A (AI0 + I, AJ0 + K) * B (BI0 + K, BJ0 + J);
            end loop;
            R.C (1 + I, 1 + J) := Sum;
         end loop;
      end loop;
      R.Stat := Ok;
      R.Success := True;
      return R;
   end Multiply_Classical;

   ---------------------------------------------------------------------------
   -- Cannon: internal block helpers (explicit storage for teaching)
   --
   --  Loc_A / Loc_B / Loc_C are full n×n arrays whose P×P tiles sit at the
   --  logical PE (Bi, Bj).  Element (r,c) belongs to PE
   --    ( (r-1)/BS , (c-1)/BS ) with local offset inside the tile.
   ---------------------------------------------------------------------------

   --  Copy a BS×BS tile from Src at PE (Src_Bi, Src_Bj) into Dest at
   --  PE (Dst_Bi, Dst_Bj).  Indices are 0-based PE coordinates.
   procedure Copy_Tile
     (Src                    : Matrix;
      Src_Bi, Src_Bj         : Natural;
      Dest                   : in out Matrix;
      Dst_Bi, Dst_Bj         : Natural;
      BS                     : Positive)
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

   --  Loc_C(PE) += Loc_A(PE) * Loc_B(PE)   (classical BS×BS GEMM accumulate)
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

   --  Circular-shift every row of tiles one PE to the left (toroidal).
   --  PE (Bi, Bj) receives the tile formerly at (Bi, (Bj+1) mod P).
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

   --  Circular-shift every column of tiles one PE upward (toroidal).
   --  PE (Bi, Bj) receives the tile formerly at ((Bi+1) mod P, Bj).
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
      if N < 1 or else N > Max_N then
         R.Stat := Dimension_Error;
         R.Success := False;
         return R;
      end if;

      --  Resolve default: Grid_P = 0 → element-per-PE mesh (P = n).
      if Grid_P = 0 then
         P := N;
      else
         P := Grid_P;
      end if;

      if not Is_Valid_Grid (N, P) then
         R.Stat := Dimension_Error;
         R.Success := False;
         R.N := N;
         R.Grid_P := P;
         return R;
      end if;

      BS := N / P;
      R.N := N;
      R.Grid_P := P;
      R.Block_Size := BS;

      declare
         --  Working copies: what each PE currently holds (full n×n layout).
         Loc_A : Matrix (1 .. N, 1 .. N);
         Loc_B : Matrix (1 .. N, 1 .. N);
         Loc_C : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];

         AI0 : constant Positive := A'First (1);
         AJ0 : constant Positive := A'First (2);
         BI0 : constant Positive := B'First (1);
         BJ0 : constant Positive := B'First (2);
      begin
         --  Copy inputs into 1-based working storage (do not mutate A, B).
         for I in 0 .. N - 1 loop
            for J in 0 .. N - 1 loop
               Loc_A (1 + I, 1 + J) := A (AI0 + I, AJ0 + J);
               Loc_B (1 + I, 1 + J) := B (BI0 + I, BJ0 + J);
            end loop;
         end loop;

         ----------------------------------------------------------------
         -- Initial alignment (Cannon skew):
         --   row Bi of A is circular-shifted left by Bi tiles;
         --   column Bj of B is circular-shifted up by Bj tiles.
         -- Equivalently, PE (Bi, Bj) starts with
         --   A_block[Bi][(Bi+Bj) mod P]  and  B_block[(Bi+Bj) mod P][Bj].
         ----------------------------------------------------------------
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

         ----------------------------------------------------------------
         -- Systolic loop: P steps of local MAC + neighbour shifts.
         -- After P steps every PE has summed all AB contributions for its
         -- C tile; Shift_Count records how many shift rounds ran (= P).
         ----------------------------------------------------------------
         for Step in 1 .. P loop
            for Bi in 0 .. P - 1 loop
               for Bj in 0 .. P - 1 loop
                  Block_MAC (Loc_A, Loc_B, Loc_C, Bi, Bj, BS);
               end loop;
            end loop;

            --  Last step needs no further communication, but we still
            --  count the MAC; shifts after the final MAC are omitted so
            --  that Shift_Count equals the number of MAC rounds (= P).
            --  (Communication rounds between MACs would be P−1; the
            --  educational counter here is the number of systolic steps.)
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

   function Product_Matrix (R : Multiply_Result) return Matrix is
      M : Matrix (1 .. R.N, 1 .. R.N);
   begin
      for I in 1 .. R.N loop
         for J in 1 .. R.N loop
            M (I, J) := R.C (I, J);
         end loop;
      end loop;
      return M;
   end Product_Matrix;

end Cannons_Algorithm;
