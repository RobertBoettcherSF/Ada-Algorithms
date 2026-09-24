--  Fermat primality test — implementation.

pragma Ada_2022;

with Interfaces;

package body Fermat_Primality_Test
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Educational fixed bases (not a CSPRNG)
   ------------------------------------------------------------------

   Educational_Bases : constant Base_List :=
     [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53,
      59, 61, 67, 71, 73, 79, 83, 89, 97];

   --  Small known Carmichael numbers for classroom demos.
   Carmichael_Examples : constant Base_List :=
     [561, 1105, 1729, 2465, 2821, 6601, 8911];

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
   --  Is_Fermat_Witness
   ------------------------------------------------------------------

   function Is_Fermat_Witness (N, A : U64) return Boolean is
      D     : U64;
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
         --  gcd (A, N) = N: base not usable for the congruence test
         return False;
      end if;

      D := Gcd (A_Mod, N);
      if D > 1 then
         --  1 < gcd < N: proper common factor → composite (broad witness)
         return True;
      end if;

      --  Classical Fermat witness: A^{N−1} ≢ 1 (mod N)
      return Mod_Pow (A_Mod, N - 1, N) /= 1;
   end Is_Fermat_Witness;

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
               if Is_Fermat_Witness (N, A) then
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
   --  Is_Fermat_Probable_Prime
   ------------------------------------------------------------------

   function Is_Fermat_Probable_Prime
     (N      : U64;
      Rounds : Positive := 8) return Boolean
   is
      K : constant Natural :=
        Min_Natural (Natural (Rounds), Educational_Bases'Length);
   begin
      return Passes_Bases (N, Educational_Bases, K);
   end Is_Fermat_Probable_Prime;

   function Is_Fermat_Probable_Prime
     (N     : U64;
      Bases : Base_List) return Boolean
   is
   begin
      return Passes_Bases (N, Bases, Bases'Length);
   end Is_Fermat_Probable_Prime;

   ------------------------------------------------------------------
   --  Is_Carmichael_Example
   ------------------------------------------------------------------

   function Is_Carmichael_Example (N : U64) return Boolean is
   begin
      for C of Carmichael_Examples loop
         if N = C then
            return True;
         end if;
      end loop;
      return False;
   end Is_Carmichael_Example;

end Fermat_Primality_Test;
