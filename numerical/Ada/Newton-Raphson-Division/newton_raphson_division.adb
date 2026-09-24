--  Newton_Raphson_Division body — NR reciprocal, Divide_NR, Integer wrappers.

pragma Ada_2022;

package body Newton_Raphson_Division
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

   function Fail_Reciprocal return Reciprocal_Result is
   begin
      return (Value => 0.0, Iterations => 0, Status => Bad_Domain);
   end Fail_Reciprocal;

   function Fail_Division return Division_Result is
   begin
      return
        (Quotient   => 0.0,
         Reciprocal => 0.0,
         Iterations => 0,
         Status     => Bad_Domain);
   end Fail_Division;

   ---------------------------------------------------------------------------
   -- Oracles
   ---------------------------------------------------------------------------

   function Exact_Quotient (N, D : Long_Float) return Long_Float is
   begin
      if D = 0.0 then
         raise Invalid_Argument with
           "Exact_Quotient: D = 0 (division by zero)";
      end if;
      return N / D;
   end Exact_Quotient;

   function Exact_Reciprocal (D : Long_Float) return Long_Float is
   begin
      if D = 0.0 then
         raise Invalid_Argument with
           "Exact_Reciprocal: D = 0 (no multiplicative inverse)";
      end if;
      return 1.0 / D;
   end Exact_Reciprocal;

   function Exact_Integer_Divide
     (N, D : Integer) return Integer_Division_Result
   is
   begin
      if D = 0 then
         raise Invalid_Argument with
           "Exact_Integer_Divide: D = 0 (division by zero)";
      end if;
      return (Quotient => N / D, Remainder => N rem D);
   end Exact_Integer_Divide;

   ---------------------------------------------------------------------------
   -- Initial guess (dyadic scale + classic NR-division linear seed)
   ---------------------------------------------------------------------------

   --  Bring |D| into M ∈ [1/2, 1) so |D| = M · Two_Power, then seed
   --    Inv_M ≈ (48/17) − (32/17) M
   --  (standard educational NR-division approximant on [1/2, 1]), and
   --  return Sign(D) · Inv_M / Two_Power.
   function Initial_Guess (D : Long_Float) return Long_Float is
      Sign_D    : constant Long_Float :=
        (if D < 0.0 then -1.0 else 1.0);
      M         : Long_Float := abs (D);
      Two_Power : Long_Float := 1.0;
      Inv_M     : Long_Float;
      Guard     : Natural := 0;
   begin
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

      Inv_M := (48.0 - 32.0 * M) / 17.0;
      if Inv_M <= 0.0 then
         Inv_M := 1.0;
      end if;

      return Sign_D * Inv_M / Two_Power;
   end Initial_Guess;

   ---------------------------------------------------------------------------
   -- Reciprocal Newton
   ---------------------------------------------------------------------------

   function Reciprocal_Newton
     (D        : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Reciprocal_Result
   is
      X      : Long_Float;
      X_Next : Long_Float;
      Rel    : Long_Float;
   begin
      if D = 0.0 then
         return Fail_Reciprocal;
      end if;

      X := Initial_Guess (D);

      for Iter in 1 .. Max_Iter loop
         --  X ← X (2 − D X)
         X_Next := X * (2.0 - D * X);
         Rel    := abs (X_Next - X);
         X      := X_Next;

         if abs (D * X - 1.0) <= Tol
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

   ---------------------------------------------------------------------------
   -- Divide_NR
   ---------------------------------------------------------------------------

   function Divide_NR_Detail
     (N, D     : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Division_Result
   is
      R : constant Reciprocal_Result :=
        Reciprocal_Newton (D, Tol, Max_Iter);
   begin
      if R.Status = Bad_Domain then
         return Fail_Division;
      end if;
      return
        (Quotient   => N * R.Value,
         Reciprocal => R.Value,
         Iterations => R.Iterations,
         Status     => R.Status);
   end Divide_NR_Detail;

   function Divide_NR (N, D : Long_Float) return Long_Float is
      R : constant Division_Result := Divide_NR_Detail (N, D);
   begin
      if R.Status /= Converged then
         raise Invalid_Argument with
           "Divide_NR: D = 0 or reciprocal failed to converge";
      end if;
      return R.Quotient;
   end Divide_NR;

   ---------------------------------------------------------------------------
   -- Integer rounding helpers (educational; Long_Float → Integer)
   ---------------------------------------------------------------------------

   --  Truncate toward zero via Long_Float'Truncation, then convert.
   function Truncate_Toward_Zero (X : Long_Float) return Integer is
      T : Long_Float;
   begin
      if X >= Long_Float (Integer'Last) then
         return Integer'Last;
      elsif X <= Long_Float (Integer'First) then
         return Integer'First;
      end if;
      T := Long_Float'Truncation (X);
      return Integer (T);
   end Truncate_Toward_Zero;

   --  Mathematical floor via Long_Float'Floor, then convert.
   function Floor_To_Integer (X : Long_Float) return Integer is
      F : Long_Float;
   begin
      if X >= Long_Float (Integer'Last) then
         return Integer'Last;
      elsif X <= Long_Float (Integer'First) then
         return Integer'First;
      end if;
      F := Long_Float'Floor (X);
      return Integer (F);
   end Floor_To_Integer;

   ---------------------------------------------------------------------------
   -- Integer wrappers
   ---------------------------------------------------------------------------

   function Divide_Integer_Toward_Zero
     (N, D : Integer) return Integer_Division_Result
   is
      Qf  : Long_Float;
      Q   : Integer;
      Rmd : Integer;
   begin
      if D = 0 then
         raise Invalid_Argument with
           "Divide_Integer_Toward_Zero: D = 0";
      end if;

      Qf  := Divide_NR (Long_Float (N), Long_Float (D));
      Q   := Truncate_Toward_Zero (Qf);
      Rmd := N - Q * D;

      --  Repair rare Float off-by-one so |Rem| < |D| and identity holds.
      while abs (Rmd) >= abs (D) loop
         if (Rmd > 0 and then D > 0) or else (Rmd < 0 and then D < 0) then
            Q   := Q + 1;
            Rmd := N - Q * D;
         else
            Q   := Q - 1;
            Rmd := N - Q * D;
         end if;
      end loop;

      --  Prefer Ada truncating semantics when residual sign disagrees.
      declare
         O : constant Integer_Division_Result := Exact_Integer_Divide (N, D);
      begin
         if N = Q * D + Rmd
           and then abs (Rmd) < abs (D)
           and then Q = O.Quotient
           and then Rmd = O.Remainder
         then
            return (Quotient => Q, Remainder => Rmd);
         else
            return O;
         end if;
      end;
   end Divide_Integer_Toward_Zero;

   function Divide_Integer_Floor
     (N, D : Integer) return Integer_Division_Result
   is
      Qf  : Long_Float;
      Q   : Integer;
      Rmd : Integer;
   begin
      if D = 0 then
         raise Invalid_Argument with
           "Divide_Integer_Floor: D = 0";
      end if;

      Qf  := Divide_NR (Long_Float (N), Long_Float (D));
      Q   := Floor_To_Integer (Qf);
      Rmd := N - Q * D;

      if D > 0 then
         while Rmd < 0 loop
            Q   := Q - 1;
            Rmd := Rmd + D;
         end loop;
         while Rmd >= D loop
            Q   := Q + 1;
            Rmd := Rmd - D;
         end loop;
      else
         --  D < 0: floor Quotient; Rem = N − Q D lies in (D, 0].
         while Rmd > 0 loop
            Q   := Q - 1;
            Rmd := Rmd + D;
         end loop;
         while Rmd <= D loop
            Q   := Q + 1;
            Rmd := Rmd - D;
         end loop;
      end if;

      return (Quotient => Q, Remainder => Rmd);
   end Divide_Integer_Floor;

end Newton_Raphson_Division;
