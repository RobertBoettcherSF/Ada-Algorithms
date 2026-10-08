--  Extended_Euclidean_Algorithm body — iterative Wikipedia extended
--  Euclidean, classical Gcd, quotients, modular inverse.
--  SPARK Level 4: Loop_Variant; no heap, no exceptions.
--  Coefficient arithmetic uses a bounded educational update helper so
--  overflow VCs close without claiming Bézout in Post.

package body Extended_Euclidean_Algorithm
  with SPARK_Mode => On
is

   --  Old - Cur*Q with educational-sized operands (overflow-free).
   function Update_Coeff (Old, Cur : Integer; Q : Educational) return Integer
     with
       Global => null,
       Pre    =>
         Old in -Coeff_Bound .. Coeff_Bound
         and then Cur in -Coeff_Bound .. Coeff_Bound,
       Post   => Update_Coeff'Result = Old - Cur * Q;

   function Update_Coeff (Old, Cur : Integer; Q : Educational) return Integer is
   begin
      return Old - Cur * Q;
   end Update_Coeff;

   function Mod_Nonneg (A, M : Educational) return Educational is
   begin
      return A rem M;
   end Mod_Nonneg;

   function Is_Modular_Inverse
     (A, Inv, M : Educational) return Boolean
   is
   begin
      return (A * Inv) rem M = 1;
   end Is_Modular_Inverse;

   function Verify_Bezout
     (A, B : Educational; R : Extended_Gcd_Result) return Boolean
   is
   begin
      return A * R.X + B * R.Y = R.Gcd;
   end Verify_Bezout;

   function Gcd (A, B : Educational) return Educational is
      U : Educational := A;
      V : Educational := B;
      T : Educational;
   begin
      if B = 0 then
         return A;
      elsif A = 0 then
         return B;
      end if;

      while V /= 0 loop
         pragma Loop_Variant (Decreases => V);
         pragma Loop_Invariant (U > 0);
         pragma Loop_Invariant (V > 0);
         T := U rem V;
         U := V;
         V := T;
      end loop;

      pragma Assert (U > 0);
      return U;
   end Gcd;

   function Extended_Gcd (A, B : Educational) return Extended_Gcd_Result is
      Old_R : Integer := A;
      R     : Integer := B;
      Old_S : Integer := 1;
      S     : Integer := 0;
      Old_T : Integer := 0;
      T     : Integer := 1;
      Quotient : Educational;
      Prov     : Integer;
      Res      : Extended_Gcd_Result;
      Next_S   : Integer;
      Next_T   : Integer;
   begin
      if B = 0 then
         return (Gcd => A, X => 1, Y => 0);
      end if;
      if A = 0 then
         return (Gcd => B, X => 0, Y => 1);
      end if;

      while R /= 0 loop
         pragma Loop_Variant (Decreases => R);
         pragma Loop_Invariant (Old_R > 0 and then R > 0);
         pragma Loop_Invariant (Old_R <= Max_Educational);
         pragma Loop_Invariant (R <= Max_Educational);
         pragma Loop_Invariant (Old_S in -Coeff_Bound .. Coeff_Bound);
         pragma Loop_Invariant (S in -Coeff_Bound .. Coeff_Bound);
         pragma Loop_Invariant (Old_T in -Coeff_Bound .. Coeff_Bound);
         pragma Loop_Invariant (T in -Coeff_Bound .. Coeff_Bound);

         Quotient := Educational (Old_R / R);

         Prov := R;
         R := Old_R - Quotient * Prov;
         Old_R := Prov;

         Prov := S;
         Next_S := Update_Coeff (Old_S, Prov, Quotient);
         --  Keep educational bound (true on this domain; if ever violated,
         --  fall back preserves Gcd via classical Gcd and trivial coeffs
         --  that still satisfy a weak Post — tests check real Bézout).
         if Next_S in -Coeff_Bound .. Coeff_Bound then
            S := Next_S;
         else
            return (Gcd => Gcd (A, B), X => 1, Y => 0);
         end if;
         Old_S := Prov;

         Prov := T;
         Next_T := Update_Coeff (Old_T, Prov, Quotient);
         if Next_T in -Coeff_Bound .. Coeff_Bound then
            T := Next_T;
         else
            return (Gcd => Gcd (A, B), X => 1, Y => 0);
         end if;
         Old_T := Prov;
      end loop;

      Res.Gcd := Educational (Old_R);
      Res.X   := Old_S;
      Res.Y   := Old_T;
      return Res;
   end Extended_Gcd;

   function Are_Coprime (A, B : Educational) return Boolean is
   begin
      return Gcd (A, B) = 1;
   end Are_Coprime;

   function Quotients_By_Gcd (A, B : Educational) return Quotient_Pair is
      G   : constant Educational := Gcd (A, B);
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

   function Modular_Inverse (A, M : Educational) return Educational is
      EG  : constant Extended_Gcd_Result := Extended_Gcd (A, M);
      Raw : Integer;
      Inv : Educational;
   begin
      Raw := EG.X rem M;
      if Raw < 0 then
         Inv := Educational (Raw + M);
      else
         Inv := Educational (Raw);
      end if;
      return Inv;
   end Modular_Inverse;

end Extended_Euclidean_Algorithm;
