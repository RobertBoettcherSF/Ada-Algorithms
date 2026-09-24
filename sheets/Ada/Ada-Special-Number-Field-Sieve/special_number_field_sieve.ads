--  Special Number Field Sieve (SNFS) — Ada 2023 educational package.
--  Classroom sketch of SNFS / congruence-of-squares factoring for integers
--  of special form (e.g. r^e ± s). NOT a production NFS implementation:
--  no algebraic number fields, no lattice sieving — toy U64 demos only.
--  Primary source:
--  https://en.wikipedia.org/wiki/Special_number_field_sieve
--  Siblings: Ada-Trial-Division, Ada-Primality-Test.
--  Next (educational): Quadratic sieve; Shor already exists elsewhere.

pragma Ada_2022;

package Special_Number_Field_Sieve
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Educational upper bound for Toy_Factor_SNFS_Like (scan + smoothness).
   Toy_Factor_Max : constant U64 := 1_000_000;

   ------------------------------------------------------------------
   --  Taxonomy — special-form sketches
   ------------------------------------------------------------------

   --  Catalogue of SNFS-friendly shapes (tiny-parameter detectors only).
   type Special_Form_Kind is
     (Not_Special,
      Mersenne_Like,       --  2^k − 1
      Fermat_Like,         --  2^(2^k) + 1  (tiny k)
      Power_Difference,    --  a^e − b^e   (tiny a,b,e)
      Power_Sum);          --  a^e + b^e   (tiny a,b,e)

   function Form_Name (K : Special_Form_Kind) return String
     with Global => null;

   --  True if N matches any tiny-parameter special form below.
   --  N < 2 → False. Educational heuristic, not a complete SNFS oracle.
   function Is_Special_Form (N : U64) return Boolean
     with Global => null;

   --  First matching kind (priority: Mersenne, Fermat, Power_Diff, Power_Sum).
   function Classify_Special_Form (N : U64) return Special_Form_Kind
     with Global => null;

   --  True iff N = 2^K − 1 for some K ≥ 2 (and N fits U64).
   function Is_Mersenne_Like (N : U64) return Boolean
     with Global => null;

   --  True iff N = 2^(2^K) + 1 for some K ≤ 5 (F0..F5 in U64).
   function Is_Fermat_Like (N : U64) return Boolean
     with Global => null;

   --  True iff N = A^E − B^E for some 2 ≤ E ≤ 12, 2 ≤ A ≤ 32, 1 ≤ B < A
   --  with no intermediate overflow (tiny classroom params).
   function Is_Power_Difference (N : U64) return Boolean
     with Global => null;

   --  True iff N = A^E + B^E for some 2 ≤ E ≤ 12, 1 ≤ A,B ≤ 32, A ≥ B
   --  with no intermediate overflow (tiny classroom params).
   function Is_Power_Sum (N : U64) return Boolean
     with Global => null;

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

   --  One relation: X^2 ≡ Q (mod N) with Q B-smooth (caller responsibility).
   type Relation is record
      X : U64;
      Q : U64;  --  typically X^2 rem N, required B-smooth w.r.t. Base
   end record;

   type Relation_List is array (Positive range <>) of Relation;

   --  Combine supplied relations via GF(2) linear algebra on exponent
   --  parities. If a dependency yields X^2 ≡ Y^2 (mod N) with
   --  X ≢ ±Y (mod N), return a nontrivial factor gcd(|X−Y|, N).
   --  Returns 0 if no nontrivial factor is found from the matrix.
   --  Raises Invalid_Argument if N < 2, Base is empty, a relation is
   --  not Base-smooth, or Q ≠ X^2 rem N.
   function Factor_Via_Congruence_Of_Squares
     (N         : U64;
      Relations : Relation_List;
      Base      : Factor_Base) return U64
     with Global => null;

   --  Toy SNFS-*like* factor: for N ≤ Toy_Factor_Max, scan X above
   --  floor(sqrt(N)), collect B-smooth values of X^2 rem N over a small
   --  factor base, then call Factor_Via_Congruence_Of_Squares.
   --  Demonstrates the NFS *idea* without algebraic number fields.
   --  Returns a nontrivial factor, or 0 on failure / N prime / N < 2
   --  (raises Invalid_Argument if N = 0 or N > Toy_Factor_Max).
   --  Even N → returns 2 when N > 2.
   function Toy_Factor_SNFS_Like
     (N          : U64;
      Smoothness : U64 := 50) return U64
     with Global => null;

end Special_Number_Field_Sieve;
