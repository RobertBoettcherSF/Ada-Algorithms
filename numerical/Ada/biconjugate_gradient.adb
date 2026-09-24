--  Biconjugate_Gradient body — classical unpreconditioned BiCG (real A).

pragma Ada_2022;

with Ada.Numerics.Elementary_Functions;

package body Biconjugate_Gradient is

   package Math renames Ada.Numerics.Elementary_Functions;

   -------------------------------------------------------------------------
   -- Numeric helpers
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

   function Dot (U, V : Vector) return Float is
      S : Float := 0.0;
      J : Positive := V'First;
   begin
      for I in U'Range loop
         S := S + U (I) * V (J);
         if J < V'Last then
            J := J + 1;
         end if;
      end loop;
      return S;
   end Dot;

   function Norm2 (V : Vector) return Float is
   begin
      return Math.Sqrt (Dot (V, V));
   end Norm2;

   function Scale (V : Vector; S : Float) return Vector is
      R : Vector (V'Range);
   begin
      for I in V'Range loop
         R (I) := S * V (I);
      end loop;
      return R;
   end Scale;

   function Add (U, V : Vector) return Vector is
      R : Vector (U'Range);
      J : Positive := V'First;
   begin
      for I in U'Range loop
         R (I) := U (I) + V (J);
         if J < V'Last then
            J := J + 1;
         end if;
      end loop;
      return R;
   end Add;

   function Sub (U, V : Vector) return Vector is
      R : Vector (U'Range);
      J : Positive := V'First;
   begin
      for I in U'Range loop
         R (I) := U (I) - V (J);
         if J < V'Last then
            J := J + 1;
         end if;
      end loop;
      return R;
   end Sub;

   function Mat_Vec (A : Matrix; X : Vector) return Vector is
      N : constant Positive := X'Length;
      Y : Vector (1 .. N) := [others => 0.0];
      Col : Positive;
   begin
      for I in 1 .. N loop
         declare
            Row : constant Positive := A'First (1) + I - 1;
            Acc : Float := 0.0;
         begin
            Col := A'First (2);
            for J in X'Range loop
               Acc := Acc + A (Row, Col) * X (J);
               if Col < A'Last (2) then
                  Col := Col + 1;
               end if;
            end loop;
            Y (I) := Acc;
         end;
      end loop;
      return Y;
   end Mat_Vec;

   function Mat_Vec_T (A : Matrix; X : Vector) return Vector is
      N : constant Positive := X'Length;
      Y : Vector (1 .. N) := [others => 0.0];
      Row : Positive;
   begin
      --  y_j = Σ_i A_ij x_i  ≡ (Aᵀ x)_j
      for J in 1 .. N loop
         declare
            Col : constant Positive := A'First (2) + J - 1;
            Acc : Float := 0.0;
         begin
            Row := A'First (1);
            for I in X'Range loop
               Acc := Acc + A (Row, Col) * X (I);
               if Row < A'Last (1) then
                  Row := Row + 1;
               end if;
            end loop;
            Y (J) := Acc;
         end;
      end loop;
      return Y;
   end Mat_Vec_T;

   function Transpose (A : Matrix) return Matrix is
      N : constant Natural := A'Length (1);
      T : Matrix (1 .. N, 1 .. N);
   begin
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            T (1 + I, 1 + J) :=
              A (A'First (1) + J, A'First (2) + I);
         end loop;
      end loop;
      return T;
   end Transpose;

   function Is_Symmetric
     (A : Matrix; Tol : Float := 1.0E-6) return Boolean
   is
      N : constant Natural := A'Length (1);
   begin
      for I in 0 .. N - 1 loop
         for J in 0 .. N - 1 loop
            declare
               RI : constant Positive := A'First (1) + I;
               RJ : constant Positive := A'First (1) + J;
               CI : constant Positive := A'First (2) + I;
               CJ : constant Positive := A'First (2) + J;
            begin
               if abs (A (RI, CJ) - A (RJ, CI)) > Tol then
                  return False;
               end if;
            end;
         end loop;
      end loop;
      return True;
   end Is_Symmetric;

   function Is_Diagonally_Dominant (A : Matrix) return Boolean is
      N : constant Natural := A'Length (1);
   begin
      for I in 0 .. N - 1 loop
         declare
            RI   : constant Positive := A'First (1) + I;
            Diag : constant Float := abs (A (RI, A'First (2) + I));
            Off  : Float := 0.0;
         begin
            for J in 0 .. N - 1 loop
               if J /= I then
                  Off := Off + abs (A (RI, A'First (2) + J));
               end if;
            end loop;
            if Diag < Off then
               return False;
            end if;
         end;
      end loop;
      return True;
   end Is_Diagonally_Dominant;

   function Residual (A : Matrix; X, B : Vector) return Vector is
   begin
      return Sub (B, Mat_Vec (A, X));
   end Residual;

   function Residual_Norm (A : Matrix; X, B : Vector) return Float is
   begin
      return Norm2 (Residual (A, X, B));
   end Residual_Norm;

   -------------------------------------------------------------------------
   -- Example generators
   -------------------------------------------------------------------------

   function Make_Example
     (Kind : Example_Kind; N : Dimension) return Matrix
   is
      A : Matrix (1 .. N, 1 .. N) := [others => [others => 0.0]];
   begin
      case Kind is
         when Nonsym_DD =>
            for I in 1 .. N loop
               for J in 1 .. N loop
                  if I = J then
                     A (I, J) := Float (N) + 2.0;
                  elsif J = I + 1 then
                     A (I, J) := 0.5;
                  elsif J = I - 1 then
                     A (I, J) := -0.3;
                  else
                     A (I, J) := 0.05;
                  end if;
               end loop;
            end loop;

         when Conv_Diff_1D =>
            declare
               C : constant Float := 0.4;
            begin
               for I in 1 .. N loop
                  A (I, I) := 2.0;
                  if I > 1 then
                     A (I, I - 1) := -1.0 - C;
                  end if;
                  if I < N then
                     A (I, I + 1) := -1.0 + C;
                  end if;
               end loop;
            end;

         when SPD_Poisson =>
            for I in 1 .. N loop
               A (I, I) := 2.0;
               if I > 1 then
                  A (I, I - 1) := -1.0;
               end if;
               if I < N then
                  A (I, I + 1) := -1.0;
               end if;
            end loop;

         when Fixed_2x2 =>
            A (1, 1) := 4.0;
            A (1, 2) := 1.0;
            A (2, 1) := 2.0;
            A (2, 2) := 3.0;

         when Fixed_3x3 =>
            A (1, 1) := 5.0;
            A (1, 2) := 1.0;
            A (1, 3) := 0.0;
            A (2, 1) := 2.0;
            A (2, 2) := 4.0;
            A (2, 3) := 1.0;
            A (3, 1) := 0.0;
            A (3, 2) := 1.0;
            A (3, 3) := 3.0;
      end case;
      return A;
   end Make_Example;

   function Make_RHS_Ones (N : Dimension) return Vector is
      B : constant Vector (1 .. N) := [others => 1.0];
   begin
      return B;
   end Make_RHS_Ones;

   function Zero_Vector (N : Dimension) return Vector is
      Z : constant Vector (1 .. N) := [others => 0.0];
   begin
      return Z;
   end Zero_Vector;

   -------------------------------------------------------------------------
   -- Pack result into fixed Max_N slots
   -------------------------------------------------------------------------

   function Pack
     (X_Sol : Vector;
      Iters : Natural;
      Res   : Float;
      St    : Status) return Result
   is
      R : Result;
      N : constant Dimension := X_Sol'Length;
   begin
      R.N := N;
      R.Iterations := Iters;
      R.Residual := Res;
      R.Stat := St;
      R.Success := St = Converged;
      for I in 1 .. N loop
         R.X (I) := X_Sol (X_Sol'First + I - 1);
      end loop;
      return R;
   end Pack;

   function Pack_Error (St : Status) return Result is
      R : Result;
   begin
      R.N := 0;
      R.Iterations := 0;
      R.Residual := 0.0;
      R.Stat := St;
      R.Success := False;
      return R;
   end Pack_Error;

   function Effective_Max_Iter (N : Dimension; Params : Parameters)
     return Natural
   is
   begin
      if Params.Max_Iter = 0 then
         return Natural (2 * N);
      else
         return Params.Max_Iter;
      end if;
   end Effective_Max_Iter;

   -------------------------------------------------------------------------
   -- Classical unpreconditioned BiCG (real matrices)
   -------------------------------------------------------------------------

   function Biconjugate_Gradient
     (A      : Matrix;
      B      : Vector;
      X0     : Vector;
      Params : Parameters := Default_Parameters) return Result
   is
      N : constant Positive := B'Length;
      X : Vector (1 .. N);
      R : Vector (1 .. N);
      R_Tilde : Vector (1 .. N);
      P : Vector (1 .. N);
      P_Tilde : Vector (1 .. N);
      Ap : Vector (1 .. N);
      Rho_Old, Rho_New, Alpha, Beta, P_Denom : Float;
      Limit : constant Natural := Effective_Max_Iter (N, Params);
   begin
      if N > Max_N or else A'Length (1) /= N or else A'Length (2) /= N
        or else X0'Length /= N
      then
         return Pack_Error (Dimension_Error);
      end if;

      for I in 1 .. N loop
         X (I) := X0 (X0'First + I - 1);
      end loop;

      R := Residual (A, X, B);
      --  Shadow residual: common choice r̃₀ = r₀.
      R_Tilde := R;
      Rho_Old := Dot (R_Tilde, R);

      declare
         R_Norm0 : constant Float := Norm2 (R);
         Abs_Tol : constant Float :=
           Float'Max (Params.Tol, Params.Tol * (1.0 + R_Norm0));
      begin
         if R_Norm0 <= Abs_Tol then
            return Pack (X, 0, R_Norm0, Converged);
         end if;

         if abs (Rho_Old) <= Epsilon_Tol * (1.0 + R_Norm0 * R_Norm0) then
            --  Cannot start BiCG (ρ₀ ≈ 0); accept only if already solved.
            return Pack (X, 0, R_Norm0, Breakdown);
         end if;

         P := R;
         P_Tilde := R_Tilde;

         for K in 1 .. Limit loop
            Ap := Mat_Vec (A, P);
            P_Denom := Dot (P_Tilde, Ap);

            if abs (P_Denom) <= Epsilon_Tol * (1.0 + abs (Rho_Old)) then
               declare
                  R_Norm : constant Float := Norm2 (R);
               begin
                  --  Soft landing: near-solution ρ/α breakdown → Converged.
                  if R_Norm <= Abs_Tol
                    or else R_Norm <= 1.0E-4 * (1.0 + R_Norm0)
                  then
                     return Pack (X, K - 1, R_Norm, Converged);
                  else
                     return Pack (X, K - 1, R_Norm, Breakdown);
                  end if;
               end;
            end if;

            Alpha := Rho_Old / P_Denom;
            X := Add (X, Scale (P, Alpha));
            R := Sub (R, Scale (Ap, Alpha));
            --  r̃ ← r̃ − α Aᵀ p̃
            R_Tilde :=
              Sub (R_Tilde, Scale (Mat_Vec_T (A, P_Tilde), Alpha));

            declare
               R_Norm : constant Float := Norm2 (R);
            begin
               if R_Norm <= Abs_Tol then
                  return Pack (X, K, R_Norm, Converged);
               end if;
            end;

            Rho_New := Dot (R_Tilde, R);
            if abs (Rho_Old) <= Epsilon_Tol
              or else abs (Rho_New) <= Epsilon_Tol * (1.0 + abs (Rho_Old))
            then
               declare
                  R_Norm : constant Float := Norm2 (R);
               begin
                  if R_Norm <= Abs_Tol
                    or else R_Norm <= 1.0E-4 * (1.0 + R_Norm0)
                  then
                     return Pack (X, K, R_Norm, Converged);
                  else
                     return Pack (X, K, R_Norm, Breakdown);
                  end if;
               end;
            end if;

            Beta := Rho_New / Rho_Old;
            P := Add (R, Scale (P, Beta));
            P_Tilde := Add (R_Tilde, Scale (P_Tilde, Beta));
            Rho_Old := Rho_New;
         end loop;

         declare
            R_Final : constant Float := Norm2 (R);
         begin
            if R_Final <= Abs_Tol then
               return Pack (X, Limit, R_Final, Converged);
            else
               return Pack (X, Limit, R_Final, Iteration_Limit);
            end if;
         end;
      end;
   end Biconjugate_Gradient;

   function Solve
     (A      : Matrix;
      B      : Vector;
      X0     : Vector := [1 .. 0 => 0.0];
      Params : Parameters := Default_Parameters) return Result
   is
      N : constant Positive := B'Length;
   begin
      if A'Length (1) /= N or else A'Length (2) /= N or else N > Max_N then
         return Pack_Error (Dimension_Error);
      end if;

      if X0'Length = 0 then
         return Biconjugate_Gradient (A, B, Zero_Vector (N), Params);
      elsif X0'Length /= N then
         return Pack_Error (Dimension_Error);
      else
         return Biconjugate_Gradient (A, B, X0, Params);
      end if;
   end Solve;

end Biconjugate_Gradient;
