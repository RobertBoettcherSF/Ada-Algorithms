--  Pollard's p−1 algorithm — Ada 2023 educational package.
--  Special-purpose integer factorization: finds a prime factor p of N
--  when p−1 is B-powersmooth (Stage 1). Algebraic-group method (Pollard 1974).
--  Primary source:
--  https://en.wikipedia.org/wiki/Pollard's_p_%E2%88%92_1_algorithm
--  Siblings: Ada-Pollards-Rho, Ada-Trial-Division, Ada-Quadratic-Sieve.
--  Next (educational): Lenstra elliptic-curve factorization (ECM).

pragma Ada_2022;

package Pollards_P_1
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Default Stage-1 smoothness bound (educational).
   Default_B : constant U64 := 100;

   --  Ordered list of primes / words (ascending).
   type U64_Array is array (Positive range <>) of U64;

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

   --  (Base ^ Exp) mod Modulus via binary exponentiation + Mul_Mod.
   --  Raises Invalid_Argument if Modulus = 0.
   --  Convention: Mod_Pow (B, 0, M) = 1 rem M for M > 0 (so 0 when M = 1).
   function Mod_Pow (Base, Exp, Modulus : U64) return U64
     with Global => null;

   --  Integer square root floor(√N), self-contained (no Float).
   --  Overflow-safe binary search on U64. N = 0 → 0.
   function Floor_Sqrt (N : U64) return U64
     with Global => null;

   --  True iff N is prime by trial division up to floor(√N).
   --  Wheel after 2/3. N < 2 → False.
   function Is_Prime_Trial (N : U64) return Boolean
     with Global => null;

   --  Primes ≤ Limit (trial). Limit < 2 → empty array.
   --  Educational sizes; not a fast sieve.
   function Primes_Up_To (Limit : U64) return U64_Array
     with Global => null;

   ------------------------------------------------------------------
   --  Pollard's p−1 — Stage 1
   ------------------------------------------------------------------

   --  Stage 1: for primes q ≤ B raise the residue by q repeatedly
   --  (a ← a^q) up to the highest q^k ≤ B (so exponent M = lcm(1..B)),
   --  checking gcd(a − 1, N) after each raise. Returns a nontrivial
   --  factor when 1 < g < N; returns 1 on failure / for primes.
   --  If g = N (all factors B-powersmooth), retries smaller bounds.
   --  Even N → 2. N < 2 or B < 2 → Invalid_Argument.
   --  Base defaults to 2 (valid when N is odd).
   function Factor_Stage1
     (N    : U64;
      B    : U64;
      Base : U64 := 2) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  Multi-base dispatcher
   ------------------------------------------------------------------

   --  Try a short menu of bases with Factor_Stage1 until a nontrivial
   --  factor appears, or return 1 on total failure. Default B is
   --  Default_B. N < 2 or B < 2 → Invalid_Argument. Primes → 1.
   function Factor
     (N : U64;
      B : U64 := Default_B) return U64
     with Global => null;

end Pollards_P_1;
