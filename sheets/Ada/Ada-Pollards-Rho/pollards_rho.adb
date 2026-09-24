--  Pollard's rho — Ada 2023 implementation (Floyd + Brent).

pragma Ada_2022;

with Interfaces;

package body Pollards_Rho
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

   --  Absolute difference on U64 (modular type: use ordering).
   function Abs_Diff (X, Y : U64) return U64 is
   begin
      if X > Y then
         return X - Y;
      else
         return Y - X;
      end if;
   end Abs_Diff;

   --  Shared preamble: N < 2 raise; even → 2; divisible by 3 → 3;
   --  prime → N. Returns 0 when the caller should run the rho loop.
   function Quick_Factor (N : U64) return U64 is
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
      return 0;
   end Quick_Factor;

   function Poly (X, C, N : U64) return U64 is
   begin
      return (Mul_Mod (X, X, N) + (C rem N)) rem N;
   end Poly;

   ------------------------------------------------------------------
   --  Floyd
   ------------------------------------------------------------------

   function Factor_Floyd
     (N         : U64;
      Seed      : U64     := 2;
      C         : U64     := 1;
      Max_Steps : Natural := Default_Max_Steps) return U64
   is
      Q        : constant U64 := Quick_Factor (N);
      Tortoise : U64;
      Hare     : U64;
      D        : U64;
      Steps    : Natural := 0;
   begin
      if Q /= 0 then
         return Q;
      end if;

      Tortoise := Seed rem N;
      Hare     := Seed rem N;

      while Steps < Max_Steps loop
         Tortoise := Poly (Tortoise, C, N);
         Hare     := Poly (Poly (Hare, C, N), C, N);
         D := Gcd (Abs_Diff (Tortoise, Hare), N);
         if D > 1 and then D < N then
            return D;
         end if;
         if D = N then
            --  Degenerate cycle (both pointers landed on same residue
            --  class mod every factor); caller may retry other C/Seed.
            return 1;
         end if;
         Steps := Steps + 1;
      end loop;
      return 1;
   end Factor_Floyd;

   ------------------------------------------------------------------
   --  Brent
   ------------------------------------------------------------------

   function Factor_Brent
     (N         : U64;
      Seed      : U64     := 2;
      C         : U64     := 1;
      Max_Steps : Natural := Default_Max_Steps) return U64
   is
      Q     : constant U64 := Quick_Factor (N);
      X     : U64;
      Y     : U64;
      D     : U64 := 1;
      R     : Natural := 1;
      K     : Natural;
      Steps : Natural := 0;
   begin
      if Q /= 0 then
         return Q;
      end if;

      Y := Seed rem N;

      --  Brent: freeze X every power-of-two block length R, advance Y
      --  one step at a time, gcd(|X−Y|, N). Cap total Poly evaluations
      --  by Max_Steps.
      Outer :
      while D = 1 and then Steps < Max_Steps loop
         X := Y;
         for I in 1 .. R loop
            Y := Poly (Y, C, N);
            Steps := Steps + 1;
            if Steps >= Max_Steps then
               exit Outer;
            end if;
         end loop;

         K := 0;
         while K < R and then D = 1 and then Steps < Max_Steps loop
            Y := Poly (Y, C, N);
            Steps := Steps + 1;
            D := Gcd (Abs_Diff (X, Y), N);
            K := K + 1;
         end loop;

         --  Next Brent block doubles the search window.
         if R <= Natural'Last / 2 then
            R := R * 2;
         end if;
      end loop Outer;

      if D > 1 and then D < N then
         return D;
      end if;
      if D = N then
         return 1;
      end if;
      return 1;
   end Factor_Brent;

   ------------------------------------------------------------------
   --  Multi-attempt Factor
   ------------------------------------------------------------------

   function Factor
     (N         : U64;
      Max_Steps : Natural := Default_Max_Steps) return U64
   is
      type Pair is record
         Seed : U64;
         C    : U64;
      end record;
      --  Small educational menu of (seed, c) for f(x)=x²+c.
      Attempts : constant array (Positive range <>) of Pair :=
        [(2, 1), (2, 2), (3, 1), (5, 1), (7, 3), (11, 1), (2, 5), (13, 7)];
      F : U64;
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

      for I in Attempts'Range loop
         if I = Attempts'Last then
            F := Factor_Brent
              (N, Attempts (I).Seed, Attempts (I).C, Max_Steps);
         else
            F := Factor_Floyd
              (N, Attempts (I).Seed, Attempts (I).C, Max_Steps);
         end if;
         if F > 1 and then F < N then
            return F;
         end if;
      end loop;
      return 1;
   end Factor;

end Pollards_Rho;
