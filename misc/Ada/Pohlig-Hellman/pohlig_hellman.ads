--  Pohlig–Hellman algorithm — Ada 2023 educational package.
--  Discrete logarithm α^γ = β in a cyclic group of smooth order n:
--  factor n, solve DLP in each prime-power subgroup, combine via CRT.
--  Primary source:
--  https://en.wikipedia.org/wiki/Pohlig–Hellman_algorithm
--  Siblings (README only; do not `with`): Pollard's rho for logarithms,
--  baby-step giant-step (BSGS), index calculus (planned).

pragma Ada_2022;

package Pohlig_Hellman
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Soft classroom bound on the group order n.
   Max_Educational_Order : constant U64 := 2_000_000;

   --  Largest prime p for which the p-adic digit search is allowed
   --  (exhaustive for tiny p, BSGS-lite otherwise). Above this, the
   --  order is treated as not smooth enough for the educational solver.
   Max_Prime_Factor : constant U64 := 50_000;

   --  Cap on the number of distinct prime-power factors stored.
   Max_Factor_Count : constant := 32;

   ------------------------------------------------------------------
   --  Smooth-order factorization (trial)
   ------------------------------------------------------------------

   type Prime_Power is record
      Prime : U64 := 0;
      Exp   : Natural := 0;
   end record;

   type Factor_Array is array (Positive range <>) of Prime_Power;

   --  Trial-factor N into prime powers. Raises Invalid_Argument if N = 0.
   --  Returns an empty array when N = 1. Factors are ascending in Prime.
   function Factorize_Trial (N : U64) return Factor_Array
     with Global => null;

   --  Product of p^e over Factors; used to validate a precomputed list.
   function Product_Of_Factors (Factors : Factor_Array) return U64
     with Global => null;

   --  True iff every prime in Factors is ≤ Max_Prime_Factor.
   function Is_Smooth_Enough (Factors : Factor_Array) return Boolean
     with Global => null;

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
   --  Pohlig–Hellman discrete logarithm
   ------------------------------------------------------------------

   --  Find γ such that Alpha^γ ≡ Beta (mod Modulus), where Alpha generates
   --  a cyclic subgroup of known order Order (caller-supplied). Factors
   --  Order by trial division, solves the DLP in each prime-power
   --  subgroup with exhaustive search or BSGS-lite for the p-adic digits,
   --  then combines residues with the Chinese remainder theorem.
   --
   --  Returns γ in 0 .. Order−1 on success. Returns Order as the
   --  documented failure sentinel (β not in ⟨α⟩, a p-adic digit search
   --  fails, CRT inconsistency, or Order not smooth enough /
   --  Max_Prime_Factor exceeded).
   --
   --  Raises Invalid_Argument when Modulus < 2, Order = 0,
   --  Order > Max_Educational_Order, Alpha rem Modulus = 0, or
   --  Beta rem Modulus = 0.
   function Discrete_Log_Pohlig_Hellman
     (Alpha   : U64;
      Beta    : U64;
      Modulus : U64;
      Order   : U64) return U64
     with Global => null;

   --  Same as above, but uses a precomputed prime-power factorization of
   --  Order. Raises Invalid_Argument when Factors is empty (and Order > 1),
   --  Product_Of_Factors (Factors) ≠ Order, or any Exp = 0 / Prime < 2.
   --  Failure sentinel and other Invalid_Argument rules match the
   --  auto-factoring overload.
   function Discrete_Log_Pohlig_Hellman
     (Alpha   : U64;
      Beta    : U64;
      Modulus : U64;
      Order   : U64;
      Factors : Factor_Array) return U64
     with Global => null;

end Pohlig_Hellman;
