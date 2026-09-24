--  Miller–Rabin primality test — implementation.

pragma Ada_2022;

with Interfaces;

package body Miller_Rabin
  with SPARK_Mode => Off
is

   type Base_List is array (Positive range <>) of U64;

   ------------------------------------------------------------------
   --  Educational fixed bases (not a CSPRNG)
   ------------------------------------------------------------------

   --  Wikipedia sufficient set for all N < 2^64, plus a few extra primes
   --  for Is_Probable_Prime rounds beyond 12.
   Educational_Bases : constant Base_List :=
     [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53,
      59, 61, 67, 71, 73, 79, 83, 89, 97];

   Deterministic_64_Bases : constant Base_List :=
     [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37];

   ------------------------------------------------------------------
   --  Mul_Mod / Mod_Pow
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

   ------------------------------------------------------------------
   --  Trial_Split_N_Minus_1
   ------------------------------------------------------------------

   procedure Trial_Split_N_Minus_1
     (N : U64;
      S : out Natural;
      D : out U64)
   is
      T : U64;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      T := N - 1;
      S := 0;
      while (T and 1) = 0 loop
         T := T / 2;
         S := S + 1;
      end loop;
      D := T;
   end Trial_Split_N_Minus_1;

   ------------------------------------------------------------------
   --  Is_Composite_Witness
   ------------------------------------------------------------------

   function Is_Composite_Witness (N, A : U64) return Boolean is
      S     : Natural;
      D     : U64;
      X     : U64;
      A_Mod : U64;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;

      if N = 2 then
         return False;
      end if;

      if (N and 1) = 0 then
         return True;  -- even > 2
      end if;

      A_Mod := A rem N;
      if A_Mod = 0 then
         --  gcd (A, N) = N: not a valid witness base for the congruence test
         return False;
      end if;
      if A_Mod = 1 or else A_Mod = N - 1 then
         return False;  -- trivial strong probable-prime bases
      end if;

      Trial_Split_N_Minus_1 (N, S, D);
      X := Mod_Pow (A_Mod, D, N);

      if X = 1 or else X = N - 1 then
         return False;  -- witness pass
      end if;

      --  Square up to S − 1 times looking for N − 1
      for R in 1 .. S - 1 loop
         X := Mul_Mod (X, X, N);
         if X = N - 1 then
            return False;  -- pass
         end if;
         if X = 1 then
            return True;   -- nontrivial square root of 1 → composite
         end if;
      end loop;

      return True;  -- never saw N − 1 → composite
   end Is_Composite_Witness;

   ------------------------------------------------------------------
   --  Shared runner over a base list
   ------------------------------------------------------------------

   function Passes_Bases
     (N     : U64;
      Bases : Base_List;
      Limit : Natural) return Boolean
   is
      Used : Natural := 0;
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

      for I in Bases'Range loop
         exit when Used >= Limit;
         declare
            A : constant U64 := Bases (I);
         begin
            if A < N then
               Used := Used + 1;
               if Is_Composite_Witness (N, A) then
                  return False;
               end if;
            end if;
         end;
      end loop;
      return True;
   end Passes_Bases;

   function Min_Natural (A, B : Natural) return Natural is
   begin
      if A <= B then
         return A;
      else
         return B;
      end if;
   end Min_Natural;

   ------------------------------------------------------------------
   --  Is_Probable_Prime / Is_Prime_Deterministic_64
   ------------------------------------------------------------------

   function Is_Probable_Prime
     (N      : U64;
      Rounds : Positive := 8) return Boolean
   is
      K : constant Natural :=
        Min_Natural (Natural (Rounds), Educational_Bases'Length);
   begin
      return Passes_Bases (N, Educational_Bases, K);
   end Is_Probable_Prime;

   function Is_Prime_Deterministic_64 (N : U64) return Boolean is
   begin
      return Passes_Bases
        (N, Deterministic_64_Bases, Deterministic_64_Bases'Length);
   end Is_Prime_Deterministic_64;

end Miller_Rabin;
