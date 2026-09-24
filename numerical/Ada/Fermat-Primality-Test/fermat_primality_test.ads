--  Fermat primality test — Ada 2023 educational package.
--  Probabilistic Fermat probable-prime test on unsigned 64-bit integers.
--  Self-contained modular arithmetic (Mul_Mod / Mod_Pow copied in-tree;
--  no sibling `with`).
--  Primary source:
--  https://en.wikipedia.org/wiki/Fermat_primality_test
--  Siblings: Ada-Miller-Rabin (stronger), Ada-Lucas-Primality-Test;
--  next: Baillie–PSW.

pragma Ada_2022;

package Fermat_Primality_Test
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Caller-supplied educational base list for Is_Fermat_Probable_Prime.
   type Base_List is array (Positive range <>) of U64;

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

   --  Euclidean gcd. Gcd (0, 0) = 0.
   function Gcd (A, B : U64) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  Witness / probable prime
   ------------------------------------------------------------------

   --  True if base A proves that N is composite in the broad Fermat sense:
   --    * 1 < gcd(A, N) < N  → True  (proper common factor; N composite);
   --    * gcd(A, N) = 1 and A^{N−1} ≢ 1 (mod N) → True  (classical Fermat
   --      witness);
   --    * gcd(A, N) = N (i.e. A ≡ 0 mod N) → False  (base not usable for
   --      the congruence test; does not by itself prove compositeness);
   --    * gcd = 1 and A^{N−1} ≡ 1 (mod N) → False  (Fermat probable prime
   --      to base A — may still be composite: Carmichael / pseudoprime).
   --  Raises Invalid_Argument if N < 2.
   --  N = 2 → False (prime). Even N > 2 → True.
   function Is_Fermat_Witness (N, A : U64) return Boolean
     with Global => null;

   --  Educational Fermat probable-prime test with a fixed base table
   --  (not a cryptographic RNG). Uses Rounds leading primes from the
   --  fixed educational base list (capped by table length).
   --  N < 2 → False; N = 2 or 3 → True; even N > 2 → False.
   --  WARNING: Carmichael numbers pass for every base coprime to N.
   function Is_Fermat_Probable_Prime
     (N      : U64;
      Rounds : Positive := 8) return Boolean
     with Global => null;

   --  Same test over an explicit caller-supplied Bases array (bases with
   --  A ≥ N are skipped). Empty Bases → True for odd N ≥ 3 (no witness
   --  tried) — educational foot-gun; prefer the Rounds overload.
   function Is_Fermat_Probable_Prime
     (N     : U64;
      Bases : Base_List) return Boolean
     with Global => null;

   --  True if N is one of a small hard-coded educational Carmichael table
   --  (561, 1105, 1729, 2465, 2821, 6601, 8911). Not a general Carmichael
   --  detector.
   function Is_Carmichael_Example (N : U64) return Boolean
     with Global => null;

end Fermat_Primality_Test;
