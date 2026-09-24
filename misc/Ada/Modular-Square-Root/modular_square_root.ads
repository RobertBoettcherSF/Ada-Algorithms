--  Modular_Square_Root — Ada 2023 educational survey package for
--  Wikipedia "Modular square root" / quadratic residue: solve
--  x^2 ≡ n (mod m). Taxonomy + self-contained sketches of the p≡3 (mod 4)
--  fast path, Tonelli–Shanks, brute force for tiny moduli, and a small
--  CRT combiner for mod pq. Cipolla and general composite CRT are
--  catalogue-only (sibling packages). This repo does not `with` siblings.
--  Primary sources:
--  https://en.wikipedia.org/wiki/Modular_square_root
--  https://en.wikipedia.org/wiki/Quadratic_residue
--  Siblings: Ada-Tonelli-Shanks, Ada-Cipolla, Ada-Berlekamp-Root-Finding.
--  Next: LLL (Lenstra–Lenstra–Lovász).

pragma Ada_2022;

package Modular_Square_Root
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Educational trial-division primality of P inside Sqrt_Mod_Prime.
   --  For larger odd P the caller must supply a prime; only P < 2 and
   --  even P ≠ 2 are still rejected.
   Max_Trial_Prime : constant U64 := 1_000_000;

   --  Brute_Force_Sqrt accepts moduli M ≤ this bound (tiny educational).
   Max_Brute_Modulus : constant U64 := 10_000;

   ------------------------------------------------------------------
   --  Taxonomy
   ------------------------------------------------------------------

   --  Survey catalogue. Catalogue-only entries point at README siblings.
   type Method_Kind is
     (Tonelli_Shanks,
      Cipolla,
      P_Congruent_3_Mod_4,
      Brute_Force,
      Catalogue_Composite_CRT);

   function Method_Name (M : Method_Kind) return String
     with Global => null;

   --  True when this package ships a working educational sketch.
   --  Cipolla and Catalogue_Composite_CRT are sibling / README only.
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

   --  Exact trial-division primality for educational sizes.
   --  N < 2 → False; N = 2 or 3 → True; even N > 2 → False.
   function Is_Prime_Trial (N : U64) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  Legendre / quadratic residue (prime modulus)
   ------------------------------------------------------------------

   --  Legendre symbol (N / P) via Euler's criterion:
   --  N^((P-1)/2) mod P ∈ {0, 1, P-1} → {0, 1, -1}.
   --  Requires odd prime P. Raises Invalid_Argument if P < 3 or P even.
   --  Returns 0 when N ≡ 0 (mod P).
   function Legendre (N, P : U64) return Integer
     with Global => null;

   --  True iff a square root of N exists modulo prime P
   --  (Legendre ≥ 0, or every class when P = 2). Raises Invalid_Argument
   --  for invalid P (< 2 or even ≠ 2). Alias name for the survey API.
   function Is_Quadratic_Residue_Prime (N, P : U64) return Boolean
     with Global => null;

   --  Smallest Z in 2 .. P-1 with Legendre (Z, P) = -1.
   --  Raises Invalid_Argument if P is not an odd prime (educational
   --  trial check when P ≤ Max_Trial_Prime) or P = 2.
   function Find_Quadratic_Non_Residue (P : U64) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  1. Sqrt_Mod_Prime — dispatch (p=2 / p≡3 mod 4 / Tonelli–Shanks)
   ------------------------------------------------------------------

   --  One square root Root of N modulo prime P when it exists.
   --  Found = True  ⇒  Root^2 ≡ N (mod P); the other root is P - Root
   --  when Root ≠ 0.
   --  Found = False ⇒  no square root (Legendre = -1); Root is unset.
   --  Dispatch: P = 2 trivial; P ≡ 3 (mod 4) fast exponent; else
   --  self-contained Tonelli–Shanks sketch.
   --  Raises Invalid_Argument if P < 2, or P even and P ≠ 2, or
   --  (when P ≤ Max_Trial_Prime) P is composite.
   procedure Sqrt_Mod_Prime
     (N     : U64;
      P     : U64;
      Root  : out U64;
      Found : out Boolean)
     with Global => null;

   --  Function form: returns one root. Raises Invalid_Argument if P is
   --  invalid/composite (as above) or if no square root exists.
   function Sqrt_Mod_Prime (N, P : U64) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  2. Explicit p ≡ 3 (mod 4) fast path
   ------------------------------------------------------------------

   --  r ≡ N^{(P+1)/4} (mod P). Requires odd prime P with P ≡ 3 (mod 4)
   --  and a quadratic residue N (or N ≡ 0). Raises Invalid_Argument if
   --  P is invalid, P ≢ 3 (mod 4), or Legendre = -1 (function form).
   procedure Sqrt_P_Congruent_3_Mod_4
     (N     : U64;
      P     : U64;
      Root  : out U64;
      Found : out Boolean)
     with Global => null;

   ------------------------------------------------------------------
   --  3. Explicit Tonelli–Shanks (general odd prime; includes fast path)
   ------------------------------------------------------------------

   --  Self-contained Tonelli–Shanks sketch (same core as Sqrt_Mod_Prime
   --  for odd P). Raises Invalid_Argument for invalid P as above.
   procedure Sqrt_Tonelli_Shanks
     (N     : U64;
      P     : U64;
      Root  : out U64;
      Found : out Boolean)
     with Global => null;

   ------------------------------------------------------------------
   --  4. Brute force for tiny moduli (any M ≤ Max_Brute_Modulus)
   ------------------------------------------------------------------

   --  Search x = 0 .. M-1 for x^2 ≡ N (mod M). Works for composite M
   --  (educational oracle). Raises Invalid_Argument if M = 0 or
   --  M > Max_Brute_Modulus.
   procedure Brute_Force_Sqrt
     (N     : U64;
      M     : U64;
      Root  : out U64;
      Found : out Boolean)
     with Global => null;

   ------------------------------------------------------------------
   --  5. Educational CRT combine (mod pq when roots mod p,q known)
   ------------------------------------------------------------------

   --  Given Rp^2 ≡ N (mod P) and Rq^2 ≡ N (mod Q) with gcd(P,Q)=1,
   --  return one R with R ≡ Rp (mod P), R ≡ Rq (mod Q), so
   --  R^2 ≡ N (mod P*Q) when P*Q does not overflow U64.
   --  Raises Invalid_Argument if gcd(P,Q) ≠ 1, P = 0, Q = 0, or
   --  P*Q would wrap past U64'Last.
   --  Sign choices (±Rp, ±Rq) yield up to four roots; call again with
   --  (P-Rp) / (Q-Rq) for the others. Full composite factorisation +
   --  Hensel lift is Catalogue_Composite_CRT (README / siblings).
   function Combine_Roots_CRT (Rp, P, Rq, Q : U64) return U64
     with Global => null;

   --  Modular inverse of A modulo M (extended Euclidean).
   --  Raises Invalid_Argument if gcd(A,M) ≠ 1 or M = 0.
   function Mod_Inv (A, M : U64) return U64
     with Global => null;

end Modular_Square_Root;
