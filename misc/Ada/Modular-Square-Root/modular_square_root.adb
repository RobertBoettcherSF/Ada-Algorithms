--  Modular_Square_Root — implementation (self-contained educational sketches).

pragma Ada_2022;

with Interfaces;

package body Modular_Square_Root
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Taxonomy
   ------------------------------------------------------------------

   function Method_Name (M : Method_Kind) return String is
   begin
      case M is
         when Tonelli_Shanks =>
            return "Tonelli–Shanks";
         when Cipolla =>
            return "Cipolla (catalogue / sibling)";
         when P_Congruent_3_Mod_4 =>
            return "p ≡ 3 (mod 4) fast path";
         when Brute_Force =>
            return "Brute force (tiny modulus)";
         when Catalogue_Composite_CRT =>
            return "Composite CRT / Hensel (catalogue)";
      end case;
   end Method_Name;

   function Is_Implemented (M : Method_Kind) return Boolean is
   begin
      case M is
         when Tonelli_Shanks | P_Congruent_3_Mod_4 | Brute_Force =>
            return True;
         when Cipolla | Catalogue_Composite_CRT =>
            return False;
      end case;
   end Is_Implemented;

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
   --  Legendre / Is_Quadratic_Residue_Prime / Find_Quadratic_Non_Residue
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
            raise Invalid_Argument;
         end if;
      end;
   end Legendre;

   function Is_Quadratic_Residue_Prime (N, P : U64) return Boolean is
   begin
      Validate_Prime_Modulus (P);
      if P = 2 then
         return True;
      end if;
      return Legendre (N, P) >= 0;
   end Is_Quadratic_Residue_Prime;

   function Find_Quadratic_Non_Residue (P : U64) return U64 is
      Z : U64;
   begin
      Validate_Prime_Modulus (P);
      if P = 2 then
         raise Invalid_Argument;
      end if;
      Z := 2;
      while Z < P loop
         if Legendre (Z, P) = -1 then
            return Z;
         end if;
         Z := Z + 1;
      end loop;
      raise Invalid_Argument;
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
            raise Invalid_Argument;
         end if;

         Exp := M - I - 1;
         B   := C;
         for K in 1 .. Exp loop
            B := Mul_Mod (B, B, P);
         end loop;

         R := Mul_Mod (R, B, P);
         C := Mul_Mod (B, B, P);
         T := Mul_Mod (T, C, P);
         M := I;
      end loop;
   end Tonelli_Shanks_Odd;

   ------------------------------------------------------------------
   --  Sqrt_Mod_Prime
   ------------------------------------------------------------------

   procedure Sqrt_Mod_Prime
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
         Root  := N_Mod;
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

      Root  := Tonelli_Shanks_Odd (N_Mod, P);
      Found := True;
   end Sqrt_Mod_Prime;

   function Sqrt_Mod_Prime (N, P : U64) return U64 is
      Root  : U64;
      Found : Boolean;
   begin
      Sqrt_Mod_Prime (N, P, Root, Found);
      if not Found then
         raise Invalid_Argument;
      end if;
      return Root;
   end Sqrt_Mod_Prime;

   ------------------------------------------------------------------
   --  Sqrt_P_Congruent_3_Mod_4
   ------------------------------------------------------------------

   procedure Sqrt_P_Congruent_3_Mod_4
     (N     : U64;
      P     : U64;
      Root  : out U64;
      Found : out Boolean)
   is
      N_Mod : U64;
      L     : Integer;
   begin
      Validate_Prime_Modulus (P);
      if P = 2 or else P rem 4 /= 3 then
         raise Invalid_Argument;
      end if;

      N_Mod := N rem P;
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

      Root  := Mod_Pow (N_Mod, (P + 1) / 4, P);
      Found := True;
   end Sqrt_P_Congruent_3_Mod_4;

   ------------------------------------------------------------------
   --  Sqrt_Tonelli_Shanks (odd primes; P=2 via Validate then dispatch)
   ------------------------------------------------------------------

   procedure Sqrt_Tonelli_Shanks
     (N     : U64;
      P     : U64;
      Root  : out U64;
      Found : out Boolean)
   is
   begin
      --  Same educational entry as Sqrt_Mod_Prime (includes fast path).
      Sqrt_Mod_Prime (N, P, Root, Found);
   end Sqrt_Tonelli_Shanks;

   ------------------------------------------------------------------
   --  Brute_Force_Sqrt
   ------------------------------------------------------------------

   procedure Brute_Force_Sqrt
     (N     : U64;
      M     : U64;
      Root  : out U64;
      Found : out Boolean)
   is
      N_Mod : U64;
      X     : U64;
   begin
      if M = 0 or else M > Max_Brute_Modulus then
         raise Invalid_Argument;
      end if;
      N_Mod := N rem M;
      X     := 0;
      while X < M loop
         if Mul_Mod (X, X, M) = N_Mod then
            Root  := X;
            Found := True;
            return;
         end if;
         X := X + 1;
      end loop;
      Root  := 0;
      Found := False;
   end Brute_Force_Sqrt;

   ------------------------------------------------------------------
   --  Mod_Inv / Combine_Roots_CRT
   ------------------------------------------------------------------

   function Mod_Inv (A, M : U64) return U64 is
      --  Extended Euclidean with Long_Long_Integer Bézout coeffs
      --  (educational CRT: M fits comfortably in signed 64-bit).
      R0, R1 : U64;
      S0, S1 : Long_Long_Integer;
      Quot   : U64;
      Tmp_R  : U64;
      Tmp_S  : Long_Long_Integer;
      A_Mod  : U64;
   begin
      if M = 0 then
         raise Invalid_Argument;
      end if;
      if M > U64 (Long_Long_Integer'Last) then
         raise Invalid_Argument;
      end if;
      A_Mod := A rem M;
      if A_Mod = 0 then
         raise Invalid_Argument;
      end if;

      R0 := M;
      R1 := A_Mod;
      S0 := 0;
      S1 := 1;

      while R1 /= 0 loop
         Quot  := R0 / R1;
         Tmp_R := R0 - Quot * R1;
         R0    := R1;
         R1    := Tmp_R;
         Tmp_S := S0 - Long_Long_Integer (Quot) * S1;
         S0    := S1;
         S1    := Tmp_S;
      end loop;

      if R0 /= 1 then
         raise Invalid_Argument;
      end if;

      if S0 < 0 then
         return U64 (Long_Long_Integer (M) + S0);
      else
         return U64 (S0);
      end if;
   end Mod_Inv;

   function Combine_Roots_CRT (Rp, P, Rq, Q : U64) return U64 is
      use Interfaces;
      PP, QQ, Prod : Unsigned_128;
      Inv_P_Mod_Q  : U64;
      T            : U64;
      Diff         : U64;
      Result       : U64;
   begin
      if P = 0 or else Q = 0 then
         raise Invalid_Argument;
      end if;
      if Gcd (P, Q) /= 1 then
         raise Invalid_Argument;
      end if;

      PP   := Unsigned_128 (P);
      QQ   := Unsigned_128 (Q);
      Prod := PP * QQ;
      if Prod > Unsigned_128 (U64'Last) then
         raise Invalid_Argument;
      end if;

      --  Classic CRT: R = Rp + P * ((Rq - Rp) * P^{-1} mod Q) mod (P*Q)
      Inv_P_Mod_Q := Mod_Inv (P, Q);
      Diff := (Rq rem Q + Q - (Rp rem P) rem Q) rem Q;
      T    := Mul_Mod (Diff, Inv_P_Mod_Q, Q);
      Result :=
        U64
          (Unsigned_64
             ((Unsigned_128 (Rp rem P)
               + Unsigned_128 (P) * Unsigned_128 (T))
              rem Prod));
      return Result;
   end Combine_Roots_CRT;

end Modular_Square_Root;
