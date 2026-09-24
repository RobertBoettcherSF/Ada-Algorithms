--  Binary_GCD — Ada 2023 educational package for Stein's algorithm
--  (binary GCD / binary Euclidean algorithm).
--  Computes gcd of nonnegative integers using only shifts, comparisons,
--  and subtraction (no division / remainder).
--  Primary source:
--  https://en.wikipedia.org/wiki/Binary_GCD_algorithm
--  Sibling packages (README only; do not `with`):
--    Ada-Euclidean-Algorithm, Ada-Extended-Euclidean-Algorithm.

pragma Ada_2022;

package Binary_GCD
  with SPARK_Mode => Off
is

   ---------------------------------------------------------------------------
   -- Domain (unsigned 64-bit — nonnegative by construction)
   ---------------------------------------------------------------------------

   --  Educational word type shared with sibling number-theory packages
   --  (Miller–Rabin, Pollard's rho, …). Domain is nonnegative; there is
   --  no signed API and therefore no Invalid_Argument for negatives.
   type U64 is mod 2 ** 64;

   --  Soft classroom bound for demo operands in tests / README examples.
   Max_Educational : constant U64 := 1_000_000;

   ---------------------------------------------------------------------------
   -- Bit helpers (trailing-zero count / shifts)
   ---------------------------------------------------------------------------

   --  Number of trailing zero bits in N (valuation v2(N)).
   --  Trailing_Zeros (0) = 64 (every bit of a zero word is a trailing zero).
   function Trailing_Zeros (N : U64) return Natural
     with Global => null;

   --  Logical shifts. Shift amounts ≥ 64 yield 0 (right) / 0 (left mod 2^64).
   function Shift_Right (N : U64; Amount : Natural) return U64
     with Global => null;

   function Shift_Left (N : U64; Amount : Natural) return U64
     with Global => null;

   --  True iff N is odd (N rem 2 = 1). N = 0 → False.
   function Is_Odd (N : U64) return Boolean
     with Global => null;

   ---------------------------------------------------------------------------
   -- Stein binary GCD
   ---------------------------------------------------------------------------

   --  Iterative Stein binary GCD (preferred / performant layout).
   --  Uses trailing-zero stripping once per operand, then a subtract /
   --  re-normalize loop that keeps both values odd on entry.
   --  Gcd (0, 0) = 0; Gcd (0, B) = B; Gcd (A, 0) = A.
   function Gcd (A, B : U64) return U64
     with Global => null;

   --  Recursive formulation following the Wikipedia identities directly
   --  (educational; same results as Gcd).
   function Gcd_Recursive (A, B : U64) return U64
     with Global => null;

   ---------------------------------------------------------------------------
   -- Classical Euclidean (local reference — no sibling `with`)
   ---------------------------------------------------------------------------

   --  Classical Euclidean gcd via successive remainders, on the same U64
   --  domain. Used by tests to cross-check Stein. Gcd_Euclidean (0,0) = 0.
   function Gcd_Euclidean (A, B : U64) return U64
     with Global => null;

   --  True iff Gcd (A, B) = 1.
   function Are_Coprime (A, B : U64) return Boolean
     with Global => null;

end Binary_GCD;
