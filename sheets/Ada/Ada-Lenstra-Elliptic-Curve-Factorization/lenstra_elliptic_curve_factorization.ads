--  Lenstra elliptic-curve factorization (ECM) — Ada 2023 educational package.
--  Special-purpose algebraic-group factorization: Stage 1 over random
--  Weierstrass curves y² = x³ + ax + b (mod N). When the group order
--  modulo a prime factor p of N is B-smooth, point arithmetic fails with
--  a non-invertible denominator and gcd yields a nontrivial factor.
--  Primary source:
--  https://en.wikipedia.org/wiki/Lenstra_elliptic_curve_factorization
--  Siblings: Ada-Pollards-P-1, Ada-Pollards-Rho, Ada-Quadratic-Sieve.
--  Next (educational / general-purpose): GNFS (README pointer only).

pragma Ada_2022;

package Lenstra_Elliptic_Curve_Factorization
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Default Stage-1 smoothness bound (educational).
   Default_B : constant U64 := 50;

   --  Default number of random curves to try.
   Default_Curves : constant Natural := 40;

   --  Ordered list of primes / words (ascending).
   type U64_Array is array (Positive range <>) of U64;

   ------------------------------------------------------------------
   --  Affine Weierstrass point over Z/NZ
   ------------------------------------------------------------------

   --  Point on y² = x³ + A·x + B (mod N). Infinity is the group identity.
   type Point is record
      X, Y     : U64    := 0;
      Infinity : Boolean := False;
   end record;

   --  Short Weierstrass curve over Z/NZ.
   type Curve is record
      A, B, N : U64 := 0;
   end record;

   --  Result of a curve operation: either a point or a nontrivial factor.
   type Op_Kind is (Ok, Factor_Found);

   type Op_Result (Kind : Op_Kind := Ok) is record
      case Kind is
         when Ok =>
            P : Point;
         when Factor_Found =>
            Factor : U64;
      end case;
   end record;

   --  Result of modular inversion: inverse or gcd-based factor.
   type Inv_Result (Kind : Op_Kind := Ok) is record
      case Kind is
         when Ok =>
            Inv : U64;
         when Factor_Found =>
            Factor : U64;
      end case;
   end record;

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

   --  (A + B) mod M. Raises Invalid_Argument if M = 0.
   function Add_Mod (A, B, M : U64) return U64
     with Global => null;

   --  (A − B) mod M. Raises Invalid_Argument if M = 0.
   function Sub_Mod (A, B, M : U64) return U64
     with Global => null;

   --  Modular inverse of A mod M via extended Euclidean algorithm.
   --  Returns Ok with Inv, or Factor_Found with gcd(A,M) when not
   --  invertible (including when gcd is M itself → Factor = M).
   --  Raises Invalid_Argument if M = 0.
   function Try_Mod_Inv (A, M : U64) return Inv_Result
     with Global => null;

   --  Integer square root floor(√N), self-contained (no Float).
   --  Overflow-safe binary search on U64. N = 0 → 0.
   function Floor_Sqrt (N : U64) return U64
     with Global => null;

   --  True iff N is prime by trial division up to floor(√N).
   --  Wheel after 2/3. N < 2 → False.
   function Is_Prime_Trial (N : U64) return Boolean
     with Global => null;

   --  Primes ≤ Limit (trial). Limit < 2 → empty array.
   --  Educational sizes; not a fast sieve.
   function Primes_Up_To (Limit : U64) return U64_Array
     with Global => null;

   ------------------------------------------------------------------
   --  Elliptic-curve group law (mod N)
   ------------------------------------------------------------------

   --  Point doubling 2·P on Curve C. On a non-invertible denominator,
   --  returns Factor_Found with gcd(denom, N).
   function Double (P : Point; C : Curve) return Op_Result
     with Global => null;

   --  Point addition P + Q on Curve C. Same Factor_Found convention.
   function Add (P, Q : Point; C : Curve) return Op_Result
     with Global => null;

   --  Scalar multiplication K·P (binary method). Returns Ok with the
   --  resulting point, or Factor_Found when an intermediate add/double
   --  exposes a nontrivial (or full) gcd with N.
   function Scalar_Mult (K : U64; P : Point; C : Curve) return Op_Result
     with Global => null;

   ------------------------------------------------------------------
   --  Lenstra ECM — Stage 1
   ------------------------------------------------------------------

   --  Stage 1 on one curve / point: compute (roughly) [lcm(1..B)]·P by
   --  successive prime-power scalar multiplications. Returns a nontrivial
   --  factor when found; returns 1 on miss; may return N if every factor
   --  collapses at once (treated as miss by the dispatcher).
   function ECM_Stage1_Once
     (C : Curve; P : Point; B : U64) return U64
     with Global => null;

   --  Try up to Curves random Weierstrass curves with Stage-1 bound B.
   --  Seed drives a deterministic LCG for (A, X0, Y0); B_coeff is chosen
   --  so that P=(X0,Y0) lies on the curve. Even N → 2. Primes → 1.
   --  N < 2 or B < 2 or Curves = 0 → Invalid_Argument.
   --  Returns a nontrivial factor, or 1 on total failure.
   function Factor_ECM_Stage1
     (N      : U64;
      B      : U64     := Default_B;
      Curves : Natural := Default_Curves;
      Seed   : U64     := 1) return U64
     with Global => null;

   --  Convenience wrapper: Factor_ECM_Stage1 with package defaults.
   function Factor
     (N    : U64;
      B    : U64 := Default_B;
      Seed : U64 := 1) return U64
     with Global => null;

end Lenstra_Elliptic_Curve_Factorization;
