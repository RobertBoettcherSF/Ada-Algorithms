--  Primality_Test — Ada 2023 educational survey package for
--  Wikipedia "Primality test": taxonomy + self-contained sketches of
--  trial division, Fermat, deterministic-small Miller–Rabin, and a tiny
--  AKS-flavoured perfect-power + trial hybrid. Sibling packages (full
--  Miller–Rabin, Fermat, Lucas, Baillie–PSW, AKS, sieves, …) are linked
--  in the README only — this repo does not `with` them.
--  Primary source: https://en.wikipedia.org/wiki/Primality_test

pragma Ada_2022;

package Primality_Test
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Educational upper bound for Miller_Rabin_Deterministic_Small
   --  (Wikipedia: bases {2,7,61} suffice for all N < 4_759_123_141,
   --  which covers every N ≤ 2^32).
   MR_Small_Max : constant U64 := 2 ** 32;

   --  Educational upper bound for AKS_Is_Prime_Tiny (perfect-power +
   --  trial hybrid — not the full AKS polynomial congruence step).
   AKS_Tiny_Max : constant U64 := 10_000;

   ------------------------------------------------------------------
   --  Taxonomy
   ------------------------------------------------------------------

   --  Survey catalogue. Catalogue-only entries point at README siblings.
   type Method_Kind is
     (Trial_Division,
      Fermat,
      Miller_Rabin,
      Lucas_N_Minus_1,
      Baillie_PSW,
      AKS,
      Sieve_Eratosthenes_Catalogue,
      Sieve_Atkin_Catalogue,
      Solovay_Strassen_Catalogue,
      Default);

   function Method_Name (M : Method_Kind) return String
     with Global => null;

   --  Always-correct answer on the method's stated domain (no random
   --  bases / no one-sided error). Fermat is never deterministic.
   function Is_Deterministic (M : Method_Kind) return Boolean
     with Global => null;

   --  May accept some composites as "probably prime" (one-sided error).
   function Is_Probabilistic (M : Method_Kind) return Boolean
     with Global => null;

   --  Affirmative answer proves primality (or compositeness via a
   --  certificate / exhaustive check). Fermat / Baillie–PSW sketches do
   --  not prove primality in the Wikipedia sense.
   function Is_Proving (M : Method_Kind) return Boolean
     with Global => null;

   function Is_Implemented (M : Method_Kind) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  Modular arithmetic helpers (self-contained; no sibling `with`)
   ------------------------------------------------------------------

   --  (A * B) mod M without intermediate overflow (Unsigned_128 product).
   --  Raises Invalid_Argument if M = 0.
   function Mul_Mod (A, B, M : U64) return U64
     with Global => null;

   --  (Base ^ Exp) mod Modulus via binary exponentiation + Mul_Mod.
   --  Raises Invalid_Argument if Modulus = 0.
   --  Convention: Mod_Pow (B, 0, M) = 1 rem M for M > 0 (so 0 when M = 1).
   function Mod_Pow (Base, Exp, Modulus : U64) return U64
     with Global => null;

   --  Euclidean gcd. Gcd (0, 0) = 0.
   function Gcd (A, B : U64) return U64
     with Global => null;

   --  True iff N is a perfect square (integer square-root check).
   function Is_Perfect_Square (N : U64) return Boolean
     with Global => null;

   --  True iff N = A^B for integers A > 1 and B > 1 (perfect power).
   --  N < 2 → False. Educational loop over exponents.
   function Is_Perfect_Power (N : U64) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  1. Trial division (classic √N loop)
   ------------------------------------------------------------------

   --  Deterministic proving test: trial-divide by 2 and odd candidates
   --  up to floor(√N). N < 2 → False; N = 2 or 3 → True.
   function Trial_Division_Is_Prime (N : U64) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  2. Fermat probable prime (fixed educational bases)
   ------------------------------------------------------------------

   --  Educational Fermat test: for each of the first Rounds primes from
   --  the fixed base table {2,3,5,7,11,…}, require A^{N−1} ≡ 1 (mod N)
   --  when gcd(A,N)=1; a proper common factor rejects. Not cryptographic.
   --  WARNING — Carmichael numbers (e.g. 561) pass for every base
   --  coprime to N; with Rounds = 1 (base 2 only) 561 fools the test.
   --  N < 2 → False; N = 2 or 3 → True; even N > 2 → False.
   function Fermat_Probable_Prime
     (N      : U64;
      Rounds : Positive := 3) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  3. Miller–Rabin deterministic-small
   ------------------------------------------------------------------

   --  Strong probable-prime / Miller–Rabin with bases {2,7,61}, which is
   --  sufficient for every N ≤ MR_Small_Max (= 2^32). Raises
   --  Invalid_Argument if N > MR_Small_Max. N < 2 → False.
   function Miller_Rabin_Deterministic_Small (N : U64) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  4. Tiny AKS-flavoured hybrid (NOT full AKS)
   ------------------------------------------------------------------

   --  Educational stand-in for early AKS steps only: reject perfect
   --  powers, then trial-divide. Valid for N ≤ AKS_Tiny_Max. Raises
   --  Invalid_Argument if N > AKS_Tiny_Max. Full polynomial-congruence
   --  AKS lives in the Ada-AKS-Primality-Test sibling (README link).
   function AKS_Is_Prime_Tiny (N : U64) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  5. Default / dispatcher
   ------------------------------------------------------------------

   --  Practical educational default: trial division for N ≤ 10_000,
   --  else Miller_Rabin_Deterministic_Small (requires N ≤ MR_Small_Max).
   --  Raises Invalid_Argument if N > MR_Small_Max.
   function Is_Prime_Default (N : U64) return Boolean
     with Global => null;

   --  Route to an implemented sketch. Catalogue-only methods raise
   --  Invalid_Argument. AKS uses AKS_Is_Prime_Tiny (tiny domain).
   function Is_Prime (N : U64; Method : Method_Kind) return Boolean
     with Global => null;

end Primality_Test;
