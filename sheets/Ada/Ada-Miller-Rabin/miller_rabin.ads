--  Miller–Rabin primality test — Ada 2023 educational package.
--  Probabilistic (and deterministic-for-64-bit) strong probable-prime test
--  on unsigned 64-bit integers. Self-contained modular arithmetic.
--  Primary source:
--  https://en.wikipedia.org/wiki/Miller%E2%80%93Rabin_primality_test
--  Note-sheet typo "Miler-Rabin" → Miller–Rabin.
--  Siblings: Ada-Sieve-Of-Eratosthenes (and other sieves); next: Lucas
--  primality test.

pragma Ada_2022;

package Miller_Rabin
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   --  All candidates and bases live in the full unsigned 64-bit range.
   --  Deterministic 64-bit primality uses the Wikipedia base set that is
   --  sufficient for every N < 2^64.
   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   ------------------------------------------------------------------
   --  Modular arithmetic helpers
   ------------------------------------------------------------------

   --  (A * B) mod M without intermediate overflow.
   --  Uses Interfaces.Unsigned_128 for the product.
   --  Raises Invalid_Argument if M = 0.
   function Mul_Mod (A, B, M : U64) return U64
     with Global => null;

   --  (Base ^ Exp) mod Modulus via binary exponentiation + Mul_Mod.
   --  Raises Invalid_Argument if Modulus = 0.
   --  Convention: Mod_Pow (B, 0, M) = 1 rem M for M > 0 (so 0 when M = 1).
   function Mod_Pow (Base, Exp, Modulus : U64) return U64
     with Global => null;

   --  Factor N − 1 = 2^S · D with D odd (S ≥ 0).
   --  Raises Invalid_Argument if N < 2.
   procedure Trial_Split_N_Minus_1
     (N : U64;
      S : out Natural;
      D : out U64)
     with Global => null;

   ------------------------------------------------------------------
   --  Witness / probable prime
   ------------------------------------------------------------------

   --  True if base A proves that N is composite (Miller–Rabin witness).
   --  Raises Invalid_Argument if N < 2.
   --  N = 2 → False (prime). Even N > 2 → True.
   --  If A mod N = 0 the base is invalid for the congruence test; returns
   --  False (does not prove compositeness by itself when gcd = N).
   function Is_Composite_Witness (N, A : U64) return Boolean
     with Global => null;

   --  Educational probable-prime test with a fixed base list (not a
   --  cryptographic RNG). Uses Rounds leading primes from the fixed
   --  educational base table (capped by table length). For N below the
   --  known deterministic thresholds the effective base set is sufficient
   --  for that range; prefer Is_Prime_Deterministic_64 for a full 64-bit
   --  guarantee. N < 2 → False.
   function Is_Probable_Prime
     (N      : U64;
      Rounds : Positive := 8) return Boolean
     with Global => null;

   --  Deterministic Miller–Rabin for every N in 0 .. 2^64 − 1 using the
   --  Wikipedia / OEIS A014233 base set
   --  {2,3,5,7,11,13,17,19,23,29,31,37}, which is sufficient for all
   --  N < 2^64. N < 2 → False; N = 2 or 3 → True; even N > 2 → False.
   function Is_Prime_Deterministic_64 (N : U64) return Boolean
     with Global => null;

end Miller_Rabin;
