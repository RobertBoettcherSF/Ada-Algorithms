--  Congruence of squares — Ada 2023 body (educational toy).

pragma Ada_2022;

with Interfaces;

package body Congruence_Of_Squares
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Mul_Mod / Gcd / Floor_Sqrt / Ceil_Sqrt / Is_Perfect_Square
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

   ------------------------------------------------------------------
   --  Trial helpers
   ------------------------------------------------------------------

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
   --  Predicates
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

   ------------------------------------------------------------------
   --  Factor extraction
   ------------------------------------------------------------------

   --  (X − Y) mod N as a representative in 0 .. N−1.
   function Diff_Mod (X, Y, N : U64) return U64 is
      Xn : constant U64 := X rem N;
      Yn : constant U64 := Y rem N;
   begin
      return (Xn + N - Yn) rem N;
   end Diff_Mod;

   --  (X + Y) mod N.
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
   --  Search demos
   ------------------------------------------------------------------

   function Ordered_Pair (A, B : U64) return Factor_Pair is
      P : Factor_Pair;
   begin
      if A <= B then
         P.F1 := A;
         P.F2 := B;
      else
         P.F1 := B;
         P.F2 := A;
      end if;
      return P;
   end Ordered_Pair;

   function Find_Fermat_Style_Congruence
     (N         : U64;
      Max_Steps : Natural := Default_Max_Steps) return Factor_Pair
   is
      A, R, B, F : U64;
      Steps      : Natural := 0;
      Fail       : Factor_Pair;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      if N > Factor_Search_Max then
         raise Invalid_Argument;
      end if;
      if (N and 1) = 0 then
         if N = 2 then
            return Ordered_Pair (1, 2);
         else
            return Ordered_Pair (2, N / 2);
         end if;
      end if;

      --  Perfect square → trivial Fermat split √N × √N (not a CoS
      --  nontrivial pair); still useful as an educational factor.
      if Is_Perfect_Square (N) then
         B := Floor_Sqrt (N);
         return Ordered_Pair (B, B);
      end if;

      A := Ceil_Sqrt (N);
      while Steps < Max_Steps loop
         --  Classical Fermat: a² − N is a square ⇒ a² ≡ b² (mod N)
         --  with residue 0. Also accept any a² rem N that is square.
         R := Mul_Mod (A, A, N);
         if Is_Perfect_Square (R) then
            B := Floor_Sqrt (R);
            if Is_Nontrivial_Congruence (A, B, N) then
               F := Factor_From_Congruence (A, B, N);
               if F > 1 and then F < N then
                  return Ordered_Pair (F, N / F);
               end if;
            end if;
         end if;
         --  Also try residue of a² − k·N for the Fermat difference
         --  when a² ≥ N (always true for a ≥ ceil(√N)): a² − N.
         declare
            Diff : constant U64 := A * A - N;
         begin
            if Is_Perfect_Square (Diff) then
               B := Floor_Sqrt (Diff);
               --  a² − b² = N ⇒ factors (a−b)(a+b)
               if B < A then
                  return Ordered_Pair (A - B, A + B);
               end if;
            end if;
         end;
         exit when A = U64'Last;
         A := A + 1;
         Steps := Steps + 1;
      end loop;
      return Fail;
   end Find_Fermat_Style_Congruence;

   function Find_Random_Square_Congruence
     (N          : U64;
      Seed       : U64     := 1;
      Max_Trials : Natural := Default_Max_Trials) return Factor_Pair
   is
      State : U64;
      A, R, B, F : U64;
      Fail  : Factor_Pair;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;
      if N > Factor_Search_Max then
         raise Invalid_Argument;
      end if;
      if (N and 1) = 0 then
         if N = 2 then
            return Ordered_Pair (1, 2);
         else
            return Ordered_Pair (2, N / 2);
         end if;
      end if;

      --  LCG: State := 6364136223846793005 * State + 1 (splitmix-ish const)
      State := Seed;
      if State = 0 then
         State := 1;
      end if;

      for Trial in 1 .. Max_Trials loop
         State := State * 6364136223846793005 + 1;
         A := 1 + (State rem (N - 1));
         R := Mul_Mod (A, A, N);
         if Is_Perfect_Square (R) then
            B := Floor_Sqrt (R);
            if Is_Nontrivial_Congruence (A, B, N) then
               F := Factor_From_Congruence (A, B, N);
               if F > 1 and then F < N then
                  return Ordered_Pair (F, N / F);
               end if;
            end if;
         end if;
      end loop;
      return Fail;
   end Find_Random_Square_Congruence;

   function Factor
     (N    : U64;
      Seed : U64 := 1) return U64
   is
      P : Factor_Pair;
      F : U64;
   begin
      if N = 0 or else N > Factor_Search_Max then
         raise Invalid_Argument;
      end if;
      if N < 2 then
         return 1;
      end if;
      if (N and 1) = 0 then
         return 2;
      end if;
      if Is_Prime_Trial (N) then
         return 1;
      end if;

      P := Find_Fermat_Style_Congruence (N);
      if P.F1 > 1 and then P.F1 < N then
         return P.F1;
      end if;

      P := Find_Random_Square_Congruence (N, Seed);
      if P.F1 > 1 and then P.F1 < N then
         return P.F1;
      end if;

      --  Trial fallback so classroom demos still finish.
      F := Smallest_Prime_Factor (N);
      if F > 1 and then F < N then
         return F;
      end if;
      return 1;
   end Factor;

end Congruence_Of_Squares;
