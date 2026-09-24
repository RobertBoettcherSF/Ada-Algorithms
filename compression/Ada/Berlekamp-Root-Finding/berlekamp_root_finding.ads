--  Berlekamp's root finding algorithm (Berlekamp–Rabin) — Ada 2023
--  educational package. Find roots of a univariate polynomial over the
--  prime field F_p on unsigned 64-bit integers.
--  Primary source:
--  https://en.wikipedia.org/wiki/Berlekamp's_root_finding_algorithm
--  Self-contained modular + dense polynomial arithmetic.
--  Probabilistic; Tonelli–Shanks / Cipolla are the degree-2 special case.
--  Next sheet: Modular square root survey.

pragma Ada_2022;

package Berlekamp_Root_Finding
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Educational trial-division primality enforced for P ≤ this bound.
   Max_Trial_Prime : constant U64 := 1_000_000;

   --  Brute-force oracle (Find_Roots_Deterministic_Small) accepts P ≤ this.
   Max_Brute_P : constant U64 := 10_000;

   --  Default random-split budget for Find_Roots.
   Default_Max_Attempts : constant Positive := 64;

   --  Educational degree hint (algorithm works beyond this; tests stay small).
   Max_Edu_Degree : constant Natural := 8;

   ------------------------------------------------------------------
   --  Dense polynomials (low degree first) and root lists
   ------------------------------------------------------------------

   --  Coeffs(0) + Coeffs(1)*x + ... + Coeffs(n)*x^n  over F_p.
   type Poly is array (Natural range <>) of U64;

   --  Distinct roots in 0 .. P-1 (order unspecified).
   type Root_List is array (Natural range <>) of U64;

   ------------------------------------------------------------------
   --  Modular arithmetic helpers
   ------------------------------------------------------------------

   --  (A * B) mod M without intermediate overflow (Unsigned_128).
   --  Raises Invalid_Argument if M = 0.
   function Mul_Mod (A, B, M : U64) return U64;

   --  (Base ^ Exp) mod Modulus via binary exponentiation + Mul_Mod.
   --  Raises Invalid_Argument if Modulus = 0.
   function Mod_Pow (Base, Exp, Modulus : U64) return U64;

   --  Greatest common divisor (Euclidean). Gcd (0, 0) = 0.
   function Gcd (A, B : U64) return U64;

   --  Modular inverse of A modulo prime P (Fermat: A^(P-2)).
   --  Raises Invalid_Argument if P < 2 or A ≡ 0 (mod P).
   function Mod_Inv (A, P : U64) return U64;

   --  Exact trial-division primality for educational sizes.
   function Is_Prime_Trial (N : U64) return Boolean;

   ------------------------------------------------------------------
   --  Polynomial helpers over F_p
   ------------------------------------------------------------------

   --  Degree of F mod P; −1 if the zero polynomial.
   function Poly_Degree (F : Poly; P : U64) return Integer;

   --  Reduce coeffs mod P and strip leading zeros (may return (1 => 0)).
   function Poly_Normalize (F : Poly; P : U64) return Poly;

   --  F + G and F − G componentwise mod P (result normalized).
   function Poly_Add (F, G : Poly; P : U64) return Poly;
   function Poly_Sub (F, G : Poly; P : U64) return Poly;

   --  Schoolbook product mod P (normalized).
   function Poly_Mul (F, G : Poly; P : U64) return Poly;

   --  Remainder of A divided by M over F_p (deg result < deg M when deg M≥0).
   --  Raises Invalid_Argument if M is the zero polynomial.
   function Poly_Mod (A, M : Poly; P : U64) return Poly;

   --  Quotient of A / M when M divides A exactly (leading monic preferred).
   --  Raises Invalid_Argument if M is zero or does not divide A.
   function Poly_Quotient (A, M : Poly; P : U64) return Poly;

   --  Euclidean GCD over F_p; result is monic when non-zero.
   function Poly_Gcd (F, G : Poly; P : U64) return Poly;

   --  Base^Exp mod Modulus in F_p[x]/(Modulus), coeffs mod P.
   --  Raises Invalid_Argument if Modulus is zero.
   function Poly_Mod_Pow
     (Base    : Poly;
      Exp     : U64;
      Modulus : Poly;
      P       : U64) return Poly;

   --  Formal derivative over F_p.
   function Poly_Derivative (F : Poly; P : U64) return Poly;

   --  Horner evaluation F(X) mod P.
   function Poly_Eval (F : Poly; X, P : U64) return U64;

   --  Square-free kernel: F / gcd(F, F') over F_p (distinct-root support).
   function Poly_Square_Free (F : Poly; P : U64) return Poly;

   --  Compose F(x − Z) over F_p (binomial expansion of powers).
   function Poly_Shift (F : Poly; Z, P : U64) return Poly;

   ------------------------------------------------------------------
   --  Root finding
   ------------------------------------------------------------------

   --  Probabilistic Berlekamp–Rabin root finding over F_p.
   --  Returns distinct roots of F in F_p (after square-free reduction via
   --  gcd with the derivative). Empty result ⇒ no F_p-roots found
   --  (irreducible factors of deg > 1, or exhausted Max_Attempts unluckily).
   --  Seed drives an internal LCG for reproducible random splits.
   --  Raises Invalid_Argument if F is empty, P < 2, P even ≠ 2, or
   --  (when P ≤ Max_Trial_Prime) P is composite.
   function Find_Roots
     (F            : Poly;
      P            : U64;
      Max_Attempts : Positive := Default_Max_Attempts;
      Seed         : U64     := 1) return Root_List;

   --  Brute-force oracle: evaluate F at 0 .. P−1. Requires P ≤ Max_Brute_P
   --  and a valid prime modulus (same validation as Find_Roots).
   --  Returns all distinct r with F(r) ≡ 0 (mod P).
   function Find_Roots_Deterministic_Small
     (F : Poly;
      P : U64) return Root_List;

end Berlekamp_Root_Finding;
