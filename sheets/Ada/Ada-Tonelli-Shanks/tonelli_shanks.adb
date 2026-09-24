--  Tonelli–Shanks modular square root — implementation.

pragma Ada_2022;

with Interfaces;

package body Tonelli_Shanks
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
   --  Is_Prime_Trial
   ------------------------------------------------------------------

   function Is_Prime_Trial (N : U64) return Boolean is
   begin
      if N < 2 then
         return False;
      end if;
      if N = 2 or else N = 3 then
         return True;
      end if;
      if (N and 1) = 0 then
         return False;
      end if;
      if N rem 3 = 0 then
         return False;
      end if;
      declare
         D : U64 := 5;
      begin
         --  6k±1 wheel; stop when D*D would overflow or exceed N
         while D <= N / D loop
            if N rem D = 0 or else N rem (D + 2) = 0 then
               return False;
            end if;
            D := D + 6;
         end loop;
         return True;
      end;
   end Is_Prime_Trial;

   ------------------------------------------------------------------
   --  Validate_Prime_Modulus
   ------------------------------------------------------------------

   --  P = 2 ok; odd P with educational trial check when ≤ Max_Trial_Prime.
   procedure Validate_Prime_Modulus (P : U64) is
   begin
      if P < 2 then
         raise Invalid_Argument;
      end if;
      if P = 2 then
         return;
      end if;
      if (P and 1) = 0 then
         raise Invalid_Argument;
      end if;
      if P <= Max_Trial_Prime and then not Is_Prime_Trial (P) then
         raise Invalid_Argument;
      end if;
   end Validate_Prime_Modulus;

   ------------------------------------------------------------------
   --  Legendre / Is_Quadratic_Residue / Find_Quadratic_Non_Residue
   ------------------------------------------------------------------

   function Legendre (N, P : U64) return Integer is
      E : U64;
      X : U64;
   begin
      if P < 3 or else (P and 1) = 0 then
         raise Invalid_Argument;
      end if;
      if P <= Max_Trial_Prime and then not Is_Prime_Trial (P) then
         raise Invalid_Argument;
      end if;

      declare
         N_Mod : constant U64 := N rem P;
      begin
         if N_Mod = 0 then
            return 0;
         end if;
         E := (P - 1) / 2;
         X := Mod_Pow (N_Mod, E, P);
         if X = 1 then
            return 1;
         elsif X = P - 1 then
            return -1;
         else
            --  Should not happen for prime P; treat as invalid domain
            raise Invalid_Argument;
         end if;
      end;
   end Legendre;

   function Is_Quadratic_Residue (N, P : U64) return Boolean is
   begin
      Validate_Prime_Modulus (P);
      if P = 2 then
         return True;  -- every class mod 2 is a square
      end if;
      return Legendre (N, P) >= 0;  -- 0 or 1
   end Is_Quadratic_Residue;

   function Find_Quadratic_Non_Residue (P : U64) return U64 is
      Z : U64;
   begin
      Validate_Prime_Modulus (P);
      if P = 2 then
         raise Invalid_Argument;  -- no non-residue mod 2
      end if;
      Z := 2;
      while Z < P loop
         if Legendre (Z, P) = -1 then
            return Z;
         end if;
         Z := Z + 1;
      end loop;
      raise Invalid_Argument;  -- unreachable for odd prime P
   end Find_Quadratic_Non_Residue;

   ------------------------------------------------------------------
   --  Tonelli–Shanks core (odd prime, Legendre = 1, N_Mod ≠ 0)
   ------------------------------------------------------------------

   function Tonelli_Shanks_Odd
     (N_Mod : U64;
      P     : U64) return U64
   is
      Q     : U64;
      S     : Natural := 0;
      Z, C, R, T, B, T2 : U64;
      M, I  : Natural;
      Exp   : Natural;
   begin
      --  Fast path: p ≡ 3 (mod 4)
      if P rem 4 = 3 then
         return Mod_Pow (N_Mod, (P + 1) / 4, P);
      end if;

      --  Write P - 1 = Q * 2^S with Q odd
      Q := P - 1;
      while (Q and 1) = 0 loop
         Q := Q / 2;
         S := S + 1;
      end loop;

      Z := Find_Quadratic_Non_Residue (P);
      M := S;
      C := Mod_Pow (Z, Q, P);
      R := Mod_Pow (N_Mod, (Q + 1) / 2, P);
      T := Mod_Pow (N_Mod, Q, P);

      loop
         if T = 0 then
            return 0;
         end if;
         if T = 1 then
            return R;
         end if;

         --  Least i with 0 < i < M and T^(2^i) ≡ 1 (mod P)
         T2 := T;
         I  := 0;
         for K in 1 .. M - 1 loop
            T2 := Mul_Mod (T2, T2, P);
            if T2 = 1 then
               I := K;
               exit;
            end if;
         end loop;

         if I = 0 then
            --  No such i: should not occur when Legendre = 1
            raise Invalid_Argument;
         end if;

         --  b ← c^(2^(M-i-1))
         Exp := M - I - 1;
         B   := C;
         for K in 1 .. Exp loop
            B := Mul_Mod (B, B, P);
         end loop;
         --  when Exp = 0, B stays C (= c^(2^0))

         R := Mul_Mod (R, B, P);
         C := Mul_Mod (B, B, P);
         T := Mul_Mod (T, C, P);
         M := I;
      end loop;
   end Tonelli_Shanks_Odd;

   ------------------------------------------------------------------
   --  Modular_Sqrt
   ------------------------------------------------------------------

   procedure Modular_Sqrt
     (N     : U64;
      P     : U64;
      Root  : out U64;
      Found : out Boolean)
   is
      N_Mod : U64;
      L     : Integer;
   begin
      Validate_Prime_Modulus (P);

      N_Mod := N rem P;

      if P = 2 then
         Root  := N_Mod;  -- 0^2 ≡ 0, 1^2 ≡ 1 (mod 2)
         Found := True;
         return;
      end if;

      if N_Mod = 0 then
         Root  := 0;
         Found := True;
         return;
      end if;

      L := Legendre (N_Mod, P);
      if L = -1 then
         Root  := 0;
         Found := False;
         return;
      end if;

      --  L = 1 (residue)
      Root  := Tonelli_Shanks_Odd (N_Mod, P);
      Found := True;
   end Modular_Sqrt;

   function Modular_Sqrt (N, P : U64) return U64 is
      Root  : U64;
      Found : Boolean;
   begin
      Modular_Sqrt (N, P, Root, Found);
      if not Found then
         raise Invalid_Argument;
      end if;
      return Root;
   end Modular_Sqrt;

end Tonelli_Shanks;
