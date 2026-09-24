--  Congruence of squares — Ada 2023 educational package.
--  Integer-factorization primitive: if x² ≡ y² (mod n) and
--  x ≢ ±y (mod n), then gcd(|x−y|, n) and gcd(x+y, n) are
--  nontrivial factors of n.
--  Primary source:
--  https://en.wikipedia.org/wiki/Congruence_of_squares
--  Siblings: Ada-Dixon, Ada-Quadratic-Sieve, Ada-Fermat-Factorization.
--  Educational toy only — NOT a production Dixon / QS / NFS.

pragma Ada_2022;

package Congruence_Of_Squares
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Educational upper bound for Factor / Find_* demos (classroom N).
   Factor_Search_Max : constant U64 := 1_000_000;

   --  Default trial / step caps for the optional search demos.
   Default_Max_Steps  : constant Natural := 200_000;
   Default_Max_Trials : constant Natural := 200_000;

   ------------------------------------------------------------------
   --  Factor pair (F1 × F2 = N when a CoS split succeeds)
   ------------------------------------------------------------------

   --  On success: 1 < F1 ≤ F2 < N and F1 * F2 = N (when both known).
   --  On failure / trivial congruence: F1 = 0, F2 = 0.
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
   --  Congruence-of-squares predicates
   ------------------------------------------------------------------

   --  True iff X² ≡ Y² (mod N). Raises Invalid_Argument if N = 0.
   function Squares_Congruent (X, Y, N : U64) return Boolean
     with Global => null;

   --  True iff X ≡ Y (mod N) or X ≡ −Y (mod N).
   --  Raises Invalid_Argument if N = 0.
   function Is_Trivial_Pair (X, Y, N : U64) return Boolean
     with Global => null;

   --  True iff X² ≡ Y² (mod N) AND X ≢ ±Y (mod N) — the nontrivial
   --  congruence of squares used by factorization algorithms.
   --  Raises Invalid_Argument if N = 0.
   function Is_Nontrivial_Congruence (X, Y, N : U64) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  Factor extraction from a known congruence
   ------------------------------------------------------------------

   --  If (X, Y, N) is a nontrivial congruence of squares, return a
   --  nontrivial factor of N (gcd(|X−Y|, N) or gcd(X+Y, N)).
   --  Returns 0 when the congruence does not hold or is trivial
   --  (sentinel; caller may continue searching).
   --  Raises Invalid_Argument if N < 2.
   function Factor_From_Congruence (X, Y, N : U64) return U64
     with Global => null;

   --  Same check; on success returns (F1, F2) with F1 = gcd(|X−Y|, N),
   --  F2 = N / F1 (ordered so F1 ≤ F2). On failure → (0, 0).
   --  Raises Invalid_Argument if N < 2.
   function Factors_From_Congruence (X, Y, N : U64) return Factor_Pair
     with Global => null;

   ------------------------------------------------------------------
   --  Optional classroom demos (toy bounds)
   ------------------------------------------------------------------

   --  Fermat-style search: a := ceil(√N), a := a + 1, …; whenever
   --  a² rem N is a perfect square b² with a ≢ ±b (mod N), return the
   --  Factor_Pair from that congruence. Also hits the classical Fermat
   --  equality a² − N = b² (then a² ≡ b² (mod N) with residue 0).
   --  N < 2 → Invalid_Argument. N > Factor_Search_Max → Invalid_Argument.
   --  Even N > 2 → (2, N/2) immediately. Exhaustion → (0, 0).
   function Find_Fermat_Style_Congruence
     (N         : U64;
      Max_Steps : Natural := Default_Max_Steps) return Factor_Pair
     with Global => null;

   --  Random-square style: sample pseudo-random A (seeded LCG), check
   --  whether A² rem N is a perfect square B² forming a nontrivial CoS.
   --  N < 2 → Invalid_Argument. N > Factor_Search_Max → Invalid_Argument.
   --  Even N > 2 → (2, N/2). Exhaustion → (0, 0).
   function Find_Random_Square_Congruence
     (N          : U64;
      Seed       : U64     := 1;
      Max_Trials : Natural := Default_Max_Trials) return Factor_Pair
     with Global => null;

   --  Educational factorizer: even → 2; else Fermat-style CoS, then
   --  random-square CoS, then trial SPF. Returns a nontrivial factor,
   --  or 1 if N is prime / search failed. Raises Invalid_Argument if
   --  N = 0 or N > Factor_Search_Max.
   function Factor
     (N    : U64;
      Seed : U64 := 1) return U64
     with Global => null;

end Congruence_Of_Squares;
