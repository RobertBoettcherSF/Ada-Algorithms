--  AKS primality test (Agrawal–Kayal–Saxena) — Ada 2023 educational package.
--  Deterministic polynomial-time primality (PRIMES in P) for small N only:
--  full AKS needs dense polynomial arithmetic in (Z/nZ)[X]/(X^r−1), which
--  is correct but impractical; this package caps N at Max_Educational_N.
--  Primary source:
--  https://en.wikipedia.org/wiki/AKS_primality_test
--  Siblings: Ada-Baillie-PSW, Ada-Miller-Rabin; next: Primality test survey.

pragma Ada_2022;

package AKS_Primality_Test
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type / educational domain
   ------------------------------------------------------------------

   --  Candidates and moduli live in unsigned 64-bit; the algorithm is
   --  only offered up to Max_Educational_N (dense poly step is O~(r^2 log N)
   --  per witness a, with r = Ω((log N)^2)).
   type U64 is mod 2 ** 64;

   --  Upper bound for Is_Prime_AKS. Chosen so a full cross-check of
   --  2 .. Max_Educational_N against trial division finishes in seconds.
   Max_Educational_N : constant U64 := 500;

   Invalid_Argument : exception;

   ------------------------------------------------------------------
   --  Modular / number-theoretic helpers
   ------------------------------------------------------------------

   --  (A * B) mod M without intermediate overflow (Unsigned_128 product).
   --  Raises Invalid_Argument if M = 0.
   function Mul_Mod (A, B, M : U64) return U64
     with Global => null;

   --  Greatest common divisor (Euclidean algorithm).
   function Gcd (A, B : U64) return U64
     with Global => null;

   --  Floor(log2 N) for N ≥ 1. Raises Invalid_Argument if N = 0.
   function Floor_Log2 (N : U64) return Natural
     with Global => null;

   --  Floor((log2 N)^2) for N ≥ 2 (AKS order threshold).
   --  Raises Invalid_Argument if N < 2.
   function Floor_Log2_Squared (N : U64) return Natural
     with Global => null;

   --  Euler's totient φ(R) for R ≥ 1. Raises Invalid_Argument if R = 0.
   function Totient (R : U64) return U64
     with Global => null;

   --  True iff N = A^B for integers A > 1 and B > 1 (perfect power).
   --  N < 2 → False.
   function Is_Perfect_Power (N : U64) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  AKS building blocks
   ------------------------------------------------------------------

   --  Smallest R ≥ 2 such that ord_R(N) > (log2 N)^2 (Wikipedia step 2).
   --  Skips R that are not coprime to N (order undefined).
   --  Raises Invalid_Argument if N < 2 or N > Max_Educational_N.
   function Find_AKS_R (N : U64) return U64
     with Global => null;

   --  Full educational AKS (2004 / Wikipedia form):
   --    1. perfect power → composite
   --    2. find R with ord_R(N) > (log2 N)^2
   --    3. if 1 < gcd(A,N) < N for some A ≤ R → composite
   --    4. if N ≤ R → prime
   --    5. for A = 1 .. floor(√φ(R)·log2 N): check
   --         (X+A)^N ≡ X^N + A  (mod X^R − 1, N)
   --       any failure → composite; else prime
   --  Raises Invalid_Argument if N < 2 or N > Max_Educational_N.
   function Is_Prime_AKS (N : U64) return Boolean
     with Global => null;

end AKS_Primality_Test;
