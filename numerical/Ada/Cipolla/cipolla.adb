--  Cipolla's algorithm — implementation (Fp2 mul / Mod_Pow in the ring).

pragma Ada_2022;

with Interfaces;

package body Cipolla
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
   --  Legendre / Is_Quadratic_Residue
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

   ------------------------------------------------------------------
   --  Fp2 = Fp[ω] with ω² = W2 = Omega² − N (quadratic non-residue)
   --  Elements are X + Y·√W2 represented as (X, Y).
   ------------------------------------------------------------------

   type Fp2 is record
      X : U64 := 0;
      Y : U64 := 0;
   end record;

   --  (X1 + Y1√W2)(X2 + Y2√W2)
   --    = (X1 X2 + Y1 Y2 W2) + (X1 Y2 + Y1 X2) √W2
   function Mul_Fp2 (A, B : Fp2; W2, P : U64) return Fp2 is
      RX, RY : U64;
   begin
      RX := Mul_Mod (A.X, B.X, P);
      RX := (RX + Mul_Mod (Mul_Mod (A.Y, B.Y, P), W2, P)) rem P;
      RY := Mul_Mod (A.X, B.Y, P);
      RY := (RY + Mul_Mod (A.Y, B.X, P)) rem P;
      return (X => RX, Y => RY);
   end Mul_Fp2;

   --  Binary exponentiation in Fp2.
   function Mod_Pow_Fp2 (Base : Fp2; Exp : U64; W2, P : U64) return Fp2 is
      Result : Fp2 := (X => 1, Y => 0);
      B      : Fp2 := Base;
      E      : U64 := Exp;
   begin
      while E > 0 loop
         if (E and 1) = 1 then
            Result := Mul_Fp2 (Result, B, W2, P);
         end if;
         B := Mul_Fp2 (B, B, W2, P);
         E := E / 2;
      end loop;
      return Result;
   end Mod_Pow_Fp2;

   ------------------------------------------------------------------
   --  Find_Omega (Cipolla step 1)
   ------------------------------------------------------------------

   function Find_Omega (N, P : U64) return U64 is
      N_Mod : U64;
      Omega  : U64;
      Diff   : U64;
   begin
      Validate_Prime_Modulus (P);
      if P = 2 then
         raise Invalid_Argument;
      end if;
      N_Mod := N rem P;
      if N_Mod = 0 or else Legendre (N_Mod, P) /= 1 then
         raise Invalid_Argument;
      end if;

      Omega := 0;
      while Omega < P loop
         --  Diff = Omega² − N (mod P)
         Diff := Mul_Mod (Omega, Omega, P);
         if Diff >= N_Mod then
            Diff := Diff - N_Mod;
         else
            Diff := Diff + P - N_Mod;
         end if;
         if Legendre (Diff, P) = -1 then
            return Omega;
         end if;
         Omega := Omega + 1;
      end loop;
      raise Invalid_Argument;  -- unreachable for odd prime + residue
   end Find_Omega;

   ------------------------------------------------------------------
   --  Cipolla core (odd prime, Legendre = 1, N_Mod ≠ 0)
   ------------------------------------------------------------------

   function Cipolla_Odd (N_Mod, P : U64) return U64 is
      Omega : constant U64 := Find_Omega (N_Mod, P);
      W2    : U64;
      Base  : Fp2;
      Pow   : Fp2;
   begin
      --  W2 = Omega² − N (mod P)
      W2 := Mul_Mod (Omega, Omega, P);
      if W2 >= N_Mod then
         W2 := W2 - N_Mod;
      else
         W2 := W2 + P - N_Mod;
      end if;

      --  Base = Omega + 1·√W2 ; raise to (P+1)/2
      Base := (X => Omega, Y => 1);
      Pow  := Mod_Pow_Fp2 (Base, (P + 1) / 2, W2, P);

      --  Result is in Fp: Pow.Y must be 0; Pow.X is the root
      return Pow.X;
   end Cipolla_Odd;

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

      --  L = 1 (residue): Cipolla via Fp2
      Root  := Cipolla_Odd (N_Mod, P);
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

end Cipolla;
