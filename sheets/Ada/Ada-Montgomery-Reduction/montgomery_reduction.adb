--  Montgomery_Reduction body — REDC, domain conversions, Mont multiply/pow.

pragma Ada_2022;

package body Montgomery_Reduction
  with SPARK_Mode => Off
is

   -------------------------------------------------------------------------
   -- Helpers
   -------------------------------------------------------------------------

   function Abs_LI (X : Long_Integer) return Long_Integer is
   begin
      if X < 0 then
         return -X;
      else
         return X;
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

   function Is_Power_Of_Two (X : Long_Integer) return Boolean is
      V : Long_Integer := X;
   begin
      if X <= 0 then
         return False;
      end if;
      while V rem 2 = 0 loop
         V := V / 2;
      end loop;
      return V = 1;
   end Is_Power_Of_Two;

   function Floor_Log2 (X : Long_Integer) return Natural is
      V : Long_Integer := X;
      K : Natural := 0;
   begin
      if X < 1 then
         raise Invalid_Argument;
      end if;
      while V > 1 loop
         V := V / 2;
         K := K + 1;
      end loop;
      return K;
   end Floor_Log2;

   function Mod_Mul (A, B, N : Long_Integer) return Long_Integer is
   begin
      return Mod_Nonneg (A, N) * Mod_Nonneg (B, N) rem N;
   end Mod_Mul;

   function Mod_Pow
     (Base, Exp, N : Long_Integer) return Long_Integer
   is
      Result : Long_Integer := 1;
      B      : Long_Integer := Mod_Nonneg (Base, N);
      E      : Long_Integer := Exp;
   begin
      if Exp < 0 then
         raise Invalid_Argument;
      end if;
      while E > 0 loop
         if E rem 2 = 1 then
            Result := Mod_Mul (Result, B, N);
         end if;
         B := Mod_Mul (B, B, N);
         E := E / 2;
      end loop;
      return Result;
   end Mod_Pow;

   function Mod_Inverse (A, M : Long_Integer) return Long_Integer is
      --  Iterative extended Euclidean: find X with A*X ≡ 1 (mod M).
      R0  : Long_Integer := Mod_Nonneg (A, M);
      R1  : Long_Integer := M;
      S0  : Long_Integer := 1;
      S1  : Long_Integer := 0;
      Q   : Long_Integer;
      Tmp : Long_Integer;
   begin
      if M <= 1 then
         raise Invalid_Argument;
      end if;
      while R1 /= 0 loop
         Q := R0 / R1;
         Tmp := R0 - Q * R1;
         R0 := R1;
         R1 := Tmp;
         Tmp := S0 - Q * S1;
         S0 := S1;
         S1 := Tmp;
      end loop;
      if Abs_LI (R0) /= 1 then
         raise Invalid_Argument;
      end if;
      if R0 < 0 then
         S0 := -S0;
      end if;
      return Mod_Nonneg (S0, M);
   end Mod_Inverse;

   --  N' = −N^{−1} mod R for odd N and R = 2^R_Bits.
   --  Lift N^{−1} mod 2 → mod R by Newton / Hensel:
   --    inv ← inv · (2 − N · inv)  (mod 2^bits), doubling precision.
   function Compute_N_Prime
     (N      : Long_Integer;
      R      : Long_Integer;
      R_Bits : Natural) return Long_Integer
   is
      Inv     : Long_Integer := 1;
      Bits    : Natural := 1;
      Modulus : Long_Integer;
      Two     : constant Long_Integer := 2;
   begin
      while Bits < R_Bits loop
         Bits := Natural'Min (Bits * 2, R_Bits);
         Modulus := Two ** Bits;
         Inv := Mod_Nonneg (Inv * (Two - Mod_Nonneg (N * Inv, Modulus)),
                            Modulus);
      end loop;
      return Mod_Nonneg (-Inv, R);
   end Compute_N_Prime;

   -------------------------------------------------------------------------
   -- Context
   -------------------------------------------------------------------------

   function Create_Context
     (N      : Long_Integer;
      R_Bits : Natural := Default_R_Bits) return Context
   is
      Ctx : Context;
      R   : Long_Integer;
   begin
      if N <= 1 or else (N rem 2) = 0 then
         raise Invalid_Argument;
      end if;
      if R_Bits = 0 or else R_Bits > Max_R_Bits then
         raise Invalid_Argument;
      end if;
      R := Long_Integer (2) ** R_Bits;
      if R <= N then
         raise Invalid_Argument;
      end if;
      Ctx.N := N;
      Ctx.R := R;
      Ctx.R_Bits := R_Bits;
      Ctx.N_Prime := Compute_N_Prime (N, R, R_Bits);
      Ctx.R_Mod_N := R rem N;
      Ctx.R2_Mod_N := Mod_Mul (Ctx.R_Mod_N, Ctx.R_Mod_N, N);
      return Ctx;
   end Create_Context;

   function Is_Valid_Context (Ctx : Context) return Boolean is
   begin
      if Ctx.N <= 1 or else (Ctx.N rem 2) = 0 then
         return False;
      end if;
      if Ctx.R_Bits = 0 or else Ctx.R_Bits > Max_R_Bits then
         return False;
      end if;
      if Ctx.R /= Long_Integer (2) ** Ctx.R_Bits then
         return False;
      end if;
      if Ctx.R <= Ctx.N then
         return False;
      end if;
      --  N·N' ≡ −1 ≡ R−1 (mod R)
      if Mod_Nonneg (Ctx.N * Ctx.N_Prime, Ctx.R) /= Ctx.R - 1 then
         return False;
      end if;
      if Ctx.R_Mod_N /= Ctx.R rem Ctx.N then
         return False;
      end if;
      if Ctx.R2_Mod_N /= Mod_Mul (Ctx.R_Mod_N, Ctx.R_Mod_N, Ctx.N) then
         return False;
      end if;
      return True;
   end Is_Valid_Context;

   -------------------------------------------------------------------------
   -- REDC
   -------------------------------------------------------------------------

   function REDC
     (Ctx : Context;
      T   : Long_Integer) return Long_Integer
   is
      M : Long_Integer;
      U : Long_Integer;
   begin
      if not Is_Valid_Context (Ctx) then
         raise Invalid_Argument;
      end if;
      if T < 0 then
         raise Invalid_Argument;
      end if;
      --  m ← ((T mod R) · N') mod R
      M := Mod_Nonneg ((T rem Ctx.R) * Ctx.N_Prime, Ctx.R);
      --  t ← (T + m·N) / R   (exact: T + m·N ≡ 0 (mod R))
      U := (T + M * Ctx.N) / Ctx.R;
      if U >= Ctx.N then
         return U - Ctx.N;
      else
         return U;
      end if;
   end REDC;

   -------------------------------------------------------------------------
   -- Conversions / multiply / pow
   -------------------------------------------------------------------------

   function To_Montgomery
     (Ctx : Context;
      A   : Long_Integer) return Long_Integer
   is
   begin
      if not Is_Valid_Context (Ctx) then
         raise Invalid_Argument;
      end if;
      return REDC (Ctx, Mod_Nonneg (A, Ctx.N) * Ctx.R2_Mod_N);
   end To_Montgomery;

   function From_Montgomery
     (Ctx     : Context;
      A_Tilde : Long_Integer) return Long_Integer
   is
   begin
      if not Is_Valid_Context (Ctx) then
         raise Invalid_Argument;
      end if;
      if A_Tilde < 0 then
         raise Invalid_Argument;
      end if;
      return REDC (Ctx, A_Tilde);
   end From_Montgomery;

   function Montgomery_Multiply
     (Ctx              : Context;
      A_Tilde, B_Tilde : Long_Integer) return Long_Integer
   is
   begin
      if not Is_Valid_Context (Ctx) then
         raise Invalid_Argument;
      end if;
      if A_Tilde < 0 or else B_Tilde < 0 then
         raise Invalid_Argument;
      end if;
      return REDC (Ctx, A_Tilde * B_Tilde);
   end Montgomery_Multiply;

   function Montgomery_Pow
     (Ctx  : Context;
      Base : Long_Integer;
      Exp  : Long_Integer) return Long_Integer
   is
      Result : Long_Integer;
      B      : Long_Integer;
      E      : Long_Integer;
   begin
      if not Is_Valid_Context (Ctx) then
         raise Invalid_Argument;
      end if;
      if Exp < 0 then
         raise Invalid_Argument;
      end if;
      --  Montgomery form of 1 is R mod N.
      Result := Ctx.R_Mod_N;
      B := To_Montgomery (Ctx, Base);
      E := Exp;
      while E > 0 loop
         if E rem 2 = 1 then
            Result := Montgomery_Multiply (Ctx, Result, B);
         end if;
         B := Montgomery_Multiply (Ctx, B, B);
         E := E / 2;
      end loop;
      return From_Montgomery (Ctx, Result);
   end Montgomery_Pow;

end Montgomery_Reduction;
