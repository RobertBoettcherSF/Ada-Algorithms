--  Fermat's factorization method — Ada 2023 implementation.

pragma Ada_2022;

with Interfaces;

package body Fermat_Factorization
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

   function Ceil_Sqrt (N : U64) return U64 is
      R : constant U64 := Floor_Sqrt (N);
   begin
      if N = 0 then
         return 0;
      end if;
      if R * R = N then
         return R;
      end if;
      return R + 1;
   end Ceil_Sqrt;

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
   --  Fermat
   ------------------------------------------------------------------

   --  floor(√X) for X fitting in Unsigned_128 (a² − N may exceed U64
   --  when a is large, though for educational U64 N it stays modest).
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

   function Factor
     (N         : U64;
      Max_Steps : Natural := Default_Max_Steps) return Factor_Pair
   is
      use Interfaces;
      A, B, F1, F2 : U64;
      Steps        : Natural := 0;
      AA, NN, Diff : Unsigned_128;
   begin
      if N < 2 then
         raise Invalid_Argument;
      end if;

      --  Even N: Fermat assumes odd N. Peel 2; N = 2 is prime.
      if N rem 2 = 0 then
         if N = 2 then
            return (F1 => 1, F2 => 2);
         end if;
         return (F1 => 2, F2 => N / 2);
      end if;

      --  Perfect square → (√N, √N) immediately.
      if Is_Perfect_Square (N) then
         B := Floor_Sqrt (N);
         return (F1 => B, F2 => B);
      end if;

      A  := Ceil_Sqrt (N);
      NN := Unsigned_128 (N);

      loop
         AA := Unsigned_128 (A) * Unsigned_128 (A);
         if AA < NN then
            --  Should not happen after ceil(√N); treat as failure.
            return (F1 => 0, F2 => 0);
         end if;

         Diff := AA - NN;
         B := Floor_Sqrt_128 (Diff);

         if Unsigned_128 (B) * Unsigned_128 (B) = Diff then
            --  Factors a − b and a + b.
            if A > B then
               F1 := A - B;
               F2 := A + B;
               --  Sanity: F1 * F2 should equal N (may wrap on huge a;
               --  educational U64 path keeps products exact when F2
               --  fits). Prefer ordered F1 ≤ F2.
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
   end Factor;

end Fermat_Factorization;
