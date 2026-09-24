--  Cipolla's algorithm — modular square root via Fp2 — Ada 2023 educational
--  package. Solve x^2 ≡ n (mod p) for odd prime p on unsigned 64-bit integers.
--  Self-contained modular arithmetic (Mul_Mod / Mod_Pow) and Fp2 ring ops.
--  Primary source:
--  https://en.wikipedia.org/wiki/Cipolla%27s_algorithm
--  Not for composite moduli (equivalent to factoring).
--  Sibling: Tonelli–Shanks. Next: Berlekamp root finding.

pragma Ada_2022;

package Cipolla
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   --  Residues and primes live in the full unsigned 64-bit range.
   --  Tests and educational use focus on small/medium primes where
   --  trial division for primality is comfortable.
   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Upper bound for educational trial-division primality of P inside
   --  Modular_Sqrt. For larger odd P the caller must supply a prime;
   --  only P < 2 and even P ≠ 2 are still rejected.
   Max_Trial_Prime : constant U64 := 1_000_000;

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

   --  Greatest common divisor (binary / Euclidean). Gcd (0, 0) = 0.
   function Gcd (A, B : U64) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  Primality (educational trial division)
   ------------------------------------------------------------------

   --  Exact trial-division primality for educational sizes.
   --  N < 2 → False; N = 2 or 3 → True; even N > 2 → False.
   function Is_Prime_Trial (N : U64) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  Legendre / quadratic residue
   ------------------------------------------------------------------

   --  Legendre symbol (N / P) via Euler's criterion:
   --  N^((P-1)/2) mod P ∈ {0, 1, P-1} → {0, 1, -1}.
   --  Requires odd prime P (educational). Raises Invalid_Argument if
   --  P < 3 or P even. Returns 0 when N ≡ 0 (mod P).
   function Legendre (N, P : U64) return Integer
     with Global => null;

   --  True iff Legendre (N, P) = 1, or the trivial residue cases for
   --  P = 2 / N ≡ 0. Raises Invalid_Argument for invalid P (< 2 or
   --  even ≠ 2). For P = 2 every residue class has a square root.
   function Is_Quadratic_Residue (N, P : U64) return Boolean
     with Global => null;

   --  Smallest ω in 0 .. P-1 with Legendre (ω² − N, P) = −1
   --  (Cipolla step 1; ω² − N is a quadratic non-residue).
   --  Requires odd prime P and Legendre (N, P) = 1 with N ≢ 0.
   --  Raises Invalid_Argument if P is invalid or no such ω exists
   --  (should not happen for odd prime P and quadratic residue N).
   function Find_Omega (N, P : U64) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  Modular square root (Cipolla)
   ------------------------------------------------------------------

   --  One square root Root of N modulo prime P when it exists.
   --  Found = True  ⇒  Root^2 ≡ N (mod P); the other root is P - Root
   --  when Root ≠ 0.
   --  Found = False ⇒  no square root (Legendre = -1); Root is unset
   --  (do not use).
   --  Raises Invalid_Argument if P < 2, or P even and P ≠ 2, or
   --  (when P ≤ Max_Trial_Prime) P is composite.
   --  Algorithm (odd prime, residue): find ω with Legendre(ω²−N,P)=−1,
   --  then compute (ω + √(ω²−N))^((P+1)/2) in Fp2 = Fp[√(ω²−N)].
   procedure Modular_Sqrt
     (N     : U64;
      P     : U64;
      Root  : out U64;
      Found : out Boolean)
     with Global => null;

   --  Function form: returns one root. Raises Invalid_Argument if P is
   --  invalid/composite (as above) or if no square root exists.
   --  Document ±Root: if R is returned then P - R is the other root
   --  (when R ≠ 0).
   function Modular_Sqrt (N, P : U64) return U64
     with Global => null;

end Cipolla;
