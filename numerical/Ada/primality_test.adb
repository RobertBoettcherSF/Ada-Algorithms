--  Primality_Test — implementation (self-contained educational sketches).

pragma Ada_2022;

with Interfaces;

package body Primality_Test
  with SPARK_Mode => Off
is

   type Base_List is array (Positive range <>) of U64;

   Educational_Fermat_Bases : constant Base_List :=
     [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31];

   --  Sufficient for all N < 4_759_123_141 (covers 2^32).
   MR_Small_Bases : constant Base_List := [2, 7, 61];

   Trial_Default_Cutoff : constant U64 := 10_000;

   ------------------------------------------------------------------
   --  Taxonomy
   ------------------------------------------------------------------

   function Method_Name (M : Method_Kind) return String is
   begin
      case M is
         when Trial_Division =>
            return "Trial division";
         when Fermat =>
            return "Fermat";
         when Miller_Rabin =>
            return "Miller–Rabin";
         when Lucas_N_Minus_1 =>
            return "Lucas (N − 1)";
         when Baillie_PSW =>
            return "Baillie–PSW";
         when AKS =>
            return "AKS (tiny hybrid)";
         when Sieve_Eratosthenes_Catalogue =>
            return "Sieve of Eratosthenes (catalogue)";
         when Sieve_Atkin_Catalogue =>
            return "Sieve of Atkin (catalogue)";
         when Solovay_Strassen_Catalogue =>
            return "Solovay–Strassen (catalogue)";
         when Default =>
            return "Default (trial / MR-small)";
      end case;
   end Method_Name;

   function Is_Deterministic (M : Method_Kind) return Boolean is
   begin
      case M is
         when Trial_Division
            | Miller_Rabin
            | Lucas_N_Minus_1
            | AKS
            | Sieve_Eratosthenes_Catalogue
            | Sieve_Atkin_Catalogue
            | Default =>
            return True;
         when Fermat | Baillie_PSW | Solovay_Strassen_Catalogue =>
            return False;
      end case;
   end Is_Deterministic;

   function Is_Probabilistic (M : Method_Kind) return Boolean is
   begin
      case M is
         when Fermat | Baillie_PSW | Solovay_Strassen_Catalogue =>
            return True;
         when others =>
            return False;
      end case;
   end Is_Probabilistic;

   function Is_Proving (M : Method_Kind) return Boolean is
   begin
      case M is
         when Trial_Division
            | Miller_Rabin
            | Lucas_N_Minus_1
            | AKS
            | Sieve_Eratosthenes_Catalogue
            | Sieve_Atkin_Catalogue
            | Default =>
            return True;
         when Fermat | Baillie_PSW | Solovay_Strassen_Catalogue =>
            return False;
      end case;
   end Is_Proving;

   function Is_Implemented (M : Method_Kind) return Boolean is
   begin
      case M is
         when Trial_Division | Fermat | Miller_Rabin | AKS | Default =>
            return True;
         when Lucas_N_Minus_1
            | Baillie_PSW
            | Sieve_Eratosthenes_Catalogue
            | Sieve_Atkin_Catalogue
            | Solovay_Strassen_Catalogue =>
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
   --  Is_Perfect_Square / Is_Perfect_Power
   ------------------------------------------------------------------

   function Isqrt (N : U64) return U64 is
      --  Integer square root via binary search (educational).
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
   end Isqrt;

   function Is_Perfect_Square (N : U64) return Boolean is
      R : U64;
   begin
      R := Isqrt (N);
      return R * R = N;
   end Is_Perfect_Square;

   function Integer_Root (N : U64; K : Natural) return U64 is
      --  Floor of the K-th root of N by binary search (K ≥ 2).
      Lo, Hi, Mid : U64;
      function Pow_U (Base : U64; Exp : Natural) return U64 is
         R : U64 := 1;
         B : U64 := Base;
         E : Natural := Exp;
      begin
         while E > 0 loop
            if E rem 2 = 1 then
               if B /= 0 and then R > U64'Last / B then
                  return U64'Last;  -- overflow sentinel
               end if;
               R := R * B;
            end if;
            E := E / 2;
            if E > 0 then
               if B > Isqrt (U64'Last) then
                  return U64'Last;
               end if;
               B := B * B;
            end if;
         end loop;
         return R;
      end Pow_U;
   begin
      if K < 2 then
         return N;
      end if;
      if N < 2 then
         return N;
      end if;
      Lo := 1;
      Hi := N;
      --  Tighten Hi for large K
      if K >= 2 then
         Hi := Isqrt (N) + 1;
      end if;
      while Lo < Hi loop
         Mid := Lo + (Hi - Lo + 1) / 2;
         declare
            P : constant U64 := Pow_U (Mid, K);
         begin
            if P = U64'Last or else P > N then
               Hi := Mid - 1;
            else
               Lo := Mid;
            end if;
         end;
      end loop;
      return Lo;
   end Integer_Root;

   function Is_Perfect_Power (N : U64) return Boolean is
      Max_Exp : Natural;
      T       : U64;
      Root    : U64;
      P       : U64;
   begin
      if N < 4 then
         return False;
      end if;
      if Is_Perfect_Square (N) then
         return True;
      end if;
      --  Max useful exponent: 2^Max_Exp ≤ N → Max_Exp ≤ floor(log2 N)
      Max_Exp := 1;
      T := N;
      while T > 1 loop
         T := T / 2;
         Max_Exp := Max_Exp + 1;
      end loop;
      for K in 3 .. Max_Exp loop
         Root := Integer_Root (N, K);
         if Root >= 2 then
            --  Check Root^K = N without wrapping when possible
            P := 1;
            declare
               Ok : Boolean := True;
            begin
               for I in 1 .. K loop
                  if P > U64'Last / Root then
                     Ok := False;
                     exit;
                  end if;
                  P := P * Root;
               end loop;
               if Ok and then P = N then
                  return True;
               end if;
            end;
         end if;
      end loop;
      return False;
   end Is_Perfect_Power;

   ------------------------------------------------------------------
   --  Trial_Division_Is_Prime
   ------------------------------------------------------------------

   function Trial_Division_Is_Prime (N : U64) return Boolean is
      D   : U64;
      Lim : U64;
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
      Lim := Isqrt (N);
      D := 5;
      while D <= Lim loop
         if N rem D = 0 then
            return False;
         end if;
         if D + 2 <= Lim and then N rem (D + 2) = 0 then
            return False;
         end if;
         if D > U64'Last - 6 then
            exit;
         end if;
         D := D + 6;
      end loop;
      return True;
   end Trial_Division_Is_Prime;

   ------------------------------------------------------------------
   --  Fermat_Probable_Prime
   ------------------------------------------------------------------

   function Is_Fermat_Witness (N, A : U64) return Boolean is
      A_Mod : U64;
      D     : U64;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      if N = 2 then
         return False;
      end if;
      if (N and 1) = 0 then
         return True;
      end if;
      A_Mod := A rem N;
      if A_Mod = 0 then
         return False;
      end if;
      D := Gcd (A_Mod, N);
      if D > 1 then
         return True;  -- proper factor
      end if;
      return Mod_Pow (A_Mod, N - 1, N) /= 1;
   end Is_Fermat_Witness;

   function Fermat_Probable_Prime
     (N      : U64;
      Rounds : Positive := 3) return Boolean
   is
      Used  : Natural := 0;
      Limit : Natural;
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
      Limit := Natural (Rounds);
      if Limit > Educational_Fermat_Bases'Length then
         Limit := Educational_Fermat_Bases'Length;
      end if;
      for I in Educational_Fermat_Bases'Range loop
         exit when Used >= Limit;
         declare
            A : constant U64 := Educational_Fermat_Bases (I);
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
   end Fermat_Probable_Prime;

   ------------------------------------------------------------------
   --  Miller–Rabin deterministic-small
   ------------------------------------------------------------------

   procedure Split_N_Minus_1
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
   end Split_N_Minus_1;

   function Is_MR_Composite_Witness (N, A : U64) return Boolean is
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
         return True;
      end if;
      A_Mod := A rem N;
      if A_Mod = 0 then
         return False;
      end if;
      if A_Mod = 1 or else A_Mod = N - 1 then
         return False;
      end if;
      Split_N_Minus_1 (N, S, D);
      X := Mod_Pow (A_Mod, D, N);
      if X = 1 or else X = N - 1 then
         return False;
      end if;
      for R in 1 .. S - 1 loop
         X := Mul_Mod (X, X, N);
         if X = N - 1 then
            return False;
         end if;
         if X = 1 then
            return True;
         end if;
      end loop;
      return True;
   end Is_MR_Composite_Witness;

   function Miller_Rabin_Deterministic_Small (N : U64) return Boolean is
   begin
      if N > MR_Small_Max then
         raise Invalid_Argument;
      end if;
      if N < 2 then
         return False;
      end if;
      if N = 2 or else N = 3 then
         return True;
      end if;
      if (N and 1) = 0 then
         return False;
      end if;
      for A of MR_Small_Bases loop
         if A < N and then Is_MR_Composite_Witness (N, A) then
            return False;
         end if;
      end loop;
      return True;
   end Miller_Rabin_Deterministic_Small;

   ------------------------------------------------------------------
   --  AKS_Is_Prime_Tiny
   ------------------------------------------------------------------

   function AKS_Is_Prime_Tiny (N : U64) return Boolean is
   begin
      if N > AKS_Tiny_Max then
         raise Invalid_Argument;
      end if;
      if N < 2 then
         return False;
      end if;
      --  AKS step 1 (sketch): perfect power → composite
      if Is_Perfect_Power (N) then
         return False;
      end if;
      --  Remaining steps replaced by trial division on the tiny domain
      return Trial_Division_Is_Prime (N);
   end AKS_Is_Prime_Tiny;

   ------------------------------------------------------------------
   --  Is_Prime_Default / Is_Prime dispatcher
   ------------------------------------------------------------------

   function Is_Prime_Default (N : U64) return Boolean is
   begin
      if N > MR_Small_Max then
         raise Invalid_Argument;
      end if;
      if N <= Trial_Default_Cutoff then
         return Trial_Division_Is_Prime (N);
      else
         return Miller_Rabin_Deterministic_Small (N);
      end if;
   end Is_Prime_Default;

   function Is_Prime (N : U64; Method : Method_Kind) return Boolean is
   begin
      case Method is
         when Trial_Division =>
            return Trial_Division_Is_Prime (N);
         when Fermat =>
            return Fermat_Probable_Prime (N);
         when Miller_Rabin =>
            return Miller_Rabin_Deterministic_Small (N);
         when AKS =>
            return AKS_Is_Prime_Tiny (N);
         when Default =>
            return Is_Prime_Default (N);
         when Lucas_N_Minus_1
            | Baillie_PSW
            | Sieve_Eratosthenes_Catalogue
            | Sieve_Atkin_Catalogue
            | Solovay_Strassen_Catalogue =>
            raise Invalid_Argument;
      end case;
   end Is_Prime;

end Primality_Test;
