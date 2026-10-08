--  Binary_GCD — Ada/SPARK Level 4 educational package for Stein's
--  algorithm (binary GCD / binary Euclidean algorithm).
--  Computes gcd of nonnegative integers using only shifts, comparisons,
--  and subtraction (no division / remainder in the main Stein path).
--
--  SPARK port of Ada-Binary-GCD: unsigned U64 domain (no exceptions),
--  contracts replace exception paths; Gcd(0,0) = 0 by definition.
--  Classical Euclidean is a local reference for cross-checks (no sibling
--  `with`). Closest SPARK sibling: Ada-SPARK-Euclidean-Algorithm.
--
--  Reference: https://en.wikipedia.org/wiki/Binary_GCD_algorithm

package Binary_GCD
  with SPARK_Mode => On
is

   ---------------------------------------------------------------------------
   -- Domain (unsigned 64-bit — nonnegative by construction)
   ---------------------------------------------------------------------------

   --  Educational word type shared with sibling SPARK number-theory
   --  packages. Domain is nonnegative; there is no signed API.
   type U64 is mod 2 ** 64;

   --  Soft classroom bound for demo operands / recursive Stein measure.
   Max_Educational : constant U64 := 1_000_000;

   --  Outer Stein reduction ceiling (educational termination bound).
   Max_Stein_Steps : constant Natural := 4096;

   ---------------------------------------------------------------------------
   -- Bit helpers (trailing-zero count / shifts)
   ---------------------------------------------------------------------------

   --  Number of trailing zero bits in N (valuation v2(N)).
   --  Trailing_Zeros (0) = 64 (every bit of a zero word is a trailing zero).
   function Trailing_Zeros (N : U64) return Natural
     with
       Global => null,
       Post   =>
         Trailing_Zeros'Result <= 64
         and then (if N = 0 then Trailing_Zeros'Result = 64
                   else Trailing_Zeros'Result < 64);

   --  Logical shifts. Shift amounts ≥ 64 yield 0.
   function Shift_Right (N : U64; Amount : Natural) return U64
     with
       Global => null,
       Post   =>
         (if Amount >= 64 then Shift_Right'Result = 0
          elsif Amount = 0 then Shift_Right'Result = N);

   function Shift_Left (N : U64; Amount : Natural) return U64
     with
       Global => null,
       Post   =>
         (if Amount >= 64 then Shift_Left'Result = 0
          elsif Amount = 0 then Shift_Left'Result = N);

   --  True iff N is odd (N rem 2 = 1). N = 0 → False.
   function Is_Odd (N : U64) return Boolean is
     ((N and 1) = 1)
   with Global => null;

   ---------------------------------------------------------------------------
   -- Stein binary GCD
   ---------------------------------------------------------------------------

   --  Iterative Stein binary GCD (preferred / performant layout).
   --  Uses trailing-zero stripping once per operand, then a subtract /
   --  re-normalize loop that keeps both values odd on entry.
   --  Bounded outer reduction so Level 4 termination is immediate;
   --  falls back to classical Euclidean if the classroom ceiling were
   --  ever hit. Gcd (0, 0) = 0; Gcd (0, B) = B; Gcd (A, 0) = A.
   function Gcd (A, B : U64) return U64
     with
       Global => null,
       Post   =>
         (if A = 0 and then B = 0 then
            Gcd'Result = 0
          elsif A = 0 then
            Gcd'Result = B
          elsif B = 0 then
            Gcd'Result = A
          else
            Gcd'Result > 0);

   --  Educational recursive entry with the same contracts as Gcd on the
   --  classroom domain. Pre caps operands (matches non-SPARK demo sizes).
   --  Body delegates to iterative Stein so Level 4 discharges a compact VC;
   --  the identity-driven recursive formulation lives in Ada-Binary-GCD.
   function Gcd_Recursive (A, B : U64) return U64
     with
       Global => null,
       Pre    => A <= Max_Educational and then B <= Max_Educational,
       Post   =>
         (if A = 0 and then B = 0 then
            Gcd_Recursive'Result = 0
          elsif A = 0 then
            Gcd_Recursive'Result = B
          elsif B = 0 then
            Gcd_Recursive'Result = A
          else
            Gcd_Recursive'Result > 0);

   ---------------------------------------------------------------------------
   -- Classical Euclidean (local reference — no sibling `with`)
   ---------------------------------------------------------------------------

   --  Classical Euclidean gcd via successive remainders, on the same U64
   --  domain. Used by tests to cross-check Stein. Gcd_Euclidean (0,0) = 0.
   function Gcd_Euclidean (A, B : U64) return U64
     with
       Global => null,
       Post   =>
         (if A = 0 and then B = 0 then
            Gcd_Euclidean'Result = 0
          elsif B = 0 then
            Gcd_Euclidean'Result = A
          elsif A = 0 then
            Gcd_Euclidean'Result = B
          else
            Gcd_Euclidean'Result > 0);

   --  True iff Gcd (A, B) = 1.
   function Are_Coprime (A, B : U64) return Boolean
     with
       Global => null,
       Post   => Are_Coprime'Result = (Gcd (A, B) = 1);

end Binary_GCD;
