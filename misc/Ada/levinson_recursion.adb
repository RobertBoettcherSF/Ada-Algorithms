--  Levinson_Recursion body — O(n^2) Levinson / Durbin for Toeplitz systems.

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Levinson_Recursion
  with SPARK_Mode => Off
is

   package Math renames Ada.Numerics.Elementary_Functions;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Near (A, B : Float; Tol : Float := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Vec_Near
     (A, B : Vector; Tol : Float := Epsilon_Tol) return Boolean
   is
   begin
      for I in A'Range loop
         if abs (A (I) - B (I - A'First + B'First)) > Tol then
            return False;
         end if;
      end loop;
      return True;
   end Vec_Near;

   function Norm2 (V : Vector) return Float is
      S : Float := 0.0;
   begin
      for X of V loop
         S := S + X * X;
      end loop;
      return Math.Sqrt (S);
   end Norm2;

   function Max_Abs (V : Vector) return Float is
      M : Float := 0.0;
   begin
      for X of V loop
         if abs (X) > M then
            M := abs (X);
         end if;
      end loop;
      return M;
   end Max_Abs;

   function Zero_Vector (N : Dimension) return Vector is
      Z : constant Vector (1 .. N) := [others => 0.0];
   begin
      return Z;
   end Zero_Vector;

   function Ones_Vector (N : Dimension; Value : Float := 1.0) return Vector is
      Z : constant Vector (1 .. N) := [others => Value];
   begin
      return Z;
   end Ones_Vector;

   -------------------------------------------------------------------------
   -- Toeplitz helpers
   -------------------------------------------------------------------------

   function Toeplitz_Entry
     (R : Toeplitz_Row; I, J : Positive) return Float
   is
      D : constant Natural :=
        (if I >= J then I - J else J - I);
   begin
      return R (R'First + D);
   end Toeplitz_Entry;

   function Multiply_Toeplitz
     (R : Toeplitz_Row; X : Vector) return Vector
   is
      N   : constant Positive := X'Length;
      LoR : constant Positive := R'First;
      LoX : constant Positive := X'First;
      Y   : Vector (1 .. N) := [others => 0.0];
   begin
      for I in 1 .. N loop
         declare
            S : Float := 0.0;
         begin
            for J in 1 .. N loop
               S := S + R (LoR + (if I >= J then I - J else J - I))
                      * X (LoX + J - 1);
            end loop;
            Y (I) := S;
         end;
      end loop;
      return Y;
   end Multiply_Toeplitz;

   function Residual
     (R : Toeplitz_Row; Y, X : Vector) return Vector
   is
      TX : constant Vector := Multiply_Toeplitz (R, X);
      Res : Vector (1 .. Y'Length);
      LoY : constant Positive := Y'First;
   begin
      for I in 1 .. Y'Length loop
         Res (I) := Y (LoY + I - 1) - TX (I);
      end loop;
      return Res;
   end Residual;

   function Residual_Norm
     (R : Toeplitz_Row; Y, X : Vector) return Float
   is
   begin
      return Norm2 (Residual (R, Y, X));
   end Residual_Norm;

   function Residual_Max_Abs
     (R : Toeplitz_Row; Y, X : Vector) return Float
   is
   begin
      return Max_Abs (Residual (R, Y, X));
   end Residual_Max_Abs;

   procedure Make_Exponential_Toeplitz
     (N     : Dimension;
      Diag  : Float;
      Rho   : Float;
      Scale : Float := 1.0;
      R     : out Toeplitz_Row)
   is
      P : Float := 1.0;
   begin
      R (R'First) := Diag;
      for K in 2 .. N loop
         P := P * Rho;
         R (R'First + K - 1) := Scale * P;
      end loop;
   end Make_Exponential_Toeplitz;

   procedure Make_Constant_Toeplitz
     (N          : Dimension;
      Diag, Off  : Float;
      R          : out Toeplitz_Row)
   is
   begin
      R (R'First) := Diag;
      for K in 2 .. N loop
         R (R'First + K - 1) := Off;
      end loop;
   end Make_Constant_Toeplitz;

   -------------------------------------------------------------------------
   -- Solve_Levinson (Wikipedia forward / backward vectors, symmetric)
   -------------------------------------------------------------------------

   function Solve_Levinson
     (R : Toeplitz_Row; Y : Vector) return Result
   is
      N   : constant Positive := Y'Length;
      LoR : constant Positive := R'First;
      LoY : constant Positive := Y'First;
      Res : Result;
      --  Forward vector F(1..M) at order M; T_M F = e_1.
      F   : Vector (1 .. Max_N) := [others => 0.0];
      X   : Vector (1 .. Max_N) := [others => 0.0];
      T0  : constant Float := R (LoR);
   begin
      Res.N := N;

      if abs (T0) <= Pivot_Tol then
         Res.Stat := Degenerate;
         Res.Success := False;
         Res.Order := 1;
         return Res;
      end if;

      --  Order 1: F = [1/t_0], X = y_1 · F.
      F (1) := 1.0 / T0;
      X (1) := Y (LoY) * F (1);

      for M in 1 .. N - 1 loop
         declare
            Eps_F : Float := 0.0;
            Denom : Float;
            Alpha : Float;
            Eps_X : Float;
         begin
            --  ε_f from extending F with a trailing zero.
            for J in 1 .. M loop
               Eps_F := Eps_F + R (LoR + (M + 1 - J)) * F (J);
            end loop;

            Denom := 1.0 - Eps_F * Eps_F;
            if abs (Denom) <= Pivot_Tol then
               Res.Stat := Degenerate;
               Res.Success := False;
               Res.Order := Dim_Index (M + 1);
               return Res;
            end if;

            Alpha := 1.0 / Denom;

            --  F_new = α ( [F;0] − ε_f [0; reverse(F)] )
            declare
               F_Old : constant Vector (1 .. M) := F (1 .. M);
               F_New : Vector (1 .. M + 1);
            begin
               for I in 1 .. M + 1 loop
                  declare
                     Ext_F : constant Float :=
                       (if I <= M then F_Old (I) else 0.0);
                     Ext_B : constant Float :=
                       (if I = 1 then 0.0 else F_Old (M + 2 - I));
                  begin
                     F_New (I) := Alpha * (Ext_F - Eps_F * Ext_B);
                  end;
               end loop;
               F (1 .. M + 1) := F_New;

               --  ε_x residual of last equation with X padded by 0.
               Eps_X := Y (LoY + M);
               for J in 1 .. M loop
                  Eps_X := Eps_X - R (LoR + (M + 1 - J)) * X (J);
               end loop;

               --  X_new = [X;0] + ε_x · reverse(F_new)
               for I in 1 .. M + 1 loop
                  declare
                     Ext_X : constant Float :=
                       (if I <= M then X (I) else 0.0);
                     B_I   : constant Float := F_New (M + 2 - I);
                  begin
                     X (I) := Ext_X + Eps_X * B_I;
                  end;
               end loop;
            end;
         end;
      end loop;

      Res.X (1 .. N) := X (1 .. N);
      Res.Stat := Ok;
      Res.Success := True;
      Res.Order := 1;
      return Res;
   end Solve_Levinson;

   function Solve
     (R : Toeplitz_Row; Y : Vector) return Result
   is
   begin
      return Solve_Levinson (R, Y);
   end Solve;

   -------------------------------------------------------------------------
   -- Durbin Yule–Walker
   -------------------------------------------------------------------------

   function Durbin_Yule_Walker
     (R : Toeplitz_Row) return Durbin_Result
   is
      --  R length P+1 → solve P×P system for a_1..a_P.
      P   : constant Positive := R'Length - 1;
      LoR : constant Positive := R'First;
      Res : Durbin_Result;
      A   : Vector (1 .. Max_N) := [others => 0.0];
      K   : Vector (1 .. Max_N) := [others => 0.0];
      E   : Float := R (LoR);
   begin
      Res.P := P;

      if abs (E) <= Pivot_Tol then
         Res.Stat := Degenerate;
         Res.Success := False;
         Res.Order := 1;
         return Res;
      end if;

      for M in 1 .. P loop
         declare
            Acc : Float := R (LoR + M);
            Km  : Float;
         begin
            for J in 1 .. M - 1 loop
               Acc := Acc + A (J) * R (LoR + (M - J));
            end loop;

            if abs (E) <= Pivot_Tol then
               Res.Stat := Degenerate;
               Res.Success := False;
               Res.Order := Dim_Index (M);
               return Res;
            end if;

            Km := -Acc / E;
            K (M) := Km;

            declare
               A_Old : constant Vector (1 .. M) := A (1 .. M);
            begin
               A (M) := Km;
               for J in 1 .. M - 1 loop
                  A (J) := A_Old (J) + Km * A_Old (M - J);
               end loop;
            end;

            E := E * (1.0 - Km * Km);

            if abs (E) <= Pivot_Tol and then M < P then
               Res.Stat := Degenerate;
               Res.Success := False;
               Res.Order := Dim_Index (M);
               Res.A (1 .. M) := A (1 .. M);
               Res.K (1 .. M) := K (1 .. M);
               Res.E := E;
               return Res;
            end if;
         end;
      end loop;

      Res.A (1 .. P) := A (1 .. P);
      Res.K (1 .. P) := K (1 .. P);
      Res.E := E;
      Res.Stat := Ok;
      Res.Success := True;
      Res.Order := 1;
      return Res;
   end Durbin_Yule_Walker;

   -------------------------------------------------------------------------
   -- Reflection coefficients (PARCOR) via Durbin of order N-1
   -------------------------------------------------------------------------

   function Reflection_Coefficients
     (R : Toeplitz_Row) return Reflection_Result
   is
      N   : constant Positive := R'Length;
      RR : Reflection_Result;
   begin
      if N = 1 then
         --  No reflection coefficients; E_0 = t_0.
         RR.N := 0;
         RR.E := R (R'First);
         if abs (RR.E) <= Pivot_Tol then
            RR.Stat := Degenerate;
            RR.Success := False;
            RR.Order := 1;
         else
            RR.Stat := Ok;
            RR.Success := True;
         end if;
         return RR;
      end if;

      --  Durbin on full R (lags 0..N-1) yields k_1..k_{N-1} and E_{N-1}.
      --  Input length for Durbin_Yule_Walker is P+1 with P = N-1, so R
      --  of length N is exactly right.
      declare
         D : constant Durbin_Result := Durbin_Yule_Walker (R);
      begin
         RR.N := D.P;
         RR.K (1 .. D.P) := D.K (1 .. D.P);
         RR.E := D.E;
         RR.Stat := D.Stat;
         RR.Success := D.Success;
         RR.Order := D.Order;
         return RR;
      end;
   end Reflection_Coefficients;

end Levinson_Recursion;
