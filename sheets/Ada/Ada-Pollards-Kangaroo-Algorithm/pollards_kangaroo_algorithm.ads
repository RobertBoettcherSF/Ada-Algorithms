--  Pollard's kangaroo (lambda) algorithm — Ada 2023 educational package.
--  Discrete logarithm in a known interval [A, B] of the multiplicative
--  group modulo a prime: find X with G^X ≡ Y (mod P) and A ≤ X ≤ B.
--  Classic tame/wild kangaroo with the same jump set; tame starts at G^B
--  (Wikipedia-faithful). Expected time ~ O(√(B−A)).
--  Primary source:
--  https://en.wikipedia.org/wiki/Pollard's_kangaroo_algorithm
--  Siblings (README only; do not `with`): Pollard's rho for logarithms,
--  Baby-step giant-step, Pohlig–Hellman, Index calculus.

pragma Ada_2022;

package Pollards_Kangaroo_Algorithm
  with SPARK_Mode => Off
is

   ------------------------------------------------------------------
   --  Word type (educational 64-bit unsigned domain)
   ------------------------------------------------------------------

   type U64 is mod 2 ** 64;

   Invalid_Argument : exception;
   Not_Found        : exception;

   --  Soft classroom bound on interval width B−A (kangaroo is O(√W)).
   Max_Educational_Width : constant U64 := 2_000_000;

   --  Default cap on tame + wild jump steps before giving up.
   Default_Max_Steps : constant Natural := 500_000;

   ------------------------------------------------------------------
   --  Result record (Found / X)
   ------------------------------------------------------------------

   type Kangaroo_Result is record
      Found : Boolean := False;
      X     : U64     := 0;
   end record;

   ------------------------------------------------------------------
   --  Modular / integer helpers (self-contained; no sibling `with`)
   ------------------------------------------------------------------

   --  (A * B) mod M without intermediate overflow (Unsigned_128 product).
   --  Raises Invalid_Argument if M = 0.
   function Mul_Mod (A, B, M : U64) return U64
     with Global => null;

   --  (Base ^ Exp) mod Modulus via binary exponentiation + Mul_Mod.
   --  Alias of the usual modular power; named Mod_Exp to match the
   --  kangaroo API sketch. Raises Invalid_Argument if Modulus = 0.
   function Mod_Exp (Base, Exp, Modulus : U64) return U64
     with Global => null;

   --  Largest K such that K*K ≤ N (integer floor square root). Floor_Sqrt(0)=0.
   function Floor_Sqrt (N : U64) return U64
     with Global => null;

   --  True iff G^X ≡ Y (mod P) with P > 1.
   function Verify_Discrete_Log
     (G, Y, P, X : U64) return Boolean
     with Global => null;

   ------------------------------------------------------------------
   --  Pollard's kangaroo (lambda) — interval discrete log
   ------------------------------------------------------------------

   --  Find X in [A, B] such that G^X ≡ Y (mod P).
   --
   --  Wikipedia-faithful tame start: the tame kangaroo begins at G^B with
   --  travelled distance 0. Both kangaroos share the same pseudorandom
   --  jump map f (hash of the current group element into a small set of
   --  jump exponents whose mean is ~ √(B−A)). This educational build
   --  stores the full tame path (element → distance) so that a wild
   --  collision with any tame landing recovers
   --
   --      X = B + d_tame − d_wild
   --
   --  (verified in [A, B] and by modular exponentiation).
   --
   --  Returns a Kangaroo_Result with Found = True and X in [A, B] on
   --  success. On step exhaustion or no recoverable solution, Found is
   --  False (X is unspecified). Prefer Solve_Kangaroo when you want the
   --  Not_Found exception instead of a soft failure.
   --
   --  Raises Invalid_Argument when P < 2, G rem P = 0, Y rem P = 0,
   --  A > B, B − A > Max_Educational_Width, or Max_Steps = 0.
   function Try_Solve_Kangaroo
     (P         : U64;
      G         : U64;
      Y         : U64;
      A         : U64;
      B         : U64;
      Max_Steps : Natural := Default_Max_Steps) return Kangaroo_Result
     with Global => null;

   --  Same search as Try_Solve_Kangaroo, but returns X on success and
   --  raises Not_Found when the search fails within Max_Steps.
   --  Raises Invalid_Argument on the same bad-parameter conditions.
   function Solve_Kangaroo
     (P         : U64;
      G         : U64;
      Y         : U64;
      A         : U64;
      B         : U64;
      Max_Steps : Natural := Default_Max_Steps) return U64
     with Global => null;

end Pollards_Kangaroo_Algorithm;
