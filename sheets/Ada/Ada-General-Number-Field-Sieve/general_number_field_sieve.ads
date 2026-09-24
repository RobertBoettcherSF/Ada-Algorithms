--  General Number Field Sieve (GNFS) — Ada 2023 educational package.
--  Classroom sketch of GNFS / congruence-of-squares factoring for general
--  integers. NOT a production NFS implementation: no algebraic number
--  fields, no lattice sieving — toy U64 demos only.
--  Primary source:
--  https://en.wikipedia.org/wiki/General_number_field_sieve
--  Siblings: Ada-Special-Number-Field-Sieve, Ada-Quadratic-Sieve,
--  Ada-Elliptic-Curve-Method (related).
--  Next (educational): Fermat's factorization method.

pragma Ada_2022;

package General_Number_Field_Sieve
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Educational upper bound for Toy_Factor (scan + smoothness + CoS).
   Toy_Factor_Max : constant U64 := 1_000_000;

   ------------------------------------------------------------------
   --  Taxonomy — factoring families / complexity sketches
   ------------------------------------------------------------------

   --  Classical factoring families contrasted with GNFS (classroom).
   type Factoring_Family is
     (Trial_Division,
      Quadratic_Sieve,
      Special_NFS,
      General_NFS,
      ECM_Like,
      Other);

   function Family_Name (F : Factoring_Family) return String
     with Global => null;

   --  Short L-notation / big-O sketch string for the family (prose helper).
   --  GNFS → "L_n[1/3,(64/9)^{1/3}]"; SNFS → "L_n[1/3,(32/9)^{1/3}]";
   --  QS → "L_n[1/2,1]"; trial → "O(sqrt(n))"; ECM → "L_p[1/2,√2]"; …
   function Heuristic_Complexity (F : Factoring_Family) return String
     with Global => null;

   --  True iff this family is asymptotically in the L_n[1/3, ·] class
   --  (SNFS / GNFS). Educational taxonomy flag — not a runtime oracle.
   function Is_L_One_Third_Family (F : Factoring_Family) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  SNFS vs GNFS contrast (API flags)
   ------------------------------------------------------------------

   --  NFS variant: special-form SNFS vs general GNFS.
   type Nfs_Variant is (General_Nfs, Special_Nfs);

   function Variant_Name (V : Nfs_Variant) return String
     with Global => null;

   --  Leading constant numerator in L_n[1/3,(C/9)^{1/3}]: GNFS → 64, SNFS → 32.
   function Complexity_Constant_Numerator (V : Nfs_Variant) return Natural
     with Global => null;

   --  Educational preference: use SNFS when N has a sparse special form;
   --  otherwise GNFS. Always returns True (documenting the rule).
   function Prefer_Snfs_When_Special_Form return Boolean
     with Global => null;

   --  Recommended variant for a classroom bit-length sketch.
   --  Bits < 2 → Invalid_Argument. Tiny Bits → Trial hint via Other;
   --  mid range → Quadratic_Sieve family mapped to General_Nfs for API;
   --  large → General_Nfs. Always returns a legal Nfs_Variant.
   function Recommended_Variant
     (Bit_Length       : Natural;
      Has_Special_Form : Boolean) return Nfs_Variant
     with Global => null;

   ------------------------------------------------------------------
   --  Pipeline stages (documented enumeration — not a coded sieve)
   ------------------------------------------------------------------

   type Pipeline_Stage is
     (Polynomial_Selection,
      Factor_Base_Setup,
      Sieving,
      Filtering,
      Linear_Algebra,
      Square_Root,
      Gcd_Split);

   function Stage_Name (S : Pipeline_Stage) return String
     with Global => null;

   --  First .. Last stage ordinals for classroom iteration demos.
   function First_Stage return Pipeline_Stage
     with Global => null;

   function Last_Stage return Pipeline_Stage
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

   --  Toy GNFS-*like* factor: for N ≤ Toy_Factor_Max, scan X above
   --  floor(sqrt(N)), collect B-smooth values of X^2 rem N over a small
   --  factor base, then call Factor_Via_Congruence_Of_Squares.
   --  Demonstrates the NFS *idea* without algebraic number fields.
   --  Returns a nontrivial factor, or 0 on failure / N prime / N < 2
   --  (raises Invalid_Argument if N = 0 or N > Toy_Factor_Max).
   --  Even N → returns 2 when N > 2.
   function Toy_Factor
     (N          : U64;
      Smoothness : U64 := 50) return U64
     with Global => null;

end General_Number_Field_Sieve;
