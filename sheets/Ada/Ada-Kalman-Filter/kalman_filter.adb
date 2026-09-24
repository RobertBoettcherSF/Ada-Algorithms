--  Kalman_Filter body — discrete linear Gaussian KF (scalar + fixed vector).

pragma Ada_2022;

package body Kalman_Filter
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Near (A, B : Real; Tol : Real := Epsilon_Tol) return Boolean is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Identity (N : Dim_Count) return Matrix is
      R : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      if N = 0 then
         raise Invalid_Argument with "Identity: N must be >= 1";
      end if;
      for I in 1 .. N loop
         R (I, I) := 1.0;
      end loop;
      return R;
   end Identity;

   function Zero_Vector (N : Dim_Count) return Vector is
   begin
      if N = 0 then
         raise Invalid_Argument with "Zero_Vector: N must be >= 1";
      end if;
      return [1 .. N => 0.0];
   end Zero_Vector;

   function Zero_Matrix (Rows, Cols : Dim_Count) return Matrix is
   begin
      if Rows = 0 or else Cols = 0 then
         raise Invalid_Argument with "Zero_Matrix: dims must be >= 1";
      end if;
      return [1 .. Rows => [1 .. Cols => 0.0]];
   end Zero_Matrix;

   -------------------------------------------------------------------------
   -- Dense linear algebra
   -------------------------------------------------------------------------

   function Transpose (A : Matrix) return Matrix is
      R : Matrix (A'Range (2), A'Range (1));
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            R (J, I) := A (I, J);
         end loop;
      end loop;
      return R;
   end Transpose;

   function "+" (A, B : Matrix) return Matrix is
      R : Matrix (A'Range (1), A'Range (2));
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            R (I, J) := A (I, J) + B (I, J);
         end loop;
      end loop;
      return R;
   end "+";

   function "-" (A, B : Matrix) return Matrix is
      R : Matrix (A'Range (1), A'Range (2));
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            R (I, J) := A (I, J) - B (I, J);
         end loop;
      end loop;
      return R;
   end "-";

   function "*" (A, B : Matrix) return Matrix is
      R : Matrix (A'Range (1), B'Range (2)) :=
        [others => [others => 0.0]];
   begin
      for I in A'Range (1) loop
         for J in B'Range (2) loop
            declare
               Acc : Real := 0.0;
            begin
               for K in A'Range (2) loop
                  Acc := Acc + A (I, K) * B (K, J);
               end loop;
               R (I, J) := Acc;
            end;
         end loop;
      end loop;
      return R;
   end "*";

   function "*" (A : Matrix; V : Vector) return Vector is
      R : Vector (A'Range (1)) := [others => 0.0];
   begin
      for I in A'Range (1) loop
         declare
            Acc : Real := 0.0;
         begin
            for J in V'Range loop
               Acc := Acc + A (I, J) * V (J);
            end loop;
            R (I) := Acc;
         end;
      end loop;
      return R;
   end "*";

   function "+" (U, V : Vector) return Vector is
      R : Vector (U'Range);
   begin
      for I in U'Range loop
         R (I) := U (I) + V (I);
      end loop;
      return R;
   end "+";

   function "-" (U, V : Vector) return Vector is
      R : Vector (U'Range);
   begin
      for I in U'Range loop
         R (I) := U (I) - V (I);
      end loop;
      return R;
   end "-";

   function Scale (A : Matrix; S : Real) return Matrix is
      R : Matrix (A'Range (1), A'Range (2));
   begin
      for I in A'Range (1) loop
         for J in A'Range (2) loop
            R (I, J) := A (I, J) * S;
         end loop;
      end loop;
      return R;
   end Scale;

   function Scale (V : Vector; S : Real) return Vector is
      R : Vector (V'Range);
   begin
      for I in V'Range loop
         R (I) := V (I) * S;
      end loop;
      return R;
   end Scale;

   function Solve (S, B : Matrix) return Matrix is
      N_Nat     : constant Natural := S'Length (1);
      N_RHS_Nat : constant Natural := B'Length (2);
   begin
      if N_Nat = 0 or else N_RHS_Nat = 0 then
         raise Invalid_Argument with "Solve: empty system";
      end if;
      if N_Nat > Max_Dim or else N_RHS_Nat > Max_Dim then
         raise Capacity_Exceeded with "Solve: dimension > Max_Dim";
      end if;

      declare
         N     : constant Dim_Count := N_Nat;
         N_RHS : constant Dim_Count := N_RHS_Nat;
         A : array (1 .. N, 1 .. N) of Real;
         X : array (1 .. N, 1 .. N_RHS) of Real;
         Result : Matrix (1 .. N, 1 .. N_RHS);
         Pivot_Row : Integer;
         Max_Abs   : Real;
         Tmp       : Real;
         Fac       : Real;
      begin
         for I in 1 .. N loop
            for J in 1 .. N loop
               A (I, J) := S (S'First (1) + I - 1, S'First (2) + J - 1);
            end loop;
            for J in 1 .. N_RHS loop
               X (I, J) := B (B'First (1) + I - 1, B'First (2) + J - 1);
            end loop;
         end loop;

         --  Forward elimination with partial pivoting.
         for Col in 1 .. N loop
            Pivot_Row := Col;
            Max_Abs := abs (A (Col, Col));
            for Row in Col + 1 .. N loop
               if abs (A (Row, Col)) > Max_Abs then
                  Max_Abs := abs (A (Row, Col));
                  Pivot_Row := Row;
               end if;
            end loop;

            if Max_Abs < Singularity_Tol then
               raise Degenerate_Geometry with "Solve: singular matrix";
            end if;

            if Pivot_Row /= Col then
               for J in Col .. N loop
                  Tmp := A (Col, J);
                  A (Col, J) := A (Pivot_Row, J);
                  A (Pivot_Row, J) := Tmp;
               end loop;
               for J in 1 .. N_RHS loop
                  Tmp := X (Col, J);
                  X (Col, J) := X (Pivot_Row, J);
                  X (Pivot_Row, J) := Tmp;
               end loop;
            end if;

            for Row in Col + 1 .. N loop
               Fac := A (Row, Col) / A (Col, Col);
               A (Row, Col) := 0.0;
               for J in Col + 1 .. N loop
                  A (Row, J) := A (Row, J) - Fac * A (Col, J);
               end loop;
               for J in 1 .. N_RHS loop
                  X (Row, J) := X (Row, J) - Fac * X (Col, J);
               end loop;
            end loop;
         end loop;

         --  Back substitution.
         for Col in reverse 1 .. N loop
            if abs (A (Col, Col)) < Singularity_Tol then
               raise Degenerate_Geometry with "Solve: singular on back-sub";
            end if;
            for J in 1 .. N_RHS loop
               Tmp := X (Col, J);
               for K in Col + 1 .. N loop
                  Tmp := Tmp - A (Col, K) * X (K, J);
               end loop;
               X (Col, J) := Tmp / A (Col, Col);
            end loop;
         end loop;

         for I in 1 .. N loop
            for J in 1 .. N_RHS loop
               Result (I, J) := X (I, J);
            end loop;
         end loop;
         return Result;
      end;
   end Solve;

   function Invert (S : Matrix) return Matrix is
      N_Nat : constant Natural := S'Length (1);
   begin
      if N_Nat = 0 then
         raise Invalid_Argument with "Invert: empty matrix";
      end if;
      if N_Nat > Max_Dim then
         raise Capacity_Exceeded with "Invert: dimension > Max_Dim";
      end if;
      return Solve (S, Identity (Dim_Count (N_Nat)));
   end Invert;

   -------------------------------------------------------------------------
   -- Scalar KF
   -------------------------------------------------------------------------

   procedure Scalar_Predict
     (State : in out Scalar_State;
      F     : Real;
      B     : Real;
      U     : Real;
      Q     : Real)
   is
   begin
      if Q < 0.0 then
         raise Invalid_Argument with "Scalar_Predict: Q must be >= 0";
      end if;
      State.X := F * State.X + B * U;
      State.P := F * F * State.P + Q;
   end Scalar_Predict;

   procedure Scalar_Update
     (State      : in out Scalar_State;
      Z          : Real;
      H          : Real;
      R          : Real;
      Innovation : out Real;
      Gain       : out Real)
   is
      S_Cov : Real;
      K     : Real;
      IKH   : Real;
   begin
      if R < 0.0 then
         raise Invalid_Argument with "Scalar_Update: R must be >= 0";
      end if;

      Innovation := Z - H * State.X;
      S_Cov := H * H * State.P + R;

      if abs (S_Cov) < Singularity_Tol then
         raise Degenerate_Geometry
           with "Scalar_Update: singular innovation covariance S";
      end if;

      K := State.P * H / S_Cov;
      Gain := K;
      State.X := State.X + K * Innovation;

      --  Joseph form: P ← (1 − K H)² P + K² R
      IKH := 1.0 - K * H;
      State.P := IKH * IKH * State.P + K * K * R;
   end Scalar_Update;

   procedure Scalar_Step
     (State      : in out Scalar_State;
      F, B, U, Q : Real;
      Z, H, R    : Real;
      Innovation : out Real;
      Gain       : out Real)
   is
   begin
      Scalar_Predict (State, F, B, U, Q);
      Scalar_Update (State, Z, H, R, Innovation, Gain);
   end Scalar_Step;

   -------------------------------------------------------------------------
   -- Vector KF
   -------------------------------------------------------------------------

   procedure Predict
     (State : in out Filter_State;
      F     : Matrix;
      Q     : Matrix;
      B     : Matrix;
      U     : Vector;
      Use_B : Boolean := False)
   is
      FT : constant Matrix := Transpose (F);
   begin
      if State.N = 0 then
         raise Invalid_Argument with "Predict: empty state";
      end if;
      if F'Length (1) /= State.N or else F'Length (2) /= State.N
        or else Q'Length (1) /= State.N or else Q'Length (2) /= State.N
      then
         raise Invalid_Argument with "Predict: F/Q dimension mismatch";
      end if;

      if Use_B then
         if B'Length (1) /= State.N
           or else U'Length = 0
           or else B'Length (2) /= U'Length
         then
            raise Invalid_Argument with "Predict: B/U dimension mismatch";
         end if;
         if B'Length (2) > Max_Dim then
            raise Capacity_Exceeded with "Predict: control dim > Max_Dim";
         end if;
         State.X := F * State.X + B * U;
      else
         State.X := F * State.X;
      end if;

      State.P := F * State.P * FT + Q;
   end Predict;

   procedure Predict
     (State : in out Filter_State;
      F     : Matrix;
      Q     : Matrix)
   is
      Dummy_B : constant Matrix (1 .. 1, 1 .. 1) :=
        [others => [others => 0.0]];
      Dummy_U : Vector (1 .. 0);
   begin
      Predict (State, F, Q, Dummy_B, Dummy_U, Use_B => False);
   end Predict;

   procedure Update
     (State      : in out Filter_State;
      Z          : Vector;
      H          : Matrix;
      R          : Matrix;
      Innovation : out Vector;
      Gain       : out Matrix)
   is
      M_Nat : constant Natural := Z'Length;
      N     : constant Dim_Count := State.N;
   begin
      if N = 0 or else M_Nat = 0 then
         raise Invalid_Argument with "Update: empty dimensions";
      end if;
      if M_Nat > Max_Dim then
         raise Capacity_Exceeded with "Update: measurement dim > Max_Dim";
      end if;
      if H'Length (1) /= M_Nat or else H'Length (2) /= N
        or else R'Length (1) /= M_Nat or else R'Length (2) /= M_Nat
      then
         raise Invalid_Argument with "Update: H/R dimension mismatch";
      end if;

      declare
         M    : constant Dim_Count := M_Nat;
         Hw   : Matrix (1 .. M, 1 .. N);
         Rw   : Matrix (1 .. M, 1 .. M);
         HT   : Matrix (1 .. N, 1 .. M);
         S    : Matrix (1 .. M, 1 .. M);
         PHt  : Matrix (1 .. N, 1 .. M);
         K    : Matrix (1 .. N, 1 .. M);
         IKH  : Matrix (1 .. N, 1 .. N);
         IKH_T : Matrix (1 .. N, 1 .. N);
         Eye  : constant Matrix := Identity (N);
         Pred_Z : Vector (1 .. M);
         Y    : Vector (1 .. M);
      begin
         for I in 1 .. M loop
            for J in 1 .. N loop
               Hw (I, J) := H (H'First (1) + I - 1, H'First (2) + J - 1);
            end loop;
         end loop;
         for I in 1 .. M loop
            for J in 1 .. M loop
               Rw (I, J) := R (R'First (1) + I - 1, R'First (2) + J - 1);
            end loop;
         end loop;

         HT := Transpose (Hw);
         Pred_Z := Hw * State.X;
         for I in 1 .. M loop
            Y (I) := Z (Z'First + I - 1) - Pred_Z (I);
         end loop;
         Innovation := Y;

         PHt := State.P * HT;
         S := Hw * PHt + Rw;
         K := PHt * Invert (S);
         Gain := K;

         State.X := State.X + K * Innovation;

         --  Joseph: P ← (I − K H) P (I − K H)ᵀ + K R Kᵀ
         IKH := Eye - K * Hw;
         IKH_T := Transpose (IKH);
         State.P := IKH * State.P * IKH_T + K * Rw * Transpose (K);
      end;
   end Update;

   procedure Filter_Step
     (State      : in out Filter_State;
      Mdl        : Model;
      Z          : Vector;
      U          : Vector;
      Innovation : out Vector;
      Gain       : out Matrix)
   is
   begin
      if State.N /= Mdl.N then
         raise Invalid_Argument with "Filter_Step: state/model N mismatch";
      end if;
      if Z'Length /= Mdl.M then
         raise Invalid_Argument with "Filter_Step: z/model M mismatch";
      end if;

      if Mdl.Has_Control then
         if U'Length = 0 then
            raise Invalid_Argument
              with "Filter_Step: control model needs U";
         end if;
         Predict (State, Mdl.F, Mdl.Q, Mdl.B, U, Use_B => True);
      else
         Predict (State, Mdl.F, Mdl.Q);
      end if;

      Update (State, Z, Mdl.H, Mdl.R, Innovation, Gain);
   end Filter_Step;

   procedure Filter_Step
     (State      : in out Filter_State;
      Mdl        : Model;
      Z          : Vector;
      Innovation : out Vector;
      Gain       : out Matrix)
   is
      Empty_U : Vector (1 .. 0);
   begin
      if Mdl.Has_Control then
         raise Invalid_Argument
           with "Filter_Step: model has control; supply U";
      end if;
      Filter_Step (State, Mdl, Z, Empty_U, Innovation, Gain);
   end Filter_Step;

end Kalman_Filter;
