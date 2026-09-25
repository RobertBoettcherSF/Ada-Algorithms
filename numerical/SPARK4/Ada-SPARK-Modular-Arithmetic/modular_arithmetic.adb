--  Version: 0.001
--  Modular_Arithmetic body: implementations and their proofs.

pragma Ada_2022;

with Modular_Arithmetic.Lemmas;

package body Modular_Arithmetic
  with SPARK_Mode => On
is

   package L renames Modular_Arithmetic.Lemmas;

   -------------
   -- Add_Mod --
   -------------

   function Add_Mod (A, B : Natural_64; N : Modulus_Type) return Natural_64
   is
   begin
      if A >= N - B then
         --  A + B >= N: subtract N first so that nothing overflows.
         L.Mod_Unique (Wide (A) + Wide (B), 1, Wide (A - (N - B)), Wide (N));
         return A - (N - B);
      else
         L.Mod_Unique (Wide (A) + Wide (B), 0, Wide (A + B), Wide (N));
         return A + B;
      end if;
   end Add_Mod;

   -------------
   -- Sub_Mod --
   -------------

   function Sub_Mod (A, B : Natural_64; N : Modulus_Type) return Natural_64
   is
   begin
      if A >= B then
         L.Mod_Unique (Wide (A) - Wide (B), 0, Wide (A - B), Wide (N));
         return A - B;
      else
         L.Mod_Unique
           (Wide (A) - Wide (B), -1, Wide (N - (B - A)), Wide (N));
         return N - (B - A);
      end if;
   end Sub_Mod;

   -------------
   -- Neg_Mod --
   -------------

   function Neg_Mod (A : Natural_64; N : Modulus_Type) return Natural_64 is
   begin
      if A = 0 then
         return 0;
      else
         L.Mod_Unique (-Wide (A), -1, Wide (N - A), Wide (N));
         return N - A;
      end if;
   end Neg_Mod;

   -------------
   -- Mul_Mod --
   -------------

   function Mul_Mod (A, B : Natural_64; N : Modulus_Type) return Natural_64
   is
   begin
      return Natural_64 ((Wide (A) * Wide (B)) mod Wide (N));
   end Mul_Mod;

   --------------------
   -- Lemma_Pow_Succ --
   --------------------

   procedure Lemma_Pow_Succ (B, E : Natural_64; N : Modulus_Type) is
      H : constant Natural_64 := Pow_Spec (B, E / 2, N);
      S : constant Natural_64 := Mul_Mod (H, H, N);
   begin
      if E mod 2 = 0 then
         --  E + 1 is odd and (E + 1) / 2 = E / 2.
         pragma Assert ((E + 1) / 2 = E / 2);
         pragma Assert (Pow_Spec (B, E + 1, N) = Mul_Mod (S, B, N));
         if E = 0 then
            pragma Assert (H = 1);
            pragma Assert (S = 1);
            pragma Assert (Pow_Spec (B, E, N) = 1);
         else
            pragma Assert (Pow_Spec (B, E, N) = S);
         end if;
      else
         --  E = 2h + 1, E + 1 = 2 (h + 1).
         Lemma_Pow_Succ (B, E / 2, N);
         pragma Assert ((E + 1) / 2 = E / 2 + 1);
         declare
            H1 : constant Natural_64 := Pow_Spec (B, E / 2 + 1, N);
         begin
            pragma Assert (H1 = Mul_Mod (H, B, N));
            pragma Assert (Pow_Spec (B, E + 1, N) = Mul_Mod (H1, H1, N));
            pragma Assert (Pow_Spec (B, E, N) = Mul_Mod (S, B, N));
            L.Sq_Mul (Wide (H), Wide (B), Wide (N));
            pragma Assert
              (Mul_Mod (H1, H1, N) = Mul_Mod (Mul_Mod (S, B, N), B, N));
         end;
      end if;
   end Lemma_Pow_Succ;

   -------------
   -- Pow_Mod --
   -------------

   function Pow_Mod (B, E : Natural_64; N : Modulus_Type) return Natural_64
   is
   begin
      if E = 0 then
         return 1;
      end if;
      declare
         H : constant Natural_64 := Pow_Mod (B, E / 2, N);   --  B**(E/2)
         S : constant Natural_64 := Mul_Mod (H, H, N);       --  square
      begin
         if E mod 2 = 0 then
            return S;
         else
            return Mul_Mod (S, B, N);                        --  multiply
         end if;
      end;
   end Pow_Mod;

   ------------------
   -- Extended_Gcd --
   ------------------

   function Extended_Gcd (A, B : Natural_64) return Bezout is
      WA : constant Wide := Wide (A);
      WB : constant Wide := Wide (B);
      R0 : Wide_Nat := WA;
      R1 : Wide_Nat := WB;
      --  Magnitudes of the Bezout coefficients of R0 / R1.  The signs
      --  alternate:  if Even then R0 = A*S0 - B*T0, R1 = B*T1 - A*S1,
      --  otherwise the signs are swapped.
      S0, T1 : Wide_Nat := 1;
      S1, T0 : Wide_Nat := 0;
      Even   : Boolean := True;
      Q, R2, S2, T2 : Wide;
      Result : Bezout;

      --  At the end (R1 = 0): A = T1 * R0 and B = S1 * R0.
      procedure Prove_Divides with Ghost is
      begin
         if R0 > 0 then
            L.Mod_Unique (WA, T1, 0, R0);
            L.Mod_Unique (WB, S1, 0, R0);
            pragma Assert (if WA > 0 then T1 >= 1);
            pragma Assert (if WB > 0 then S1 >= 1);
         end if;
      end Prove_Divides;

   begin
      while R1 /= 0 loop
         pragma Loop_Invariant
           (if Even then R0 = WA * S0 - WB * T0 and then R1 = WB * T1 - WA * S1
            else R0 = WB * T0 - WA * S0 and then R1 = WA * S1 - WB * T1);
         pragma Loop_Invariant (WA = T1 * R0 + T0 * R1);
         pragma Loop_Invariant (WB = S1 * R0 + S0 * R1);
         pragma Loop_Invariant (S0 <= Max1 (B) and then S1 <= Max1 (B));
         pragma Loop_Invariant (T0 <= Max1 (A) and then T1 <= Max1 (A));
         pragma Loop_Variant (Decreases => R1);

         Q  := R0 / R1;
         R2 := R0 mod R1;
         L.Div_Mod (R0, R1);
         pragma Assert (R0 = Q * R1 + R2);
         pragma Assert (Q <= R0);
         S2 := S0 + Q * S1;
         T2 := T0 + Q * T1;
         pragma Assert (WB = S2 * R1 + S1 * R2);
         pragma Assert (WA = T2 * R1 + T1 * R2);
         pragma Assert (S2 <= S2 * R1);
         pragma Assert (T2 <= T2 * R1);
         pragma Assert (S2 <= WB and then T2 <= WA);

         R0 := R1;
         R1 := R2;
         S0 := S1;
         S1 := S2;
         T0 := T1;
         T1 := T2;
         Even := not Even;
      end loop;

      Result.G := Natural_64 (R0);
      if Even then
         Result.X := S0;
         Result.Y := -T0;
      else
         Result.X := -S0;
         Result.Y := T0;
      end if;

      Prove_Divides;
      return Result;
   end Extended_Gcd;

   -------------
   -- Inverse --
   -------------

   function Inverse (A : Natural_64; N : Modulus_Type) return Natural_64 is
      E  : constant Bezout := Extended_Gcd (A, N);
      WA : constant Wide := Wide (A);
      WN : constant Wide := Wide (N);
   begin
      pragma Assert (E.G = 1);
      pragma Assert (WA * E.X + WN * E.Y = 1);
      if E.X >= 0 then
         pragma Assert (WA * E.X = (-E.Y) * WN + 1);
         L.Mod_Unique (WA * E.X, -E.Y, 1, WN);
         L.Mul_Mod_Right (WA, E.X, WN);
         return Natural_64 (E.X mod WN);
      else
         pragma Assert (E.Y >= 0 and then E.Y <= WA);
         pragma Assert (WA * (E.X + WN) = (WA - E.Y) * WN + 1);
         L.Mod_Unique (WA * (E.X + WN), WA - E.Y, 1, WN);
         return Natural_64 (E.X + WN);
      end if;
   end Inverse;

   ------------------
   -- Orbit_Length --
   ------------------

   function Orbit_Length (A : Natural_64; N : Modulus_Type) return Natural_64
   is
      G : constant Natural_64 := Gcd (A, N);
      K : constant Natural_64 := N / G;
   begin
      pragma Assert (G >= 1);
      L.Div_Mod (Wide (N), Wide (G));
      pragma Assert (Wide (K) * Wide (G) = Wide (N));
      L.Div_Mod (Wide (A), Wide (G));
      pragma Assert (Wide (A) = Wide (A / G) * Wide (G));
      pragma Assert (Wide (K) * Wide (A) = Wide (A / G) * Wide (N));
      L.Mod_Unique (Wide (K) * Wide (A), Wide (A / G), 0, Wide (N));
      return K;
   end Orbit_Length;

   --------------------------
   -- Multiplicative_Order --
   --------------------------

   function Multiplicative_Order
     (A : Natural_64; N : Modulus_Type) return Natural_64
   is
      X : Natural_64 := A;   --  A**K mod N
   begin
      pragma Assert (Pow_Spec (A, 0, N) = 1);
      pragma Assert (Pow_Spec (A, 1, N) = A);
      for K in 1 .. N - 1 loop
         pragma Loop_Invariant (X < N and then X = Pow_Spec (A, K, N));
         pragma Loop_Invariant
           (for all J in 1 .. K - 1 => Pow_Spec (A, J, N) /= 1);
         if X = 1 then
            return K;
         end if;
         Lemma_Pow_Succ (A, K, N);
         X := Mul_Mod (X, A, N);
      end loop;
      return 0;
   end Multiplicative_Order;

end Modular_Arithmetic;
