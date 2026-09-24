--  Dixon's factorization method (random squares) — Ada 2023 educational
--  package. Classroom sketch of John D. Dixon's 1981 factor-base algorithm.
--  Toy U64 demos only — NOT a production Dixon / QS / NFS.
--  Primary source:
--  https://en.wikipedia.org/wiki/Dixon's_factorization_method
--  Siblings: Ada-Quadratic-Sieve, Ada-Fermat-Factorization.
--  Next (educational): Congruence of squares (shared CoS core survey).

pragma Ada_2022;

package Dixon
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Educational upper bound for Factor_Dixon (random + smooth + CoS).
   Factor_Dixon_Max : constant U64 := 10_000_000;

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

   --  Trial primality (wheel after 2/3). N < 2 → False.
   function Is_Prime_Trial (N : U64) return Boolean
     with Global => null;

   --  Least prime factor of N via trial. N < 2 → Invalid_Argument.
   --  If N is prime, returns N.
   function Smallest_Prime_Factor (N : U64) return U64
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

   --  Dixon factor base for bound B: all primes p ≤ B (no Legendre filter;
   --  contrast QS which keeps only (N/p)=1). B < 2 → empty.
   function Dixon_Factor_Base (B : U64) return Factor_Base
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
   --  Congruence-of-squares educational core
   ------------------------------------------------------------------

   --  One relation: A² ≡ B (mod N) with B B-smooth (caller responsibility).
   type Relation is record
      A : U64;  --  random (or chosen) square root side
      B : U64;  --  A² rem N, required B-smooth w.r.t. Base
   end record;

   type Relation_List is array (Positive range <>) of Relation;

   --  Combine supplied relations via GF(2) linear algebra on exponent
   --  parities. If a dependency yields X² ≡ Y² (mod N) with
   --  X ≢ ±Y (mod N), return a nontrivial factor gcd(|X−Y|, N).
   --  Returns 0 if no nontrivial factor is found from the matrix.
   --  Raises Invalid_Argument if N < 2, Base is empty, a relation is
   --  not Base-smooth, or B ≠ A² rem N.
   function Factor_Via_Congruence_Of_Squares
     (N         : U64;
      Relations : Relation_List;
      Base      : Factor_Base) return U64
     with Global => null;

   --  Educational Dixon random-squares factorizer.
   --  For N ≤ Factor_Dixon_Max: build factor base (primes ≤ Smoothness),
   --  sample pseudo-random A, collect B-smooth values of A² rem N, then
   --  Factor_Via_Congruence_Of_Squares. Returns a nontrivial factor of N,
   --  or 1 on failure / N prime / N < 2.
   --  Raises Invalid_Argument if N = 0 or N > Factor_Dixon_Max.
   --  Even N > 2 → returns 2 immediately.
   --  Seed selects the LCG starting state (reproducible classroom demos).
   function Factor_Dixon
     (N          : U64;
      Smoothness : U64 := 100;
      Seed       : U64 := 1) return U64
     with Global => null;

   --  Alias for Factor_Dixon (same defaults).
   function Factor
     (N          : U64;
      Smoothness : U64 := 100;
      Seed       : U64 := 1) return U64
     with Global => null;

end Dixon;
