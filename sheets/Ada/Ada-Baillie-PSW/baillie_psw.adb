--  Baillie–PSW primality test — implementation.

pragma Ada_2022;

with Interfaces;

package body Baillie_PSW
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Mul_Mod / Mod_Pow / Gcd
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

   ------------------------------------------------------------------
   --  Residue helpers (signed → mod N, sub, div-by-2)
   ------------------------------------------------------------------

   --  Reduce signed A into 0 .. N−1.
   function Residue (A : I64; N : U64) return U64 is
      use Interfaces;
      NN    : constant Unsigned_128 := Unsigned_128 (N);
      R     : Unsigned_128;
      Abs_A : Unsigned_128;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if A >= 0 then
         R := Unsigned_128 (A) rem NN;
      else
         --  Avoid overflowing I64'First when taking −A.
         if A = I64'First then
            Abs_A := Unsigned_128 (2) ** 63;
         else
            Abs_A := Unsigned_128 (-A);
         end if;
         R := Abs_A rem NN;
         if R /= 0 then
            R := NN - R;
         end if;
      end if;
      return U64 (Unsigned_64 (R));
   end Residue;

   function Sub_Mod (A, B, M : U64) return U64 is
      AA : constant U64 := A rem M;
      BB : constant U64 := B rem M;
   begin
      if AA >= BB then
         return AA - BB;
      else
         return M - (BB - AA);
      end if;
   end Sub_Mod;

   --  (X / 2) mod N for odd N (X already reduced into 0 .. N−1).
   function Div2_Mod (X, N : U64) return U64 is
      use Interfaces;
      XX : Unsigned_128 := Unsigned_128 (X);
   begin
      if (XX and 1) = 1 then
         XX := XX + Unsigned_128 (N);
      end if;
      return U64 (Unsigned_64 (XX / 2));
   end Div2_Mod;

   ------------------------------------------------------------------
   --  Jacobi
   ------------------------------------------------------------------

   function Jacobi (A : I64; N : U64) return Integer is
      AA     : U64;
      NN     : U64 := N;
      Result : Integer := 1;
      Tmp    : U64;
      R      : U64;
   begin
      if N = 0 or else (N and 1) = 0 then
         raise Invalid_Argument;
      end if;

      AA := Residue (A, N);

      while AA /= 0 loop
         while (AA and 1) = 0 loop
            AA := AA / 2;
            R := NN rem 8;
            if R = 3 or else R = 5 then
               Result := -Result;
            end if;
         end loop;

         --  swap
         Tmp := AA;
         AA  := NN;
         NN  := Tmp;

         if (AA rem 4) = 3 and then (NN rem 4) = 3 then
            Result := -Result;
         end if;

         AA := AA rem NN;
      end loop;

      if NN = 1 then
         return Result;
      else
         return 0;
      end if;
   end Jacobi;

   ------------------------------------------------------------------
   --  Is_Perfect_Square (integer Newton / binary search)
   ------------------------------------------------------------------

   function Is_Perfect_Square (N : U64) return Boolean is
      use Interfaces;
      --  Floor sqrt via Newton on Unsigned_128, then check square.
      X    : Unsigned_128;
      Y    : Unsigned_128;
      NN   : constant Unsigned_128 := Unsigned_128 (N);
      Prod : Unsigned_128;
   begin
      if N <= 1 then
         return True;  -- 0 and 1 are squares
      end if;

      --  Initial guess: shift based on bit length
      X := NN;
      Y := (X + 1) / 2;
      while Y < X loop
         X := Y;
         Y := (X + NN / X) / 2;
      end loop;

      Prod := X * X;
      return Prod = NN;
   end Is_Perfect_Square;

   ------------------------------------------------------------------
   --  Is_Strong_PRP_Base_2
   ------------------------------------------------------------------

   function Is_Strong_PRP_Base_2 (N : U64) return Boolean is
      S : Natural := 0;
      D : U64;
      X : U64;
      T : U64;
   begin
      if N < 2 then
         return False;
      end if;
      if N = 2 then
         return True;
      end if;
      if (N and 1) = 0 then
         return False;
      end if;

      --  N − 1 = 2^S · D, D odd
      T := N - 1;
      while (T and 1) = 0 loop
         T := T / 2;
         S := S + 1;
      end loop;
      D := T;

      X := Mod_Pow (2, D, N);
      if X = 1 or else X = N - 1 then
         return True;
      end if;

      for R in 1 .. S - 1 loop
         X := Mul_Mod (X, X, N);
         if X = N - 1 then
            return True;
         end if;
         if X = 1 then
            return False;
         end if;
      end loop;

      return False;
   end Is_Strong_PRP_Base_2;

   ------------------------------------------------------------------
   --  Choose_Selfridge_D
   ------------------------------------------------------------------

   function Choose_Selfridge_D (N : U64) return I64 is
      Abs_D : U64 := 5;
      Sign  : I64 := 1;
      D     : I64;
      J     : Integer;
      G     : U64;
   begin
      if N < 3 or else (N and 1) = 0 then
         raise Invalid_Argument;
      end if;

      loop
         D := Sign * I64 (Abs_D);
         J := Jacobi (D, N);

         if J = -1 then
            return D;
         end if;

         if J = 0 then
            G := Gcd (Abs_D, N);
            if G > 1 and then G < N then
               raise Composite_Signal;
            end if;
         end if;

         Abs_D := Abs_D + 2;
         Sign  := -Sign;

         --  Safety: for a non-square odd N a suitable D always exists
         --  with |D| well below N; abort if the search runs away.
         if Abs_D > N and then Abs_D > 1_000_000 then
            raise Composite_Signal;
         end if;
      end loop;
   end Choose_Selfridge_D;

   ------------------------------------------------------------------
   --  Lucas U_k, V_k, Q^k via binary chain (bits of k, MSB first)
   ------------------------------------------------------------------

   function Add_Mod (A, B, M : U64) return U64 is
      AA : constant U64 := A rem M;
      BB : constant U64 := B rem M;
   begin
      if AA <= M - 1 - BB then
         return AA + BB;
      else
         return AA - (M - BB);
      end if;
   end Add_Mod;

   procedure Lucas_UV_At
     (P, Q, D_Mod, N, K : U64;
      U, V, Qk          : out U64)
   is
      use Interfaces;
      Bit_Index : Natural;
      Mask      : U64;
      U2, V2    : U64;
      Two_Qk    : U64;
   begin
      --  Index 1: U_1 = 1, V_1 = P, Q^1 = Q
      U  := 1;
      V  := P rem N;
      Qk := Q rem N;

      if K <= 1 then
         return;
      end if;

      --  Highest bit position of K (0-based from LSB)
      Bit_Index := 0;
      declare
         T : U64 := K;
      begin
         while T > 1 loop
            T := T / 2;
            Bit_Index := Bit_Index + 1;
         end loop;
      end;

      --  Process bits Bit_Index−1 .. 0 (leading 1 already consumed)
      while Bit_Index > 0 loop
         Bit_Index := Bit_Index - 1;
         Mask := U64 (Shift_Left (Unsigned_64 (1), Bit_Index));

         --  Double: U ← U·V; V ← V² − 2 Q^k; Q^k ← (Q^k)²
         U      := Mul_Mod (U, V, N);
         Two_Qk := Mul_Mod (2, Qk, N);
         V      := Sub_Mod (Mul_Mod (V, V, N), Two_Qk, N);
         Qk     := Mul_Mod (Qk, Qk, N);

         if (K and Mask) /= 0 then
            --  Add one
            U2 := Div2_Mod (Add_Mod (Mul_Mod (P, U, N), V, N), N);
            V2 := Div2_Mod
              (Add_Mod (Mul_Mod (D_Mod, U, N), Mul_Mod (P, V, N), N), N);
            Qk := Mul_Mod (Qk, Q, N);
            U  := U2;
            V  := V2;
         end if;
      end loop;
   end Lucas_UV_At;

   ------------------------------------------------------------------
   --  Is_Strong_Lucas_PRP
   ------------------------------------------------------------------

   function Is_Strong_Lucas_PRP (N : U64; D : I64) return Boolean is
      P     : constant U64 := 1;
      Q_I   : I64;
      Q     : U64;
      D_Mod : U64;
      S     : Natural := 0;
      Od    : U64;  -- odd part of N+1
      U, V, Qk : U64;
      Two_Qk   : U64;
   begin
      if N < 3 or else (N and 1) = 0 then
         return False;
      end if;

      --  Q = (1 − D)/4  (exact in integers; D ≡ 1 (mod 4) for Selfridge)
      Q_I := (1 - D) / 4;
      Q     := Residue (Q_I, N);
      D_Mod := Residue (D, N);

      --  N + 1 = Od · 2^S with Od odd
      if N = U64'Last then
         --  N + 1 = 2^64
         S  := 64;
         Od := 1;
      else
         declare
            T : U64 := N + 1;
         begin
            while (T and 1) = 0 loop
               T := T / 2;
               S := S + 1;
            end loop;
            Od := T;
         end;
      end if;

      Lucas_UV_At (P, Q, D_Mod, N, Od, U, V, Qk);

      if U = 0 then
         return True;  -- U_d ≡ 0
      end if;

      --  Check V_{d · 2^r} ≡ 0 for 0 ≤ r < S
      for R in 0 .. S - 1 loop
         if V = 0 then
            return True;
         end if;
         --  Double for next r (unless last check; still safe to compute)
         U      := Mul_Mod (U, V, N);
         Two_Qk := Mul_Mod (2, Qk, N);
         V      := Sub_Mod (Mul_Mod (V, V, N), Two_Qk, N);
         Qk     := Mul_Mod (Qk, Qk, N);
      end loop;

      return False;
   end Is_Strong_Lucas_PRP;

   ------------------------------------------------------------------
   --  Is_Baillie_PSW_Prime
   ------------------------------------------------------------------

   function Is_Baillie_PSW_Prime (N : U64) return Boolean is
      D : I64;
   begin
      if N < 2 then
         return False;
      end if;
      if N = 2 then
         return True;
      end if;
      if (N and 1) = 0 then
         return False;
      end if;

      --  Perfect squares are never Lucas PRP under Selfridge selection
      if Is_Perfect_Square (N) then
         return False;
      end if;

      if not Is_Strong_PRP_Base_2 (N) then
         return False;
      end if;

      begin
         D := Choose_Selfridge_D (N);
      exception
         when Composite_Signal =>
            return False;
      end;

      return Is_Strong_Lucas_PRP (N, D);
   end Is_Baillie_PSW_Prime;

end Baillie_PSW;
