--  Pollard's rho algorithm — Ada 2023 educational package.
--  Integer factorization via pseudorandom polynomial iteration and
--  Floyd / Brent cycle detection (gcd of |x−y| with N).
--  Expected time ~ O(√p) for the smallest prime factor p of N.
--  Primary source:
--  https://en.wikipedia.org/wiki/Pollard's_rho_algorithm
--  Siblings: Ada-Trial-Division, Ada-Prime-Factorization, Ada-Quadratic-Sieve.
--  Next (educational): Pollard's p−1. Distinguish later from Pollard's rho
--  for discrete logarithms (sibling algorithm, different problem).

pragma Ada_2022;

package Pollards_Rho
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Educational cap on Floyd / Brent outer iterations before giving up.
   Default_Max_Steps : constant Natural := 100_000;

   ------------------------------------------------------------------
   --  Modular / integer helpers (self-contained; no sibling `with`)
   ------------------------------------------------------------------

   --  Euclidean gcd. Gcd (0, 0) = 0.
   function Gcd (A, B : U64) return U64
     with Global => null;

   --  (A * B) mod M without intermediate overflow (Unsigned_128 product).
   --  Raises Invalid_Argument if M = 0.
   function Mul_Mod (A, B, M : U64) return U64
     with Global => null;

   --  Integer square root floor(√N), self-contained (no Float).
   --  Overflow-safe binary search on U64. N = 0 → 0.
   function Floor_Sqrt (N : U64) return U64
     with Global => null;

   --  True iff N is prime by trial division up to floor(√N).
   --  Wheel after 2/3. N < 2 → False.
   function Is_Prime_Trial (N : U64) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  Pollard's rho — Floyd (classic tortoise / hare)
   ------------------------------------------------------------------

   --  Classic Pollard's rho with f(x) = x² + C (mod N) and Floyd's
   --  cycle-finding (tortoise one step, hare two steps). Returns a
   --  non-trivial factor when found; returns 1 on failure / Max_Steps
   --  exhaustion; returns N when N is prime (trial for tiny / all U64
   --  educational sizes). N < 2 → Invalid_Argument. Even N > 2 → 2.
   --  Expected running time is proportional to √p for the smallest
   --  prime factor p of N (birthday paradox / rho shape).
   function Factor_Floyd
     (N         : U64;
      Seed      : U64     := 2;
      C         : U64     := 1;
      Max_Steps : Natural := Default_Max_Steps) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  Pollard's rho — Brent cycle variant (optional)
   ------------------------------------------------------------------

   --  Same polynomial f(x) = x² + C (mod N), but cycle detection uses
   --  Brent's method (power-of-two backtracks) instead of Floyd.
   --  Same return conventions as Factor_Floyd. Often fewer evaluations
   --  of f in practice (Wikipedia / Brent 1980).
   function Factor_Brent
     (N         : U64;
      Seed      : U64     := 2;
      C         : U64     := 1;
      Max_Steps : Natural := Default_Max_Steps) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  Multi-attempt dispatcher
   ------------------------------------------------------------------

   --  Try a small menu of (Seed, C) pairs with Factor_Floyd (then
   --  Factor_Brent on the last attempt) until a non-trivial factor
   --  appears, or return 1 on total failure. N < 2 → Invalid_Argument.
   --  Even N > 2 → 2. Primes → N (via trial). Educational hybrid only.
   function Factor
     (N         : U64;
      Max_Steps : Natural := Default_Max_Steps) return U64
     with Global => null;

end Pollards_Rho;
