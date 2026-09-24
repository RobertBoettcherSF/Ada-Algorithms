--  Pollard's rho algorithm for logarithms — Ada 2023 educational package.
--  Discrete logarithm in a cyclic group via pseudorandom iteration of
--  exponents (x = α^a · β^b) and Floyd cycle detection — NOT integer
--  factorization (that is Ada-Pollards-Rho).
--  Expected time ~ O(√n) for group order n.
--  Primary source:
--  https://en.wikipedia.org/wiki/Pollard's_rho_algorithm_for_logarithms
--  Siblings (README only; do not `with`): Ada-Pollards-Rho (factorization),
--  Pohlig–Hellman, Baby-step giant-step, Index calculus (planned).

pragma Ada_2022;

package Pollards_Rho_Logarithms
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Soft classroom bound on the group order n (rho is O(√n)).
   Max_Educational_Order : constant U64 := 2_000_000;

   --  Cap on Floyd outer iterations before giving up (sentinel).
   Default_Max_Steps : constant Natural := 200_000;

   ------------------------------------------------------------------
   --  Modular / integer helpers (self-contained; no sibling `with`)
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

   --  Non-negative difference (X − Y) mod M with M > 0.
   --  Raises Invalid_Argument if M = 0.
   function Sub_Mod (X, Y, M : U64) return U64
     with Global => null;

   --  Modular multiplicative inverse of A modulo M in 0 .. M−1 when
   --  Gcd(A, M) = 1 and M > 1. Raises Invalid_Argument otherwise.
   function Modular_Inverse (A, M : U64) return U64
     with Global => null;

   --  True iff Alpha^Log ≡ Beta (mod Modulus) with Modulus > 1.
   function Verify_Discrete_Log
     (Alpha, Beta, Modulus, Log : U64) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  Pollard's rho for discrete logarithms (Floyd)
   ------------------------------------------------------------------

   --  Find γ such that Alpha^γ ≡ Beta (mod Modulus), where Alpha generates
   --  a cyclic subgroup of known order Order (caller-supplied). Uses the
   --  Wikipedia three-set partition on x rem 3, tracks exponents
   --  (a, b) for x = Alpha^a · Beta^b, and Floyd tortoise/hare until
   --  x_i = x_2i; then solves (B−b)γ ≡ (a−A) (mod Order).
   --
   --  Returns γ in 0 .. Order−1 on success. Returns Order as the
   --  documented failure sentinel (r = 0, unlucky partition, Max_Steps
   --  exhaustion, or no candidate verifies). Seed sets the initial
   --  α-exponent a0 (x0 = Alpha^Seed); Seed = 0 is the classic start.
   --
   --  Raises Invalid_Argument when Modulus < 2, Order = 0,
   --  Order > Max_Educational_Order, Alpha rem Modulus = 0, or
   --  Beta rem Modulus = 0.
   function Discrete_Log_Rho
     (Alpha     : U64;
      Beta      : U64;
      Modulus   : U64;
      Order     : U64;
      Seed      : U64     := 0;
      Max_Steps : Natural := Default_Max_Steps) return U64
     with Global => null;

end Pollards_Rho_Logarithms;
