--  Pollard's p−1 — Ada 2023 implementation (Stage 1).

pragma Ada_2022;

with Interfaces;

package body Pollards_P_1
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Helpers
   ------------------------------------------------------------------

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

   function Floor_Sqrt (N : U64) return U64 is
      Lo, Hi, Mid : U64;
   begin
      if N < 2 then
         return N;
      end if;
      Lo := 1;
      Hi := N / 2 + 1;
      while Lo < Hi loop
         Mid := Lo + (Hi - Lo + 1) / 2;
         if Mid > N / Mid then
            Hi := Mid - 1;
         else
            Lo := Mid;
         end if;
      end loop;
      return Lo;
   end Floor_Sqrt;

   function Is_Prime_Trial (N : U64) return Boolean is
      D : U64;
   begin
      if N < 2 then
         return False;
      end if;
      if N = 2 or else N = 3 then
         return True;
      end if;
      if N rem 2 = 0 or else N rem 3 = 0 then
         return False;
      end if;
      D := 5;
      while D <= N / D loop
         if N rem D = 0 or else N rem (D + 2) = 0 then
            return False;
         end if;
         D := D + 6;
      end loop;
      return True;
   end Is_Prime_Trial;

   function Primes_Up_To (Limit : U64) return U64_Array is
      Count : Natural := 0;
   begin
      if Limit < 2 then
         declare
            Empty : U64_Array (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      for C in U64 range 2 .. Limit loop
         if Is_Prime_Trial (C) then
            Count := Count + 1;
         end if;
      end loop;

      declare
         Result : U64_Array (1 .. Count);
         I      : Natural := 0;
      begin
         for C in U64 range 2 .. Limit loop
            if Is_Prime_Trial (C) then
               I := I + 1;
               Result (I) := C;
            end if;
         end loop;
         return Result;
      end;
   end Primes_Up_To;

   --  gcd(R − 1, N) with modular residue R = a^M mod N.
   function Gcd_R_Minus_1 (R, N : U64) return U64 is
   begin
      if R = 0 then
         return Gcd (N - 1, N);
      elsif R = 1 then
         return N;
      else
         return Gcd (R - 1, N);
      end if;
   end Gcd_R_Minus_1;


   --  Single Stage-1 pass at a fixed bound (no g=N retry).
   --  Returns nontrivial factor, 1 (miss), or N (all factors smooth).
   --  Raises the residue by each prime p repeatedly (a <- a^p) up to
   --  the highest p^k <= Bound, checking gcd after every raise so that
   --  unequal orders mod different factors can split before g = N.
   function Stage1_Once
     (N, Bound, Base : U64) return U64
   is
      A  : U64 := Base rem N;
      G  : U64;
      PP : U64;
   begin
      if A = 0 then
         return 1;
      end if;

      G := Gcd (A, N);
      if G > 1 and then G < N then
         return G;
      end if;

      declare
         Primes : constant U64_Array := Primes_Up_To (Bound);
      begin
         for P of Primes loop
            PP := P;
            loop
               A := Mod_Pow (A, P, N);
               G := Gcd_R_Minus_1 (A, N);
               if G > 1 and then G < N then
                  return G;
               end if;
               if G = N then
                  return N;
               end if;
               exit when PP > Bound / P;
               PP := PP * P;
            end loop;
         end loop;
      end;

      return Gcd_R_Minus_1 (A, N);
   end Stage1_Once;

   ------------------------------------------------------------------
   --  Stage 1
   ------------------------------------------------------------------

   function Factor_Stage1
     (N    : U64;
      B    : U64;
      Base : U64 := 2) return U64
   is
      Bound : U64;
      G     : U64;
   begin
      if N < 2 or else B < 2 then
         raise Invalid_Argument;
      end if;

      if N rem 2 = 0 then
         return 2;
      end if;

      if Is_Prime_Trial (N) then
         return 1;
      end if;

      --  First try the requested bound.
      G := Stage1_Once (N, B, Base);
      if G > 1 and then G < N then
         return G;
      end if;
      if G = 1 then
         return 1;
      end if;

      --  G = N: every prime factor looks B-powersmooth. Wikipedia:
      --  select a smaller B. Scan B-1 .. 2 for a split (educational).
      Bound := B - 1;
      while Bound >= 2 loop
         G := Stage1_Once (N, Bound, Base);
         if G > 1 and then G < N then
            return G;
         end if;
         Bound := Bound - 1;
      end loop;
      return 1;
   end Factor_Stage1;

   ------------------------------------------------------------------
   --  Multi-base Factor
   ------------------------------------------------------------------

   function Factor
     (N : U64;
      B : U64 := Default_B) return U64
   is
      Bases : constant U64_Array :=
        [2, 3, 5, 7, 11, 13, 17, 19, 23];
      F : U64;
   begin
      if N < 2 or else B < 2 then
         raise Invalid_Argument;
      end if;

      if N rem 2 = 0 then
         return 2;
      end if;

      if Is_Prime_Trial (N) then
         return 1;
      end if;

      for Base of Bases loop
         F := Factor_Stage1 (N, B, Base);
         if F > 1 and then F < N then
            return F;
         end if;
      end loop;
      return 1;
   end Factor;

end Pollards_P_1;
