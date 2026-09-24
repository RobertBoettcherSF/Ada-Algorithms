--  Baby-step giant-step (Shanks) — Ada 2023 educational package.
--  Discrete logarithm α^γ = β in a cyclic group of known order n via
--  meet-in-the-middle: baby table α^j (j < m) and giant steps with α^{-m},
--  m = ceil(√n). Time and space Θ(√n).
--  Primary source:
--  https://en.wikipedia.org/wiki/Baby-step_giant-step
--  Siblings (README only; do not `with`): Pohlig–Hellman,
--  Pollard's rho for logarithms, index calculus (planned).

pragma Ada_2022;

package Baby_Step_Giant_Step
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Soft classroom bound on the group order n (BSGS stores Θ(√n) entries).
   Max_Educational_Order : constant U64 := 2_000_000;

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

   --  Modular multiplicative inverse of A modulo M in 0 .. M−1 when
   --  Gcd(A, M) = 1 and M > 1. Raises Invalid_Argument otherwise.
   function Modular_Inverse (A, M : U64) return U64
     with Global => null;

   --  Largest K such that K*K ≤ N (integer floor square root). Floor_Sqrt(0)=0.
   function Floor_Sqrt (N : U64) return U64
     with Global => null;

   --  Smallest K such that K*K ≥ N (integer ceil square root). Ceil_Sqrt(0)=0.
   function Ceil_Sqrt (N : U64) return U64
     with Global => null;

   --  True iff Alpha^Log ≡ Beta (mod Modulus) with Modulus > 1.
   function Verify_Discrete_Log
     (Alpha, Beta, Modulus, Log : U64) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  Baby-step giant-step discrete logarithm (Shanks)
   ------------------------------------------------------------------

   --  Find γ such that Alpha^γ ≡ Beta (mod Modulus), where Alpha generates
   --  a cyclic subgroup of known order Order (caller-supplied).
   --
   --  Let m = ceil(√Order). Build a baby-step table of (α^j, j) for
   --  j = 0 .. m−1 (linear O(m) lookup — fine for toy sizes). Then walk
   --  giant steps y_i = β · (α^{-m})^i and look up each y_i in the table.
   --  A match α^j = y_i yields γ = i·m + j.
   --
   --  Returns γ in 0 .. Order−1 on success. Returns Order as the
   --  documented failure sentinel (β not in ⟨α⟩, or no match within the
   --  i = 0 .. m−1 search window).
   --
   --  Raises Invalid_Argument when Modulus < 2, Order = 0,
   --  Order > Max_Educational_Order, Alpha rem Modulus = 0, or
   --  Beta rem Modulus = 0.
   function Discrete_Log_BSGS
     (Alpha   : U64;
      Beta    : U64;
      Modulus : U64;
      Order   : U64) return U64
     with Global => null;

end Baby_Step_Giant_Step;
