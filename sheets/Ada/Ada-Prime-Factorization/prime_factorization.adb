--  Prime_Factorization — implementation (self-contained educational sketches).

pragma Ada_2022;

with Interfaces;

package body Prime_Factorization
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Taxonomy
   ------------------------------------------------------------------

   function Method_Name (M : Method_Kind) return String is
   begin
      case M is
         when Trial_Division =>
            return "Trial division";
         when Fermat =>
            return "Fermat factorization";
         when Pollard_Rho =>
            return "Pollard's rho";
         when Pollard_P1 =>
            return "Pollard's p − 1 (catalogue)";
         when Quadratic_Sieve =>
            return "Quadratic sieve (catalogue)";
         when SNFS =>
            return "Special number field sieve (catalogue)";
         when GNFS =>
            return "General number field sieve (catalogue)";
         when ECM =>
            return "Elliptic curve method (catalogue)";
         when Shor_Catalogue =>
            return "Shor's algorithm (catalogue)";
         when Default =>
            return "Default (trial / rho hybrid)";
      end case;
   end Method_Name;

   function Is_Special_Purpose (M : Method_Kind) return Boolean is
   begin
      case M is
         when Trial_Division
            | Fermat
            | Pollard_Rho
            | Pollard_P1
            | SNFS
            | ECM =>
            return True;
         when Quadratic_Sieve | GNFS | Shor_Catalogue | Default =>
            return False;
      end case;
   end Is_Special_Purpose;

   function Is_General (M : Method_Kind) return Boolean is
   begin
      case M is
         when Quadratic_Sieve | GNFS | Default =>
            return True;
         when others =>
            return False;
      end case;
   end Is_General;

   function Is_Implemented (M : Method_Kind) return Boolean is
   begin
      case M is
         when Trial_Division | Fermat | Pollard_Rho | Default =>
            return True;
         when Pollard_P1
            | Quadratic_Sieve
            | SNFS
            | GNFS
            | ECM
            | Shor_Catalogue =>
            return False;
      end case;
   end Is_Implemented;

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

   function Is_Perfect_Square (N : U64) return Boolean is
      R : constant U64 := Floor_Sqrt (N);
   begin
      return R * R = N;
   end Is_Perfect_Square;

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

   ------------------------------------------------------------------
   --  Trial division
   ------------------------------------------------------------------

   function Trial_Division_Factor (N : U64) return U64 is
      D : U64;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      if N rem 2 = 0 then
         return 2;
      end if;
      if N rem 3 = 0 then
         return 3;
      end if;
      D := 5;
      while D <= N / D loop
         if N rem D = 0 then
            return D;
         end if;
         if N rem (D + 2) = 0 then
            return D + 2;
         end if;
         D := D + 6;
      end loop;
      return N;
   end Trial_Division_Factor;

   function Factorize_Trial (N : U64) return Factor_List is
      Remaining : U64 := N;
      Buf       : Factor_List (1 .. 64);
      Count     : Natural := 0;
      P         : U64;
      Exp       : Natural;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if N = 1 then
         return Factor_List'(1 .. 0 => <>);
      end if;

      while Remaining > 1 loop
         P := Trial_Division_Factor (Remaining);
         Exp := 0;
         while Remaining rem P = 0 loop
            Remaining := Remaining / P;
            Exp := Exp + 1;
         end loop;
         Count := Count + 1;
         Buf (Count) := (Prime => P, Exponent => Exp);
      end loop;

      return Buf (1 .. Count);
   end Factorize_Trial;

   ------------------------------------------------------------------
   --  Fermat
   ------------------------------------------------------------------

   function Ceil_Sqrt (N : U64) return U64 is
      R : constant U64 := Floor_Sqrt (N);
   begin
      if R * R = N then
         return R;
      end if;
      return R + 1;
   end Ceil_Sqrt;

   function Fermat_Factor
     (N         : U64;
      Max_Steps : Natural := Fermat_Default_Max_Steps) return U64
   is
      use Interfaces;
      A, B : U64;
      Steps : Natural := 0;
      AA, NN, Diff128 : Unsigned_128;
      function Floor_Sqrt_128 (X : Unsigned_128) return U64 is
         Lo, Hi, Mid : Unsigned_128;
      begin
         if X < 2 then
            return U64 (X);
         end if;
         Lo := 1;
         Hi := X / 2 + 1;
         while Lo < Hi loop
            Mid := Lo + (Hi - Lo + 1) / 2;
            if Mid > X / Mid then
               Hi := Mid - 1;
            else
               Lo := Mid;
            end if;
         end loop;
         return U64 (Lo);
      end Floor_Sqrt_128;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      if N rem 2 = 0 then
         return 2;
      end if;
      if Is_Perfect_Square (N) then
         return Floor_Sqrt (N);
      end if;

      A := Ceil_Sqrt (N);
      NN := Unsigned_128 (N);
      loop
         AA := Unsigned_128 (A) * Unsigned_128 (A);
         if AA < NN then
            --  Should not happen after ceil(sqrt); treat as failure.
            return 1;
         end if;
         Diff128 := AA - NN;
         B := Floor_Sqrt_128 (Diff128);
         if Unsigned_128 (B) * Unsigned_128 (B) = Diff128 then
            if A > B then
               return A - B;
            else
               return 1;
            end if;
         end if;
         Steps := Steps + 1;
         if Steps >= Max_Steps then
            return 1;
         end if;
         if A = U64'Last then
            return 1;
         end if;
         A := A + 1;
      end loop;
   end Fermat_Factor;

   ------------------------------------------------------------------
   --  Pollard's rho (Floyd)
   ------------------------------------------------------------------

   function Pollard_Rho_Factor
     (N         : U64;
      Seed      : U64    := 2;
      C         : U64    := 1;
      Max_Steps : Natural := Rho_Default_Max_Steps) return U64
   is
      function F (X : U64) return U64 is
      begin
         return (Mul_Mod (X, X, N) + (C rem N)) rem N;
      end F;

      Tortoise : U64;
      Hare     : U64;
      D        : U64;
      Steps    : Natural := 0;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      if N rem 2 = 0 then
         return 2;
      end if;
      if N rem 3 = 0 then
         return 3;
      end if;
      if Is_Prime_Trial (N) then
         return N;
      end if;

      Tortoise := Seed rem N;
      Hare     := Seed rem N;

      while Steps < Max_Steps loop
         Tortoise := F (Tortoise);
         Hare     := F (F (Hare));
         if Tortoise > Hare then
            D := Gcd (Tortoise - Hare, N);
         else
            D := Gcd (Hare - Tortoise, N);
         end if;
         if D > 1 and then D < N then
            return D;
         end if;
         if D = N then
            --  Cycle degenerated; try a different constant if possible.
            return 1;
         end if;
         Steps := Steps + 1;
      end loop;
      return 1;
   end Pollard_Rho_Factor;

   ------------------------------------------------------------------
   --  Dispatcher / Factorize
   ------------------------------------------------------------------

   function Factor
     (N      : U64;
      Method : Method_Kind := Default) return U64
   is
      F : U64;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;

      case Method is
         when Trial_Division =>
            return Trial_Division_Factor (N);

         when Fermat =>
            return Fermat_Factor (N);

         when Pollard_Rho =>
            return Pollard_Rho_Factor (N);

         when Default =>
            --  Practical educational hybrid: cheap trial first, then
            --  Pollard's rho on the remaining composite, then trial
            --  as a deterministic fallback.
            if N rem 2 = 0 then
               return 2;
            end if;
            if Is_Prime_Trial (N) then
               return N;
            end if;
            --  Quick small-factor peel via trial (bounded).
            F := Trial_Division_Factor (N);
            if F < N then
               return F;
            end if;
            --  Should not reach here for composites (trial always
            --  finds a factor ≤ √N). Keep rho for larger educational
            --  use / when trial is skipped by callers via Method.
            F := Pollard_Rho_Factor (N);
            if F > 1 and then F < N then
               return F;
            end if;
            return Trial_Division_Factor (N);

         when Pollard_P1
            | Quadratic_Sieve
            | SNFS
            | GNFS
            | ECM
            | Shor_Catalogue =>
            raise Invalid_Argument;
      end case;
   end Factor;

   function Factorize (N : U64) return Factor_List is
      Remaining : U64 := N;
      Buf       : Factor_List (1 .. 64);
      Count     : Natural := 0;
      P, F      : U64;
      Exp       : Natural;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      if N = 1 then
         return Factor_List'(1 .. 0 => <>);
      end if;

      --  Peel 2s.
      if Remaining rem 2 = 0 then
         Exp := 0;
         while Remaining rem 2 = 0 loop
            Remaining := Remaining / 2;
            Exp := Exp + 1;
         end loop;
         Count := Count + 1;
         Buf (Count) := (Prime => 2, Exponent => Exp);
      end if;

      while Remaining > 1 loop
         if Is_Prime_Trial (Remaining) then
            Count := Count + 1;
            Buf (Count) := (Prime => Remaining, Exponent => 1);
            Remaining := 1;
         else
            F := Factor (Remaining, Default);
            if F <= 1 or else F >= Remaining then
               --  Fallback: trial least factor (always works).
               F := Trial_Division_Factor (Remaining);
            end if;
            --  Ensure F is prime (factor may be composite).
            while not Is_Prime_Trial (F) and then F > 1 loop
               F := Trial_Division_Factor (F);
            end loop;
            P := F;
            Exp := 0;
            while Remaining rem P = 0 loop
               Remaining := Remaining / P;
               Exp := Exp + 1;
            end loop;
            if Exp = 0 then
               --  Pathological; force trial peel.
               P := Trial_Division_Factor (Remaining);
               while Remaining rem P = 0 loop
                  Remaining := Remaining / P;
                  Exp := Exp + 1;
               end loop;
            end if;
            Count := Count + 1;
            Buf (Count) := (Prime => P, Exponent => Exp);
         end if;
      end loop;

      --  Sort by ascending Prime (insertion; Count is tiny).
      declare
         I, J : Natural;
         Key  : Prime_Power;
      begin
         I := 2;
         while I <= Count loop
            Key := Buf (I);
            J := I;
            while J > 1 and then Buf (J - 1).Prime > Key.Prime loop
               Buf (J) := Buf (J - 1);
               J := J - 1;
            end loop;
            Buf (J) := Key;
            I := I + 1;
         end loop;
      end;

      return Buf (1 .. Count);
   end Factorize;

end Prime_Factorization;
