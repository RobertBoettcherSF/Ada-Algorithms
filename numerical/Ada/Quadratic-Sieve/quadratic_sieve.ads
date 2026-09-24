--  Quadratic sieve (QS) — Ada 2023 educational package.
--  Classroom sketch of Carl Pomerance's quadratic sieve for integer
--  factorization. Toy U64 demos only — NOT a production QS / MPQS.
--  Primary source:
--  https://en.wikipedia.org/wiki/Quadratic_sieve
--  Siblings: Ada-Trial-Division, Ada-Special-Number-Field-Sieve.
--  Next (educational): prime-factorization algorithm survey;
--  Shor already exists elsewhere (skipped).

pragma Ada_2022;

package Quadratic_Sieve
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Educational upper bound for Factor_QS (scan + smoothness + CoS).
   Factor_QS_Max : constant U64 := 10_000_000;

   ------------------------------------------------------------------
   --  Modular / trial helpers (self-contained; no sibling `with`)
   ------------------------------------------------------------------

   --  (A * B) mod M without intermediate overflow (Unsigned_128 product).
   --  Raises Invalid_Argument if M = 0.
   function Mul_Mod (A, B, M : U64) return U64
     with Global => null;

   --  (Base ^ Exp) mod Modulus via binary exponentiation + Mul_Mod.
   --  Raises Invalid_Argument if Modulus = 0.
   function Mod_Pow (Base, Exp, Modulus : U64) return U64
     with Global => null;

   --  Euclidean gcd. Gcd (0, 0) = 0.
   function Gcd (A, B : U64) return U64
     with Global => null;

   --  Integer square root floor(sqrt(N)), no Float.
   function Floor_Sqrt (N : U64) return U64
     with Global => null;

   --  ceil(sqrt(N)): Floor_Sqrt(N) if perfect square, else Floor_Sqrt(N)+1.
   --  N = 0 → 0.
   function Ceil_Sqrt (N : U64) return U64
     with Global => null;

   --  Trial primality (wheel after 2/3). N < 2 → False.
   function Is_Prime_Trial (N : U64) return Boolean
     with Global => null;

   --  Least prime factor of N via trial. N < 2 → Invalid_Argument.
   --  If N is prime, returns N.
   function Smallest_Prime_Factor (N : U64) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  Legendre symbol (for QS factor-base selection)
   ------------------------------------------------------------------

   --  Legendre (A / P) ∈ {-1, 0, +1} via Euler's criterion.
   --  P must be an odd prime (educational; not re-proven here).
   --  Raises Invalid_Argument if P < 3 or P even.
   --  Returns 0 if A ≡ 0 (mod P); +1 if A is quadratic residue mod P;
   --  -1 if non-residue. Used to keep only primes with (N/p)=1 in the FB.
   function Legendre (A, P : U64) return Integer
     with Global => null;

   ------------------------------------------------------------------
   --  Smoothness / factor base
   ------------------------------------------------------------------

   --  Ordered list of primes used as a factor base (ascending).
   type Factor_Base is array (Positive range <>) of U64;

   --  Exponent vector aligned with a Factor_Base'Range (parity or full).
   type Exponent_Vector is array (Positive range <>) of Natural;

   --  First primes ≤ B (trial sieve). B < 2 → empty. Educational size.
   function Primes_Up_To (B : U64) return Factor_Base
     with Global => null;

   --  QS factor base for N: primes p ≤ B with Legendre(N/p)=1, plus 2
   --  when 2 ≤ B (N odd ⇒ N ≡ 1 (mod 8) is classical; we still include 2
   --  for educational smoothness of even Q). N < 2 → Invalid_Argument.
   --  B < 2 → empty.
   function QS_Factor_Base (N, B : U64) return Factor_Base
     with Global => null;

   --  True iff every prime factor of N is in Base (N fully factors).
   --  N = 0 → Invalid_Argument. N = 1 → True (empty product).
   function Is_B_Smooth (N : U64; Base : Factor_Base) return Boolean
     with Global => null;

   --  Full exponents of N over Base if B-smooth; otherwise raises
   --  Invalid_Argument. Length = Base'Length. N = 0 → Invalid_Argument.
   function Smooth_Exponents
     (N : U64; Base : Factor_Base) return Exponent_Vector
     with Global => null;

   ------------------------------------------------------------------
   --  Quadratic polynomial Q(x) = x² − N  (single-polynomial QS)
   ------------------------------------------------------------------

   --  Q(X, N) := X² rem N  (educational remainder used as the smooth
   --  target). When X = Ceil_Sqrt(N) + t for small t ≥ 0, this equals
   --  (Ceil_Sqrt(N)+t)² − N as long as X² < 2N. Raises Invalid_Argument
   --  if N = 0.
   function Q_Of (X, N : U64) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  Congruence-of-squares educational core
   ------------------------------------------------------------------

   --  One relation: X² ≡ Q (mod N) with Q B-smooth (caller responsibility).
   type Relation is record
      X : U64;
      Q : U64;  --  typically X² rem N, required B-smooth w.r.t. Base
   end record;

   type Relation_List is array (Positive range <>) of Relation;

   --  Combine supplied relations via GF(2) linear algebra on exponent
   --  parities. If a dependency yields X² ≡ Y² (mod N) with
   --  X ≢ ±Y (mod N), return a nontrivial factor gcd(|X−Y|, N).
   --  Returns 0 if no nontrivial factor is found from the matrix.
   --  Raises Invalid_Argument if N < 2, Base is empty, a relation is
   --  not Base-smooth, or Q ≠ X² rem N.
   function Factor_Via_Congruence_Of_Squares
     (N         : U64;
      Relations : Relation_List;
      Base      : Factor_Base) return U64
     with Global => null;

   --  Educational single-polynomial quadratic sieve.
   --  For N ≤ Factor_QS_Max: build a QS factor base (primes p ≤
   --  Smoothness with (N/p)=1), scan X ≥ Ceil_Sqrt(N), collect B-smooth
   --  values of Q(X)=X² rem N, then Factor_Via_Congruence_Of_Squares.
   --  Returns a nontrivial factor of N, or 1 on failure / N prime / N < 2.
   --  Raises Invalid_Argument if N = 0 or N > Factor_QS_Max.
   --  Even N > 2 → returns 2 immediately.
   --  Multiple-polynomial QS (MPQS) is documented in the README only.
   function Factor_QS
     (N          : U64;
      Smoothness : U64 := 100) return U64
     with Global => null;

end Quadratic_Sieve;
