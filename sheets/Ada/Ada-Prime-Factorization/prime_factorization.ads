--  Prime_Factorization — Ada 2023 educational survey package for
--  Wikipedia "Integer factorization" / sheet row "prime factorization
--  algorithm": taxonomy + self-contained sketches of trial division,
--  Fermat factorization, and Pollard's rho (Floyd). Sibling packages
--  (Trial Division, QS, SNFS, Fermat, ECM, GNFS, Shor, …) are linked
--  in the README only — this repo does not `with` them.
--  Primary source: https://en.wikipedia.org/wiki/Integer_factorization

pragma Ada_2022;

package Prime_Factorization
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Educational cap on Fermat a-steps (a := a+1) before giving up.
   Fermat_Default_Max_Steps : constant Natural := 1_000_000;

   --  Educational cap on Pollard's rho outer iterations.
   Rho_Default_Max_Steps : constant Natural := 100_000;

   ------------------------------------------------------------------
   --  Taxonomy (special-purpose vs general-purpose)
   ------------------------------------------------------------------

   --  Survey catalogue. Special-purpose running time depends on the
   --  unknown factors / form of N; general-purpose depends only on the
   --  size of N (Kraitchik / congruence-of-squares family). Shor is the
   --  quantum polynomial-time catalogue entry. Default is a practical
   --  educational hybrid (trial, then rho on remaining composites).
   type Method_Kind is
     (Trial_Division,
      Fermat,
      Pollard_Rho,
      Pollard_P1,
      Quadratic_Sieve,
      SNFS,
      GNFS,
      ECM,
      Shor_Catalogue,
      Default);

   function Method_Name (M : Method_Kind) return String
     with Global => null;

   --  Wikipedia Category 1 / special-purpose (incl. SNFS, ECM, trial).
   function Is_Special_Purpose (M : Method_Kind) return Boolean
     with Global => null;

   --  Wikipedia Category 2 / general-purpose (QS, GNFS; Default hybrid).
   function Is_General (M : Method_Kind) return Boolean
     with Global => null;

   function Is_Implemented (M : Method_Kind) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  Factor representation (prime powers with multiplicity)
   ------------------------------------------------------------------

   type Prime_Power is record
      Prime    : U64;
      Exponent : Natural;
   end record;

   --  Unconstrained list of distinct prime powers (secondary-stack
   --  return). Empty for N = 1. Ordered by increasing Prime.
   type Factor_List is array (Positive range <>) of Prime_Power;

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

   --  True iff N is prime by trial division up to floor(√N).
   --  N < 2 → False. N = 0 is allowed (returns False; no raise).
   function Is_Prime_Trial (N : U64) return Boolean
     with Global => null;

   --  Integer square root floor(√N), self-contained (no Float).
   --  Overflow-safe binary search on U64. N = 0 → 0.
   function Floor_Sqrt (N : U64) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  1. Trial division
   ------------------------------------------------------------------

   --  Least prime factor of N (wheel after 2). N = 0 or N = 1 → raise
   --  Invalid_Argument. If N is prime, returns N.
   function Trial_Division_Factor (N : U64) return U64
     with Global => null;

   --  Complete prime-power factorization by trial peeling.
   --  N = 0 → Invalid_Argument. N = 1 → empty list.
   function Factorize_Trial (N : U64) return Factor_List
     with Global => null;

   ------------------------------------------------------------------
   --  2. Fermat factorization (odd N close to a square)
   ------------------------------------------------------------------

   --  Classic Fermat: a := ceil(√N); while a²−N is not square, a := a+1;
   --  then return a−b with b = √(a²−N). Requires odd N ≥ 3. Even N →
   --  returns 2 when N > 2. N < 2 → Invalid_Argument. If Max_Steps is
   --  exhausted without a hit, returns 1 (failure sentinel). When N is
   --  prime the loop finds the trivial split 1 × N after ~ (N−1)/2
   --  steps — use Max_Steps to stay educational.
   function Fermat_Factor
     (N         : U64;
      Max_Steps : Natural := Fermat_Default_Max_Steps) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  3. Pollard's rho (Floyd cycle toy)
   ------------------------------------------------------------------

   --  Floyd tortoise/hare on f(x) = x² + C (mod N). Returns a non-
   --  trivial factor when found; returns 1 on failure / Max_Steps
   --  exhaustion; returns N when N is prime (detected by trial for
   --  tiny N, else may return 1). N < 2 → Invalid_Argument. Even N > 2
   --  → 2. Educational only — not cryptographic.
   function Pollard_Rho_Factor
     (N         : U64;
      Seed      : U64    := 2;
      C         : U64    := 1;
      Max_Steps : Natural := Rho_Default_Max_Steps) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  4. Dispatcher / Default hybrid
   ------------------------------------------------------------------

   --  Route to an implemented single-factor sketch. Catalogue-only
   --  methods (QS, SNFS, GNFS, ECM, Shor, Pollard's p−1) raise
   --  Invalid_Argument. Default: peel small trial factors; if N still
   --  composite try Pollard's rho; fall back to trial least factor.
   --  Returns a non-trivial factor when one is found; N when N is
   --  prime; raises if N < 2.
   function Factor
     (N      : U64;
      Method : Method_Kind := Default) return U64
     with Global => null;

   --  Complete factorization via repeated Default Factor calls
   --  (trial + rho hybrid). N = 0 → Invalid_Argument. N = 1 → empty.
   function Factorize (N : U64) return Factor_List
     with Global => null;

end Prime_Factorization;
