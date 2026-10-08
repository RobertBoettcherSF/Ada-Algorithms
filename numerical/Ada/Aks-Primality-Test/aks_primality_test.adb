--  AKS primality test — implementation (educational dense-poly form).

pragma Ada_2022;

with Ada.Numerics.Long_Elementary_Functions;
with Interfaces;

package body AKS_Primality_Test
  with SPARK_Mode => Off
is

   use Ada.Numerics.Long_Elementary_Functions;

   ------------------------------------------------------------------
   --  Dense polynomials in (Z/NZ)[X] / (X^R − 1)
   ------------------------------------------------------------------

   --  Coeff (I) is the coefficient of X^I, I in 0 .. R−1.
   type Poly is array (Natural range <>) of U64;

   ------------------------------------------------------------------
   --  Mul_Mod / Gcd / logs
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

   function Floor_Log2 (N : U64) return Natural is
      X : U64 := N;
      L : Natural := 0;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      while X > 1 loop
         X := X / 2;
         L := L + 1;
      end loop;
      return L;
   end Floor_Log2;

   function Floor_Log2_Squared (N : U64) return Natural is
      Lg : Long_Float;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      --  Exact for educational Max_Educational_N ≪ 2^53.
      Lg := Log (Long_Float (N), 2.0);
      return Natural (Long_Float'Floor (Lg * Lg));
   end Floor_Log2_Squared;

   ------------------------------------------------------------------
   --  Totient
   ------------------------------------------------------------------

   function Totient (R : U64) return U64 is
      Result : U64;
      X      : U64;
      P      : U64;
   begin
      if R = 0 then
         raise Invalid_Argument;
      end if;
      Result := R;
      X      := R;
      P      := 2;
      while P * P <= X loop
         if X rem P = 0 then
            while X rem P = 0 loop
               X := X / P;
            end loop;
            Result := Result - Result / P;
         end if;
         if P = 2 then
            P := 3;
         else
            P := P + 2;
         end if;
      end loop;
      if X > 1 then
         Result := Result - Result / X;
      end if;
      return Result;
   end Totient;

   ------------------------------------------------------------------
   --  Is_Perfect_Power
   ------------------------------------------------------------------

   --  Integer power Base^Exp for Exp ≥ 1; returns (Value, Overflow).
   procedure IPow
     (Base     : U64;
      Exp      : Positive;
      Value    : out U64;
      Overflow : out Boolean)
   is
      Result : U64 := 1;
      B      : U64 := Base;
      E      : Natural := Exp;
   begin
      Overflow := False;
      if Base = 0 then
         Value := 0;
         return;
      end if;
      while E > 0 loop
         if (E mod 2) = 1 then
            --  Result * B overflow if Result > U64'Last / B
            if B /= 0 and then Result > U64'Last / B then
               Overflow := True;
               Value    := 0;
               return;
            end if;
            Result := Result * B;
         end if;
         E := E / 2;
         if E > 0 then
            if B > U64'Last / B then
               --  Further squaring would overflow; if Exp still needs it,
               --  the power overflows. Mark and continue only if done.
               Overflow := True;
               Value    := 0;
               return;
            end if;
            B := B * B;
         end if;
      end loop;
      Value := Result;
   end IPow;

   function Is_Perfect_Power (N : U64) return Boolean is
      Max_B : Natural;
      Lo, Hi, Mid : U64;
      P           : U64;
      Overflow    : Boolean;
   begin
      if N < 4 then
         return False;
      end if;
      Max_B := Floor_Log2 (N);  --  A^B = N ⇒ B ≤ log2 N
      for B in 2 .. Max_B loop
         --  Binary search A > 1 with A^B = N.
         Lo := 2;
         Hi := N;  --  loose upper bound; shrink quickly
         --  A ≤ 2^(floor(log2 N)/B) + 1
         declare
            Bits : constant Natural := Floor_Log2 (N) / B + 2;
         begin
            if Bits >= 64 then
               Hi := N;
            else
               Hi := U64 (2) ** Bits;
               if Hi > N then
                  Hi := N;
               end if;
            end if;
         end;
         while Lo <= Hi loop
            Mid := Lo + (Hi - Lo) / 2;
            IPow (Mid, B, P, Overflow);
            if Overflow or else P > N then
               if Mid = 0 then
                  exit;
               end if;
               Hi := Mid - 1;
            elsif P < N then
               Lo := Mid + 1;
            else
               return True;
            end if;
         end loop;
      end loop;
      return False;
   end Is_Perfect_Power;

   ------------------------------------------------------------------
   --  Find_AKS_R
   ------------------------------------------------------------------

   --  True iff ord_R(N) > Max_K (requires Gcd(N,R)=1).
   --  Equivalent: N^K ≢ 1 (mod R) for all K = 1 .. Max_K.
   function Order_Exceeds (N, R : U64; Max_K : Natural) return Boolean is
      X  : U64 := 1;
      Nm : constant U64 := N rem R;
   begin
      for K in 1 .. Max_K loop
         X := (X * Nm) rem R;
         if X = 1 then
            return False;
         end if;
      end loop;
      return True;
   end Order_Exceeds;

   function Find_AKS_R (N : U64) return U64 is
      Max_K : Natural;
      R     : U64;
   begin
      if N < 2 or else N > Max_Educational_N then
         raise Invalid_Argument;
      end if;
      Max_K := Floor_Log2_Squared (N);
      R     := 2;
      loop
         if Gcd (N, R) = 1 and then Order_Exceeds (N, R, Max_K) then
            return R;
         end if;
         R := R + 1;
         --  Theory: such an R exists with R = O((log N)^5); for our
         --  Max_Educational_N a hard cap is only a safety net.
         if R > Max_Educational_N * 4 + 100 then
            raise Invalid_Argument;
         end if;
      end loop;
   end Find_AKS_R;

   ------------------------------------------------------------------
   --  Polynomial arithmetic mod (X^R − 1, N)
   ------------------------------------------------------------------

   function Poly_Mul_Mod
     (A, B : Poly;
      N    : U64;
      R    : Natural) return Poly
   is
      C : Poly (0 .. R - 1) := [others => 0];
   begin
      for I in 0 .. R - 1 loop
         if A (I) /= 0 then
            for J in 0 .. R - 1 loop
               if B (J) /= 0 then
                  declare
                     K : constant Natural := (I + J) rem R;
                  begin
                     C (K) := C (K) + Mul_Mod (A (I), B (J), N);
                     if C (K) >= N then
                        C (K) := C (K) - N;
                     end if;
                  end;
               end if;
            end loop;
         end if;
      end loop;
      return C;
   end Poly_Mul_Mod;

   function Poly_Mod_Pow
     (Base : Poly;
      Exp  : U64;
      N    : U64;
      R    : Natural) return Poly
   is
      Result : Poly (0 .. R - 1) := [others => 0];
      B      : Poly (0 .. R - 1) := Base;
      E      : U64 := Exp;
   begin
      Result (0) := 1 rem N;
      while E > 0 loop
         if (E and 1) = 1 then
            Result := Poly_Mul_Mod (Result, B, N, R);
         end if;
         B := Poly_Mul_Mod (B, B, N, R);
         E := E / 2;
      end loop;
      return Result;
   end Poly_Mod_Pow;

   function Congruence_Holds
     (N, A_Const, R_U : U64) return Boolean
   is
      R       : constant Natural := Natural (R_U);
      Base    : Poly (0 .. R - 1) := [others => 0];
      Left    : Poly (0 .. R - 1);
      Right   : Poly (0 .. R - 1) := [others => 0];
      Rhs_Deg : constant Natural := Natural (N rem R_U);
   begin
      --  Base = X + A
      Base (0) := A_Const rem N;
      if R > 1 then
         Base (1) := 1;
      end if;

      Left := Poly_Mod_Pow (Base, N, N, R);

      --  Right = X^N + A ≡ X^(N mod R) + A  (since X^R ≡ 1)
      Right (0) := A_Const rem N;
      Right (Rhs_Deg) := Right (Rhs_Deg) + 1;
      if Right (Rhs_Deg) >= N then
         Right (Rhs_Deg) := Right (Rhs_Deg) - N;
      end if;

      for I in 0 .. R - 1 loop
         if Left (I) /= Right (I) then
            return False;
         end if;
      end loop;
      return True;
   end Congruence_Holds;

   ------------------------------------------------------------------
   --  Is_Prime_AKS
   ------------------------------------------------------------------

   function Is_Prime_AKS (N : U64) return Boolean is
      R       : U64;
      Phi     : U64;
      Limit   : Natural;
      Lg, Sqr : Long_Float;
      Upper   : U64;
   begin
      if N < 2 or else N > Max_Educational_N then
         raise Invalid_Argument;
      end if;

      --  Step 1: perfect power → composite
      if Is_Perfect_Power (N) then
         return False;
      end if;

      --  Step 2: smallest R with ord_R(N) > (log2 N)^2
      R := Find_AKS_R (N);

      --  Step 3: if 1 < gcd(A,N) < N for some A ≤ R → composite
      --  (Wikipedia / paper; equivalent to trial division up to R)
      Upper := R;
      if Upper > N - 1 then
         Upper := N - 1;
      end if;
      declare
         A : U64 := 2;
         G : U64;
      begin
         while A <= Upper loop
            G := Gcd (A, N);
            if G > 1 and then G < N then
               return False;
            end if;
            A := A + 1;
         end loop;
      end;

      --  Step 4: N ≤ R → prime
      if N <= R then
         return True;
      end if;

      --  Step 5: congruence witnesses
      --  Limit = floor(√φ(R) · log2 N)
      Phi := Totient (R);
      Lg  := Log (Long_Float (N), 2.0);
      Sqr := Sqrt (Long_Float (Phi));
      Limit := Natural (Long_Float'Floor (Sqr * Lg));

      for A in 1 .. Limit loop
         if not Congruence_Holds (N, U64 (A), R) then
            return False;
         end if;
      end loop;

      --  Step 6
      return True;
   end Is_Prime_AKS;

end AKS_Primality_Test;
