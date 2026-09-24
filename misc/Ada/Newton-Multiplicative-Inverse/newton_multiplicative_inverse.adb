--  Newton_Multiplicative_Inverse body — NR reciprocal, divide, series inverse.

pragma Ada_2022;

package body Newton_Multiplicative_Inverse
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Helpers
   ---------------------------------------------------------------------------

   function Near
     (A, B : Long_Float; Tol : Long_Float := Near_Tol) return Boolean
   is
   begin
      return abs (A - B) <= Tol;
   end Near;

   function Abs_Error (A, B : Long_Float) return Long_Float is
   begin
      return abs (A - B);
   end Abs_Error;

   function Rel_Error (Approx, Exact : Long_Float) return Long_Float is
   begin
      if Exact = 0.0 then
         return abs (Approx);
      else
         return abs (Approx - Exact) / abs (Exact);
      end if;
   end Rel_Error;

   function Exact_Reciprocal (A : Long_Float) return Long_Float is
   begin
      if A = 0.0 then
         raise Invalid_Argument with
           "Exact_Reciprocal: A = 0 (no multiplicative inverse)";
      end if;
      return 1.0 / A;
   end Exact_Reciprocal;

   function Fail_Domain return Reciprocal_Result is
   begin
      return (Value => 0.0, Iterations => 0, Status => Bad_Domain);
   end Fail_Domain;

   ---------------------------------------------------------------------------
   -- Initial guess (dyadic scale + classic NR-division linear seed)
   ---------------------------------------------------------------------------

   --  Bring |A| into M ∈ [1/2, 1) so |A| = M · Two_Power, then seed
   --    Inv_M ≈ (48/17) − (32/17) M
   --  (standard educational NR-division approximant on [1/2, 1]), and
   --  return Sign(A) · Inv_M / Two_Power. Guarantees a starting point
   --  close enough for quadratic convergence on typical Long_Float args.
   function Initial_Guess (A : Long_Float) return Long_Float is
      Sign_A    : constant Long_Float :=
        (if A < 0.0 then -1.0 else 1.0);
      M         : Long_Float := abs (A);
      Two_Power : Long_Float := 1.0;
      Inv_M     : Long_Float;
      Guard     : Natural := 0;
   begin
      --  Scale into [0.5, 1).
      while M >= 1.0 and then Guard < 2048 loop
         M         := M * 0.5;
         Two_Power := Two_Power * 2.0;
         Guard     := Guard + 1;
      end loop;
      Guard := 0;
      while M < 0.5 and then M > 0.0 and then Guard < 2048 loop
         M         := M * 2.0;
         Two_Power := Two_Power * 0.5;
         Guard     := Guard + 1;
      end loop;

      --  Linear seed on [1/2, 1]: (48 − 32 M) / 17.
      Inv_M := (48.0 - 32.0 * M) / 17.0;
      if Inv_M <= 0.0 then
         Inv_M := 1.0;  -- defensive fallback (should not occur on [1/2,1])
      end if;

      return Sign_A * Inv_M / Two_Power;
   end Initial_Guess;

   ---------------------------------------------------------------------------
   -- Reciprocal Newton
   ---------------------------------------------------------------------------

   function Reciprocal_Newton
     (A        : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Reciprocal_Result
   is
      X      : Long_Float;
      X_Next : Long_Float;
      Rel    : Long_Float;
   begin
      if A = 0.0 then
         return Fail_Domain;
      end if;

      X := Initial_Guess (A);

      for Iter in 1 .. Max_Iter loop
         --  x ← x (2 − a x)  — two multiplies, one subtract.
         X_Next := X * (2.0 - A * X);
         Rel    := abs (X_Next - X);
         X      := X_Next;

         --  Prefer multiplicative residual |a x − 1|; also accept a
         --  relative step. Avoid bare absolute Rel ≤ Tol (too loose when
         --  |x| ≪ 1, i.e. large |a|).
         if abs (A * X - 1.0) <= Tol
           or else Rel <= Tol * abs (X)
         then
            return
              (Value      => X,
               Iterations => Iter,
               Status     => Converged);
         end if;
      end loop;

      return
        (Value      => X,
         Iterations => Max_Iter,
         Status     => Max_Iterations_Reached);
   end Reciprocal_Newton;

   function Reciprocal (A : Long_Float) return Long_Float is
      R : constant Reciprocal_Result := Reciprocal_Newton (A);
   begin
      if R.Status /= Converged then
         raise Invalid_Argument with
           "Reciprocal: A = 0 or failed to converge";
      end if;
      return R.Value;
   end Reciprocal;

   ---------------------------------------------------------------------------
   -- Division via reciprocal
   ---------------------------------------------------------------------------

   function Divide_Newton
     (B, A     : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Reciprocal_Result
   is
      R : Reciprocal_Result := Reciprocal_Newton (A, Tol, Max_Iter);
   begin
      if R.Status = Bad_Domain then
         return Fail_Domain;
      end if;
      R.Value := B * R.Value;
      return R;
   end Divide_Newton;

   function Divide (B, A : Long_Float) return Long_Float is
      R : constant Reciprocal_Result := Divide_Newton (B, A);
   begin
      if R.Status /= Converged then
         raise Invalid_Argument with
           "Divide: A = 0 or reciprocal failed to converge";
      end if;
      return R.Value;
   end Divide;

   ---------------------------------------------------------------------------
   -- Series helpers (truncated multiply / Newton lift)
   ---------------------------------------------------------------------------

   --  Truncated product R = trunc_Degree (U * V), both indexed from 0.
   procedure Trunc_Mul
     (U, V   : Series_Coeffs;
      Degree : Series_Index;
      R      : out Series_Coeffs)
   is
      Acc : Long_Float;
   begin
      for N in 0 .. Degree loop
         Acc := 0.0;
         for K in 0 .. N loop
            if K <= U'Last and then (N - K) <= V'Last then
               Acc := Acc + U (K) * V (N - K);
            end if;
         end loop;
         R (N) := Acc;
      end loop;
      for N in Degree + 1 .. R'Last loop
         R (N) := 0.0;
      end loop;
   end Trunc_Mul;

   function Series_Coeff_Near
     (U, V   : Series_Coeffs;
      Degree : Series_Index;
      Tol    : Long_Float) return Boolean
   is
   begin
      for N in 0 .. Degree loop
         if abs (U (N) - V (N)) > Tol
           and then abs (U (N) - V (N)) > Tol * (1.0 + abs (V (N)))
         then
            return False;
         end if;
      end loop;
      return True;
   end Series_Coeff_Near;

   function Series_Inverse_Newton
     (P        : Series_Coeffs;
      Degree   : Series_Index;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Series_Result
   is
      Q     : Series_Coeffs (Series_Index) := [others => 0.0];
      Q_New : Series_Coeffs (Series_Index) := [others => 0.0];
      Tmp   : Series_Coeffs (Series_Index) := [others => 0.0];
      Two_M : Series_Coeffs (Series_Index) := [others => 0.0];
      Prod  : Series_Coeffs (Series_Index) := [others => 0.0];
      Unit  : Series_Coeffs (Series_Index) := [others => 0.0];
      P_Use : Series_Coeffs (Series_Index) := [others => 0.0];
      Result : Series_Result;
   begin
      if P (0) = 0.0 then
         return Result;  -- Bad_Domain default
      end if;

      for N in 0 .. Degree loop
         P_Use (N) := P (N);
      end loop;

      --  q0 = 1/p0 (degree-0 seed).
      Q (0) := 1.0 / P_Use (0);
      Unit (0) := 1.0;

      for Iter in 1 .. Max_Iter loop
         --  Tmp = trunc (P · Q)
         Trunc_Mul (P_Use, Q, Degree, Tmp);
         --  Two_M = 2 − Tmp  (constant 2, then subtract series)
         Two_M := [others => 0.0];
         Two_M (0) := 2.0;
         for N in 0 .. Degree loop
            Two_M (N) := Two_M (N) - Tmp (N);
         end loop;
         --  Q_New = trunc (Q · Two_M)
         Trunc_Mul (Q, Two_M, Degree, Q_New);

         Q := Q_New;

         --  Check trunc (P · Q) ≈ 1.
         Trunc_Mul (P_Use, Q, Degree, Prod);
         if Series_Coeff_Near (Prod, Unit, Degree, Tol) then
            Result.Coeffs     := Q;
            Result.Degree     := Degree;
            Result.Iterations := Iter;
            Result.Status     := Converged;
            return Result;
         end if;
      end loop;

      Result.Coeffs     := Q;
      Result.Degree     := Degree;
      Result.Iterations := Max_Iter;
      Result.Status     := Max_Iterations_Reached;
      return Result;
   end Series_Inverse_Newton;

end Newton_Multiplicative_Inverse;
