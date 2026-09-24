--  Goldschmidt_Division body — normalize, iterate F=2−D on N and D.

pragma Ada_2022;

package body Goldschmidt_Division
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

   function Fail_Division return Division_Result is
   begin
      return
        (Quotient    => 0.0,
         Final_Denom => 0.0,
         Iterations  => 0,
         Status      => Bad_Domain);
   end Fail_Division;

   ---------------------------------------------------------------------------
   -- Oracle
   ---------------------------------------------------------------------------

   function Exact_Quotient (N, D : Long_Float) return Long_Float is
   begin
      if D = 0.0 then
         raise Invalid_Argument with
           "Exact_Quotient: D = 0 (division by zero)";
      end if;
      return N / D;
   end Exact_Quotient;

   ---------------------------------------------------------------------------
   -- Normalize: dyadic scale so |D| ∈ (1/2, 1], apply same scale to N.
   -- Returns Sign_Q · |N_scaled| / |D_scaled| with positive D_scaled.
   ---------------------------------------------------------------------------

   procedure Normalize
     (N_In, D_In : Long_Float;
      N_Out      : out Long_Float;
      D_Out      : out Long_Float;
      Sign_Q     : out Long_Float)
   is
      Abs_N : Long_Float := abs (N_In);
      Abs_D : Long_Float := abs (D_In);
      Guard : Natural := 0;
   begin
      if (N_In < 0.0) xor (D_In < 0.0) then
         Sign_Q := -1.0;
      else
         Sign_Q := 1.0;
      end if;

      --  Scale Abs_D into (1/2, 1]; scale Abs_N by the same factor.
      while Abs_D > 1.0 and then Guard < 2048 loop
         Abs_D := Abs_D * 0.5;
         Abs_N := Abs_N * 0.5;
         Guard := Guard + 1;
      end loop;
      Guard := 0;
      while Abs_D <= 0.5 and then Abs_D > 0.0 and then Guard < 2048 loop
         Abs_D := Abs_D * 2.0;
         Abs_N := Abs_N * 2.0;
         Guard := Guard + 1;
      end loop;

      N_Out := Abs_N;
      D_Out := Abs_D;
   end Normalize;

   ---------------------------------------------------------------------------
   -- Divide_Goldschmidt_Detail
   ---------------------------------------------------------------------------

   function Divide_Goldschmidt_Detail
     (N, D     : Long_Float;
      Tol      : Long_Float := Default_Tol;
      Max_Iter : Positive   := Default_Max_Iter) return Division_Result
   is
      Num    : Long_Float;
      Den    : Long_Float;
      Sign_Q : Long_Float;
      F      : Long_Float;
   begin
      if D = 0.0 then
         return Fail_Division;
      end if;

      Normalize (N, D, Num, Den, Sign_Q);

      --  Already at unity after normalize (rare exact |D| power of two).
      if abs (Den - 1.0) <= Tol then
         return
           (Quotient    => Sign_Q * Num,
            Final_Denom => Den,
            Iterations  => 0,
            Status      => Converged);
      end if;

      for Iter in 1 .. Max_Iter loop
         --  F_i = 2 − D_i  (same algebraic step as Newton reciprocal)
         F   := 2.0 - Den;
         Num := Num * F;
         Den := Den * F;

         if abs (Den - 1.0) <= Tol then
            return
              (Quotient    => Sign_Q * Num,
               Final_Denom => Den,
               Iterations  => Iter,
               Status      => Converged);
         end if;
      end loop;

      return
        (Quotient    => Sign_Q * Num,
         Final_Denom => Den,
         Iterations  => Max_Iter,
         Status      => Max_Iterations_Reached);
   end Divide_Goldschmidt_Detail;

   function Divide_Goldschmidt (N, D : Long_Float) return Long_Float is
      R : constant Division_Result := Divide_Goldschmidt_Detail (N, D);
   begin
      if R.Status /= Converged then
         raise Invalid_Argument with
           "Divide_Goldschmidt: D = 0 or iteration failed to converge";
      end if;
      return R.Quotient;
   end Divide_Goldschmidt;

end Goldschmidt_Division;
