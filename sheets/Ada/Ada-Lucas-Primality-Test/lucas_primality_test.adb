--  Lucas primality test — implementation.

pragma Ada_2022;

with Interfaces;

package body Lucas_Primality_Test
  with SPARK_Mode => Off
is

   --  Upper bound on bases tried by Find_Lucas_Witness (educational).
   Max_Witness_Search : constant U64 := 10_000;

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
   --  Factors_Of_N_Minus_1
   ------------------------------------------------------------------

   function Factors_Of_N_Minus_1 (N : U64) return Factor_List is
      Max_Factors : constant := 64;
      Buf         : array (1 .. Max_Factors) of U64;
      Count       : Natural := 0;
      M           : U64;
      D           : U64;
   begin
      if N < 2 or else N > Max_Auto_N then
         raise Invalid_Argument;
      end if;

      if N = 2 then
         declare
            Empty : Factor_List (1 .. 0);
         begin
            return Empty;
         end;
      end if;

      M := N - 1;

      --  Factor out 2
      if (M and 1) = 0 then
         Count := Count + 1;
         Buf (Count) := 2;
         while (M and 1) = 0 loop
            M := M / 2;
         end loop;
      end if;

      --  Odd trial factors
      D := 3;
      while D * D <= M loop
         if M rem D = 0 then
            Count := Count + 1;
            if Count > Max_Factors then
               raise Invalid_Argument;
            end if;
            Buf (Count) := D;
            while M rem D = 0 loop
               M := M / D;
            end loop;
         end if;
         D := D + 2;
      end loop;

      if M > 1 then
         Count := Count + 1;
         if Count > Max_Factors then
            raise Invalid_Argument;
         end if;
         Buf (Count) := M;
      end if;

      declare
         Result : Factor_List (1 .. Count);
      begin
         for I in 1 .. Count loop
            Result (I) := Buf (I);
         end loop;
         return Result;
      end;
   end Factors_Of_N_Minus_1;

   ------------------------------------------------------------------
   --  Validate Factors divide N − 1
   ------------------------------------------------------------------

   procedure Check_Factors (N : U64; Factors : Factor_List) is
      Nm1 : constant U64 := N - 1;
   begin
      if Factors'Length = 0 then
         raise Invalid_Argument;
      end if;
      for Q of Factors loop
         if Q < 2 or else Nm1 rem Q /= 0 then
            raise Invalid_Argument;
         end if;
      end loop;
   end Check_Factors;

   ------------------------------------------------------------------
   --  Lucas_Witness
   ------------------------------------------------------------------

   function Lucas_Witness
     (N       : U64;
      A       : U64;
      Factors : Factor_List) return Boolean
   is
      Nm1 : U64;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;

      if N = 2 then
         return False;  -- no base with 1 < A < 2
      end if;

      if (N and 1) = 0 then
         return False;  -- even > 2: not prime; no certificate
      end if;

      Check_Factors (N, Factors);

      if A <= 1 or else A >= N then
         return False;
      end if;

      Nm1 := N - 1;

      --  A^{N−1} ≡ 1 (mod N)
      if Mod_Pow (A, Nm1, N) /= 1 then
         return False;
      end if;

      --  For every prime factor Q of N − 1: A^{(N−1)/Q} ≢ 1 (mod N)
      for Q of Factors loop
         if Mod_Pow (A, Nm1 / Q, N) = 1 then
            return False;
         end if;
      end loop;

      return True;
   end Lucas_Witness;

   ------------------------------------------------------------------
   --  Find_Lucas_Witness
   ------------------------------------------------------------------

   function Find_Lucas_Witness
     (N       : U64;
      Factors : Factor_List) return U64
   is
      Limit : U64;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;

      if N = 2 then
         return 0;
      end if;

      if (N and 1) = 0 then
         Check_Factors (N, Factors);  -- still validate when caller asks
         return 0;
      end if;

      Check_Factors (N, Factors);

      Limit := N - 1;
      if Limit > Max_Witness_Search then
         Limit := Max_Witness_Search;
      end if;

      declare
         A : U64 := 2;
      begin
         while A <= Limit loop
            if Lucas_Witness (N, A, Factors) then
               return A;
            end if;
            A := A + 1;
         end loop;
      end;

      return 0;
   end Find_Lucas_Witness;

   ------------------------------------------------------------------
   --  Is_Prime_Lucas
   ------------------------------------------------------------------

   function Is_Prime_Lucas
     (N       : U64;
      Factors : Factor_List) return Boolean
   is
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;

      if N = 2 then
         return True;
      end if;

      if (N and 1) = 0 then
         return False;
      end if;

      return Find_Lucas_Witness (N, Factors) /= 0;
   end Is_Prime_Lucas;

   ------------------------------------------------------------------
   --  Is_Prime_Lucas_Auto
   ------------------------------------------------------------------

   function Is_Prime_Lucas_Auto (N : U64) return Boolean is
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

      if N > Max_Auto_N then
         raise Invalid_Argument;
      end if;

      declare
         Factors : constant Factor_List := Factors_Of_N_Minus_1 (N);
      begin
         return Is_Prime_Lucas (N, Factors);
      end;
   end Is_Prime_Lucas_Auto;

end Lucas_Primality_Test;
