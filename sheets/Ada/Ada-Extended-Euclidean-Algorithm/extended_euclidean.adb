--  Extended_Euclidean body — iterative extended Euclidean algorithm.

pragma Ada_2022;

package body Extended_Euclidean
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Abs_LI (N : Long_Integer) return Long_Integer is
   begin
      if N < 0 then
         return -N;
      else
         return N;
      end if;
   end Abs_LI;

   function Mod_Nonneg (A, M : Long_Integer) return Long_Integer is
      R : Long_Integer := A rem M;
   begin
      if R < 0 then
         R := R + M;
      end if;
      return R;
   end Mod_Nonneg;

   function Is_Modular_Inverse
     (A, Inv, M : Long_Integer) return Boolean
   is
   begin
      return Mod_Nonneg (A * Inv, M) = 1;
   end Is_Modular_Inverse;

   function Verify_Bezout
     (A, B : Long_Integer; R : Extended_Gcd_Result) return Boolean
   is
   begin
      return R.Gcd >= 0
        and then A * R.X + B * R.Y = R.Gcd;
   end Verify_Bezout;

   -------------------------------------------------------------------------
   -- Classical Euclidean gcd
   -------------------------------------------------------------------------

   function Gcd (A, B : Long_Integer) return Long_Integer is
      U : Long_Integer := Abs_LI (A);
      V : Long_Integer := Abs_LI (B);
      T : Long_Integer;
   begin
      while V /= 0 loop
         T := U rem V;
         U := V;
         V := T;
      end loop;
      return U;
   end Gcd;

   -------------------------------------------------------------------------
   -- Iterative extended Euclidean (Wikipedia)
   --
   --   (old_r, r) := (a, b)
   --   (old_s, s) := (1, 0)
   --   (old_t, t) := (0, 1)
   --   while r ≠ 0 do
   --       q := old_r div r
   --       (old_r, r) := (r, old_r − q × r)
   --       (old_s, s) := (s, old_s − q × s)
   --       (old_t, t) := (t, old_t − q × t)
   --   output Bézout (old_s, old_t), gcd old_r
   --
   -- If the raw gcd is negative (zero / negative edge cases), flip all
   -- three outputs so Gcd ≥ 0 (Wikipedia note on sign correction).
   -------------------------------------------------------------------------

   function Extended_Gcd (A, B : Long_Integer) return Extended_Gcd_Result is
      Old_R : Long_Integer := A;
      R     : Long_Integer := B;
      Old_S : Long_Integer := 1;
      S     : Long_Integer := 0;
      Old_T : Long_Integer := 0;
      T     : Long_Integer := 1;
      Quotient : Long_Integer;
      Prov     : Long_Integer;
      Res      : Extended_Gcd_Result;
   begin
      while R /= 0 loop
         Quotient := Old_R / R;

         Prov := R;
         R := Old_R - Quotient * Prov;
         Old_R := Prov;

         Prov := S;
         S := Old_S - Quotient * Prov;
         Old_S := Prov;

         Prov := T;
         T := Old_T - Quotient * Prov;
         Old_T := Prov;
      end loop;

      --  Normalize so Gcd ≥ 0 (flip Bézout signs together).
      if Old_R < 0 then
         Res.Gcd := -Old_R;
         Res.X   := -Old_S;
         Res.Y   := -Old_T;
      else
         Res.Gcd := Old_R;
         Res.X   := Old_S;
         Res.Y   := Old_T;
      end if;
      return Res;
   end Extended_Gcd;

   function Are_Coprime (A, B : Long_Integer) return Boolean is
   begin
      return Gcd (A, B) = 1;
   end Are_Coprime;

   function Quotients_By_Gcd (A, B : Long_Integer) return Quotient_Pair is
      G   : constant Long_Integer := Gcd (A, B);
      Res : Quotient_Pair;
   begin
      if G = 0 then
         Res.A_Over_G := 0;
         Res.B_Over_G := 0;
      else
         Res.A_Over_G := A / G;
         Res.B_Over_G := B / G;
      end if;
      return Res;
   end Quotients_By_Gcd;

   -------------------------------------------------------------------------
   -- Modular inverse via extended Euclidean
   -------------------------------------------------------------------------

   function Modular_Inverse (A, M : Long_Integer) return Long_Integer is
      A_N : Long_Integer;
      EG  : Extended_Gcd_Result;
   begin
      if M <= 1 then
         raise Invalid_Argument;
      end if;
      A_N := Mod_Nonneg (A, M);
      EG  := Extended_Gcd (A_N, M);
      if EG.Gcd /= 1 then
         raise Invalid_Argument;
      end if;
      return Mod_Nonneg (EG.X, M);
   end Modular_Inverse;

end Extended_Euclidean;
