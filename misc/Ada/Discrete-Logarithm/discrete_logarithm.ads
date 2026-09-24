--  Discrete logarithm — Ada 2023 educational survey package.
--  Self-contained U64 classroom sketches of classical DLP methods from
--  Wikipedia "Discrete logarithm": trial multiplication, baby-step
--  giant-step (Shanks), and a minimal Pohlig–Hellman-style path for
--  smooth order (trial factor + CRT), plus a Discrete_Log driver.
--  Sibling packages (Pollard's rho for logarithms, dedicated Pohlig–
--  Hellman, BSGS, index calculus) are documented in the README only —
--  this repo does not `with` them.
--  Primary source:
--  https://en.wikipedia.org/wiki/Discrete_logarithm

pragma Ada_2022;

package Discrete_Logarithm
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;

   --  Soft classroom bound on the group order n for BSGS / driver /
   --  Pohlig–Hellman sketches (BSGS stores Θ(√n) entries).
   Max_Educational_Order : constant U64 := 2_000_000;

   --  Driver uses exhaustive trial when Order ≤ this bound.
   Max_Trial_Order : constant U64 := 256;

   --  Largest prime p allowed in the educational Pohlig–Hellman path.
   Max_Prime_Factor : constant U64 := 4_096;

   --  Cap on distinct prime-power factors stored for PH.
   Max_Factor_Count : constant := 32;

   ------------------------------------------------------------------
   --  Smooth-order factorization (trial; for PH path)
   ------------------------------------------------------------------

   type Prime_Power is record
      Prime : U64 := 0;
      Exp   : Natural := 0;
   end record;

   type Factor_Array is array (Positive range <>) of Prime_Power;

   --  Trial-factor N into prime powers. Raises Invalid_Argument if N = 0.
   --  Returns an empty array when N = 1. Factors ascending in Prime.
   function Factorize_Trial (N : U64) return Factor_Array
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
   --  1. Trial multiplication (exhaustive search)
   ------------------------------------------------------------------

   --  Find γ such that Alpha^γ ≡ Beta (mod Modulus) by walking
   --  Cur := 1, Cur := Cur · Alpha for γ = 0 .. Order−1.
   --  Returns γ in 0 .. Order−1 on success. Returns Order as the
   --  documented failure sentinel (β not in ⟨α⟩ within the window).
   --  Raises Invalid_Argument when Modulus < 2, Order = 0,
   --  Order > Max_Educational_Order, Alpha rem Modulus = 0, or
   --  Beta rem Modulus = 0.
   function Discrete_Log_Trial
     (Alpha   : U64;
      Beta    : U64;
      Modulus : U64;
      Order   : U64) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  2. Baby-step giant-step (Shanks)
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
   --  documented failure sentinel.
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

   ------------------------------------------------------------------
   --  3. Minimal Pohlig–Hellman-style path (smooth order)
   ------------------------------------------------------------------

   --  Educational sketch: factor Order by trial division; if every
   --  prime factor is ≤ Max_Prime_Factor, solve the DLP in each
   --  prime-power subgroup (exhaustive digit search) and combine via
   --  CRT. Otherwise return the failure sentinel Order.
   --
   --  Returns γ in 0 .. Order−1 on success. Returns Order on failure
   --  (not smooth enough, digit miss, CRT inconsistency, β ∉ ⟨α⟩).
   --
   --  Raises Invalid_Argument when Modulus < 2, Order = 0,
   --  Order > Max_Educational_Order, Alpha rem Modulus = 0, or
   --  Beta rem Modulus = 0.
   --
   --  Full-featured sibling: Ada-Pohlig-Hellman (README link only).
   function Discrete_Log_Pohlig_Hellman
     (Alpha   : U64;
      Beta    : U64;
      Modulus : U64;
      Order   : U64) return U64
     with Global => null;

   ------------------------------------------------------------------
   --  4. Driver Discrete_Log (classroom strategy)
   ------------------------------------------------------------------

   --  Educational driver for Order ≤ Max_Educational_Order:
   --    Order ≤ Max_Trial_Order → Discrete_Log_Trial;
   --    else → Discrete_Log_BSGS.
   --  Documented educational Max_Order = Max_Educational_Order.
   --  Failure sentinel and Invalid_Argument rules match the callees.
   function Discrete_Log
     (Alpha   : U64;
      Beta    : U64;
      Modulus : U64;
      Order   : U64) return U64
     with Global => null;

end Discrete_Logarithm;
