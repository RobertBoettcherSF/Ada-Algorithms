--  Baillie–PSW primality test — Ada 2023 educational package.
--  Combines a strong probable-prime test to base 2 with a strong Lucas
--  probable-prime test (Selfridge parameters) on unsigned 64-bit integers.
--  Self-contained modular arithmetic (no sibling `with`).
--  Primary source:
--  https://en.wikipedia.org/wiki/Baillie%E2%80%93PSW_primality_test
--  Note-sheet typo "Bailie-PSW" → Baillie–PSW.
--  Siblings: Ada-Miller-Rabin, Ada-Fermat-Primality-Test,
--  Ada-Lucas-Primality-Test (classical Lucas — different algorithm);
--  next: AKS primality test.

pragma Ada_2022;

package Baillie_PSW
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word / signed helper types (educational 64-bit domain)
   ------------------------------------------------------------------

   --  All candidates live in the full unsigned 64-bit range.
   type U64 is mod 2 ** 64;

   --  Signed 64-bit for Selfridge discriminants D (can be negative).
   type I64 is range -(2 ** 63) .. (2 ** 63) - 1;

   Invalid_Argument : exception;
   --  Raised by Choose_Selfridge_D when Jacobi(D, N) = 0 exposes a
   --  proper factor of N (so N is composite).
   Composite_Signal : exception;

   ------------------------------------------------------------------
   --  Modular arithmetic helpers
   ------------------------------------------------------------------

   --  (A * B) mod M without intermediate overflow.
   --  Uses Interfaces.Unsigned_128 for the product.
   --  Raises Invalid_Argument if M = 0.
   function Mul_Mod (A, B, M : U64) return U64
     with Global => null;

   --  (Base ^ Exp) mod Modulus via binary exponentiation + Mul_Mod.
   --  Raises Invalid_Argument if Modulus = 0.
   --  Convention: Mod_Pow (B, 0, M) = 1 rem M for M > 0 (so 0 when M = 1).
   function Mod_Pow (Base, Exp, Modulus : U64) return U64
     with Global => null;

   --  Greatest common divisor (non-negative Euclidean algorithm).
   function Gcd (A, B : U64) return U64
     with Global => null;

   --  Jacobi symbol (A / N) for odd positive N.
   --  Returns −1, 0, or +1.
   --  Raises Invalid_Argument if N = 0 or N is even.
   function Jacobi (A : I64; N : U64) return Integer
     with Global => null;

   --  True iff N is a perfect square (integer square root check).
   function Is_Perfect_Square (N : U64) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  Baillie–PSW building blocks
   ------------------------------------------------------------------

   --  Strong probable prime to base 2 (Miller–Rabin strong test, A = 2).
   --  N < 2 → False; N = 2 → True; even N > 2 → False.
   function Is_Strong_PRP_Base_2 (N : U64) return Boolean
     with Global => null;

   --  Selfridge Method A: first D in 5, −7, 9, −11, … with Jacobi(D, N) = −1.
   --  Raises Invalid_Argument if N < 3 or N even.
   --  Raises Composite_Signal if Jacobi = 0 exposes gcd(|D|, N) ∈ (1, N).
   --  Caller should reject perfect squares before searching (no such D exists).
   function Choose_Selfridge_D (N : U64) return I64
     with Global => null;

   --  Strong Lucas probable prime with Selfridge P = 1, Q = (1 − D)/4.
   --  Requires odd N > 2 and Jacobi(D, N) = −1 (as chosen by Selfridge).
   --  Passes iff U_d ≡ 0 (mod N) or V_{d·2^r} ≡ 0 (mod N) for some
   --  0 ≤ r < s, where N + 1 = d · 2^s with d odd (Baillie–Wagstaff).
   function Is_Strong_Lucas_PRP (N : U64; D : I64) return Boolean
     with Global => null;

   --  Full Baillie–PSW test on U64.
   --  N < 2 → False; N = 2 → True; even N > 2 → False;
   --  perfect square → False; then strong base-2 SPRP + strong Lucas PRP.
   function Is_Baillie_PSW_Prime (N : U64) return Boolean
     with Global => null;

end Baillie_PSW;
