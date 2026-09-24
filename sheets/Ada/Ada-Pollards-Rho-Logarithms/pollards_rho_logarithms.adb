--  Pollard's rho for logarithms — Ada 2023 implementation (educational).

pragma Ada_2022;

with Interfaces;

package body Pollards_Rho_Logarithms
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Helpers
   ------------------------------------------------------------------

   function Mul_Mod (A, B, M : U64) return U64 is
      use Interfaces;
      AA, BB, MM, Prod : Unsigned_128;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      if M = 1 then
         return 0;
      end if;
      AA   := Unsigned_128 (A rem M);
      BB   := Unsigned_128 (B rem M);
      MM   := Unsigned_128 (M);
      Prod := AA * BB;
      return U64 (Unsigned_64 (Prod rem MM));
   end Mul_Mod;

   function Mod_Pow (Base, Exp, Modulus : U64) return U64 is
      Result : U64 := 1;
      B      : U64;
      E      : U64 := Exp;
   begin
      if Modulus = 0 then
         raise Invalid_Argument;
      end if;
      if Modulus = 1 then
         return 0;
      end if;
      B := Base rem Modulus;
      while E > 0 loop
         if (E and 1) = 1 then
            Result := Mul_Mod (Result, B, Modulus);
         end if;
         B := Mul_Mod (B, B, Modulus);
         E := E / 2;
      end loop;
      return Result;
   end Mod_Pow;

   function Gcd (A, B : U64) return U64 is
      X : U64 := A;
      Y : U64 := B;
      T : U64;
   begin
      while Y /= 0 loop
         T := X rem Y;
         X := Y;
         Y := T;
      end loop;
      return X;
   end Gcd;

   function Sub_Mod (X, Y, M : U64) return U64 is
      XX, YY : U64;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      if M = 1 then
         return 0;
      end if;
      XX := X rem M;
      YY := Y rem M;
      if XX >= YY then
         return XX - YY;
      else
         return XX + M - YY;
      end if;
   end Sub_Mod;

   --  Extended Euclidean on Long_Long_Integer; returns (G, X, Y) with
   --  A*X + B*Y = G and G ≥ 0. Used only for Modular_Inverse / congruence.
   procedure Extended_Gcd_LL
     (A, B : Long_Long_Integer;
      G, X, Y : out Long_Long_Integer)
   is
      Old_R, R : Long_Long_Integer;
      Old_S, S : Long_Long_Integer;
      Old_T, T : Long_Long_Integer;
      Quotient, Tmp : Long_Long_Integer;
   begin
      Old_R := A;
      R     := B;
      Old_S := 1;
      S     := 0;
      Old_T := 0;
      T     := 1;
      while R /= 0 loop
         Quotient := Old_R / R;
         Tmp := R;
         R := Old_R - Quotient * R;
         Old_R := Tmp;
         Tmp := S;
         S := Old_S - Quotient * S;
         Old_S := Tmp;
         Tmp := T;
         T := Old_T - Quotient * T;
         Old_T := Tmp;
      end loop;
      if Old_R < 0 then
         G := -Old_R;
         X := -Old_S;
         Y := -Old_T;
      else
         G := Old_R;
         X := Old_S;
         Y := Old_T;
      end if;
   end Extended_Gcd_LL;

   function Modular_Inverse (A, M : U64) return U64 is
      AA, MM : Long_Long_Integer;
      G, X, Y : Long_Long_Integer;
      Inv : Long_Long_Integer;
   begin
      if M <= 1 then
         raise Invalid_Argument;
      end if;
      AA := Long_Long_Integer (A rem M);
      MM := Long_Long_Integer (M);
      Extended_Gcd_LL (AA, MM, G, X, Y);
      pragma Unreferenced (Y);
      if G /= 1 then
         raise Invalid_Argument;
      end if;
      Inv := X mod MM;
      if Inv < 0 then
         Inv := Inv + MM;
      end if;
      return U64 (Inv);
   end Modular_Inverse;

   function Verify_Discrete_Log
     (Alpha, Beta, Modulus, Log : U64) return Boolean
   is
   begin
      if Modulus <= 1 then
         return False;
      end if;
      return Mod_Pow (Alpha, Log, Modulus) = (Beta rem Modulus);
   end Verify_Discrete_Log;

   ------------------------------------------------------------------
   --  Partition step (Wikipedia example: rem-3 map matching the
   --  worked table for α=2, β=5, N=1019)
   --    x ≡ 0 (mod 3) → square:     a ← 2a, b ← 2b
   --    x ≡ 1 (mod 3) → ×α:         a ← a+1
   --    x ≡ 2 (mod 3) → ×β:         b ← b+1
   ------------------------------------------------------------------

   procedure Step
     (X, A, B           : in out U64;
      Alpha, Beta       : U64;
      Modulus, Order    : U64)
   is
      R : constant U64 := X rem 3;
   begin
      if R = 0 then
         X := Mul_Mod (X, X, Modulus);
         A := Mul_Mod (A, 2, Order);
         B := Mul_Mod (B, 2, Order);
      elsif R = 1 then
         X := Mul_Mod (X, Alpha, Modulus);
         A := (A + 1) rem Order;
      else
         X := Mul_Mod (X, Beta, Modulus);
         B := (B + 1) rem Order;
      end if;
   end Step;

   --  Solve C·γ ≡ D (mod N); try all Gcd(C,N) candidates; return the
   --  one that verifies Alpha^γ ≡ Beta, or Order on failure.
   function Solve_Congruence
     (C, D, N, Alpha, Beta, Modulus : U64) return U64
   is
      G     : U64;
      CC, DD, NN : U64;
      Inv   : U64;
      Gamma0 : U64;
      Cand  : U64;
      K     : U64;
   begin
      if N = 0 then
         return 0;
      end if;
      G := Gcd (C, N);
      if G = 0 then
         return N;
      end if;
      if D rem G /= 0 then
         return N;
      end if;

      CC := C / G;
      DD := D / G;
      NN := N / G;

      begin
         Inv := Modular_Inverse (CC, NN);
      exception
         when Invalid_Argument =>
            return N;
      end;

      Gamma0 := Mul_Mod (Inv, DD, NN);
      K := 0;
      while K < G loop
         Cand := Gamma0 + K * NN;
         if Cand < N
           and then Verify_Discrete_Log (Alpha, Beta, Modulus, Cand)
         then
            return Cand;
         end if;
         K := K + 1;
      end loop;
      return N;
   end Solve_Congruence;

   ------------------------------------------------------------------
   --  Discrete_Log_Rho
   ------------------------------------------------------------------

   function Discrete_Log_Rho
     (Alpha     : U64;
      Beta      : U64;
      Modulus   : U64;
      Order     : U64;
      Seed      : U64     := 0;
      Max_Steps : Natural := Default_Max_Steps) return U64
   is
      A_Alp : U64;
      B_Bet : U64;
      Tort_X, Tort_A, Tort_B : U64;
      Hare_X, Hare_A, Hare_B : U64;
      Diff_B, Diff_A : U64;
      Steps : Natural := 0;
      Result : U64;
   begin
      if Modulus < 2 then
         raise Invalid_Argument;
      end if;
      if Order = 0 or else Order > Max_Educational_Order then
         raise Invalid_Argument;
      end if;
      A_Alp := Alpha rem Modulus;
      B_Bet := Beta rem Modulus;
      if A_Alp = 0 or else B_Bet = 0 then
         raise Invalid_Argument;
      end if;

      --  Trivial / quick cases
      if B_Bet = 1 then
         return 0;
      end if;
      if A_Alp = B_Bet then
         return 1 rem Order;
      end if;

      --  Initialise: x0 = α^Seed, a0 = Seed rem Order, b0 = 0
      Tort_A := Seed rem Order;
      Tort_B := 0;
      Tort_X := Mod_Pow (A_Alp, Tort_A, Modulus);
      Hare_X := Tort_X;
      Hare_A := Tort_A;
      Hare_B := Tort_B;

      while Steps < Max_Steps loop
         --  Tortoise: one step
         Step (Tort_X, Tort_A, Tort_B, A_Alp, B_Bet, Modulus, Order);
         --  Hare: two steps
         Step (Hare_X, Hare_A, Hare_B, A_Alp, B_Bet, Modulus, Order);
         Step (Hare_X, Hare_A, Hare_B, A_Alp, B_Bet, Modulus, Order);

         Steps := Steps + 1;

         if Tort_X = Hare_X then
            --  α^{Tort_A} β^{Tort_B} = α^{Hare_A} β^{Hare_B}
            --  (Hare_B − Tort_B) γ ≡ (Tort_A − Hare_A)  (mod Order)
            Diff_B := Sub_Mod (Hare_B, Tort_B, Order);
            Diff_A := Sub_Mod (Tort_A, Hare_A, Order);

            if Diff_B = 0 then
               --  Wikipedia: r = 0 → failure (retry other Seed)
               return Order;
            end if;

            Result := Solve_Congruence
              (Diff_B, Diff_A, Order, A_Alp, B_Bet, Modulus);
            return Result;
         end if;
      end loop;

      return Order;  --  Max_Steps exhaustion
   end Discrete_Log_Rho;

end Pollards_Rho_Logarithms;
