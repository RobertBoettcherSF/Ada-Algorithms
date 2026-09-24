--  Partial_Least_Squares body — PLS1 + PLS2 NIPALS educational kernels.

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;

package body Partial_Least_Squares
  with SPARK_Mode => Off
is

   package EF renames Ada.Numerics.Long_Elementary_Functions;

   function Sqrt_R (X : Real) return Real is
   begin
      if X <= 0.0 then
         return 0.0;
      end if;
      return Real (EF.Sqrt (Long_Float (X)));
   end Sqrt_R;

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Dot (A, B : Vector) return Real is
      S : Real := 0.0;
   begin
      for I in A'Range loop
         S := S + A (I) * B (I);
      end loop;
      return S;
   end Dot;

   function Norm2 (V : Vector) return Non_Negative is
      S : Real := 0.0;
   begin
      for I in V'Range loop
         S := S + V (I) * V (I);
      end loop;
      return Sqrt_R (S);
   end Norm2;

   procedure Scale (V : in out Vector; Alpha : Real) is
   begin
      for I in V'Range loop
         V (I) := Alpha * V (I);
      end loop;
   end Scale;

   procedure Axpy (Y : in out Vector; Alpha : Real; X : Vector) is
   begin
      for I in Y'Range loop
         Y (I) := Y (I) + Alpha * X (I);
      end loop;
   end Axpy;

   procedure Outer_Add
     (Out_M : in out Matrix;
      Alpha : Real;
      U     : Vector;
      V     : Vector)
   is
   begin
      for I in U'Range loop
         for J in V'Range loop
            Out_M (I, J) := Out_M (I, J) + Alpha * U (I) * V (J);
         end loop;
      end loop;
   end Outer_Add;

   procedure Mat_Vec (A : Matrix; X : Vector; Y : out Vector) is
      S : Real;
   begin
      for I in A'Range (1) loop
         S := 0.0;
         for J in A'Range (2) loop
            S := S + A (I, J) * X (J);
         end loop;
         Y (I) := S;
      end loop;
   end Mat_Vec;

   procedure Mat_T_Vec (A : Matrix; X : Vector; Y : out Vector) is
      S : Real;
   begin
      for J in A'Range (2) loop
         S := 0.0;
         for I in A'Range (1) loop
            S := S + A (I, J) * X (I);
         end loop;
         Y (J) := S;
      end loop;
   end Mat_T_Vec;

   procedure Column_Means (A : Matrix; Means : out Vector) is
      N : constant Real := Real (A'Length (1));
      S : Real;
   begin
      for J in A'Range (2) loop
         S := 0.0;
         for I in A'Range (1) loop
            S := S + A (I, J);
         end loop;
         Means (J) := S / N;
      end loop;
   end Column_Means;

   procedure Mean_Center_Columns (A : in out Matrix; Means : Vector) is
   begin
      for J in A'Range (2) loop
         for I in A'Range (1) loop
            A (I, J) := A (I, J) - Means (J);
         end loop;
      end loop;
   end Mean_Center_Columns;

   procedure Standardize_Columns
     (A : in out Matrix; Means : Vector; Stds : out Vector)
   is
      N    : constant Real := Real (A'Length (1));
      Acc  : Real;
      Sdev : Real;
   begin
      for J in A'Range (2) loop
         Acc := 0.0;
         for I in A'Range (1) loop
            Acc := Acc + (A (I, J) - Means (J)) ** 2;
         end loop;
         Sdev := Sqrt_R (Acc / N);
         Stds (J) := Sdev;
         if Sdev > Singularity then
            for I in A'Range (1) loop
               A (I, J) := (A (I, J) - Means (J)) / Sdev;
            end loop;
         else
            for I in A'Range (1) loop
               A (I, J) := 0.0;
            end loop;
         end if;
      end loop;
   end Standardize_Columns;

   procedure Solve_Dense (A : in out Square; Q : Vector; Z : out Vector) is
      N     : constant Component_Index := A'Last (1);
      First : constant Component_Index := A'First (1);
      Pivot : Component_Index;
      Big   : Real;
      Tmp   : Real;
      Fac   : Real;
      RHS   : Vector (First .. N);
   begin
      for I in First .. N loop
         RHS (I) := Q (I);
      end loop;

      --  Forward elimination with partial pivoting.
      for K in First .. N loop
         Pivot := K;
         Big := abs (A (K, K));
         for I in K + 1 .. N loop
            if abs (A (I, K)) > Big then
               Big := abs (A (I, K));
               Pivot := I;
            end if;
         end loop;
         if Big < Singularity then
            raise Degenerate_Geometry with "singular P^T W in Solve_Dense";
         end if;
         if Pivot /= K then
            for J in First .. N loop
               Tmp := A (K, J);
               A (K, J) := A (Pivot, J);
               A (Pivot, J) := Tmp;
            end loop;
            Tmp := RHS (K);
            RHS (K) := RHS (Pivot);
            RHS (Pivot) := Tmp;
         end if;
         for I in K + 1 .. N loop
            Fac := A (I, K) / A (K, K);
            A (I, K) := 0.0;
            for J in K + 1 .. N loop
               A (I, J) := A (I, J) - Fac * A (K, J);
            end loop;
            RHS (I) := RHS (I) - Fac * RHS (K);
         end loop;
      end loop;

      --  Back substitution (pre-clear Z so J>I reads are defined at I=N).
      for I in First .. N loop
         Z (I) := 0.0;
      end loop;
      for I in reverse First .. N loop
         Tmp := RHS (I);
         for J in I + 1 .. N loop
            Tmp := Tmp - A (I, J) * Z (J);
         end loop;
         if abs (A (I, I)) < Singularity then
            raise Degenerate_Geometry with "singular diagonal in Solve_Dense";
         end if;
         Z (I) := Tmp / A (I, I);
      end loop;
   end Solve_Dense;

   function Ordinary_Least_Squares_1D (X, Y : Vector) return Real is
      N     : constant Real := Real (X'Length);
      Mx, My, Acc_XX, Acc_XY : Real := 0.0;
   begin
      for I in X'Range loop
         Mx := Mx + X (I);
         My := My + Y (I);
      end loop;
      Mx := Mx / N;
      My := My / N;
      for I in X'Range loop
         Acc_XX := Acc_XX + (X (I) - Mx) ** 2;
         Acc_XY := Acc_XY + (X (I) - Mx) * (Y (I) - My);
      end loop;
      if Acc_XX < Singularity then
         raise Degenerate_Geometry with "OLS_1D: zero predictor variance";
      end if;
      return Acc_XY / Acc_XX;
   end Ordinary_Least_Squares_1D;

   function R_Squared (Y_True, Y_Hat : Vector) return Real is
      N     : constant Real := Real (Y_True'Length);
      Mean  : Real := 0.0;
      SS_Tot, SS_Res : Real := 0.0;
   begin
      for I in Y_True'Range loop
         Mean := Mean + Y_True (I);
      end loop;
      Mean := Mean / N;
      for I in Y_True'Range loop
         SS_Tot := SS_Tot + (Y_True (I) - Mean) ** 2;
         SS_Res := SS_Res + (Y_True (I) - Y_Hat (I)) ** 2;
      end loop;
      if SS_Tot < Singularity then
         if SS_Res < Singularity then
            return 1.0;
         else
            return 0.0;
         end if;
      end if;
      return 1.0 - SS_Res / SS_Tot;
   end R_Squared;

   function RMSE (Y_True, Y_Hat : Vector) return Non_Negative is
      Acc : Real := 0.0;
      N   : constant Real := Real (Y_True'Length);
   begin
      for I in Y_True'Range loop
         Acc := Acc + (Y_True (I) - Y_Hat (I)) ** 2;
      end loop;
      return Sqrt_R (Acc / N);
   end RMSE;

   -------------------------------------------------------------------------
   -- Internal: form B = W (P^T W)^{-1} q  for PLS1
   -------------------------------------------------------------------------

   procedure Form_B_PLS1
     (W_Mat, P_Mat : Matrix;
      Q_Vec        : Vector;
      N_Comp       : Component_Count;
      N_Vars       : Col_Count;
      B_Out        : out Vector)
   is
      PTW   : Square (1 .. N_Comp, 1 .. N_Comp);
      Z     : Vector (1 .. N_Comp);
      Q_Sub : Vector (1 .. N_Comp);
      S     : Real;
   begin
      if N_Comp = 0 then
         for J in 1 .. N_Vars loop
            B_Out (J) := 0.0;
         end loop;
         return;
      end if;

      --  PTW (a,b) = P(:,a) · W(:,b)
      for A in 1 .. N_Comp loop
         for B in 1 .. N_Comp loop
            S := 0.0;
            for I in 1 .. N_Vars loop
               S := S + P_Mat (I, A) * W_Mat (I, B);
            end loop;
            PTW (A, B) := S;
         end loop;
         Q_Sub (A) := Q_Vec (A);
      end loop;

      Solve_Dense (PTW, Q_Sub, Z);

      --  B = W * Z
      for I in 1 .. N_Vars loop
         S := 0.0;
         for K in 1 .. N_Comp loop
            S := S + W_Mat (I, K) * Z (K);
         end loop;
         B_Out (I) := S;
      end loop;
      for I in N_Vars + 1 .. B_Out'Last loop
         B_Out (I) := 0.0;
      end loop;
   end Form_B_PLS1;

   -------------------------------------------------------------------------
   -- PLS1
   -------------------------------------------------------------------------

   function PLS1_Fit
     (X            : Matrix;
      Y            : Vector;
      N_Components : Positive;
      Center       : Boolean := True) return PLS1_Model
   is
      N : constant Row_Count := X'Length (1);
      M : constant Col_Count := X'Length (2);
      R0 : constant Row_Index := X'First (1);
      C0 : constant Col_Index := X'First (2);

      XW : Matrix (1 .. N, 1 .. M);
      YW : Vector (1 .. N);
      Wk : Vector (1 .. M);
      Tk : Vector (1 .. N);
      Pk : Vector (1 .. M);
      Model : PLS1_Model;
      Max_K : Component_Count;
      TT, Qk, Nw : Real;
      K_Done : Component_Count := 0;
   begin
      if Y'Length /= N then
         raise Invalid_Argument with "PLS1_Fit: Y length mismatch";
      end if;

      --  Copy into 1-based working buffers.
      for I in 1 .. N loop
         for J in 1 .. M loop
            XW (I, J) := X (R0 + I - 1, C0 + J - 1);
         end loop;
         YW (I) := Y (Y'First + I - 1);
      end loop;

      Model.N_Rows := N;
      Model.N_Cols := M;
      Model.Centered := Center;

      if Center then
         declare
            XM : Vector (1 .. M);
            YS : Real := 0.0;
         begin
            Column_Means (XW, XM);
            for J in 1 .. M loop
               Model.X_Mean (J) := XM (J);
            end loop;
            Mean_Center_Columns (XW, XM);
            for I in 1 .. N loop
               YS := YS + YW (I);
            end loop;
            Model.Y_Mean := YS / Real (N);
            for I in 1 .. N loop
               YW (I) := YW (I) - Model.Y_Mean;
            end loop;
         end;
      end if;

      declare
         Cap : Natural := Natural'Min (Natural (N), Natural (M));
      begin
         Cap := Natural'Min (Cap, Max_Components);
         Cap := Natural'Min (Cap, Natural (N_Components));
         Max_K := Component_Count (Cap);
      end;

      for K in 1 .. Max_K loop
         --  w ∝ X^T y
         Mat_T_Vec (XW, YW, Wk);
         Nw := Norm2 (Wk);
         if Nw < Cov_Stop_Tol then
            exit;
         end if;
         Scale (Wk, 1.0 / Nw);

         --  t = X w
         Mat_Vec (XW, Wk, Tk);
         TT := Dot (Tk, Tk);
         if TT < Cov_Stop_Tol then
            exit;
         end if;

         --  p = X^T t / (t^T t);  q = y^T t / (t^T t)
         Mat_T_Vec (XW, Tk, Pk);
         Scale (Pk, 1.0 / TT);
         Qk := Dot (YW, Tk) / TT;
         if abs (Qk) < Cov_Stop_Tol then
            exit;
         end if;

         --  Store column K
         for J in 1 .. M loop
            Model.W (J, K) := Wk (J);
            Model.P (J, K) := Pk (J);
         end loop;
         for I in 1 .. N loop
            Model.T (I, K) := Tk (I);
         end loop;
         Model.Q (K) := Qk;
         K_Done := K;

         --  Deflate X := X - t p^T ; y := y - t q
         Outer_Add (XW, -1.0, Tk, Pk);
         for I in 1 .. N loop
            YW (I) := YW (I) - Tk (I) * Qk;
         end loop;
      end loop;

      Model.N_Components := K_Done;

      declare
         B_Full : Vector (1 .. Max_Cols) := [others => 0.0];
         Acc    : Real;
      begin
         Form_B_PLS1
           (Model.W, Model.P, Model.Q, K_Done, M, B_Full);
         for J in 1 .. M loop
            Model.B (J) := B_Full (J);
         end loop;
         if Center then
            Acc := Model.Y_Mean;
            for J in 1 .. M loop
               Acc := Acc - Model.X_Mean (J) * Model.B (J);
            end loop;
            Model.B0 := Acc;
         else
            Model.B0 := 0.0;
         end if;
      end;

      return Model;
   end PLS1_Fit;

   function PLS1_Predict (Model : PLS1_Model; X_New : Matrix) return Vector is
      N  : constant Row_Count := X_New'Length (1);
      M  : constant Col_Count := Model.N_Cols;
      R0 : constant Row_Index := X_New'First (1);
      C0 : constant Col_Index := X_New'First (2);
      Yh : Vector (1 .. N);
      S  : Real;
      Xj : Real;
   begin
      if X_New'Length (2) /= M then
         raise Invalid_Argument with "PLS1_Predict: column mismatch";
      end if;

      for I in 1 .. N loop
         S := Model.B0;
         for J in 1 .. M loop
            Xj := X_New (R0 + I - 1, C0 + J - 1);
            S := S + Xj * Model.B (J);
         end loop;
         Yh (I) := S;
      end loop;
      return Yh;
   end PLS1_Predict;

   -------------------------------------------------------------------------
   -- PLS2 NIPALS
   -------------------------------------------------------------------------

   procedure Form_B_PLS2
     (W_Mat, P_Mat : Matrix;
      C_Mat        : Loading_Y_Matrix;
      N_Comp       : Component_Count;
      N_Vars       : Col_Count;
      N_Resp       : Response_Count;
      B_Out        : out Coef_Matrix)
   is
      PTW   : Square (1 .. N_Comp, 1 .. N_Comp);
      Z     : Vector (1 .. N_Comp);
      Q_Sub : Vector (1 .. N_Comp);
      S     : Real;
   begin
      for J in 1 .. N_Vars loop
         for R in 1 .. N_Resp loop
            B_Out (J, R) := 0.0;
         end loop;
      end loop;

      if N_Comp = 0 then
         return;
      end if;

      for A in 1 .. N_Comp loop
         for B in 1 .. N_Comp loop
            S := 0.0;
            for I in 1 .. N_Vars loop
               S := S + P_Mat (I, A) * W_Mat (I, B);
            end loop;
            PTW (A, B) := S;
         end loop;
      end loop;

      --  For each response r: solve (P^T W) z = C(r, :)^T ; B(:,r) = W z
      for R in 1 .. N_Resp loop
         declare
            PTW_Copy : Square (1 .. N_Comp, 1 .. N_Comp);
         begin
            for A in 1 .. N_Comp loop
               for B in 1 .. N_Comp loop
                  PTW_Copy (A, B) := PTW (A, B);
               end loop;
               Q_Sub (A) := C_Mat (R, A);
            end loop;
            Solve_Dense (PTW_Copy, Q_Sub, Z);
            for I in 1 .. N_Vars loop
               S := 0.0;
               for K in 1 .. N_Comp loop
                  S := S + W_Mat (I, K) * Z (K);
               end loop;
               B_Out (I, R) := S;
            end loop;
         end;
      end loop;
   end Form_B_PLS2;

   function PLS2_Fit
     (X            : Matrix;
      Y            : Y_Matrix;
      N_Components : Positive;
      Center       : Boolean := True;
      Max_Iter     : Positive := 100;
      Tol          : Real := 1.0E-8) return PLS2_Model
   is
      N : constant Row_Count := X'Length (1);
      M : constant Col_Count := X'Length (2);
      P : constant Response_Count := Y'Length (2);
      R0 : constant Row_Index := X'First (1);
      C0 : constant Col_Index := X'First (2);
      YR0 : constant Row_Index := Y'First (1);
      YC0 : constant Response_Index := Y'First (2);

      XW : Matrix (1 .. N, 1 .. M);
      YW : Y_Matrix (1 .. N, 1 .. P);
      Model : PLS2_Model;
      Max_K : Component_Count;
      K_Done : Component_Count := 0;

      Wk : Vector (1 .. M);
      Tk : Vector (1 .. N);
      Pk : Vector (1 .. M);
      Ck : Vector (1 .. P);
      Uk : Vector (1 .. N);
      U_Old : Vector (1 .. N);
      Nw, Nc, TT, Nu, Diff : Real;
   begin

      for I in 1 .. N loop
         for J in 1 .. M loop
            XW (I, J) := X (R0 + I - 1, C0 + J - 1);
         end loop;
         for R in 1 .. P loop
            YW (I, R) := Y (YR0 + I - 1, YC0 + R - 1);
         end loop;
      end loop;

      Model.N_Rows := N;
      Model.N_Cols := M;
      Model.N_Responses := P;
      Model.Centered := Center;

      if Center then
         declare
            XM : Vector (1 .. M);
            YM : Vector (1 .. P);
            S  : Real;
         begin
            Column_Means (XW, XM);
            for J in 1 .. M loop
               Model.X_Mean (J) := XM (J);
            end loop;
            Mean_Center_Columns (XW, XM);
            for R in 1 .. P loop
               S := 0.0;
               for I in 1 .. N loop
                  S := S + YW (I, R);
               end loop;
               YM (R) := S / Real (N);
               Model.Y_Mean (R) := YM (R);
               for I in 1 .. N loop
                  YW (I, R) := YW (I, R) - YM (R);
               end loop;
            end loop;
         end;
      end if;

      declare
         Cap : Natural := Natural'Min (Natural (N), Natural (M));
      begin
         Cap := Natural'Min (Cap, Max_Components);
         Cap := Natural'Min (Cap, Natural (N_Components));
         Max_K := Component_Count (Cap);
      end;

      for K in 1 .. Max_K loop
         --  Initialise u from first Y column (or residual).
         for I in 1 .. N loop
            Uk (I) := YW (I, 1);
         end loop;
         Nu := Norm2 (Uk);
         if Nu < Cov_Stop_Tol then
            --  Try another response column.
            declare
               Found : Boolean := False;
            begin
               for R in 2 .. P loop
                  for I in 1 .. N loop
                     Uk (I) := YW (I, R);
                  end loop;
                  Nu := Norm2 (Uk);
                  if Nu >= Cov_Stop_Tol then
                     Found := True;
                     exit;
                  end if;
               end loop;
               if not Found then
                  exit;
               end if;
            end;
         end if;

         --  NIPALS inner loop
         for Iter in 1 .. Max_Iter loop
            U_Old := Uk;

            --  w = X^T u / ||.||
            Mat_T_Vec (XW, Uk, Wk);
            Nw := Norm2 (Wk);
            if Nw < Cov_Stop_Tol then
               exit;
            end if;
            Scale (Wk, 1.0 / Nw);

            --  t = X w
            Mat_Vec (XW, Wk, Tk);

            --  c = Y^T t ; normalize
            for R in 1 .. P loop
               declare
                  S : Real := 0.0;
               begin
                  for I in 1 .. N loop
                     S := S + YW (I, R) * Tk (I);
                  end loop;
                  Ck (R) := S;
               end;
            end loop;
            Nc := Norm2 (Ck);
            if Nc < Cov_Stop_Tol then
               exit;
            end if;
            Scale (Ck, 1.0 / Nc);

            --  u = Y c
            for I in 1 .. N loop
               declare
                  S : Real := 0.0;
               begin
                  for R in 1 .. P loop
                     S := S + YW (I, R) * Ck (R);
                  end loop;
                  Uk (I) := S;
               end;
            end loop;

            Diff := 0.0;
            for I in 1 .. N loop
               Diff := Diff + (Uk (I) - U_Old (I)) ** 2;
            end loop;
            Diff := Sqrt_R (Diff);
            exit when Diff < Tol;
         end loop;

         Nw := Norm2 (Wk);
         if Nw < Cov_Stop_Tol then
            exit;
         end if;

         TT := Dot (Tk, Tk);
         if TT < Cov_Stop_Tol then
            exit;
         end if;

         --  p = X^T t / (t^T t); rescale c so Y ≈ t c^T with c = Y^T t / tt
         Mat_T_Vec (XW, Tk, Pk);
         Scale (Pk, 1.0 / TT);
         for R in 1 .. P loop
            declare
               S : Real := 0.0;
            begin
               for I in 1 .. N loop
                  S := S + YW (I, R) * Tk (I);
               end loop;
               Ck (R) := S / TT;
            end;
         end loop;

         --  Store
         for J in 1 .. M loop
            Model.W (J, K) := Wk (J);
            Model.P (J, K) := Pk (J);
         end loop;
         for R in 1 .. P loop
            Model.C (R, K) := Ck (R);
         end loop;
         K_Done := K;

         --  Deflate
         Outer_Add (XW, -1.0, Tk, Pk);
         for I in 1 .. N loop
            for R in 1 .. P loop
               YW (I, R) := YW (I, R) - Tk (I) * Ck (R);
            end loop;
         end loop;
      end loop;

      Model.N_Components := K_Done;

      declare
         B_Tmp : Coef_Matrix (1 .. M, 1 .. P);
         Acc   : Real;
      begin
         Form_B_PLS2
           (Model.W, Model.P, Model.C, K_Done, M, P, B_Tmp);
         for J in 1 .. M loop
            for R in 1 .. P loop
               Model.B (J, R) := B_Tmp (J, R);
            end loop;
         end loop;
         if Center then
            for R in 1 .. P loop
               Acc := Model.Y_Mean (R);
               for J in 1 .. M loop
                  Acc := Acc - Model.X_Mean (J) * Model.B (J, R);
               end loop;
               Model.B0 (R) := Acc;
            end loop;
         end if;
      end;

      return Model;
   end PLS2_Fit;

   function PLS2_Predict (Model : PLS2_Model; X_New : Matrix) return Y_Matrix is
      N  : constant Row_Count := X_New'Length (1);
      M  : constant Col_Count := Model.N_Cols;
      P  : constant Response_Count := Model.N_Responses;
      R0 : constant Row_Index := X_New'First (1);
      C0 : constant Col_Index := X_New'First (2);
      Yh : Y_Matrix (1 .. N, 1 .. P);
      S  : Real;
      Xj : Real;
   begin
      if X_New'Length (2) /= M then
         raise Invalid_Argument with "PLS2_Predict: column mismatch";
      end if;

      for I in 1 .. N loop
         for R in 1 .. P loop
            S := Model.B0 (R);
            for J in 1 .. M loop
               Xj := X_New (R0 + I - 1, C0 + J - 1);
               S := S + Xj * Model.B (J, R);
            end loop;
            Yh (I, R) := S;
         end loop;
      end loop;
      return Yh;
   end PLS2_Predict;

end Partial_Least_Squares;
