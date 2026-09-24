--  Integer factorization — Ada 2023 educational survey package.
--  Self-contained U64 classroom sketches of classical methods from
--  Wikipedia "Integer factorization": trial division, Fermat,
--  Pollard's rho, and congruence-of-squares factor extraction, plus
--  a Factor / Factorize driver with documented educational bounds.
--  Sibling packages (Dixon, QS, ECM, GNFS, Pollard's p−1, …) are
--  documented in the README only — this repo does not `with` them.
--  Primary source:
--  https://en.wikipedia.org/wiki/Integer_factorization
--  Related (independent): Ada-Prime-Factorization — do not `with`.

pragma Ada_2022;

package Integer_Factorization
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Educational upper bound for Factor / Factorize classroom demos.
   Factor_Max : constant U64 := 10_000_000;

   --  Educational cap on Fermat a-steps (a := a + 1) before giving up.
   Fermat_Default_Max_Steps : constant Natural := 1_000_000;

   --  Educational cap on Pollard's rho outer iterations.
   Rho_Default_Max_Steps : constant Natural := 100_000;

   ------------------------------------------------------------------
   --  Factor representations
   ------------------------------------------------------------------

   --  Prime power with multiplicity (complete factorizations).
   type Prime_Power is record
      Prime    : U64;
      Exponent : Natural;
   end record;

   --  Unconstrained list of distinct prime powers (secondary-stack
   --  return). Empty for N = 1. Ordered by increasing Prime.
   type Factor_List is array (Positive range <>) of Prime_Power;

   --  On success: 1 ≤ F1 ≤ F2 and F1 * F2 = N (when both known).
   --  On failure: F1 = 0, F2 = 0.
   type Factor_Pair is record
      F1 : U64 := 0;
      F2 : U64 := 0;
   end record;

   ------------------------------------------------------------------
   --  Modular / trial helpers (self-contained; no sibling `with`)
   ------------------------------------------------------------------

   --  (A * B) mod M without intermediate overflow (Unsigned_128 product).
   --  Raises Invalid_Argument if M = 0.
   function Mul_Mod (A, B, M : U64) return U64
     with Global => null;

   --  Euclidean gcd. Gcd (0, 0) = 0.
   function Gcd (A, B : U64) return U64
     with Global => null;

   --  Integer square root floor(√N), no Float.
   function Floor_Sqrt (N : U64) return U64
     with Global => null;

   --  Ceiling of √N. Perfect square → Floor_Sqrt (N); else Floor_Sqrt + 1.
   --  N = 0 → 0.
   function Ceil_Sqrt (N : U64) return U64
     with Global => null;

   --  True iff N is a perfect square (Floor_Sqrt (N)² = N).
   function Is_Perfect_Square (N : U64) return Boolean
     with Global => null;

   --  Trial primality (wheel after 2/3). N < 2 → False.
   function Is_Prime_Trial (N : U64) return Boolean
     with Global => null;

   --  Least prime factor of N via trial. N < 2 → Invalid_Argument.
   --  If N is prime, returns N.
   function Smallest_Prime_Factor (N : U64) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  1. Trial division factorization
   ------------------------------------------------------------------

   --  Alias of Smallest_Prime_Factor (least prime factor).
   function Trial_Division_Factor (N : U64) return U64
     with Global => null;

   --  Complete prime-power factorization by trial peeling.
   --  N = 0 → Invalid_Argument. N = 1 → empty list.
   --  Educational: intended for small classroom N (see Factor_Max).
   function Factorize_Trial (N : U64) return Factor_List
     with Global => null;

   ------------------------------------------------------------------
   --  2. Fermat factorization sketch (nearby factors)
   ------------------------------------------------------------------

   --  Classic Fermat: a := ceil(√N); while a² − N is not square,
   --  a := a + 1; then return a − b with b = √(a² − N).
   --  N < 2 → Invalid_Argument. Even N > 2 → 2. Even N = 2 → 2.
   --  Perfect-square N → √N. Exhaustion / failure → 1 (sentinel).
   --  Fast when the unknown factors are close.
   function Fermat_Factor
     (N         : U64;
      Max_Steps : Natural := Fermat_Default_Max_Steps) return U64
     with Global => null;

   --  Same search; returns ordered (F1, F2) with F1 * F2 = N, or
   --  (0, 0) on Max_Steps exhaustion. Even N > 2 → (2, N/2).
   --  N = 2 → (1, 2). Perfect square → (√N, √N).
   function Fermat_Factor_Pair
     (N         : U64;
      Max_Steps : Natural := Fermat_Default_Max_Steps) return Factor_Pair
     with Global => null;

   ------------------------------------------------------------------
   --  3. Pollard's rho sketch (Floyd; f(x) = x² + C)
   ------------------------------------------------------------------

   --  Floyd tortoise/hare on f(x) = x² + C (mod N). Seeded starting
   --  state (Seed rem N). Returns a nontrivial factor when found;
   --  returns 1 on failure / Max_Steps exhaustion; returns N when N
   --  is prime (trial). N < 2 → Invalid_Argument. Even N > 2 → 2.
   function Pollard_Rho_Factor
     (N         : U64;
      Seed      : U64     := 2;
      C         : U64     := 1;
      Max_Steps : Natural := Rho_Default_Max_Steps) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  4. Congruence-of-squares factor extraction
   ------------------------------------------------------------------

   --  True iff X² ≡ Y² (mod N). Raises Invalid_Argument if N = 0.
   function Squares_Congruent (X, Y, N : U64) return Boolean
     with Global => null;

   --  True iff X ≡ Y (mod N) or X ≡ −Y (mod N).
   --  Raises Invalid_Argument if N = 0.
   function Is_Trivial_Pair (X, Y, N : U64) return Boolean
     with Global => null;

   --  True iff X² ≡ Y² (mod N) AND X ≢ ±Y (mod N).
   --  Raises Invalid_Argument if N = 0.
   function Is_Nontrivial_Congruence (X, Y, N : U64) return Boolean
     with Global => null;

   --  If (X, Y, N) is a nontrivial congruence of squares, return a
   --  nontrivial factor of N (gcd(|X−Y|, N) or gcd(X+Y, N)).
   --  Returns 0 when the congruence does not hold or is trivial.
   --  Raises Invalid_Argument if N < 2.
   function Factor_From_Congruence (X, Y, N : U64) return U64
     with Global => null;

   --  Same check; on success returns (F1, F2) with F1 = gcd(|X−Y|, N),
   --  F2 = N / F1 (ordered so F1 ≤ F2). On failure → (0, 0).
   --  Raises Invalid_Argument if N < 2.
   function Factors_From_Congruence (X, Y, N : U64) return Factor_Pair
     with Global => null;

   ------------------------------------------------------------------
   --  5. Driver Factor / Factorize (classroom strategy)
   ------------------------------------------------------------------

   --  Educational single-factor driver for N ≤ Factor_Max:
   --    even → 2; prime → N; else small trial SPF; if still composite
   --    try Fermat (nearby factors), then Pollard's rho, then trial.
   --  Raises Invalid_Argument if N = 0 or N > Factor_Max.
   --  N = 1 → Invalid_Argument (no nontrivial factor).
   function Factor
     (N    : U64;
      Seed : U64 := 2) return U64
     with Global => null;

   --  Complete factorization via repeated Factor / trial peeling for
   --  N ≤ Factor_Max. N = 0 → Invalid_Argument. N = 1 → empty.
   --  N > Factor_Max → Invalid_Argument.
   function Factorize (N : U64) return Factor_List
     with Global => null;

end Integer_Factorization;
