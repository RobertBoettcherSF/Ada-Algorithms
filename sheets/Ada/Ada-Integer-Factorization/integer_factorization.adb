--  Integer factorization — Ada 2023 body (educational survey sketches).

pragma Ada_2022;

with Interfaces;

package body Integer_Factorization
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Helpers
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

   function Floor_Sqrt (N : U64) return U64 is
      Lo  : U64 := 0;
      Hi  : U64 := N;
      Mid : U64;
   begin
      if N = 0 or else N = 1 then
         return N;
      end if;
      while Lo < Hi loop
         Mid := Lo + (Hi - Lo + 1) / 2;
         if Mid > 0 and then Mid > N / Mid then
            Hi := Mid - 1;
         else
            Lo := Mid;
         end if;
      end loop;
      return Lo;
   end Floor_Sqrt;

   function Ceil_Sqrt (N : U64) return U64 is
      R : U64;
   begin
      if N = 0 then
         return 0;
      end if;
      R := Floor_Sqrt (N);
      if R * R = N then
         return R;
      else
         return R + 1;
      end if;
   end Ceil_Sqrt;

   function Is_Perfect_Square (N : U64) return Boolean is
      R : constant U64 := Floor_Sqrt (N);
   begin
      return R * R = N;
   end Is_Perfect_Square;

   function Is_Prime_Trial (N : U64) return Boolean is
      D    : U64;
      Root : U64;
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
      Root := Floor_Sqrt (N);
      D := 5;
      while D <= Root loop
         if N rem D = 0 then
            return False;
         end if;
         if D + 2 <= Root and then N rem (D + 2) = 0 then
            return False;
         end if;
         if D > U64'Last - 6 then
            exit;
         end if;
         D := D + 6;
      end loop;
      return True;
   end Is_Prime_Trial;

   function Smallest_Prime_Factor (N : U64) return U64 is
      D    : U64;
      Root : U64;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      if (N and 1) = 0 then
         return 2;
      end if;
      if N rem 3 = 0 then
         return 3;
      end if;
      Root := Floor_Sqrt (N);
      D := 5;
      while D <= Root loop
         if N rem D = 0 then
            return D;
         end if;
         if D + 2 <= Root and then N rem (D + 2) = 0 then
            return D + 2;
         end if;
         if D > U64'Last - 6 then
            exit;
         end if;
         D := D + 6;
      end loop;
      return N;
   end Smallest_Prime_Factor;

   ------------------------------------------------------------------
   --  Trial division
   ------------------------------------------------------------------

   function Trial_Division_Factor (N : U64) return U64 is
   begin
      return Smallest_Prime_Factor (N);
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
         return [];
      end if;

      while Remaining > 1 loop
         P := Smallest_Prime_Factor (Remaining);
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

   function Floor_Sqrt_128 (X : Interfaces.Unsigned_128) return U64 is
      use Interfaces;
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

   function Fermat_Factor
     (N         : U64;
      Max_Steps : Natural := Fermat_Default_Max_Steps) return U64
   is
      use Interfaces;
      A, B        : U64;
      Steps       : Natural := 0;
      AA, NN, Diff : Unsigned_128;
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

      A  := Ceil_Sqrt (N);
      NN := Unsigned_128 (N);
      loop
         AA := Unsigned_128 (A) * Unsigned_128 (A);
         if AA < NN then
            return 1;
         end if;
         Diff := AA - NN;
         B := Floor_Sqrt_128 (Diff);
         if Unsigned_128 (B) * Unsigned_128 (B) = Diff then
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

   function Fermat_Factor_Pair
     (N         : U64;
      Max_Steps : Natural := Fermat_Default_Max_Steps) return Factor_Pair
   is
      use Interfaces;
      A, B, F1, F2 : U64;
      Steps        : Natural := 0;
      AA, NN, Diff : Unsigned_128;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;

      if N rem 2 = 0 then
         if N = 2 then
            return (F1 => 1, F2 => 2);
         end if;
         return (F1 => 2, F2 => N / 2);
      end if;

      if Is_Perfect_Square (N) then
         B := Floor_Sqrt (N);
         return (F1 => B, F2 => B);
      end if;

      A  := Ceil_Sqrt (N);
      NN := Unsigned_128 (N);

      loop
         AA := Unsigned_128 (A) * Unsigned_128 (A);
         if AA < NN then
            return (F1 => 0, F2 => 0);
         end if;

         Diff := AA - NN;
         B := Floor_Sqrt_128 (Diff);

         if Unsigned_128 (B) * Unsigned_128 (B) = Diff then
            if A > B then
               F1 := A - B;
               F2 := A + B;
               if F1 > F2 then
                  declare
                     T : constant U64 := F1;
                  begin
                     F1 := F2;
                     F2 := T;
                  end;
               end if;
               return (F1 => F1, F2 => F2);
            else
               return (F1 => 0, F2 => 0);
            end if;
         end if;

         Steps := Steps + 1;
         if Steps >= Max_Steps then
            return (F1 => 0, F2 => 0);
         end if;
         if A = U64'Last then
            return (F1 => 0, F2 => 0);
         end if;
         A := A + 1;
      end loop;
   end Fermat_Factor_Pair;

   ------------------------------------------------------------------
   --  Pollard's rho (Floyd)
   ------------------------------------------------------------------

   function Abs_Diff (A, B : U64) return U64 is
   begin
      if A >= B then
         return A - B;
      else
         return B - A;
      end if;
   end Abs_Diff;

   function Pollard_Rho_Factor
     (N         : U64;
      Seed      : U64     := 2;
      C         : U64     := 1;
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
         D := Gcd (Abs_Diff (Tortoise, Hare), N);
         if D > 1 and then D < N then
            return D;
         end if;
         if D = N then
            return 1;
         end if;
         Steps := Steps + 1;
      end loop;
      return 1;
   end Pollard_Rho_Factor;

   ------------------------------------------------------------------
   --  Congruence of squares
   ------------------------------------------------------------------

   function Squares_Congruent (X, Y, N : U64) return Boolean is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      return Mul_Mod (X, X, N) = Mul_Mod (Y, Y, N);
   end Squares_Congruent;

   function Is_Trivial_Pair (X, Y, N : U64) return Boolean is
      Xn, Yn, Neg_Y : U64;
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      Xn := X rem N;
      Yn := Y rem N;
      if Yn = 0 then
         Neg_Y := 0;
      else
         Neg_Y := N - Yn;
      end if;
      return Xn = Yn or else Xn = Neg_Y;
   end Is_Trivial_Pair;

   function Is_Nontrivial_Congruence (X, Y, N : U64) return Boolean is
   begin
      if N = 0 then
         raise Invalid_Argument;
      end if;
      return Squares_Congruent (X, Y, N)
        and then not Is_Trivial_Pair (X, Y, N);
   end Is_Nontrivial_Congruence;

   function Diff_Mod (X, Y, N : U64) return U64 is
      Xn : constant U64 := X rem N;
      Yn : constant U64 := Y rem N;
   begin
      return (Xn + N - Yn) rem N;
   end Diff_Mod;

   function Sum_Mod (X, Y, N : U64) return U64 is
      Xn : constant U64 := X rem N;
      Yn : constant U64 := Y rem N;
   begin
      return (Xn + Yn) rem N;
   end Sum_Mod;

   function Factor_From_Congruence (X, Y, N : U64) return U64 is
      D, S, F : U64;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      if not Is_Nontrivial_Congruence (X, Y, N) then
         return 0;
      end if;
      D := Diff_Mod (X, Y, N);
      F := Gcd (D, N);
      if F > 1 and then F < N then
         return F;
      end if;
      S := Sum_Mod (X, Y, N);
      F := Gcd (S, N);
      if F > 1 and then F < N then
         return F;
      end if;
      return 0;
   end Factor_From_Congruence;

   function Factors_From_Congruence (X, Y, N : U64) return Factor_Pair is
      F : U64;
      P : Factor_Pair;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      F := Factor_From_Congruence (X, Y, N);
      if F = 0 then
         return P;
      end if;
      if F <= N / F then
         P.F1 := F;
         P.F2 := N / F;
      else
         P.F1 := N / F;
         P.F2 := F;
      end if;
      return P;
   end Factors_From_Congruence;

   ------------------------------------------------------------------
   --  Driver Factor / Factorize
   ------------------------------------------------------------------

   --  Trial peel only for tiny factors (classroom hybrid).
   function Small_Trial_Factor (N : U64; Limit : U64) return U64 is
      D : U64;
   begin
      if N rem 2 = 0 then
         return 2;
      end if;
      if N rem 3 = 0 then
         return 3;
      end if;
      D := 5;
      while D <= Limit and then D <= N / D loop
         if N rem D = 0 then
            return D;
         end if;
         if D + 2 <= Limit and then N rem (D + 2) = 0 then
            return D + 2;
         end if;
         if D > U64'Last - 6 then
            exit;
         end if;
         D := D + 6;
      end loop;
      return 1;
   end Small_Trial_Factor;

   function Factor
     (N    : U64;
      Seed : U64 := 2) return U64
   is
      F : U64;
      P : Factor_Pair;
   begin
      if N = 0 or else N > Factor_Max then
         raise Invalid_Argument;
      end if;
      if N = 1 then
         raise Invalid_Argument;
      end if;

      if N rem 2 = 0 then
         return 2;
      end if;
      if Is_Prime_Trial (N) then
         return N;
      end if;

      --  1. Strip tiny factors quickly (Limit = 1000).
      F := Small_Trial_Factor (N, 1000);
      if F > 1 and then F < N then
         return F;
      end if;

      --  2. Fermat sketch (nearby factors; capped steps).
      P := Fermat_Factor_Pair (N, Max_Steps => 100_000);
      if P.F1 > 1 and then P.F1 < N then
         return P.F1;
      end if;

      --  3. Pollard's rho (seeded x²+c Floyd), a few C values.
      declare
         Cs : constant array (Positive range <>) of U64 :=
           [1, 2, 3, 5, 7];
      begin
         for I in Cs'Range loop
            F := Pollard_Rho_Factor
              (N, Seed => Seed, C => Cs (I), Max_Steps => Rho_Default_Max_Steps);
            if F > 1 and then F < N then
               return F;
            end if;
         end loop;
      end;

      --  4. Deterministic trial fallback (always succeeds for composites).
      return Smallest_Prime_Factor (N);
   end Factor;

   function Factorize (N : U64) return Factor_List is
      Remaining : U64 := N;
      Buf       : Factor_List (1 .. 64);
      Count     : Natural := 0;
      P, F      : U64;
      Exp       : Natural;
   begin
      if N = 0 or else N > Factor_Max then
         raise Invalid_Argument;
      end if;
      if N = 1 then
         return [];
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
            --  Prefer trial SPF for deterministic classroom results;
            --  Factor still exercises the hybrid path on demand.
            F := Smallest_Prime_Factor (Remaining);
            if F <= 1 or else F >= Remaining then
               F := Factor (Remaining);
            end if;
            while not Is_Prime_Trial (F) and then F > 1 loop
               F := Smallest_Prime_Factor (F);
            end loop;
            P := F;
            Exp := 0;
            while Remaining rem P = 0 loop
               Remaining := Remaining / P;
               Exp := Exp + 1;
            end loop;
            if Exp = 0 then
               P := Smallest_Prime_Factor (Remaining);
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

end Integer_Factorization;
