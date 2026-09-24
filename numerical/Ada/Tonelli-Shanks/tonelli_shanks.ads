--  Tonelli–Shanks modular square root — Ada 2023 educational package.
--  Solve r^2 ≡ n (mod p) for odd prime p (and p = 2), on unsigned 64-bit
--  integers. Self-contained modular arithmetic (Mul_Mod / Mod_Pow).
--  Primary source:
--  https://en.wikipedia.org/wiki/Tonelli%E2%80%93Shanks_algorithm
--  Not for composite moduli (equivalent to factoring).
--  Siblings upcoming: Cipolla, Berlekamp root finding, modular square-root
--  survey. Sheet mult-row topics (Toom-Cook etc.) already on GitHub.

pragma Ada_2022;

package Tonelli_Shanks
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

   --  Smallest Z in 2 .. P-1 with Legendre (Z, P) = -1.
   --  Raises Invalid_Argument if P is not an odd prime (educational
   --  trial check when P ≤ Max_Trial_Prime).
   function Find_Quadratic_Non_Residue (P : U64) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  Modular square root
   ------------------------------------------------------------------

   --  One square root Root of N modulo prime P when it exists.
   --  Found = True  ⇒  Root^2 ≡ N (mod P); the other root is P - Root
   --  when Root ≠ 0.
   --  Found = False ⇒  no square root (Legendre = -1); Root is unset
   --  (do not use).
   --  Raises Invalid_Argument if P < 2, or P even and P ≠ 2, or
   --  (when P ≤ Max_Trial_Prime) P is composite.
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

end Tonelli_Shanks;
