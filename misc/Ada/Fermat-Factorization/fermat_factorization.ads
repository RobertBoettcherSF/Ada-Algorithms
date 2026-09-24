--  Fermat's factorization method — Ada 2023 educational package.
--  Odd N = a² − b² = (a − b)(a + b). Start a = ceil(√N); while
--  a² − N is not a square, a := a + 1; factors are a ± b.
--  Fast when the unknown factors are close (difference small).
--  Primary source:
--  https://en.wikipedia.org/wiki/Fermat's_factorization_method
--  Siblings: Ada-Trial-Division, Ada-Prime-Factorization, Ada-Pollards-Rho,
--  Ada-Quadratic-Sieve.
--  Next (educational): Dixon's algorithm (congruence of squares).

pragma Ada_2022;

package Fermat_Factorization
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Educational cap on Fermat a-steps (a := a + 1) before giving up.
   Default_Max_Steps : constant Natural := 1_000_000;

   ------------------------------------------------------------------
   --  Factor pair (F1 × F2 = N when successful)
   ------------------------------------------------------------------

   --  On success: F1 ≤ F2, F1 * F2 = N, F1 ≥ 1.
   --  Perfect-square N → F1 = F2 = √N.
   --  Prime (given enough steps) → F1 = 1, F2 = N.
   --  Max_Steps exhaustion without a hit → F1 = 0, F2 = 0 (failure).
   type Factor_Pair is record
      F1 : U64 := 0;
      F2 : U64 := 0;
   end record;

   ------------------------------------------------------------------
   --  Modular / integer helpers (self-contained; no sibling `with`)
   ------------------------------------------------------------------

   --  Euclidean gcd. Gcd (0, 0) = 0.
   function Gcd (A, B : U64) return U64
     with Global => null;

   --  Integer square root floor(√N), self-contained (no Float).
   --  Overflow-safe binary search on U64. N = 0 → 0.
   function Floor_Sqrt (N : U64) return U64
     with Global => null;

   --  Ceiling of √N. Perfect square → Floor_Sqrt (N); else Floor_Sqrt + 1.
   --  N = 0 → 0.
   function Ceil_Sqrt (N : U64) return U64
     with Global => null;

   --  True iff N is a perfect square (Floor_Sqrt (N)² = N).
   function Is_Perfect_Square (N : U64) return Boolean
     with Global => null;

   --  True iff N is prime by trial division up to floor(√N).
   --  Wheel after 2/3. N < 2 → False.
   function Is_Prime_Trial (N : U64) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  Fermat factorization
   ------------------------------------------------------------------

   --  Classic Fermat: a := ceil(√N); while a² − N is not square,
   --  a := a + 1; then return (a − b, a + b) with b = √(a² − N).
   --  N < 2 → Invalid_Argument.
   --  Even N = 2 → (1, 2). Even N > 2 → (2, N/2) (Fermat needs odd N).
   --  Fast when factors are close. If Max_Steps is exhausted without a
   --  hit, returns (0, 0). When N is prime the loop finds the trivial
   --  split 1 × N after ~ (N − 1)/2 steps — use Max_Steps to stay
   --  educational. Perfect-square N returns (√N, √N) immediately.
   function Factor
     (N         : U64;
      Max_Steps : Natural := Default_Max_Steps) return Factor_Pair
     with Global => null;

end Fermat_Factorization;
